#!/bin/sh
# Build with Zig 0.13.0 and the actual guest libraries.
set -eu
test "$#" -eq 2 || { echo "usage: $0 SONY_ROOTFS_LIB_DIR OUTPUT_SO" >&2; exit 2; }
src=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
libs=$(CDPATH='' cd -- "$1" && pwd)
out=$2
temp=$(mktemp -d)
trap 'rm -rf "$temp"' EXIT
"${ZIG:-zig}" cc -target arm-linux-gnueabi -mcpu=arm1176jzf_s -marm -mfloat-abi=soft \
    -O2 -fPIC -fno-stack-protector -std=gnu11 -Wall -Wextra -Werror \
    -c "$src/pair_trace.c" -o "$temp/trace.o"
"${ZIG:-zig}" cc -target arm-linux-gnueabi -mcpu=arm1176jzf_s -marm \
    -c "$src/ioctl_arm.S" -o "$temp/ioctl.o"
"${ZIG:-zig}" ld.lld -m armelf_linux_eabi -s -shared -soname bx510_pair.so --as-needed \
    --hash-style=both -z now -z defs -z noexecstack -z max-page-size=4096 --no-rosegment \
    -T "$src/rel-arm.ld" \
    -o "$out" "$temp/trace.o" "$temp/ioctl.o" \
    "$libs/libdl.so.2" "$libs/libpthread.so.0" "$libs/libc.so.6" "$libs/libgcc_s.so.1"
