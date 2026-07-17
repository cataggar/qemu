#!/usr/bin/env python3

import argparse
import json
import subprocess
import tempfile
from pathlib import Path
from typing import List, Optional


FIXTURE_SIZE = 2 * 1024 * 1024
STATIC_DYLIB_NAMES = ("libslirp", "libglib-2.0", "libintl", "libzstd")


def run(
    command: List[str],
    *,
    input_text: Optional[str] = None,
    timeout: int = 30,
) -> subprocess.CompletedProcess[str]:
    try:
        result = subprocess.run(
            command,
            input=input_text,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(
            f"command timed out after {timeout}s: {' '.join(command)}"
        ) from error

    if result.returncode != 0:
        raise RuntimeError(
            f"command failed ({result.returncode}): {' '.join(command)}\n"
            f"stdout:\n{result.stdout}\n"
            f"stderr:\n{result.stderr}"
        )
    return result


def require_file(path: Path) -> None:
    if not path.is_file():
        raise RuntimeError(f"required package file is missing: {path}")


def verify_linkage(binary: Path) -> None:
    output = run(["otool", "-L", str(binary)]).stdout
    for line in output.splitlines()[1:]:
        dependency = line.strip().lower()
        if any(name in dependency for name in STATIC_DYLIB_NAMES):
            raise RuntimeError(
                f"{binary} dynamically links a dependency that must be static:\n"
                f"{line}"
            )
        if "zstd" in dependency and (
            "/opt/homebrew/" in dependency
            or "/usr/local/" in dependency
            or "/homebrew/" in dependency
        ):
            raise RuntimeError(
                f"{binary} contains a Homebrew Zstd dependency:\n{line}"
            )


def create_zstd_fixture(qemu_img: Path, directory: Path) -> Path:
    raw = directory / "zstd-fixture.raw"
    qcow2 = directory / "zstd-fixture.qcow2"
    round_trip = directory / "zstd-fixture.round-trip.raw"

    pattern = bytes(range(1, 256))
    raw.write_bytes(
        (pattern * ((FIXTURE_SIZE + len(pattern) - 1) // len(pattern)))[
            :FIXTURE_SIZE
        ]
    )

    run(
        [
            str(qemu_img),
            "convert",
            "-f",
            "raw",
            "-O",
            "qcow2",
            "-c",
            "-o",
            "compression_type=zstd,cluster_size=65536",
            str(raw),
            str(qcow2),
        ]
    )
    if qcow2.stat().st_size >= raw.stat().st_size:
        raise RuntimeError(
            "Zstd QCOW2 fixture is not smaller than its raw input: "
            f"{qcow2.stat().st_size} >= {raw.stat().st_size}"
        )

    info = json.loads(
        run([str(qemu_img), "info", "--output=json", str(qcow2)]).stdout
    )
    if info.get("format") != "qcow2":
        raise RuntimeError(f"unexpected fixture format: {info.get('format')!r}")
    if info.get("virtual-size") != FIXTURE_SIZE:
        raise RuntimeError(
            f"unexpected fixture virtual size: {info.get('virtual-size')!r}"
        )
    if info.get("cluster-size") != 65536:
        raise RuntimeError(
            f"unexpected fixture cluster size: {info.get('cluster-size')!r}"
        )
    try:
        format_specific = info["format-specific"]
        compression_type = format_specific["data"]["compression-type"]
    except (KeyError, TypeError) as error:
        raise RuntimeError(
            "qemu-img info did not report the QCOW2 compression type"
        ) from error
    if format_specific.get("type") != "qcow2":
        raise RuntimeError(
            "qemu-img info did not report QCOW2 format-specific data"
        )
    if compression_type != "zstd":
        raise RuntimeError(
            f"unexpected QCOW2 compression type: {compression_type!r}"
        )

    check = json.loads(
        run(
            [
                str(qemu_img),
                "check",
                "--output=json",
                "-f",
                "qcow2",
                str(qcow2),
            ]
        ).stdout
    )
    if check.get("check-errors") != 0:
        raise RuntimeError(f"qemu-img check reported errors: {check}")
    if check.get("compressed-clusters", 0) <= 0:
        raise RuntimeError(
            f"qemu-img check found no compressed clusters: {check}"
        )
    run(
        [
            str(qemu_img),
            "convert",
            "-f",
            "qcow2",
            "-O",
            "raw",
            str(qcow2),
            str(round_trip),
        ]
    )
    run(["cmp", str(raw), str(round_trip)])
    return qcow2


def verify_system_binary(binary: Path, fixture: Path) -> None:
    qmp_input = (
        '{"execute":"qmp_capabilities","id":"caps"}\n'
        '{"execute":"query-named-block-nodes","id":"nodes"}\n'
        '{"execute":"quit","id":"quit"}\n'
    )
    file_node = json.dumps(
        {
            "driver": "file",
            "node-name": "file0",
            "filename": str(fixture.resolve()),
        }
    )
    qcow2_node = json.dumps(
        {
            "driver": "qcow2",
            "node-name": "fmt0",
            "file": "file0",
        }
    )
    result = run(
        [
            str(binary),
            "-machine",
            "none",
            "-accel",
            "tcg",
            "-nodefaults",
            "-display",
            "none",
            "-serial",
            "none",
            "-S",
            "-netdev",
            "user,id=ci",
            "-blockdev",
            file_node,
            "-blockdev",
            qcow2_node,
            "-qmp",
            "stdio",
        ],
        input_text=qmp_input,
        timeout=20,
    )

    responses = []
    for line in result.stdout.splitlines():
        try:
            responses.append(json.loads(line))
        except json.JSONDecodeError as error:
            raise RuntimeError(
                f"{binary} produced invalid QMP output:\n{result.stdout}"
            ) from error
    errors = [response["error"] for response in responses if "error" in response]
    if errors:
        raise RuntimeError(f"{binary} returned QMP errors: {errors}")
    try:
        nodes = next(
            response["return"]
            for response in responses
            if response.get("id") == "nodes"
        )
    except StopIteration as error:
        raise RuntimeError(
            f"{binary} did not return its named block nodes:\n"
            f"{result.stdout}\n{result.stderr}"
        ) from error
    if not any(
        node.get("node-name") == "fmt0" and node.get("drv") == "qcow2"
        for node in nodes
    ):
        raise RuntimeError(
            f"{binary} did not open the Zstd QCOW2 node: {nodes}"
        )


def verify_package(package_dir: Path) -> None:
    qemu_img = package_dir / "qemu-img"
    qemu_io = package_dir / "qemu-io"
    system_binaries = sorted(package_dir.glob("qemu-system-*"))
    license_file = (
        package_dir
        / "share"
        / "licenses"
        / "qemu-deps"
        / "zstd"
        / "LICENSE"
    )

    require_file(qemu_img)
    require_file(qemu_io)
    require_file(license_file)
    if not system_binaries:
        raise RuntimeError(f"no qemu-system-* binaries found in {package_dir}")

    binaries = [qemu_img, qemu_io, *system_binaries]
    for binary in binaries:
        require_file(binary)
        run([str(binary), "--version"])
        verify_linkage(binary)

    with tempfile.TemporaryDirectory(prefix="qemu-zstd-") as temporary:
        fixture = create_zstd_fixture(qemu_img, Path(temporary))
        for binary in system_binaries:
            verify_system_binary(binary, fixture)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Qualify an extracted macOS QEMU release package"
    )
    parser.add_argument("package_dir", type=Path)
    args = parser.parse_args()
    verify_package(args.package_dir.resolve())


if __name__ == "__main__":
    main()
