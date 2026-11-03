#!/bin/sh
# sacd_hardware.sh — Mac-side orchestration for the on-player (BX510) session.
#
# Everything around the hardware leg, codified: USB build/verification/mode
# flips, listener wait, baseline capture, pair capture, analysis, artifact
# collection, and session verification. Only the physical player steps
# (power, disc, tray) are manual — every subcommand prints exactly what to
# do at its boundary. See evidence/bx510/PLAYER-SESSION-RUNBOOK.md.
#
# Usage: tools/sacd_hardware.sh <command> [args]
#   preflight        verify ISO + both pinned ELFs + client selftest
#   usb-build        DESTRUCTIVE: DISK=/dev/diskN CONFIRM=ERASE — build the
#                    baseline USB (FAT32, original daemon, observer kit,
#                    baseline AutoScript)
#   usb-check        verify the stick's contents (daemon SHA, AutoScript, kit)
#   usb-baseline-mode   write the normal daemon AutoScript line
#   usb-pair-mode       write the trace-launch AutoScript line (PAIR_LSN)
#   usb-original        put the original ELF on the stick
#   usb-candidate       put the release-candidate ELF on the stick
#   wait             block until the daemon listens (HW_HOST:HW_PORT)
#   baseline         run the baseline capture (teed into SESSION_DIR)
#   baseline-retry   retry the capture (fresh out dir + label)
#   pair             run the request-pair ground-truth capture (PAIR_LSN)
#   analyze          validate pair + baseline against the ISO
#   collect          assemble the handoff folder (SESSION_DIR)
#   verify-session   SHA-verify + inventory the collected artifacts
#
# Environment overrides:
#   HW_HOST (10.20.1.236)  HW_PORT (2002)  USB (/Volumes/SONYUSB)
#   PLAYER_MOUNT (/mnt/sda1)  PAIR_LSN (600)
#   SESSION_DIR (~/bx510-session)  HW_ISO (the Firebird rip)
set -eu

EXP="$(cd "$(dirname "$0")/.." && pwd)"
ORIGINAL="$EXP/original/sacd_extract_160"
RELEASE="$EXP/reconstruct/release/sacd_extract_160_release"
OPTICAL="$EXP/emulator-handoff/optical"
HWMON_DIR="${HWMON_DIR:-$(repo)/evidence/bx510/hwmon-payload}"

SHA_ORIG="0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45"
SHA_REL="e91720fbbbd592505bde6630843b0495ff82a93e40c0e427aaa70a081ff9ae22"
ISO_SIZE_EXPECTED=2179497984

HW_HOST="${HW_HOST:-10.20.1.236}"
HW_PORT="${HW_PORT:-2002}"
USB="${USB:-/Volumes/SONYUSB}"
PLAYER_MOUNT="${PLAYER_MOUNT:-/mnt/sda1}"
PAIR_LSN="${PAIR_LSN:-600}"
SESSION_DIR="${SESSION_DIR:-$HOME/bx510-session}"
HW_ISO="${HW_ISO:-/Volumes/1TB - WD/tomita/iso/Firebird/Firebird.iso}"
DISK="${DISK:-}"
CONFIRM="${CONFIRM:-}"

die() { echo "ERROR: $*" >&2; exit 1; }
stamp() { date '+%Y-%m-%d %H:%M:%S'; }

sha_of() { shasum -a 256 "$1" | awk '{print $1}'; }

check_elf() {
    # $1 = path  $2 = expected sha
    [ -f "$1" ] || die "missing ELF: $1"
    got=$(sha_of "$1")
    [ "$got" = "$2" ] || die "SHA mismatch for $1: $got"
    echo "OK  $1 ($2)"
}

auto_baseline() {
    # daemon + the standby watcher: the watcher snapshots process/
    # module/display state to the stick continuously, so the power-press
    # transition (is bdpprog alive in standby? who holds /dev/fb0?) is
    # captured as runtime evidence (docs/ui-graphics-reconstruction.md)
    printf '/bin/sh %s/sacd_extract_160 -S &\n' "$PLAYER_MOUNT"
    printf '/bin/sh %s/hwmon_start.sh &\n' "$PLAYER_MOUNT"
}

auto_pair() {
    printf '/bin/sh %s/optical/trace-launch.sh %s/sacd_extract_160 %s %s/firebird.pair -S\n' \
        "$PLAYER_MOUNT" "$PLAYER_MOUNT" "$PAIR_LSN" "$PLAYER_MOUNT"
}

cmd_preflight() {
    echo "== preflight $(stamp) =="
    [ -f "$HW_ISO" ] || die "ISO not found: $HW_ISO (override with HW_ISO=...)"
    size=$(stat -f %z "$HW_ISO")
    if [ "$size" = "$ISO_SIZE_EXPECTED" ]; then
        echo "OK  ISO $HW_ISO ($size bytes)"
    else
        echo "WARN ISO size $size != expected $ISO_SIZE_EXPECTED — is this Firebird?"
    fi
    check_elf "$ORIGINAL" "$SHA_ORIG"
    check_elf "$RELEASE" "$SHA_REL"
    [ -f "$OPTICAL/media_check.py" ] || die "observer kit missing: $OPTICAL"
    echo "OK  observer kit $OPTICAL"
    (cd "$EXP" && python3 tools/sacd_client.py selftest --out /tmp/sacd-hw-selftest)
    echo
    echo "Preflight clean. Next:"
    echo "  1) make sacd-usb-build DISK=/dev/diskN CONFIRM=ERASE   (blank USB)"
    echo "     - or, if your USB is already built: make sacd-usb-check"
    echo "  2) PLAYER: power off, Firebird in tray, USB in, power on"
    echo "  3) make sacd-hw-wait && make sacd-hw-baseline"
}

cmd_usb_build() {
    echo "== usb-build $(stamp) =="
    case "$DISK" in
        /dev/disk*) ;;
        *) die "refusing: DISK must be a /dev/diskN device (got '${DISK:-empty}'). Find it with: diskutil list external" ;;
    esac
    diskutil info "$DISK" >/dev/null 2>&1 || die "$DISK not found"
    echo "About to ERASE $DISK and rebuild it as the baseline USB."
    diskutil info "$DISK" | sed -n '1,12p'
    if [ "$CONFIRM" != "ERASE" ]; then
        die "not confirmed — re-run with CONFIRM=ERASE after checking the device above is your USB stick"
    fi
    diskutil eraseDisk FAT32 SONYUSB MBRFormat "$DISK"
    i=0
    while [ ! -d "$USB" ] && [ $i -lt 30 ]; do sleep 1; i=$((i+1)); done
    [ -d "$USB" ] || die "USB did not mount at $USB — check the volume name (expected SONYUSB) and pass USB=/Volumes/<name>"
    cp "$ORIGINAL" "$USB/sacd_extract_160"
    cp -R "$OPTICAL" "$USB/optical"
    cp "$HWMON_DIR/hwmon" "$USB/hwmon"
    cp "$HWMON_DIR/hwmon_start.sh" "$USB/hwmon_start.sh"
    auto_baseline > "$USB/AutoScript"
    cmd_usb_check
    echo
    echo "USB built. Next:"
    echo "  PLAYER: power off, Firebird in tray, USB in, power on (~60-90s),"
    echo "  then:  make sacd-hw-wait && make sacd-hw-baseline"
}

cmd_usb_check() {
    echo "== usb-check $(stamp) =="
    [ -d "$USB" ] || die "USB not mounted at $USB (pass USB=/Volumes/<name>)"
    [ -f "$USB/sacd_extract_160" ] || die "no daemon on the stick"
    got=$(sha_of "$USB/sacd_extract_160")
    case "$got" in
        "$SHA_ORIG") echo "OK  daemon = ORIGINAL (0fdcefdb…)" ;;
        "$SHA_REL")  echo "OK  daemon = RELEASE CANDIDATE (e91720fb…)" ;;
        *) die "daemon on stick is NEITHER pinned ELF: $got" ;;
    esac
    [ -f "$USB/optical/trace-launch.sh" ] || die "observer kit missing on stick ($USB/optical)"
    echo "OK  observer kit present"
    [ -f "$USB/hwmon" ] || die "hwmon watcher missing on stick ($USB/hwmon)"
    echo "OK  hwmon watcher present (standby-transition snapshots -> <stick>/hwmon/)"
    echo "AutoScript ($(USB)/AutoScript):"
    sed 's/^/    /' "$USB/AutoScript"
    case "$(cat "$USB/AutoScript")" in
        *trace-launch*) echo "MODE: pair-capture (instrumented)" ;;
        *) echo "MODE: baseline (normal daemon)" ;;
    esac
    [ -f "$USB/firebird.pair" ] && echo "NOTE: firebird.pair already on stick (trace-launch will refuse; make sacd-usb-pair-mode removes it on mode switch)"
}

cmd_usb_mode() { # $1 = baseline|pair
    [ -d "$USB" ] || die "USB not mounted at $USB"
    if [ "$1" = "pair" ]; then
        if [ -f "$USB/firebird.pair" ]; then
            rm "$USB/firebird.pair"
            echo "removed stale $USB/firebird.pair (trace-launch refuses to overwrite)"
        fi
        auto_pair > "$USB/AutoScript"
        echo "AutoScript set to PAIR mode at LSN $PAIR_LSN."
        echo "  PLAYER: power off, (disc in, USB in), power on, then:"
        echo "          make sacd-hw-wait && make sacd-hw-pair"
    else
        auto_baseline > "$USB/AutoScript"
        echo "AutoScript set to BASELINE mode (normal daemon)."
    fi
    sed 's/^/    /' "$USB/AutoScript"
}

cmd_usb_use() { # $1 = path $2 = sha $3 = name
    [ -d "$USB" ] || die "USB not mounted at $USB"
    check_elf "$1" "$2"
    cp "$1" "$USB/sacd_extract_160"
    got=$(sha_of "$USB/sacd_extract_160")
    [ "$got" = "$2" ] || die "post-copy SHA mismatch on stick"
    echo "OK  stick now carries the $3 ($2)"
}

cmd_wait() {
    echo "== waiting for daemon at $HW_HOST:$HW_PORT (power the player on) $(stamp) =="
    until nc -z "$HW_HOST" "$HW_PORT"; do sleep 2; done
    echo "listener UP at $HW_HOST:$HW_PORT"
}

run_capture() { # $1 = outdir $2 = label  (cd EXP; tee console)
    mkdir -p "$SESSION_DIR"
    ( cd "$EXP" && python3 tools/sacd_client.py capture \
        --host "$HW_HOST" --port "$HW_PORT" \
        --out "$1" \
        --firmware "M15.R.0257 (BDP-S5100 family)" \
        --disc-id "Tomita - Firebird" \
        --label "$2" \
        --daemon-sha "$(sha_of "$USB/sacd_extract_160" 2>/dev/null || sha_of "$ORIGINAL")" \
        2>&1 | tee "$SESSION_DIR/$2-capture-console.txt" )
    echo "capture finished at $(stamp); console saved to $SESSION_DIR/$2-capture-console.txt"
}

cmd_baseline() {
    echo "== baseline capture $(stamp) =="
    cmd_wait
    run_capture "$EXP/evidence/bx510-baseline" baseline
    echo
    echo "Next: make sacd-usb-pair-mode LSN=$PAIR_LSN  (then reboot the player)"
    echo "If OPEN returned zero bytes: wait 90s, then make sacd-hw-baseline-retry"
}

cmd_baseline_retry() {
    echo "== baseline retry $(stamp) =="
    run_capture "$EXP/evidence/bx510-baseline-retry" baseline-retry
}

cmd_pair() {
    echo "== pair capture at LSN $PAIR_LSN $(stamp) =="
    cmd_wait
    mkdir -p "$SESSION_DIR"
    ( cd "$EXP" && python3 "$OPTICAL/media_check.py" request-pair \
        --client tools/sacd_client.py --host "$HW_HOST" --lsn "$PAIR_LSN" \
        2>&1 | tee "$SESSION_DIR/request-pair-console.txt" )
    echo "pair request finished at $(stamp)"
    echo "  PLAYER: power off, remove the USB, then:"
    echo "          make sacd-hw-analyze && make sacd-hw-collect"
}

cmd_analyze() {
    echo "== analyze $(stamp) =="
    [ -f "$USB/firebird.pair" ] || die "no firebird.pair on the stick ($USB)"
    ( cd "$EXP" && python3 "$OPTICAL/media_check.py" pair "$USB/firebird.pair" --iso "$HW_ISO" )
    for m in "$EXP"/evidence/bx510-baseline/manifest.json "$EXP"/evidence/bx510-baseline-retry/manifest.json; do
        [ -f "$m" ] || continue
        ( cd "$EXP" && python3 "$OPTICAL/media_check.py" baseline "$m" --iso "$HW_ISO" )
    done
}

cmd_collect() {
    echo "== collect $(stamp) =="
    mkdir -p "$SESSION_DIR"
    [ -f "$USB/firebird.pair" ] && cp "$USB/firebird.pair" "$SESSION_DIR/"
    for d in bx510-baseline bx510-baseline-retry; do
        [ -d "$EXP/evidence/$d" ] && cp -R "$EXP/evidence/$d" "$SESSION_DIR/"
    done
    if [ ! -f "$SESSION_DIR/notes.txt" ]; then
        {
            echo "BX510 hardware session notes"
            echo "collected: $(stamp)"
            echo "player: $HW_HOST  firmware: M15.R.0257  disc: Firebird"
            echo
            echo "- boot time / when daemon came up:"
            echo "- baseline result (OPEN/SIZE/reads):"
            echo "- retry needed? why:"
            echo "- pair capture result / wire hash:"
            echo "- anything on the player screen:"
        } > "$SESSION_DIR/notes.txt"
    fi
    cmd_verify_session
    echo
    echo "Handoff folder ready: $SESSION_DIR"
    echo "Tell the assistant: \"it's in $SESSION_DIR\"."
}

cmd_verify_session() {
    echo "== verify-session $(stamp) =="
    [ -d "$SESSION_DIR" ] || die "no session dir at $SESSION_DIR"
    found=0
    if [ -f "$SESSION_DIR/firebird.pair" ]; then
        echo "pair file: $(stat -f %z "$SESSION_DIR/firebird.pair") bytes, sha $(sha_of "$SESSION_DIR/firebird.pair")"
        found=$((found+1))
    fi
    for m in "$SESSION_DIR"/bx510-baseline*/manifest.json; do
        [ -f "$m" ] || continue
        python3 - "$m" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
print(f"manifest {sys.argv[1]}: label={m.get('label')} frames={len(m.get('frames', []))} size={m.get('disc_size_sectors')}")
PY
        found=$((found+1))
    done
    for f in baseline-capture-console.txt baseline-retry-capture-console.txt \
             request-pair-console.txt notes.txt; do
        [ -f "$SESSION_DIR/$f" ] && echo "console/notes: $f present"
    done
    [ "$found" -gt 0 ] || die "no artifacts found in $SESSION_DIR — did the captures run?"
    echo "verification done: $found artifact set(s) present"
}

case "${1:-}" in
    preflight)       cmd_preflight ;;
    usb-build)       cmd_usb_build ;;
    usb-check)       cmd_usb_check ;;
    usb-baseline-mode) cmd_usb_mode baseline ;;
    usb-pair-mode)   cmd_usb_mode pair ;;
    usb-original)     cmd_usb_use "$ORIGINAL" "$SHA_ORIG" "ORIGINAL" ;;
    usb-candidate)    cmd_usb_use "$RELEASE" "$SHA_REL" "RELEASE CANDIDATE" ;;
    wait)            cmd_wait ;;
    baseline)        cmd_baseline ;;
    baseline-retry)  cmd_baseline_retry ;;
    pair)            cmd_pair ;;
    analyze)         cmd_analyze ;;
    collect)         cmd_collect ;;
    verify-session)  cmd_verify_session ;;
    *) die "unknown command '${1:-}'; see header of $0" ;;
esac
