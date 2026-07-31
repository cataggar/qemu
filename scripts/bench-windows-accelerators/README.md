# Windows accelerator benchmark suite

This suite implements the reproducible TCG, WHPX, and native Hyper-V comparison tracked by [issue #21](https://github.com/cataggar/qemu/issues/21). It preserves the original prime-counting workload and defines the complete CPU/SMP, memory, disk, networking, minimal-guest boot, and full Alpine Linux boot matrix.

## Implementation status

All five implementation phases are complete: `benchmark.json` defines the complete matrix, `build-guests.sh` constructs the locked guests, `run.ps1` executes sequential QEMU TCG/WHPX, Hyper-V, and optional WSL reference runs, and `analyze.py` validates and reports the results. The hardened full-profile verification completed all 1,782 runs with 1,620 measured successes, 162 successful warmups, zero final failures/skips, and all 352 fio/iperf3 raw records reconciled.

## Experimental boundaries

CPU and memory workloads are the closest accelerator comparison because each environment runs the same guest instructions with fixed vCPU and RAM settings. Disk and networking workloads compare complete platform paths: QEMU uses an ephemeral qcow2 overlay backed by the immutable VHDX parent, virtio-blk, virtio-net-pci, and libslirp, while Hyper-V uses a native differencing VHDX, synthetic SCSI/NIC devices, and an internal vSwitch. The generated report must keep those results separate from the pure CPU headline.

The suite does not change the host power plan, stop unrelated processes, drop the Windows filesystem cache, or automate WHPX/Hyper-V execution in GitHub Actions.

## Prerequisites

- x86_64 Windows 11 or a supported Windows 10 release.
- Hyper-V enabled; alternatively, Windows Hypervisor Platform must be enabled for WHPX-only runs.
- Hyper-V enabled, including the Hyper-V PowerShell module.
- Hardware virtualization enabled in firmware and the Windows hypervisor running.
- An elevated PowerShell session for real preflight and Hyper-V execution.
- WSL with a working Linux distribution for guest-image construction.
- Ubuntu 24.04 in WSL with `qemu-utils`, `qemu-system-x86`, `ovmf`, `dosfstools`, `xorriso`, `cpio`, `rsync`, and Python 3.
- Zig 0.16.0 available as `zig` or `zig.exe` inside the WSL environment.
- Windows `iperf3.exe` 3.21, installable with `winget install --id ar51an.iPerf3`.
- WSL `sysbench` 1.0.20 when using `-IncludeWslReference`.
- At least 40 GiB free on the result drive, 4 GiB free host memory, and 2 GiB static RAM per benchmark VM.
- A Windows QEMU package containing `qemu-system-x86_64.exe`, `qemu-img.exe`, `share\bios-256k.bin` or `share\bios.bin`, `share\edk2-x86_64-code.fd`, and `share\edk2-i386-vars.fd`.

The current release can be downloaded from:

```powershell
gh release download v11.0.50-z.14 `
  --repo cataggar/qemu `
  --pattern qemu-v11.0.50-z.14-windows-x64.zip
Expand-Archive qemu-v11.0.50-z.14-windows-x64.zip C:\qemu-bench
```

Pass the extracted directory that directly contains `qemu-system-x86_64.exe` as `-QemuRoot`.

## Build the guests

Install the Ubuntu WSL dependencies once:

```powershell
wsl -d Ubuntu-24.04 -u root -- apt-get update
wsl -d Ubuntu-24.04 -u root -- apt-get install -y --no-install-recommends `
  qemu-utils qemu-system-x86 ovmf dosfstools xorriso cpio rsync python3
```

Build from locked inputs and run both QEMU TCG smoke tests:

```powershell
$wslRepo = (wsl -d Ubuntu-24.04 -- wslpath -a $PWD.Path).Trim()
wsl -d Ubuntu-24.04 -u root -- bash -lc `
  "cd '$wslRepo' && scripts/bench-windows-accelerators/build-guests.sh --clean --verify"
```

The build verifies repository indexes and every downloaded file against `guest/inputs.lock.json`. Locked direct APKs, including the kernel, are installed from the verified local cache so a newer package appearing on the live Alpine mirror cannot silently replace them; dependency packages still resolve from the configured Alpine repositories. Use `build-guests.sh --refresh-lock` as an explicit, reviewable operation when updating Alpine packages or source files.

The manifest records the exact lock-file and artifact hashes used by a run, and `run.ps1` rejects artifacts whose lock hash is stale. The VHDX/GPT/filesystem tools generate fresh identifiers, so clean VHDX builds are input-reproducible but are not expected to have byte-identical container hashes.

`alpine-make-vm-image` uses NBD and bind mounts while installing the full guest. The wrapper patches its exit trap to preserve failures, confines temporary mount points under `out\work`, and refuses to delete build directories until all nested mounts and suite-owned NBD processes are gone.

## Profiles

| Profile | Purpose | Warmups | Measured repetitions | Estimated runtime | Expected scope |
|---|---:|---:|---:|---:|---|
| `quick` | Matrix and runner smoke test | 1 | 2 | 10-20 minutes | Original prime workload plus one full-system boot cell set |
| `core` | CPU, SMP, memory, and boot comparison | 1 | 10 | 2-4 hours | Excludes fio and iperf3 |
| `full` | Complete issue #21 comparison | 1 | 10 | 24-36 hours | Includes CPU, memory, fio, iperf3, and boot |

The `quick` profile uses only 1-vCPU and 4-vCPU cells. The `core` and `full` profiles request 1, 2, 4, and 8 vCPUs where a workload supports scaling. A host with fewer logical processors marks larger cells as skipped with an explicit reason; it never substitutes a different vCPU count.

Allow roughly 40 GiB for the generated boot VHDX, fully preconditioned fixed 16 GiB fio VHDX container, minimal ISO, and build intermediates. Raw serial/tool output and reports are normally below 5 GiB per full run, but the runtime preflight separately requires 40 GiB free so per-run overlays and interrupted-run diagnostics have headroom.

## Inspect the exact matrix

`-WhatIf` validates `benchmark.json` and writes a stable JSON plan to standard output without requiring QEMU, administrator rights, guest artifacts, or VM creation:

```powershell
powershell -NoProfile -File scripts\bench-windows-accelerators\run.ps1 `
  -Profile quick `
  -WhatIf
```

Include the planned reference-only WSL environment when inspecting compatible standardized CPU/memory workloads:

```powershell
powershell -NoProfile -File scripts\bench-windows-accelerators\run.ps1 `
  -Profile core `
  -IncludeWslReference `
  -WhatIf
```

Each matrix cell records the workload, guest type, environment, explicit accelerator string, vCPU count, RAM, timeout, warmup count, measured repetition count, parameters, and whether host CPU capacity requires the cell to be skipped.

`-IncludeWslReference` executes matching WSL sysbench CPU and memory cells. These records are marked reference-only and are excluded from QEMU-versus-Hyper-V speedup calculations.

Use `-ConfigurationPath` to validate or execute a generated reduced configuration without changing the committed `benchmark.json`. The selected configuration hash is recorded in the result manifest and must still define the required `quick`, `core`, and `full` profiles.

## Run the benchmark

After Phase 2 has produced `out\guest\manifest.json` and its guest artifacts:

```powershell
powershell -NoProfile -File scripts\bench-windows-accelerators\run.ps1 `
  -Profile quick `
  -QemuRoot C:\qemu-bench\qemu-v11.0.50-z.14-windows-x64
```

Run the complete matrix into an explicit result directory:

```powershell
powershell -NoProfile -File scripts\bench-windows-accelerators\run.ps1 `
  -Profile full `
  -QemuRoot C:\qemu-bench\qemu-v11.0.50-z.14-windows-x64 `
  -OutputDirectory scripts\bench-windows-accelerators\results\issue-21-full
```

The preflight checks administrator rights, Hyper-V, Windows iperf3, WSL/xorriso, optional WSL sysbench, hypervisor presence, memory/disk capacity, QEMU accelerators, qemu-img, slirp, split EDK2 firmware, and every checksum in the guest artifact manifest. While active, the runner uses the Windows execution-state API to prevent host sleep without changing the configured power plan. It then executes the deterministic warmup/measured order one environment at a time and appends one normalized record per run to `runs.jsonl`.

Use `-OutputDirectory` to choose a result directory. Without it, the script uses `scripts\bench-windows-accelerators\results\<UTC timestamp>`. Use `-Resume` only with an existing directory whose profile, run order, configuration, QEMU, and guest-manifest hashes match; completed successful or failed run IDs are not repeated. Add `-RetryFailed` with `-Resume` to archive existing failed records under `failed-runs\`, remove them from the active JSONL/state, and schedule only those failed cells again.

`-KeepArtifactsOnFailure` retains a failed run's derived ISO and overlay disks while still removing its QEMU process or Hyper-V VM/switch/pipe. QEMU uses qcow2 overlays because its VHDX driver does not support differencing images; Hyper-V uses native differencing VHDX children. Hyper-V serial-transport failures and runner timeouts are retried up to three attempts; failed-attempt serial/raw/work files are preserved under `retries\<run-id>\attempt-XX`, and only the final successful attempt becomes the benchmark sample. The default removes temporary media and disks after every run. An exclusive suite lock prevents concurrent benchmark sessions. The runner refuses benchmark-prefixed stale QEMU or Hyper-V resources; use `-CleanupStale` to remove only those explicitly benchmark-owned resources after the lock confirms no other suite run is active.

## Output layout

```text
results\<run-id>\
  manifest.json
  runs.jsonl
  state.json
  serial\
  raw\
  retries\
  failed-runs\
  work\
  summary.json
  report.md
```

The runner creates `manifest.json`, `runs.jsonl`, `state.json`, serial logs, and per-run raw diagnostics. `retries\` is created only when a transport failure or timeout requires another attempt, and `failed-runs\` only when `-RetryFailed` archives final failed records before rerunning their cells. QEMU work files use `work\`; Hyper-V uses a short hashed directory under the Windows temporary directory to avoid legacy smart-paging path limits. Both are removed after successful cleanup unless failed artifacts were explicitly retained. The analyzer creates `summary.json` and `report.md`. The complete `out\` and `results\` trees are ignored by Git.

## Analyze results

Run the standard-library analyzer after a benchmark completes:

```powershell
python scripts\bench-windows-accelerators\analyze.py `
  scripts\bench-windows-accelerators\results\issue-21-full
```

Use `--cv-threshold 0.10` to change the default 5% coefficient-of-variation warning threshold. `--summary` and `--report` select non-default output paths.

The analyzer rejects duplicate or missing run IDs, matrix metadata mismatches, invalid known answers, guest vCPU mismatches, non-finite metrics, inconsistent units/directions, and fio/iperf3 values that do not reconcile with retained raw JSON. It rechecks the configuration and guest-manifest hashes when their recorded source paths remain available; copied result directories retain the recorded hashes and receive a source-availability warning when those files cannot be reopened.

`summary.json` contains machine-readable counts, validation totals, per-group statistics, baselines, direction-aware relative speedups, failed/skipped records, and variance warnings. `report.md` contains the issue-ready host metadata, methodology, prime continuity, CPU/SMP scaling, memory, boot, disk, network, WHPX irqchip, variance, and caveat sections.

To rerun only final failed cells before analysis:

```powershell
powershell -NoProfile -File scripts\bench-windows-accelerators\run.ps1 `
  -Profile full `
  -QemuRoot C:\qemu-bench\qemu-v11.0.50-z.14-windows-x64 `
  -OutputDirectory scripts\bench-windows-accelerators\results\issue-21-full `
  -Resume `
  -RetryFailed
```

## Serial result protocol

Guests use a 38400-baud COM1 console and emit one compact JSON object per serial line:

```text
BENCH_JSON {"schema":1,"run_id":"...","workload":"sysbench-cpu","metric":"events_per_second","value":1234.5,"unit":"events/s"}
```

Normalized records include the environment, accelerator options, guest type, vCPUs, RAM, repetition, warmup flag, workload parameters, metric direction, guest elapsed time, and success/error state. Host boot timings use the same schema and add host start/marker timestamps.

## Safe interruption and cleanup

Use Ctrl+C once and allow the current cleanup path to finish. Do not terminate QEMU, PowerShell, WSL, `qemu-nbd`, or Hyper-V worker processes by name.

Guest-image construction uses NBD and mounted filesystems. Before deleting a guest-build work directory, unmount every nested mount and disconnect the exact NBD device used by that build. Never recursively delete a directory that still contains `/dev`, `/proc`, `/sys`, or another bind mount.

The VM runners use unique session-prefixed VM, switch, named-pipe, ISO, and VHDX names. Cleanup removes only resources carrying the current session identifier and never modifies a pre-existing Hyper-V switch or VM.

## Interpretation

The analyzer reports medians, arithmetic means, sample standard deviations, coefficients of variation, minima, maxima, and direction-aware relative speedups. Warmups are excluded. High variance is reported rather than hidden by deleting outliers.

TCG cells always specify `thread=single` or `thread=multi`; this suite never assumes the default is single-threaded. WHPX interrupt-path experiments specify `kernel-irqchip=on` or `kernel-irqchip=off`; split mode is unsupported and rejected by configuration validation.

## Publish issue #21 results

Before updating issue #21:

1. Confirm `summary.json` reports the expected run count with no unexplained failures or skips.
2. Review every variance warning and rerun only failed or experimentally invalid cells; do not delete statistical outliers.
3. Include the exact QEMU version/SHA-256, host metadata, configuration hash, firmware hashes, and guest artifact hashes from the report.
4. Paste or link the generated report while keeping CPU/memory conclusions separate from disk/network device-stack conclusions.
5. Record where the complete raw result directory is retained and link the committed harness revision.
