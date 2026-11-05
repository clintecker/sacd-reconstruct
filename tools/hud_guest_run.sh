#!/bin/sh
# hud_guest_run.sh — run the HUD in the REAL Sony guest (QEMU on the lab VM) and
# GATE it: rc must be 0 AND the dumped pool framebuffer must not be black.
set -eu
H="${VM_USER:-aftermath}@${VM_HOST:-10.20.0.18}"
P="${VM_PORT:-2222}"
HERE="$(cd "$(dirname "$0")" && pwd)"
EXP="$(cd "$HERE/.." && pwd)"
DP="$EXP/evidence/bx510/display-payload"

scp -q -o BatchMode=yes -P "$P" "$HERE/bx510_hud_repro.py" "$HERE/bx510_fbdump.c" "$DP/sony-font.ttf" "$DP/sacd_hud" "$H:/tmp/"

cat > /tmp/hud_guest_run.sh <<'INNER'
set -eu
E=~/bx510-emu/emulator
~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -o $E/fbdump /tmp/bx510_fbdump.c
~/gnuarm/bin/arm-none-linux-gnueabi-strip $E/fbdump || true
cp /tmp/sacd_hud $E/sacd_hud
cp /tmp/bx510_hud_repro.py $E/
cp /tmp/sony-font.ttf $E/
cd $E
timeout 900 python3 bx510_hud_repro.py --qemu work/build/qemu-system-arm \
  --images ../images --shim /tmp/tmpredir.so --fbmod /tmp/mt85mod2/bx510_fbvirt.ko \
  --hud ./sacd_hud --fbdump ./fbdump --font ./sony-font.ttf \
  --log /tmp/hud_guest.log --secs 2 --pool-ofs 0 >/dev/null 2>&1 || true
INNER

ssh -o BatchMode=yes -p "$P" "$H" 'sh -s' < /tmp/hud_guest_run.sh >/dev/null 2>&1 || true
scp -q -o BatchMode=yes -P "$P" "$H:/tmp/hud_guest.log" /tmp/hud_guest.log
python3 "$HERE/hud_guest_gate.py" /tmp/hud_guest.log
