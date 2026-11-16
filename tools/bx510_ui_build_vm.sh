#!/bin/sh
# bx510_ui_build_vm.sh — the VM-SIDE half of `make bx510-ui-build`.
#
# Staged to /tmp and run over ssh by tools/bx510_ui_build.sh (the same split as
# bx510_stub_build.sh: the caller scp's sources, this script builds). It builds
# the whole UI kit with the era toolchain and REPACKS the daemon payload tgz in
# place, so one fire carries daemon + sacd_read.ko + helper + client + UI +
# framebuffer kit in the single nested-tgz staging channel
# (evidence/bx510-guest/bdpdrv/decode/daemon-wiring.md §4.3).
#
# Why every piece is built here and not reused from /tmp: the C110 lesson — a
# stale tgz member (daemon_gate.sh) served fires for several runs because the
# tgz was rebuilt from whatever /tmp already held. The tgz is therefore
# assembled from the REPO-staged sources and the pinned ELF every time.
#
# Inputs (all staged by the caller): /tmp/sacd_ui.c /tmp/sacdclient.c
#   /tmp/bx510_fbdump.c /tmp/bx510_fbvirt.c /tmp/bx510_fbvirt_mt85.h
#   /tmp/bx510_vermagic_patch.py /tmp/sacd_gate_ioctl.c /tmp/daemon_gate.sh
#   /tmp/third_party/{stb_truetype.h,font8x8_basic.h}
# Outputs: /tmp/ui_kit/{sacd_ui,sacdclient,fbdump,sacdgate,bx510_fbvirt.ko}
#   and the repacked /tmp/bx510-daemon-payload.tgz (TAM=)
set -eu

S=${S:-$HOME/the verification tree}
TAM=${TAM:-/tmp/bx510-daemon-payload.tgz}
OUT=/tmp/ui_kit
CC=$HOME/gnuarm/bin/arm-none-linux-gnueabi-gcc
STRIP=$HOME/gnuarm/bin/arm-none-linux-gnueabi-strip
KDIR=$HOME/sony-kernel/linux-2.6.35
DFBT=${DFBT:-$HOME/mt85src/DirectFB-1.2.7}

# pinned originals (daemon-wiring.md §4.2). A drifting daemon ELF would make
# every UI verdict un-attributable, so refuse instead of packing.
PIN_DAEMON=0fdcefdb84ae
PIN_KO=b3d7a383e45d
need_sha() {
    got=$(sha256sum "$1" | cut -d' ' -f1)
    case $got in
        "$2"*) : ;;
        *) echo "FATAL $1 sha256=$got does not start with $2 (pinned)"; exit 1 ;;
    esac
    echo "pin ok  $1 $got"
}
need_sha "$S/original/sacd_extract_160" "$PIN_DAEMON"
need_sha "$S/original/sacd_read.ko" "$PIN_KO"

rm -rf "$OUT"; mkdir -p "$OUT"

# ── userspace pieces (dynamic, Sony's own libc — the shape the guest runs) ──
build() {  # build <out-name> <src> [extra flags...]
    name=$1; src=$2; shift 2
    "$CC" "$@" -o "$OUT/$name" "$src" >/tmp/ui_build_"$name".log 2>&1 || {
        echo "FATAL build $name failed:"; tail -15 /tmp/ui_build_"$name".log; exit 1; }
    "$STRIP" "$OUT/$name" 2>/dev/null || true
    echo "built   $name $(stat -c%s "$OUT/$name") B"
}

build fbdump     /tmp/bx510_fbdump.c  -O2 -Wall -std=gnu99
build sacdclient /tmp/sacdclient.c    -O2 -Wall -std=gnu99
build sacdgate   /tmp/sacd_gate_ioctl.c -O2 -Wall -std=gnu99

# The UI's flags are the one thing this script cannot know in advance, so it
# reads them off the source instead of guessing: a DirectFB-drawing UI needs
# the retail headers/libs (hud_build.sh's proven set), a raw-fbdev one needs
# nothing. UI_CFLAGS / UI_LDFLAGS override both, for either case.
UI_CFLAGS=${UI_CFLAGS:--O2 -std=gnu99 -Wall -Wextra -Wno-pragmas -I/tmp/third_party}
if grep -qi 'directfb\|IDirectFB\|DFBSurface' /tmp/sacd_ui.c; then
    UI_LINK=${UI_LDFLAGS:--L/tmp/rootfs/lib -ldirectfb -ldirect -lfusion -lpthread -lrt -lm}
    UI_CFLAGS="$UI_CFLAGS -I$DFBT/include -I$DFBT/lib -I$DFBT/lib/direct -I$DFBT"
    echo "ui link: DirectFB (retail headers under $DFBT)"
else
    UI_LINK=${UI_LDFLAGS:-}
    echo "ui link: plain (no DirectFB reference in sacd_ui.c)"
fi
# shellcheck disable=SC2086  # word splitting of the flag strings is intended
build sacd_ui /tmp/sacd_ui.c $UI_CFLAGS $UI_LINK

# ── the kernel module: fbvirt is the guest's only fbdev ────────────────────
rm -rf /tmp/uimod; mkdir -p /tmp/uimod
cp /tmp/bx510_fbvirt.c /tmp/bx510_fbvirt_mt85.h /tmp/uimod/
echo 'obj-m := bx510_fbvirt.o' > /tmp/uimod/Makefile
export CROSS_COMPILE="$HOME/gnuarm/bin/arm-none-linux-gnueabi-"
make -C "$KDIR" ARCH=arm M=/tmp/uimod modules \
    EXTRA_CFLAGS="-U__LINUX_ARM_ARCH__ -D__LINUX_ARM_ARCH__=6 -march=armv6 -Wa,-march=armv6" \
    >/tmp/ui_build_fbvirt.log 2>&1 || {
        echo "FATAL fbvirt.ko build failed:"; tail -15 /tmp/ui_build_fbvirt.log; exit 1; }
python3 /tmp/bx510_vermagic_patch.py /tmp/uimod/bx510_fbvirt.ko
# NOT stripped: the proven artifact (/tmp/mt85mod2/bx510_fbvirt.ko, 117,079 B)
# keeps its debug/symbol sections, and a .ko is the one thing here where
# "smaller" is not obviously better. It gzips fine inside the tgz.
cp /tmp/uimod/bx510_fbvirt.ko "$OUT/bx510_fbvirt.ko"
echo "built   bx510_fbvirt.ko $(stat -c%s "$OUT/bx510_fbvirt.ko") B"
"$HOME/gnuarm/bin/arm-none-linux-gnueabi-strings" "$OUT/bx510_fbvirt.ko" | grep vermagic

# ── repack the nested tgz (members are guest paths: shim/<name>) ────────────
export S OUT TAM
python3 - <<'PY'
import hashlib, io, os, pathlib, tarfile
src = pathlib.Path(os.environ["S"]) / "original"
kit = pathlib.Path(os.environ["OUT"])
tam = pathlib.Path(os.environ["TAM"])
members = [
    (src / "sacd_extract_160", "shim/sacd_extract_160"),
    (src / "sacd_read.ko", "shim/sacd_read.ko"),
    (kit / "sacdgate", "shim/sacdgate"),
    (pathlib.Path("/tmp/daemon_gate.sh"), "shim/daemon_gate.sh"),
    (kit / "sacdclient", "shim/sacdclient"),
    (kit / "sacd_ui", "shim/sacd_ui"),
    (kit / "fbdump", "shim/fbdump"),
    (pathlib.Path("/tmp/sony-font.ttf"), "shim/sony-font.ttf"),
    (kit / "bx510_fbvirt.ko", "shim/bx510_fbvirt.ko"),
]
buf = io.BytesIO()
with tarfile.open(fileobj=buf, mode="w:gz", format=tarfile.USTAR_FORMAT) as arc:
    for path, name in members:
        blob = path.read_bytes()
        e = tarfile.TarInfo(name)
        e.size, e.mode = len(blob), 0o755
        arc.addfile(e, io.BytesIO(blob))
        print(f"  member {name:26s} {len(blob):8d} B  sha256 {hashlib.sha256(blob).hexdigest()[:16]}")
blob = buf.getvalue()
tam.write_bytes(blob)
print(f"tgz {tam} {len(blob)} B  sha256 {hashlib.sha256(blob).hexdigest()[:16]}")
PY
echo "UI-KIT-READY $OUT $TAM"
