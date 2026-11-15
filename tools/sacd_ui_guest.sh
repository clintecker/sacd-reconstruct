#!/bin/sh
# sacd_ui_guest.sh — the in-guest sequence for the enhanced SACD UI (run c123).
# Staged by tools/sacd_ui_build.sh (it rides inside the daemon payload tgz) and
# fired as the probe's single --guest-cmd:  sh /res/shim/sacd_ui_guest.sh
#
# It is a FILE, not a one-liner, on purpose: the guest shell truncated long
# one-liners (Run C43 lesson), and this sequence is the c122g daemon bring-up
# plus a framebuffer, a UI client and a frame readback.
#
# Ordering rules that are load-bearing (each cost a run):
#   1. sr_fa_mode CLEAR comes AFTER sr_mod is loaded (c122f: a read with the
#      latch set returns ZERO FE traffic and the daemon "succeeds" silently).
#   2. The UI takes its own client session; the daemon parks every connection
#      in ONE shared accept slot (decode/daemon-socket-protocol.md §0.6), so a
#      second client only runs after the UI writes /res/ui-session.done. That
#      marker is written at DISC_CLOSE, never guessed with a sleep.
#   3. /res is a tmpfs here, so Sony's /res/font.bin is shadowed — the font is
#      the staged copy under /res/shim/sony-font.ttf (HUD_FONT chain).
#   4. The frame is read back with fbdump --pool (the proven pool-slice dump),
#      AFTER the UI exits, so the dump is one COMPLETE frame.
set -u
PATH=/sbin:/usr/sbin:/bin:/usr/bin:/res/shim; export PATH
SHIM=/res/shim
HOLD=30

echo UI_STAGE_BEGIN
mkdir -p /tmp; mount -t tmpfs tmpfs /tmp; echo UI_TMP=$?
ifconfig lo 127.0.0.1 netmask 255.0.0.0 up; echo UI_LO=$?
tar -xzf $SHIM/daemon_payload.tgz -C /res; echo UI_TGZ=$?
ls -l $SHIM/sacd_ui $SHIM/fbdump $SHIM/sony-font.ttf $SHIM/bx510_fbvirt.ko
md5sum $SHIM/sacd_ui $SHIM/fbdump $SHIM/sony-font.ttf; echo UI_PAYLOAD_MD5=$?

# --- the c122g module stack ------------------------------------------------
insmod $SHIM/bx510_cpsa_peer.ko; echo UI_PEER=$?
insmod $SHIM/sacd_read.ko minor=201 compid=0; echo UI_SACDREAD=$?
rm -f /dev/sacd_read; mknod /dev/sacd_read c 10 201; echo UI_NODE=$?
$SHIM/sacdgate 0x40105301 /dev/sacd_read
$SHIM/sacdgate 0x40105305 /dev/sacd_read
# the FA/be-quiet latch (order matters: AFTER sr_mod, see header)
$SHIM/sr_fa_mode /dev/sr0 clear; echo UI_FA_CLEAR=$?
$SHIM/sr_fa_mode /dev/sr0
grep sr0 /res/proc/partitions

# --- the guest framebuffer + vendor pool (HUD guest-gate path) -------------
# NOTE: this guest ALSO carries the real mt8530 framebuffer, so fbvirt is NOT
# fb0 (c123b: /proc/fb = "0 mt8530 / 1 fbvirt", and drawing into fb0's pool
# mapping SIGBUSed). Pick fbvirt's index from /proc/fb instead of assuming 0.
insmod $SHIM/bx510_fbvirt.ko; echo UI_FBVIRT=$?
cat /res/proc/fb; echo UI_PROC_FB=$?
set -- $(grep fbvirt /res/proc/fb)
FBIDX=$1
echo UI_FBIDX=$FBIDX
rm -f /dev/fb$FBIDX; mknod /dev/fb$FBIDX c 29 $FBIDX; echo UI_FBNODE=$?
FBDEV=/dev/fb$FBIDX
ls -l $FBDEV

# --- the daemon ------------------------------------------------------------
# Quiet the kernel's console writers BEFORE the frame readback: on a busy
# guest they interleave into the FBPIX hex and truncated it at 1016/230400
# pixels (c123c). Level 3 keeps errors/oopses, drops the driver chatter; the
# shell's own echo output is /dev/console, so the evidence lines still land.
echo 3 > /res/proc/sys/kernel/printk 2>/dev/null || echo 3 > /proc/sys/kernel/printk
cat /res/proc/sys/kernel/printk 2>/dev/null

cd $SHIM || echo UI_CD_FAIL=$?
./sacd_extract_160 -S </dev/null >/res/daemon.out 2>&1 &
sleep 8
grep -q 'SACD Daemon 0.37 active' /res/daemon.out; echo UI_DAEMON_ORACLE=$?

# --- the UI: a real client session, then render + /proc watch --------------
rm -f /res/ui-session.done
SACD_UI_FB=$FBDEV SACD_UI_FONT=$SHIM/sony-font.ttf SACD_UI_DONE_FILE=/res/ui-session.done \
    ./sacd_ui 127.0.0.1 $HOLD >/res/ui.out 2>&1 &
UI_PID=$!
echo UI_PID=$UI_PID

# wait for the UI's session to CLOSE before any second client runs
n=0
while [ ! -f /res/ui-session.done ] && [ $n -lt 180 ]; do sleep 1; n=$((n+1)); done
echo UI_SESSION_WAIT=$n
cat /res/ui-session.done 2>/dev/null

# an ordinary second client — the activity the UI sees from /proc/net/tcp
./sacdclient 127.0.0.1 510 10 /tmp/client-toc.bin; echo UI_CLIENT_RC=$?
md5sum /tmp/client-toc.bin
sleep 2

wait $UI_PID; echo UI_RC=$?

# --- the frame the UI left in the vendor pool ------------------------------
# --rows: one FBPIXROW line per sampled row, so any surviving console
# interleaving damages ONE row instead of truncating the whole frame.
./fbdump --pool $FBDEV 3 4096 1920 1080 --rows > /res/fb.txt 2>&1; echo UI_DUMP_RC=$?
echo UI_OUT_BEGIN
cat /res/ui.out
echo UI_OUT_END
grep FBGEOM /res/fb.txt
echo UI_FB_BEGIN
cat /res/fb.txt
echo UI_FB_END
grep -q UI_PASS /res/ui.out && echo UI_PASS_MARKER=1 || echo UI_PASS_MARKER=0
echo UI_STAGE_DONE
echo SACD_UI_DONE
