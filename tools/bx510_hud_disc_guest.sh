#!/bin/sh
# hudisc3.sh — the HUD disc-console fire: dump the pool MID-SESSION.
#
# Derived from shim/hudpan1.sh (the proven HUD-panel guest script, itself the
# rendered bx510_ui_guest.sh.in with all mandatory invariants intact).
# The hudisc1 lesson: the standard ui-fire dumps AFTER the UI's session, and
# the disc scene's DISC_CLOSE handler clears toc_valid — so the captured frame
# was the honest post-close idle frame (fallback heads, no rows). This script
# dumps the pool WHILE the UI's client session is open, after its first frame
# (first frame => the TOC read completed => the daemon published toc_valid=1).
#   * the FA-latch clear (sr_fa_mode) — c122f
#   * the /tmp tmpfs — daemon-wiring §2
#   * frame egress + UI_SHOT_DONE marker
#   * the fbvirt fb node bound to the index fbvirt actually got (run u1: fb1)

# 1. the VFS skeleton an init=/bin/sh guest does not have
mkdir -p /tmp /res/tmp
mount -t tmpfs tmpfs /tmp
# 2. loopback, so the client leg reaches the daemon at 127.0.0.1:2002
ifconfig lo 127.0.0.1 netmask 255.0.0.0 up
# 3. the payload tgz: daemon + sacd_read.ko + sacdgate + client + UI + FB kit
tar -xzf /res/shim/daemon_payload.tgz -C /res
# 4. the SACD session — c122g's proven Connect/Release pair
insmod /res/shim/bx510_cpsa_peer.ko
insmod /res/shim/sacd_read.ko minor=201 compid=0
rm -f /dev/sacd_read
mknod /dev/sacd_read c 10 201
/res/shim/sacdgate 0x40105301 /dev/sacd_read
/res/shim/sacdgate 0x40105305 /dev/sacd_read
# 5. THE FA-LATCH CLEAR (mandatory). Second invocation = read-back + next open.
/res/shim/sr_fa_mode /dev/sr0 clear
/res/shim/sr_fa_mode /dev/sr0
grep sr0 /res/proc/partitions
# 6. the display: fbvirt comes up as fb1 with the daemon stack resident (run u1)
insmod /res/shim/bx510_fbvirt.ko
cat /res/proc/fb
set -- $(grep fbvirt /res/proc/fb); mknod /dev/fb0 c 29 $1
insmod /lib/modules/2.6.35/BDP/fusion.ko
set -- $(grep fusion /res/proc/devices); mknod /dev/fusion0 c $1 0
# 7. the daemon: the ONE HUD, panel mode, the MERGED disc console scene
cd /res/shim
HUD_SCENE=disc HUD_POOL_DEV=/dev/fb0 HUD_FONT=/res/shim/sony-font.ttf ./sacd_extract_160 -S --hud=panel </dev/null >/res/daemon.out 2>&1 &
echo DAEMON_PID=$!
sleep 8
cat /res/daemon.out; echo DAEMON_OUT_END
# 8. the rip leg (hudisc2 lesson: sacd_ui paints the SAME pool and its
#    console frame wins the panel — the ripper client paints nothing).
#    Repeated sector reads in the background: every session is
#    DISC_OPEN (TOC publish) + reads (telemetry), so the disc console
#    renders LIVE data while the dump happens.
( i=0; while [ $i -lt 40 ]; do ./sacdclient 127.0.0.1 544 128 /tmp/rip-$i.bin; i=$((i+1)); done ) >/res/rip.out 2>&1 &
R=$!
echo RIP_PID=$R
# 9. MID-RIP pool dump: the TOC is published, reads are flowing — the
#    disc console's money frame. Twelve seconds settle several sessions.
sleep 12
echo UI_SCALE=6
./fbdump --rows --pool /dev/fb0 6 4096 1920 1080 >/res/fb-pool-mid.txt 2>&1
echo UI_DUMP_POOL_MID=$?
cat /res/fb-pool-mid.txt; echo UI_POOL_MID_END
# 10. stop the rip, then the honest post-close idle frame for contrast
kill $R 2>/dev/null
sleep 2
cat /res/rip.out; echo RIP_OUT_END
./fbdump --rows /dev/fb0 6 >/res/fb-fbdev.txt 2>&1
echo UI_DUMP_FBDEV=$?
cat /res/fb-fbdev.txt; echo UI_FBDEV_END
./fbdump --rows --pool /dev/fb0 6 4096 1920 1080 >/res/fb-pool.txt 2>&1
echo UI_DUMP_POOL=$?
cat /res/fb-pool.txt; echo UI_POOL_END
echo UI_SHOT_DONE
cat /res/daemon.out; echo DAEMON_OUT_END2
