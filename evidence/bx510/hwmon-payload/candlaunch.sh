#!/bin/sh
# candlaunch.sh — daemon-debug launcher: run sacd_extract_160 -S with its
# stdout/stderr CAPTURED and its exit status RECORDED.
#
# Why this exists (2026-11-04 hardware session, attempt 2): the release
# candidate started on the player and was gone within 6 s — the hwmon
# snapshots caught `/sacd_extract_160 -S` at uptime 62 and not at 68, and
# port 2002 was never bound. The stock launch line redirects nothing, so
# the cause died with ipcd's console. This wrapper is the instrument:
# it starts the daemon exactly as the stock line does (same binary in /,
# same -S), captures the output, samples liveness for 40 s, and records
# rc + dmesg when it dies.
#
# Runs from /tmp (copied by a short CLI line — proven shape). Stick dir is
# resolved by glob (mount point moves: sda1/sdb1/sdc1/sdd1 observed).
#
# busybox constraint (hardware-proven): cat, ls, head, sleep, pidof, kill
# and builtins only — no date/tr/cut/sed/tail/readlink.
D=$(ls -d /mnt/sd*/AutoScript 2>/dev/null | head -n 1)
[ -n "$CANDLAUNCH_D" ] && D="$CANDLAUNCH_D"   # test hook (VM smoke)
[ -n "$D" ] || D=/tmp
L1="$D/candlaunch.log"
L2="/tmp/candlaunch.log"
log() {
    printf '%s\n' "$@" >>"$L1" 2>/dev/null
    printf '%s\n' "$@" >>"$L2" 2>/dev/null
}
utime() {
    up=""
    read -r up _ < /proc/uptime 2>/dev/null && printf '%s' "${up%%.*}"
}

log "=== candlaunch trigger (uptime $(cat /proc/uptime 2>/dev/null)) ==="
log "stick dir: $D"
log "daemon: $(ls -l /sacd_extract_160 2>&1)"
log "osrelease: $(cat /proc/sys/kernel/osrelease 2>/dev/null)"
log "proc/modules has sacd_read: $(cat /proc/modules 2>/dev/null | head -n 40)"
log "dev/sacd_read: $(ls -l /dev/sacd_read 2>&1)"
# module-loader preconditions: the daemon shells out to insmod/rmmod, which
# live in /sbin on this rootfs (/bin/busybox does not exist) — a PATH without
# /sbin inside ipcd's system() context fails install_modules on BOTH binaries
log "PATH: $PATH"
log "insmod: $(ls -l /sbin/insmod 2>&1)"
log "rmmod: $(ls -l /sbin/rmmod 2>&1)"
log "tmp dir: $(ls -ld /tmp 2>&1)"
log "id: $(id 2>&1)"
# who owns the misc device the module needs (minor 201)? bdpdrv carries its
# own CPSA/SACD stack; if it registered 201 first, our insmod dies EBUSY
log "proc/misc: $(cat /proc/misc 2>/dev/null)"
log "proc/devices: $(cat /proc/devices 2>/dev/null)"

# --- standalone module probe (does the BLOB even load in this state?) ---
# The daemon's own insmod returns EBUSY (module init claims CPSA). Probing the
# extracted sacd_read.ko directly separates "the blob cannot load" from "the
# daemon mishandles the failure", and its stderr carries the real errno.
KO="$D/sacd_read.ko"
if [ -f "$KO" ]; then
    log "ko: $(ls -l "$KO" 2>&1)"
    : >/tmp/ko_probe.out
    insmod "$KO" minor=201 >>/tmp/ko_probe.out 2>&1
    log "probe insmod minor=201 (compid default) rc=$?"
    # init_module maps -EBUSY to "compid = N is used. Try another." when the
    # appliance already holds that CPSA compute id — so pre-load on a free one
    # (param compid, 0-3). The daemon's own insmod then fails "busy" harmlessly
    # and its validate_device() sees a live module.
    for c in 0 1 2 3; do
        insmod "$KO" compid=$c minor=201 >>/tmp/ko_probe.out 2>&1
        rc=$?
        log "preload compid=$c minor=201 rc=$rc"
        if [ "$rc" -eq 0 ]; then
            log "module PRE-LOADED on compid=$c"
            PRELOADED="yes"
            break
        fi
    done
    log "proc/misc after preload: $(cat /proc/misc 2>/dev/null)"
    log "proc/misc after probes: $(cat /proc/misc 2>/dev/null)"
    cat /tmp/ko_probe.out >>"$L1" 2>/dev/null
    cat /tmp/ko_probe.out >>"$L2" 2>/dev/null
    if [ "$PRELOADED" = "yes" ]; then
        log "leaving the preloaded module in place for the daemon"
    else
        rmmod sacd_read >>/tmp/ko_probe.out 2>&1
        log "probe rmmod rc=$?"
    fi
else
    log "ko: $KO absent (no standalone module probe)"
fi

# OPT-IN per-request telemetry: with a `hudevents` flag on the stick, start
# the daemon under the LD_PRELOAD observer (optical/bx510_pair.so) and let it
# log every READ/DECRYPT to /tmp/hud-events.log — the HUD tails that file, so
# the ticker shows real requests instead of startup chatter.
if [ -f "$D/hudevents" ] && [ -f "$D/optical/bx510_pair.so" ]; then
    BX510_PAIR_LOG=/tmp/hud-events.log
    LD_PRELOAD="$D/optical/bx510_pair.so"
    export BX510_PAIR_LOG LD_PRELOAD
    log "observer enabled: LD_PRELOAD=$LD_PRELOAD BX510_PAIR_LOG=$BX510_PAIR_LOG"
fi

# start EXACTLY like the stock line, but with output captured
: >/tmp/cand.out
/sacd_extract_160 -S >/tmp/cand.out 2>&1 &
PID=$!
log "started pid $PID at uptime $(utime)"

i=0
died=""
while [ "$i" -lt 40 ]; do
    if kill -0 "$PID" 2>/dev/null; then
        sleep 1
        i=$((i + 1))
    else
        died="yes"
        break
    fi
done

if [ -n "$died" ]; then
    wait "$PID" 2>/dev/null
    rc=$?
    log "daemon DIED within ${i}s — exit status $rc (uptime $(utime))"
    dmesg >/tmp/cand.dmesg 2>/dev/null
    cp /tmp/cand.dmesg "$D/cand.dmesg" 2>/dev/null
    log "dmesg captured -> $D/cand.dmesg (/tmp/cand.dmesg)"
else
    log "daemon ALIVE after ${i}s (pid $PID) — leaving it running (uptime $(utime))"
fi

if [ -f /tmp/hud-events.log ]; then
    log "observer events: $(cat /proc/uptime 2>/dev/null | head -c 0) see /tmp/hud-events.log"
fi
log "--- daemon output (/tmp/cand.out) ---"
cat /tmp/cand.out >>"$L1" 2>/dev/null
cat /tmp/cand.out >>"$L2" 2>/dev/null
log "--- tcp table (port 2002 = 07D2) ---"
log "$(cat /proc/net/tcp 2>/dev/null)"
log "=== candlaunch end (uptime $(utime)) ==="
exit 0
