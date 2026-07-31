[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [string]$QemuRoot,
    [ValidateSet('quick', 'core', 'full')]
    [string]$Profile = 'quick',
    [string]$ConfigurationPath,
    [string]$OutputDirectory,
    [switch]$Resume,
    [switch]$RetryFailed,
    [switch]$IncludeWslReference,
    [switch]$KeepArtifactsOnFailure,
    [switch]$CleanupStale
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ConfigPath = if ([string]::IsNullOrWhiteSpace($ConfigurationPath)) {
    Join-Path $PSScriptRoot 'benchmark.json'
} else {
    [System.IO.Path]::GetFullPath($ConfigurationPath)
}
$script:RepositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))

function Get-ObjectProperty {
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }
    return $property.Value
}

function Assert-Condition {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if (-not $Condition) {
        throw "Benchmark error: $Message"
    }
}

function Get-Sha256 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Set-BenchmarkSleepInhibition {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )

    if ($null -eq ('BenchmarkExecutionState' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class BenchmarkExecutionState
{
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint SetThreadExecutionState(uint flags);
}
'@
    }

    $flags = if ($Enabled) {
        [Convert]::ToUInt32('80000001', 16)
    } else {
        [Convert]::ToUInt32('80000000', 16)
    }
    $result = [BenchmarkExecutionState]::SetThreadExecutionState($flags)
    Assert-Condition ($result -ne 0) 'Unable to update the Windows execution state.'
}

function Test-BenchmarkCleanupSucceeded {
    param(
        [Parameter(Mandatory = $true)]
        [object]$RunnerResult
    )

    switch ([string]$RunnerResult.runner) {
        'qemu' {
            return [bool]$RunnerResult.cleanup.qemu_process_removed -and
                [bool]$RunnerResult.cleanup.host_iperf_removed -and
                ([bool]$RunnerResult.cleanup.work_directory_removed -or [bool]$RunnerResult.cleanup.artifacts_retained)
        }
        'hyperv' {
            return [bool]$RunnerResult.cleanup.vm_removed -and
                [bool]$RunnerResult.cleanup.switch_removed -and
                [bool]$RunnerResult.cleanup.firewall_rule_removed -and
                [bool]$RunnerResult.cleanup.pipe_closed -and
                [bool]$RunnerResult.cleanup.host_iperf_removed -and
                ([bool]$RunnerResult.cleanup.work_directory_removed -or [bool]$RunnerResult.cleanup.artifacts_retained)
        }
        'wsl' {
            return [bool]$RunnerResult.cleanup.process_removed -and
                [bool]$RunnerResult.cleanup.work_directory_removed
        }
        default {
            return $true
        }
    }
}

function Test-BenchmarkRetryableFailure {
    param(
        [Parameter(Mandatory = $true)]
        [object]$RunnerResult
    )

    if ([string]$RunnerResult.status -ne 'error') {
        return $false
    }
    $message = [string]$RunnerResult.error
    if ($message -match '(?i)exceeded its \d+ second timeout|timed out') {
        return $true
    }
    return [string]$RunnerResult.runner -eq 'hyperv' -and $message -match (
        '(?i)Malformed BENCH_JSON|did not emit BENCH_READY|' +
        'did not emit exactly one .* record|malformed raw tool JSON|' +
        'raw value .* does not match normalized value'
    )
}

function Save-BenchmarkRetryArtifacts {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Run,
        [Parameter(Mandatory = $true)]
        [object]$RunnerResult,
        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory,
        [Parameter(Mandatory = $true)]
        [int]$Attempt
    )

    $retryDirectory = Join-Path $OutputDirectory ("retries\{0}\attempt-{1:d2}" -f $Run.run_id, $Attempt)
    New-Item -ItemType Directory -Path $retryDirectory -Force | Out-Null
    if (-not [string]::IsNullOrWhiteSpace([string]$RunnerResult.serial_path) -and
        (Test-Path -LiteralPath $RunnerResult.serial_path -PathType Leaf)) {
        Move-Item -LiteralPath $RunnerResult.serial_path -Destination (Join-Path $retryDirectory 'serial.log') -Force
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$RunnerResult.raw_directory) -and
        (Test-Path -LiteralPath $RunnerResult.raw_directory -PathType Container)) {
        Move-Item -LiteralPath $RunnerResult.raw_directory -Destination (Join-Path $retryDirectory 'raw') -Force
    }

    $workDirectory = if ([string]$RunnerResult.runner -eq 'qemu') {
        Join-Path $OutputDirectory "work\$($Run.run_id)"
    } else {
        Get-ObjectProperty -InputObject $RunnerResult.configuration -Name 'work_directory'
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$workDirectory) -and
        (Test-Path -LiteralPath $workDirectory -PathType Container)) {
        Move-Item -LiteralPath $workDirectory -Destination (Join-Path $retryDirectory 'work') -Force
    }
}

function Get-ProfileConfig {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Configuration,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $profileConfig = Get-ObjectProperty -InputObject $Configuration.profiles -Name $Name
    Assert-Condition ($null -ne $profileConfig) "Profile '$Name' does not exist."
    return $profileConfig
}

function Test-BenchmarkConfiguration {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Configuration
    )

    Assert-Condition ($Configuration.schema -eq 1) 'Only configuration schema 1 is supported.'
    Assert-Condition ($Configuration.defaults.ram_mib -gt 0) 'defaults.ram_mib must be positive.'
    Assert-Condition ($Configuration.defaults.run_order_seed -ge 0) 'defaults.run_order_seed must not be negative.'
    Assert-Condition ($Configuration.defaults.minimum_free_disk_gib -gt 0) 'defaults.minimum_free_disk_gib must be positive.'
    Assert-Condition ($Configuration.defaults.minimum_free_memory_mib -gt 0) 'defaults.minimum_free_memory_mib must be positive.'

    $defaultVcpus = @{}
    foreach ($vcpu in @($Configuration.defaults.vcpu_counts)) {
        Assert-Condition ($vcpu -is [int] -or $vcpu -is [long]) 'Every defaults.vcpu_counts value must be an integer.'
        Assert-Condition ($vcpu -gt 0) 'Every defaults.vcpu_counts value must be positive.'
        Assert-Condition (-not $defaultVcpus.ContainsKey([string]$vcpu)) "Duplicate default vCPU count '$vcpu'."
        $defaultVcpus[[string]$vcpu] = $true
    }
    Assert-Condition ($defaultVcpus.Count -gt 0) 'defaults.vcpu_counts must not be empty.'

    $environmentById = @{}
    $allowedAccelerators = @{
        'qemu-tcg-single' = 'tcg,thread=single'
        'qemu-tcg-multi' = 'tcg,thread=multi'
        'qemu-whpx-irqchip-on' = 'whpx,kernel-irqchip=on'
        'qemu-whpx-irqchip-off' = 'whpx,kernel-irqchip=off'
    }

    foreach ($environment in @($Configuration.environments)) {
        $id = [string]$environment.id
        Assert-Condition ($id -match '^[a-z0-9][a-z0-9-]*$') "Environment ID '$id' is invalid."
        Assert-Condition (-not $environmentById.ContainsKey($id)) "Duplicate environment ID '$id'."
        Assert-Condition (@('qemu', 'hyperv', 'wsl') -contains [string]$environment.runner) "Environment '$id' has unsupported runner '$($environment.runner)'."

        $accelerator = Get-ObjectProperty -InputObject $environment -Name 'accelerator'
        if ($environment.runner -eq 'qemu') {
            Assert-Condition ($allowedAccelerators.ContainsKey($id)) "QEMU environment '$id' is not an approved explicit accelerator configuration."
            Assert-Condition ([string]$accelerator -eq $allowedAccelerators[$id]) "QEMU environment '$id' must use accelerator '$($allowedAccelerators[$id])'."
            Assert-Condition ([string]$accelerator -notmatch 'kernel-irqchip=split') "WHPX environment '$id' requests unsupported split irqchip mode."
        } else {
            Assert-Condition ($null -eq $accelerator) "Non-QEMU environment '$id' must not define an accelerator."
        }

        if ($environment.runner -eq 'hyperv') {
            Assert-Condition ($id -eq 'hyperv') "The Hyper-V runner must use environment ID 'hyperv'."
        }
        if ($environment.runner -eq 'wsl') {
            Assert-Condition ([bool]$environment.reference_only) "WSL environment '$id' must be reference-only."
        }

        $environmentById[$id] = $environment
    }
    Assert-Condition ($environmentById.Count -gt 0) 'environments must not be empty.'

    $workloadById = @{}
    foreach ($workload in @($Configuration.workloads)) {
        $id = [string]$workload.id
        Assert-Condition ($id -match '^[a-z0-9][a-z0-9-]*$') "Workload ID '$id' is invalid."
        Assert-Condition (-not $workloadById.ContainsKey($id)) "Duplicate workload ID '$id'."
        Assert-Condition (@('micro', 'system') -contains [string]$workload.guest) "Workload '$id' has unsupported guest '$($workload.guest)'."
        Assert-Condition (@('lower', 'higher') -contains [string]$workload.metric_direction) "Workload '$id' has unsupported metric direction '$($workload.metric_direction)'."
        Assert-Condition ($workload.timeout_seconds -gt 0) "Workload '$id' must have a positive timeout."

        $workloadVcpus = @($workload.vcpus)
        Assert-Condition ($workloadVcpus.Count -gt 0) "Workload '$id' must request at least one vCPU count."
        foreach ($vcpu in $workloadVcpus) {
            Assert-Condition ($vcpu -is [int] -or $vcpu -is [long]) "Workload '$id' has a non-integer vCPU count."
            Assert-Condition ($defaultVcpus.ContainsKey([string]$vcpu)) "Workload '$id' requests unsupported vCPU count '$vcpu'."
        }

        $workloadEnvironments = @($workload.environments)
        Assert-Condition ($workloadEnvironments.Count -gt 0) "Workload '$id' must request at least one environment."
        foreach ($environmentId in $workloadEnvironments) {
            Assert-Condition ($environmentById.ContainsKey([string]$environmentId)) "Workload '$id' references unknown environment '$environmentId'."
            Assert-Condition ($environmentById[[string]$environmentId].runner -ne 'wsl') "Workload '$id' must add WSL through allow_wsl_reference, not its environments list."
        }

        $knownAnswer = Get-ObjectProperty -InputObject $workload -Name 'known_answer'
        if ($null -ne $knownAnswer) {
            Assert-Condition (-not [string]::IsNullOrWhiteSpace([string]$knownAnswer.metric)) "Workload '$id' has a known answer without a metric."
            Assert-Condition ($null -ne (Get-ObjectProperty -InputObject $knownAnswer -Name 'value')) "Workload '$id' has a known answer without a value."
        }

        $workloadById[$id] = $workload
    }
    Assert-Condition ($workloadById.Count -gt 0) 'workloads must not be empty.'

    foreach ($profileProperty in $Configuration.profiles.PSObject.Properties) {
        $profileName = $profileProperty.Name
        $profileConfig = $profileProperty.Value
        Assert-Condition ($profileConfig.warmups -ge 0) "Profile '$profileName' must not have negative warmups."
        Assert-Condition ($profileConfig.repetitions -gt 0) "Profile '$profileName' must have positive repetitions."
        Assert-Condition ($profileConfig.timeout_scale -gt 0) "Profile '$profileName' must have a positive timeout scale."

        $profileVcpus = @($profileConfig.vcpu_counts)
        Assert-Condition ($profileVcpus.Count -gt 0) "Profile '$profileName' must request at least one vCPU count."
        foreach ($vcpu in $profileVcpus) {
            Assert-Condition ($defaultVcpus.ContainsKey([string]$vcpu)) "Profile '$profileName' requests unsupported vCPU count '$vcpu'."
        }

        $profileWorkloads = @($profileConfig.workload_ids)
        Assert-Condition ($profileWorkloads.Count -gt 0) "Profile '$profileName' must request at least one workload."
        $seenProfileWorkloads = @{}
        foreach ($workloadId in $profileWorkloads) {
            Assert-Condition ($workloadById.ContainsKey([string]$workloadId)) "Profile '$profileName' references unknown workload '$workloadId'."
            Assert-Condition (-not $seenProfileWorkloads.ContainsKey([string]$workloadId)) "Profile '$profileName' repeats workload '$workloadId'."
            $seenProfileWorkloads[[string]$workloadId] = $true
        }
    }

    foreach ($requiredProfile in @('quick', 'core', 'full')) {
        Assert-Condition ($null -ne (Get-ObjectProperty -InputObject $Configuration.profiles -Name $requiredProfile)) "Required profile '$requiredProfile' is missing."
    }
}

function Expand-BenchmarkMatrix {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Configuration,
        [Parameter(Mandatory = $true)]
        [string]$ProfileName,
        [Parameter(Mandatory = $true)]
        [int]$HostLogicalProcessors,
        [Parameter(Mandatory = $true)]
        [bool]$AddWslReference
    )

    $profileConfig = Get-ProfileConfig -Configuration $Configuration -Name $ProfileName
    $environmentById = @{}
    foreach ($environment in @($Configuration.environments)) {
        $environmentById[[string]$environment.id] = $environment
    }
    $workloadById = @{}
    foreach ($workload in @($Configuration.workloads)) {
        $workloadById[[string]$workload.id] = $workload
    }
    $profileVcpus = @{}
    foreach ($vcpu in @($profileConfig.vcpu_counts)) {
        $profileVcpus[[string]$vcpu] = $true
    }

    $cells = @()
    foreach ($workloadId in @($profileConfig.workload_ids)) {
        $workload = $workloadById[[string]$workloadId]
        $environmentIds = @($workload.environments)
        if ($AddWslReference -and [bool]$workload.allow_wsl_reference) {
            $environmentIds += 'wsl-reference'
        }

        foreach ($vcpu in @($workload.vcpus)) {
            if (-not $profileVcpus.ContainsKey([string]$vcpu)) {
                continue
            }
            foreach ($environmentId in $environmentIds) {
                $environment = $environmentById[[string]$environmentId]
                $skipReason = $null
                if ($vcpu -gt $HostLogicalProcessors) {
                    $skipReason = "Host exposes $HostLogicalProcessors logical processors; requested $vcpu."
                }

                $cells += [ordered]@{
                    cell_id = "$($workload.id)__$environmentId`__${vcpu}vcpu"
                    workload = [string]$workload.id
                    guest = [string]$workload.guest
                    environment = [string]$environmentId
                    runner = [string]$environment.runner
                    accelerator = Get-ObjectProperty -InputObject $environment -Name 'accelerator'
                    reference_only = [bool]$environment.reference_only
                    vcpus = [int]$vcpu
                    ram_mib = [int]$Configuration.defaults.ram_mib
                    timeout_seconds = [int][Math]::Max(1, [Math]::Ceiling([double]$workload.timeout_seconds * [double]$profileConfig.timeout_scale))
                    warmups = [int]$profileConfig.warmups
                    repetitions = [int]$profileConfig.repetitions
                    total_runs = [int]$profileConfig.warmups + [int]$profileConfig.repetitions
                    metric_direction = [string]$workload.metric_direction
                    parameters = $workload.parameters
                    known_answer = Get-ObjectProperty -InputObject $workload -Name 'known_answer'
                    status = $(if ($null -eq $skipReason) { 'planned' } else { 'skipped' })
                    skip_reason = $skipReason
                }
            }
        }
    }

    return $cells
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-OptionalFeatureState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureName
    )

    $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName
    return [string]$feature.State
}

function Invoke-QemuProbe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Executable,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $output = @(& $Executable @Arguments 2>&1 | ForEach-Object { $_.ToString() })
    return [ordered]@{
        exit_code = [int]$LASTEXITCODE
        output = ($output -join [Environment]::NewLine)
    }
}

function Test-GuestArtifactManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,
        [Parameter(Mandatory = $true)]
        [string]$InputsLockPath
    )

    Assert-Condition (Test-Path -LiteralPath $ManifestPath -PathType Leaf) "Guest artifact manifest '$ManifestPath' is missing. Run build-guests.sh first."
    Assert-Condition (Test-Path -LiteralPath $InputsLockPath -PathType Leaf) "Guest input lock '$InputsLockPath' is missing."
    $manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    Assert-Condition ($manifest.schema -eq 1) "Guest artifact manifest '$ManifestPath' has unsupported schema '$($manifest.schema)'."
    Assert-Condition ($null -ne $manifest.PSObject.Properties['inputs_lock_sha256']) "Guest artifact manifest '$ManifestPath' has no input-lock SHA-256."
    Assert-Condition ([string]$manifest.inputs_lock_sha256 -match '^[0-9a-fA-F]{64}$') "Guest artifact manifest '$ManifestPath' has an invalid input-lock SHA-256."
    $inputsLockHash = Get-Sha256 -Path $InputsLockPath
    Assert-Condition ($inputsLockHash -eq ([string]$manifest.inputs_lock_sha256).ToLowerInvariant()) "Guest artifacts were built from a different inputs.lock.json. Run build-guests.sh again."
    $artifacts = @($manifest.artifacts)
    Assert-Condition ($artifacts.Count -gt 0) "Guest artifact manifest '$ManifestPath' contains no artifacts."

    $manifestDirectory = Split-Path -Parent $ManifestPath
    $validatedArtifacts = @()
    foreach ($artifact in $artifacts) {
        Assert-Condition (-not [string]::IsNullOrWhiteSpace([string]$artifact.path)) 'Guest artifact path must not be empty.'
        Assert-Condition ([string]$artifact.sha256 -match '^[0-9a-fA-F]{64}$') "Guest artifact '$($artifact.path)' has an invalid SHA-256."

        $artifactPath = [System.IO.Path]::GetFullPath((Join-Path $manifestDirectory ([string]$artifact.path)))
        $manifestRoot = [System.IO.Path]::GetFullPath($manifestDirectory).TrimEnd('\') + '\'
        Assert-Condition ($artifactPath.StartsWith($manifestRoot, [StringComparison]::OrdinalIgnoreCase)) "Guest artifact '$($artifact.path)' escapes the guest output directory."
        Assert-Condition (Test-Path -LiteralPath $artifactPath -PathType Leaf) "Guest artifact '$artifactPath' is missing."

        $actualHash = Get-Sha256 -Path $artifactPath
        Assert-Condition ($actualHash -eq ([string]$artifact.sha256).ToLowerInvariant()) "Guest artifact '$artifactPath' does not match its manifest SHA-256."
        $validatedArtifacts += [ordered]@{
            path = $artifactPath
            sha256 = $actualHash
            size_bytes = [long](Get-Item -LiteralPath $artifactPath).Length
        }
    }

    return [ordered]@{
        path = [System.IO.Path]::GetFullPath($ManifestPath)
        sha256 = Get-Sha256 -Path $ManifestPath
        inputs_lock = [ordered]@{
            path = [System.IO.Path]::GetFullPath($InputsLockPath)
            sha256 = $inputsLockHash
        }
        artifacts = $validatedArtifacts
    }
}

function Get-GitMetadata {
    $commit = (& git -C $script:RepositoryRoot rev-parse HEAD 2>$null)
    Assert-Condition ($LASTEXITCODE -eq 0) "Unable to read Git commit from '$script:RepositoryRoot'."
    $status = @(& git -C $script:RepositoryRoot status --porcelain 2>$null)
    Assert-Condition ($LASTEXITCODE -eq 0) "Unable to read Git status from '$script:RepositoryRoot'."
    return [ordered]@{
        commit = ([string]$commit).Trim()
        dirty = ($status.Count -gt 0)
    }
}

function Get-ActivePowerPlan {
    $output = @(& powercfg.exe /getactivescheme 2>&1 | ForEach-Object { $_.ToString() })
    Assert-Condition ($LASTEXITCODE -eq 0) 'Unable to query the active Windows power plan.'
    return ($output -join ' ').Trim()
}

function Get-ExistingParentPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $candidate = [System.IO.Path]::GetFullPath($Path)
    while (-not (Test-Path -LiteralPath $candidate)) {
        $parent = Split-Path -Parent $candidate
        Assert-Condition (-not [string]::IsNullOrWhiteSpace($parent)) "No existing parent directory exists for '$Path'."
        Assert-Condition ($parent -ne $candidate) "No existing parent directory exists for '$Path'."
        $candidate = $parent
    }
    return $candidate
}

function Invoke-RuntimePreflight {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Configuration,
        [Parameter(Mandatory = $true)]
        [string]$ResolvedQemuRoot,
        [Parameter(Mandatory = $true)]
        [string]$ResolvedOutputDirectory,
        [Parameter(Mandatory = $true)]
        [bool]$IncludeWslReference
    )

    Assert-Condition ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) 'Runtime benchmarks require Windows.'

    $qemuExecutable = Join-Path $ResolvedQemuRoot 'qemu-system-x86_64.exe'
    $qemuImgExecutable = Join-Path $ResolvedQemuRoot 'qemu-img.exe'
    $shareDirectory = Join-Path $ResolvedQemuRoot 'share'
    Assert-Condition (Test-Path -LiteralPath $qemuExecutable -PathType Leaf) "QEMU executable '$qemuExecutable' is missing."
    Assert-Condition (Test-Path -LiteralPath $qemuImgExecutable -PathType Leaf) "QEMU image tool '$qemuImgExecutable' is missing."
    Assert-Condition (Test-Path -LiteralPath $shareDirectory -PathType Container) "QEMU share directory '$shareDirectory' is missing."

    $biosCandidates = @(
        (Join-Path $shareDirectory 'bios-256k.bin'),
        (Join-Path $shareDirectory 'bios.bin')
    )
    $biosPath = $null
    foreach ($candidate in $biosCandidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $biosPath = $candidate
            break
        }
    }
    Assert-Condition ($null -ne $biosPath) "SeaBIOS firmware is missing from '$shareDirectory'."
    $edk2Path = Join-Path $shareDirectory 'edk2-x86_64-code.fd'
    Assert-Condition (Test-Path -LiteralPath $edk2Path -PathType Leaf) "EDK2 firmware '$edk2Path' is missing."
    $edk2VarsPath = Join-Path $shareDirectory 'edk2-i386-vars.fd'
    Assert-Condition (Test-Path -LiteralPath $edk2VarsPath -PathType Leaf) "EDK2 NVRAM template '$edk2VarsPath' is missing."

    $guestManifestPath = Join-Path $PSScriptRoot 'out\guest\manifest.json'
    $inputsLockPath = Join-Path $PSScriptRoot 'guest\inputs.lock.json'
    $guestArtifacts = Test-GuestArtifactManifest -ManifestPath $guestManifestPath -InputsLockPath $inputsLockPath

    Assert-Condition (Test-IsAdministrator) 'Runtime preflight must run from an elevated PowerShell session.'

    foreach ($commandName in @(
        'Get-WindowsOptionalFeature',
        'Get-VM',
        'New-VM',
        'Remove-VM',
        'Start-VM',
        'Stop-VM',
        'Get-VMHost',
        'Get-VMSwitch',
        'New-VMSwitch',
        'Remove-VMSwitch',
        'New-VHD',
        'Get-VMNetworkAdapter',
        'Remove-VMNetworkAdapter',
        'Connect-VMNetworkAdapter',
        'Get-NetAdapter',
        'New-NetIPAddress',
        'Get-NetFirewallRule',
        'New-NetFirewallRule',
        'Remove-NetFirewallRule'
    )) {
        Assert-Condition ($null -ne (Get-Command $commandName -ErrorAction SilentlyContinue)) "Required command '$commandName' is unavailable."
    }
    Assert-Condition ($null -ne (Get-Command 'wsl.exe' -ErrorAction SilentlyContinue)) 'wsl.exe is unavailable.'
    $xorrisoProbe = @(& wsl.exe -d Ubuntu-24.04 -u root -- sh -lc 'command -v xorriso' 2>&1 | ForEach-Object { $_.ToString() })
    Assert-Condition ($LASTEXITCODE -eq 0) "Ubuntu-24.04 WSL does not provide xorriso: $($xorrisoProbe -join ' ')"

    $whpxFeatureState = Get-OptionalFeatureState -FeatureName 'HypervisorPlatform'
    $hyperVFeatureState = Get-OptionalFeatureState -FeatureName 'Microsoft-Hyper-V-All'
    Assert-Condition ($hyperVFeatureState -eq 'Enabled') "Hyper-V is '$hyperVFeatureState', not Enabled."

    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
    $processors = @(Get-CimInstance -ClassName Win32_Processor)
    Assert-Condition ([bool]$computerSystem.HypervisorPresent) 'The Windows hypervisor is not present.'

    $wslOutput = @(& wsl.exe --status 2>&1 | ForEach-Object { $_.ToString() })
    Assert-Condition ($LASTEXITCODE -eq 0) "WSL status failed: $($wslOutput -join ' ')"

    $freeMemoryMib = [Math]::Floor([double]$operatingSystem.FreePhysicalMemory / 1024)
    Assert-Condition ($freeMemoryMib -ge [double]$Configuration.defaults.minimum_free_memory_mib) "Only $freeMemoryMib MiB host memory is free; $($Configuration.defaults.minimum_free_memory_mib) MiB is required."

    $existingOutputParent = Get-ExistingParentPath -Path $ResolvedOutputDirectory
    $outputRoot = [System.IO.Path]::GetPathRoot($existingOutputParent)
    $driveName = $outputRoot.TrimEnd('\').TrimEnd(':')
    $outputDrive = Get-PSDrive -Name $driveName
    $freeDiskGib = [Math]::Floor([double]$outputDrive.Free / 1GB)
    Assert-Condition ($freeDiskGib -ge [double]$Configuration.defaults.minimum_free_disk_gib) "Only $freeDiskGib GiB is free on '$outputRoot'; $($Configuration.defaults.minimum_free_disk_gib) GiB is required."

    $acceleratorProbe = Invoke-QemuProbe -Executable $qemuExecutable -Arguments @('-accel', 'help')
    Assert-Condition ($acceleratorProbe.output -match '(?m)^\s*tcg\s*$') 'QEMU does not list the TCG accelerator.'
    Assert-Condition ($acceleratorProbe.output -match '(?m)^\s*whpx\s*$') 'QEMU does not list the WHPX accelerator.'

    $networkProbe = Invoke-QemuProbe -Executable $qemuExecutable -Arguments @('-machine', 'none', '-accel', 'tcg', '-netdev', 'help')
    Assert-Condition ($networkProbe.output -match '(?m)^\s*user\s*$') 'QEMU does not list the slirp user netdev.'

    $versionProbe = Invoke-QemuProbe -Executable $qemuExecutable -Arguments @('--version')
    Assert-Condition ($versionProbe.exit_code -eq 0) "QEMU version probe failed with exit code $($versionProbe.exit_code)."
    $iperfMetadata = Get-BenchmarkIperfMetadata
    $wslReferenceMetadata = if ($IncludeWslReference) {
        Get-WslSysbenchMetadata
    } else {
        $null
    }

    return [ordered]@{
        host = [ordered]@{
            windows_caption = [string]$operatingSystem.Caption
            windows_version = [string]$operatingSystem.Version
            windows_build = [string]$operatingSystem.BuildNumber
            computer_model = [string]$computerSystem.Model
            logical_processors = [int]$computerSystem.NumberOfLogicalProcessors
            total_memory_mib = [long][Math]::Floor([double]$computerSystem.TotalPhysicalMemory / 1MB)
            free_memory_mib = [long]$freeMemoryMib
            cpu = @($processors | ForEach-Object {
                [ordered]@{
                    name = ([string]$_.Name).Trim()
                    cores = [int]$_.NumberOfCores
                    logical_processors = [int]$_.NumberOfLogicalProcessors
                    max_clock_mhz = [int]$_.MaxClockSpeed
                    virtualization_firmware_enabled = [bool]$_.VirtualizationFirmwareEnabled
                }
            })
            hypervisor_present = [bool]$computerSystem.HypervisorPresent
            whpx_feature_state = $whpxFeatureState
            hyperv_feature_state = $hyperVFeatureState
            active_power_plan = Get-ActivePowerPlan
            free_result_disk_gib = [long]$freeDiskGib
            wsl_status = ($wslOutput -join [Environment]::NewLine)
        }
        qemu = [ordered]@{
            root = $ResolvedQemuRoot
            executable = $qemuExecutable
            image_tool = $qemuImgExecutable
            version = $versionProbe.output.Trim()
            sha256 = Get-Sha256 -Path $qemuExecutable
            accelerator_probe = $acceleratorProbe.output
            network_probe = $networkProbe.output
            firmware = [ordered]@{
                seabios = [ordered]@{
                    path = $biosPath
                    sha256 = Get-Sha256 -Path $biosPath
                }
                edk2 = [ordered]@{
                    path = $edk2Path
                    sha256 = Get-Sha256 -Path $edk2Path
                    vars_path = $edk2VarsPath
                    vars_sha256 = Get-Sha256 -Path $edk2VarsPath
                }
            }
        }
        host_tools = [ordered]@{
            iperf3 = $iperfMetadata
        }
        wsl_reference = $wslReferenceMetadata
        guest_artifacts = $guestArtifacts
    }
}

function Write-JsonAtomic {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Value,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $temporaryPath = "$Path.tmp-$([Guid]::NewGuid().ToString('N'))"
    try {
        $Value | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $temporaryPath -Encoding UTF8
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
        } else {
            [IO.File]::Move($temporaryPath, $Path)
        }
    } finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

. (Join-Path $PSScriptRoot 'lib\Common.ps1')
. (Join-Path $PSScriptRoot 'lib\Qemu.ps1')
. (Join-Path $PSScriptRoot 'lib\HyperV.ps1')
. (Join-Path $PSScriptRoot 'lib\Wsl.ps1')

Assert-Condition (Test-Path -LiteralPath $script:ConfigPath -PathType Leaf) "Configuration file '$script:ConfigPath' is missing."
$configuration = Get-Content -LiteralPath $script:ConfigPath -Raw | ConvertFrom-Json
Test-BenchmarkConfiguration -Configuration $configuration
$profileConfig = Get-ProfileConfig -Configuration $configuration -Name $Profile

$isWhatIf = [bool]$WhatIfPreference
Assert-Condition (-not $RetryFailed -or $Resume) '-RetryFailed requires -Resume.'
$hostLogicalProcessors = [Environment]::ProcessorCount
$matrix = Expand-BenchmarkMatrix -Configuration $configuration -ProfileName $Profile -HostLogicalProcessors $hostLogicalProcessors -AddWslReference ([bool]$IncludeWslReference)

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    if ($isWhatIf) {
        $OutputDirectory = Join-Path $PSScriptRoot 'results\generated-run-id'
    } else {
        $runTimestamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
        $OutputDirectory = Join-Path $PSScriptRoot "results\$runTimestamp"
    }
}
$resolvedOutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)

if ($isWhatIf) {
    [ordered]@{
        schema = 1
        mode = 'what-if'
        profile = $Profile
        description = [string]$profileConfig.description
        host_logical_processors = $hostLogicalProcessors
        run_order_seed = [int]$configuration.defaults.run_order_seed
        warmups = [int]$profileConfig.warmups
        repetitions = [int]$profileConfig.repetitions
        output_directory = $resolvedOutputDirectory
        include_wsl_reference = [bool]$IncludeWslReference
        planned_cells = @($matrix | Where-Object { $_.status -eq 'planned' }).Count
        skipped_cells = @($matrix | Where-Object { $_.status -eq 'skipped' }).Count
        cells = $matrix
    } | ConvertTo-Json -Depth 100
    return
}

$runnerLockPath = Join-Path $PSScriptRoot 'out\runner.lock'
$runnerLock = $null
$sleepInhibited = $false
try {
    New-Item -ItemType Directory -Path (Split-Path -Parent $runnerLockPath) -Force | Out-Null
    try {
        $runnerLock = [IO.FileStream]::new(
            $runnerLockPath,
            [IO.FileMode]::OpenOrCreate,
            [IO.FileAccess]::ReadWrite,
            [IO.FileShare]::None
        )
    } catch [IO.IOException] {
        throw "Benchmark error: Another benchmark runner is active and owns '$runnerLockPath'."
    }
    Set-BenchmarkSleepInhibition -Enabled $true
    $sleepInhibited = $true

    Assert-Condition (-not [string]::IsNullOrWhiteSpace($QemuRoot)) '-QemuRoot is required unless -WhatIf is used.'
    $resolvedQemuRoot = [System.IO.Path]::GetFullPath($QemuRoot)
    $runtime = Invoke-RuntimePreflight -Configuration $configuration -ResolvedQemuRoot $resolvedQemuRoot `
        -ResolvedOutputDirectory $resolvedOutputDirectory -IncludeWslReference ([bool]$IncludeWslReference)
    $configurationHash = Get-Sha256 -Path $script:ConfigPath
    $gitMetadata = Get-GitMetadata
    $schedule = @(New-BenchmarkSchedule -Matrix $matrix -Seed ([int]$configuration.defaults.run_order_seed))

    if ($CleanupStale) {
        Remove-StaleQemuBenchmarkResources
        Remove-StaleHyperVBenchmarkResources
    }
    $staleResources = @()
    $staleResources += @(Get-StaleQemuBenchmarkResources)
    $staleResources += @(Get-StaleHyperVBenchmarkResources)
    $staleDescriptions = @($staleResources | ForEach-Object { "$($_.type):$($_.name)" })
    Assert-Condition ($staleResources.Count -eq 0) "Stale benchmark resources are present: $($staleDescriptions -join ', '). Use -CleanupStale to remove them."

    $manifestPath = Join-Path $resolvedOutputDirectory 'manifest.json'
    if ($Resume) {
    Assert-Condition (Test-Path -LiteralPath $manifestPath -PathType Leaf) "Cannot resume because '$manifestPath' does not exist."
    $existingManifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    Assert-Condition ($existingManifest.schema -eq 1) 'Existing manifest has an unsupported schema.'
    Assert-Condition ($null -ne $existingManifest.PSObject.Properties['session_id']) 'Existing manifest predates Phase 3 orchestration and cannot be resumed.'
    Assert-Condition ([string]$existingManifest.profile -eq $Profile) 'Existing manifest profile does not match the requested profile.'
    Assert-Condition ([string]$existingManifest.configuration.sha256 -eq $configurationHash) 'Existing manifest configuration hash does not match.'
    Assert-Condition ([string]$existingManifest.qemu.sha256 -eq [string]$runtime.qemu.sha256) 'Existing manifest QEMU hash does not match.'
    Assert-Condition ([string]$existingManifest.host_tools.iperf3.sha256 -eq [string]$runtime.host_tools.iperf3.sha256) 'Existing manifest host iperf3 hash does not match.'
    Assert-Condition ([string]$existingManifest.guest_artifacts.sha256 -eq [string]$runtime.guest_artifacts.sha256) 'Existing manifest guest artifact hash does not match.'
    Assert-Condition ([bool]$existingManifest.options.include_wsl_reference -eq [bool]$IncludeWslReference) 'Existing manifest WSL-reference option does not match.'
    if ($IncludeWslReference) {
        Assert-Condition ([string]$existingManifest.wsl_reference.version -eq [string]$runtime.wsl_reference.version) 'Existing manifest WSL sysbench version does not match.'
    }
    $expectedRunIds = @($schedule | ForEach-Object { [string]$_.run_id })
    $existingRunIds = @($existingManifest.run_order | ForEach-Object { [string]$_.run_id })
    Assert-Condition (($expectedRunIds -join "`n") -eq ($existingRunIds -join "`n")) 'Existing manifest run order does not match the requested matrix.'
    $manifest = $existingManifest
    $sessionId = [string]$manifest.session_id
    } else {
    Assert-Condition (-not (Test-Path -LiteralPath $resolvedOutputDirectory)) "Output directory '$resolvedOutputDirectory' already exists. Use -Resume or choose a new directory."
    $sessionId = New-BenchmarkSessionId
    $manifest = [ordered]@{
        schema = 1
        created_utc = [DateTime]::UtcNow.ToString('o')
        session_id = $sessionId
        profile = $Profile
        configuration = [ordered]@{
            path = $script:ConfigPath
            sha256 = $configurationHash
            run_order_seed = [int]$configuration.defaults.run_order_seed
            ram_mib = [int]$configuration.defaults.ram_mib
            warmups = [int]$profileConfig.warmups
            repetitions = [int]$profileConfig.repetitions
        }
        options = [ordered]@{
            include_wsl_reference = [bool]$IncludeWslReference
            keep_artifacts_on_failure = [bool]$KeepArtifactsOnFailure
            cleanup_stale = [bool]$CleanupStale
            prevent_system_sleep = $true
            maximum_run_attempts = 3
        }
        repository = $gitMetadata
        host = $runtime.host
        qemu = $runtime.qemu
        host_tools = $runtime.host_tools
        wsl_reference = $runtime.wsl_reference
        guest_artifacts = $runtime.guest_artifacts
        runner_templates = [ordered]@{
            qemu = [ordered]@{
                common = @('-name', '<resource>', '-accel', '<explicit-accelerator>', '-m', '<ram-mib>', '-smp', '<vcpus>', '-display', 'none', '-monitor', 'none', '-serial', 'file:<serial-log>', '-no-reboot')
                micro = @('-machine', 'pc', '-nic', 'none', '-boot', 'd', '-cdrom', '<derived-micro-iso>')
                system = @('-machine', 'q35', '-drive', 'if=pflash,unit=0,format=raw,readonly=on,file=<edk2-code>', '-drive', 'if=pflash,unit=1,format=raw,file=<edk2-vars-clone>', '-drive', 'file=<system-overlay>,format=qcow2,if=none,id=os', '-device', 'virtio-blk-pci,drive=os,bootindex=1', '-drive', 'file=<config-iso>,format=raw,media=cdrom,readonly=on', '-netdev', 'user,id=net0', '-device', 'virtio-net-pci,netdev=net0')
                accelerators = @($configuration.environments | Where-Object { $_.runner -eq 'qemu' } | ForEach-Object {
                    [ordered]@{
                        environment = [string]$_.id
                        argument = [string]$_.accelerator
                    }
                })
            }
            hyperv = [ordered]@{
                micro_generation = 1
                system_generation = 2
                secure_boot = $false
                memory_mode = 'static'
                serial = 'COM1 named pipe'
            }
            wsl = [ordered]@{
                distribution = 'Ubuntu-24.04'
                tool = 'sysbench 1.0.20'
                reference_only = $true
            }
        }
        matrix = [ordered]@{
            planned_cells = @($matrix | Where-Object { $_.status -eq 'planned' }).Count
            skipped_cells = @($matrix | Where-Object { $_.status -eq 'skipped' }).Count
            cells = $matrix
        }
        run_order = @($schedule | ForEach-Object {
            [ordered]@{
                run_id = [string]$_.run_id
                schedule_index = [int]$_.schedule_index
                cell_id = [string]$_.cell.cell_id
                environment = [string]$_.cell.environment
                is_warmup = [bool]$_.is_warmup
                repetition = [int]$_.repetition
            }
        })
    }
    New-Item -ItemType Directory -Path $resolvedOutputDirectory | Out-Null
    Write-JsonAtomic -Value $manifest -Path $manifestPath
    }

    $runsPath = Join-Path $resolvedOutputDirectory 'runs.jsonl'
    $statePath = Join-Path $resolvedOutputDirectory 'state.json'
    $records = @(Read-BenchmarkRunRecords -Path $runsPath)
    $failedRecordsRetried = 0
    if ($RetryFailed) {
        $failedRecords = @($records | Where-Object { $_.status -eq 'error' })
        if ($failedRecords.Count -gt 0) {
            $failedArchiveDirectory = Join-Path $resolvedOutputDirectory 'failed-runs'
            New-Item -ItemType Directory -Path $failedArchiveDirectory -Force | Out-Null
            $failedArchivePath = Join-Path $failedArchiveDirectory (
                "{0}.jsonl" -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
            )
            foreach ($failedRecord in $failedRecords) {
                Write-BenchmarkJsonLine -Value $failedRecord -Path $failedArchivePath
            }

            $records = @($records | Where-Object { $_.status -ne 'error' })
            $temporaryRunsPath = "$runsPath.retry"
            Write-Utf8NoBom -Path $temporaryRunsPath -Value ''
            foreach ($record in $records) {
                Write-BenchmarkJsonLine -Value $record -Path $temporaryRunsPath
            }
            $backupRunsPath = "$runsPath.backup"
            [IO.File]::Replace($temporaryRunsPath, $runsPath, $backupRunsPath)
            Remove-Item -LiteralPath $backupRunsPath -Force
            Write-BenchmarkState -Records $records -Path $statePath
            $failedRecordsRetried = $failedRecords.Count
        }
    }
    $completedRunIds = @{}
    foreach ($record in $records) {
        $completedRunIds[[string]$record.run_id] = $true
    }

    $executedRuns = 0
    $executedAttempts = 0
    foreach ($run in $schedule) {
    if ($completedRunIds.ContainsKey([string]$run.run_id)) {
        continue
    }

    $attemptErrors = @()
    $attempt = 0
    do {
        $attempt++
        $executedAttempts++
        $runnerResult = switch ([string]$run.cell.runner) {
            'qemu' {
                Invoke-QemuBenchmarkRun -Run $run -Runtime $runtime -OutputDirectory $resolvedOutputDirectory `
                    -SessionId $sessionId -KeepArtifactsOnFailure ([bool]$KeepArtifactsOnFailure)
                break
            }
            'hyperv' {
                Invoke-HyperVBenchmarkRun -Run $run -Runtime $runtime -OutputDirectory $resolvedOutputDirectory `
                    -SessionId $sessionId -KeepArtifactsOnFailure ([bool]$KeepArtifactsOnFailure)
                break
            }
            'wsl' {
                Invoke-WslBenchmarkRun -Run $run -OutputDirectory $resolvedOutputDirectory
                break
            }
            default {
                throw "Benchmark error: Unsupported runner '$($run.cell.runner)'."
            }
        }

        $cleanupSucceeded = Test-BenchmarkCleanupSucceeded -RunnerResult $runnerResult
        if (-not $cleanupSucceeded -and $runnerResult.status -eq 'success') {
            $runnerResult.status = 'error'
            $runnerResult.error = 'Runner cleanup did not complete.'
        }

        $shouldRetry = $cleanupSucceeded -and
            $attempt -lt 3 -and
            (Test-BenchmarkRetryableFailure -RunnerResult $runnerResult)
        if ($shouldRetry) {
            $attemptErrors += [ordered]@{
                attempt = $attempt
                error = [string]$runnerResult.error
                completed_utc = [string]$runnerResult.completed_utc
            }
            Save-BenchmarkRetryArtifacts -Run $run -RunnerResult $runnerResult `
                -OutputDirectory $resolvedOutputDirectory -Attempt $attempt
            Start-Sleep -Seconds 1
        }
    } while ($shouldRetry)

    $serialResult = $runnerResult.serial_result
    $startedUtc = [DateTime]::Parse([string]$runnerResult.started_utc)
    $completedUtc = [DateTime]::Parse([string]$runnerResult.completed_utc)
    $execution = if ($runnerResult.runner -eq 'qemu') {
        [ordered]@{
            executable = [string]$runnerResult.executable
            arguments = @($runnerResult.arguments)
        }
    } else {
        $runnerResult.configuration
    }
    $execution.attempt_count = $attempt
    $execution.retry_errors = $attemptErrors

    $normalizedRecord = [ordered]@{
        schema = 1
        run_id = [string]$run.run_id
        schedule_index = [int]$run.schedule_index
        cell_id = [string]$run.cell.cell_id
        workload = [string]$run.cell.workload
        guest = [string]$run.cell.guest
        environment = [string]$run.cell.environment
        runner = [string]$run.cell.runner
        accelerator = $run.cell.accelerator
        vcpus = [int]$run.cell.vcpus
        ram_mib = [int]$run.cell.ram_mib
        is_warmup = [bool]$run.is_warmup
        repetition = [int]$run.repetition
        metric_direction = [string]$run.cell.metric_direction
        parameters = $run.cell.parameters
        status = [string]$runnerResult.status
        error = $runnerResult.error
        started_utc = $startedUtc.ToString('o')
        completed_utc = $completedUtc.ToString('o')
        duration_seconds = ($completedUtc - $startedUtc).TotalSeconds
        host_timing = [ordered]@{
            first_serial_seconds = if ($null -eq $serialResult) { $null } else { $serialResult.first_serial_seconds }
            ready_seconds = if ($null -eq $serialResult) { $null } else { $serialResult.ready_seconds }
        }
        primary_result = $runnerResult.target_result
        guest_records = if ($null -eq $serialResult) { @() } else { @($serialResult.guest_records) }
        execution = $execution
        serial_path = $runnerResult.serial_path
        raw_directory = $runnerResult.raw_directory
        cleanup = $runnerResult.cleanup
    }

    Write-BenchmarkJsonLine -Value $normalizedRecord -Path $runsPath
    $records += [pscustomobject]$normalizedRecord
    $completedRunIds[[string]$run.run_id] = $true
    Write-BenchmarkState -Records $records -Path $statePath
    $executedRuns++
    }

    $failedRuns = @($records | Where-Object { $_.status -eq 'error' }).Count
    [ordered]@{
        status = if ($failedRuns -eq 0) { 'complete' } else { 'complete-with-errors' }
        manifest = $manifestPath
        runs = $runsPath
        state = $statePath
        planned_cells = [int]$manifest.matrix.planned_cells
        skipped_cells = [int]$manifest.matrix.skipped_cells
        total_runs = $schedule.Count
        completed_runs = $records.Count
        executed_runs = $executedRuns
        executed_attempts = $executedAttempts
        failed_records_retried = $failedRecordsRetried
        failed_runs = $failedRuns
    } | ConvertTo-Json -Depth 10
} finally {
    if ($sleepInhibited) {
        try {
            Set-BenchmarkSleepInhibition -Enabled $false
        } catch {
        }
    }
    if ($null -ne $runnerLock) {
        $runnerLock.Dispose()
    }
    Remove-Item -LiteralPath $runnerLockPath -Force -ErrorAction SilentlyContinue
}
