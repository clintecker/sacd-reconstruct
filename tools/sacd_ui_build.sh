#!/bin/sh
# sacd_ui_build.sh — build the enhanced-SACD-UI binaries with the ERA toolchain
# on the lab VM and rebuild the one staging channel (the daemon payload tgz).
#
# The flags are the HUD's proven set (tools/hud_build.sh): gnuarm 2009q3,
# -std=gnu99 (the default is gnu89 — for-declarations fail), -Wno-pragmas
# (vendored stb_truetype), DYNAMIC link (the guest rootfs carries the libs,
# exactly like tools/sacdclient.c which runs there today). No DirectFB: the UI
# paints through the fbdev + vendor-pool path the guest gate proved.
#
# Staging channel: fe_test_data is 1 MiB TOTAL and already carries the five
# daemon files (~466 KiB uncompressed, 208 KiB as the tgz). The new members
# ride inside the SAME tgz the guest already extracts to /res:
#   sacd_ui          the UI client (this build)
#   fbdump           the proven pool readback (tools/bx510_fbdump.c)
#   fbvirt.ko        the guest framebuffer+pool model (/tmp/mt85mod2)
#   sony-font.ttf    Sony's screen font (/res is a tmpfs in the probe run, so
#                    /res/font.bin is shadowed and the font must be staged)
#   sacd_ui_guest.sh the in-guest fire sequence (one staged script, not a
#                    long one-liner — the Run C43 truncation lesson)
# The budget check prints the tgz size against the 1 MiB partition.
set -eu
REPO=$(cd "$(dirname "$0")/.." && pwd)
H="${VM_USER:-aftermath}@${VM_HOST:-10.20.0.18}"
P="${VM_PORT:-2222}"
SCP="scp -q -o BatchMode=yes -P $P"
SSH="ssh -o BatchMode=yes -p $P $H"
OUT="$REPO/evidence/bx510/display-payload"

$SCP "$REPO/tools/sacd_ui.c" "$REPO/tools/bx510_fbdump.c" "$REPO/tools/sacd_ui_guest.sh" "$H:/tmp/"
$SCP "$REPO/tools/third_party/stb_truetype.h" "$H:/tmp/"
$SCP "$REPO/evidence/bx510/display-payload/sony-font.ttf" "$H:/tmp/sony-font.ttf"

$SSH '
set -e
mkdir -p /tmp/third_party
cp /tmp/stb_truetype.h /tmp/third_party/
G=~/gnuarm/bin/arm-none-linux-gnueabi-
${G}gcc -O2 -std=gnu99 -Wall -Wextra -Wno-pragmas -I/tmp \
  -o /tmp/sacd_ui /tmp/sacd_ui.c -lrt -lm
${G}strip /tmp/sacd_ui
${G}gcc -O2 -std=gnu99 -Wall -o /tmp/fbdump /tmp/bx510_fbdump.c
${G}strip /tmp/fbdump
sha256sum /tmp/sacd_ui /tmp/fbdump

# --- the one staging channel: rebuild the daemon payload tgz -------------
mkdir -p /tmp/daemon-payload/shim
cp /tmp/dtgz/shim/sacd_extract_160 /tmp/dtgz/shim/sacd_read.ko \
   /tmp/dtgz/shim/sacdgate /tmp/daemon_gate.sh /tmp/sacdclient \
   /tmp/daemon-payload/shim/
cp /tmp/sacd_ui /tmp/fbdump /tmp/sony-font.ttf /tmp/sacd_ui_guest.sh \
   /tmp/mt85mod2/bx510_fbvirt.ko /tmp/daemon-payload/shim/
chmod 0755 /tmp/daemon-payload/shim/sacd_ui /tmp/daemon-payload/shim/fbdump \
           /tmp/daemon-payload/shim/sacd_ui_guest.sh \
           /tmp/daemon-payload/shim/sacd_extract_160 \
           /tmp/daemon-payload/shim/sacd_read.ko \
           /tmp/daemon-payload/shim/sacdgate \
           /tmp/daemon-payload/shim/sacdclient
cd /tmp/daemon-payload
python3 - <<PY
import os, tarfile
members = ["sacd_extract_160", "sacd_read.ko", "sacdgate", "daemon_gate.sh",
           "sacdclient", "sacd_ui", "fbdump", "sony-font.ttf",
           "bx510_fbvirt.ko", "sacd_ui_guest.sh"]
with tarfile.open("/tmp/bx510-daemon-payload.tgz", "w:gz") as t:
    for f in members:
        t.add("shim/" + f, arcname="shim/" + f)
raw = sum(os.path.getsize("shim/" + f) for f in members)
gz = os.path.getsize("/tmp/bx510-daemon-payload.tgz")
print("tgz: %d B gz / %d B raw, members %d" % (gz, raw, len(members)))
print("fe_test_data budget: 1048576 B -> %d B free in the tgz file alone" % (1048576 - gz))
PY
tar -tzvf /tmp/bx510-daemon-payload.tgz
'
$SCP "$H:/tmp/sacd_ui" "$OUT/sacd_ui"
$SCP "$H:/tmp/fbdump" "$OUT/fbdump"
echo "payload: $OUT/sacd_ui $OUT/fbdump"
shasum -a 256 "$OUT/sacd_ui" "$OUT/fbdump"
