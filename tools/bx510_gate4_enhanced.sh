#!/bin/sh
# bx510_gate4_enhanced.sh — the 5 GiB boundary-sentinel battery, run for
# the ENHANCED pairing: frozen original (0fdcefdb...) vs the release-next
# ENHANCED binary (9aa4b4b4..., B05-B09 fix stack). Production plan
# section 15 requires the 2/4 GiB+ sentinel coverage for the repaired
# tree, not just the frozen reference.
#
# Verbatim structure of bx510_gate4.sh (that runner is evidence-chained
# via its own sha256 in prior transcripts, so it stays pristine): only
# the release-side binary, its pinned SHA, the role name, the output
# prefix and the transcript provenance lines differ. The negative
# control, self-pairs, sentinel-identity check and raw-frame
# verification are unchanged.
#
# Why this matters for the enhanced tree: B07 (per-request sizing —
# the stale block_size fix) is exercised exactly by the tail sentinels
# (offsets past the encrypted area, first-read-in-tail cases); B08
# (checked decrypt) by every read; B09 (transactional OPEN) by the
# reconnect leg. Expected: wire behavior identical to the original on
# the healthy battery; the clamp result=6 at 1048494 is the pinned
# case (B07 changed no clamp arithmetic).
set -e
ORIG=~/sacd-verify/original/sacd_extract_160
ENH=~/reconstruct/release-next/sacd_extract_160_enhanced/sacd_extract_160_release
PIN_ORIG=0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45
PIN_ENH=9aa4b4b4585b742af9d26ad4007e6141b2ef397d299e5359f98b6442067b6792
RUNNER_SHA=$(sha256sum "$0" | cut -d' ' -f1)
STAMP=$(date +%Y%m%d-%H%M%S)
OUT=/tmp/gate4e-$STAMP
mkdir -p "$OUT"
echo "GATE4-ENHANCED: output directory $OUT"
echo "GATE4-ENHANCED: runner sha256=$RUNNER_SHA"

SO=$(sha256sum $ORIG | cut -d' ' -f1)
SR=$(sha256sum $ENH | cut -d' ' -f1)
echo "SHA original=$SO"
echo "SHA enhanced=$SR"
[ "$SO" = "$PIN_ORIG" ] || { echo "GATE4-ENHANCED: FATAL original SHA mismatch"; exit 1; }
[ "$SR" = "$PIN_ENH" ] || { echo "GATE4-ENHANCED: FATAL enhanced SHA mismatch"; exit 1; }
echo "GATE4-ENHANCED: pinned ELF hashes verified (role-asserted per run)"

~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -std=gnu99 -o /tmp/gclient /tmp/bx510_guest_client.c
~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -std=gnu99 -o /tmp/sacdstat /tmp/bx510_sacdstat.c

# VERIFY_ONLY=DIR: re-run every check against an existing evidence
# directory (no boots, no image build) — same reviewer path as gate4.
if [ -n "$VERIFY_ONLY" ]; then
  OUT="$VERIFY_ONLY"
  echo "GATE4-ENHANCED: VERIFY-ONLY against $OUT (no boots)"
else
# --- the 5 GiB image + negative variant + manifest ---
python3 /tmp/bx510_bigimg_gen.py "$OUT/big.bin" --manifest "$OUT/big.manifest.txt"
python3 - "$OUT/big.bin" "$OUT/big-corrupt.bin" <<'PY'
import shutil, sys
shutil.copyfile(sys.argv[1], sys.argv[2])
with open(sys.argv[2], "r+b") as f:
    f.seek(510 * 2048)
    f.write(b"\xAA" * 8)
print("negative image: SACDMTOC magic destroyed")
PY
IMG_ID=$(head -5 "$OUT/big.manifest.txt" | grep image_sha256 | cut -d' ' -f2)
echo "GATE4-ENHANCED: image identity sha256=$IMG_ID (5 GiB, 2621440 sectors, sparse)"
# regenerable: never leave multi-GB binaries in the evidence dir (the
# 100MB lesson; identity is SHA-recorded + rebuildable from the tool)
cp "$OUT/big.manifest.txt" "$OUT/manifest-kept.txt"
fi

cd ~/bx510-emu/emulator
cp /tmp/bx510_phase0_probe.py .

run() {
  ref="$1"; role="$2"; flags="$3"; img="$4"; log="$5"
  rc=0
  python3 bx510_phase0_probe.py \
    --qemu work/build/qemu-system-arm --images ../images \
    --role "$role" --reference "$ref" --shim /tmp/tmpredir.so --bgstart /tmp/bgstart \
    --stub /tmp/mod3/bx510_bdpvirt.ko --mkfixture /tmp/mkfixture \
    --gclient /tmp/gclient --lo_up /tmp/lo_up --sacdstat /tmp/sacdstat \
    --hdhost "$img" --hdmod /tmp/hdmod/bx510_hdhost.ko \
    --sr0-target /res/dev/hdhost \
    --timeout 900 $flags --rawdump --log "$log" > "$log.probe.out" 2>&1 || rc=$?
  if [ $rc -ne 0 ]; then
    echo "GATE4-ENHANCED: FATAL probe execution failure (role=$role, rc=$rc) — log: $log"
    tail -5 "$log.probe.out"
    exit 1
  fi
  {
    echo "# role=$role"
    echo "# reference=$ref"
    echo "# sha256($role)=$(sha256sum "$ref" | cut -d' ' -f1)"
    echo "# sha256(original)=$PIN_ORIG"
    echo "# sha256(enhanced)=$PIN_ENH"
    echo "# runner sha256=$RUNNER_SHA"
    echo "# image manifest sha256=$IMG_ID (bx510_bigimg_gen.py; 2621440 sectors)"
    echo "# rig: HDHOST transport, 5 GiB boundary-sentinel battery (enhanced pairing)"
    echo "# invocation: bx510_phase0_probe.py --role $role --reference $ref --hdhost <5GiB img> --sr0-target /res/dev/hdhost $flags"
  } > "$log.txt"
  sed -n '/P0_CLIENT_BEGIN/,/P0_CLIENT_END/p' "$log" | sed 's/port=[0-9]*/port=N/' >> "$log.txt"
  grep -m1 '^STAT:' "$log" >> "$log.txt" || { echo "GATE4-ENHANCED: FATAL no STAT record in $log"; exit 1; }
  [ -s "$log.txt" ] || { echo "GATE4-ENHANCED: FATAL empty transcript $log.txt"; exit 1; }
}

if [ -z "$VERIFY_ONLY" ]; then
run $ENH  enhanced "--corrupt-toc --big" "$OUT/big-corrupt.bin" $OUT/g-enh-neg.log
run $ORIG original "--corrupt-toc --big" "$OUT/big-corrupt.bin" $OUT/g-orig-neg.log
run $ORIG original "--big" "$OUT/big.bin" $OUT/g-orig.log
run $ENH  enhanced "--big" "$OUT/big.bin" $OUT/g-enh.log
run $ORIG original "--big" "$OUT/big.bin" $OUT/g-orig2.log
run $ENH  enhanced "--big" "$OUT/big.bin" $OUT/g-enh2.log
fi

echo "=== SENTINEL IDENTITY (guest dd through HDHOST vs generators) ==="
rcid=0
for lg in $OUT/g-*.log; do
  case "$lg" in
    *-neg.log) python3 /tmp/bx510_gate3_idcheck.py --big-corrupt "$lg" || rcid=1 ;;
    *)         python3 /tmp/bx510_gate3_idcheck.py --big "$lg" || rcid=1 ;;
  esac
done
[ $rcid -eq 0 ] && echo "SENTINEL IDENTITY: PASS" || echo "SENTINEL IDENTITY: FAIL"

echo "=== POSITIVE BATTERY + CROSS-BINARY DIFF (original vs enhanced) ==="
python3 /tmp/bx510_gate4_check.py positive $OUT/g-orig.log.txt $OUT/g-enh.log.txt || pc=$?
echo "=== NEGATIVE CONTROL (malformed TOC, 5 GiB variant) ==="
python3 /tmp/bx510_gate4_check.py negative $OUT/g-orig-neg.log.txt $OUT/g-enh-neg.log.txt || nc=$?
echo "=== SELF-PAIR original->original ==="
python3 /tmp/bx510_gate4_check.py positive $OUT/g-orig.log.txt $OUT/g-orig2.log.txt || sp1=$?
echo "=== SELF-PAIR enhanced->enhanced ==="
python3 /tmp/bx510_gate4_check.py positive $OUT/g-enh.log.txt $OUT/g-enh2.log.txt || sp2=$?
echo "=== RAW-FRAME VERIFICATION (positive) ==="
python3 /tmp/bx510_rawdecode.py --session-diff $OUT/g-orig.log $OUT/g-enh.log $OUT/g-orig $OUT/g-enh || rf1=$?
echo "=== RAW-FRAME VERIFICATION (negative) ==="
python3 /tmp/bx510_rawdecode.py --session-diff $OUT/g-orig-neg.log $OUT/g-enh-neg.log $OUT/g-orig-neg $OUT/g-enh-neg || rf2=$?

[ -z "$VERIFY_ONLY" ] && rm -f "$OUT"/big.bin "$OUT"/big-corrupt.bin
[ ${pc:-0} -eq 0 ] && [ ${nc:-0} -eq 0 ] && [ ${sp1:-0} -eq 0 ] && [ ${sp2:-0} -eq 0 ] \
  && [ ${rf1:-0} -eq 0 ] && [ ${rf2:-0} -eq 0 ] && [ $rcid -eq 0 ] \
  && echo "GATE4-ENHANCED: OVERALL VERDICT: PASS (battery, self-pairs, raw-frame, byte-identity)" \
  || echo "GATE4-ENHANCED: OVERALL VERDICT: FAIL"
echo "GATE4-ENHANCED: evidence in $OUT (pull before next run; image removed — SHA-recorded)"
