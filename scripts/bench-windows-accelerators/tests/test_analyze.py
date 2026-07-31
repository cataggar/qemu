#!/usr/bin/env python3
"""Tests for the Windows accelerator benchmark analyzer."""

from __future__ import annotations

import copy
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from typing import Any


TEST_DIRECTORY = Path(__file__).resolve().parent
FIXTURE_DIRECTORY = TEST_DIRECTORY / "fixtures"
MODULE_PATH = TEST_DIRECTORY.parent / "analyze.py"
SPEC = importlib.util.spec_from_file_location("bench_analyze", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
analyze = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(analyze)


def fixture_json(name: str) -> dict[str, Any]:
    return json.loads((FIXTURE_DIRECTORY / name).read_text(encoding="utf-8"))


def fixture_jsonl(name: str) -> list[dict[str, Any]]:
    return [
        json.loads(line)
        for line in (FIXTURE_DIRECTORY / name)
        .read_text(encoding="utf-8")
        .splitlines()
        if line.strip()
    ]


def make_cell(
    workload: str,
    environment: str,
    vcpus: int,
    direction: str,
    *,
    metric: str,
    unit: str,
    value: float,
    parameters: dict[str, Any] | None = None,
    known_answer: dict[str, Any] | None = None,
    status: str = "planned",
    skip_reason: str | None = None,
    reference_only: bool = False,
) -> tuple[dict[str, Any], dict[str, Any]]:
    cell_id = f"{workload}__{environment}__{vcpus}vcpu"
    cell = {
        "cell_id": cell_id,
        "workload": workload,
        "guest": "micro" if workload.startswith("prime") else "system",
        "environment": environment,
        "runner": "hyperv" if environment == "hyperv" else "qemu",
        "accelerator": None if environment == "hyperv" else environment,
        "reference_only": reference_only,
        "vcpus": vcpus,
        "ram_mib": 2048,
        "warmups": 0,
        "repetitions": 1,
        "total_runs": 1,
        "metric_direction": direction,
        "parameters": parameters or {},
        "known_answer": known_answer,
        "status": status,
        "skip_reason": skip_reason,
    }
    run_id = f"{cell_id}__measure-01"
    primary = {
        "metric": metric,
        "value": value,
        "unit": unit,
        "direction": direction,
    }
    if known_answer is not None:
        primary[known_answer["metric"]] = known_answer["value"]
    record = {
        "schema": 1,
        "run_id": run_id,
        "schedule_index": 0,
        "cell_id": cell_id,
        "workload": workload,
        "guest": cell["guest"],
        "environment": environment,
        "runner": cell["runner"],
        "accelerator": cell["accelerator"],
        "vcpus": vcpus,
        "ram_mib": cell["ram_mib"],
        "is_warmup": False,
        "repetition": 1,
        "metric_direction": direction,
        "status": "success",
        "error": None,
        "parameters": parameters or {},
        "primary_result": primary,
        "guest_records": [
            {
                "workload": "guest-metadata",
                "metric": "online_vcpus",
                "value": vcpus,
                "unit": "count",
                "direction": "exact",
            }
        ],
        "host_timing": {},
    }
    return cell, record


def write_dataset(
    directory: Path,
    cells: list[dict[str, Any]],
    records: list[dict[str, Any]],
    *,
    manifest: dict[str, Any] | None = None,
) -> dict[str, Any]:
    output_manifest = copy.deepcopy(manifest or fixture_json("manifest.json"))
    output_manifest["matrix"] = {
        "planned_cells": sum(cell.get("status") == "planned" for cell in cells),
        "skipped_cells": sum(cell.get("status") == "skipped" for cell in cells),
        "cells": cells,
    }
    output_manifest["run_order"] = [
        {
            "run_id": record["run_id"],
            "schedule_index": index,
            "cell_id": record["cell_id"],
            "environment": record["environment"],
            "is_warmup": record["is_warmup"],
            "repetition": record["repetition"],
        }
        for index, record in enumerate(records)
    ]
    for index, record in enumerate(records):
        record["schedule_index"] = index
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "manifest.json").write_text(
        json.dumps(output_manifest, indent=2) + "\n", encoding="utf-8"
    )
    (directory / "runs.jsonl").write_text(
        "".join(json.dumps(record) + "\n" for record in records),
        encoding="utf-8",
    )
    for record in records:
        if record.get("status") != "success":
            continue
        workload = str(record["workload"])
        if not (workload.startswith("fio-") or workload.startswith("iperf-")):
            continue
        raw_directory = directory / "raw" / record["run_id"]
        raw_directory.mkdir(parents=True, exist_ok=True)
        if workload.startswith("fio-"):
            raw = fixture_json("fio.json")
            operation = record["parameters"]["rw"]
            raw["jobs"][0][operation]["bw_bytes"] = record["primary_result"]["value"]
            (raw_directory / "guest-raw.jsonl").write_text(
                json.dumps(raw) + "\n", encoding="utf-8"
            )
        else:
            raw = fixture_json("iperf.json")
            raw["end"]["sum_sent"]["bits_per_second"] = record[
                "primary_result"
            ]["value"]
            raw["end"]["sum_received"]["bits_per_second"] = record[
                "primary_result"
            ]["value"]
            if record["parameters"]["direction"] == "guest-to-host":
                path = raw_directory / "guest-raw.jsonl"
                path.write_text(json.dumps(raw) + "\n", encoding="utf-8")
            else:
                path = raw_directory / "host-iperf.json"
                path.write_text(json.dumps(raw) + "\n", encoding="utf-8")
    return output_manifest


class StatisticsTests(unittest.TestCase):
    def test_median_stdev_and_cv(self) -> None:
        result = analyze.calculate_statistics([1.0, 2.0, 3.0])
        self.assertEqual(result["count"], 3)
        self.assertEqual(result["median"], 2.0)
        self.assertEqual(result["mean"], 2.0)
        self.assertEqual(result["sample_stdev"], 1.0)
        self.assertEqual(result["coefficient_of_variation"], 0.5)
        self.assertEqual(result["minimum"], 1.0)
        self.assertEqual(result["maximum"], 3.0)

    def test_direction_aware_speedups(self) -> None:
        self.assertEqual(analyze.directional_speedup(10.0, 5.0, "lower"), 2.0)
        self.assertEqual(analyze.directional_speedup(10.0, 20.0, "higher"), 2.0)


class AnalyzerTests(unittest.TestCase):
    def test_fixture_excludes_warmup_and_checks_known_answer(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            manifest = fixture_json("manifest.json")
            records = fixture_jsonl("runs.jsonl")
            write_dataset(
                directory,
                manifest["matrix"]["cells"],
                records,
                manifest=manifest,
            )
            summary, report = analyze.analyze_directory(directory, 0.05)
        self.assertEqual(summary["counts"]["warmup"], 1)
        self.assertEqual(summary["counts"]["measured"], 1)
        self.assertEqual(summary["validation"]["known_answers_checked"], 2)
        self.assertEqual(summary["groups"][0]["count"], 1)
        self.assertEqual(summary["groups"][0]["median"], 10.0)
        self.assertIn("Original prime-v1 continuity", report)

    def test_missing_cell_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            manifest = fixture_json("manifest.json")
            records = fixture_jsonl("runs.jsonl")[:1]
            (directory / "manifest.json").write_text(
                json.dumps(manifest), encoding="utf-8"
            )
            (directory / "runs.jsonl").write_text(
                json.dumps(records[0]) + "\n", encoding="utf-8"
            )
            with self.assertRaisesRegex(analyze.AnalysisError, "Missing planned runs"):
                analyze.analyze_directory(directory, 0.05)

    def test_planned_cell_omitted_from_schedule_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            manifest = fixture_json("manifest.json")
            manifest["run_order"] = []
            (directory / "manifest.json").write_text(
                json.dumps(manifest), encoding="utf-8"
            )
            (directory / "runs.jsonl").write_text("", encoding="utf-8")
            with self.assertRaisesRegex(
                analyze.AnalysisError, "scheduled runs"
            ):
                analyze.analyze_directory(directory, 0.05)

    def test_known_answer_failure_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            manifest = fixture_json("manifest.json")
            records = fixture_jsonl("runs.jsonl")
            records[1]["primary_result"]["prime_count"] = 1
            write_dataset(
                directory,
                manifest["matrix"]["cells"],
                records,
                manifest=manifest,
            )
            with self.assertRaisesRegex(
                analyze.AnalysisError, "Known-answer failure"
            ):
                analyze.analyze_directory(directory, 0.05)

    def test_duplicate_resumed_run_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            manifest = fixture_json("manifest.json")
            records = fixture_jsonl("runs.jsonl")
            write_dataset(
                directory,
                manifest["matrix"]["cells"],
                records,
                manifest=manifest,
            )
            with (directory / "runs.jsonl").open("a", encoding="utf-8") as stream:
                stream.write(json.dumps(records[-1]) + "\n")
            with self.assertRaisesRegex(analyze.AnalysisError, "Duplicate run ID"):
                analyze.analyze_directory(directory, 0.05)

    def test_failed_and_skipped_runs_are_reported(self) -> None:
        success_cell, success = make_cell(
            "sysbench-cpu",
            "qemu-tcg-single",
            1,
            "higher",
            metric="events_per_second",
            unit="events/s",
            value=10,
        )
        error_cell, error = make_cell(
            "sysbench-cpu",
            "hyperv",
            1,
            "higher",
            metric="events_per_second",
            unit="events/s",
            value=20,
        )
        error["status"] = "error"
        error["error"] = "fixture error"
        error["primary_result"] = None
        error["guest_records"] = []
        skipped_cell, skipped = make_cell(
            "sysbench-cpu",
            "qemu-whpx-irqchip-on",
            1,
            "higher",
            metric="events_per_second",
            unit="events/s",
            value=30,
        )
        skipped["status"] = "skipped"
        skipped["error"] = "fixture skip"
        skipped["primary_result"] = None
        skipped["guest_records"] = []
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_dataset(
                directory,
                [success_cell, error_cell, skipped_cell],
                [success, error, skipped],
            )
            summary, report = analyze.analyze_directory(directory, 0.05)
        self.assertEqual(summary["counts"]["success"], 1)
        self.assertEqual(summary["counts"]["error"], 1)
        self.assertEqual(summary["counts"]["skipped"], 1)
        self.assertIn("fixture error", report)
        self.assertIn("fixture skip", report)

    def test_fio_and_iperf_raw_results_are_reconciled(self) -> None:
        fio_cell, fio_record = make_cell(
            "fio-sequential-read",
            "qemu-tcg-multi",
            4,
            "higher",
            metric="bytes_per_second",
            unit="bytes/s",
            value=1048576,
            parameters={"rw": "read"},
        )
        iperf_cell, iperf_record = make_cell(
            "iperf-guest-to-host-one",
            "qemu-tcg-multi",
            4,
            "higher",
            metric="bits_per_second",
            unit="bits/s",
            value=1000000,
            parameters={"direction": "guest-to-host"},
        )
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_dataset(
                directory,
                [fio_cell, iperf_cell],
                [fio_record, iperf_record],
            )
            multi_job_raw = fixture_json("fio.json")
            multi_job_raw["jobs"] = [
                {
                    "read": {"bw_bytes": 524288},
                    "write": {"bw_bytes": 0},
                },
                {
                    "read": {"bw_bytes": 524288},
                    "write": {"bw_bytes": 0},
                },
            ]
            (
                directory / "raw" / fio_record["run_id"] / "guest-raw.jsonl"
            ).write_text(json.dumps(multi_job_raw) + "\n", encoding="utf-8")
            summary, _ = analyze.analyze_directory(directory, 0.05)
            raw = json.loads(
                (
                    directory
                    / "raw"
                    / fio_record["run_id"]
                    / "guest-raw.jsonl"
                ).read_text(encoding="utf-8")
            )
            raw["jobs"][0]["read"]["bw_bytes"] = 1
            (
                directory / "raw" / fio_record["run_id"] / "guest-raw.jsonl"
            ).write_text(json.dumps(raw) + "\n", encoding="utf-8")
            with self.assertRaisesRegex(
                analyze.AnalysisError, "Raw result mismatch"
            ):
                analyze.analyze_directory(directory, 0.05)
        self.assertEqual(summary["validation"]["raw_records_checked"], 2)

    def test_record_parameters_must_match_matrix_cell(self) -> None:
        cell, record = make_cell(
            "fio-sequential-read",
            "qemu-tcg-multi",
            4,
            "higher",
            metric="bytes_per_second",
            unit="bytes/s",
            value=1048576,
            parameters={"rw": "read"},
        )
        record["parameters"] = {"rw": "write"}
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_dataset(directory, [cell], [record])
            with self.assertRaisesRegex(
                analyze.AnalysisError, "mismatched parameters"
            ):
                analyze.analyze_directory(directory, 0.05)

    def test_source_hash_mismatch_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            manifest = fixture_json("manifest.json")
            manifest["configuration"]["path"] = "configuration.json"
            records = fixture_jsonl("runs.jsonl")
            write_dataset(
                directory,
                manifest["matrix"]["cells"],
                records,
                manifest=manifest,
            )
            (directory / "configuration.json").write_text("{}\n", encoding="utf-8")
            with self.assertRaisesRegex(
                analyze.AnalysisError, "Configuration hash mismatch"
            ):
                analyze.analyze_directory(directory, 0.05)

    def test_report_contains_all_required_result_sections(self) -> None:
        specifications = [
            (
                "prime-smp",
                "qemu-tcg-single",
                1,
                "lower",
                "elapsed_seconds",
                "seconds",
                10.0,
                {},
            ),
            (
                "prime-smp",
                "qemu-tcg-single",
                2,
                "lower",
                "elapsed_seconds",
                "seconds",
                6.0,
                {},
            ),
            (
                "full-boot",
                "qemu-whpx-irqchip-on",
                4,
                "lower",
                "service_ready_seconds",
                "seconds",
                0.5,
                {},
            ),
            (
                "full-boot",
                "qemu-whpx-irqchip-off",
                4,
                "lower",
                "service_ready_seconds",
                "seconds",
                0.4,
                {},
            ),
            (
                "fio-sequential-read",
                "qemu-whpx-irqchip-on",
                4,
                "higher",
                "bytes_per_second",
                "bytes/s",
                1048576,
                {"rw": "read"},
            ),
            (
                "fio-sequential-read",
                "qemu-whpx-irqchip-off",
                4,
                "higher",
                "bytes_per_second",
                "bytes/s",
                1048576,
                {"rw": "read"},
            ),
            (
                "iperf-guest-to-host-one",
                "qemu-whpx-irqchip-on",
                4,
                "higher",
                "bits_per_second",
                "bits/s",
                1000000,
                {"direction": "guest-to-host"},
            ),
            (
                "iperf-guest-to-host-one",
                "qemu-whpx-irqchip-off",
                4,
                "higher",
                "bits_per_second",
                "bits/s",
                1000000,
                {"direction": "guest-to-host"},
            ),
        ]
        cells = []
        records = []
        for specification in specifications:
            cell, record = make_cell(
                specification[0],
                specification[1],
                specification[2],
                specification[3],
                metric=specification[4],
                unit=specification[5],
                value=specification[6],
                parameters=specification[7],
            )
            if specification[0] == "full-boot":
                record["host_timing"] = {
                    "first_serial_seconds": 3.0,
                    "ready_seconds": 10.0,
                }
            cells.append(cell)
            records.append(record)
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_dataset(directory, cells, records)
            _, report = analyze.analyze_directory(directory, 0.05)
        for heading in (
            "CPU and SMP scaling",
            "Boot timing",
            "Disk fio results",
            "Network iperf3 results",
            "WHPX irqchip on/off comparison",
        ):
            self.assertIn(heading, report)
        self.assertIn("Scaling efficiency", report)
        self.assertIn("qemu-whpx-irqchip-off", report)


if __name__ == "__main__":
    unittest.main()
