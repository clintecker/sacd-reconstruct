#!/bin/sh
# Build the board into the pinned upstream release, keeping source and build
# objects under the chosen work directory. No system installation is performed.
set -eu
kit_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
work=${1:-"$kit_dir/work"}
mkdir -p "$work"
work=$(CDPATH='' cd -- "$work" && pwd)
archive="$work/qemu-9.2.4.tar.xz"
src="$work/qemu-9.2.4"
if [ ! -f "$archive" ]; then
    if [ -f "$kit_dir/upstream/qemu-9.2.4.tar.xz" ]; then
        cp "$kit_dir/upstream/qemu-9.2.4.tar.xz" "$archive.part"
    else
        curl --fail --location --retry 2 --output "$archive.part" https://download.qemu.org/qemu-9.2.4.tar.xz
    fi
    mv "$archive.part" "$archive"
fi
python3 - "$archive" <<'PY'
from pathlib import Path
import sys, hashlib
h = hashlib.sha256()
with Path(sys.argv[1]).open("rb") as f:
    for chunk in iter(lambda: f.read(1 << 20), b""):
        h.update(chunk)
if h.hexdigest() != "f3cc1c4eabfdb288218ac3e33763dbe9e276d8bc890b867a2335d58de2ddd39a":
    raise SystemExit("QEMU source SHA-256 mismatch")
PY
if [ ! -f "$src/.bx510-patched" ]; then
    if [ -d "$src" ]; then
        echo "Choose a new work directory or remove the incomplete source tree: $src" >&2
        exit 1
    fi
    tar --no-same-owner -xf "$archive" -C "$work"
    (cd "$src" && patch -p1 < "$kit_dir/qemu-integration.patch")
    touch "$src/.bx510-patched"
fi
cp "$kit_dir/sony-bx510.c" "$kit_dir/mt8560-nfi.c" "$kit_dir/mt8560-nfi.h" "$src/hw/arm/"
mkdir -p "$work/build"
cd "$work/build"
if [ ! -f build.ninja ]; then
    "$src/configure" --target-list=arm-softmmu --without-default-devices --without-default-features \
        --enable-tcg --enable-fdt=system --disable-docs --disable-werror --disable-guest-agent
fi
ninja -j "${JOBS:-4}" qemu-system-arm
./qemu-system-arm -machine help | grep 'sony-bx510'
