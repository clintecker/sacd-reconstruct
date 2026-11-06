#!/bin/sh
# hud_build.sh — build the HUD for the player and pull it into the payload dir.
#
# One place for the flags that matter, each learned the hard way:
#   -std=gnu99        the gnuarm default is gnu89 (for-declarations fail)
#   -Wno-pragmas      vendored stb_truetype pragmas
#   dynamic           a static build's dlopen of the retail DirectFB dies on
#                     _dl_pagesize (mt85 run6 lesson)
#   DIRECTFB 1.2.7 headers need a configured tree (build.h) -- see DISPLAY-SPEC
set -eu
EXP="$(cd "$(dirname "$0")/.." && pwd)"
H="${VM_USER:-aftermath}@${VM_HOST:-10.20.0.18}"
P="${VM_PORT:-2222}"
SRC="$EXP/tools/bx510_sacd_hud.c"
OUT="$EXP/evidence/bx510/display-payload/sacd_hud"
scp -q -o BatchMode=yes -P "$P" "$SRC" "$H:/tmp/bx510_sacd_hud.c"
ssh -o BatchMode=yes -p "$P" "$H" '
set -e
T=~/mt85src/DirectFB-1.2.7
~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -std=gnu99 -Wall -Wextra -Wno-pragmas \
  -I$T/include -I$T/lib -I$T/lib/direct -I$T -o /tmp/sacd_hud /tmp/bx510_sacd_hud.c \
  -L/tmp/rootfs/lib -ldirectfb -ldirect -lfusion -lpthread -lrt -lm
~/gnuarm/bin/arm-none-linux-gnueabi-strip /tmp/sacd_hud
sha256sum /tmp/sacd_hud
'
scp -q -o BatchMode=yes -P "$P" "$H:/tmp/sacd_hud" "$OUT"
echo "payload: $OUT"
shasum -a 256 "$OUT"
