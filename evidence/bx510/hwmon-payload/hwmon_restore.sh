#!/bin/sh
# Runs FIRST on every AutoScript trigger (both baseline and pair modes):
# - records the trigger state (uptime, mounts, previous daemon, TCP) to
#   the stick
# - recovers RAM-backed artifacts from a previous trigger: hwmon
#   snapshots (/tmp/hwmon-data) and the pair capture (/tmp/firebird.pair)
#   — RAM survives SLEEP; only full power loss clears it. The stick may
#   unmount in the serving state, so all captures write to RAM and are
#   recovered here at the NEXT trigger (reinsertion).
# - removes the stale pair file so trace-launch (which refuses existing
#   outputs) starts clean
# - runs the Phase-0 runtime inventory ONCE per boot (guarded by uptime
#   monotonicity: /proc/uptime resets at boot, so a current uptime LOWER
#   than the newest recorded one means a NEW boot -> collect; higher
#   means the same boot -> skip. Output: $D/inventory-<uptime>.txt)
# - kills any previous daemon so each trigger launches a fresh instance
D=$(ls -d /mnt/sd*/AutoScript 2>/dev/null | head -n 1)
[ -n "$D" ] || exit 0
{
    echo "=== AutoScript trigger ==="
    cat /proc/uptime 2>/dev/null
    echo "--- mounts ---"
    cat /proc/mounts
    echo "--- previous daemon ---"
    ls -la /sacd_extract_160 2>/dev/null
    echo "--- tcp ---"
    cat /proc/net/tcp 2>/dev/null
} >>"$D/hwmon-boot.txt" 2>&1
# --- Phase-0 runtime inventory (once per boot) ---
# Tolerant: a missing binary or unreadable uptime is logged, never fatal —
# this script must keep working as the trigger bootstrap either way.
# busybox constraint (hardware-proven): the player's busybox lacks date,
# tr and cut, and only head is proven among text tools — so this block
# uses shell builtins + parameter expansion ONLY.
if [ -x "$D/inventory" ]; then
    up=""; U=""
    read -r up _ < /proc/uptime 2>/dev/null && U=${up%%.*}
    if [ -n "$U" ]; then
        LAST=""
        for f in "$D"/inventory-*.txt; do
            [ -f "$f" ] || continue
            n=${f##*inventory-}; n=${n%.txt}
            case "$n" in *[!0-9]*) continue ;; esac
            if [ -z "$LAST" ] || [ "$n" -gt "$LAST" ]; then LAST=$n; fi
        done
        if [ -n "$LAST" ] && [ "$U" -gt "$LAST" ]; then
            echo "inventory: skipped (uptime $U > last collection $LAST, same boot)" >>"$D/hwmon-boot.txt"
        elif "$D/inventory" >"$D/inventory-$U.txt" 2>&1; then
            echo "inventory: wrote $D/inventory-$U.txt" >>"$D/hwmon-boot.txt"
        else
            echo "inventory: FAILED (exit $?), output so far in $D/inventory-$U.txt" >>"$D/hwmon-boot.txt"
        fi
    else
        echo "inventory: skipped (cannot read /proc/uptime)" >>"$D/hwmon-boot.txt"
    fi
else
    echo "inventory: skipped ($D/inventory missing or not executable)" >>"$D/hwmon-boot.txt"
fi
# --- /tmp hygiene (2026-11-04, hardware): every trigger appends hwmon
# snapshots to /tmp/hwmon-data and nothing prunes them; over ~15 triggers the
# rw ramfs filled and BOTH writers' output became ZERO-BYTE files (inventory
# and displaylaunch logs) while the programs themselves still ran. Recovered
# copies on the stick are already safe, so the RAM set is disposable per
# trigger.
rm -rf /tmp/hwmon-data 2>/dev/null

# --- CPSA module preload (compid) ---
# init_module returns -EBUSY when its CPSA compute id is taken by the
# appliance ("compid = N is used. Try another."), which killed every daemon
# launch in 1 s until we found it. Preload on a free compid so the daemon's
# own install_modules finds the module operational and validates it.
case "$(cat /proc/modules 2>/dev/null)" in
    *sacd_read*) : ;;
    *)
        if [ -f "$D/sacd_read.ko" ]; then
            for c in 0 1 2 3; do
                if insmod "$D/sacd_read.ko" compid=$c minor=201 2>/dev/null; then
                    echo "cpsa: preloaded sacd_read.ko compid=$c" >>"$D/hwmon-boot.txt"
                    break
                fi
            done
        fi ;;
esac

# --- display leg bootstrap (flag-driven) ---
# The MTK CLI parser truncates longer scripts (evidence 2026-11-04 attempt 6:
# a 13-line/628-byte display script ran hwmon_restore and then stopped — no
# hwmon, no wrapper, no cyberdraw). So the display AutoScript stays at the
# PROVEN baseline length and the leg is armed by the displayanim flag file,
# started here (line 4, always executes).
if [ -f "$D/displayanim" ]; then
    # ONE supervisor owns the leg (module preload + daemon + HUD). The player
    # fires this script more than once per insertion, and per-trigger daemon/HUD
    # starts made triggers kill each other (SIGKILL 137, two HUDs flipping on
    # the panel). Whoever runs last wins; the kill above removed the rest.
    if [ -f "$D/hudlaunch.sh" ]; then
        # IDEMPOTENT: the player retriggers this script about every 10 s
        # (observed 2026-11-05). Only one supervisor may exist; later triggers
        # must not start a second one or kill the first.
        RUNPID=""
        [ -f /tmp/hudlaunch.pid ] && read -r RUNPID < /tmp/hudlaunch.pid
        case "$(cat /proc/$RUNPID/cmdline 2>/dev/null)" in
            *hudlaunch*) ALIVE=1 ;;
            *) ALIVE=0 ;;
        esac
        if [ -n "$RUNPID" ] && [ "$ALIVE" = "1" ]; then
            echo "display: supervisor already running (pid $RUNPID)" >>"$D/hwmon-boot.txt"
        else
            cp "$D/hudlaunch.sh" /tmp/hudlaunch.sh 2>/dev/null
            echo "display: starting hudlaunch.sh supervisor (uptime $(cat /proc/uptime 2>/dev/null))" >>"$D/hwmon-boot.txt"
            /bin/sh /tmp/hudlaunch.sh >/dev/null 2>&1 &
        fi
    elif false; then
        echo "display: starting hudlaunch.sh supervisor (uptime $(cat /proc/uptime 2>/dev/null))" >>"$D/hwmon-boot.txt"
        /bin/sh /tmp/hudlaunch.sh >/dev/null 2>&1 &
    elif [ -f "$D/displaylaunch.sh" ] && [ -f "$D/cyberdraw" ]; then
        cp "$D/displaylaunch.sh" /tmp/dl.sh 2>/dev/null
        cp "$D/cyberdraw" /tmp/cyberdraw 2>/dev/null
        cp "$D/fbmd5" /tmp/fbmd5 2>/dev/null
        cp "$D/dfbhello" /tmp/dfbhello 2>/dev/null
        cp "$D/sacd_hud" /tmp/sacd_hud 2>/dev/null
        chmod 755 /tmp/cyberdraw /tmp/dl.sh /tmp/fbmd5 /tmp/dfbhello /tmp/sacd_hud 2>/dev/null
        echo "display: fallback displaylaunch.sh (no supervisor staged)" >>"$D/hwmon-boot.txt"
        /bin/sh /tmp/dl.sh >/dev/null 2>&1 &
    else
        echo "display: displayanim set but payload missing" >>"$D/hwmon-boot.txt"
    fi
fi
if [ -d /tmp/hwmon-data ]; then
    B="$D/hwmon-backup"
    mkdir -p "$B" 2>/dev/null && cp -r /tmp/hwmon-data/. "$B/" 2>/dev/null
    echo "restored /tmp/hwmon-data -> $B" >>"$D/hwmon-boot.txt"
fi
if [ -f /tmp/firebird.pair ]; then
    cp /tmp/firebird.pair "$D/firebird.pair" 2>/dev/null
    echo "recovered pair capture -> $D/firebird.pair" >>"$D/hwmon-boot.txt"
fi
# display leg: the active-display inventory samples live in RAM first (the
# stick may unmount during the animation window)
for f in /tmp/inventory-active-*.txt; do
    [ -f "$f" ] || continue
    cp "$f" "$D/" 2>/dev/null && echo "recovered $f -> $D/${f##*/}" >>"$D/hwmon-boot.txt"
done
# daemon-debug leg: the captured daemon output (separate from its log)
if [ -f /tmp/cand.out ]; then
    cp /tmp/cand.out "$D/cand-recovered.out" 2>/dev/null \
        && echo "recovered /tmp/cand.out -> $D/cand-recovered.out" >>"$D/hwmon-boot.txt"
fi
for L in /tmp/pairlaunch.log /tmp/bx510-pairdbg.log /tmp/displaylaunch.log \
         /tmp/candlaunch.log; do
    if [ -f "$L" ]; then
        B=$(basename "$L" .log)
        cp "$L" "$D/$B-recovered.log" 2>/dev/null
        echo "recovered $L -> $D/$B-recovered.log" >>"$D/hwmon-boot.txt"
    fi
done
rm -f /tmp/firebird.pair 2>/dev/null
# NB: do NOT kill the daemon here. It is started by the supervisor, and the
# daemon binds 2002 WITHOUT SO_REUSEADDR -- killing it costs ~60 s of TIME_WAIT
# during which every restart fails (2026-11-05). The supervisor decides.
# --- /tmp hygiene (2026-11-04, hardware): every trigger appends hwmon
# snapshots to /tmp/hwmon-data and nothing prunes them; over ~15 triggers the
# rw ramfs filled and BOTH writers' output became ZERO-BYTE files (inventory
# and displaylaunch logs) while the programs themselves still ran. Recovered
# copies on the stick are already safe, so the RAM set is disposable per
# trigger.
rm -rf /tmp/hwmon-data 2>/dev/null

# --- CPSA module preload (compid) ---
# init_module returns -EBUSY when its CPSA compute id is taken by the
# appliance ("compid = N is used. Try another."), which killed every daemon
# launch in 1 s until we found it. Preload on a free compid so the daemon's
# own install_modules finds the module operational and validates it.
case "$(cat /proc/modules 2>/dev/null)" in
    *sacd_read*) : ;;
    *)
        if [ -f "$D/sacd_read.ko" ]; then
            for c in 0 1 2 3; do
                if insmod "$D/sacd_read.ko" compid=$c minor=201 2>/dev/null; then
                    echo "cpsa: preloaded sacd_read.ko compid=$c" >>"$D/hwmon-boot.txt"
                    break
                fi
            done
        fi ;;
esac

# --- display leg bootstrap (flag-driven) ---
# The MTK CLI parser truncates longer scripts (evidence 2026-11-04 attempt 6:
# a 13-line/628-byte display script ran hwmon_restore and then stopped — no
# hwmon, no wrapper, no cyberdraw). So the display AutoScript stays at the
# PROVEN baseline length and the leg is armed by the displayanim flag file,
# started here (line 4, always executes).
if [ -f "$D/displayanim" ]; then
    # ONE supervisor owns the leg (module preload + daemon + HUD). The player
    # fires this script more than once per insertion, and per-trigger daemon/HUD
    # starts made triggers kill each other (SIGKILL 137, two HUDs flipping on
    # the panel). Whoever runs last wins; the kill above removed the rest.
    if [ -f "$D/hudlaunch.sh" ]; then
        # IDEMPOTENT: the player retriggers this script about every 10 s
        # (observed 2026-11-05). Only one supervisor may exist; later triggers
        # must not start a second one or kill the first.
        RUNPID=""
        [ -f /tmp/hudlaunch.pid ] && read -r RUNPID < /tmp/hudlaunch.pid
        if [ -n "$RUNPID" ] && kill -0 "$RUNPID" 2>/dev/null; then
            echo "display: supervisor already running (pid $RUNPID)" >>"$D/hwmon-boot.txt"
        else
            cp "$D/hudlaunch.sh" /tmp/hudlaunch.sh 2>/dev/null
            echo "display: starting hudlaunch.sh supervisor (uptime $(cat /proc/uptime 2>/dev/null))" >>"$D/hwmon-boot.txt"
            /bin/sh /tmp/hudlaunch.sh >/dev/null 2>&1 &
        fi
    elif false; then
        echo "display: starting hudlaunch.sh supervisor (uptime $(cat /proc/uptime 2>/dev/null))" >>"$D/hwmon-boot.txt"
        /bin/sh /tmp/hudlaunch.sh >/dev/null 2>&1 &
    elif [ -f "$D/displaylaunch.sh" ] && [ -f "$D/cyberdraw" ]; then
        cp "$D/displaylaunch.sh" /tmp/dl.sh 2>/dev/null
        cp "$D/cyberdraw" /tmp/cyberdraw 2>/dev/null
        cp "$D/fbmd5" /tmp/fbmd5 2>/dev/null
        cp "$D/dfbhello" /tmp/dfbhello 2>/dev/null
        cp "$D/sacd_hud" /tmp/sacd_hud 2>/dev/null
        chmod 755 /tmp/cyberdraw /tmp/dl.sh /tmp/fbmd5 /tmp/dfbhello /tmp/sacd_hud 2>/dev/null
        echo "display: fallback displaylaunch.sh (no supervisor staged)" >>"$D/hwmon-boot.txt"
        /bin/sh /tmp/dl.sh >/dev/null 2>&1 &
    else
        echo "display: displayanim set but payload missing" >>"$D/hwmon-boot.txt"
    fi
fi
if [ -d /tmp/hwmon-data ]; then
    B="$D/hwmon-backup"
    mkdir -p "$B" 2>/dev/null && cp -r /tmp/hwmon-data/. "$B/" 2>/dev/null
    echo "restored /tmp/hwmon-data -> $B" >>"$D/hwmon-boot.txt"
fi
if [ -f /tmp/firebird.pair ]; then
    cp /tmp/firebird.pair "$D/firebird.pair" 2>/dev/null
    echo "recovered pair capture -> $D/firebird.pair" >>"$D/hwmon-boot.txt"
fi
# display leg: the active-display inventory samples live in RAM first (the
# stick may unmount during the animation window)
for f in /tmp/inventory-active-*.txt; do
    [ -f "$f" ] || continue
    cp "$f" "$D/" 2>/dev/null && echo "recovered $f -> $D/${f##*/}" >>"$D/hwmon-boot.txt"
done
# daemon-debug leg: the captured daemon output (separate from its log)
if [ -f /tmp/cand.out ]; then
    cp /tmp/cand.out "$D/cand-recovered.out" 2>/dev/null \
        && echo "recovered /tmp/cand.out -> $D/cand-recovered.out" >>"$D/hwmon-boot.txt"
fi
for L in /tmp/pairlaunch.log /tmp/bx510-pairdbg.log /tmp/displaylaunch.log \
         /tmp/candlaunch.log; do
    if [ -f "$L" ]; then
        B=$(basename "$L" .log)
        cp "$L" "$D/$B-recovered.log" 2>/dev/null
        echo "recovered $L -> $D/$B-recovered.log" >>"$D/hwmon-boot.txt"
    fi
done
rm -f /tmp/firebird.pair 2>/dev/null
# Kill any previous daemon by SCANNING /proc — no pidof, no killall: neither is
# reliably present on this busybox (pidof missing, proven). A survivor loses
# the bind race with the next trigger's daemon and its remove_modules rmmods
# the module UNDER the winner, after which NOTHING listens (2026-11-05).
killed=""
for pd in /proc/[0-9]*; do
    pc=$(cat "$pd/cmdline" 2>/dev/null)
    case "$pc" in
        *sacd_extract_160*)
            pn=${pd##*/}
            [ "$pn" = "$$" ] && continue
            if kill -9 "$pn" 2>/dev/null; then killed="$killed $pn"; fi ;;
    esac
done
if [ -n "$killed" ]; then
    echo "killed previous daemon(s):$killed" >>"$D/hwmon-boot.txt"
    sleep 2
fi
# hwmon instances accumulate one per trigger (2026-11-04 corpus finding:
# three concurrent writers on one boot) — kill the previous ones
if pidof hwmon.bin >/dev/null 2>&1; then
    echo "killing previous hwmon" >>"$D/hwmon-boot.txt"
    killall hwmon.bin 2>/dev/null
    sleep 1
fi
# Pre-create the hwmon-data dir so the CLI hwmon line's glob EXPANDS
# (nullglob leaves a literal /mnt/sd*/... arg when the dir does not
# exist yet, so stick writes silently fail and only the RAM backup
# carries data — the 2026-11-04 lesson)
mkdir -p "$D/hwmon-data" 2>/dev/null
