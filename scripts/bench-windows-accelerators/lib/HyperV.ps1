Set-StrictMode -Version Latest

function Get-BenchmarkHyperVWorkRoot {
    return Join-Path ([IO.Path]::GetTempPath()) 'qemu-bench-work'
}

function Get-StaleHyperVBenchmarkResources {
    $resources = @()
    foreach ($vm in @(Get-VM -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'qemu-bench-*' })) {
        $resources += [ordered]@{
            type = 'hyperv-vm'
            id = [string]$vm.Id
            name = [string]$vm.Name
            state = [string]$vm.State
        }
    }
    foreach ($switch in @(Get-VMSwitch -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'qemu-bench-*' })) {
        $resources += [ordered]@{
            type = 'hyperv-switch'
            id = [string]$switch.Id
            name = [string]$switch.Name
            state = 'present'
        }
    }
    foreach ($rule in @(Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like 'qemu-bench-*' })) {
        $resources += [ordered]@{
            type = 'hyperv-firewall'
            id = [string]$rule.Name
            name = [string]$rule.DisplayName
            state = [string]$rule.Enabled
        }
    }
    $workRoot = Get-BenchmarkHyperVWorkRoot
    foreach ($directory in @(Get-ChildItem -LiteralPath $workRoot -Directory -ErrorAction SilentlyContinue)) {
        $resources += [ordered]@{
            type = 'hyperv-work-directory'
            id = [string]$directory.FullName
            name = [string]$directory.Name
            state = 'present'
        }
    }
    return $resources
}

function Remove-StaleHyperVBenchmarkResources {
    foreach ($vm in @(Get-VM -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'qemu-bench-*' })) {
        if ($vm.State -ne 'Off') {
            Stop-VM -VM $vm -TurnOff -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        }
        Remove-VM -VM $vm -Force -ErrorAction SilentlyContinue
    }
    Get-NetFirewallRule -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like 'qemu-bench-*' } |
        Remove-NetFirewallRule -ErrorAction SilentlyContinue
    foreach ($switch in @(Get-VMSwitch -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'qemu-bench-*' })) {
        Remove-VMSwitch -VMSwitch $switch -Force -ErrorAction SilentlyContinue
    }
    $workRoot = Get-BenchmarkHyperVWorkRoot
    Get-ChildItem -LiteralPath $workRoot -Directory -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $workRoot -Force -ErrorAction SilentlyContinue
}

function New-BenchmarkInternalSwitch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$HostIp
    )

    Assert-Condition ($null -eq (Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue)) "Benchmark switch '$Name' already exists."
    $created = $false
    try {
        New-VMSwitch -Name $Name -SwitchType Internal | Out-Null
        $created = $true

        $adapterName = "vEthernet ($Name)"
        $deadline = [DateTime]::UtcNow.AddSeconds(30)
        do {
            $adapter = Get-NetAdapter -Name $adapterName -ErrorAction SilentlyContinue
            if ($null -ne $adapter) {
                break
            }
            Start-Sleep -Milliseconds 250
        } while ([DateTime]::UtcNow -lt $deadline)
        Assert-Condition ($null -ne $adapter) "Host adapter '$adapterName' did not appear."

        New-NetIPAddress -InterfaceAlias $adapterName -IPAddress $HostIp -PrefixLength 24 `
            -AddressFamily IPv4 -ErrorAction Stop | Out-Null
        return $adapterName
    } catch {
        if ($created) {
            $switch = Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue
            if ($null -ne $switch) {
                Remove-VMSwitch -VMSwitch $switch -Force -ErrorAction SilentlyContinue
            }
        }
        throw
    }
}

function Invoke-HyperVBenchmarkRun {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Run,
        [Parameter(Mandatory = $true)]
        [object]$Runtime,
        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory,
        [Parameter(Mandatory = $true)]
        [string]$SessionId,
        [Parameter(Mandatory = $true)]
        [bool]$KeepArtifactsOnFailure
    )

    $runId = [string]$Run.run_id
    $cell = $Run.cell
    $sessionToken = ConvertTo-BenchmarkToken -Value $SessionId -MaximumLength 24
    $resourceToken = "$sessionToken-$(Get-BenchmarkShortHash -Value $runId)"
    $vmName = "qemu-bench-$resourceToken"
    $pipeName = "qemu-bench-$resourceToken"
    $switchName = "qemu-bench-$((ConvertTo-BenchmarkToken -Value $SessionId -MaximumLength 40))"
    $workDirectory = Join-Path (Get-BenchmarkHyperVWorkRoot) $resourceToken
    $serialDirectory = Join-Path $OutputDirectory 'serial'
    $rawDirectory = Join-Path $OutputDirectory "raw\$runId"
    $serialPath = Join-Path $serialDirectory "$runId.log"
    $microIso = Get-BenchmarkArtifactPath -GuestArtifacts $Runtime.guest_artifacts -FileName 'microbench.iso'
    $systemVhdx = Get-BenchmarkArtifactPath -GuestArtifacts $Runtime.guest_artifacts -FileName 'alpine-bench.vhdx'
    $dataVhdx = Get-BenchmarkArtifactPath -GuestArtifacts $Runtime.guest_artifacts -FileName 'fio-data.vhdx'
    $pipeJob = $null
    $hostIperfProcess = $null
    $hostIperfPersistent = $false
    $switchCreated = $false
    $firewallRuleCreated = $false
    $status = 'error'
    $errorMessage = $null
    $serialResult = $null
    $targetResult = $null
    $startedUtc = [DateTime]::UtcNow
    $interrupted = $false
    $networkState = @{
        warmup_started = $false
        client_started = $false
    }
    $configuration = [ordered]@{
        generation = if ($cell.guest -eq 'micro') { 1 } else { 2 }
        memory_mib = [int]$cell.ram_mib
        vcpus = [int]$cell.vcpus
        secure_boot = if ($cell.guest -eq 'micro') { $null } else { $false }
        switch_name = $null
        firewall_rule = $null
        work_directory = $workDirectory
    }
    $cleanup = [ordered]@{
        vm_removed = $false
        switch_removed = $true
        firewall_rule_removed = $true
        pipe_closed = $false
        host_iperf_removed = $true
        work_directory_removed = $false
        artifacts_retained = $false
    }

    New-Item -ItemType Directory -Path $workDirectory, $serialDirectory, $rawDirectory -Force | Out-Null
    Remove-Item -LiteralPath $serialPath -Force -ErrorAction SilentlyContinue
    Write-Utf8NoBom -Path $serialPath -Value ''

    try {
        $onSerialLine = $null
        if ($cell.guest -eq 'micro') {
            $derivedIso = Join-Path $workDirectory 'microbench-run.iso'
            New-BenchmarkMicroIso -BaseIsoPath $microIso -Run $Run -OutputPath $derivedIso

            New-VM -Name $vmName -Generation 1 -MemoryStartupBytes ([long]$cell.ram_mib * 1MB) `
                -NoVHD -Path $workDirectory | Out-Null
            Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $false
            Set-VMProcessor -VMName $vmName -Count ([int]$cell.vcpus)
            Get-VMNetworkAdapter -VMName $vmName | Remove-VMNetworkAdapter
            Add-VMDvdDrive -VMName $vmName -Path $derivedIso | Out-Null
            Set-VMBios -VMName $vmName -StartupOrder @('CD', 'IDE', 'LegacyNetworkAdapter', 'Floppy')
        } else {
            $systemClone = Join-Path $workDirectory 'alpine-bench.vhdx'
            $configIso = Join-Path $workDirectory 'config.iso'
            New-BenchmarkDifferencingVhdx -ParentPath $systemVhdx -Path $systemClone

            $hostIp = $null
            $guestIp = $null
            $adapterName = $null
            if ([string]$cell.workload -like 'iperf-*') {
                $hostIp = '192.168.210.1'
                $guestIp = '192.168.210.2'
                $adapterName = New-BenchmarkInternalSwitch -Name $switchName -HostIp $hostIp
                $switchCreated = $true
                $cleanup.switch_removed = $false
                $configuration.switch_name = $switchName
            }
            if ([string]$cell.workload -like 'iperf-guest-to-host-*') {
                $firewallRuleName = "$vmName-iperf"
                New-NetFirewallRule -DisplayName $firewallRuleName -Direction Inbound -Action Allow `
                    -Protocol TCP -LocalPort 5201 -InterfaceAlias $adapterName -Profile Any | Out-Null
                $firewallRuleCreated = $true
                $cleanup.firewall_rule_removed = $false
                $configuration.firewall_rule = $firewallRuleName
                $hostIperfProcess = Start-BenchmarkIperfServer -Port 5201 `
                    -OutputPath (Join-Path $rawDirectory 'host-iperf-server.log') `
                    -ErrorPath (Join-Path $rawDirectory 'host-iperf.stderr.log') `
                    -OneOff $false
                $hostIperfPersistent = $true
                $cleanup.host_iperf_removed = $false
            } elseif ([string]$cell.workload -like 'iperf-host-to-guest-*') {
                $clientOutput = Join-Path $rawDirectory 'host-iperf.json'
                $clientError = Join-Path $rawDirectory 'host-iperf.stderr.log'
                $parallelStreams = [int]$cell.parameters.parallel_streams
                $durationSeconds = [int]$cell.parameters.duration_seconds
                $onSerialLine = {
                    param($line)
                    if (-not $networkState.warmup_started -and $line -like "BENCH_IPERF_WARMUP_SERVER_READY run_id=$runId *") {
                        $networkState.warmup_started = $true
                        Invoke-BenchmarkIperfClient -HostName $guestIp -Port 5201 `
                            -ParallelStreams $parallelStreams -DurationSeconds 1 `
                            -OutputPath (Join-Path $rawDirectory 'host-iperf-warmup.json') `
                            -ErrorPath (Join-Path $rawDirectory 'host-iperf-warmup.stderr.log')
                    } elseif (-not $networkState.client_started -and $line -like "BENCH_IPERF_SERVER_READY run_id=$runId *") {
                        $networkState.client_started = $true
                        Invoke-BenchmarkIperfClient -HostName $guestIp -Port 5201 `
                            -ParallelStreams $parallelStreams -DurationSeconds $durationSeconds `
                            -OutputPath $clientOutput -ErrorPath $clientError
                    }
                }
            }

            $job = Get-SystemBenchmarkJob -Run $Run -Runner hyperv -HostIp $hostIp -GuestIp $guestIp
            New-BenchmarkConfigIso -Job $job -OutputPath $configIso

            New-VM -Name $vmName -Generation 2 -MemoryStartupBytes ([long]$cell.ram_mib * 1MB) `
                -VHDPath $systemClone -Path $workDirectory | Out-Null
            Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $false
            Set-VMProcessor -VMName $vmName -Count ([int]$cell.vcpus)
            Set-VMFirmware -VMName $vmName -EnableSecureBoot Off
            Add-VMDvdDrive -VMName $vmName -Path $configIso | Out-Null
            $bootDisk = Get-VMHardDiskDrive -VMName $vmName
            Set-VMFirmware -VMName $vmName -FirstBootDevice $bootDisk

            if ([string]$cell.workload -like 'fio-*') {
                $dataClone = Join-Path $workDirectory 'fio-data.vhdx'
                New-BenchmarkDifferencingVhdx -ParentPath $dataVhdx -Path $dataClone
                Add-VMHardDiskDrive -VMName $vmName -ControllerType SCSI -Path $dataClone | Out-Null
            }
            if ($switchCreated) {
                Connect-VMNetworkAdapter -VMName $vmName -SwitchName $switchName
            }
        }

        Set-VMComPort -VMName $vmName -Number 1 -Path "\\.\pipe\$pipeName"
        $pipeJob = Start-BenchmarkPipeCapture -PipeName $pipeName -LogPath $serialPath `
            -ConnectTimeoutMilliseconds ([Math]::Min(120000, [int]$cell.timeout_seconds * 1000))

        $startedUtc = [DateTime]::UtcNow
        Start-VM -Name $vmName | Out-Null
        $serialResult = Wait-BenchmarkSerial -SerialPath $serialPath -RunId $runId `
            -StartedUtc $startedUtc -TimeoutSeconds ([int]$cell.timeout_seconds) `
            -IsStopped {
                $currentVm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
                $vmStopped = $null -eq $currentVm -or $currentVm.State -eq 'Off'
                $pipeStopped = $pipeJob.State -in @('Completed', 'Failed')
                $vmStopped -and $pipeStopped
            } `
            -OnLine $onSerialLine

        Complete-BenchmarkPipeCapture -Job $pipeJob
        $pipeJob = $null
        $cleanup.pipe_closed = $true
        if ([string]$cell.workload -like 'iperf-host-to-guest-*') {
            Assert-Condition ($networkState.warmup_started) "Run '$runId' never requested the host iperf3 warmup client."
            Assert-Condition ($networkState.client_started) "Run '$runId' never requested the host iperf3 client."
        }
        if ($null -ne $hostIperfProcess -and -not $hostIperfPersistent) {
            Assert-Condition ($hostIperfProcess.WaitForExit(15000)) 'Host iperf3 server did not exit after the guest completed.'
            $hostIperfExitCode = Complete-BenchmarkProcess -Process $hostIperfProcess
            Assert-Condition ($hostIperfExitCode -eq 0) "Host iperf3 server exited with code $hostIperfExitCode."
        }

        $targetResult = Test-BenchmarkGuestResult -Run $Run -SerialResult $serialResult
        if ($serialResult.raw_records.Count -gt 0) {
            Write-Utf8NoBom -Path (Join-Path $rawDirectory 'guest-raw.jsonl') `
                -Value (($serialResult.raw_records -join "`n") + "`n")
        }
        $status = 'success'
    } catch {
        if ($_.Exception -is [Management.Automation.PipelineStoppedException]) {
            $interrupted = $true
        } else {
            $errorMessage = $_.Exception.Message
        }
    } finally {
        if ($null -ne $hostIperfProcess) {
            if (-not $hostIperfProcess.HasExited) {
                Stop-BenchmarkProcessTree -ProcessId $hostIperfProcess.Id
            }
            Complete-BenchmarkProcess -Process $hostIperfProcess | Out-Null
            $hostIperfProcess.Dispose()
        }
        $cleanup.host_iperf_removed = $true

        $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
        if ($null -ne $vm) {
            if ($vm.State -ne 'Off') {
                Stop-VM -VM $vm -TurnOff -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            }
            Remove-VM -VM $vm -Force -ErrorAction SilentlyContinue
        }
        $cleanup.vm_removed = $null -eq (Get-VM -Name $vmName -ErrorAction SilentlyContinue)

        if ($null -ne $pipeJob) {
            Stop-Job -Job $pipeJob -ErrorAction SilentlyContinue
            Receive-Job -Job $pipeJob -Wait -ErrorAction SilentlyContinue | Out-Null
            Remove-Job -Job $pipeJob -Force -ErrorAction SilentlyContinue
            $cleanup.pipe_closed = $true
        }

        if ($firewallRuleCreated) {
            Get-NetFirewallRule -DisplayName $configuration.firewall_rule -ErrorAction SilentlyContinue |
                Remove-NetFirewallRule -ErrorAction SilentlyContinue
        }
        if ($null -eq $configuration.firewall_rule) {
            $cleanup.firewall_rule_removed = $true
        } else {
            $cleanup.firewall_rule_removed = $null -eq (
                Get-NetFirewallRule -DisplayName $configuration.firewall_rule -ErrorAction SilentlyContinue
            )
        }

        if ($switchCreated) {
            $switch = Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue
            if ($null -ne $switch) {
                Remove-VMSwitch -VMSwitch $switch -Force -ErrorAction SilentlyContinue
            }
        }
        $cleanup.switch_removed = $null -eq (Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue)

        if ($status -eq 'success' -or -not $KeepArtifactsOnFailure) {
            $cleanup.work_directory_removed = Remove-BenchmarkDirectory -Path $workDirectory
        } else {
            $cleanup.artifacts_retained = $true
        }
    }

    if ($interrupted) {
        throw [Management.Automation.PipelineStoppedException]::new()
    }

    return [ordered]@{
        runner = 'hyperv'
        status = $status
        error = $errorMessage
        started_utc = $startedUtc.ToString('o')
        completed_utc = [DateTime]::UtcNow.ToString('o')
        resource_name = $vmName
        pipe_name = $pipeName
        configuration = $configuration
        serial_path = $serialPath
        raw_directory = $rawDirectory
        serial_result = $serialResult
        target_result = $targetResult
        cleanup = $cleanup
    }
}
