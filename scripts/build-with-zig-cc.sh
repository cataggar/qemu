#!/usr/bin/env bash
#
# Build QEMU using `zig cc` (Zig's bundled clang) as the C/C++ compiler.
#
# This was validated with Zig 0.16.0 (clang 21) on Azure Linux 3.0 (aarch64).
# It documents the workarounds needed because `zig cc` differs from a plain
# gcc/clang in a few ways that QEMU's build system does not expect:
#
#   1. `-Werror` + clang surfaces warnings gcc does not (e.g.
#      -Wunused-but-set-variable). We build with --disable-werror.
#
#   2. `zig cc` defines NDEBUG by default in optimized modes, but QEMU's
#      include/qemu/osdep.h hard-errors with "building with NDEBUG is not
#      supported". We undefine it with -UNDEBUG.
#
#   3. QEMU ships its own newer kernel uapi copies under linux-headers/ and
#      adds them with `-isystem`. `zig cc` orders user `-isystem` paths AFTER
#      /usr/include, and it de-duplicates a path given as both `-I` and
#      `-isystem` down to the lower-priority `-isystem` slot. The net effect is
#      the host's older /usr/include/linux/{iommufd,kvm}.h shadow QEMU's copies,
#      causing errors like "incomplete type struct iommu_hw_info_arm_smmuv3" and
#      "undeclared identifier KVM_ARM_DEV_EL1_VTIMER".
#
#      Workaround: make a REAL copy of linux-headers at a distinct path (so it
#      is not de-duplicated against the -isystem entry) and add it with `-I`
#      (which zig cc *does* rank above /usr/include). We also add the arch
#      `asm` -> `asm-<arch>` symlink QEMU normally creates in its build dir.
#
#   4. Zig's linker rejects `--dynamic-list`, which QEMU uses to export plugin
#      symbols. We build with --disable-plugins.
#
# Usage:  scripts/build-with-zig-cc.sh [build-dir]
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${1:-$SRC_DIR/build-zig}"

# Pick the QEMU asm-<arch> dir matching the host architecture.
case "$(uname -m)" in
    aarch64|arm64) ASM_ARCH=asm-arm64 ;;
    x86_64|amd64)  ASM_ARCH=asm-x86 ;;
    riscv64)       ASM_ARCH=asm-riscv ;;
    s390x)         ASM_ARCH=asm-s390 ;;
    ppc64*|powerpc*) ASM_ARCH=asm-powerpc ;;
    loongarch64)   ASM_ARCH=asm-loongarch ;;
    mips*)         ASM_ARCH=asm-mips ;;
    *) echo "unsupported host arch $(uname -m)" >&2; exit 1 ;;
esac

mkdir -p "$BUILD_DIR"

# (3) Real copy of linux-headers at a distinct path, plus the asm symlink.
HDR_COPY="$BUILD_DIR/zig-linux-headers-copy"
rm -rf "$HDR_COPY"
cp -r "$SRC_DIR/linux-headers" "$HDR_COPY"
ln -sfn "$ASM_ARCH" "$HDR_COPY/asm"

EXTRA_FLAGS="-UNDEBUG -I$HDR_COPY"   # (2) + (3)

cd "$BUILD_DIR"
"$SRC_DIR/configure" \
    --cc="zig cc" \
    --cxx="zig c++" \
    --disable-werror \
    --disable-plugins \
    --extra-cflags="$EXTRA_FLAGS" \
    --extra-cxxflags="$EXTRA_FLAGS" \
    "${@:2}"

ninja

echo
echo "Built with zig cc:"
./qemu-system-"$(uname -m 2>/dev/null | sed 's/arm64/aarch64/')" --version 2>/dev/null | head -1 || true
