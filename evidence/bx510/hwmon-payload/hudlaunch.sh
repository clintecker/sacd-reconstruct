#!/bin/sh
# hudlaunch.sh — the single owner of the display leg: preload module, start the
# daemon (stdout captured), wait for the listener, then run the HUD.
#
# Why a supervisor (2026-11-05, hardware): the player fires the MTK AutoScript
# MORE THAN ONCE per insertion (5 triggers observed on one boot). With each
# trigger starting its own daemon+HUD and killing the previous ones, every
# second trigger killed the daemon it had just started 2 s earlier (candlaunch
# "exit status 137" = SIGKILL) and left two HUDs alternating on the panel.
# Now hwmon_restore kills hudlaunch (and its children) and starts exactly one;
# the last trigger wins and nothing fights over the panel or port 2002.
#
# busybox-safe: cat/ls/head/sleep/kill + builtins only (no pidof/killall/grep).
D=$(ls -d /mnt/sd*/AutoScript 2>/dev/null | head -n 1)
[ -n "$HUDLAUNCH_D" ] && D="$HUDLAUNCH_D"      # test hook
[ -n "$D" ] || D=/tmp
export D
L1="$D/hudlaunch.log"
log() { printf '%s\n' "$@" | while IFS= read -r l; do printf '%s\n' "$l" >>"$L1" 2>/dev/null; done; }
utime() { u=""; read -r u _ < /proc/uptime 2>/dev/null; printf '%s' "${u%%.*}"; }

printf '%s\n' "$$" >/tmp/hudlaunch.pid
log "=== hudlaunch (uptime $(utime)) pid $$ ==="
log "stick dir: $D"

# --- module preload on a free CPSA compid (the daemon hardcodes compid 0,
#     which the appliance owns -> insmod -EBUSY -> "Can not install modules") ---
case "$(cat /proc/modules 2>/dev/null)" in
    *sacd_read*) log "module already loaded" ;;
    *)
        for c in 0 1 2 3; do
            if insmod "$D/sacd_read.ko" compid=$c minor=201 2>/dev/null; then
                log "preloaded sacd_read.ko compid=$c"
                break
            fi
        done ;;
esac

# --- daemon (stdout captured: this is the HUD ticker's source) ---
if [ ! -x /sacd_extract_160 ]; then
    cp "$D/sacd_extract_160" /sacd_extract_160 2>/dev/null
    chmod 755 /sacd_extract_160 2>/dev/null
    log "daemon copied to /sacd_extract_160"
fi
[ -x /sacd_extract_160 ] || log "FATAL: no /sacd_extract_160"
cp "$D/optical/bx510_pair_dbg.so" /tmp/pairdbg.so 2>/dev/null
# Sony's own screen font (carved from /res/font.bin) for the HUD text
cp "$D/sony-font.ttf" /tmp/sony-font.ttf 2>/dev/null && log "font: /tmp/sony-font.ttf installed"
: >/tmp/cand.out

start_daemon() {
    if [ -f "$D/hudevents" ] && [ -f /tmp/pairdbg.so ]; then
        LD_PRELOAD=/tmp/pairdbg.so
        BX510_PAIR_LOG=/tmp/hud-events.log
        BX510_PAIR_OUT=/tmp/hud-pair.bin
        BX510_PAIR_LSN=600
        export LD_PRELOAD BX510_PAIR_LOG BX510_PAIR_OUT BX510_PAIR_LSN
        /sacd_extract_160 -S >>/tmp/cand.out 2>&1 &
        DPID=$!
        unset LD_PRELOAD
        log "daemon started pid $DPID under the observer"
    else
        /sacd_extract_160 -S >>/tmp/cand.out 2>&1 &
        DPID=$!
        log "daemon started pid $DPID"
    fi
}

listening() {
    case "$(cat /proc/net/tcp 2>/dev/null)" in
        *07D2*0A*) return 0 ;;
    esac
    return 1
}

if listening; then
    log "daemon already listening — attaching"
    DPID=0
else
    start_daemon
fi
# let it bind before the HUD attaches (short: the HUD is a pure observer)
i=0
while [ "$i" -lt 20 ]; do
    listening && { log "listener up after ${i}s"; break; }
    [ "$DPID" = "0" ] || kill -0 "$DPID" 2>/dev/null || { wait "$DPID" 2>/dev/null; log "daemon EXITED rc=$? after ${i}s"; break; }
    sleep 1
    i=$((i + 1))
done

# --- the HUD, plus the watchdog that keeps the leg alive ---
cp "$D/sacd_hud" /tmp/sacd_hud 2>/dev/null
chmod 755 /tmp/sacd_hud 2>/dev/null
/tmp/sacd_hud "${HUD_SECS:-1800}" /tmp/cand.out >>"$L1" 2>&1 &
HPID=$!
printf '%s\n' "$HPID" >/tmp/sacd_hud.pid
log "HUD started pid $HPID (watchdog active)"

WD=0
while kill -0 "$HPID" 2>/dev/null; do
    sleep 5
    WD=$((WD + 5))
    # the player fires AutoScript repeatedly; a later trigger's kill loop takes
    # the daemon out (2026-11-05: listener gone, panel still drawing). Restart it.
    if ! listening; then
        if [ "$DPID" = "0" ] || ! kill -0 "$DPID" 2>/dev/null; then
            log "watchdog: no listener at ${WD}s — starting a daemon"
            [ -s /tmp/cand.out ] && log "  daemon output: $(tail -n 3 /tmp/cand.out 2>/dev/null)"
            start_daemon
        fi
    fi
    case "$WD" in
        30|300|900) log "watchdog ${WD}s: listener=$(listening && echo up || echo down) daemon=$(kill -0 "$DPID" 2>/dev/null && echo alive || echo dead)" ;;
    esac
done
wait "$HPID" 2>/dev/null
log "HUD exited rc=$? (watchdog ran ${WD}s)"
log "=== hudlaunch end (uptime $(utime)) ==="
