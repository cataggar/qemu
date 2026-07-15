#!/usr/bin/env bash
#
# Cross-compile qemu-img/qemu-io for Windows (x86_64-windows-gnu) from a
# Linux runner, using `zig cc`/`zig c++` as the compiler and *our own*
# Zig-package-managed target libraries instead of MSYS2/vcpkg (see
# https://github.com/cataggar/qemu/issues/17). This is the true-cross-compile
# follow-up to scripts/build-with-zig-cc.sh, which only builds natively.
#
# Prerequisites (see .github/workflows/zig-windows-cross.yml for the full
# list installed in CI):
#   - zig 0.16.0 on PATH
#   - meson, ninja, pkg-config, python3
#   - binutils-mingw-w64-x86-64 (apt), for a *real* GNU windres/ar/dlltool/
#     nm/objcopy/strip that understand PE/COFF. This is the one piece we do
#     not build with zig cc ourselves: zig has no windres equivalent that
#     speaks GNU windres's command-line dialect (meson's windows module
#     shells out to plain `windres`-style args, not MSVC rc.exe-style args,
#     whenever the C compiler isn't MSVC/clang-cl -- see meson's
#     mesonbuild/modules/windows.py:_find_resource_compiler). This is a
#     generic binutils cross-tools package, not a prebuilt Windows glib2/
#     pixman package, so it does not reintroduce the MSYS2/vcpkg dependency
#     issue #17 is about.
#   - Network access on the first build so Zig can fetch the immutable
#     packages pinned in the root build.zig.zon.
#
# Usage:  scripts/build-with-zig-cc-windows.sh [build-dir]
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${1:-$SRC_DIR/build-zig-windows}"
SYSROOT="${QEMU_ZIG_SYSROOT:-$SRC_DIR/zig-out-windows-deps}"

ZIG_TARGET=x86_64-windows-gnu
export ZIG_TARGET   # read by scripts/zig-cc-windows-defs/rc-preprocessor.sh
CROSS_PREFIX=x86_64-w64-mingw32-

mkdir -p "$BUILD_DIR" "$SYSROOT"
BUILD_DIR="$(cd "$BUILD_DIR" && pwd)"
SYSROOT="$(cd "$SYSROOT" && pwd)"

( cd "$SRC_DIR" && zig build deps \
    -Dtarget="$ZIG_TARGET" \
    -Doptimize=ReleaseFast \
    --prefix "$SYSROOT" )

export PKG_CONFIG_PATH="$SYSROOT/lib/pkgconfig"
export PKG_CONFIG_LIBDIR="$SYSROOT/lib/pkgconfig"
# QEMU's configure defaults pkg_config to "${cross_prefix}pkg-config"
# (x86_64-w64-mingw32-pkg-config here), but pkg-config itself is not a
# per-target binary -- binutils-mingw-w64-x86-64 doesn't ship one under
# that name, only ar/nm/strip/windres/dlltool/etc. Point it at the plain
# host pkg-config instead; PKG_CONFIG_PATH/LIBDIR above are what actually
# make it resolve glib-2.0/pixman-1/zlib to our Windows .pc files.
export PKG_CONFIG=pkg-config

# x86_64-w64-mingw32-windres (a real GNU tool, unlike our C/C++ compiler)
# shells out to "${cross_prefix}gcc" by default to preprocess version.rc
# (expanding its #include/#define macros), which doesn't exist here since
# we only install binutils-mingw-w64-x86-64 (no gcc-mingw-w64).
# scripts/zig-cc-windows-defs/rc-preprocessor.sh (a `zig cc -E` shim,
# using zig cc's own bundled mingw-w64 headers -- no system mingw-w64-dev
# package needed) is used instead, via windres's --preprocessor= flag.
# configure/meson tokenizes a space-separated WINDRES value into a proper
# argv list for the generated cross file (same mechanism already relied
# on for --cc="zig cc -target ...").
DEFS_DIR="$SRC_DIR/scripts/zig-cc-windows-defs"
export WINDRES="${CROSS_PREFIX}windres --preprocessor=$DEFS_DIR/rc-preprocessor.sh"

# zig's bundled mingw-w64 subset doesn't include the libpathcch.a/
# libsynchronization.a friendly-name import-lib aliases that QEMU's
# meson.build hard-requires on Windows (cc.find_library('pathcch',
# required: true) / ('synchronization', required: true)) -- only the
# underlying api-ms-win-*.def files they'd normally be built from. See
# scripts/zig-cc-windows-defs/*.def for the full rationale; synthesize
# those two import libs here with `zig dlltool` (zig's drop-in
# dlltool.exe) rather than depending on a full mingw-w64 install.
mkdir -p "$BUILD_DIR/windows-import-libs"
IMPLIB_DIR="$BUILD_DIR/windows-import-libs"
zig dlltool -d "$DEFS_DIR/pathcch.def" -l "$IMPLIB_DIR/libpathcch.a" -m i386:x86-64
zig dlltool -d "$DEFS_DIR/synchronization.def" -l "$IMPLIB_DIR/libsynchronization.a" -m i386:x86-64

EXTRA_FLAGS="-UNDEBUG -I$SYSROOT/include"   # zig cc defines NDEBUG by default; osdep.h rejects that
EXTRA_LDFLAGS="-L$IMPLIB_DIR -L$SYSROOT/lib"

cd "$BUILD_DIR"
"$SRC_DIR/configure" \
    --cross-prefix="$CROSS_PREFIX" \
    --cc="zig cc -target $ZIG_TARGET" \
    --cxx="zig c++ -target $ZIG_TARGET" \
    --target-list= \
    --enable-tools \
    --enable-zstd \
    --disable-system \
    --disable-guest-agent \
    --disable-werror \
    --disable-plugins \
    --extra-cflags="$EXTRA_FLAGS" \
    --extra-cxxflags="$EXTRA_FLAGS" \
    --extra-ldflags="$EXTRA_LDFLAGS" \
    "${@:2}"

ninja qemu-img.exe qemu-io.exe

echo
echo "Built with zig cc for $ZIG_TARGET:"
file qemu-img.exe qemu-io.exe
