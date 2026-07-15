#!/usr/bin/env bash
#
# Cross-compile qemu-system-x86_64 for Windows (x86_64-windows-gnu) from a
# Linux runner, using `zig cc`/`zig c++`, with WHPX (Windows Hypervisor
# Platform) hardware-acceleration support built in. Follow-up to
# https://github.com/cataggar/qemu/issues/20, extending the tools-only
# scripts/build-with-zig-cc-windows.sh (issue #17) to the actual machine
# emulator. Console-only (`-nographic`) for this first pass: SDL/GTK/VNC/
# OpenGL are all disabled.
#
# Manually verified (see issue #20): a cross-compiled qemu-system-x86_64.exe
# built by this script boots real SeaBIOS firmware and a custom guest boot
# sector under `-accel whpx` on real Windows hardware -- not just TCG
# software emulation. GitHub-hosted windows-latest runners don't support
# nested virtualization, so this can only be *build*-verified in CI; WHPX
# runtime behavior needs manual verification on real hardware, same as
# this was done.
#
# Prerequisites: same as scripts/build-with-zig-cc-windows.sh (zig 0.16.0,
# meson/ninja/pkg-config/python3 and binutils-mingw-w64-x86-64). Target
# libraries are fetched and built through the root build.zig.zon.
#
# nettle is needed here (unlike the tools-only build) because
# --target-list=x86_64-softmmu makes have_system=true, and meson.build's
# crypto backend selection (gcrypt vs. nettle) becomes live; we force
# nettle explicitly with --enable-nettle --disable-gcrypt --disable-gnutls
# so gnutls/gcrypt (neither of which we have a zig-cc build of) are never
# probed.
#
# Usage:  scripts/build-with-zig-cc-windows-system.sh [build-dir]
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${1:-$SRC_DIR/build-zig-windows-system}"
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
export PKG_CONFIG=pkg-config   # see scripts/build-with-zig-cc-windows.sh

DEFS_DIR="$SRC_DIR/scripts/zig-cc-windows-defs"
export WINDRES="${CROSS_PREFIX}windres --preprocessor=$DEFS_DIR/rc-preprocessor.sh"

mkdir -p "$BUILD_DIR/windows-import-libs"
IMPLIB_DIR="$BUILD_DIR/windows-import-libs"
zig dlltool -d "$DEFS_DIR/pathcch.def" -l "$IMPLIB_DIR/libpathcch.a" -m i386:x86-64
zig dlltool -d "$DEFS_DIR/synchronization.def" -l "$IMPLIB_DIR/libsynchronization.a" -m i386:x86-64

# -DGLIB_STATIC_COMPILATION: without it, glib's headers declare functions
# like g_mapped_file_get_contents/g_sequence_new/g_thread_pool_new with
# __declspec(dllimport) (glib assumes it's usually a shared library on
# Windows), and lld-link refuses to resolve those against our plain
# static glib-2.0.lib archive ("... cannot be used because it is not an
# import library"). meson.build only adds this cflag automatically under
# --enable-static (get_option('prefer_static')), but turning that on
# flips meson's find_library() for pathcch/synchronization into a mode
# that only searches the compiler's own built-in library dirs (zig cc
# --print-search-dirs), ignoring our -L windows-import-libs entirely --
# so we define the macro ourselves instead of using --static.
EXTRA_FLAGS="-UNDEBUG -DGLIB_STATIC_COMPILATION -I$SYSROOT/include"
EXTRA_LDFLAGS="-L$IMPLIB_DIR -L$SYSROOT/lib"

cd "$BUILD_DIR"
"$SRC_DIR/configure" \
    --cross-prefix="$CROSS_PREFIX" \
    --cc="zig cc -target $ZIG_TARGET" \
    --cxx="zig c++ -target $ZIG_TARGET" \
    --target-list=x86_64-softmmu \
    --enable-tools \
    --enable-whpx \
    --enable-nettle \
    --enable-slirp \
    --enable-zstd \
    --disable-gcrypt \
    --disable-gnutls \
    --disable-sdl \
    --disable-gtk \
    --disable-vnc \
    --disable-opengl \
    --disable-virglrenderer \
    --disable-dbus-display \
    --disable-guest-agent \
    --disable-werror \
    --disable-plugins \
    --disable-curses \
    --disable-brlapi \
    --disable-spice \
    --disable-usb-redir \
    --disable-install-blobs \
    --extra-cflags="$EXTRA_FLAGS" \
    --extra-cxxflags="$EXTRA_FLAGS" \
    --extra-ldflags="$EXTRA_LDFLAGS" \
    "${@:2}"

ninja qemu-system-x86_64.exe

echo
echo "Built with zig cc for $ZIG_TARGET:"
file qemu-system-x86_64.exe
