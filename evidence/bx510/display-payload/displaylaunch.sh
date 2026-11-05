#!/bin/sh
# displaylaunch.sh — the display-leg launcher (does OUR pixels reach the TV?).
#
# Runs from /tmp (copied there by a short CLI line — the proven shape; a
# script executed straight off the stick would break if the stick unmounts
# mid-run). The stick mount point MOVES between boots (sda1/sdb1/sdc1/sdd1
# all observed) — resolve it with the glob, never a fixed path.
#
# What it does, in order (each stage logs BEFORE it runs, so a crash leaves
# the cause named on the stick AND in RAM):
#   1. dump the display state the plan still owes: /proc/fb, /dev/fb*,
#      fb0 sysfs (blank/state/stride), /dev/fusion*, /proc/fusion/*,
#      /dev/shm, bdpprog presence + its fd table, directfbrc, meminfo head
#   2. cyberdraw --static on EVERY /dev/fb* — device sweep: geometry + a
#      deterministic full-frame md5 per device (the RETURN CHANNEL: these
#      land in the log even if the TV shows nothing — "drew on fbN" and
#      "fbN is displayed" are separate claims). The first device that opens
#      and draws is the one the anim uses.
#   3. cyberdraw --anim N on that device — the TV-video window (default
#      45 s, capped 100 by the tool; a `displayanim` file on the stick
#      overrides). It ends on the static frame, so a photo after the run is
#      still meaningful.
#   4. Phase-0 inventory re-run DURING the anim — our process holding
#      /dev/fb0 is exactly the "active-display" state RECONCILIATION §14
#      lists as still unmeasured (idle captures had zero fb/fusion holders).
#   5. a post-run state dump (blank/state/holders) — the difference
#      before/during/after names a repaint or a blanking cause.
#
# busybox constraint (hardware-proven): the player has NO date/tr/cut/sed/
# tail/readlink certainty — use cat, ls, head, sleep, pidof and shell
# builtins ONLY.
#
# Evidence contract: a TV photo/video of the cyberpunk scene is the DISPLAY
# proof; this log is the CAUSE proof when the screen stays black (device
# missing / open failed / screeninfo failed / mmap failed / wrong bpp /
# blank=1 / drew and nobody scanned it out). "Draw returned 0" is NOT
# display evidence.
D=$(ls -d /mnt/sd*/AutoScript 2>/dev/null | head -n 1)
[ -n "$DISPLAY_D" ] && D="$DISPLAY_D"   # test hook (VM smoke, fake stick)
[ -n "$D" ] || D=/tmp
L1="$D/displaylaunch.log"
L2="/tmp/displaylaunch.log"
log() {
    printf '%s\n' "$@" >>"$L1" 2>/dev/null
    printf '%s\n' "$@" >>"$L2" 2>/dev/null
}
# /proc/uptime is the only clock this busybox reliably has
utime() {
    up=""
    read -r up _ < /proc/uptime 2>/dev/null && printf '%s' "${up%%.*}"
}
# fb0 sysfs + device + holder state, in one repeatable block
state_dump() { # $1 = stage label
    log "--- state($1) uptime $(utime) ---"
    log "proc/fb: $(cat /proc/fb 2>/dev/null)"
    log "ls /dev/fb*: $(ls -l /dev/fb* 2>&1)"
    for f in /sys/class/graphics/fb0/blank /sys/class/graphics/fb0/state \
             /sys/class/graphics/fb0/stride /sys/class/graphics/fb0/virtual_size \
             /sys/class/graphics/fb0/mode; do
        [ -f "$f" ] && log "$f: $(cat "$f" 2>/dev/null)"
    done
    log "ls /dev/fusion*: $(ls -l /dev/fusion* 2>&1)"
    log "ls /proc/fusion: $(ls -l /proc/fusion 2>&1)"
    log "ls /dev/shm: $(ls -la /dev/shm 2>&1)"
    B=$(pidof bdpprog 2>/dev/null)
    log "bdpprog pid: $B"
    if [ -n "$B" ] && [ -d "/proc/$B/fd" ]; then
        log "bdpprog fd table:"
        log "$(ls -l "/proc/$B/fd" 2>&1)"
    fi
}

# anim seconds: env override, then the stick's displayanim file (written by
# usb-display-mode — an env assignment on the CLI line is NOT proven to
# survive CLI_exec), then the default
ANIM=45
if [ -f "$D/displayanim" ]; then
    read -r A < "$D/displayanim" 2>/dev/null
    case "$A" in ''|*[!0-9]*) : ;; *) ANIM="$A" ;; esac
fi
[ -n "$DISPLAY_ANIM" ] && ANIM="$DISPLAY_ANIM"

# trigger separator: the stick log APPENDS across triggers/boots (same
# convention as pairlaunch.sh — an early death never destroys earlier
# evidence); each run is bounded by its own header/footer block
log "=== displaylaunch trigger (uptime $(cat /proc/uptime 2>/dev/null)) ==="
log "uptime: $(cat /proc/uptime 2>/dev/null)"
log "stick dir: $D"
log "osrelease: $(cat /proc/sys/kernel/osrelease 2>/dev/null)"

state_dump before

for f in /proc/fusion/*; do
    [ -f "$f" ] || continue
    log "$f: $(cat "$f" 2>/dev/null)"
done
log "--- directfbrc ---"
for f in /usr/etc/directfbrc /etc/directfbrc /usr/local/etc/directfbrc; do
    [ -f "$f" ] && log "$f: $(cat "$f" 2>/dev/null)"
done
log "meminfo (head): $(head -n 3 /proc/meminfo 2>/dev/null)"

C="$D/cyberdraw"
[ -x "$C" ] || C=/tmp/cyberdraw
log "cyberdraw: $C (executable: $([ -x "$C" ] && echo yes || echo NO))"
if [ ! -x "$C" ]; then
    log "FATAL: no executable cyberdraw (stick or /tmp) — aborting display leg"
    log "=== displaylaunch end (no draw) ==="
    exit 1
fi

# run the drawer once, teeing its output into BOTH logs (program output is
# appended separately from the log() lines — no duplication)
run_tool() { # $1 = tool path, $2 = stage label, rest = args
    tl=$1
    lb=$2
    shift 2
    : >/tmp/displaylaunch.$lb
    "$tl" "$@" >>/tmp/displaylaunch.$lb 2>&1
    rc=$?
    log "$lb exit: $rc"
    cat /tmp/displaylaunch.$lb >>"$L1" 2>/dev/null
    cat /tmp/displaylaunch.$lb >>"$L2" 2>/dev/null
    return $rc
}
draw() { # $1 = stage label; rest = cyberdraw args
    lb=$1
    shift
    run_tool "$C" "$lb" "$@"
}

# Stage 2 — the deterministic frame FIRST, on EVERY fb device: geometry + md5
# land in the log before anything can hang or be repainted over. A device the
# appliance does not scan out still proves the paint; the sweep is what finds
# the OSD/second-plane case instead of guessing fb0.
FBGLOB="${FB_GLOB:-/dev/fb*}"   # FB_GLOB is a test hook (VM/fake-stick smoke)
FBOK=""
FBSEEN=0
log "--- cyberdraw --static device sweep ($FBGLOB) uptime $(utime) ---"
for d in $FBGLOB; do
    [ -e "$d" ] || continue
    FBSEEN=$((FBSEEN + 1))
    if draw "static-${d##*/}" --static "$d"; then
        [ -n "$FBOK" ] || FBOK="$d"
    fi
done
[ "$FBSEEN" -eq 0 ] && log "no character device matched $FBGLOB (nothing probed)"
log "display device for the anim: ${FBOK:-none} (probed $FBSEEN)"

# Stage 2c — Tier-1: the REAL DirectFB stack (the vendor pool is the
# scan-out; a raw /dev/fb0 paint never reaches the panel). dfbhello links the
# player's own libdirectfb/libdirect/libfusion and draws through the retail
# provider, which is exactly the path the appliance itself uses.
# the HUD mock (docs/HUD-DESIGN.md phase H0) supersedes the colour-bar probe
# when staged: same stack, the actual interface layout
HUD="$D/sacd_hud"
[ -x "$HUD" ] || HUD=/tmp/sacd_hud
DFB="$D/dfbhello"
[ -x "$DFB" ] || DFB=/tmp/dfbhello
if [ -x "$HUD" ]; then
    # LIVE logging: append straight to the stick log so the first HUD lines
    # (init rcs, self-test) exist within seconds instead of at exit — the
    # 120 s hold used to mean "pull the stick and see nothing"
    log "--- sacd_hud (real DirectFB stack) uptime $(utime) ---"
    "${HUD}" "${HUD_SECS:-600}" >>"$L1" 2>&1 &
    HP=$!
    wait $HP 2>/dev/null
    log "hud exit: $?"
    DFBRAN=yes
elif [ -x "$DFB" ]; then
    log "--- dfbhello (real DirectFB stack) uptime $(utime) ---"
    run_tool "$DFB" dfbhello 1920 1080 25
    DFBRAN=yes
else
    log "dfbhello/sacd_hud: absent (Tier-1 probe not staged)"
    DFBRAN=
fi

# Stage 4 — active-display inventory, fired INTO the animation window.
# (The normal per-boot guard covers the trigger path; this is an explicit
# second sample, named by uptime so it can never be confused with it.)
if [ -x "$D/inventory" ]; then
    (
        sleep 5
        UU=$(utime)
        # RAM FIRST (the stick can unmount mid-window — proven failure mode);
        # hwmon_restore.sh recovers /tmp/inventory-active-* at the next trigger
        "$D/inventory" >"/tmp/inventory-active-$UU.txt" 2>&1
        cp "/tmp/inventory-active-$UU.txt" "$D/inventory-active-$UU.txt" 2>/dev/null
        log "inventory (active-display sample) -> stick $D/inventory-active-$UU.txt (RAM copy /tmp/inventory-active-$UU.txt)"
    ) &
    log "inventory active-display sample armed (+5s)"
fi

# stage-2b — did anything repaint our pixels away? fbmd5 re-reads the same
# region WITHOUT painting: same hash as cyberdraw's => the buffer kept our
# frame (a black TV then means "not the scan-out surface"); different hash =>
# the appliance repainted us.
FBM="$D/fbmd5"
[ -x "$FBM" ] || FBM=/tmp/fbmd5
if [ -x "$FBM" ] && [ -n "$FBOK" ]; then
    log "--- fbmd5 settle check on $FBOK (+2s) uptime $(utime) ---"
    sleep 2
    run_tool "$FBM" fbmd5 "$FBOK"
fi

# Stage 3 — the TV-video window (on the first device that drew; if none did,
# retry the default /dev/fb0 so ITS named error is in the log too).
# NOTE: cyberdraw takes the device as argv[2] (which collides with --anim's
# seconds arg — "open 45" bug, attempt 7), so target it with CYBER_FBDEV.
if [ -n "$DFBRAN" ]; then
    log "--- cyberdraw --anim skipped (dfbhello already ran) ---"
elif [ -n "$FBOK" ]; then
    log "--- cyberdraw --anim $ANIM on $FBOK (uptime $(utime)) ---"
    CYBER_FBDEV="$FBOK"
    export CYBER_FBDEV
    draw anim --anim "$ANIM"
else
    log "--- cyberdraw --anim $ANIM on /dev/fb0 (no device drew; error path) ---"
    CYBER_FBDEV=/dev/fb0
    export CYBER_FBDEV
    draw anim --anim "$ANIM"
fi
# and once more afterwards: what is in the buffer when the anim ends?
if [ -x "$FBM" ] && [ -n "$FBOK" ]; then
    log "--- fbmd5 after anim on $FBOK (uptime $(utime)) ---"
    run_tool "$FBM" fbmd5-after "$FBOK"
fi

# Stage 5 — did anything change while we were drawing?
state_dump after
log "=== displaylaunch end (uptime $(utime)) ==="
exit 0
