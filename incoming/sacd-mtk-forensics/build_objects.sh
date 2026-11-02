#!/bin/sh
# Run against a configured, built GNU GCC 4.4.1 cross compiler and target GAS.
set -eu
if [ "$#" -ne 4 ]; then
    echo "usage: $0 GCC_SOURCE GCC_BUILD ARM_AS OUTPUT_DIR" >&2
    exit 2
fi
src=$(cd "$1" && pwd)
build=$(cd "$2" && pwd)
arm_as=$3
out=$4
mkdir -p "$out"
# Keep assembler sources temporary. The result consists of three relocatables.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
compile() {
    name=$1
    input=$2
    shift 2
    # GCC's ARM Linux libgcc rules compile division as PIC with unwind support.
    # The host compiler was built without a target sysroot. These routines do
    # not need target libc headers. Build-tree headers supply the GCC types.
    "$build/gcc/xgcc" -B"$build/gcc/" -O2 -g -marm -march=armv6z \
        -mfloat-abi=soft -mabi=aapcs-linux -fPIC -fexceptions -fnon-call-exceptions \
        -fvisibility=hidden -DHIDE_EXPORTS -DIN_GCC -DCROSS_DIRECTORY_STRUCTURE \
        -DIN_LIBGCC2 -D__GCC_FLOAT_NOT_NEEDED -Dinhibit_libc \
        -fdebug-prefix-map="$src"=gcc-4.4.1 -fdebug-prefix-map="$build"=gcc-build \
        -I"$build/gcc" -I"$src/gcc" -I"$src/include" -I"$src/libgcc" \
        "$@" -S "$input" -o "$tmp/$name.s"
    "$arm_as" -march=armv6z -meabi=5 -o "$out/$name.o" "$tmp/$name.s"
}
compile bpabi     "$src/gcc/config/arm/bpabi.c"
compile _divdi3   "$src/gcc/libgcc2.c" -DL_divdi3
compile _udivdi3  "$src/gcc/libgcc2.c" -DL_udivdi3
