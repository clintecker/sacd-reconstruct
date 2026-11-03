#!/bin/sh
# sacd_parity.sh — Mac-side parity harness for one candidate ELF.
#
# Usage: tools/sacd_parity.sh <original.elf> <candidate.elf>
#
# 1. fn_diff over the 390 normalized functions. The only tolerable
#    mismatches are the two documented startup residuals
#    (_start, call_gmon_start — see DELTA.md); anything else fails.
# 2. pool_audit: literal-pool content comparison at load sites
#    (strings/scalars/pointer structures).
# 3. The two literal regression tests (pointer swap + ninth character).
set -u

ORIG=${1:?original elf}
CAND=${2:?candidate elf}
HERE=$(cd "$(dirname "$0")" && pwd)
ACCEPTED=" _start call_gmon_start "
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
echo "=== pool_audit"
python3 "$HERE/pool_audit.py" "$ORIG" "$CAND" --verbose || fail=1

echo
echo "=== literal regressions"
python3 "$HERE/test_pool_audit_regressions.py" "$ORIG" "$CAND" || fail=1

echo
echo "sacd-parity: $([ $fail = 0 ] && echo PASS || echo FAIL)"
exit $fail
