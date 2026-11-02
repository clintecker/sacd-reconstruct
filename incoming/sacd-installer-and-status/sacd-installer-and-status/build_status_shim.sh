#!/bin/sh
# Usage: build_status_shim.sh ARM_CC ARM_LD SYSROOT OUTPUT_SO [extra compiler options]
# For an uninstalled GCC, pass its -B/path/to/build/gcc/ as the final option.
set -eu
if test "$#" -lt 4; then
    echo "usage: $0 ARM_CC ARM_LD SYSROOT OUTPUT_SO [extra compiler options]" >&2
    exit 2
fi
cc=$1
ld=$2
sysroot=$3
out=$4
shift 4
dir=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# Use the target's legacy libc headers and link only to its libc/libdl DSOs.
"$cc" "$@" -O2 -marm -march=armv6z -mfloat-abi=soft -fPIC \
  -fno-unwind-tables -fno-asynchronous-unwind-tables \
  -isystem "$sysroot/usr/include" -c "$dir/status_probe.c" -o "$tmp/shim.o"
"$ld" -shared -z defs -soname status_probe.so -o "$out" "$tmp/shim.o" \
  -rpath-link "$sysroot/lib" "$sysroot/lib/libdl.so.2" "$sysroot/lib/libc.so.6"
