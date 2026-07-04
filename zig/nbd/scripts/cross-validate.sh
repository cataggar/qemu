#!/usr/bin/env bash
#
# Cross-validate the native Zig NBD implementation against real qemu-nbd /
# qemu-img / qemu-io binaries, in both directions:
#
#   1. Client validation: starts `qemu-nbd -f raw` (Unix domain socket) over
#      a randomly-populated raw disk image, then
#        - compares `nbd read` output byte-for-byte (via cmp) against the
#          raw file directly, for both a full-disk read and a
#          partial/offset read;
#        - performs an `nbd write` followed by an `nbd flush`, and verifies
#          the write landed both when read back over NBD and in the
#          backing raw file directly (qemu-nbd's `-t`/writethrough option
#          is used so writes are synchronous);
#        - checks `nbd info` reports the expected export size.
#
#   2. Server validation: starts `nbd serve` (this repo's minimal reference
#      server) over a second raw disk image, then
#        - checks `qemu-img info nbd+unix://...` reports the expected size;
#        - compares `qemu-img convert -O raw` output byte-for-byte against
#          the raw file directly;
#        - performs a `qemu-io write` followed by a `qemu-io read -P` (which
#          itself verifies the pattern it just wrote) against the server.
#
# Usage: cross-validate.sh <qemu-build-dir> <nbd-cli>
#   <qemu-build-dir>  directory containing the qemu-nbd, qemu-img, and
#                      qemu-io binaries (e.g. build-zig, built via
#                      scripts/build-with-zig-cc.sh)
#   <nbd-cli>          path to the zig/nbd CLI binary (zig-out/bin/nbd)
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <qemu-build-dir> <nbd-cli>" >&2
    exit 2
fi

QEMU_NBD="$(cd "$1" && pwd)/qemu-nbd"
QEMU_IMG="$(cd "$1" && pwd)/qemu-img"
QEMU_IO="$(cd "$1" && pwd)/qemu-io"
NBD="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"

for bin in "$QEMU_NBD" "$QEMU_IMG" "$QEMU_IO" "$NBD"; do
    if [[ ! -x "$bin" ]]; then
        echo "error: not an executable: $bin" >&2
        exit 2
    fi
done

WORK="$(mktemp -d)"
NBD_PID=""
SERVE_PID=""
cleanup() {
    for pid in "$NBD_PID" "$SERVE_PID"; do
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            wait "$pid" 2>/dev/null || true
        fi
    done
    rm -rf "$WORK"
}
trap cleanup EXIT
cd "$WORK"

fail=0
DISK_SIZE=$((8 * 1024 * 1024))
SOCK="$WORK/nbd.sock"
EXPORT=test

# wait_for_socket <path>
wait_for_socket() {
    for _ in $(seq 1 50); do
        [[ -S "$1" ]] && return 0
        sleep 0.1
    done
    return 1
}

echo "###### Part 1: client validation (Zig client <-> real qemu-nbd) ######"

dd if=/dev/urandom of=disk.raw bs=1M count=8 status=none

"$QEMU_NBD" -f raw --export-name="$EXPORT" -k "$SOCK" -t -x "$EXPORT" disk.raw &
NBD_PID=$!

if ! wait_for_socket "$SOCK"; then
    echo "error: qemu-nbd never created $SOCK" >&2
    exit 1
fi

TARGET="unix:$SOCK"

echo "== info =="
if "$NBD" info "$TARGET" "$EXPORT" | grep -q "export size:        $DISK_SIZE bytes"; then
    echo "PASS: info (export size matches)"
else
    echo "FAIL: info -- unexpected export size" >&2
    fail=1
fi

echo "== full read =="
"$NBD" read "$TARGET" "$EXPORT" 0 "$DISK_SIZE" > full.got.raw
if cmp -s disk.raw full.got.raw; then
    echo "PASS: full read"
else
    echo "FAIL: full read differs from the raw file" >&2
    fail=1
fi

echo "== partial/offset read =="
"$NBD" read "$TARGET" "$EXPORT" 4096 1024 > partial.got.raw
dd if=disk.raw of=partial.expected.raw bs=1 skip=4096 count=1024 status=none
if cmp -s partial.expected.raw partial.got.raw; then
    echo "PASS: partial read"
else
    echo "FAIL: partial read differs from the raw file" >&2
    fail=1
fi

echo "== write + flush =="
head -c 512 /dev/urandom > patch.bin
"$NBD" write "$TARGET" "$EXPORT" 12345 < patch.bin
"$NBD" flush "$TARGET" "$EXPORT"
"$NBD" read "$TARGET" "$EXPORT" 12345 512 > readback.bin
dd if=disk.raw of=backing.got.bin bs=1 skip=12345 count=512 status=none
if cmp -s patch.bin readback.bin && cmp -s patch.bin backing.got.bin; then
    echo "PASS: write + flush (visible over NBD and in the backing file)"
else
    echo "FAIL: write + flush -- data mismatch" >&2
    fail=1
fi

kill "$NBD_PID" 2>/dev/null || true
wait "$NBD_PID" 2>/dev/null || true
NBD_PID=""

echo "###### Part 2: server validation (real qemu-img/qemu-io <-> Zig server) ######"

dd if=/dev/urandom of=srv-disk.raw bs=1M count=4 status=none
SRV_SOCK="$WORK/srv.sock"
SRV_URL="nbd+unix:///$EXPORT?socket=$SRV_SOCK"

"$NBD" serve "unix:$SRV_SOCK" "$EXPORT" srv-disk.raw &
SERVE_PID=$!

if ! wait_for_socket "$SRV_SOCK"; then
    echo "error: nbd serve never created $SRV_SOCK" >&2
    exit 1
fi

echo "== qemu-img info =="
if "$QEMU_IMG" info "$SRV_URL" | grep -q "virtual size: 4 MiB (4194304 bytes)"; then
    echo "PASS: qemu-img info (export size matches)"
else
    echo "FAIL: qemu-img info -- unexpected export size" >&2
    fail=1
fi

echo "== qemu-img convert (full read) =="
"$QEMU_IMG" convert -f raw -O raw "$SRV_URL" srv-full.got.raw
if cmp -s srv-disk.raw srv-full.got.raw; then
    echo "PASS: qemu-img convert read"
else
    echo "FAIL: qemu-img convert read differs from the raw file" >&2
    fail=1
fi

echo "== qemu-io write + read -P (self-verifying) =="
if "$QEMU_IO" -f raw -c "write -P 0x42 1000 2048" "$SRV_URL" >/dev/null &&
    "$QEMU_IO" -f raw -c "read -P 0x42 1000 2048" "$SRV_URL" >/dev/null; then
    echo "PASS: qemu-io write + read -P"
else
    echo "FAIL: qemu-io write/read -P against the Zig server" >&2
    fail=1
fi

if [[ "$fail" -ne 0 ]]; then
    echo "cross-validation FAILED" >&2
    exit 1
fi
echo "cross-validation OK"

