Set-StrictMode -Version Latest

function ConvertTo-BenchmarkToken {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value,
        [int]$MaximumLength = 96
    )

    $token = ($Value -replace '[^A-Za-z0-9._-]', '-').Trim('-')
    Assert-Condition (-not [string]::IsNullOrWhiteSpace($token)) "Value '$Value' cannot form a benchmark token."
    if ($token.Length -gt $MaximumLength) {
        $token = $token.Substring(0, $MaximumLength).TrimEnd('-')
    }
    return $token
}

function New-BenchmarkSessionId {
    return "$([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ'))-$([Guid]::NewGuid().ToString('N').Substring(0, 8))"
}

function Get-BenchmarkShortHash {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value,
        [int]$Length = 12
    )

    $hasher = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Value)
        $digest = $hasher.ComputeHash($bytes)
        $hex = ([BitConverter]::ToString($digest)).Replace('-', '').ToLowerInvariant()
        return $hex.Substring(0, $Length)
    } finally {
        $hasher.Dispose()
    }
}

function Get-BenchmarkRunId {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Cell,
        [Parameter(Mandatory = $true)]
        [bool]$IsWarmup,
        [Parameter(Mandatory = $true)]
        [int]$Repetition
    )

    $kind = if ($IsWarmup) { 'warmup' } else { 'measure' }
    return ConvertTo-BenchmarkToken -Value "$($Cell.cell_id)__$kind-$('{0:D2}' -f $Repetition)"
}

function New-BenchmarkSchedule {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Matrix,
        [Parameter(Mandatory = $true)]
        [int]$Seed
    )

    $groups = [ordered]@{}
    foreach ($cell in @($Matrix | Where-Object { $_.status -eq 'planned' })) {
        $key = "$($cell.workload)|$($cell.guest)|$($cell.vcpus)"
        if (-not $groups.Contains($key)) {
            $groups[$key] = @()
        }
        $groups[$key] = @($groups[$key]) + $cell
    }

    $schedule = @()
    foreach ($groupEntry in $groups.GetEnumerator()) {
        $cells = @($groupEntry.Value)
        Assert-Condition ($cells.Count -gt 0) "Schedule group '$($groupEntry.Key)' is empty."
        $totalRuns = [int]$cells[0].total_runs
        foreach ($cell in $cells) {
            Assert-Condition ([int]$cell.total_runs -eq $totalRuns) "Schedule group '$($groupEntry.Key)' has inconsistent run counts."
        }

        for ($runIndex = 0; $runIndex -lt $totalRuns; $runIndex++) {
            $offset = (($Seed + $runIndex) % $cells.Count + $cells.Count) % $cells.Count
            for ($environmentIndex = 0; $environmentIndex -lt $cells.Count; $environmentIndex++) {
                $cell = $cells[($environmentIndex + $offset) % $cells.Count]
                $isWarmup = $runIndex -lt [int]$cell.warmups
                $repetition = if ($isWarmup) {
                    $runIndex + 1
                } else {
                    $runIndex - [int]$cell.warmups + 1
                }
                $schedule += [ordered]@{
                    run_id = Get-BenchmarkRunId -Cell $cell -IsWarmup $isWarmup -Repetition $repetition
                    cell = $cell
                    is_warmup = $isWarmup
                    repetition = $repetition
                    schedule_index = $schedule.Count
                }
            }
        }
    }
    return $schedule
}

function Get-BenchmarkArtifactPath {
    param(
        [Parameter(Mandatory = $true)]
        [object]$GuestArtifacts,
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )

    $artifact = @($GuestArtifacts.artifacts | Where-Object {
        [IO.Path]::GetFileName([string]$_.path) -eq $FileName
    })
    Assert-Condition ($artifact.Count -eq 1) "Guest artifact '$FileName' was not found exactly once."
    return [string]$artifact[0].path
}

function New-BenchmarkDifferencingVhdx {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ParentPath,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Assert-Condition (Test-Path -LiteralPath $ParentPath -PathType Leaf) "VHDX parent '$ParentPath' is missing."
    Assert-Condition (-not (Test-Path -LiteralPath $Path)) "VHDX child '$Path' already exists."
    New-VHD -Path $Path -ParentPath $ParentPath -Differencing | Out-Null
    Assert-Condition (Test-Path -LiteralPath $Path -PathType Leaf) "Differencing VHDX '$Path' was not created."
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    [IO.File]::WriteAllText($Path, $Value, [Text.UTF8Encoding]::new($false))
}

function Remove-BenchmarkDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [int]$TimeoutSeconds = 10
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
        if (-not (Test-Path -LiteralPath $Path)) {
            return $true
        }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)
    return -not (Test-Path -LiteralPath $Path)
}

function Write-BenchmarkJsonLine {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Value,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $json = $Value | ConvertTo-Json -Depth 100 -Compress
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes("$json`n")
    $stream = [IO.FileStream]::new(
        $Path,
        [IO.FileMode]::Append,
        [IO.FileAccess]::Write,
        [IO.FileShare]::Read
    )
    try {
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
    } finally {
        $stream.Dispose()
    }
}

function Read-BenchmarkRunRecords {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $records = @()
    $runIds = @{}
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $records
    }

    $lineNumber = 0
    foreach ($line in [IO.File]::ReadLines($Path)) {
        $lineNumber++
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        try {
            $record = $line | ConvertFrom-Json
        } catch {
            throw "Benchmark error: Invalid JSON in '$Path' at line $lineNumber`: $($_.Exception.Message)"
        }
        Assert-Condition ($record.schema -eq 1) "Run record '${Path}:$lineNumber' has an unsupported schema."
        Assert-Condition (-not [string]::IsNullOrWhiteSpace([string]$record.run_id)) "Run record '${Path}:$lineNumber' has no run ID."
        Assert-Condition (-not $runIds.ContainsKey([string]$record.run_id)) "Run ID '$($record.run_id)' appears more than once in '$Path'."
        $runIds[[string]$record.run_id] = $true
        $records += $record
    }
    return $records
}

function Write-BenchmarkState {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Records,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $state = [ordered]@{
        schema = 1
        updated_utc = [DateTime]::UtcNow.ToString('o')
        completed_run_ids = @($Records | ForEach-Object { [string]$_.run_id })
        successful_runs = @($Records | Where-Object { $_.status -eq 'success' }).Count
        failed_runs = @($Records | Where-Object { $_.status -eq 'error' }).Count
    }
    Write-JsonAtomic -Value $state -Path $Path
}

function ConvertTo-WslPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$Distribution = 'Ubuntu-24.04'
    )

    $fullPath = [IO.Path]::GetFullPath($Path)
    Assert-Condition ($fullPath -match '^([A-Za-z]):\\(.*)$') "Only local drive paths can be translated to WSL: '$fullPath'."
    $drive = $Matches[1].ToLowerInvariant()
    $relative = $Matches[2].Replace('\', '/')
    return "/mnt/$drive/$relative"
}

function Invoke-BenchmarkWslTool {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [string]$Distribution = 'Ubuntu-24.04'
    )

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& wsl.exe -d $Distribution -u root -- @Arguments 2>&1 | ForEach-Object { $_.ToString() })
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    Assert-Condition ($LASTEXITCODE -eq 0) "WSL command failed: $($Arguments -join ' ')`n$($output -join [Environment]::NewLine)"
    return $output
}

function New-BenchmarkConfigIso {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Job,
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        [string]$Distribution = 'Ubuntu-24.04'
    )

    $root = Join-Path (Split-Path -Parent $OutputPath) 'config-root'
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $root -Force | Out-Null

    $lines = @()
    foreach ($entry in $Job.GetEnumerator()) {
        $key = [string]$entry.Key
        $value = [string]$entry.Value
        Assert-Condition ($key -match '^[a-z][a-z0-9_]*$') "Invalid job key '$key'."
        Assert-Condition ($value -match '^[A-Za-z0-9._:/-]+$') "Invalid value for job key '$key'."
        $lines += "$key=$value"
    }
    Write-Utf8NoBom -Path (Join-Path $root 'job.conf') -Value (($lines -join "`n") + "`n")

    $wslRoot = ConvertTo-WslPath -Path $root -Distribution $Distribution
    $wslOutput = ConvertTo-WslPath -Path $OutputPath -Distribution $Distribution
    Invoke-BenchmarkWslTool -Distribution $Distribution -Arguments @(
        'xorriso', '-as', 'mkisofs', '-quiet', '-V', 'BENCHCFG', '-o', $wslOutput, $wslRoot
    ) | Out-Null
    Assert-Condition (Test-Path -LiteralPath $OutputPath -PathType Leaf) "Config ISO '$OutputPath' was not created."
}

function New-BenchmarkMicroIso {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseIsoPath,
        [Parameter(Mandatory = $true)]
        [object]$Run,
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        [string]$Distribution = 'Ubuntu-24.04'
    )

    $cell = $Run.cell
    $parameters = $cell.parameters
    $workload = [string]$cell.workload
    $guestWorkload = if ($workload -eq 'minimal-boot') { 'prime-v1' } else { $workload }
    $arguments = @(
        "bench.run_id=$($Run.run_id)",
        "bench.workloads=$guestWorkload"
    )
    if ($workload -eq 'prime-smp') {
        $arguments += "bench.prime_limit=$([int]$parameters.prime_limit)"
    }
    if ($workload -like 'memory-*') {
        $arguments += "bench.memory_mib=$([int]$parameters.working_set_mib)"
        $arguments += "bench.duration=$([int]$parameters.duration_seconds)"
    }

    $configPath = Join-Path (Split-Path -Parent $OutputPath) 'isolinux.cfg'
    $config = @"
SERIAL 0 38400
CONSOLE 0
PROMPT 0
TIMEOUT 1
DEFAULT benchmark

LABEL benchmark
    KERNEL /boot/vmlinuz-virt
    APPEND initrd=/boot/initramfs.cpio.gz console=ttyS0,38400n8 loglevel=4 $($arguments -join ' ')
"@
    Write-Utf8NoBom -Path $configPath -Value ($config.Replace("`r`n", "`n"))

    $wslBase = ConvertTo-WslPath -Path $BaseIsoPath -Distribution $Distribution
    $wslConfig = ConvertTo-WslPath -Path $configPath -Distribution $Distribution
    $wslOutput = ConvertTo-WslPath -Path $OutputPath -Distribution $Distribution
    Invoke-BenchmarkWslTool -Distribution $Distribution -Arguments @(
        'xorriso',
        '-abort_on', 'FAILURE',
        '-overwrite', 'on',
        '-indev', $wslBase,
        '-outdev', $wslOutput,
        '-boot_image', 'any', 'replay',
        '-map', $wslConfig, '/isolinux/isolinux.cfg'
    ) | Out-Null
    Assert-Condition (Test-Path -LiteralPath $OutputPath -PathType Leaf) "Derived micro ISO '$OutputPath' was not created."
}

function Get-SystemBenchmarkJob {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Run,
        [Parameter(Mandatory = $true)]
        [ValidateSet('qemu', 'hyperv')]
        [string]$Runner,
        [string]$HostIp,
        [string]$GuestIp
    )

    $cell = $Run.cell
    $parameters = $cell.parameters
    $job = [ordered]@{
        schema = 1
        run_id = [string]$Run.run_id
        workload = [string]$cell.workload
        vcpus = [int]$cell.vcpus
    }

    switch -Wildcard ([string]$cell.workload) {
        'sysbench-cpu' {
            $job.cpu_max_prime = [int]$parameters.cpu_max_prime
            $job.duration_seconds = [int]$parameters.duration_seconds
        }
        'sysbench-memory-*' {
            $job.operation = [string]$parameters.operation
            $job.access_mode = [string]$parameters.access_mode
            $job.block_size = [string]$parameters.block_size
            $job.duration_seconds = [int]$parameters.duration_seconds
        }
        'fio-*' {
            $job.disk_device = if ($Runner -eq 'qemu') { '/dev/vdb' } else { '/dev/sdb' }
            $job.operation = [string]$parameters.rw
            $job.block_size = [string]$parameters.block_size
            $job.duration_seconds = [int]$parameters.duration_seconds
            $job.ramp_seconds = [int]$parameters.ramp_seconds
            $job.iodepth = [int]$parameters.iodepth
            $job.numjobs = [int]$parameters.numjobs
        }
        'iperf-*' {
            $job.parallel_streams = [int]$parameters.parallel_streams
            $job.duration_seconds = [int]$parameters.duration_seconds
            if (-not [string]::IsNullOrWhiteSpace($HostIp)) {
                $job.host_ip = $HostIp
            }
            if (-not [string]::IsNullOrWhiteSpace($GuestIp)) {
                $job.guest_ip = $GuestIp
                $job.prefix_length = 24
            }
        }
        'full-boot' {}
        default {
            throw "Benchmark error: Unsupported system workload '$($cell.workload)'."
        }
    }
    return $job
}

function Wait-BenchmarkSerial {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SerialPath,
        [Parameter(Mandatory = $true)]
        [string]$RunId,
        [Parameter(Mandatory = $true)]
        [DateTime]$StartedUtc,
        [Parameter(Mandatory = $true)]
        [int]$TimeoutSeconds,
        [Parameter(Mandatory = $true)]
        [scriptblock]$IsStopped,
        [scriptblock]$OnLine
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    $offset = 0L
    $buffer = ''
    $lines = [Collections.Generic.List[string]]::new()
    $guestRecords = [Collections.Generic.List[object]]::new()
    $rawRecords = [Collections.Generic.List[string]]::new()
    $firstSerialUtc = $null
    $readyUtc = $null

    while ($true) {
        if (Test-Path -LiteralPath $SerialPath -PathType Leaf) {
            $stream = [IO.FileStream]::new(
                $SerialPath,
                [IO.FileMode]::Open,
                [IO.FileAccess]::Read,
                [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete
            )
            try {
                if ($stream.Length -gt $offset) {
                    if ($null -eq $firstSerialUtc) {
                        $firstSerialUtc = [DateTime]::UtcNow
                    }
                    $null = $stream.Seek($offset, [IO.SeekOrigin]::Begin)
                    $remaining = [int]($stream.Length - $offset)
                    $bytes = [byte[]]::new($remaining)
                    $read = $stream.Read($bytes, 0, $remaining)
                    $offset += $read
                    $buffer += [Text.Encoding]::UTF8.GetString($bytes, 0, $read)
                }
            } finally {
                $stream.Dispose()
            }
        }

        while (($newline = $buffer.IndexOfAny([char[]]@("`r", "`n"))) -ge 0) {
            $line = $buffer.Substring(0, $newline)
            $buffer = $buffer.Substring($newline + 1)
            if ($buffer.StartsWith("`n", [StringComparison]::Ordinal)) {
                $buffer = $buffer.Substring(1)
            }
            $lines.Add($line)
            if ($line -eq "BENCH_READY run_id=$RunId" -or $line -like "BENCH_READY run_id=$RunId workload=*") {
                if ($null -eq $readyUtc) {
                    $readyUtc = [DateTime]::UtcNow
                }
            }
            if ($line.StartsWith('BENCH_JSON ', [StringComparison]::Ordinal)) {
                try {
                    $record = $line.Substring(11) | ConvertFrom-Json
                } catch {
                    throw "Benchmark error: Malformed BENCH_JSON for '$RunId': $line"
                }
                Assert-Condition ($record.schema -eq 1) "Guest record for '$RunId' has unsupported schema."
                $guestRecords.Add($record)
            } elseif ($line.StartsWith('BENCH_RAW_JSON ', [StringComparison]::Ordinal)) {
                $rawRecords.Add($line.Substring(15))
            }
            if ($null -ne $OnLine) {
                & $OnLine $line | Out-Null
            }
        }

        $stopped = [bool](& $IsStopped)
        if ($stopped) {
            if (-not [string]::IsNullOrEmpty($buffer)) {
                $lines.Add($buffer.TrimEnd("`r"))
                $buffer = ''
            }
            break
        }
        if ([DateTime]::UtcNow -ge $deadline) {
            throw [TimeoutException]::new("Run '$RunId' exceeded its $TimeoutSeconds second timeout.")
        }
        Start-Sleep -Milliseconds 100
    }

    return [ordered]@{
        lines = @($lines)
        guest_records = @($guestRecords)
        raw_records = @($rawRecords)
        first_serial_utc = $firstSerialUtc
        ready_utc = $readyUtc
        first_serial_seconds = if ($null -eq $firstSerialUtc) { $null } else { ($firstSerialUtc - $StartedUtc).TotalSeconds }
        ready_seconds = if ($null -eq $readyUtc) { $null } else { ($readyUtc - $StartedUtc).TotalSeconds }
    }
}

function Test-BenchmarkGuestResult {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Run,
        [Parameter(Mandatory = $true)]
        [object]$SerialResult
    )

    Assert-Condition ($null -ne $SerialResult.ready_utc) "Run '$($Run.run_id)' did not emit BENCH_READY."
    $metadata = @($SerialResult.guest_records | Where-Object { $_.workload -eq 'guest-metadata' })
    Assert-Condition ($metadata.Count -eq 1) "Run '$($Run.run_id)' did not emit exactly one guest-metadata record."
    Assert-Condition ([int]$metadata[0].value -eq [int]$Run.cell.vcpus) "Run '$($Run.run_id)' detected $($metadata[0].value) vCPUs instead of $($Run.cell.vcpus)."

    if ($Run.cell.workload -eq 'minimal-boot') {
        return [ordered]@{
            schema = 1
            run_id = [string]$Run.run_id
            workload = 'minimal-boot'
            metric = 'host_to_ready_seconds'
            value = [double]$SerialResult.ready_seconds
            unit = 'seconds'
            direction = 'lower'
            status = 'success'
        }
    }

    $target = @($SerialResult.guest_records | Where-Object { $_.workload -eq $Run.cell.workload })
    Assert-Condition ($target.Count -eq 1) "Run '$($Run.run_id)' did not emit exactly one '$($Run.cell.workload)' record."
    Assert-Condition ([string]$target[0].status -eq 'success') "Run '$($Run.run_id)' reported guest status '$($target[0].status)'."

    if ($null -ne $Run.cell.known_answer) {
        $metricName = [string]$Run.cell.known_answer.metric
        $actual = Get-ObjectProperty -InputObject $target[0] -Name $metricName
        Assert-Condition ($null -ne $actual) "Run '$($Run.run_id)' omitted known-answer metric '$metricName'."
        Assert-Condition ([double]$actual -eq [double]$Run.cell.known_answer.value) "Run '$($Run.run_id)' produced $metricName=$actual instead of $($Run.cell.known_answer.value)."
    }
    Test-BenchmarkRawResult -Run $Run -SerialResult $SerialResult -TargetResult $target[0]
    return $target[0]
}

function Test-BenchmarkRawResult {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Run,
        [Parameter(Mandatory = $true)]
        [object]$SerialResult,
        [Parameter(Mandatory = $true)]
        [object]$TargetResult
    )

    $workload = [string]$Run.cell.workload
    if ($workload -notlike 'fio-*' -and $workload -notlike 'iperf-*') {
        return
    }

    Assert-Condition ($SerialResult.raw_records.Count -eq 1) "Run '$($Run.run_id)' did not emit exactly one raw tool record."
    try {
        $raw = $SerialResult.raw_records[0] | ConvertFrom-Json
    } catch {
        throw "Benchmark error: Run '$($Run.run_id)' emitted malformed raw tool JSON."
    }

    if ($workload -like 'fio-*') {
        $property = if ([string]$Run.cell.parameters.rw -in @('read', 'randread')) { 'read' } else { 'write' }
        $rawValue = 0.0
        foreach ($job in @($raw.jobs)) {
            $rawValue += [double](Get-ObjectProperty -InputObject (Get-ObjectProperty -InputObject $job -Name $property) -Name 'bw_bytes')
        }
    } elseif ($workload -like 'iperf-guest-to-host-*') {
        $rawValue = [double]$raw.end.sum_sent.bits_per_second
    } else {
        $rawValue = [double]$raw.end.sum_received.bits_per_second
    }

    $normalizedValue = [double]$TargetResult.value
    $tolerance = [Math]::Max(0.001, [Math]::Abs($rawValue) * 1e-9)
    Assert-Condition ([Math]::Abs($rawValue - $normalizedValue) -le $tolerance) "Run '$($Run.run_id)' raw value $rawValue does not match normalized value $normalizedValue."
}

function ConvertTo-NativeArgument {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    if ($Value -notmatch '[\s"]') {
        return $Value
    }
    return '"' + ($Value -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
}

function Start-BenchmarkProcess {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$StandardOutputPath,
        [Parameter(Mandatory = $true)]
        [string]$StandardErrorPath
    )

    $argumentLine = @($Arguments | ForEach-Object { ConvertTo-NativeArgument -Value $_ }) -join ' '
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $FilePath
    $startInfo.Arguments = $argumentLine
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    Assert-Condition ($process.Start()) "Unable to start '$FilePath'."
    $process | Add-Member -NotePropertyName BenchmarkStandardOutputPath -NotePropertyValue $StandardOutputPath
    $process | Add-Member -NotePropertyName BenchmarkStandardErrorPath -NotePropertyValue $StandardErrorPath
    $process | Add-Member -NotePropertyName BenchmarkStandardOutputTask -NotePropertyValue $process.StandardOutput.ReadToEndAsync()
    $process | Add-Member -NotePropertyName BenchmarkStandardErrorTask -NotePropertyValue $process.StandardError.ReadToEndAsync()
    $process | Add-Member -NotePropertyName BenchmarkOutputCompleted -NotePropertyValue $false
    return $process
}

function Complete-BenchmarkProcess {
    param(
        [Parameter(Mandatory = $true)]
        [Diagnostics.Process]$Process
    )

    $Process.WaitForExit()
    if (-not [bool]$Process.BenchmarkOutputCompleted) {
        $standardOutput = $Process.BenchmarkStandardOutputTask.GetAwaiter().GetResult()
        $standardError = $Process.BenchmarkStandardErrorTask.GetAwaiter().GetResult()
        Write-Utf8NoBom -Path ([string]$Process.BenchmarkStandardOutputPath) -Value $standardOutput
        Write-Utf8NoBom -Path ([string]$Process.BenchmarkStandardErrorPath) -Value $standardError
        $Process.BenchmarkOutputCompleted = $true
    }
    $Process.Refresh()
    return [int]$Process.ExitCode
}

function Stop-BenchmarkProcessTree {
    param(
        [Parameter(Mandatory = $true)]
        [int]$ProcessId
    )

    $children = @(Get-CimInstance -ClassName Win32_Process -Filter "ParentProcessId=$ProcessId" -ErrorAction SilentlyContinue)
    foreach ($child in $children) {
        Stop-BenchmarkProcessTree -ProcessId ([int]$child.ProcessId)
    }
    if ($null -ne (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue)) {
        Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
        try {
            Wait-Process -Id $ProcessId -Timeout 10 -ErrorAction SilentlyContinue
        } catch {
        }
    }
}

function Start-BenchmarkPipeCapture {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PipeName,
        [Parameter(Mandatory = $true)]
        [string]$LogPath,
        [Parameter(Mandatory = $true)]
        [int]$ConnectTimeoutMilliseconds
    )

    return Start-Job -ArgumentList $PipeName, $LogPath, $ConnectTimeoutMilliseconds -ScriptBlock {
        param($PipeName, $LogPath, $ConnectTimeoutMilliseconds)

        $pipe = [IO.Pipes.NamedPipeClientStream]::new(
            '.',
            $PipeName,
            [IO.Pipes.PipeDirection]::In,
            [IO.Pipes.PipeOptions]::Asynchronous
        )
        try {
            $pipe.Connect($ConnectTimeoutMilliseconds)
            $reader = [IO.StreamReader]::new($pipe)
            $writer = [IO.StreamWriter]::new($LogPath, $false, [Text.UTF8Encoding]::new($false))
            try {
                $writer.AutoFlush = $true
                while (($line = $reader.ReadLine()) -ne $null) {
                    $writer.WriteLine($line)
                }
            } finally {
                $writer.Dispose()
                $reader.Dispose()
            }
        } finally {
            $pipe.Dispose()
        }
    }
}

function Complete-BenchmarkPipeCapture {
    param(
        [Parameter(Mandatory = $true)]
        [Management.Automation.Job]$Job
    )

    $null = Wait-Job -Job $Job -Timeout 15
    if ($Job.State -notin @('Completed', 'Failed')) {
        Stop-Job -Job $Job -ErrorAction SilentlyContinue
    }
    Receive-Job -Job $Job -Wait -ErrorAction Stop | Out-Null
    Remove-Job -Job $Job -Force
}

function Get-FreeTcpPort {
    $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
    try {
        $listener.Start()
        return ([Net.IPEndPoint]$listener.LocalEndpoint).Port
    } finally {
        $listener.Stop()
    }
}

function Get-BenchmarkIperfExecutable {
    $command = Get-Command iperf3.exe -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return [string]$command.Source
    }

    $packageRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    $candidate = @(Get-ChildItem -LiteralPath $packageRoot -Filter iperf3.exe -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like '*ar51an.iPerf3*' } |
        Sort-Object FullName -Descending |
        Select-Object -First 1)
    Assert-Condition ($candidate.Count -eq 1) 'iperf3.exe is required for networking workloads. Install ar51an.iPerf3 with winget.'
    return [string]$candidate[0].FullName
}

function Get-BenchmarkIperfMetadata {
    $path = Get-BenchmarkIperfExecutable
    $probe = Invoke-QemuProbe -Executable $path -Arguments @('--version')
    Assert-Condition ($probe.exit_code -eq 0) "iperf3 version probe failed with exit code $($probe.exit_code)."
    return [ordered]@{
        path = $path
        version = ($probe.output -split "`r?`n")[0]
        sha256 = Get-Sha256 -Path $path
    }
}

function Invoke-BenchmarkIperfClient {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HostName,
        [Parameter(Mandatory = $true)]
        [int]$Port,
        [Parameter(Mandatory = $true)]
        [int]$ParallelStreams,
        [Parameter(Mandatory = $true)]
        [int]$DurationSeconds,
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        [Parameter(Mandatory = $true)]
        [string]$ErrorPath
    )

    $iperf = Get-BenchmarkIperfExecutable
    $process = Start-BenchmarkProcess -FilePath $iperf -Arguments @(
        '-c', $HostName, '-p', [string]$Port, '-P', [string]$ParallelStreams,
        '-t', [string]$DurationSeconds, '--json'
    ) -StandardOutputPath $OutputPath -StandardErrorPath $ErrorPath
    try {
        if (-not $process.WaitForExit(($DurationSeconds + 45) * 1000)) {
            throw [TimeoutException]::new('Host iperf3 client timed out.')
        }
        $exitCode = Complete-BenchmarkProcess -Process $process
        Assert-Condition ($exitCode -eq 0) "Host iperf3 client exited with code $exitCode."
    } finally {
        if (-not $process.HasExited) {
            Stop-BenchmarkProcessTree -ProcessId $process.Id
        }
        Complete-BenchmarkProcess -Process $process | Out-Null
        $process.Dispose()
    }
}

function Start-BenchmarkIperfServer {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Port,
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        [Parameter(Mandatory = $true)]
        [string]$ErrorPath,
        [bool]$OneOff = $true
    )

    $iperf = Get-BenchmarkIperfExecutable
    $arguments = @('-s', '-p', [string]$Port)
    if ($OneOff) {
        $arguments += @('-1', '--json')
    }
    $process = Start-BenchmarkProcess -FilePath $iperf -Arguments $arguments `
        -StandardOutputPath $OutputPath -StandardErrorPath $ErrorPath
    Start-Sleep -Milliseconds 500
    Assert-Condition (-not $process.HasExited) 'Host iperf3 server exited before the guest connected.'
    return $process
}
