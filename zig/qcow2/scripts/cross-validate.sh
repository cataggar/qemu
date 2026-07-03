#!/usr/bin/env bash
#
# Cross-validate the native Zig qcow2 reader against a real qemu-img/qemu-io
# build. Creates a handful of qcow2 images (including Extended L2 images with
# mixed allocated/zero/unallocated subclusters, an Extended L2 image with a
# backing-file chain, and an image with an internal snapshot) using the real
# tools, then:
#   - compares `qcow2 read` output byte-for-byte (via cmp) against
#     `qemu-img convert -O raw` output (and, for the snapshot case, `qcow2
#     read --snapshot=<id>` against `qemu-img convert -l <id> -O raw`), and
#   - compares `qcow2 check`'s clean/dirty verdict against real
#     `qemu-img check` on the same images.
#
# Usage: cross-validate.sh <qemu-build-dir> <qcow2-cli>
#   <qemu-build-dir>  directory containing the qemu-img and qemu-io binaries
#                      (e.g. build-zig, built via scripts/build-with-zig-cc.sh)
#   <qcow2-cli>        path to the zig/qcow2 CLI binary (zig-out/bin/qcow2)
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <qemu-build-dir> <qcow2-cli>" >&2
    exit 2
fi

QEMU_IMG="$(cd "$1" && pwd)/qemu-img"
QEMU_IO="$(cd "$1" && pwd)/qemu-io"
QCOW2="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"

for bin in "$QEMU_IMG" "$QEMU_IO" "$QCOW2"; do
    if [[ ! -x "$bin" ]]; then
        echo "error: not an executable: $bin" >&2
        exit 2
    fi
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

fail=0

# check() <name> <qcow2-image> <size>
# Reads `<size>` bytes from `<qcow2-image>` with both the real qemu-img
# (convert -O raw) and our CLI, then compares the two outputs byte-for-byte.
check() {
    local name="$1" img="$2" size="$3"
    "$QEMU_IMG" convert -O raw "$img" "$name.expected.raw"
    "$QCOW2" read "$img" 0 "$size" > "$name.got.raw"
    if cmp -s "$name.expected.raw" "$name.got.raw"; then
        echo "PASS: $name"
    else
        echo "FAIL: $name (qcow2 read output differs from qemu-img convert -O raw)" >&2
        fail=1
    fi
}

# check_consistency() <name> <qcow2-image>
# Runs both `qemu-img check` and `qcow2 check` on `<qcow2-image>` and
# requires them to agree that the image is clean (exit 0 / "no errors").
check_consistency() {
    local name="$1" img="$2"
    local qemu_ok=1 qcow2_ok=1
    "$QEMU_IMG" check "$img" >"$name.qemu-img-check.log" 2>&1 || qemu_ok=0
    "$QCOW2" check "$img" >"$name.qcow2-check.log" 2>&1 || qcow2_ok=0
    if [[ "$qemu_ok" -eq 1 && "$qcow2_ok" -eq 1 ]]; then
        echo "PASS: $name (check)"
    else
        echo "FAIL: $name (check) -- qemu-img check ok=$qemu_ok, qcow2 check ok=$qcow2_ok" >&2
        cat "$name.qemu-img-check.log" "$name.qcow2-check.log" >&2
        fail=1
    fi
}

echo "== plain v3 image =="
"$QEMU_IMG" create -f qcow2 plain.qcow2 2M >/dev/null
"$QEMU_IO" -c "write -P 0x42 0 1048576" plain.qcow2 >/dev/null
check plain plain.qcow2 2097152
check_consistency plain plain.qcow2

echo "== Extended L2: mixed allocated / zero / unallocated subclusters =="
"$QEMU_IMG" create -f qcow2 -o extended_l2=on,cluster_size=64k ext.qcow2 4M >/dev/null
head -c 2048 /dev/urandom > pat0.bin
head -c 2048 /dev/urandom > pat5.bin
"$QEMU_IO" -c "write -s pat0.bin 0 2048" ext.qcow2 >/dev/null      # subcluster 0: allocated
"$QEMU_IO" -c "write -z 4096 2048" ext.qcow2 >/dev/null            # subcluster 2: explicit zero
"$QEMU_IO" -c "write -s pat5.bin 10240 2048" ext.qcow2 >/dev/null  # subcluster 5: allocated
check ext-l2 ext.qcow2 4194304
check_consistency ext-l2 ext.qcow2

echo "== Extended L2 + backing-file chain =="
"$QEMU_IMG" create -f qcow2 backing.qcow2 2M >/dev/null
"$QEMU_IO" -c "write -P 0x5A 0 2097152" backing.qcow2 >/dev/null
"$QEMU_IMG" create -f qcow2 -o extended_l2=on,cluster_size=64k -F qcow2 -b backing.qcow2 overlay.qcow2 >/dev/null
"$QEMU_IO" -c "write -P 0xAA 0 2048" overlay.qcow2 >/dev/null
check ext-l2-backing overlay.qcow2 2097152
check_consistency backing backing.qcow2
check_consistency ext-l2-backing overlay.qcow2

echo "== Snapshots: read the active image and an internal snapshot =="
"$QEMU_IMG" create -f qcow2 snap.qcow2 1M >/dev/null
"$QEMU_IO" -c "write -P 0xAA 0 65536" snap.qcow2 >/dev/null
"$QEMU_IMG" snapshot -c snap1 snap.qcow2 >/dev/null
"$QEMU_IO" -c "write -P 0xBB 0 65536" snap.qcow2 >/dev/null
check snap-active snap.qcow2 1048576
check_consistency snap-active snap.qcow2
"$QEMU_IMG" convert -l snap1 -O raw snap.qcow2 snap1.expected.raw
"$QCOW2" read snap.qcow2 0 1048576 --snapshot=snap1 > snap1.got.raw
if cmp -s snap1.expected.raw snap1.got.raw; then
    echo "PASS: snap1 (snapshot read)"
else
    echo "FAIL: snap1 (snapshot read) -- qcow2 read --snapshot differs from qemu-img convert -l" >&2
    fail=1
fi

if [[ "$fail" -ne 0 ]]; then
    echo "cross-validation FAILED" >&2
    exit 1
fi
echo "cross-validation OK"
