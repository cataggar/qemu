Set-StrictMode -Version Latest

function Get-WslSysbenchMetadata {
    param(
        [string]$Distribution = 'Ubuntu-24.04'
    )

    $output = Invoke-BenchmarkWslTool -Distribution $Distribution -Arguments @('sysbench', '--version')
    $version = ([string]($output -join "`n")).Trim()
    Assert-Condition ($version -match '^sysbench 1\.0\.20(?:\s|$)') "WSL sysbench version '$version' does not match 1.0.20."
    return [ordered]@{
        distribution = $Distribution
        version = $version
    }
}

function Invoke-WslBenchmarkRun {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Run,
        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory,
        [string]$Distribution = 'Ubuntu-24.04'
    )

    $runId = [string]$Run.run_id
    $cell = $Run.cell
    $rawDirectory = Join-Path $OutputDirectory "raw\$runId"
    $stdoutPath = Join-Path $rawDirectory 'sysbench.stdout.log'
    $stderrPath = Join-Path $rawDirectory 'sysbench.stderr.log'
    $process = $null
    $status = 'error'
    $errorMessage = $null
    $targetResult = $null
    $startedUtc = [DateTime]::UtcNow
    $interrupted = $false
    $arguments = @(
        '-d', $Distribution,
        '-u', 'root',
        '--',
        'timeout', '--signal=TERM', "$([int]$cell.timeout_seconds)s",
        'sysbench'
    )
    $cleanup = [ordered]@{
        process_removed = $false
        work_directory_removed = $true
    }

    New-Item -ItemType Directory -Path $rawDirectory -Force | Out-Null
    Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue

    switch -Wildcard ([string]$cell.workload) {
        'sysbench-cpu' {
            $arguments += @(
                'cpu',
                "--threads=$([int]$cell.vcpus)",
                "--time=$([int]$cell.parameters.duration_seconds)",
                "--cpu-max-prime=$([int]$cell.parameters.cpu_max_prime)",
                'run'
            )
        }
        'sysbench-memory-*' {
            $arguments += @(
                'memory',
                "--threads=$([int]$cell.vcpus)",
                "--time=$([int]$cell.parameters.duration_seconds)",
                '--events=0',
                '--memory-total-size=1T',
                "--memory-oper=$([string]$cell.parameters.operation)",
                "--memory-access-mode=$([string]$cell.parameters.access_mode)",
                "--memory-block-size=$([string]$cell.parameters.block_size)",
                'run'
            )
        }
        default {
            throw "Benchmark error: Unsupported WSL reference workload '$($cell.workload)'."
        }
    }

    try {
        $startedUtc = [DateTime]::UtcNow
        $process = Start-BenchmarkProcess -FilePath (Join-Path $env:SystemRoot 'System32\wsl.exe') `
            -Arguments $arguments -StandardOutputPath $stdoutPath -StandardErrorPath $stderrPath
        if (-not $process.WaitForExit(([int]$cell.timeout_seconds + 15) * 1000)) {
            throw [TimeoutException]::new("WSL run '$runId' exceeded its timeout.")
        }
        $exitCode = Complete-BenchmarkProcess -Process $process
        Assert-Condition ($exitCode -eq 0) "WSL sysbench exited with code $exitCode."

        $output = Get-Content -LiteralPath $stdoutPath -Raw
        if ([string]$cell.workload -eq 'sysbench-cpu') {
            Assert-Condition ($output -match '(?m)^\s*events per second:\s*([0-9.]+)\s*$') "Unable to parse WSL sysbench CPU output for '$runId'."
            $metric = 'events_per_second'
            $value = [double]$Matches[1]
            $unit = 'events/s'
        } else {
            Assert-Condition ($output -match '\(([0-9.]+)\s+MiB/sec\)') "Unable to parse WSL sysbench memory output for '$runId'."
            $metric = 'mib_per_second'
            $value = [double]$Matches[1]
            $unit = 'MiB/s'
        }
        $targetResult = [ordered]@{
            schema = 1
            run_id = $runId
            workload = [string]$cell.workload
            metric = $metric
            value = $value
            unit = $unit
            direction = 'higher'
            threads = [int]$cell.vcpus
            status = 'success'
        }
        $status = 'success'
    } catch {
        if ($_.Exception -is [Management.Automation.PipelineStoppedException]) {
            $interrupted = $true
        } else {
            $errorMessage = $_.Exception.Message
        }
    } finally {
        if ($null -ne $process) {
            if (-not $process.HasExited) {
                Stop-BenchmarkProcessTree -ProcessId $process.Id
            }
            Complete-BenchmarkProcess -Process $process | Out-Null
            $process.Dispose()
        }
        $cleanup.process_removed = $true
    }

    if ($interrupted) {
        throw [Management.Automation.PipelineStoppedException]::new()
    }

    return [ordered]@{
        runner = 'wsl'
        status = $status
        error = $errorMessage
        started_utc = $startedUtc.ToString('o')
        completed_utc = [DateTime]::UtcNow.ToString('o')
        resource_name = $null
        configuration = [ordered]@{
            distribution = $Distribution
            arguments = $arguments
        }
        serial_path = $null
        raw_directory = $rawDirectory
        serial_result = $null
        target_result = $targetResult
        cleanup = $cleanup
    }
}
