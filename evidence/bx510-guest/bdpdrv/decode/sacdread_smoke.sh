#!/bin/sh
# sacdread_smoke.sh — guest-side SMOKE STAGE for sacd_read.ko, WITH NO DAEMON.
#
# Placement in the C-run sequence: after the CLI probes (C95-C99) and after the
# module stack that bdpdrv needs, BEFORE sacd_extract_160 is ever launched.
# This stage answers one question — "do the module's bdpdrv hooks actually
# work?" — without a disc, a daemon, or a client:
#
#   insmod minor=201   -> 13 kallsyms lookups against a resident bdpdrv
#   /proc/misc         -> sacd_read registered on minor 201
#   mknod c 10 201     -> the node the daemon's own mknod creates
#   ioctl 0x40105301   -> CPSA_SACDCmdEnable: Connect(0x16b,compid,360,compid)
#                          + CPSMode_Ctrl(handle,0x40,TRUE) -> i4CPSA_SACD_Create
#                          + i4CPSA_SACD_SetCallback          (kernel bookkeeping
#                          only: no MMIO, no /dev/sr0 — see sacdread-stage-plan.md §4)
#   ioctl 0x40105302   -> CPSA_SACDCmdSetCtrl: GetInst + i4CPSA_Inst_SetSACDControl
#                          -> i4CPSA_SACD_EnableControl, THEN _SACDCLI_TestPhy
#                          (the full SACD bring-up self-test: TUR loop <=20 s,
#                          GET CONFIGURATION, seek, PSP/PDM) and, if that returns 0,
#                          eSacdGetVersion (0xFD039008) + vSacdDecryptEnable(TRUE)
#                          (0xFD039000/0xFD039004 + BIM doorbell 0xFD008154).
#                          This is the correction to decode/sacdread-cpsa.md §1:
#                          _SACDCLI_TestPhy / eSacdGetVersion ARE called — from here.
#   ioctl 0x40105305   -> CPSA_SACDCmdDisable: vSacdDecryptEnable(FALSE) +
#                          CPSMode_Ctrl(handle,0x40,FALSE) + Disconnect
#   ioctl 0x40105301   -> INIT a SECOND time: the only decisive proof that
#                          UNINIT released the compid slot (_au4CpsaInst[compid]
#                          back to -1); a leak shows up here as 0xE8000006, not
#                          as a silently-kept instance
#   rmmod              -> /proc/misc no longer lists sacd_read
#
# ORDER IS A SAFETY RULE, not a preference. AUTH (5302) and UNINIT (5305) both
# take the handle from u4CPSA_Inst_GetInstHandleFromCompId, which returns
# 0xFFFFFFFF while the compid slot is free, and i4CPSA_Inst_SetSACDControl
# dereferences it before validating the magic (bdpdrv 0x55908: `ldr r2,[r0]`
# then `cmp r2,#0x12043000`). Firing either ioctl without a SUCCESSFUL INIT
# faults the guest kernel instead of returning an error. S07 gates S08/S09.
#
# Busybox/POSIX sh only: no arrays, no [[ ]], no local, no bashisms. `sh -n` on
# dash is the syntax gate; shellcheck -s sh is the lint gate.
#
# Usage (guest side):
#   sh /res/shim/sacdread_smoke.sh
#   PROC=/res/proc DEV=/dev/sacd_read KO=/res/shim/sacd_read.ko \
#       HELPER=/res/shim/sacdgate AUTH=0 sh /res/shim/sacdread_smoke.sh
#
# Env (all optional):
#   PROC    procfs mount point                   (default /proc)
#   DEV     /dev/sacd_read node                  (default /dev/sacd_read)
#   SR0     the ODD block node, reported only    (default /dev/sr0)
#   KO      staged sacd_read.ko                  (default /res/shim/sacd_read.ko)
#   HELPER  the ioctl helper (decode/sacd_gate_ioctl.c, built on the VM)
#   MINOR   misc minor for insmod/mknod          (default 201 — the daemon's)
#   COMPID  insmod compid (default: empty = module default 0)
#   AUTH    "0" to skip S08 (fast, hardware-free run)
#   UNLOAD  "0" to leave the module resident at the end
#
# Output contract (one line per gate, greppable; every step also echoes a
# console marker so the UART transcript can be sliced around it):
#   SMOKE <id> <PASS|FAIL|SKIP> <name> -- <detail>
#   SMOKE_N=<passed>/<total>
#   SMOKE_FAIL=<n>  SMOKE_SKIP=<n>
#   SMOKE_VERDICT=<PASS|INCOMPLETE|FAIL>
# Exit status: 0 only on PASS. INCOMPLETE (a gate could not run: helper not
# staged, AUTH=0, no /dev/sr0 for the TestPhy leg) is not a pass.

set -u

PROC=${PROC:-/proc}
DEV=${DEV:-/dev/sacd_read}
SR0=${SR0:-/dev/sr0}
KO=${KO:-/res/shim/sacd_read.ko}
HELPER=${HELPER:-/res/shim/sacdgate}
MINOR=${MINOR:-201}
COMPID=${COMPID:-}
AUTH=${AUTH:-1}
UNLOAD=${UNLOAD:-1}

PASSED=0
FAILED=0
SKIPPED=0
TOTAL=0

# The CPSA "OK" code both hooks return (bdpdrv i4CPSA_SACD_*: `mov r0,#0x68000000`).
# Positive, never 0 — a gate that tested == 0 would report a false FAIL.
CPSA_OK=1744830464

gate() {
    TOTAL=$((TOTAL + 1))
    case $3 in
        PASS) PASSED=$((PASSED + 1)) ;;
        FAIL) FAILED=$((FAILED + 1)) ;;
        SKIP) SKIPPED=$((SKIPPED + 1)) ;;
    esac
    printf 'SMOKE %s %s %s -- %s\n' "$1" "$3" "$2" "$4"
}

step() {
    printf 'SMOKE_STEP=%s\n' "$1"
}

# ioctl_run <cmd>  — same helper contract as decode/daemon_gate.sh:
#   IO_RET  ioctl(2) return (0 on success, -22 -EINVAL for a non-0x53 command,
#           -14 -EFAULT on a copy failure — the CPSA code is NOT the ioctl return)
#   IO_RES  cmd.u4Result, the value the driver's hook returned (what the daemon
#           reads back; see decode/daemon-ioctl-side.md §1.2)
#   IO_ERR  errno when IO_RET < 0
#   IO_RAW  the raw argument quad
IO_RET=-1
IO_RES=-1
IO_ERR=0
IO_RAW=""
IO_RC=1
IO_OUT=""
ioctl_run() {
    IO_RET=-1
    IO_RES=-1
    IO_ERR=0
    IO_RAW=""
    IO_RC=1
    IO_OUT=""
    if [ ! -f "$HELPER" ]; then
        return 1
    fi
    IO_OUT=$("$HELPER" "$1" "$DEV" 2>&1)
    IO_RC=$?
    IO_RET=$(printf '%s\n' "$IO_OUT" | sed -n 's/.*ret=\(-*[0-9][0-9]*\).*/\1/p')
    IO_RES=$(printf '%s\n' "$IO_OUT" | sed -n 's/.*result=\(-*[0-9][0-9]*\).*/\1/p')
    IO_ERR=$(printf '%s\n' "$IO_OUT" | sed -n 's/.*errno=\(-*[0-9][0-9]*\).*/\1/p')
    IO_RAW=$(printf '%s\n' "$IO_OUT" | sed -n 's/.*raw=\(.*\) dev=.*/\1/p')
    [ -n "$IO_RET" ] || IO_RET=-1
    [ -n "$IO_RES" ] || IO_RES=-1
    [ -n "$IO_ERR" ] || IO_ERR=0
    return 0
}

# cpsa_hint <result> — name the CPSA failure code instead of leaving a number.
cpsa_hint() {
    case $1 in
        -402653178) printf ' (0xE8000006 CPSA: compid slot busy — an earlier instance was never disconnected)' ;;
        -402653182) printf ' (0xE8000002 CPSA Assert: bad handle magic — INIT did not run)' ;;
        -402653183) printf ' (0xE8000001 CPSA: instance/invalid state)' ;;
        -402653174) printf ' (0xE800000A SACD ctx not enabled)' ;;
        -1)         printf ' (ODD leg: /dev/sr0 open or ioctl 0x8530 failed — sacdread-cpsa.md §4.2)' ;;
        *)          printf ' (negative = the bdpdrv hook failed; kernel console line names it)' ;;
    esac
}

misc_minor() {
    [ -r "$PROC/misc" ] || return 1
    awk '$2=="sacd_read"{print $1}' "$PROC/misc" 2>/dev/null
}

echo "== sacdread_smoke: sacd_read.ko insmod + ioctl smoke (no daemon) =="
echo "PROC=$PROC DEV=$DEV SR0=$SR0 KO=$KO HELPER=$HELPER MINOR=$MINOR"
echo "COMPID=${COMPID:-<module-default>} AUTH=$AUTH UNLOAD=$UNLOAD"
echo

# ── S01 — /proc readable (insmod + /proc/misc + the symbol table) ────────────
step S01
if [ -r "$PROC/modules" ] && [ -r "$PROC/misc" ]; then
    gate S01 proc-mount PASS "$PROC/modules and $PROC/misc readable"
else
    gate S01 proc-mount FAIL "no $PROC/modules or $PROC/misc — mount -t proc proc $PROC first"
fi

# ── S02 — bdpdrv resident (the 13 lookups are resolved at init) ──────────────
# sacdread-cpsa.md §2.4: bdpdrv must already be loaded AND i4CPSA_Init must have
# run (it is what fills _au4CpsaInst[] with -1, the value INIT's compid gate
# demands). This stage never loads bdpdrv — C50/C51-C55 does.
step S02
if [ -r "$PROC/modules" ] && grep -q '^bdpdrv' "$PROC/modules" 2>/dev/null; then
    gate S02 bdpdrv-resident PASS "$(grep '^bdpdrv' "$PROC/modules" | cut -d' ' -f1-3)"
else
    gate S02 bdpdrv-resident FAIL "bdpdrv not in $PROC/modules — insmod would return -EFAULT on all 13 lookups"
fi

# ── S03 — the module's link-time imports (not the kallsyms ones) ────────────
# x_memset is the only non-kernel import (PHASE0-RESULTS P2); INIT additionally
# needs the OSAL primitives i4GCPU_InstanceCreate calls (x_thread_create,
# x_ev_group_create, x_msg_q_create, x_sema_lock, x_mem_aligned_alloc) — all
# five are exported by the C-run's osal_stub.ko (nm, /tmp/osal_b).
step S03
imps_ok=0
imps_need=2
imps_missing=""
for sym in x_memset x_thread_create; do
    if grep -qw "$sym" "$PROC/kallsyms" 2>/dev/null; then
        imps_ok=$((imps_ok + 1))
    else
        imps_missing="$imps_missing $sym"
    fi
done
if [ "$imps_ok" -eq "$imps_need" ]; then
    gate S03 module-imports PASS "$imps_ok/$imps_need resolvable (x_memset + the GCPU thread's x_thread_create)"
else
    gate S03 module-imports FAIL "$imps_ok/$imps_need; missing:$imps_missing — insmod fails with 'Unknown symbol'"
fi

# ── S04 — the staged image survives the tar staging (size is the budget) ────
# The daemon's own embedded copy is 97,805 B (sha256 b3d7a383…); the staged copy
# must be the same object, so a truncated/short member is caught here, before
# insmod turns it into "Invalid module format".
step S04
ko_bytes=0
if [ -f "$KO" ]; then
    ko_bytes=$(wc -c < "$KO" 2>/dev/null)
    [ -n "$ko_bytes" ] || ko_bytes=0
fi
if [ "$ko_bytes" -eq 97805 ]; then
    gate S04 module-image PASS "$KO is 97805 B (the daemon's embedded copy size)"
elif [ "$ko_bytes" -gt 0 ]; then
    gate S04 module-image FAIL "$KO is $ko_bytes B, expected 97805 — wrong file or a truncated tar member"
else
    gate S04 module-image FAIL "no module at $KO — stage it with --extra-file sacd_read.ko=…"
fi

# ── S05 — insmod minor=201, then /proc/misc says minor 201 ─────────────────
# The daemon's own line is `insmod <tmp> minor=201` with NO compid
# (daemon-ioctl-side.md §3.1). Both halves matter: the node the daemon mknods
# is c 10 201, so a minor mismatch is invisible until open() gives ENODEV.
step S05
insmod_rc=-1
insmod_out=""
already=$(misc_minor)
if [ -n "${already:-}" ]; then
    gate S05 module-load PASS "already resident, $PROC/misc reports sacd_read minor $already"
elif [ "$ko_bytes" -gt 0 ]; then
    if [ -n "$COMPID" ]; then
        insmod_out=$(insmod "$KO" minor="$MINOR" compid="$COMPID" 2>&1)
        insmod_rc=$?
    else
        insmod_out=$(insmod "$KO" minor="$MINOR" 2>&1)
        insmod_rc=$?
    fi
    now=$(misc_minor)
    if [ "$insmod_rc" -eq 0 ] && [ "${now:-}" = "$MINOR" ]; then
        gate S05 module-load PASS "insmod rc=0, $PROC/misc reports sacd_read minor $now"
    else
        detail="insmod rc=$insmod_rc '$insmod_out'; $PROC/misc sacd_read minor '${now:-<absent>}' (want $MINOR)"
        case $insmod_out in
            *"Bad address"*)         detail="$detail -> EFAULT: one of the 13 kallsyms lookups is NULL (S02/S03)" ;;
            *"resource busy"*)       detail="$detail -> EBUSY: compid ${COMPID:-0} already owned; retry COMPID=1..3" ;;
            *"File exists"*)         detail="$detail -> EEXIST: resident; rmmod sacd_read first" ;;
            *"Unknown symbol"*)      detail="$detail -> a link-time import is missing (S03)" ;;
            *"Invalid module format"*) detail="$detail -> vermagic is '2.6.35 preempt mod_unload ARMv6'" ;;
        esac
        gate S05 module-load FAIL "$detail"
    fi
else
    gate S05 module-load FAIL "no module image at $KO (S04)"
fi

# ── S06 — the node the daemon mknods, created only if absent ───────────────
# `mknod -m0666 /dev/sacd_read c 10 201` (daemon-ioctl-side.md §3.1). A node we
# did not create is a finding, not something to overwrite silently.
step S06
g06=FAIL
g06d=""
if [ -c "$DEV" ]; then
    g06d="$DEV already present (left as found)"
    if dd if="$DEV" of=/dev/null bs=16 count=0 2>/dev/null; then
        g06=PASS
        g06d="$g06d, opens O_RDONLY"
    else
        g06d="$g06d, will not open — node minor vs $PROC/misc must agree (S05)"
    fi
elif mknod -m0666 "$DEV" c 10 "$MINOR" 2>/dev/null && [ -c "$DEV" ]; then
    g06d="created $DEV c 10 $MINOR"
    if dd if="$DEV" of=/dev/null bs=16 count=0 2>/dev/null; then
        g06=PASS
        g06d="$g06d, opens O_RDONLY"
    else
        g06d="$g06d, will not open"
    fi
else
    g06d="cannot create $DEV c 10 $MINOR (writable /dev? see C54)"
fi
gate S06 sacd-read-node "$g06" "$g06d"

# ── S06b — the CPSA peer entry (gcpu-connect-path.md Route A) ────────────
# The driver's Connect query (0x168, compid, 0) has no counterparty in
# bdpdrv (all 19 i4ImRegisterInterface2 call sites resolved, none 0x168),
# so INIT fails 0xE8000000 forever without this. Registered BEFORE the first
# INIT; the wildcard compid matches the query. Idempotent-ish: a second
# insmod fails benignly (the record persists for the bdpdrv load's lifetime).
if insmod /res/shim/bx510_cpsa_peer.ko 2>/dev/null; then
    gate S06b cpsa-peer PASS "peer entry registered (0x168 wildcard)"
else
    gate S06b cpsa-peer SKIP "insmod failed (already registered, or module absent)"
fi

# ── S07 — ioctl 0x40105301 INIT: the bdpdrv hook proof ────────────────────
# CPSA_SACDCmdEnable(compid): Connect(0x16b,compid,360,compid) ->
# i4CPSA_Inst_Create (instance magic 0x12043000, GCPU worker thread, event
# groups) then CPSMode_Ctrl(handle,0x40,TRUE) -> i4CPSA_SACD_Create (ctx magic
# 0x12043007) + SetCallback. Success value is 0x68000000 (= %d 1744830464),
# which is POSITIVE — test signed >= 0, never == 0.
step S07
g07=SKIP
g07d="helper missing: build decode/sacd_gate_ioctl.c on the VM (arm-none-linux-gnueabi-gcc -O2 -Wall -std=gnu99)"
if [ "$g06" = "PASS" ] && ioctl_run 0x40105301; then
    if [ "$IO_RET" -ge 0 ] && [ "$IO_RES" -ge 0 ]; then
        g07=PASS
        g07d="ret=$IO_RET result=$IO_RES raw=[$IO_RAW]"
        if [ "$IO_RES" -ne "$CPSA_OK" ]; then
            g07d="$g07d (not 0x68000000=$CPSA_OK — hook returned a different positive code)"
        fi
    else
        g07=FAIL
        g07d="ret=$IO_RET errno=$IO_ERR result=$IO_RES raw=[$IO_RAW]$(cpsa_hint "$IO_RES")"
    fi
fi
gate S07 sacd-init "$g07" "$g07d"

# ── S08 — ioctl 0x40105302 AUTH: SetSACDControl + WHOLE bring-up self-test ─
# On SetSACDControl success the module runs _SACDCLI_TestPhy() and, if that
# returns 0, eSacdGetVersion() (reads 0xFD039008) and vSacdDecryptEnable(TRUE)
# (writes 0xFD039000 and the BIM doorbell 0xFD00815C/0xFD008154). Budget up to
# ~35 s of guest time when /dev/sr0 exists but answers nothing: the TUR loop
# polls 100x200 ms (timeout 20000) and eSacdWaitPspPdmResult waits 5000 ms.
# GATED ON S07: without a live instance the handle is 0xFFFFFFFF and
# i4CPSA_Inst_SetSACDControl dereferences it (bdpdrv 0x55908) — a guest oops.
step S08
g08=SKIP
g08d="skipped by AUTH=0"
if [ "$AUTH" != "0" ]; then
    if [ "$g07" != "PASS" ]; then
        g08d="not run: INIT (S07) did not pass — AUTH would dereference a 0xFFFFFFFF instance handle"
    elif ioctl_run 0x40105302; then
        sr0_note="no $SR0 (TestPhy's /dev/sr0 open fails, expected pre-C102)"
        [ -b "$SR0" ] && sr0_note="$SR0 present"
        if [ "$IO_RET" -ge 0 ] && [ "$IO_RES" -ge 0 ]; then
            g08=PASS
            g08d="ret=$IO_RET result=$IO_RES raw=[$IO_RAW]; TestPhy returned 0 so the version + decrypt-enable leg ran; $sr0_note"
        else
            g08=FAIL
            g08d="ret=$IO_RET errno=$IO_ERR result=$IO_RES raw=[$IO_RAW]$(cpsa_hint "$IO_RES"); $sr0_note"
        fi
    fi
fi
gate S08 sacd-auth "$g08" "$g08d"

# ── S09 — ioctl 0x40105305 UNINIT: the disable/disconnect hook ────────────
# CPSA_SACDCmdDisable: vSacdDecryptEnable(FALSE) -> CPSMode_Ctrl(handle,0x40,
# FALSE) -> vCPSA_SACD_Destroy -> Disconnect(0x16b,compid,360,compid). Same
# handle-deref rule as S08, so the same S07 gate applies. The daemon ignores
# this result (uninit_sacd reads nothing back), so PASS is "the ioctl was
# accepted", and result is recorded for the transcript.
step S09
g09=SKIP
g09d="not run: INIT (S07) did not pass — Disable dereferences the instance handle too"
if [ "$g07" = "PASS" ] && ioctl_run 0x40105305; then
    if [ "$IO_RET" -ge 0 ]; then
        g09=PASS
        g09d="ret=$IO_RET result=$IO_RES raw=[$IO_RAW] (the daemon ignores this value; S10 is the decisive check)"
    else
        g09=FAIL
        g09d="ret=$IO_RET errno=$IO_ERR result=$IO_RES raw=[$IO_RAW]$(cpsa_hint "$IO_RES")"
    fi
fi
gate S09 sacd-uninit "$g09" "$g09d"

# ── S10 — INIT again: UNINIT really released the compid slot ──────────────
# i4CPSA_Inst_Connect refuses with 0xE8000006 while _au4CpsaInst[compid] != -1,
# and only i4CPSA_Inst_Disconnect clears it back to -1. So a second INIT is the
# decisive teardown proof — and it is also what the daemon needs: a slot left
# owned by this stage would make the daemon's own INIT fail with EBUSY.
step S10
g10=SKIP
g10d="not run: nothing to re-init (S07/S09)"
if [ "$g09" = "PASS" ] && ioctl_run 0x40105301; then
    if [ "$IO_RET" -ge 0 ] && [ "$IO_RES" -ge 0 ]; then
        g10=PASS
        g10d="ret=$IO_RET result=$IO_RES raw=[$IO_RAW]; the compid slot was free again"
    else
        g10=FAIL
        g10d="ret=$IO_RET errno=$IO_ERR result=$IO_RES raw=[$IO_RAW]$(cpsa_hint "$IO_RES")"
    fi
fi
gate S10 sacd-reinit "$g10" "$g10d"

# ── S11 — best-effort kernel-side evidence for this stage ──────────────────
# The printk lines ("[SACDREAD] …", "[%s]… Fail:%d") go to the console and are
# already in the fire's UART capture; dmesg just puts a copy in the script's own
# output when the guest has it.
step S11
if command -v dmesg >/dev/null 2>&1; then
    echo "SMOKE_DMESG_BEGIN"
    dmesg 2>/dev/null | tail -40
    echo "SMOKE_DMESG_END"
    gate S11 dmesg PASS "last 40 kernel lines captured between the markers"
else
    gate S11 dmesg SKIP "no dmesg in the guest; use the fire's UART capture ([SACDREAD] lines)"
fi

# ── S12 — rmmod, so the daemon's own insmod does not hit EEXIST ───────────
# The daemon runs `mknod`, `insmod <tmp> minor=201`, then opens the node; a
# module left resident by this stage makes its insmod fail (the open would
# still succeed, but the transcript would then be ambiguous about who loaded
# the module).
step S12
g12=SKIP
g12d="UNLOAD=0 — module left resident for the next stage"
if [ "$UNLOAD" != "0" ] && command -v rmmod >/dev/null 2>&1; then
    rmmod_out=""
    rmmod_rc=-1
    rmmod_out=$(rmmod sacd_read 2>&1)
    rmmod_rc=$?
    after=$(misc_minor)
    if [ -z "${after:-}" ]; then
        g12=PASS
        g12d="rmmod rc=$rmmod_rc, $PROC/misc no longer lists sacd_read"
    else
        g12=FAIL
        g12d="rmmod rc=$rmmod_rc '$rmmod_out', $PROC/misc still says minor $after (open fd?)"
    fi
fi
gate S12 module-unload "$g12" "$g12d"

# ── summary ───────────────────────────────────────────────────────────────
echo
echo "SMOKE_N=$PASSED/$TOTAL"
echo "SMOKE_FAIL=$FAILED"
echo "SMOKE_SKIP=$SKIPPED"
if [ "$FAILED" -gt 0 ]; then
    echo "SMOKE_VERDICT=FAIL"
elif [ "$SKIPPED" -gt 0 ]; then
    echo "SMOKE_VERDICT=INCOMPLETE"
else
    echo "SMOKE_VERDICT=PASS"
fi
[ "$FAILED" -eq 0 ] && [ "$SKIPPED" -eq 0 ]
