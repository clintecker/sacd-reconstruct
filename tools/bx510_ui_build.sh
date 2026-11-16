#!/bin/sh
# bx510_ui_build.sh — stage + era-build the UI kit on the build host, repack the
# daemon payload tgz with it, and gate the fe_test_data staging budget.
#
# `make bx510-ui-build` is the first third of the iterate loop; the VM-side
# half is tools/bx510_ui_build_vm.sh (staged to /tmp and run over ssh — the
# bx510_stub_build.sh split, because a build this size must not live in an
# ssh one-liner: nested quotes broke vm-exec three times in one session).
#
# The budget gate is deliberately not arithmetic done here: it runs
# `bx510-fire.sh DRYRUN=1`, i.e. the probe builds the payload it WOULD stage
# and prints `payload: N B of 1048576 B (M B free)`. One spelling of the
# staging arithmetic, and it fails before an expensive boot rather than during
# one (daemon-wiring.md §4.2 is the history: the daemon stage was 98,304 B over
# and "drop a module" could not rescue it).
#
# Usage: UI_SRC=tools/sacd_ui.c sh tools/bx510_ui_build.sh
set -eu

REPO=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO"

UI_SRC=${UI_SRC:-tools/sacd_ui.c}
FONT=${FONT:-evidence/bx510/display-payload/sony-font.ttf}
if [ ! -f "$UI_SRC" ]; then
    echo "REFUSING: $UI_SRC is not in the tree." >&2
    echo "  The UI source is its own lane's artifact (tools/sacd_ui.c); this" >&2
    echo "  target stages and builds it, it does not create it. Point" >&2
    echo "  UI_SRC=<path> at another source to build that instead." >&2
    exit 2
fi

H="${VM_USER:-aftermath}@${VM_HOST:-192.0.2.10}"
P="${VM_PORT:-2222}"
SCP="scp -q -o BatchMode=yes -P $P"
SSH="ssh -o BatchMode=yes -p $P"

# ── 1. stage every source the kit is built from (repo copies, never /tmp
#       leftovers — the C110 stale-member lesson) ────────────────────────────
echo "== staging UI kit sources (UI_SRC=$UI_SRC) =="
$SSH "$H" 'mkdir -p /tmp/third_party'
$SCP "$UI_SRC" "$H:/tmp/sacd_ui.c"
$SCP tools/sacdclient.c tools/bx510_fbdump.c tools/bx510_fbvirt.c \
     tools/bx510_fbvirt_mt85.h tools/bx510_vermagic_patch.py \
     evidence/bx510-guest/bdpdrv/decode/sacd_gate_ioctl.c \
     evidence/bx510-guest/bdpdrv/decode/daemon_gate.sh \
     "$H:/tmp/"
$SCP tools/third_party/stb_truetype.h tools/third_party/font8x8_basic.h \
     "$H:/tmp/third_party/"
# the guest font the UI opens by default (the HUD's carved Sony font; without
# it the UI stops at "UI: NO FONT" and draws nothing — measured, run uiloop2)
if [ -f "$FONT" ]; then
    $SCP "$FONT" "$H:/tmp/sony-font.ttf"
else
    echo "WARNING: no font at $FONT — the UI will render without text" >&2
fi
$SCP tools/bx510_ui_build_vm.sh "$H:/tmp/"

# ── 2. build on the VM (era toolchain) + repack the tgz ─────────────────────
echo "== building the UI kit on the VM =="
# The log is kept whole (it is the build's evidence); the filter is only for
# the console. A failed build must still print why, so nothing here may abort
# the script before the UI-KIT-READY check.
$SSH "$H" "sh /tmp/bx510_ui_build_vm.sh" > /tmp/bx510-ui-build.log 2>&1 || true
grep -a 'built \|pin ok \|member \|tgz \|ui link\|vermagic\|FATAL\|UI-KIT-READY' /tmp/bx510-ui-build.log || true
grep -qa 'UI-KIT-READY' /tmp/bx510-ui-build.log || {
    echo "FATAL: UI kit build did not finish:"; tail -20 /tmp/bx510-ui-build.log; exit 1; }

# ── 3. the fe_test_data budget gate — the probe's own payload arithmetic ────
echo "== budget gate: fe_test_data (the probe's real payload build) =="
# the render also validates the guest script's invariants; the files are
# throwaways — the fire renders its own for this run.
python3 tools/bx510_ui_render.py --runid ui-budget \
    --out /tmp/g-ui-budget.txt --script /tmp/bx510_ui_guest-ui-budget.sh >/dev/null
BUDGET=$(DRYRUN=1 RUNID=ui-budget GCMD_FILE=/tmp/g-ui-budget.txt sh tools/bx510-fire.sh 2>&1) || {
    echo "$BUDGET" | tail -20; echo "FATAL: the probe dry run failed (rig cold? run make sacd-stub-build)"; exit 1; }
echo "$BUDGET" | grep -a 'member shim/\|^payload:\|^stages:' || true
PAYLOAD=$(echo "$BUDGET" | sed -n 's/^payload: \([0-9][0-9]*\) B of \([0-9][0-9]*\) B (\(.*\) B free).*/\1 \2 \3/p' | head -1)
if [ -z "$PAYLOAD" ]; then
    echo "$BUDGET" | tail -20
    echo "FATAL: no payload budget line from the dry run"; exit 1
fi
# shellcheck disable=SC2086  # deliberate split of the three budget fields
set -- $PAYLOAD
echo "budget: $1 B of $2 B ($3 B free)"
[ "$3" -gt 0 ] || { echo "FATAL: the UI kit does not fit fe_test_data (over by $((-$3)) B)"; exit 1; }
echo "== UI KIT READY ($3 B of staging head-room left) =="
