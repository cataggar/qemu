#!/bin/sh
# Preprocessor shim for x86_64-w64-mingw32-windres (see
# scripts/build-with-zig-cc-windows.sh). GNU windres shells out to a real
# C preprocessor to expand macros/#includes in .rc files, defaulting to
# "${cross_prefix}gcc" -- which doesn't exist here, since we only install
# binutils-mingw-w64-x86-64 (no gcc-mingw-w64). `zig cc -E` works fine as
# a drop-in preprocessor and, unlike a plain native `cpp`, correctly
# predefines the Windows-target macros (_WIN32, __MINGW32__, etc.) that
# version.rc's includes (winver.h et al) depend on.
exec zig cc -target "${ZIG_TARGET:-x86_64-windows-gnu}" -E -x c "$@"
