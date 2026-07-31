#!/usr/bin/env bash

set -Eeuo pipefail

SUITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK_FILE="$SUITE_DIR/guest/inputs.lock.json"
OUT_DIR="$SUITE_DIR/out"
GUEST_DIR="$OUT_DIR/guest"
WORK_DIR="$OUT_DIR/work"
CACHE_DIR="$OUT_DIR/cache"
SOURCE_DATE_EPOCH=1784606400
VERIFY=0
CLEAN=0

usage()
{
    cat <<EOF
Usage: $0 [--clean] [--verify] [--refresh-lock]

  --clean         Remove existing generated artifacts after safe mount/NBD checks.
  --verify        Boot both guests under QEMU TCG after building.
  --refresh-lock  Refresh repository, package, and file hashes in inputs.lock.json.
EOF
}

while (($#)); do
    case "$1" in
        --clean) CLEAN=1 ;;
        --verify) VERIFY=1 ;;
        --refresh-lock)
            exec python3 "$SUITE_DIR/guest/refresh-inputs.py" "$LOCK_FILE"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if [[ "$(id -u)" -ne 0 ]]; then
    echo "build-guests.sh must run as root inside WSL (for NBD and image mounts)" >&2
    exit 1
fi

for command_name in python3 curl sha256sum tar cpio gzip xorriso qemu-img qemu-io qemu-nbd \
    sfdisk mkfs.ext4 mkfs.vfat mount umount findmnt modprobe timeout qemu-system-x86_64 \
    wget blockdev blkid udevadm getopt realpath install; do
    command -v "$command_name" >/dev/null || {
        echo "missing required command: $command_name" >&2
        exit 1
    }
done

if command -v zig >/dev/null 2>&1; then
    ZIG="${ZIG:-zig}"
elif command -v zig.exe >/dev/null 2>&1; then
    ZIG="${ZIG:-zig.exe}"
else
    echo "Zig 0.16.0 was not found (set ZIG or expose zig/zig.exe in PATH)" >&2
    exit 1
fi
if [[ "$("$ZIG" version)" != 0.16.0 ]]; then
    echo "Zig 0.16.0 is required" >&2
    exit 1
fi

cleanup_suite_resources()
{
    local failed=0
    local target
    local pid_file
    local pid
    local command_line
    local device

    set +e
    if [[ -d "$WORK_DIR" ]]; then
        while IFS= read -r target; do
            [[ -n "$target" ]] || continue
            umount "$target" || failed=1
        done < <(findmnt -Rrn -o TARGET "$WORK_DIR" 2>/dev/null | sort -r)
    fi

    for pid_file in /sys/block/nbd*/pid; do
        [[ -r "$pid_file" ]] || continue
        pid="$(cat "$pid_file" 2>/dev/null || true)"
        [[ -n "$pid" && -r "/proc/$pid/cmdline" ]] || continue
        command_line="$(tr '\0' ' ' < "/proc/$pid/cmdline")"
        if [[ "$command_line" == *"$SUITE_DIR"* ]]; then
            device="/dev/$(basename "$(dirname "$pid_file")")"
            qemu-nbd --disconnect "$device" || failed=1
        fi
    done

    if [[ -d "$WORK_DIR" ]] && findmnt -Rrn "$WORK_DIR" >/dev/null 2>&1; then
        echo "mounted paths remain under $WORK_DIR" >&2
        findmnt -R "$WORK_DIR" >&2 || true
        failed=1
    fi
    for pid_file in /sys/block/nbd*/pid; do
        [[ -r "$pid_file" ]] || continue
        pid="$(cat "$pid_file" 2>/dev/null || true)"
        [[ -n "$pid" && -r "/proc/$pid/cmdline" ]] || continue
        command_line="$(tr '\0' ' ' < "/proc/$pid/cmdline")"
        if [[ "$command_line" == *"$SUITE_DIR"* ]]; then
            echo "suite-owned NBD process remains: $command_line" >&2
            failed=1
        fi
    done
    set -e
    return "$failed"
}

on_exit()
{
    local status=$?

    trap - EXIT
    if ! cleanup_suite_resources; then
        status=1
    fi
    exit "$status"
}
trap on_exit EXIT
trap 'exit 130' HUP INT TERM

cleanup_suite_resources
if ((CLEAN)); then
    rm -rf "$OUT_DIR"
fi
mkdir -p "$GUEST_DIR" "$WORK_DIR" "$CACHE_DIR" "$WORK_DIR/tmp"

locked_rows()
{
    python3 - "$LOCK_FILE" "$1" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as input_file:
    lock = json.load(input_file)
for entry in lock[sys.argv[2]]:
    print("\t".join([
        entry["id"],
        entry["url"],
        entry["sha256"],
        str(entry.get("size_bytes", "")),
    ]))
PY
}

download_locked()
{
    local id="$1"
    local url="$2"
    local expected_hash="$3"
    local expected_size="$4"
    local filename="${url##*/}"
    local destination="$CACHE_DIR/$id-$filename"
    local temporary="$destination.tmp"
    local actual_hash
    local actual_size

    if [[ -f "$destination" ]]; then
        actual_hash="$(sha256sum "$destination" | cut -d ' ' -f 1)"
        if [[ "$actual_hash" == "$expected_hash" ]]; then
            printf '%s\n' "$destination"
            return
        fi
        rm -f "$destination"
    fi

    curl --fail --location --retry 3 --silent --show-error --output "$temporary" "$url"
    actual_hash="$(sha256sum "$temporary" | cut -d ' ' -f 1)"
    [[ "$actual_hash" == "$expected_hash" ]] || {
        rm -f "$temporary"
        echo "$id SHA-256 mismatch: got $actual_hash, expected $expected_hash" >&2
        exit 1
    }
    if [[ -n "$expected_size" ]]; then
        actual_size="$(stat -c %s "$temporary")"
        [[ "$actual_size" == "$expected_size" ]] || {
            rm -f "$temporary"
            echo "$id size mismatch: got $actual_size, expected $expected_size" >&2
            exit 1
        }
    fi
    mv "$temporary" "$destination"
    printf '%s\n' "$destination"
}

while IFS=$'\t' read -r id url expected_hash expected_size; do
    download_locked "$id" "$url" "$expected_hash" "$expected_size" >/dev/null
done < <(locked_rows repositories)
while IFS=$'\t' read -r id url expected_hash expected_size; do
    download_locked "$id" "$url" "$expected_hash" "$expected_size" >/dev/null
done < <(locked_rows sources)

input_path()
{
    local id="$1"
    local matches=("$CACHE_DIR/$id-"*)

    [[ -f "${matches[0]}" ]] || {
        echo "locked input '$id' was not downloaded" >&2
        exit 1
    }
    printf '%s\n' "${matches[0]}"
}

LINUX_APK="$(input_path linux-virt)"
BUSYBOX_APK="$(input_path busybox-static)"
SYSLINUX_APK="$(input_path syslinux)"
IMAGE_BUILDER_SOURCE="$(input_path alpine-make-vm-image)"
APK_STATIC_SOURCE="$(input_path apk-tools-static)"

MICRO_WORK="$WORK_DIR/micro"
MICRO_ROOT="$MICRO_WORK/root"
ISO_ROOT="$MICRO_WORK/iso"
rm -rf "$MICRO_WORK"
mkdir -p "$MICRO_ROOT/bin" "$MICRO_ROOT/proc" "$MICRO_ROOT/sys" "$MICRO_ROOT/dev" \
    "$MICRO_ROOT/tmp" "$ISO_ROOT/boot" "$ISO_ROOT/isolinux"

tar -xzf "$LINUX_APK" -C "$MICRO_WORK" boot/vmlinuz-virt 2>/dev/null
tar -xzf "$BUSYBOX_APK" -C "$MICRO_WORK" bin/busybox.static 2>/dev/null
tar -xzf "$SYSLINUX_APK" -C "$MICRO_WORK" \
    usr/share/syslinux/isolinux.bin usr/share/syslinux/ldlinux.c32 2>/dev/null

cd "$SUITE_DIR"
"$ZIG" cc -target x86_64-linux-musl -O3 -static -pthread \
    guest/microbench.c -o out/work/micro/root/bin/microbench

cp "$MICRO_WORK/bin/busybox.static" "$MICRO_ROOT/bin/busybox"
cp "$SUITE_DIR/guest/micro-init" "$MICRO_ROOT/init"
chmod 0755 "$MICRO_ROOT/init" "$MICRO_ROOT/bin/busybox" "$MICRO_ROOT/bin/microbench"

BENCH_RUN_ID=build-known-answer "$MICRO_ROOT/bin/microbench" prime-v1 |
    tee "$MICRO_WORK/known-answer.log"
grep -q '"prime_count":216816' "$MICRO_WORK/known-answer.log"

(
    cd "$MICRO_ROOT"
    find . -print0 |
        sort -z |
        cpio --null --create --format=newc --owner=0:0 --reproducible 2>/dev/null |
        gzip -9n > "$MICRO_WORK/initramfs.cpio.gz"
)

cp "$MICRO_WORK/boot/vmlinuz-virt" "$ISO_ROOT/boot/vmlinuz-virt"
cp "$MICRO_WORK/initramfs.cpio.gz" "$ISO_ROOT/boot/initramfs.cpio.gz"
cp "$MICRO_WORK/usr/share/syslinux/isolinux.bin" "$ISO_ROOT/isolinux/isolinux.bin"
cp "$MICRO_WORK/usr/share/syslinux/ldlinux.c32" "$ISO_ROOT/isolinux/ldlinux.c32"
cat > "$ISO_ROOT/isolinux/isolinux.cfg" <<'EOF'
SERIAL 0 38400
CONSOLE 0
PROMPT 0
TIMEOUT 1
DEFAULT benchmark

LABEL benchmark
    KERNEL /boot/vmlinuz-virt
    APPEND initrd=/boot/initramfs.cpio.gz console=ttyS0,38400n8 loglevel=4 bench.run_id=phase2-smoke bench.workloads=prime-v1
EOF
find "$MICRO_WORK" -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +
xorriso -as mkisofs -quiet \
    -V QEMU_BENCH_MICRO \
    --modification-date=2026072100000000 \
    --set_all_file_dates 2026072100000000 \
    -o "$GUEST_DIR/microbench.iso" \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    "$ISO_ROOT"

TOOLS_DIR="$WORK_DIR/tools"
mkdir -p "$TOOLS_DIR"
IMAGE_BUILDER="$TOOLS_DIR/alpine-make-vm-image"
cp "$IMAGE_BUILDER_SOURCE" "$IMAGE_BUILDER"
python3 - "$IMAGE_BUILDER" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
old_trap = "trap 'cleanup; exit 0' EXIT"
new_trap = "trap 'rc=$?; cleanup; exit $rc' EXIT"
old_tmp = "mktemp -d /tmp/$PROGNAME.XXXXXX"
new_tmp = 'mktemp -d "${TMPDIR:-/tmp}/$PROGNAME.XXXXXX"'
old_kernel = '\t_apk add --root . linux-$KERNEL_FLAVOR\nelse'
new_kernel = '\t_apk add --root . "$KERNEL_APK"\nelse'
if text.count(old_trap) != 1 or text.count(old_tmp) != 2 or text.count(old_kernel) != 1:
    raise SystemExit("unexpected alpine-make-vm-image source; safety patch did not apply")
text = text.replace(old_trap, new_trap).replace(old_tmp, new_tmp).replace(old_kernel, new_kernel)
path.write_text(text)
PY
chmod 0755 "$IMAGE_BUILDER"

REPOSITORIES_FILE="$WORK_DIR/repositories"
python3 - "$LOCK_FILE" > "$REPOSITORIES_FILE" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as input_file:
    lock = json.load(input_file)
alpine = lock["alpine"]
for repository in lock["repositories"]:
    print(f"{alpine['mirror']}/{alpine['branch']}/{repository['repository']}")
PY

GUEST_PACKAGES="$(
    python3 - "$LOCK_FILE" "$CACHE_DIR" <<'PY'
import json
import pathlib
import sys

with open(sys.argv[1], encoding="utf-8") as input_file:
    lock = json.load(input_file)
cache_dir = pathlib.Path(sys.argv[2])
print(" ".join(
    str(cache_dir / f"{source['id']}-{source['url'].rsplit('/', 1)[-1]}")
    for source in lock["sources"]
    if source.get("install_in_guest") and source["id"] != "linux-virt"
))
PY
)"

APK_TOOLS_URI="$(
    python3 - "$LOCK_FILE" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as input_file:
    lock = json.load(input_file)
print(next(item["url"] for item in lock["sources"] if item["id"] == "apk-tools-static"))
PY
)"
APK_TOOLS_SHA256="$(sha256sum "$APK_STATIC_SOURCE" | cut -d ' ' -f 1)"

SYSTEM_IMAGE="$GUEST_DIR/alpine-bench.vhdx"
rm -f "$SYSTEM_IMAGE"
TMPDIR="$WORK_DIR/tmp" \
APK_TOOLS_URI="$APK_TOOLS_URI" \
APK_TOOLS_SHA256="$APK_TOOLS_SHA256" \
KERNEL_APK="$LINUX_APK" \
"$IMAGE_BUILDER" \
    --arch x86_64 \
    --boot-mode UEFI \
    --branch 3.24 \
    --image-format vhdx \
    --image-size 8G \
    --initfs-features "scsi virtio network cdrom" \
    --kernel-flavor virt \
    --packages "$GUEST_PACKAGES" \
    --repositories-file "$REPOSITORIES_FILE" \
    --serial-console \
    "$SYSTEM_IMAGE" \
    "$SUITE_DIR/guest/configure-alpine.sh"

cleanup_suite_resources

DATA_IMAGE="$GUEST_DIR/fio-data.vhdx"
rm -f "$DATA_IMAGE"
qemu-img create -f vhdx -o subformat=fixed "$DATA_IMAGE" 16G >/dev/null
for ((offset_gib = 0; offset_gib < 16; offset_gib++)); do
    qemu-io -f vhdx -c "write -P 0x5a ${offset_gib}G 1G" "$DATA_IMAGE" >/dev/null
done
qemu-img info --output=json "$SYSTEM_IMAGE" > "$WORK_DIR/alpine-bench.info.json"
qemu-img info --output=json "$DATA_IMAGE" > "$WORK_DIR/fio-data.info.json"

verify_guests()
{
    local micro_log="$WORK_DIR/micro-smoke.log"
    local system_log="$WORK_DIR/system-smoke.log"
    local config_root="$WORK_DIR/config-iso"
    local config_iso="$WORK_DIR/smoke-config.iso"
    local smoke_image="$WORK_DIR/alpine-bench-smoke.vhdx"
    local ovmf_code="${QEMU_EFI:-}"
    local ovmf_vars="${QEMU_EFI_VARS:-}"
    local smoke_vars="$WORK_DIR/OVMF_VARS.fd"

    timeout 180s qemu-system-x86_64 \
        -accel tcg \
        -machine q35 \
        -m 512 \
        -smp 1 \
        -display none \
        -monitor none \
        -serial stdio \
        -no-reboot \
        -nic none \
        -cdrom "$GUEST_DIR/microbench.iso" > "$micro_log" 2>&1
    grep -q 'BENCH_READY run_id=phase2-smoke' "$micro_log"
    grep -q '"workload":"prime-v1".*"prime_count":216816.*"status":"success"' "$micro_log"

    if [[ -z "$ovmf_code" ]]; then
        for candidate in \
            /usr/share/OVMF/OVMF_CODE_4M.fd \
            /usr/share/OVMF/OVMF_CODE.fd; do
            if [[ -f "$candidate" ]]; then
                ovmf_code="$candidate"
                break
            fi
        done
    fi
    if [[ -z "$ovmf_vars" ]]; then
        for candidate in \
            /usr/share/OVMF/OVMF_VARS_4M.fd \
            /usr/share/OVMF/OVMF_VARS.fd; do
            if [[ -f "$candidate" ]]; then
                ovmf_vars="$candidate"
                break
            fi
        done
    fi
    [[ -f "$ovmf_code" && -f "$ovmf_vars" ]] || {
        echo "OVMF code/variables were not found; install ovmf or set QEMU_EFI and QEMU_EFI_VARS" >&2
        exit 1
    }

    rm -rf "$config_root"
    mkdir -p "$config_root"
    cat > "$config_root/job.conf" <<'EOF'
schema=1
run_id=phase2-system-smoke
workload=smoke
vcpus=2
EOF
    xorriso -as mkisofs -quiet -V BENCHCFG -o "$config_iso" "$config_root"
    cp --reflink=auto "$SYSTEM_IMAGE" "$smoke_image"
    cp "$ovmf_vars" "$smoke_vars"

    timeout 300s qemu-system-x86_64 \
        -accel tcg \
        -machine q35 \
        -m 2048 \
        -smp 2 \
        -display none \
        -monitor none \
        -serial stdio \
        -no-reboot \
        -drive "if=pflash,unit=0,format=raw,readonly=on,file=$ovmf_code" \
        -drive "if=pflash,unit=1,format=raw,file=$smoke_vars" \
        -drive "file=$smoke_image,format=vhdx,if=none,id=os" \
        -device virtio-blk-pci,drive=os,bootindex=1 \
        -drive "file=$config_iso,format=raw,media=cdrom,readonly=on" \
        -netdev user,id=net0 \
        -device virtio-net-pci,netdev=net0 > "$system_log" 2>&1
    grep -q 'BENCH_READY run_id=phase2-system-smoke workload=smoke' "$system_log"
    grep -q '"workload":"smoke".*"status":"success"' "$system_log"
}

if ((VERIFY)); then
    verify_guests
fi

python3 - "$LOCK_FILE" "$GUEST_DIR" "$SOURCE_DATE_EPOCH" <<'PY'
import datetime
import hashlib
import json
import os
import sys

lock_file, guest_dir, source_date_epoch = sys.argv[1:]

def digest(path):
    hasher = hashlib.sha256()
    with open(path, "rb") as input_file:
        for chunk in iter(lambda: input_file.read(1024 * 1024), b""):
            hasher.update(chunk)
    return hasher.hexdigest()

with open(lock_file, encoding="utf-8") as input_file:
    lock = json.load(input_file)

artifacts = []
for artifact_id, filename, image_format in [
    ("microbench-iso", "microbench.iso", "iso"),
    ("alpine-system-vhdx", "alpine-bench.vhdx", "vhdx"),
    ("fio-data-vhdx", "fio-data.vhdx", "vhdx"),
]:
    path = os.path.join(guest_dir, filename)
    artifacts.append({
        "id": artifact_id,
        "path": filename,
        "format": image_format,
        "sha256": digest(path),
        "size_bytes": os.path.getsize(path),
    })

manifest = {
    "schema": 1,
    "created_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "source_date_epoch": int(source_date_epoch),
    "inputs_lock_sha256": digest(lock_file),
    "alpine": lock["alpine"],
    "packages": {
        item["package"]: item["version"]
        for item in lock["sources"]
        if item.get("kind") == "package"
    },
    "fio_data_precondition": {
        "pattern": "0x5a",
        "bytes": 16 * 1024 * 1024 * 1024,
    },
    "artifacts": artifacts,
}
temporary = os.path.join(guest_dir, "manifest.json.tmp")
with open(temporary, "w", encoding="utf-8", newline="\n") as output:
    json.dump(manifest, output, indent=2)
    output.write("\n")
os.replace(temporary, os.path.join(guest_dir, "manifest.json"))
PY

echo "Built guest artifacts:"
python3 - "$GUEST_DIR/manifest.json" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as input_file:
    manifest = json.load(input_file)
for artifact in manifest["artifacts"]:
    print(f"  {artifact['path']}: {artifact['sha256']} ({artifact['size_bytes']} bytes)")
PY
