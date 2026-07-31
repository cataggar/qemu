Set-StrictMode -Version Latest

function Get-StaleQemuBenchmarkResources {
    return @(Get-CimInstance -ClassName Win32_Process -Filter "Name = 'qemu-system-x86_64.exe'" -ErrorAction SilentlyContinue |
        Where-Object { [string]$_.CommandLine -match '(?i)-name\s+(?:"?qemu-bench-)' } |
        ForEach-Object {
            [ordered]@{
                type = 'qemu-process'
                id = [int]$_.ProcessId
                name = [string]$_.Name
                command_line = [string]$_.CommandLine
            }
        })
}

function Remove-StaleQemuBenchmarkResources {
    foreach ($resource in @(Get-StaleQemuBenchmarkResources)) {
        Stop-BenchmarkProcessTree -ProcessId ([int]$resource.id)
    }
}

function New-QemuBenchmarkOverlay {
    param(
        [Parameter(Mandatory = $true)]
        [string]$QemuImgPath,
        [Parameter(Mandatory = $true)]
        [string]$ParentPath,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Assert-Condition (Test-Path -LiteralPath $ParentPath -PathType Leaf) "VHDX parent '$ParentPath' is missing."
    Assert-Condition (-not (Test-Path -LiteralPath $Path)) "QEMU overlay '$Path' already exists."
    $probe = Invoke-QemuProbe -Executable $QemuImgPath -Arguments @(
        'create',
        '-f', 'qcow2',
        '-F', 'vhdx',
        '-b', $ParentPath,
        $Path
    )
    Assert-Condition ($probe.exit_code -eq 0) "Unable to create QEMU overlay '$Path': $($probe.output)"
    Assert-Condition (Test-Path -LiteralPath $Path -PathType Leaf) "QEMU overlay '$Path' was not created."
}

function Invoke-QemuBenchmarkRun {
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
    $resourceToken = ConvertTo-BenchmarkToken -Value "$SessionId-$runId" -MaximumLength 54
    $vmName = "qemu-bench-$resourceToken"
    $workDirectory = Join-Path $OutputDirectory "work\$runId"
    $serialDirectory = Join-Path $OutputDirectory 'serial'
    $rawDirectory = Join-Path $OutputDirectory "raw\$runId"
    $serialPath = Join-Path $serialDirectory "$runId.log"
    $stdoutPath = Join-Path $rawDirectory 'qemu.stdout.log'
    $stderrPath = Join-Path $rawDirectory 'qemu.stderr.log'
    $microIso = Get-BenchmarkArtifactPath -GuestArtifacts $Runtime.guest_artifacts -FileName 'microbench.iso'
    $systemVhdx = Get-BenchmarkArtifactPath -GuestArtifacts $Runtime.guest_artifacts -FileName 'alpine-bench.vhdx'
    $dataVhdx = Get-BenchmarkArtifactPath -GuestArtifacts $Runtime.guest_artifacts -FileName 'fio-data.vhdx'
    $qemuProcess = $null
    $hostIperfProcess = $null
    $hostIperfPersistent = $false
    $status = 'error'
    $errorMessage = $null
    $serialResult = $null
    $targetResult = $null
    $arguments = @()
    $startedUtc = [DateTime]::UtcNow
    $interrupted = $false
    $networkState = @{
        warmup_started = $false
        client_started = $false
    }
    $cleanup = [ordered]@{
        qemu_process_removed = $false
        host_iperf_removed = $true
        work_directory_removed = $false
        artifacts_retained = $false
    }

    New-Item -ItemType Directory -Path $workDirectory, $serialDirectory, $rawDirectory -Force | Out-Null
    Remove-Item -LiteralPath $serialPath, $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    Write-Utf8NoBom -Path $serialPath -Value ''

    try {
        $arguments = @(
            '-name', $vmName,
            '-accel', [string]$cell.accelerator,
            '-m', [string]$cell.ram_mib,
            '-smp', [string]$cell.vcpus,
            '-display', 'none',
            '-monitor', 'none',
            '-serial', "file:$serialPath",
            '-no-reboot'
        )

        $onSerialLine = $null
        if ($cell.guest -eq 'micro') {
            $derivedIso = Join-Path $workDirectory 'microbench-run.iso'
            New-BenchmarkMicroIso -BaseIsoPath $microIso -Run $Run -OutputPath $derivedIso
            $arguments += @(
                '-machine', 'pc',
                '-nic', 'none',
                '-boot', 'd',
                '-cdrom', $derivedIso
            )
        } else {
            $systemClone = Join-Path $workDirectory 'alpine-bench.qcow2'
            $configIso = Join-Path $workDirectory 'config.iso'
            $firmwareVars = Join-Path $workDirectory 'edk2-vars.fd'
            New-QemuBenchmarkOverlay -QemuImgPath ([string]$Runtime.qemu.image_tool) `
                -ParentPath $systemVhdx -Path $systemClone
            Copy-Item -LiteralPath ([string]$Runtime.qemu.firmware.edk2.vars_path) -Destination $firmwareVars

            $hostIp = $null
            $guestIp = $null
            $hostForwardPort = $null
            if ([string]$cell.workload -like 'iperf-*') {
                $hostIp = '10.0.2.2'
            }
            if ([string]$cell.workload -like 'iperf-guest-to-host-*') {
                $hostIperfProcess = Start-BenchmarkIperfServer -Port 5201 `
                    -OutputPath (Join-Path $rawDirectory 'host-iperf-server.log') `
                    -ErrorPath (Join-Path $rawDirectory 'host-iperf.stderr.log') `
                    -OneOff $false
                $hostIperfPersistent = $true
                $cleanup.host_iperf_removed = $false
            } elseif ([string]$cell.workload -like 'iperf-host-to-guest-*') {
                $hostForwardPort = Get-FreeTcpPort
                $clientOutput = Join-Path $rawDirectory 'host-iperf.json'
                $clientError = Join-Path $rawDirectory 'host-iperf.stderr.log'
                $parallelStreams = [int]$cell.parameters.parallel_streams
                $durationSeconds = [int]$cell.parameters.duration_seconds
                $onSerialLine = {
                    param($line)
                    if (-not $networkState.warmup_started -and $line -like "BENCH_IPERF_WARMUP_SERVER_READY run_id=$runId *") {
                        $networkState.warmup_started = $true
                        Invoke-BenchmarkIperfClient -HostName '127.0.0.1' -Port $hostForwardPort `
                            -ParallelStreams $parallelStreams -DurationSeconds 1 `
                            -OutputPath (Join-Path $rawDirectory 'host-iperf-warmup.json') `
                            -ErrorPath (Join-Path $rawDirectory 'host-iperf-warmup.stderr.log')
                    } elseif (-not $networkState.client_started -and $line -like "BENCH_IPERF_SERVER_READY run_id=$runId *") {
                        $networkState.client_started = $true
                        Invoke-BenchmarkIperfClient -HostName '127.0.0.1' -Port $hostForwardPort `
                            -ParallelStreams $parallelStreams -DurationSeconds $durationSeconds `
                            -OutputPath $clientOutput -ErrorPath $clientError
                    }
                }
            }

            $job = Get-SystemBenchmarkJob -Run $Run -Runner qemu -HostIp $hostIp -GuestIp $guestIp
            New-BenchmarkConfigIso -Job $job -OutputPath $configIso

            $netdev = 'user,id=net0'
            if ($null -ne $hostForwardPort) {
                $netdev += ",hostfwd=tcp:127.0.0.1:$hostForwardPort-:5201"
            }
            $arguments += @(
                '-machine', 'q35',
                '-drive', "if=pflash,unit=0,format=raw,readonly=on,file=$($Runtime.qemu.firmware.edk2.path)",
                '-drive', "if=pflash,unit=1,format=raw,file=$firmwareVars",
                '-drive', "file=$systemClone,format=qcow2,if=none,id=os",
                '-device', 'virtio-blk-pci,drive=os,bootindex=1',
                '-drive', "file=$configIso,format=raw,media=cdrom,readonly=on",
                '-netdev', $netdev,
                '-device', 'virtio-net-pci,netdev=net0'
            )

            if ([string]$cell.workload -like 'fio-*') {
                $dataClone = Join-Path $workDirectory 'fio-data.qcow2'
                New-QemuBenchmarkOverlay -QemuImgPath ([string]$Runtime.qemu.image_tool) `
                    -ParentPath $dataVhdx -Path $dataClone
                $arguments += @(
                    '-drive', "file=$dataClone,format=qcow2,if=none,id=data",
                    '-device', 'virtio-blk-pci,drive=data'
                )
            }
        }

        $startedUtc = [DateTime]::UtcNow
        $qemuProcess = Start-BenchmarkProcess -FilePath ([string]$Runtime.qemu.executable) `
            -Arguments $arguments -StandardOutputPath $stdoutPath -StandardErrorPath $stderrPath
        $serialResult = Wait-BenchmarkSerial -SerialPath $serialPath -RunId $runId `
            -StartedUtc $startedUtc -TimeoutSeconds ([int]$cell.timeout_seconds) `
            -IsStopped { $qemuProcess.HasExited } -OnLine $onSerialLine

        $qemuExitCode = Complete-BenchmarkProcess -Process $qemuProcess
        Assert-Condition ($qemuExitCode -eq 0) "QEMU exited with code $qemuExitCode."
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

        if ($null -ne $qemuProcess) {
            if (-not $qemuProcess.HasExited) {
                Stop-BenchmarkProcessTree -ProcessId $qemuProcess.Id
            }
            Complete-BenchmarkProcess -Process $qemuProcess | Out-Null
            $qemuProcess.Dispose()
        }
        $cleanup.qemu_process_removed = $true

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
        runner = 'qemu'
        status = $status
        error = $errorMessage
        started_utc = $startedUtc.ToString('o')
        completed_utc = [DateTime]::UtcNow.ToString('o')
        resource_name = $vmName
        executable = [string]$Runtime.qemu.executable
        arguments = $arguments
        serial_path = $serialPath
        raw_directory = $rawDirectory
        serial_result = $serialResult
        target_result = $targetResult
        cleanup = $cleanup
    }
}
