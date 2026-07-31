#!/usr/bin/env python3
"""Validate and summarize Windows accelerator benchmark results."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import statistics
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


SCHEMA_VERSION = 1
DEFAULT_CV_WARNING_THRESHOLD = 0.05
VALID_DIRECTIONS = {"higher", "lower"}
VALID_STATUSES = {"success", "error", "skipped"}
HEX_DIGITS = frozenset("0123456789abcdef")


class AnalysisError(ValueError):
    """Raised when benchmark input is incomplete or inconsistent."""


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8-sig"))
    except FileNotFoundError as exc:
        raise AnalysisError(f"Required file is missing: {path}") from exc
    except json.JSONDecodeError as exc:
        raise AnalysisError(f"Invalid JSON in {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise AnalysisError(f"Expected a JSON object in {path}.")
    return value


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    try:
        lines = path.read_text(encoding="utf-8-sig").splitlines()
    except FileNotFoundError as exc:
        raise AnalysisError(f"Required file is missing: {path}") from exc
    for line_number, line in enumerate(lines, 1):
        if not line.strip():
            continue
        try:
            value = json.loads(line)
        except json.JSONDecodeError as exc:
            raise AnalysisError(
                f"Invalid JSON on line {line_number} of {path}: {exc}"
            ) from exc
        if not isinstance(value, dict):
            raise AnalysisError(
                f"Expected a JSON object on line {line_number} of {path}."
            )
        records.append(value)
    return records


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AnalysisError(message)


def require_sha256(value: Any, label: str) -> str:
    text = str(value or "").lower()
    require(
        len(text) == 64 and all(character in HEX_DIGITS for character in text),
        f"{label} is not a valid SHA-256 value.",
    )
    return text


def require_finite_number(value: Any, label: str) -> float:
    require(
        isinstance(value, (int, float)) and not isinstance(value, bool),
        f"{label} must be numeric.",
    )
    number = float(value)
    require(math.isfinite(number), f"{label} must be finite.")
    return number


def resolve_recorded_path(result_directory: Path, recorded_path: Any) -> Path | None:
    if not recorded_path:
        return None
    path = Path(str(recorded_path))
    if path.exists():
        return path
    relative = result_directory / path
    if relative.exists():
        return relative
    basename = result_directory / path.name
    if basename.exists():
        return basename
    return None


def verify_source_hashes(
    manifest: dict[str, Any], result_directory: Path
) -> tuple[list[dict[str, str]], list[str]]:
    checked: list[dict[str, str]] = []
    warnings: list[str] = []

    configuration = manifest.get("configuration")
    require(isinstance(configuration, dict), "Manifest configuration is missing.")
    configuration_hash = require_sha256(
        configuration.get("sha256"), "Manifest configuration hash"
    )
    configuration_path = resolve_recorded_path(
        result_directory, configuration.get("path")
    )
    if configuration_path is not None:
        actual = sha256_file(configuration_path)
        require(
            actual == configuration_hash,
            f"Configuration hash mismatch for {configuration_path}.",
        )
        checked.append(
            {
                "kind": "configuration",
                "path": str(configuration_path),
                "sha256": actual,
            }
        )
    else:
        warnings.append(
            "The recorded configuration source was unavailable; its manifest hash "
            "could not be re-read."
        )

    qemu = manifest.get("qemu")
    require(isinstance(qemu, dict), "Manifest QEMU metadata is missing.")
    require_sha256(qemu.get("sha256"), "Manifest QEMU hash")
    firmware = qemu.get("firmware")
    require(isinstance(firmware, dict), "Manifest firmware metadata is missing.")
    seabios = firmware.get("seabios")
    edk2 = firmware.get("edk2")
    require(isinstance(seabios, dict), "Manifest SeaBIOS metadata is missing.")
    require(isinstance(edk2, dict), "Manifest EDK2 metadata is missing.")
    require_sha256(seabios.get("sha256"), "Manifest SeaBIOS hash")
    require_sha256(edk2.get("sha256"), "Manifest EDK2 hash")
    require_sha256(edk2.get("vars_sha256"), "Manifest EDK2 variables hash")

    guest = manifest.get("guest_artifacts")
    require(isinstance(guest, dict), "Manifest guest artifact metadata is missing.")
    guest_manifest_hash = require_sha256(
        guest.get("sha256"), "Manifest guest-manifest hash"
    )
    recorded_artifacts = guest.get("artifacts")
    require(
        isinstance(recorded_artifacts, list),
        "Manifest guest artifact list is missing.",
    )
    for index, artifact in enumerate(recorded_artifacts):
        require(
            isinstance(artifact, dict),
            f"Manifest guest artifact {index} is not an object.",
        )
        require_sha256(
            artifact.get("sha256"), f"Manifest guest artifact {index} hash"
        )

    guest_manifest_path = resolve_recorded_path(result_directory, guest.get("path"))
    if guest_manifest_path is not None:
        actual = sha256_file(guest_manifest_path)
        require(
            actual == guest_manifest_hash,
            f"Guest manifest hash mismatch for {guest_manifest_path}.",
        )
        checked.append(
            {
                "kind": "guest_manifest",
                "path": str(guest_manifest_path),
                "sha256": actual,
            }
        )
        guest_manifest = load_json(guest_manifest_path)
        source_artifacts = guest_manifest.get("artifacts")
        require(
            isinstance(source_artifacts, list),
            "Guest manifest artifact list is missing.",
        )
        source_by_name = {
            Path(str(item.get("path", ""))).name: item
            for item in source_artifacts
            if isinstance(item, dict)
        }
        for artifact in recorded_artifacts:
            name = Path(str(artifact.get("path", ""))).name
            require(name in source_by_name, f"Guest artifact {name!r} is not recorded.")
            source_hash = require_sha256(
                source_by_name[name].get("sha256"),
                f"Guest manifest artifact {name!r} hash",
            )
            require(
                source_hash == str(artifact.get("sha256")).lower(),
                f"Guest artifact hash mismatch for {name!r}.",
            )
    else:
        warnings.append(
            "The recorded guest manifest was unavailable; its hash and artifact "
            "entries could not be re-read."
        )

    return checked, warnings


def directional_speedup(
    baseline: float, candidate: float, direction: str
) -> float:
    require(direction in VALID_DIRECTIONS, f"Invalid metric direction {direction!r}.")
    require(baseline > 0 and candidate > 0, "Speedup values must be positive.")
    if direction == "lower":
        return baseline / candidate
    return candidate / baseline


def calculate_statistics(values: Iterable[float]) -> dict[str, float | int | None]:
    samples = [float(value) for value in values]
    require(bool(samples), "Cannot calculate statistics for an empty sample.")
    for index, value in enumerate(samples):
        require(math.isfinite(value), f"Sample {index} is not finite.")
    arithmetic_mean = statistics.fmean(samples)
    sample_stdev = statistics.stdev(samples) if len(samples) > 1 else 0.0
    coefficient_of_variation = (
        sample_stdev / abs(arithmetic_mean) if arithmetic_mean != 0 else None
    )
    return {
        "count": len(samples),
        "median": statistics.median(samples),
        "mean": arithmetic_mean,
        "sample_stdev": sample_stdev,
        "coefficient_of_variation": coefficient_of_variation,
        "minimum": min(samples),
        "maximum": max(samples),
    }


def find_known_answer_value(record: dict[str, Any], metric: str) -> Any:
    primary = record.get("primary_result")
    if isinstance(primary, dict) and metric in primary:
        return primary[metric]
    guest_records = record.get("guest_records")
    if isinstance(guest_records, list):
        for guest_record in guest_records:
            if isinstance(guest_record, dict) and metric in guest_record:
                return guest_record[metric]
    return None


def find_guest_vcpus(record: dict[str, Any]) -> Any:
    guest_records = record.get("guest_records")
    if not isinstance(guest_records, list):
        return None
    for guest_record in guest_records:
        if (
            isinstance(guest_record, dict)
            and guest_record.get("workload") == "guest-metadata"
            and guest_record.get("metric") == "online_vcpus"
        ):
            return guest_record.get("value")
    return None


def load_guest_raw_json(path: Path) -> dict[str, Any]:
    records = load_jsonl(path)
    require(bool(records), f"Raw JSONL file is empty: {path}")
    require(len(records) == 1, f"Expected one raw JSON object in {path}.")
    return records[0]


def validate_raw_result(
    record: dict[str, Any],
    cell: dict[str, Any],
    result_directory: Path,
) -> str | None:
    workload = str(record.get("workload", ""))
    if not (workload.startswith("fio-") or workload.startswith("iperf-")):
        return None

    run_id = str(record["run_id"])
    raw_directory = result_directory / "raw" / run_id
    require(raw_directory.is_dir(), f"Raw result directory is missing: {raw_directory}")
    primary = record.get("primary_result")
    require(isinstance(primary, dict), f"Run {run_id!r} has no primary result.")
    normalized = require_finite_number(
        primary.get("value"), f"Run {run_id!r} normalized value"
    )

    if workload.startswith("fio-"):
        raw_path = raw_directory / "guest-raw.jsonl"
        raw = load_guest_raw_json(raw_path)
        jobs = raw.get("jobs")
        require(
            isinstance(jobs, list)
            and jobs
            and all(isinstance(job, dict) for job in jobs),
            f"fio raw result has invalid jobs in {raw_path}.",
        )
        parameters = cell.get("parameters")
        require(isinstance(parameters, dict), f"Cell parameters are missing for {run_id!r}.")
        rw_mode = str(parameters.get("rw", ""))
        if rw_mode.endswith("read"):
            operation = "read"
        elif rw_mode.endswith("write"):
            operation = "write"
        else:
            raise AnalysisError(f"Invalid fio operation for {run_id!r}.")
        raw_value = 0.0
        for job_index, job in enumerate(jobs):
            operation_result = job.get(operation)
            require(
                isinstance(operation_result, dict),
                f"fio raw job {job_index} has no {operation!r} object in {raw_path}.",
            )
            raw_value += require_finite_number(
                operation_result.get("bw_bytes"),
                f"fio raw bandwidth for {run_id!r} job {job_index}",
            )
    else:
        parameters = cell.get("parameters")
        require(isinstance(parameters, dict), f"Run {run_id!r} parameters are missing.")
        direction = parameters.get("direction")
        require(
            direction in {"guest-to-host", "host-to-guest"},
            f"Invalid iperf direction for {run_id!r}.",
        )
        raw_path = (
            raw_directory / "guest-raw.jsonl"
            if direction == "guest-to-host"
            else raw_directory / "host-iperf.json"
        )
        raw = (
            load_guest_raw_json(raw_path)
            if raw_path.suffix == ".jsonl"
            else load_json(raw_path)
        )
        end = raw.get("end")
        require(isinstance(end, dict), f"iperf raw result has no end object in {raw_path}.")
        sum_name = "sum_sent" if direction == "guest-to-host" else "sum_received"
        sum_received = end.get(sum_name)
        require(
            isinstance(sum_received, dict),
            f"iperf raw result has no {sum_name} object in {raw_path}.",
        )
        raw_value = require_finite_number(
            sum_received.get("bits_per_second"),
            f"iperf raw bandwidth for {run_id!r}",
        )

    require(
        math.isclose(normalized, raw_value, rel_tol=1e-9, abs_tol=0.5),
        f"Raw result mismatch for {run_id!r}: normalized {normalized}, raw {raw_value}.",
    )
    return str(raw_path)


def iter_record_metrics(record: dict[str, Any]) -> Iterable[dict[str, Any]]:
    primary = record.get("primary_result")
    require(
        isinstance(primary, dict),
        f"Successful run {record.get('run_id')!r} has no primary result.",
    )
    yield primary

    workload = str(record.get("workload", ""))
    if workload not in {"minimal-boot", "full-boot"}:
        return
    host_timing = record.get("host_timing")
    require(
        isinstance(host_timing, dict),
        f"Boot run {record.get('run_id')!r} has no host timing.",
    )
    derived = (
        (
            "host_to_first_serial_seconds",
            host_timing.get("first_serial_seconds"),
        ),
        ("host_to_ready_seconds", host_timing.get("ready_seconds")),
    )
    for metric, value in derived:
        if metric == primary.get("metric"):
            continue
        if value is None:
            continue
        yield {
            "metric": metric,
            "value": value,
            "unit": "seconds",
            "direction": "lower",
        }


def validate_inputs(
    manifest: dict[str, Any],
    records: list[dict[str, Any]],
    result_directory: Path,
) -> dict[str, Any]:
    require(manifest.get("schema") == SCHEMA_VERSION, "Unsupported manifest schema.")
    matrix = manifest.get("matrix")
    require(isinstance(matrix, dict), "Manifest matrix is missing.")
    cells = matrix.get("cells")
    require(isinstance(cells, list), "Manifest matrix cells are missing.")
    cell_by_id: dict[str, dict[str, Any]] = {}
    planned_cells: list[dict[str, Any]] = []
    skipped_cells: list[dict[str, Any]] = []
    for index, cell in enumerate(cells):
        require(isinstance(cell, dict), f"Matrix cell {index} is not an object.")
        cell_id = str(cell.get("cell_id", ""))
        require(bool(cell_id), f"Matrix cell {index} has no cell_id.")
        require(cell_id not in cell_by_id, f"Duplicate matrix cell ID {cell_id!r}.")
        status = cell.get("status")
        require(
            status in {"planned", "skipped"},
            f"Matrix cell {cell_id!r} has invalid status {status!r}.",
        )
        if status == "planned":
            planned_cells.append(cell)
        else:
            skipped_cells.append(cell)
        cell_by_id[cell_id] = cell
    require(
        matrix.get("planned_cells") == len(planned_cells),
        "Manifest planned-cell count does not match its matrix cells.",
    )
    require(
        matrix.get("skipped_cells") == len(skipped_cells),
        "Manifest skipped-cell count does not match its matrix cells.",
    )

    run_order = manifest.get("run_order")
    require(isinstance(run_order, list), "Manifest run order is missing.")
    expected_by_id: dict[str, dict[str, Any]] = {}
    runs_by_cell: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for index, expected in enumerate(run_order):
        require(isinstance(expected, dict), f"Run order entry {index} is not an object.")
        run_id = str(expected.get("run_id", ""))
        require(bool(run_id), f"Run order entry {index} has no run_id.")
        require(run_id not in expected_by_id, f"Duplicate planned run ID {run_id!r}.")
        cell_id = str(expected.get("cell_id", ""))
        require(
            cell_id in cell_by_id,
            f"Planned run {run_id!r} references an unknown cell.",
        )
        require(
            cell_by_id[cell_id].get("status") == "planned",
            f"Run order includes skipped cell {cell_id!r}.",
        )
        require(
            expected.get("schedule_index") == index,
            f"Run order entry {run_id!r} has the wrong schedule index.",
        )
        expected_by_id[run_id] = expected
        runs_by_cell[cell_id].append(expected)

    expected_run_count = 0
    for cell in planned_cells:
        cell_id = str(cell["cell_id"])
        warmups = int(cell.get("warmups", -1))
        repetitions = int(cell.get("repetitions", -1))
        total_runs = int(cell.get("total_runs", -1))
        require(
            warmups >= 0 and repetitions >= 0,
            f"Cell {cell_id!r} has invalid repetition counts.",
        )
        require(
            total_runs == warmups + repetitions,
            f"Cell {cell_id!r} total_runs does not equal warmups plus repetitions.",
        )
        expected_run_count += total_runs
        cell_runs = runs_by_cell.get(cell_id, [])
        require(
            len(cell_runs) == total_runs,
            f"Planned cell {cell_id!r} has {len(cell_runs)} scheduled runs, "
            f"expected {total_runs}.",
        )
        expected_identities = {
            (
                f"{cell_id}__warmup-{repetition:02d}",
                True,
                repetition,
            )
            for repetition in range(1, warmups + 1)
        }
        expected_identities.update(
            {
                (
                    f"{cell_id}__measure-{repetition:02d}",
                    False,
                    repetition,
                )
                for repetition in range(1, repetitions + 1)
            }
        )
        actual_identities = {
            (
                str(run.get("run_id")),
                run.get("is_warmup"),
                run.get("repetition"),
            )
            for run in cell_runs
        }
        require(
            actual_identities == expected_identities,
            f"Scheduled run identities do not match cell {cell_id!r}.",
        )
        for run in cell_runs:
            require(
                run.get("environment") == cell.get("environment"),
                f"Scheduled run {run.get('run_id')!r} has the wrong environment.",
            )
    require(
        len(run_order) == expected_run_count,
        "Manifest run-order count does not match planned cell totals.",
    )

    observed_by_id: dict[str, dict[str, Any]] = {}
    for index, record in enumerate(records):
        require(record.get("schema") == SCHEMA_VERSION, f"Run {index} has bad schema.")
        run_id = str(record.get("run_id", ""))
        require(bool(run_id), f"Run record {index} has no run_id.")
        require(run_id not in observed_by_id, f"Duplicate run ID {run_id!r}.")
        observed_by_id[run_id] = record

    missing = sorted(set(expected_by_id) - set(observed_by_id))
    extra = sorted(set(observed_by_id) - set(expected_by_id))
    require(not missing, f"Missing planned runs: {', '.join(missing[:10])}")
    require(not extra, f"Unexpected runs: {', '.join(extra[:10])}")

    known_answers_checked = 0
    guest_vcpu_records_checked = 0
    raw_records_checked = 0
    raw_paths: list[str] = []
    for run_id, expected in expected_by_id.items():
        record = observed_by_id[run_id]
        cell_id = str(expected["cell_id"])
        cell = cell_by_id[cell_id]
        require(record.get("cell_id") == cell_id, f"Run {run_id!r} has wrong cell_id.")
        require(
            record.get("schedule_index") == expected.get("schedule_index"),
            f"Run {run_id!r} has the wrong schedule index.",
        )
        require(
            record.get("environment") == cell.get("environment"),
            f"Run {run_id!r} has the wrong environment.",
        )
        require(
            record.get("workload") == cell.get("workload"),
            f"Run {run_id!r} has the wrong workload.",
        )
        require(
            record.get("vcpus") == cell.get("vcpus"),
            f"Run {run_id!r} has the wrong vCPU count.",
        )
        for field in ("guest", "runner", "accelerator", "ram_mib", "parameters"):
            require(
                record.get(field) == cell.get(field),
                f"Run {run_id!r} has mismatched {field}.",
            )
        require(
            record.get("is_warmup") == expected.get("is_warmup"),
            f"Run {run_id!r} has the wrong warmup flag.",
        )
        require(
            record.get("repetition") == expected.get("repetition"),
            f"Run {run_id!r} has the wrong repetition.",
        )
        status = record.get("status")
        require(status in VALID_STATUSES, f"Run {run_id!r} has invalid status {status!r}.")
        require(
            record.get("metric_direction") == cell.get("metric_direction"),
            f"Run {run_id!r} has the wrong metric direction.",
        )
        if status != "success":
            continue

        for metric in iter_record_metrics(record):
            direction = metric.get("direction")
            require(
                direction in VALID_DIRECTIONS,
                f"Run {run_id!r} has invalid direction {direction!r}.",
            )
            require(
                direction == cell.get("metric_direction"),
                f"Run {run_id!r} metric direction differs from its cell.",
            )
            require(bool(metric.get("metric")), f"Run {run_id!r} has no metric name.")
            require(bool(metric.get("unit")), f"Run {run_id!r} has no metric unit.")
            require_finite_number(metric.get("value"), f"Run {run_id!r} metric value")

        known_answer = cell.get("known_answer")
        if isinstance(known_answer, dict):
            metric = str(known_answer.get("metric", ""))
            require(bool(metric), f"Cell {cell_id!r} has an invalid known answer.")
            actual = find_known_answer_value(record, metric)
            require(
                actual == known_answer.get("value"),
                f"Known-answer failure for {run_id!r}: expected "
                f"{known_answer.get('value')!r}, got {actual!r}.",
            )
            known_answers_checked += 1

        if not bool(cell.get("reference_only")):
            guest_vcpus = find_guest_vcpus(record)
            require(
                guest_vcpus == cell.get("vcpus"),
                f"Guest vCPU metadata mismatch for {run_id!r}: expected "
                f"{cell.get('vcpus')!r}, got {guest_vcpus!r}.",
            )
            guest_vcpu_records_checked += 1

        raw_path = validate_raw_result(record, cell, result_directory)
        if raw_path is not None:
            raw_records_checked += 1
            raw_paths.append(raw_path)

    return {
        "cell_by_id": cell_by_id,
        "expected_by_id": expected_by_id,
        "observed_by_id": observed_by_id,
        "known_answers_checked": known_answers_checked,
        "guest_vcpu_records_checked": guest_vcpu_records_checked,
        "raw_records_checked": raw_records_checked,
        "raw_paths": raw_paths,
    }


def build_summary(
    manifest: dict[str, Any],
    records: list[dict[str, Any]],
    validation: dict[str, Any],
    result_directory: Path,
    cv_warning_threshold: float,
    source_hashes_checked: list[dict[str, str]],
    source_warnings: list[str],
) -> dict[str, Any]:
    cell_by_id = validation["cell_by_id"]
    grouped_values: dict[
        tuple[str, str, int, str], list[tuple[float, str, str, str]]
    ] = defaultdict(list)
    group_cells: dict[tuple[str, str, int, str], dict[str, Any]] = {}

    for record in records:
        if record.get("status") != "success" or record.get("is_warmup"):
            continue
        cell = cell_by_id[str(record["cell_id"])]
        for metric in iter_record_metrics(record):
            key = (
                str(record["workload"]),
                str(record["environment"]),
                int(record["vcpus"]),
                str(metric["metric"]),
            )
            value = require_finite_number(
                metric.get("value"), f"Run {record['run_id']!r} metric value"
            )
            grouped_values[key].append(
                (
                    value,
                    str(metric["unit"]),
                    str(metric["direction"]),
                    str(record["run_id"]),
                )
            )
            group_cells[key] = cell

    baseline_environment: dict[tuple[str, int], str] = {}
    for cell in manifest["matrix"]["cells"]:
        if cell.get("status") != "planned" or cell.get("reference_only"):
            continue
        key = (str(cell["workload"]), int(cell["vcpus"]))
        baseline_environment.setdefault(key, str(cell["environment"]))

    groups: list[dict[str, Any]] = []
    group_by_key: dict[tuple[str, str, int, str], dict[str, Any]] = {}
    for key in sorted(grouped_values):
        workload, environment, vcpus, metric_name = key
        samples = grouped_values[key]
        units = {sample[1] for sample in samples}
        directions = {sample[2] for sample in samples}
        require(
            len(units) == 1,
            f"Inconsistent units for {workload}/{environment}/{vcpus}/{metric_name}.",
        )
        require(
            len(directions) == 1,
            f"Inconsistent directions for "
            f"{workload}/{environment}/{vcpus}/{metric_name}.",
        )
        stats = calculate_statistics(sample[0] for sample in samples)
        cell = group_cells[key]
        group = {
            "group_id": f"{workload}__{environment}__{vcpus}vcpu__{metric_name}",
            "cell_id": cell.get("cell_id"),
            "workload": workload,
            "environment": environment,
            "runner": cell.get("runner"),
            "accelerator": cell.get("accelerator"),
            "reference_only": bool(cell.get("reference_only")),
            "vcpus": vcpus,
            "metric": metric_name,
            "unit": next(iter(units)),
            "direction": next(iter(directions)),
            **stats,
            "baseline_environment": baseline_environment.get((workload, vcpus)),
            "relative_speedup": None,
            "relative_percent": None,
            "run_ids": [sample[3] for sample in samples],
        }
        groups.append(group)
        group_by_key[key] = group

    for group in groups:
        if group["reference_only"]:
            continue
        baseline_key = (
            group["workload"],
            group["baseline_environment"],
            group["vcpus"],
            group["metric"],
        )
        baseline = group_by_key.get(baseline_key)
        if baseline is None:
            continue
        speedup = directional_speedup(
            float(baseline["median"]),
            float(group["median"]),
            str(group["direction"]),
        )
        group["relative_speedup"] = speedup
        group["relative_percent"] = (speedup - 1.0) * 100.0

    warnings: list[dict[str, Any]] = [
        {"kind": "source", "message": warning} for warning in source_warnings
    ]
    for group in groups:
        coefficient = group["coefficient_of_variation"]
        if coefficient is not None and coefficient > cv_warning_threshold:
            warnings.append(
                {
                    "kind": "high_variance",
                    "group_id": group["group_id"],
                    "coefficient_of_variation": coefficient,
                    "threshold": cv_warning_threshold,
                    "message": (
                        f"{group['group_id']} has CV {coefficient:.2%}, above "
                        f"{cv_warning_threshold:.2%}."
                    ),
                }
            )

    status_counts = Counter(str(record.get("status")) for record in records)
    measured_records = [record for record in records if not record.get("is_warmup")]
    warmup_records = [record for record in records if record.get("is_warmup")]
    measured_status_counts = Counter(
        str(record.get("status")) for record in measured_records
    )
    warmup_status_counts = Counter(
        str(record.get("status")) for record in warmup_records
    )
    failed_runs = [
        {
            "run_id": record.get("run_id"),
            "cell_id": record.get("cell_id"),
            "status": record.get("status"),
            "error": record.get("error"),
        }
        for record in records
        if record.get("status") == "error"
    ]
    skipped_runs = [
        {
            "run_id": record.get("run_id"),
            "cell_id": record.get("cell_id"),
            "status": record.get("status"),
            "error": record.get("error"),
        }
        for record in records
        if record.get("status") == "skipped"
    ]
    skipped_cells = [
        {
            "cell_id": cell.get("cell_id"),
            "workload": cell.get("workload"),
            "environment": cell.get("environment"),
            "vcpus": cell.get("vcpus"),
            "reason": cell.get("skip_reason"),
        }
        for cell in manifest["matrix"]["cells"]
        if cell.get("status") == "skipped"
    ]

    return {
        "schema": SCHEMA_VERSION,
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "result_directory": str(result_directory.resolve()),
        "manifest": {
            "profile": manifest.get("profile"),
            "session_id": manifest.get("session_id"),
            "created_utc": manifest.get("created_utc"),
            "configuration_sha256": manifest["configuration"]["sha256"],
            "qemu_sha256": manifest["qemu"]["sha256"],
            "guest_manifest_sha256": manifest["guest_artifacts"]["sha256"],
        },
        "validation": {
            "expected_runs": len(validation["expected_by_id"]),
            "observed_runs": len(records),
            "known_answers_checked": validation["known_answers_checked"],
            "guest_vcpu_records_checked": validation[
                "guest_vcpu_records_checked"
            ],
            "raw_records_checked": validation["raw_records_checked"],
            "source_hashes_checked": source_hashes_checked,
        },
        "counts": {
            "total": len(records),
            "success": status_counts["success"],
            "error": status_counts["error"],
            "skipped": status_counts["skipped"],
            "measured": len(measured_records),
            "measured_success": measured_status_counts["success"],
            "measured_error": measured_status_counts["error"],
            "measured_skipped": measured_status_counts["skipped"],
            "warmup": len(warmup_records),
            "warmup_success": warmup_status_counts["success"],
            "warmup_error": warmup_status_counts["error"],
            "warmup_skipped": warmup_status_counts["skipped"],
            "planned_cells": sum(
                1
                for cell in manifest["matrix"]["cells"]
                if cell.get("status") == "planned"
            ),
            "skipped_cells": len(skipped_cells),
        },
        "cv_warning_threshold": cv_warning_threshold,
        "groups": groups,
        "warnings": warnings,
        "failed_runs": failed_runs,
        "skipped_runs": skipped_runs,
        "skipped_cells": skipped_cells,
    }


def markdown_escape(value: Any) -> str:
    return str(value).replace("|", r"\|").replace("\r", " ").replace("\n", " ")


def format_number(value: Any) -> str:
    if value is None:
        return "-"
    number = float(value)
    magnitude = abs(number)
    if magnitude >= 1000:
        return f"{number:,.2f}"
    if magnitude >= 1:
        return f"{number:.3f}"
    if magnitude == 0:
        return "0"
    return f"{number:.4g}"


def format_ratio(value: Any) -> str:
    return "-" if value is None else f"{float(value):.3f}x"


def format_cv(value: Any) -> str:
    return "-" if value is None else f"{float(value):.2%}"


def render_markdown_table(headers: list[str], rows: list[list[Any]]) -> list[str]:
    lines = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join("---" for _ in headers) + " |",
    ]
    lines.extend(
        "| " + " | ".join(markdown_escape(value) for value in row) + " |"
        for row in rows
    )
    return lines


def select_groups(
    groups: list[dict[str, Any]],
    workloads: Iterable[str] | None = None,
    prefixes: Iterable[str] | None = None,
    environments: set[str] | None = None,
) -> list[dict[str, Any]]:
    workload_set = set(workloads or [])
    prefix_tuple = tuple(prefixes or [])
    selected = []
    for group in groups:
        workload = str(group["workload"])
        if workload_set or prefix_tuple:
            if workload not in workload_set and not workload.startswith(prefix_tuple):
                continue
        if environments is not None and group["environment"] not in environments:
            continue
        selected.append(group)
    return selected


def standard_group_rows(groups: list[dict[str, Any]]) -> list[list[Any]]:
    return [
        [
            group["workload"],
            group["metric"],
            group["vcpus"],
            group["environment"],
            group["count"],
            f"{format_number(group['median'])} {group['unit']}",
            format_number(group["mean"]),
            format_number(group["sample_stdev"]),
            format_cv(group["coefficient_of_variation"]),
            format_ratio(group["relative_speedup"]),
        ]
        for group in groups
    ]


def scaling_efficiency(
    group: dict[str, Any], groups: list[dict[str, Any]]
) -> float | None:
    if int(group["vcpus"]) == 1:
        return 1.0
    baseline = next(
        (
            candidate
            for candidate in groups
            if candidate["workload"] == group["workload"]
            and candidate["environment"] == group["environment"]
            and candidate["metric"] == group["metric"]
            and int(candidate["vcpus"]) == 1
        ),
        None,
    )
    if baseline is None:
        return None
    speedup = directional_speedup(
        float(baseline["median"]),
        float(group["median"]),
        str(group["direction"]),
    )
    return speedup / int(group["vcpus"])


def generate_report(
    manifest: dict[str, Any], summary: dict[str, Any]
) -> str:
    groups = summary["groups"]
    host = manifest["host"]
    qemu = manifest["qemu"]
    configuration = manifest["configuration"]
    guest_artifacts = manifest["guest_artifacts"]
    counts = summary["counts"]

    lines = [
        "# Windows Accelerator Benchmark Report",
        "",
        f"Generated from session `{markdown_escape(manifest.get('session_id'))}` "
        f"using the `{markdown_escape(manifest.get('profile'))}` profile.",
        "",
        "## 1. Environment",
        "",
    ]
    cpu_names = ", ".join(
        str(cpu.get("name"))
        for cpu in host.get("cpu", [])
        if isinstance(cpu, dict) and cpu.get("name")
    )
    metadata_rows = [
        ["Windows", f"{host.get('windows_caption')} build {host.get('windows_build')}"],
        ["Host model", host.get("computer_model")],
        ["CPU", cpu_names or "unknown"],
        ["Logical processors", host.get("logical_processors")],
        ["Memory", f"{host.get('total_memory_mib')} MiB"],
        ["Power plan", host.get("active_power_plan")],
        ["QEMU", str(qemu.get("version", "")).splitlines()[0]],
        ["QEMU SHA-256", qemu.get("sha256")],
        ["Configuration SHA-256", configuration.get("sha256")],
        ["Guest manifest SHA-256", guest_artifacts.get("sha256")],
        [
            "Git revision",
            f"{manifest.get('repository', {}).get('commit')} "
            f"(dirty={manifest.get('repository', {}).get('dirty')})",
        ],
    ]
    lines.extend(render_markdown_table(["Item", "Value"], metadata_rows))
    lines.extend(
        [
            "",
            "## 2. Methodology and completeness",
            "",
            f"The matrix contains {counts['planned_cells']} planned cells and "
            f"{counts['total']} recorded runs: {counts['warmup']} warmups and "
            f"{counts['measured']} measured repetitions. Warmups are excluded from "
            "all statistics. Relative speedup uses the first non-reference "
            "environment configured for each workload and vCPU count; values above "
            "1.0x are faster for both throughput and latency metrics.",
            "",
        ]
    )
    count_rows = [
        ["All runs", counts["success"], counts["error"], counts["skipped"]],
        [
            "Measured",
            counts["measured_success"],
            counts["measured_error"],
            counts["measured_skipped"],
        ],
        [
            "Warmup",
            counts["warmup_success"],
            counts["warmup_error"],
            counts["warmup_skipped"],
        ],
    ]
    lines.extend(
        render_markdown_table(["Scope", "Success", "Error", "Skipped"], count_rows)
    )

    headers = [
        "Workload",
        "Metric",
        "vCPU",
        "Environment",
        "n",
        "Median",
        "Mean",
        "Stddev",
        "CV",
        "Relative",
    ]

    prime_groups = select_groups(groups, workloads={"prime-v1"})
    lines.extend(["", "## 3. Original prime-v1 continuity", ""])
    lines.append(
        "Every successful `prime-v1` run was validated against the original count "
        "of `216816`."
    )
    lines.append("")
    lines.extend(render_markdown_table(headers, standard_group_rows(prime_groups)))

    cpu_groups = select_groups(groups, workloads={"prime-smp", "sysbench-cpu"})
    cpu_rows = []
    for group in cpu_groups:
        cpu_rows.append(
            standard_group_rows([group])[0]
            + [
                (
                    "-"
                    if scaling_efficiency(group, cpu_groups) is None
                    else f"{scaling_efficiency(group, cpu_groups):.2%}"
                )
            ]
        )
    lines.extend(["", "## 4. CPU and SMP scaling", ""])
    lines.extend(render_markdown_table(headers + ["Scaling efficiency"], cpu_rows))

    memory_groups = select_groups(
        groups, prefixes={"memory-", "sysbench-memory-"}
    )
    lines.extend(["", "## 5. Memory throughput", ""])
    lines.extend(render_markdown_table(headers, standard_group_rows(memory_groups)))

    boot_groups = select_groups(
        groups, workloads={"minimal-boot", "full-boot"}
    )
    lines.extend(["", "## 6. Boot timing", ""])
    lines.extend(render_markdown_table(headers, standard_group_rows(boot_groups)))

    fio_groups = select_groups(groups, prefixes={"fio-"})
    lines.extend(["", "## 7. Disk fio results", ""])
    lines.append(
        "QEMU uses per-run qcow2 overlays backed by VHDX through virtio-blk; "
        "Hyper-V uses native differencing VHDX through synthetic SCSI."
    )
    lines.append("")
    lines.extend(render_markdown_table(headers, standard_group_rows(fio_groups)))

    iperf_groups = select_groups(groups, prefixes={"iperf-"})
    lines.extend(["", "## 8. Network iperf3 results", ""])
    lines.append(
        "QEMU uses virtio-net-pci with libslirp user networking and host "
        "forwarding; Hyper-V uses a synthetic NIC and dedicated internal vSwitch."
    )
    lines.append("")
    lines.extend(render_markdown_table(headers, standard_group_rows(iperf_groups)))

    irq_groups = select_groups(
        groups,
        workloads={"full-boot"},
        prefixes={"fio-", "iperf-"},
        environments={"qemu-whpx-irqchip-on", "qemu-whpx-irqchip-off"},
    )
    lines.extend(["", "## 9. WHPX irqchip on/off comparison", ""])
    lines.extend(render_markdown_table(headers, standard_group_rows(irq_groups)))

    lines.extend(["", "## 10. Variance, failures, and skips", ""])
    variance_warnings = [
        warning
        for warning in summary["warnings"]
        if warning.get("kind") == "high_variance"
    ]
    source_warnings = [
        warning for warning in summary["warnings"] if warning.get("kind") == "source"
    ]
    if variance_warnings:
        lines.append(
            f"{len(variance_warnings)} groups exceeded the configured CV threshold "
            f"of {summary['cv_warning_threshold']:.2%}:"
        )
        lines.append("")
        lines.extend(f"- {warning['message']}" for warning in variance_warnings)
    else:
        lines.append(
            f"No groups exceeded the configured CV threshold of "
            f"{summary['cv_warning_threshold']:.2%}."
        )
    if source_warnings:
        lines.append("")
        lines.extend(f"- {warning['message']}" for warning in source_warnings)
    if summary["failed_runs"] or summary["skipped_runs"] or summary["skipped_cells"]:
        lines.append("")
        status_rows = [
            [
                item.get("run_id") or item.get("cell_id"),
                item.get("status", "skipped-cell"),
                item.get("error") or item.get("reason"),
            ]
            for item in (
                summary["failed_runs"]
                + summary["skipped_runs"]
                + summary["skipped_cells"]
            )
        ]
        lines.extend(
            render_markdown_table(["Run or cell", "Status", "Reason"], status_rows)
        )
    else:
        lines.append("")
        lines.append("There were no final failed or skipped runs or cells.")

    lines.extend(
        [
            "",
            "## 11. Interpretation caveats",
            "",
            "- CPU and custom-memory results are the closest accelerator comparison, "
            "but WHPX and Hyper-V still share the Windows hypervisor.",
            "- Disk results include storage format, block layer, controller, and host "
            "I/O effects; they are not accelerator-only measurements.",
            "- Network results compare libslirp/virtio-net with Hyper-V's internal "
            "vSwitch/synthetic NIC and must be treated as end-to-end guest networking.",
            "- Minimal boot uses SeaBIOS/Generation 1 paths, while full boot compares "
            "Q35+EDK2+virtio-blk with Hyper-V Generation 2+synthetic SCSI.",
            "- The host filesystem cache was not dropped. The first run was discarded "
            "as a warmup, and high variance is reported rather than removed.",
            "",
        ]
    )
    return "\n".join(lines)


def analyze_directory(
    result_directory: Path, cv_warning_threshold: float
) -> tuple[dict[str, Any], str]:
    result_directory = result_directory.resolve()
    require(
        result_directory.is_dir(),
        f"Result directory does not exist: {result_directory}",
    )
    require(
        math.isfinite(cv_warning_threshold) and cv_warning_threshold >= 0,
        "CV warning threshold must be a finite non-negative number.",
    )
    manifest = load_json(result_directory / "manifest.json")
    records = load_jsonl(result_directory / "runs.jsonl")
    source_hashes_checked, source_warnings = verify_source_hashes(
        manifest, result_directory
    )
    validation = validate_inputs(manifest, records, result_directory)
    summary = build_summary(
        manifest,
        records,
        validation,
        result_directory,
        cv_warning_threshold,
        source_hashes_checked,
        source_warnings,
    )
    report = generate_report(manifest, summary)
    return summary, report


def write_json(path: Path, value: dict[str, Any]) -> None:
    path.write_text(
        json.dumps(value, indent=2, sort_keys=False, allow_nan=False) + "\n",
        encoding="utf-8",
    )


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate and summarize Windows accelerator benchmark results."
    )
    parser.add_argument("result_directory", type=Path)
    parser.add_argument(
        "--cv-threshold",
        type=float,
        default=DEFAULT_CV_WARNING_THRESHOLD,
        help="Warn when sample coefficient of variation exceeds this fraction.",
    )
    parser.add_argument(
        "--summary",
        type=Path,
        help="Output summary JSON path (default: RESULT_DIRECTORY/summary.json).",
    )
    parser.add_argument(
        "--report",
        type=Path,
        help="Output Markdown report path (default: RESULT_DIRECTORY/report.md).",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        summary, report = analyze_directory(
            args.result_directory, args.cv_threshold
        )
        summary_path = args.summary or args.result_directory / "summary.json"
        report_path = args.report or args.result_directory / "report.md"
        summary_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.parent.mkdir(parents=True, exist_ok=True)
        write_json(summary_path, summary)
        report_path.write_text(report, encoding="utf-8")
    except (AnalysisError, OSError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    print(
        f"Wrote {summary_path} and {report_path} "
        f"({summary['counts']['measured_success']} measured successes)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
