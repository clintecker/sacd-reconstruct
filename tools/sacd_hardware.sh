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
#   usb-check        verify the stick's contents (daemon SHA, AutoScript, kit,
#                    hwmon watcher, Phase-0 inventory collector)
#   usb-baseline-mode   write the normal daemon AutoScript line (also
#                    restores the SILENT pair observer to the stick)
#   usb-pair-mode       write the pairlaunch AutoScript line (PAIR_LSN) and
#                    stage the DEBUG pair observer (bx510_pair_dbg.so) as
#                    the stick's optical/bx510_pair.so for the session
#   usb-display-mode    write the DISPLAY AutoScript line (cyberdraw --anim on
#                    /dev/fb0 via displaylaunch.sh; DISPLAY_ANIM seconds,
#                    default 45) — the TV photo/video leg
#   usb-original        put the original ELF on the stick
#   usb-candidate       put the release-candidate ELF on the stick
#   candidate        run the candidate capture (out dir evidence/bx510-candidate
#                    so the original-binary baselines are never overwritten;
#                    retry with CAND_OUT=... CAND_LABEL=candidate-retry)
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
#   PLAYER_MOUNT (/mnt/sda1)  PAIR_LSN (600)  DISPLAY_ANIM (45)
#   SESSION_DIR (~/bx510-session)  HW_ISO (the Firebird rip)
set -eu

EXP="$(cd "$(dirname "$0")/.." && pwd)"
ORIGINAL="$EXP/original/sacd_extract_160"
RELEASE="$EXP/reconstruct/release/sacd_extract_160_release"
OPTICAL="$EXP/emulator-handoff/optical"
HWMON_DIR="${HWMON_DIR:-$EXP/evidence/bx510/hwmon-payload}"
DISPLAY_DIR="${DISPLAY_DIR:-$EXP/evidence/bx510/display-payload}"

SHA_ORIG="0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45"
SHA_REL="e91720fbbbd592505bde6630843b0495ff82a93e40c0e427aaa70a081ff9ae22"
# pair observers: SILENT = the prebuilt optical/bx510_pair.so staged on the
# 2026-11-04 stick; DBG = bx510_pair_dbg.so (QEMU-proven debug build,
# evidence/bx510-guest/pair-observer/) staged AS optical/bx510_pair.so for
# the pair-retry session — the substitution is name-only (trace-launch.sh
# copies $here/bx510_pair.so)
SHA_PAIR_SILENT="cabe9f4f9d1e0194fd2627d29c456d1959881f251267a5882d45a881b364abf2"
SHA_PAIR_DBG="e23c482ddcad4e62945af3cb722a1609479e70e58f89dffc6d37ee36a2e4938c"
DBG_SO="$EXP/evidence/bx510-guest/pair-observer/bx510_pair_dbg.so"
# display payload: cyberdraw (ARM, built from tools/bx510_cyberdraw.c with
# the gnuarm toolchain — recipe + source SHA in DISPLAY-SPEC.md)
SHA_CYBER="17d0c2cb7ba7fd4ae43fa499124d099a7ec4b42c1ac7290d2f6cbcf0856fde13"
ISO_SIZE_EXPECTED=2179497984

HW_HOST="${HW_HOST:-10.20.1.236}"
HW_PORT="${HW_PORT:-2002}"
USB="${USB:-/Volumes/SONYUSB}"
PLAYER_MOUNT="${PLAYER_MOUNT:-/mnt/sda1}"
PAIR_LSN="${PAIR_LSN:-600}"
DISPLAY_ANIM="${DISPLAY_ANIM:-}"
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

# --- MTK CLI AutoScript format (saramibreak/SacdImageCreator, proven on
# BDP-S5100/BX510; scene guides): AutoScript is a DIRECTORY on the stick
# root containing the ASCII CLI script named "AutoScript", the daemon,
# hwmon, hwmon_restore.sh. The player's launcher parses "#MTKAT" CLI
# lines — plain shell text never executes (tonight's failure, evidenced:
# empty hwmon/, daemon never bound). The daemon is copied to / (RAM) and
# run from there — the stick can be removed once serving (scene recipe).
cli_head() {
    # IR squelch lines REMOVED (learning from the 2026-11-04 session: after
    # a script with CLI_drv.ir.rx.sq ran, the appliance UI wedged in an
    # OFF-flash loop with an unresponsive power button — leading hypothesis
    # is persistent IR suppression; the operator's original proven 2-line
    # script had no squelch lines. Hypothesis-driven removal, labeled.)
    printf '#MTKAT 0.xx script\n'
    printf 'CLI(CLI_drv.sacd.tray 1)\n'
    printf 'CLI(CLI_exec sleep 10s)\n'
    printf 'CLI(CLI_drv.sacd.tray 0)\n'
    printf 'CLI(CLI_exec /bin/sh /mnt/sd*/AutoScript/hwmon_restore.sh)\n'
    printf 'CLI(CLI_exec cp /mnt/sd*/AutoScript/sacd_extract_160 /sacd_extract_160)\n'
    printf 'CLI(CLI_exec cp /mnt/sd*/AutoScript/hwmon /tmp/hwmon.bin)\n'
    printf 'CLI(CLI_exec chmod 755 /sacd_extract_160 /tmp/hwmon.bin)\n'
}
cli_tail() {
    # hwmon: primary snapshots to the stick, RAM backup to /tmp/hwmon
    # (the stick may unmount at sleep; hwmon_restore recovers the backup)
    printf 'CLI(CLI_exec /tmp/hwmon.bin /mnt/sd*/AutoScript/hwmon-data /tmp/hwmon-data &)\n'
}
auto_baseline() {
    cli_head
    printf 'CLI(CLI_exec /sacd_extract_160 -S &)\n'
    cli_tail
}
auto_pair() {
    cli_head
    # the trace-launch line was the longest in the script and the daemon
    # never came up (suspected CLI_exec command-length/parse limits —
    # the parser dump warns of bounded command handling). Everything
    # complex now lives in pairlaunch.sh (full shell, full logging);
    # the CLI lines below mirror the proven baseline shapes.
    printf 'CLI(CLI_exec cp /mnt/sd*/AutoScript/pairlaunch.sh /tmp/pairlaunch.sh)\n'
    printf 'CLI(CLI_exec /bin/sh /tmp/pairlaunch.sh &)\n'
    # no cli_tail: pairlaunch.sh starts hwmon with RESOLVED paths (the
    # CLI-line glob arg was observed left literal by nullglob)
}
auto_display() {
    cli_head
    # Same proven shape as auto_pair: copy the wrapper + the tool to RAM with
    # SHORT lines, then run the wrapper (which logs to stick + RAM and starts
    # its own hwmon-backed state dumps). The anim length comes from the
    # displayanim file on the stick (an env assignment on a CLI line is not
    # proven to survive CLI_exec).
    # line lengths kept at/under the PROVEN pair line (69 chars): the CLI
    # parser has practical length limits (the long trace-launch line never
    # ran). The RAM copy is /tmp/dl.sh for exactly that reason.
    printf 'CLI(CLI_exec cp /mnt/sd*/AutoScript/displaylaunch.sh /tmp/dl.sh)\n'
    printf 'CLI(CLI_exec cp /mnt/sd*/AutoScript/cyberdraw /tmp/cyberdraw)\n'
    printf 'CLI(CLI_exec chmod 755 /tmp/dl.sh /tmp/cyberdraw)\n'
    printf 'CLI(CLI_exec /bin/sh /tmp/dl.sh &)\n'
    cli_tail
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
    check_elf "$DBG_SO" "$SHA_PAIR_DBG"
    check_elf "$DISPLAY_DIR/cyberdraw" "$SHA_CYBER"
    [ -f "$DISPLAY_DIR/displaylaunch.sh" ] || die "display payload missing: $DISPLAY_DIR/displaylaunch.sh"
    echo "OK  display payload $DISPLAY_DIR (cyberdraw + displaylaunch.sh)"
    [ -f "$OPTICAL/media_check.py" ] || die "observer kit missing: $OPTICAL"
    echo "OK  observer kit $OPTICAL"
    (cd "$EXP" && python3 tools/sacd_client.py selftest --out /tmp/sacd-hw-selftest)
    echo
    echo "Preflight clean. Next:"
    echo "  1) make sacd-usb-build DISK=/dev/diskN CONFIRM=ERASE   (blank USB)"
    echo "     - or, if your USB is already built: make sacd-usb-check"
    echo "  2) PLAYER: power ON, Firebird in tray, player idle, insert the USB ->"
    echo "     tray opens BY ITSELF (= AutoScript firing)"
    echo "  3) make sacd-hw-wait && make sacd-hw-baseline"
    echo
    echo "Session legs (PLAYER-SESSION-RUNBOOK.md): candidate trial -> standby"
    echo "capture -> pair retry (DEBUG observer) -> DISPLAY leg LAST"
    echo "  (make sacd-usb-display-mode; TV photo/video is the evidence)."
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
    mkdir -p "$USB/AutoScript"
    cp "$ORIGINAL" "$USB/AutoScript/sacd_extract_160"
    cp -R "$OPTICAL" "$USB/optical"
    cp "$HWMON_DIR/hwmon" "$USB/AutoScript/hwmon"
    cp "$HWMON_DIR/inventory" "$USB/AutoScript/inventory"
    cp "$HWMON_DIR/hwmon_restore.sh" "$USB/AutoScript/hwmon_restore.sh"
    cp "$HWMON_DIR/pairlaunch.sh" "$USB/AutoScript/pairlaunch.sh"
    cp "$DISPLAY_DIR/displaylaunch.sh" "$USB/AutoScript/displaylaunch.sh"
    cp "$DISPLAY_DIR/cyberdraw" "$USB/AutoScript/cyberdraw"
    auto_baseline > "$USB/AutoScript/AutoScript"
    cmd_usb_check
    echo
    echo "USB built (MTK CLI format). Next (sleep-trigger protocol):"
    echo "  PLAYER: check Quick Start Mode is ON; player ON, disc in tray,"
    echo "  insert USB -> tray opens BY ITSELF (= AutoScript firing),"
    echo "  power OFF -> sleep -> then: make sacd-hw-wait && make sacd-hw-baseline"
}

cmd_usb_check() {
    echo "== usb-check $(stamp) =="
    [ -d "$USB" ] || die "USB not mounted at $USB (pass USB=/Volumes/<name>)"
    [ -d "$USB/AutoScript" ] || die "no AutoScript DIRECTORY on the stick (the MTK launcher requires AutoScript/ with the CLI script inside)"
    [ -f "$USB/AutoScript/AutoScript" ] || die "no CLI script at AutoScript/AutoScript"
    head -1 "$USB/AutoScript/AutoScript" | grep -q "#MTKAT" || die "AutoScript/AutoScript is not an MTK CLI script (missing '#MTKAT 0.xx script' header)"
    [ -f "$USB/AutoScript/sacd_extract_160" ] || die "no daemon at AutoScript/sacd_extract_160"
    got=$(sha_of "$USB/AutoScript/sacd_extract_160")
    case "$got" in
        "$SHA_ORIG") echo "OK  daemon = ORIGINAL (0fdcefdb…)" ;;
        "$SHA_REL")  echo "OK  daemon = RELEASE CANDIDATE (e91720fb…)" ;;
        *) die "daemon on stick is NEITHER pinned ELF: $got" ;;
    esac
    [ -f "$USB/optical/trace-launch.sh" ] || die "observer kit missing on stick ($USB/optical)"
    echo "OK  observer kit present"
    [ -f "$USB/optical/bx510_pair.so" ] || die "pair observer missing on stick ($USB/optical/bx510_pair.so)"
    got=$(sha_of "$USB/optical/bx510_pair.so")
    case "$got" in
        "$SHA_PAIR_SILENT") echo "OK  pair observer = SILENT build (optical/bx510_pair.so, cabe9f4f…)" ;;
        "$SHA_PAIR_DBG") echo "OK  pair observer = DEBUG build (bx510_pair_dbg.so staged AS optical/bx510_pair.so; pairlaunch.sh sets BX510_PAIR_LOG=/tmp/bx510-pairdbg.log)" ;;
        *) die "pair observer on stick is NEITHER pinned build: $got" ;;
    esac
    [ -f "$USB/AutoScript/hwmon" ] || die "hwmon watcher missing on stick ($USB/AutoScript/hwmon)"
    [ -f "$USB/AutoScript/hwmon_restore.sh" ] || die "hwmon_restore.sh missing on stick"
    [ -f "$USB/AutoScript/pairlaunch.sh" ] || die "pairlaunch.sh missing on stick"
    echo "OK  hwmon watcher + restore + pairlaunch present"
    # display payload (TV photo/video leg): cyberdraw must be the PINNED ARM
    # build — a stale or foreign binary would silently test nothing. A stick
    # built before this payload only WARNS unless the session IS display mode
    # (a pre-payload stick must stay usable for baseline/pair/candidate legs).
    case "$(cat "$USB/AutoScript/AutoScript")" in
        *displaylaunch*) DISPLAY_MODE=1 ;;
        *) DISPLAY_MODE=0 ;;
    esac
    dlgot=""
    [ -f "$USB/AutoScript/cyberdraw" ] && dlgot=$(sha_of "$USB/AutoScript/cyberdraw")
    if [ ! -f "$USB/AutoScript/displaylaunch.sh" ] || [ "$dlgot" != "$SHA_CYBER" ]; then
        if [ "$DISPLAY_MODE" = 1 ]; then
            die "display payload wrong/missing on a DISPLAY-mode stick (displaylaunch.sh present? cyberdraw sha=${dlgot:-none}, expected $SHA_CYBER) — re-run make sacd-usb-display-mode"
        fi
        echo "WARN display payload absent/stale on stick (cyberdraw sha=${dlgot:-none})"
        echo "     — fine for baseline/pair legs; make sacd-usb-display-mode stages it"
    else
        echo "OK  cyberdraw = pinned ARM build (17d0c2cb…)"
        if [ -f "$USB/AutoScript/displayanim" ]; then
            echo "OK  displayanim override present: $(cat "$USB/AutoScript/displayanim") s"
        else
            echo "OK  displayanim not set (displaylaunch.sh default 45 s)"
        fi
    fi
    # Phase-0 runtime inventory (plan §4 remainder): static ARM collector,
    # launched once per boot by hwmon_restore.sh
    [ -f "$USB/AutoScript/inventory" ] || die "inventory collector missing on stick ($USB/AutoScript/inventory — staged from $HWMON_DIR/inventory)"
    case "$(file "$USB/AutoScript/inventory" 2>/dev/null)" in
        *"ELF 32-bit"*ARM*) echo "OK  inventory collector present (ARM)" ;;
        *) echo "WARN inventory collector is not an ARM ELF — expected the static arm-none-linux-gnueabi build" ;;
    esac
    for f in pairlaunch.sh hwmon_restore.sh inventory; do
        if [ -f "$HWMON_DIR/$f" ] && ! cmp -s "$HWMON_DIR/$f" "$USB/AutoScript/$f"; then
            echo "WARN $f on stick differs from the repo copy — a mode flip"
            echo "     (sacd-usb-baseline-mode / sacd-usb-pair-mode / sacd-usb-display-mode)"
            echo "     refreshes it"
        fi
    done
    if [ -f "$DISPLAY_DIR/displaylaunch.sh" ] && [ -f "$USB/AutoScript/displaylaunch.sh" ] \
       && ! cmp -s "$DISPLAY_DIR/displaylaunch.sh" "$USB/AutoScript/displaylaunch.sh"; then
        echo "WARN displaylaunch.sh on stick differs from the repo copy —"
        echo "     make sacd-usb-display-mode refreshes it"
    fi
    echo "AutoScript (${USB}/AutoScript/AutoScript):"
    sed 's/^/    /' "$USB/AutoScript/AutoScript"
    case "$(cat "$USB/AutoScript/AutoScript")" in
        *pairlaunch*) echo "MODE: pair-capture (instrumented via pairlaunch.sh wrapper)" ;;
        *displaylaunch*) echo "MODE: display (cyberdraw on /dev/fb0 via displaylaunch.sh wrapper)" ;;
        *) echo "MODE: baseline (normal daemon)" ;;
    esac
    if [ -f "$USB/AutoScript/firebird.pair" ]; then
        echo "NOTE: stale firebird.pair already at AutoScript/firebird.pair (trace-launch refuses to overwrite; make sacd-usb-pair-mode removes it on mode switch)"
    fi
}

cmd_usb_mode() { # $1 = baseline|pair
    [ -d "$USB" ] || die "USB not mounted at $USB"
    # refresh the payload scripts so the stick always carries the current
    # pairlaunch/hwmon_restore (the debug-observer log wiring lives in them)
    cp "$HWMON_DIR/pairlaunch.sh" "$USB/AutoScript/pairlaunch.sh"
    cp "$HWMON_DIR/hwmon_restore.sh" "$USB/AutoScript/hwmon_restore.sh"
    # keep the Phase-0 inventory collector current too (hwmon_restore now
    # runs it once per boot)
    if [ -f "$HWMON_DIR/inventory" ]; then
        cp "$HWMON_DIR/inventory" "$USB/AutoScript/inventory"
        echo "refreshed AutoScript/inventory (Phase-0 collector)"
    fi
    echo "refreshed AutoScript/pairlaunch.sh + hwmon_restore.sh from the repo"
    # display payload rides every mode flip too (canonical stick)
    if [ -f "$DISPLAY_DIR/displaylaunch.sh" ] && [ -f "$DISPLAY_DIR/cyberdraw" ]; then
        cp "$DISPLAY_DIR/displaylaunch.sh" "$USB/AutoScript/displaylaunch.sh"
        cp "$DISPLAY_DIR/cyberdraw" "$USB/AutoScript/cyberdraw"
        echo "refreshed AutoScript/displaylaunch.sh + cyberdraw (display payload)"
    fi
    if [ "$1" = "pair" ]; then
        if [ -f "$USB/AutoScript/firebird.pair" ]; then
            rm "$USB/AutoScript/firebird.pair"
            echo "removed stale firebird.pair (trace-launch refuses to overwrite)"
        fi
        auto_pair > "$USB/AutoScript/AutoScript"
        # Session pair-retry: stage the DEBUG observer (bx510_pair_dbg.so,
        # QEMU-proven; makes every silent arming/load failure speak) AS the
        # stick's optical/bx510_pair.so — trace-launch.sh copies
        # $here/bx510_pair.so, so the debug build rides the proven path
        # under the proven name. pairlaunch.sh exports
        # BX510_PAIR_LOG=/tmp/bx510-pairdbg.log; hwmon_restore.sh recovers
        # that log to the stick at the next trigger.
        [ -d "$USB/optical" ] || die "observer kit missing on stick ($USB/optical)"
        check_elf "$DBG_SO" "$SHA_PAIR_DBG"
        cp "$DBG_SO" "$USB/optical/bx510_pair.so"
        echo "AutoScript set to PAIR mode at LSN $PAIR_LSN."
        echo "DEBUG observer staged: stick optical/bx510_pair.so = bx510_pair_dbg.so"
        echo "  ($SHA_PAIR_DBG) — name-only substitution; it logs the arming"
        echo "  decision + every READ/DECRYPT + the save outcome."
        echo "  PLAYER: pull the stick, reinsert while idle -> tray opens BY"
        echo "          ITSELF (= trigger), then: make sacd-hw-wait && make sacd-hw-pair"
    elif [ "$1" = "display" ]; then
        # the TV photo/video leg: our pixels on the real panel (or a named cause)
        [ -f "$DISPLAY_DIR/cyberdraw" ] || die "display payload missing: $DISPLAY_DIR/cyberdraw"
        check_elf "$DISPLAY_DIR/cyberdraw" "$SHA_CYBER"
        cp "$DISPLAY_DIR/cyberdraw" "$USB/AutoScript/cyberdraw"
        cp "$DISPLAY_DIR/displaylaunch.sh" "$USB/AutoScript/displaylaunch.sh"
        if [ -n "$DISPLAY_ANIM" ]; then
            case "$DISPLAY_ANIM" in
                *[!0-9]*|'') die "DISPLAY_ANIM must be a whole number of seconds (got '$DISPLAY_ANIM')" ;;
            esac
            if [ "$DISPLAY_ANIM" -lt 1 ] || [ "$DISPLAY_ANIM" -gt 100 ]; then
                die "DISPLAY_ANIM must be 1..100 s (cyberdraw caps at 100; got $DISPLAY_ANIM)"
            fi
            printf '%s\n' "$DISPLAY_ANIM" > "$USB/AutoScript/displayanim"
            echo "displayanim override written: ${DISPLAY_ANIM}s"
        else
            rm -f "$USB/AutoScript/displayanim"
            echo "displayanim cleared (displaylaunch.sh default 45s)"
        fi
        auto_display > "$USB/AutoScript/AutoScript"
        ANS=$([ -n "$DISPLAY_ANIM" ] && echo "$DISPLAY_ANIM" || echo 45)
        echo "AutoScript set to DISPLAY mode (cyberdraw on /dev/fb0, ${ANS}s anim)."
        echo "  PLAYER: pull the stick, reinsert while idle -> tray opens BY ITSELF"
        echo "          (= trigger). PHONE READY BEFORE INSERTING: record video and"
        echo "          take a photo of the TV during the ${ANS}s window — the scene is a"
        echo "          green phosphor console + wireframe cube, unmistakeable."
        echo "  THEN (standby pass): power press ONCE -> note whether the picture"
        echo "          survives / the screen blanks -> power press again (wake) ->"
        echo "          note instant vs slow wake. Write times in notes.txt."
        echo "  THEN: pull the stick, reinsert once more (recover trigger) -> power"
        echo "          off, pull stick -> make sacd-hw-collect"
    else
        auto_baseline > "$USB/AutoScript/AutoScript"
        # restore the SILENT observer so a baseline flip leaves a canonical stick
        if [ -f "$USB/optical/bx510_pair.so" ]; then
            cp "$OPTICAL/bx510_pair.so" "$USB/optical/bx510_pair.so"
            echo "pair observer restored to SILENT build (canonical)."
        fi
        rm -f "$USB/AutoScript/displayanim"
        echo "AutoScript set to BASELINE mode (normal daemon)."
    fi
    sed 's/^/    /' "$USB/AutoScript/AutoScript"
}

cmd_usb_use() { # $1 = path $2 = sha $3 = name — stages into AutoScript/, the
    # ONLY path the MTK CLI launcher reads (it copies
    # /mnt/sd*/AutoScript/sacd_extract_160 into RAM and runs it from /)
    [ -d "$USB" ] || die "USB not mounted at $USB"
    [ -d "$USB/AutoScript" ] || die "no AutoScript/ dir on the stick — run make sacd-usb-build first"
    check_elf "$1" "$2"
    cp "$1" "$USB/AutoScript/sacd_extract_160"
    got=$(sha_of "$USB/AutoScript/sacd_extract_160")
    [ "$got" = "$2" ] || die "post-copy SHA mismatch on stick"
    echo "OK  stick AutoScript/sacd_extract_160 is now the $3 ($2)"
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
        --daemon-sha "$(sha_of "$USB/AutoScript/sacd_extract_160" 2>/dev/null || sha_of "$ORIGINAL")" \
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

cmd_candidate() {
    # The candidate trial: same capture flow as baseline, but its own out dir
    # and label so the original-binary baselines (evidence/bx510-baseline*) —
    # the comparison reference — are never overwritten. No make target yet;
    # run: sh tools/sacd_hardware.sh candidate   (retry: CAND_OUT/CAND_LABEL)
    echo "== candidate capture $(stamp) =="
    cmd_wait
    run_capture "${CAND_OUT:-$EXP/evidence/bx510-candidate}" "${CAND_LABEL:-candidate}"
    echo
    echo "Candidate capture done. Expected (the ORIGINAL-binary values,"
    echo "which the candidate must match exactly):"
    echo "  OPEN=0  SIZE=1064208  lsn0-1 e5a00aa9991ac8a5  lsn0-128 a28db88d35dbf586"
    echo "  lsn 532104 72e971d9ca072881  beyond-EOF refused  reconnect clean"
    echo "If OPEN returned zero bytes: wait 90s, retry with"
    echo "  CAND_OUT=$EXP/evidence/bx510-candidate-retry CAND_LABEL=candidate-retry \\"
    echo "  sh tools/sacd_hardware.sh candidate"
}

cmd_pair() {
    echo "== pair capture at LSN $PAIR_LSN $(stamp) =="
    cmd_wait
    mkdir -p "$SESSION_DIR"
    ( cd "$EXP" && python3 "$OPTICAL/media_check.py" request-pair \
        --client tools/sacd_client.py --host "$HW_HOST" --lsn "$PAIR_LSN" \
        2>&1 | tee "$SESSION_DIR/request-pair-console.txt" )
    echo "pair request finished at $(stamp)"
    echo "  Pair file + debug log are in PLAYER RAM (/tmp) right now. To land them"
    echo "  on the stick: PLAYER pull the stick, reinsert while idle -> tray opens"
    echo "  BY ITSELF (= trigger; hwmon_restore copies them to the stick), power"
    echo "  off, pull the stick, then: make sacd-hw-analyze && make sacd-hw-collect"
}

cmd_analyze() {
    echo "== analyze $(stamp) =="
    PAIR="$USB/AutoScript/firebird.pair"   # hwmon_restore recovers it here
    [ -f "$PAIR" ] || PAIR="$USB/firebird.pair"
    [ -f "$PAIR" ] || die "no firebird.pair on the stick (looked in AutoScript/ and stick root)"
    ( cd "$EXP" && python3 "$OPTICAL/media_check.py" pair "$PAIR" --iso "$HW_ISO" )
    for m in "$EXP"/evidence/bx510-baseline/manifest.json \
             "$EXP"/evidence/bx510-baseline-retry/manifest.json \
             "$EXP"/evidence/bx510-candidate/manifest.json \
             "$EXP"/evidence/bx510-candidate-retry/manifest.json; do
        [ -f "$m" ] || continue
        ( cd "$EXP" && python3 "$OPTICAL/media_check.py" baseline "$m" --iso "$HW_ISO" )
    done
}

cmd_collect() {
    echo "== collect $(stamp) =="
    mkdir -p "$SESSION_DIR"
    if [ -f "$USB/AutoScript/firebird.pair" ]; then cp "$USB/AutoScript/firebird.pair" "$SESSION_DIR/"; fi
    # Phase-0 runtime inventories (one per boot; see INVENTORY-SPEC.md) and
    # the display leg's active-display samples (inventory-active-*)
    for f in "$USB"/AutoScript/inventory-*.txt; do
        [ -f "$f" ] && cp "$f" "$SESSION_DIR/"
    done
    # display leg: launcher log (live-on-stick) + the next-trigger recovery copy
    for f in "$USB"/AutoScript/displaylaunch.log \
             "$USB"/AutoScript/displaylaunch-recovered.log; do
        [ -f "$f" ] && cp "$f" "$SESSION_DIR/"
    done
    for d in bx510-baseline bx510-baseline-retry bx510-candidate bx510-candidate-retry; do
        if [ -d "$EXP/evidence/$d" ]; then cp -R "$EXP/evidence/$d" "$SESSION_DIR/"; fi
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
            echo "- DISPLAY leg: photo/video file name (copied into this folder),"
            echo "  and what the TV showed (scene / black / appliance UI / garble)"
            echo "- DISPLAY leg standby pass: picture during standby (survived/blanked),"
            echo "  wake behaviour (instant/slow) + timestamps"
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
        if [ -f "$SESSION_DIR/$f" ]; then echo "console/notes: $f present"; fi
    done
    if ls "$SESSION_DIR"/displaylaunch*.log >/dev/null 2>&1; then
        grep -h "CYBERDRAW: full-frame md5\|cyberdraw: open\|unsupported bpp\|anim exit" \
             "$SESSION_DIR"/displaylaunch*.log 2>/dev/null | head -n 6
    fi
    for f in "$SESSION_DIR"/inventory*.txt; do
        [ -f "$f" ] && echo "inventory: ${f##*/}"
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
    usb-display-mode) cmd_usb_mode display ;;
    usb-original)     cmd_usb_use "$ORIGINAL" "$SHA_ORIG" "ORIGINAL" ;;
    usb-candidate)    cmd_usb_use "$RELEASE" "$SHA_REL" "RELEASE CANDIDATE" ;;
    wait)            cmd_wait ;;
    baseline)        cmd_baseline ;;
    baseline-retry)  cmd_baseline_retry ;;
    candidate)       cmd_candidate ;;
    pair)            cmd_pair ;;
    analyze)         cmd_analyze ;;
    collect)         cmd_collect ;;
    verify-session)  cmd_verify_session ;;
    *) die "unknown command '${1:-}'; see header of $0" ;;
esac
