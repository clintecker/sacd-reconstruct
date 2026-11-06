#!/bin/sh
# bx510_gate4.sh — the 5 GiB boundary-sentinel battery (final
# large-image validation, docs/large-image-interface.md).
#
# Mirrors gate3's structure (HDHOST transport, role-asserted boots,
# byte-identity controls, raw-frame verification) with the big
# geometry: 2,621,440 sectors; sentinels straddling the 2 GiB and
# 4 GiB byte-offset boundaries; clamp at the new track range
# (1048500); the client runs its "big" step set; validation by
# bx510_gate4_check.py. Negative control destroys the SACDMTOC magic
# on the big image variant.
#
# Acceptance condition under test (team round-3): both pinned daemons
# serve independently verified sectors from a large host-backed image
# through BOTH read paths, without staging the full image in guest RAM.
set -e
ORIG=~/the verification tree/original/sacd_extract_160
REL=~/reconstruct/release/sacd_extract_160_release
PIN_ORIG=0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45
PIN_REL=e91720fbbbd592505bde6630843b0495ff82a93e40c0e427aaa70a081ff9ae22
RUNNER_SHA=$(sha256sum "$0" | cut -d' ' -f1)
STAMP=$(date +%Y%m%d-%H%M%S)
OUT=/tmp/gate4v-$STAMP
mkdir -p "$OUT"
echo "GATE4: output directory $OUT"
echo "GATE4: runner sha256=$RUNNER_SHA"

SO=$(sha256sum $ORIG | cut -d' ' -f1)
SR=$(sha256sum $REL | cut -d' ' -f1)
echo "SHA original=$SO"
echo "SHA release=$SR"
[ "$SO" = "$PIN_ORIG" ] || { echo "GATE4: FATAL original SHA mismatch"; exit 1; }
[ "$SR" = "$PIN_REL" ] || { echo "GATE4: FATAL release SHA mismatch"; exit 1; }
echo "GATE4: pinned ELF hashes verified (role-asserted per run)"

~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -std=gnu99 -o /tmp/gclient /tmp/bx510_guest_client.c
~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -std=gnu99 -o /tmp/sacdstat /tmp/bx510_sacdstat.c

# VERIFY_ONLY=DIR: re-run every check against an existing evidence
# directory (no boots, no image build) — the evidence-reviewer path:
# the maintainers can re-verify saved transcripts + captures without the VM.
if [ -n "$VERIFY_ONLY" ]; then
  OUT="$VERIFY_ONLY"
  echo "GATE4: VERIFY-ONLY against $OUT (no boots)"
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
echo "GATE4: image identity sha256=$IMG_ID (5 GiB, 2621440 sectors, sparse)"
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
    echo "GATE4: FATAL probe execution failure (role=$role, rc=$rc) — log: $log"
    tail -5 "$log.probe.out"
    exit 1
  fi
  {
    echo "# role=$role"
    echo "# reference=$ref"
    echo "# sha256($role)=$(sha256sum "$ref" | cut -d' ' -f1)"
    echo "# sha256(original)=$PIN_ORIG"
    echo "# sha256(release)=$PIN_REL"
    echo "# runner sha256=$RUNNER_SHA"
    echo "# image manifest sha256=$IMG_ID (bx510_bigimg_gen.py; 2621440 sectors)"
    echo "# rig: HDHOST transport, 5 GiB boundary-sentinel battery"
    echo "# invocation: bx510_phase0_probe.py --role $role --reference $ref --hdhost <5GiB img> --sr0-target /res/dev/hdhost $flags"
  } > "$log.txt"
  sed -n '/P0_CLIENT_BEGIN/,/P0_CLIENT_END/p' "$log" | sed 's/port=[0-9]*/port=N/' >> "$log.txt"
  grep -m1 '^STAT:' "$log" >> "$log.txt" || { echo "GATE4: FATAL no STAT record in $log"; exit 1; }
  [ -s "$log.txt" ] || { echo "GATE4: FATAL empty transcript $log.txt"; exit 1; }
}

# the client "big" mode is wired via the probe's gclient args; the probe
# passes them through its client invocation. The battery boots:
if [ -z "$VERIFY_ONLY" ]; then
run $REL  release "--corrupt-toc --big" "$OUT/big-corrupt.bin" $OUT/g-rel-neg.log
run $ORIG original "--corrupt-toc --big" "$OUT/big-corrupt.bin" $OUT/g-orig-neg.log
run $ORIG original "--big" "$OUT/big.bin" $OUT/g-orig.log
run $REL  release "--big" "$OUT/big.bin" $OUT/g-rel.log
run $ORIG original "--big" "$OUT/big.bin" $OUT/g-orig2.log
run $REL  release "--big" "$OUT/big.bin" $OUT/g-rel2.log
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

echo "=== POSITIVE BATTERY + CROSS-BINARY DIFF ==="
python3 /tmp/bx510_gate4_check.py positive $OUT/g-orig.log.txt $OUT/g-rel.log.txt || pc=$?
echo "=== NEGATIVE CONTROL (malformed TOC, 5 GiB variant) ==="
python3 /tmp/bx510_gate4_check.py negative $OUT/g-orig-neg.log.txt $OUT/g-rel-neg.log.txt || nc=$?
echo "=== SELF-PAIR original->original ==="
python3 /tmp/bx510_gate4_check.py positive $OUT/g-orig.log.txt $OUT/g-orig2.log.txt || sp1=$?
echo "=== SELF-PAIR release->release ==="
python3 /tmp/bx510_gate4_check.py positive $OUT/g-rel.log.txt $OUT/g-rel2.log.txt || sp2=$?
echo "=== RAW-FRAME VERIFICATION (positive) ==="
python3 /tmp/bx510_rawdecode.py --session-diff $OUT/g-orig.log $OUT/g-rel.log $OUT/g-orig $OUT/g-rel || rf1=$?
echo "=== RAW-FRAME VERIFICATION (negative) ==="
python3 /tmp/bx510_rawdecode.py --session-diff $OUT/g-orig-neg.log $OUT/g-rel-neg.log $OUT/g-orig-neg $OUT/g-rel-neg || rf2=$?

[ -z "$VERIFY_ONLY" ] && rm -f "$OUT"/big.bin "$OUT"/big-corrupt.bin
[ ${pc:-0} -eq 0 ] && [ ${nc:-0} -eq 0 ] && [ ${sp1:-0} -eq 0 ] && [ ${sp2:-0} -eq 0 ] \
  && [ ${rf1:-0} -eq 0 ] && [ ${rf2:-0} -eq 0 ] && [ $rcid -eq 0 ] \
  && echo "GATE4: OVERALL VERDICT: PASS (battery, self-pairs, raw-frame, byte-identity)" \
  || echo "GATE4: OVERALL VERDICT: FAIL"
echo "GATE4: evidence in $OUT (pull before next run; image removed — SHA-recorded)"
