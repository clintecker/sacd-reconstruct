#!/bin/sh
# sacd_parity.sh — Mac-side parity harness for one candidate ELF.
#
# Usage: tools/sacd_parity.sh <original.elf> <candidate.elf>
#
# 1. fn_diff over the 390 normalized functions. Tolerable mismatches:
#    the two documented startup residuals (_start, call_gmon_start — see
#    DELTA.md) and recursive_mkdir — a DELIBERATE divergence: our build
#    tolerates EPERM in recursive_mkdir's errno set (the original ran as
#    root on the player and never saw it; our client runs as a normal user
#    under the qemu rig and died on it — see reconstruct/libcommon/
#    fileutils.c and decode/daemon-install-erofs.md's environment notes).
#    Anything else fails.
# 2. pool_audit: literal-pool identity at load sites (string content,
#    function-pointer symbols, section boundaries, scalar values) — see
#    evidence/status-test/fn-diff-literal-policy.md.
# 3. The embedded sacd_read.ko blob: byte identity. Neither tool sees the
#    module as code (it is data the daemon writes to /tmp and insmods), so
#    module parity IS blob parity — reported by pool_audit.
# 4. The literal regression mutants (pointer swap, ninth character,
#    function-pointer swap, module-boundary literal, blob byte).
set -u

ORIG=${1:?original elf}
CAND=${2:?candidate elf}
HERE=$(cd "$(dirname "$0")" && pwd)
ACCEPTED=" _start call_gmon_start recursive_mkdir "
fail=0

echo "=== fn_diff"
out=$(python3 "$HERE/fn_diff.py" "$ORIG" "$CAND" 2>&1)
rc=$?
echo "$out"

miss=$(echo "$out" | sed -n 's/.*missing-in-recon: \([0-9]*\).*/\1/p')
if [ "$miss" != "0" ]; then
    echo "sacd-parity: FAIL — missing-in-recon: $miss"
    fail=1
fi

for m in $(echo "$out" | sed -n 's/^MISMATCH: //p'); do
    case " $ACCEPTED " in
    *" $m "*)
        echo "residual (accepted): $m"
        ;;
    *)
        echo "sacd-parity: FAIL — unexpected fn_diff mismatch: $m"
        fail=1
        ;;
    esac
done
[ $rc -eq 0 ] || [ $rc -eq 1 ] || { echo "sacd-parity: FAIL — fn_diff error"; fail=1; }

echo
echo "=== pool_audit (literal identity + embedded module blob)"
python3 "$HERE/pool_audit.py" "$ORIG" "$CAND" --verbose || fail=1

echo
echo "=== literal + module regression mutants"
python3 "$HERE/test_pool_audit_regressions.py" "$ORIG" "$CAND" || fail=1

echo
echo "sacd-parity: $([ $fail = 0 ] && echo PASS || echo FAIL)"
exit $fail
