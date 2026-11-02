#!/bin/sh
# Usage: build_installer.sh ARM_CC ARM_AS HISTORICAL_SYSROOT RECONSTRUCT_DIR OUT_OBJECT [extra_cc_options]
set -eu
if test "$#" -lt 5; then
    echo "usage: $0 ARM_CC ARM_AS SYSROOT RECONSTRUCT_DIR OUT_OBJECT [extra compiler options]" >&2
    exit 2
fi
cc=$1; arm_as=$2; sysroot=$3; repo=$4; out=$5
shift 5
dir=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# Compile the complete file. The opening literal-copy probe in isolation can
# have a different register assignment.
"$cc" "$@" -x c -O0 -marm -march=armv6z -mfloat-abi=soft -mabi=aapcs-linux \
    -fno-pic -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64 -DLIBSACD_INTERNAL \
    -isystem "$sysroot/usr/include" -I"$repo/tool" -I"$repo/libcommon" \
    -S "$dir/install_module.c" -o "$tmp/installer.s"
"$arm_as" -march=armv6z -meabi=5 "$tmp/installer.s" -o "$out"
