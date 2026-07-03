#!/usr/bin/env bash
#
# Cross-validate the native Zig QMP client against a real qemu-system-x86_64
# build. Launches a tiny (kernel-less) guest with a QMP control socket using
# the real binary, then:
#   - connects with the Zig client and checks the server greeting parses,
#   - runs `query-status` and asserts the guest is reported as running,
#   - runs `quit` and asserts the QEMU process actually exits,
#   - exercises `spawnAndConnect()` and the QAPI-generated typed bindings
#     (`qapi.queryStatus` / `qapi.quit`) via the `spawn-status` CLI command.
#
# Usage: cross-validate.sh <qemu-build-dir> <qmp-cli>
#   <qemu-build-dir>  directory containing the qemu-system-x86_64 binary
#                      (e.g. build-zig, built via scripts/build-with-zig-cc.sh)
#   <qmp-cli>          path to the zig/qmp CLI binary (zig-out/bin/qmp)
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <qemu-build-dir> <qmp-cli>" >&2
    exit 2
fi

QEMU_SYSTEM="$(cd "$1" && pwd)/qemu-system-x86_64"
QMP="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"

for bin in "$QEMU_SYSTEM" "$QMP"; do
    if [[ ! -x "$bin" ]]; then
        echo "error: not an executable: $bin" >&2
        exit 2
    fi
done

WORK="$(mktemp -d)"
SOCK="$WORK/qmp.sock"
QEMU_PID=""

cleanup() {
    if [[ -n "$QEMU_PID" ]] && kill -0 "$QEMU_PID" 2>/dev/null; then
        kill "$QEMU_PID" 2>/dev/null || true
        wait "$QEMU_PID" 2>/dev/null || true
    fi
    rm -rf "$WORK"
}
trap cleanup EXIT

fail=0

echo "== launching qemu-system-x86_64 with a QMP control socket =="
"$QEMU_SYSTEM" -M isapc -display none \
    -qmp "unix:$SOCK,server=on,wait=off" &
QEMU_PID=$!

for _ in $(seq 1 50); do
    [[ -S "$SOCK" ]] && break
    sleep 0.1
done
if [[ ! -S "$SOCK" ]]; then
    echo "FAIL: QMP socket never appeared at $SOCK" >&2
    exit 1
fi

echo "== greeting =="
if ! "$QMP" greeting "$SOCK" > "$WORK/greeting.json"; then
    echo "FAIL: qmp greeting" >&2
    cat "$WORK/greeting.json" >&2
    fail=1
else
    echo "PASS: greeting"
fi

echo "== query-status reports running =="
if "$QMP" exec "$SOCK" query-status > "$WORK/status.json"; then
    if grep -q '"running": true' "$WORK/status.json"; then
        echo "PASS: query-status"
    else
        echo "FAIL: query-status did not report running=true" >&2
        cat "$WORK/status.json" >&2
        fail=1
    fi
else
    echo "FAIL: qmp exec query-status" >&2
    cat "$WORK/status.json" >&2
    fail=1
fi

echo "== quit terminates the process =="
if "$QMP" exec "$SOCK" quit > "$WORK/quit.json"; then
    echo "PASS: quit command accepted"
else
    echo "FAIL: qmp exec quit" >&2
    cat "$WORK/quit.json" >&2
    fail=1
fi

for _ in $(seq 1 50); do
    kill -0 "$QEMU_PID" 2>/dev/null || break
    sleep 0.1
done
if kill -0 "$QEMU_PID" 2>/dev/null; then
    echo "FAIL: qemu-system-x86_64 did not exit after quit" >&2
    fail=1
else
    echo "PASS: process exited after quit"
    QEMU_PID=""
fi

echo "== spawn-status: spawnAndConnect() + typed QAPI bindings =="
if "$QMP" spawn-status "$QEMU_SYSTEM" -M isapc -display none > "$WORK/spawn-status.log" 2>&1; then
    if grep -q 'running=true status=running' "$WORK/spawn-status.log" && grep -q 'term=.*exited = 0' "$WORK/spawn-status.log"; then
        echo "PASS: spawn-status"
    else
        echo "FAIL: spawn-status output unexpected" >&2
        cat "$WORK/spawn-status.log" >&2
        fail=1
    fi
else
    echo "FAIL: qmp spawn-status" >&2
    cat "$WORK/spawn-status.log" >&2
    fail=1
fi

if [[ "$fail" -ne 0 ]]; then
    echo "cross-validation FAILED" >&2
    exit 1
fi
echo "cross-validation OK"
