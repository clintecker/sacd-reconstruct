#!/bin/sh
# Arguments: extracted Sony DirectFB-1.2.7 source, player /lib, output ELF.
set -eu
test "$#" -eq 3 || { echo "usage: $0 DIRECTFB_SOURCE SONY_LIB_DIR OUTPUT_ELF" >&2; exit 2; }
src=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
dfb=$(CDPATH='' cd -- "$1" && pwd)
libs=$(CDPATH='' cd -- "$2" && pwd)
out=$3
temp=$(mktemp -d)
trap 'rm -rf "$temp"' EXIT
mkdir -p "$temp/include/direct"
sed -E -e 's/@DIRECT_BUILD_(STDBOOL|TEXT)@/1/g' -e 's/@DIRECT_BUILD_[A-Z]+@/0/g' \
    "$dfb/lib/direct/build.h.in" > "$temp/include/direct/build.h"
"${ZIG:-zig}" cc -target arm-linux-gnueabi -mcpu=arm1176jzf_s -marm -mfloat-abi=soft \
    -O2 -fno-pie -fno-stack-protector -Wall -Wextra -Werror -std=gnu11 \
    -isystem "$temp/include" -isystem "$dfb/include" -isystem "$dfb/lib" \
    -c "$src/screen.c" -o "$temp/screen.o"
"${ZIG:-zig}" cc -target arm-linux-gnueabi -mcpu=arm1176jzf_s -marm \
    -c "$src/start_arm.S" -o "$temp/start.o"
"${ZIG:-zig}" ld.lld -m armelf_linux_eabi -s --hash-style=both --as-needed --allow-shlib-undefined \
    -e _start --dynamic-linker /lib/ld-linux.so.3 -z noexecstack -o "$out" \
    "$temp/start.o" "$temp/screen.o" "$libs/libdirectfb-1.2.so.0" \
    "$libs/libc.so.6" "$libs/libgcc_s.so.1"
