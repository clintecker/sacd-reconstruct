#!/bin/sh
# pairlaunch.sh — the pair-phase launcher wrapper.
#
# The CLI script line that invoked trace-launch directly was the longest
# line in the MTK script and the daemon never came up (three triggers,
# zero daemon processes in the hwmon snapshots) — suspected CLI_exec
# command-length/parse limits. This wrapper keeps the CLI line short
# (same shape as the proven baseline daemon line) and LOGS everything:
# if trace-launch or its preload fails, the reason lands on the stick.
#
# Runs from /tmp (copied there by the CLI script — the stick may unmount
# later, RAM copies survive). Resolves the stick dir itself (mount point
# moves between boots: sda1/sdb1 both observed).
D=$(ls -d /mnt/sd*/AutoScript 2>/dev/null | head -n 1)
[ -n "$D" ] || D=/tmp
mkdir -p "$D/hwmon-data" /tmp/hwmon-data 2>/dev/null

# log to BOTH the stick (live view while mounted) and RAM (recovered by
# hwmon_restore at the next trigger if the stick unmounts)
L1="$D/pairlaunch.log"
L2="/tmp/pairlaunch.log"
log() {
    echo "$@" >>"$L1" 2>/dev/null
    echo "$@" >>"$L2" 2>/dev/null
}

log "=== pairlaunch ==="
log "uptime: $(cat /proc/uptime 2>/dev/null)"
log "stick dir: $D"

# hwmon first: snapshots the daemon coming up (its own log + the process
# table are the evidence if anything dies)
/tmp/hwmon.bin "$D/hwmon-data" /tmp/hwmon-data >/dev/null 2>&1 &
log "hwmon started (pid $!)"

# the pair capture itself
H=$(ls -d /mnt/sd*/optical 2>/dev/null | head -n 1)
if [ -z "$H" ]; then
    log "FATAL: no /mnt/sd*/optical dir"
    exit 1
fi
log "optical dir: $H contents:"
ls -la "$H" >>"$L1" 2>/dev/null
ls -la "$H" >>"$L2" 2>/dev/null
log "launching trace-launch: $H/trace-launch.sh /sacd_extract_160 600 /tmp/firebird.pair -S"

# Debug observer (pair-retry session): the stick's optical/bx510_pair.so IS
# bx510_pair_dbg.so for this session (name-only substitution staged by
# sacd-usb-pair-mode). Its env contract adds BX510_PAIR_LOG=<absolute path>
# on top of the BX510_PAIR_OUT/BX510_PAIR_LSN that trace-launch.sh sets — it
# logs the arming decision, every READ/DECRYPT, and the save outcome, so a
# silent pair-file miss becomes a NAMED cause. The log lives in RAM;
# hwmon_restore.sh copies it to the stick at the next trigger. Appending
# (not truncating) preserves earlier triggers' logs; the separator below
# delimits this trigger (the observer has no timestamps of its own).
PAIRLOG=/tmp/bx510-pairdbg.log
BX510_PAIR_LOG="$PAIRLOG"
export BX510_PAIR_LOG
log "debug observer: BX510_PAIR_LOG=$PAIRLOG (bx510_pair_dbg.so as $H/bx510_pair.so)"
echo "=== pairlaunch trigger (uptime $(cat /proc/uptime 2>/dev/null)) ===" >>"$PAIRLOG" 2>/dev/null

rm -f /tmp/firebird.pair 2>/dev/null
exec /bin/sh "$H/trace-launch.sh" /sacd_extract_160 600 /tmp/firebird.pair -S
