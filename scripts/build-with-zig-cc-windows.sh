#!/usr/bin/env bash
#
# Cross-compile qemu-img/qemu-io for Windows (x86_64-windows-gnu) from a
# Linux runner, using `zig cc`/`zig c++` as the compiler and *our own*
# zig-built glib/pixman/libiconv/gettext/zlib instead of MSYS2/vcpkg (see
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
#   - Sibling checkouts of the `zig16` branch of:
#       https://github.com/cataggar/pixman
#       https://github.com/cataggar/glib
#       https://github.com/cataggar/libiconv
#       https://github.com/cataggar/gettext
#       https://github.com/cataggar/zlib
#     at ../pixman, ../glib, ../libiconv, ../gettext, ../zlib (relative to
#     this qemu checkout), or point QEMU_ZIG_DEPS_DIR at a directory
#     containing them.
#
# nettle is intentionally not built/wired here: with an empty --target-list
# (--disable-system, no linux-user/bsd-user targets), QEMU's meson.build
# only probes for nettle/gcrypt/gnutls when have_system is true, so it is
# not needed for a tools-only (qemu-img/qemu-io) build. See
# https://github.com/cataggar/nettle for the zig cc build of nettle itself,
# for when a future qemu-system cross-build needs it.
#
# Usage:  scripts/build-with-zig-cc-windows.sh [build-dir]
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${1:-$SRC_DIR/build-zig-windows}"
DEPS_DIR="${QEMU_ZIG_DEPS_DIR:-$(cd "$SRC_DIR/.." && pwd)}"

ZIG_TARGET=x86_64-windows-gnu
export ZIG_TARGET   # read by scripts/zig-cc-windows-defs/rc-preprocessor.sh
CROSS_PREFIX=x86_64-w64-mingw32-

DEPS="pixman glib libiconv gettext zlib"

for dep in $DEPS; do
  dep_dir="$DEPS_DIR/$dep"
  if [ ! -f "$dep_dir/build.zig" ]; then
    echo "error: expected a zig16 checkout of cataggar/$dep at $dep_dir (see script header)" >&2
    exit 1
  fi
  echo "== building $dep for $ZIG_TARGET =="
  ( cd "$dep_dir" && zig build -Dtarget="$ZIG_TARGET" -Doptimize=ReleaseFast )
done

mkdir -p "$BUILD_DIR/pkgconfig"
BUILD_DIR="$(cd "$BUILD_DIR" && pwd)"
PC_DIR="$BUILD_DIR/pkgconfig"

# Hand-written .pc files pointing straight at each sibling repo's zig-out/,
# rather than installing/copying into a shared sysroot -- keeps this script
# simple and avoids a second copy of every header/lib. All runtime deps are
# listed directly in Libs (not Libs.private) since we don't distinguish
# static/dynamic consumers here.
write_pc() {
  local name="$1" version="$2" cflags="$3" libs="$4" vars="${5:-}"
  { [ -n "$vars" ] && printf '%s\n' "$vars"
    cat <<EOF
Name: $name
Description: zig cc build of $name for $ZIG_TARGET (see cataggar/$name, zig16 branch)
Version: $version
Cflags: $cflags
Libs: $libs
EOF
  } > "$PC_DIR/$name.pc"
}

write_pc zlib 1.3.2 \
  "-I$DEPS_DIR/zlib/zig-out/include" \
  "-L$DEPS_DIR/zlib/zig-out/lib -lz"

write_pc pixman-1 0.46.5 \
  "-I$DEPS_DIR/pixman/zig-out/include/pixman-1" \
  "-L$DEPS_DIR/pixman/zig-out/lib -lpixman-1"

# glib's own zig-out already bundles the libiconv/gettext headers and
# static libs it links against (see cataggar/glib build.zig), so a single
# -I/-L pair plus all four static libs + the Windows system libs glib
# needs (ws2_32/winmm/ole32/shell32) is enough -- no separate iconv-1.pc/
# libintl.pc required. `bindir` is only defined because meson.build
# unconditionally reads it (glib_pc.get_variable('bindir')) to build the
# nsis_cmd argument list for the (unused, for qemu-img/qemu-io) 'nsis'
# installer target -- meson evaluates that meson.build code at configure
# time regardless of which ninja target is actually requested.
write_pc glib-2.0 2.89.1 \
  "-I$DEPS_DIR/glib/zig-out/include" \
  "-L$DEPS_DIR/glib/zig-out/lib -lglib-2.0 -liconv -lintl -lws2_32 -lwinmm -lole32 -lshell32" \
  "prefix=$DEPS_DIR/glib/zig-out
bindir=\${prefix}/bin"

export PKG_CONFIG_PATH="$PC_DIR"
export PKG_CONFIG_LIBDIR="$PC_DIR"
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

EXTRA_FLAGS="-UNDEBUG"   # zig cc defines NDEBUG by default; osdep.h rejects that (see build-with-zig-cc.sh)
EXTRA_LDFLAGS="-L$IMPLIB_DIR"

cd "$BUILD_DIR"
"$SRC_DIR/configure" \
    --cross-prefix="$CROSS_PREFIX" \
    --cc="zig cc -target $ZIG_TARGET" \
    --cxx="zig c++ -target $ZIG_TARGET" \
    --target-list= \
    --enable-tools \
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
