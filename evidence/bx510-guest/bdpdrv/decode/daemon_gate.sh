#!/bin/sh
# daemon_gate.sh — guest-side STARTUP GATE for sacd_extract_160 under QEMU.
#
# Every gate below is something the REAL daemon does in its first five seconds,
# in the order decode/daemon-ioctl-side.md §3.1/§3.2 pins it:
#
#   main -> install_modules (mknod + insmod of the embedded sacd_read.ko)
#        -> server_loop (per second: disc_sacd() = ioctl 5306,
#                                  sacd_sacd()  = ioctl 5307)
#        -> first DISC_OPEN (sacd_open=/dev/sr0 -> init_sacd() ioctl 5301,
#                            plain 10-sector read at LBA 0x1FE -> "SACDMTOC",
#                            sacd_authenticate() ioctl 5302)
#
# The module-side requirements each gate stands for are in
# decode/sacdread-cpsa.md §1.1 (init gates) and §3.2 (the seven commands).
# Nothing here is invented: a gate with no decode sentence behind it is not in
# this file (see daemon-gate-experiments.md §5 for what is deliberately absent).
#
# Busybox/POSIX sh only — no arrays, no [[ ]], no `local`, no bashisms. The
# guest shell in the C-runs is busybox sh; `sh -n` on dash (the VM's /bin/sh)
# is the syntax gate.
#
# Usage (guest side, AFTER the C-run command list has run):
#   sh /res/shim/daemon_gate.sh
#   PROC=/res/proc DEV=/res/dev/sacd_read SR0=/res/dev/sr0 \
#       OKO=/res/shim/sacd_read.ko HELPER=/res/shim/sacdgate \
#       sh /res/shim/daemon_gate.sh
#
# Env (all optional):
#   PROC    procfs mount point                  (default /proc)
#   SR0     the ODD block node                  (default /dev/sr0)
#   DEV     the sacd_read misc char node        (default /dev/sacd_read)
#   KO      staged sacd_read.ko image           (default /res/shim/sacd_read.ko)
#   HELPER  the ioctl helper binary             (default /res/shim/sacdgate,
#                                                built from sacd_gate_ioctl.c)
#   MINOR   misc minor the daemon mknods        (default 201)
#   COMPID  insmod compid parameter             (default: empty = module default 0)
#   AUTH    "0" to skip the DISC_OPEN auth gate (default 1: run it)
#
# Output contract (one line per gate, greppable):
#   GATE <id> <PASS|FAIL|SKIP> <name> -- <detail>
# and a final summary:
#   GATE_N=<passed>/<total>
#   GATE_FAIL=<n>  GATE_SKIP=<n>
#   GATE_VERDICT=<PASS|INCOMPLETE|FAIL>
# Exit status: 0 only on PASS. INCOMPLETE (a gate could not run — helper not
# staged, AUTH=0 pre-disc, no disc yet) is not a pass: the fire gate needs PASS.
#
# This script is READ-ONLY with one deliberate exception: gate 07 creates
# /dev/sacd_read (c 10 201) when it is missing, because that is exactly the node
# the daemon's own `mknod -m0666 /dev/sacd_read c 10 201` creates, and gates
# 09-12 and 14 need it. It is left in place afterwards.

set -u

PROC=${PROC:-/proc}
SR0=${SR0:-/dev/sr0}
DEV=${DEV:-/dev/sacd_read}
KO=${KO:-/res/shim/sacd_read.ko}
HELPER=${HELPER:-/res/shim/sacdgate}
MINOR=${MINOR:-201}
COMPID=${COMPID:-}
AUTH=${AUTH:-1}

PASSED=0
FAILED=0
SKIPPED=0
TOTAL=0

# gate <id> <name> <PASS|FAIL|SKIP> <detail>
gate() {
    TOTAL=$((TOTAL + 1))
    case $3 in
        PASS) PASSED=$((PASSED + 1)) ;;
        FAIL) FAILED=$((FAILED + 1)) ;;
        SKIP) SKIPPED=$((SKIPPED + 1)) ;;
    esac
    printf 'GATE %s %s %s -- %s\n' "$1" "$3" "$2" "$4"
}

# ioctl_run <cmd>
# Runs the helper over a zeroed 16-byte _IOCTL_SACD_COMMAND and fills:
#   IO_RET  ioctl(2) return value   (<0 => the syscall/driver refused)
#   IO_RES  cmd.u4Result            (the daemon's success value, decode §1.2)
#   IO_ERR  errno when IO_RET < 0
#   IO_RAW  the raw argument quad, for evidence
#   IO_RC   0 = the helper produced a line, 1 = helper missing, 2 = refused
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

helper_missing_detail() {
    printf 'helper %s missing — build sacd_gate_ioctl.c on the VM: %s -O2 -Wall -std=gnu99 -o /tmp/sacdgate sacd_gate_ioctl.c' \
        "$HELPER" "$HOME/gnuarm/bin/arm-none-linux-gnueabi-gcc"
}

echo "== daemon_gate: sacd_extract_160 startup gates =="
echo "PROC=$PROC SR0=$SR0 DEV=$DEV KO=$KO HELPER=$HELPER MINOR=$MINOR COMPID=${COMPID:-<module-default>}"
echo

# ── gate 01 — /proc ───────────────────────────────────────────────────────────
# Needed by insmod/misc bookkeeping (and by every check below). Not by the
# daemon itself: the daemon's only /proc reference is the message string.
if [ -r "$PROC/modules" ]; then
    n_mod=$(grep -c . "$PROC/modules" 2>/dev/null)
    gate 01 proc-mount PASS "$PROC/modules readable, $n_mod modules loaded"
else
    n_mod=0
    gate 01 proc-mount FAIL "no $PROC/modules — mount -t proc proc $PROC first"
fi

# ── gate 02 — writable /tmp ───────────────────────────────────────────────────
# install_modules() writes the embedded sacd_read.ko (97,805 B) to a
# tmpnam("/tmp/XXXXXX") file before insmod (decode §3.1, 0x2f9a4-0x2f9f4).
# A read-only squashfs /tmp makes the daemon exit with
# "Can not install modules" and nothing else happens.
tmp_bytes=0
g02=FAIL
if dd if=/dev/zero of=/tmp/sacdgate.tmp bs=1024 count=96 2>/dev/null; then
    tmp_bytes=$(wc -c < /tmp/sacdgate.tmp 2>/dev/null)
    [ -n "$tmp_bytes" ] || tmp_bytes=0
    if [ "$tmp_bytes" -ge 97805 ]; then
        g02=PASS
    fi
fi
rm -f /tmp/sacdgate.tmp
gate 02 tmp-writable "$g02" "/tmp held $tmp_bytes B (need >= 97805 for the embedded sacd_read.ko)"

# ── gate 03 — the shell the daemon shells out to ─────────────────────────────
# install_modules/remove_modules run system("mknod ..."), system("insmod %s
# minor=201"), system("rmmod sacd_read"), system("rm -rf /dev/sacd_read").
# All four need a PATH-resolvable binary and a writable /dev (the rootfs /dev
# is on the read-only squashfs — C54 lesson).
g03=PASS
g03d=""
for tool in mknod insmod rmmod; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        g03=FAIL
        g03d="$g03d missing:$tool"
    fi
done
if ( : > /dev/.sacdgate.tmp ) 2>/dev/null; then
    rm -f /dev/.sacdgate.tmp
else
    g03=FAIL
    g03d="$g03d /dev-not-writable"
fi
gate 03 daemon-shell-deps "$g03" "mknod/insmod/rmmod in PATH, /dev writable:${g03d:- ok}"

# ── gate 04 — bdpdrv resident ────────────────────────────────────────────────
# sacd_read.ko resolves its whole API through kallsyms_lookup_name at init;
# bdpdrv must already be loaded (decode §2.4 of sacdread-cpsa.md) — the daemon
# never loads it.
if [ -r "$PROC/modules" ] && grep -q '^bdpdrv' "$PROC/modules" 2>/dev/null; then
    gate 04 bdpdrv-resident PASS "$(grep '^bdpdrv' "$PROC/modules" | cut -d' ' -f1-3)"
else
    gate 04 bdpdrv-resident FAIL "bdpdrv not in $PROC/modules — insmod of sacd_read.ko cannot resolve its API"
fi

# ── gate 05 — every symbol sacd_read.ko needs is resolvable ─────────────────
# 13 mandatory kallsyms lookups (decode §1, sacdread-cpsa.md) + x_memset, the
# module's single non-kernel link-time import (PHASE0-RESULTS.md P2). A missing
# kallsyms name = init returns -EFAULT (insmod: "Bad address"); a missing
# x_memset = unresolved symbol at insmod.
sym_found=0
sym_need=14
sym_missing=""
for sym in i4CPSA_Inst_CPSMode_Ctrl _IDECLI_OddRead _i4CPSA_Inst_Decrypt \
           i4CPSA_Inst_SetSACDControl u4CPSA_Inst_GetInstHandleFromCompId \
           i4CPSA_Inst_Connect i4CPSA_Inst_Disconnect vSacdDecryptEnable \
           _SACDCLI_TestPhy eSacdGetVersion _SACDCLI_FindTag \
           _IDECLI_OddTestUnitReadyLoop _IDECLI_OddGetProfile x_memset; do
    if grep -qw "$sym" "$PROC/kallsyms" 2>/dev/null; then
        sym_found=$((sym_found + 1))
    else
        sym_missing="$sym_missing $sym"
    fi
done
if [ "$sym_found" -eq "$sym_need" ]; then
    gate 05 module-symbols PASS "$sym_found/$sym_need resolvable (13 bdpdrv lookups + x_memset)"
else
    gate 05 module-symbols FAIL "$sym_found/$sym_need resolvable; missing:$sym_missing"
fi

# ── gate 06 — /dev/sr0 exists and opens ─────────────────────────────────────
# The daemon's DISC_OPEN path stat64()s and open()s /dev/sr0 unconditionally
# (client_thread 0xcc40); sacd_dev_input_open closes and returns NULL when the
# open fails, and the only message is "Can't open /dev/sr0 for reading".
g06=FAIL
g06d=""
if [ -b "$SR0" ]; then
    g06d="block node present"
    if dd if="$SR0" of=/dev/null bs=2048 count=0 2>/dev/null; then
        g06=PASS
        g06d="$g06d, open(O_RDONLY) ok"
    else
        g06d="$g06d, open failed"
    fi
else
    g06d="no $SR0 — needs libata+sata_mt85xx_mod+cdrom+sr_mod then mknod $SR0 b 11 0"
fi
gate 06 sr0-node "$g06" "$g06d"

# ── gate 07 — /dev/sacd_read (c 10 201) ─────────────────────────────────────
# The daemon creates this exact node itself:
#   system("mknod -m0666 /dev/sacd_read c 10 201")   (decode §3.1, 0x2f9fc)
# The gate creates it only when absent, so a wrong pre-existing node is a
# finding rather than something silently overwritten.
if [ -c "$DEV" ]; then
    # No major:minor parsing here on purpose: if the existing node disagrees with
    # the registered misc minor, gate 09's open() is what fails, and that is the
    # daemon's own probe.
    gate 07 sacd-read-node PASS "char node already present: $DEV (validated by gate 09)"
elif mknod -m0666 "$DEV" c 10 "$MINOR" 2>/dev/null && [ -c "$DEV" ]; then
    gate 07 sacd-read-node PASS "created by this gate: $DEV c 10 $MINOR (daemon mknods the same)"
else
    gate 07 sacd-read-node FAIL "cannot create $DEV c 10 $MINOR (see gate 03)"
fi

# ── gate 08 — sacd_read.ko loads and registers minor 201 ────────────────────
# Two halves of one daemon step: `insmod <tmp> minor=201` must return 0, and
# the misc device must land on the SAME minor the node carries — /proc/misc is
# where the kernel reports it (decode §1.1: misc_register is the last init
# step; a minor mismatch is invisible until open() gives ENODEV).
# The daemon passes no compid, so the module default (0, .bss-zeroed) applies.
g08=FAIL
g08d=""
insmod_rc=-1
insmod_out=""
if [ -r "$PROC/misc" ] && grep -q 'sacd_read' "$PROC/misc" 2>/dev/null; then
    misc_minor=$(awk '$2=="sacd_read"{print $1}' "$PROC/misc" 2>/dev/null)
    if [ "$misc_minor" = "$MINOR" ]; then
        g08=PASS
        g08d="already loaded, $PROC/misc reports sacd_read minor $misc_minor"
    else
        g08d="already loaded on minor $misc_minor, node is 10:$MINOR (rmmod and reload)"
    fi
elif [ ! -f "$KO" ]; then
    g08d="no module image at $KO (stage sacd_read.ko there)"
else
    if [ -n "$COMPID" ]; then
        insmod_out=$(insmod "$KO" minor="$MINOR" compid="$COMPID" 2>&1)
        insmod_rc=$?
    else
        insmod_out=$(insmod "$KO" minor="$MINOR" 2>&1)
        insmod_rc=$?
    fi
    misc_minor=""
    if [ -r "$PROC/misc" ]; then
        misc_minor=$(awk '$2=="sacd_read"{print $1}' "$PROC/misc" 2>/dev/null)
    fi
    # insmod's own text is the diagnosis: init_module returns -EFAULT/-EBUSY and
    # busybox prints strerror() — PHASE0-RESULTS P2 recorded exactly
    # "insmod: Bad address" for a NULL kallsyms lookup. Classify on the text,
    # keep rc for the record (busybox does not reliably exit with the errno).
    if [ "$insmod_rc" -eq 0 ] && [ "$misc_minor" = "$MINOR" ]; then
        g08=PASS
        g08d="insmod rc=0, $PROC/misc reports sacd_read minor $misc_minor"
    elif [ "$insmod_rc" -eq 0 ]; then
        g08d="insmod rc=0 but $PROC/misc shows sacd_read minor '${misc_minor:-<absent>}' (node is $MINOR)"
    else
        g08d="insmod rc=$insmod_rc '$insmod_out'"
        case $insmod_out in
            *"Bad address"*)      g08d="$g08d -> EFAULT: a mandatory kallsyms lookup is NULL (gate 05)" ;;
            *"resource busy"*)    g08d="$g08d -> EBUSY: compid ${COMPID:-0} is already owned; try compid=1..3" ;;
            *"File exists"*)      g08d="$g08d -> EEXIST: module already resident (rmmod sacd_read first)" ;;
            *"Unknown symbol"*)   g08d="$g08d -> unresolved link-time import (x_memset: gate 05)" ;;
            *"Invalid module format"*) g08d="$g08d -> vermagic mismatch; the module is '2.6.35 preempt mod_unload ARMv6'" ;;
        esac
        g08d="$g08d; $PROC/misc sacd_read minor '${misc_minor:-<absent>}'"
    fi
fi
gate 08 module-load "$g08" "$g08d"

# ── gate 09 — open("/dev/sacd_read") ────────────────────────────────────────
# install_modules()'s last step is exactly this open (0x2fa34): it is what
# turns a failed mknod/insmod into "Can not install modules".
g09=SKIP
g09d="no char node at $DEV"
if [ -c "$DEV" ]; then
    if dd if="$DEV" of=/dev/null bs=16 count=0 2>/dev/null; then
        g09=PASS
        g09d="$DEV opens O_RDONLY (sacd_read_open always returns 0)"
    else
        g09=FAIL
        g09d="$DEV will not open — node minor vs $PROC/misc sacd_read must agree (gate 08)"
    fi
fi
gate 09 sacd-read-open "$g09" "$g09d"

# ── gate 10 — ioctl 0x40105306 TEST UNIT READY ─────────────────────────────
# server_loop calls disc_sacd() once a second, BEFORE any client exists, and
# reads the status line's third field from it: result != 0 => "Tray is empty"
# (decode §3.3, §5.2 D-6). So this gate runs with no disc and no session.
# The driver side is _IDECLI_OddTestUnitReadyLoop(20000) — it polls 100x200 ms,
# so a hung ODD model shows up here as a multi-second gate, not an error.
g10=SKIP
g10d=$(helper_missing_detail)
if ioctl_run 0x40105306; then
    if [ "$IO_RET" -ge 0 ] && [ "$IO_RES" -eq 0 ]; then
        g10=PASS
    else
        g10=FAIL
    fi
    g10d="rc=$IO_RC ret=$IO_RET errno=$IO_ERR result=$IO_RES raw=[$IO_RAW]"
fi
gate 10 unit-ready "$g10" "$g10d"

# ── gate 11 — ioctl 0x40105307 GET CONFIGURATION profile == 0x10 ───────────
# sacd_sacd(): driver is -1 unless the MMC current profile is 0x10 (DVD-ROM).
# The daemon reads >= 0 as "SACD disc inserted" and < 0 as "Disc inserted"
# (present but not SACD) — this is the profile gate the C9x endgame needs.
g11=SKIP
g11d=$(helper_missing_detail)
if ioctl_run 0x40105307; then
    if [ "$IO_RET" -ge 0 ] && [ "$IO_RES" -ge 0 ]; then
        g11=PASS
    else
        g11=FAIL
    fi
    g11d="rc=$IO_RC ret=$IO_RET errno=$IO_ERR result=$IO_RES raw=[$IO_RAW] (result<0 means profile != 0x10)"
fi
gate 11 disc-profile "$g11" "$g11d"

# ── gate 12 — ioctl 0x40105301 INIT (the only handshake) ───────────────────
# sacd_dev_input_open: open(/dev/sr0) then, on the default /dev/sr0 path,
# init_sacd() -> ioctl 5301; result < 0 aborts the open, which is reported as
# "libsacdread: Can't open /dev/sr0 for reading" (decode §2.2). Driver side is
# CPSA_SACDCmdEnable: Connect(0x16b,compid,360,compid) + CPSMode_Ctrl(...,0x40,TRUE).
g12=SKIP
g12d=$(helper_missing_detail)
if ioctl_run 0x40105301; then
    if [ "$IO_RET" -ge 0 ] && [ "$IO_RES" -ge 0 ]; then
        g12=PASS
    else
        g12=FAIL
    fi
    g12d="rc=$IO_RC ret=$IO_RET errno=$IO_ERR result=$IO_RES raw=[$IO_RAW]"
fi
gate 12 sacd-init "$g12" "$g12d"

# ── gate 13 — the disc: "SACDMTOC" at LBA 0x1FE x10 (plain read) ───────────
# The daemon's first disc contact is NOT an ioctl: scarletbook_read_master_toc
# lseek64's to LBA 0x1FE (510), reads 10x2048 B and checks the first 8 bytes
# (decode §2.4). Failure strings: "Can't read Master TOC." / "Not a
# ScarletBook disc!". This gate is where "the disc appears" is actually
# observable — and it needs no 0x8530 support at all.
mtoc_magic=""
mtoc_bytes=0
mtoc_hex=""
g13=FAIL
g13d="no $SR0"
if [ -b "$SR0" ]; then
    if dd if="$SR0" of=/tmp/sacdgate.mtoc bs=2048 skip=510 count=10 2>/dev/null; then
        mtoc_bytes=$(wc -c < /tmp/sacdgate.mtoc 2>/dev/null)
        [ -n "$mtoc_bytes" ] || mtoc_bytes=0
        mtoc_magic=$(dd if=/tmp/sacdgate.mtoc bs=1 count=8 2>/dev/null)
        mtoc_hex=$(od -An -tx1 -N8 /tmp/sacdgate.mtoc 2>/dev/null | tr -s ' ' | sed 's/^ //')
        if [ "$mtoc_magic" = "SACDMTOC" ] && [ "$mtoc_bytes" -eq 20480 ]; then
            g13=PASS
        fi
    fi
    g13d="LBA 510 x10 = $mtoc_bytes B, first 8 bytes [$mtoc_hex] (want 53 41 43 44 4d 54 4f 43)"
fi
rm -f /tmp/sacdgate.mtoc
gate 13 master-toc "$g13" "$g13d"

# ── gate 14 — ioctl 0x40105302 AUTH (DISC_OPEN, after the TOC) ─────────────
# client_thread's DISC_OPEN order is sacd_open -> scarletbook_open (gate 13)
# -> sacd_authenticate -> ioctl 5302 (decode §2.5). Gated on 13 for that
# reason. The daemon tolerates a failure (only a log line at level > 1 and a
# non-zero DISC_OPEN result) — so this gate is the one that separates "the
# driver answers" from "the daemon silently serves an unauthenticated disc".
g14=SKIP
g14d="skipped by AUTH=0"
if [ "$AUTH" != "0" ]; then
    if [ "$g13" != "PASS" ]; then
        g14d="no valid Master TOC (gate 13) — the daemon reaches AUTH only after it"
    elif ioctl_run 0x40105302; then
        if [ "$IO_RET" -ge 0 ] && [ "$IO_RES" -ge 0 ]; then
            g14=PASS
        else
            g14=FAIL
        fi
        g14d="rc=$IO_RC ret=$IO_RET errno=$IO_ERR result=$IO_RES raw=[$IO_RAW]"
    else
        g14d=$(helper_missing_detail)
    fi
fi
gate 14 sacd-auth "$g14" "$g14d"

# ── summary ─────────────────────────────────────────────────────────────────
echo
echo "GATE_N=$PASSED/$TOTAL"
echo "GATE_FAIL=$FAILED"
echo "GATE_SKIP=$SKIPPED"
if [ "$FAILED" -eq 0 ] && [ "$SKIPPED" -eq 0 ]; then
    echo "GATE_VERDICT=PASS"
    exit 0
fi
if [ "$FAILED" -eq 0 ]; then
    # A gate that could not run is NOT a pass. The fire gate needs PASS; a
    # pre-disc run (AUTH=0, helper not yet staged) lands here by design.
    echo "GATE_VERDICT=INCOMPLETE"
    exit 1
fi
echo "GATE_VERDICT=FAIL"
exit 1
