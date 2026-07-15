#!/usr/bin/env bash
#
# Build static QEMU Linux executables with zig cc and the target dependency
# sysroot described by the repository's build.zig.zon. Host tools still come
# from the build machine; target libraries come only from Zig packages.
#
# Usage:
#   scripts/build-static-linux-with-zig.sh BUILD_DIR TARGET_LIST [NINJA_TARGET...]
#
# Optional environment:
#   QEMU_PKG_VERSION       Value for configure's --with-pkgversion.
#   QEMU_ZIG_ACCEL_OPT     Accelerator option such as --enable-kvm.
#   QEMU_ZIG_SYSROOT       Dependency install prefix.
#
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "usage: $0 BUILD_DIR TARGET_LIST [NINJA_TARGET...]" >&2
    exit 2
fi

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$1"
TARGET_LIST="$2"
shift 2

case "$(uname -m)" in
    x86_64|amd64)
        ZIG_TARGET=x86_64-linux-musl
        ASM_ARCH=asm-x86
        ;;
    aarch64|arm64)
        ZIG_TARGET=aarch64-linux-musl
        ASM_ARCH=asm-arm64
        ;;
    *)
        echo "unsupported Linux host architecture: $(uname -m)" >&2
        exit 1
        ;;
esac

SYSROOT="${QEMU_ZIG_SYSROOT:-$SRC_DIR/zig-out-static-deps}"
mkdir -p "$SYSROOT" "$BUILD_DIR"
SYSROOT="$(cd "$SYSROOT" && pwd)"
BUILD_DIR="$(cd "$BUILD_DIR" && pwd)"

(
    cd "$SRC_DIR"
    zig build deps \
        -Dtarget="$ZIG_TARGET" \
        -Doptimize=ReleaseFast \
        --prefix "$SYSROOT"
)

HDR_COPY="$BUILD_DIR/zig-linux-headers-copy"
rm -rf "$HDR_COPY"
cp -r "$SRC_DIR/linux-headers" "$HDR_COPY"
ln -sfn "$ASM_ARCH" "$HDR_COPY/asm"

export PKG_CONFIG=pkg-config
export PKG_CONFIG_PATH="$SYSROOT/lib/pkgconfig"
export PKG_CONFIG_LIBDIR="$SYSROOT/lib/pkgconfig"

configure_args=(
    "--cc=zig cc -target $ZIG_TARGET"
    "--cxx=zig c++ -target $ZIG_TARGET"
    "--target-list=$TARGET_LIST"
    --static
    --without-default-features
    --enable-tools
    --enable-tcg
    --enable-slirp
    --enable-zstd
    --enable-nettle
    --enable-pixman
    --enable-fdt
    --disable-gio
    --disable-gcrypt
    --disable-gnutls
    --disable-guest-agent
    --disable-werror
    --disable-plugins
    --disable-modules
    --disable-curses
    --disable-install-blobs
    --bindir=
    --with-suffix=
    "--extra-cflags=-UNDEBUG -I$HDR_COPY -I$SYSROOT/include"
    "--extra-cxxflags=-UNDEBUG -I$HDR_COPY -I$SYSROOT/include"
    "--extra-ldflags=-L$SYSROOT/lib"
)

if [ -n "${QEMU_PKG_VERSION:-}" ]; then
    configure_args+=("--with-pkgversion=$QEMU_PKG_VERSION")
fi
if [ -n "${QEMU_ZIG_ACCEL_OPT:-}" ]; then
    configure_args+=("$QEMU_ZIG_ACCEL_OPT")
fi

cd "$BUILD_DIR"
"$SRC_DIR/configure" "${configure_args[@]}"
ninja "$@"
