#!/bin/sh
# bx510_gate2.sh — canonical in-guest validation runner (6 boots + raw-frame
# verification, team-review hardened).
#
# Improvements (virtual-drive team review round 3):
#   - FRESH OUTPUT DIRECTORY per invocation (timestamped): earlier valid
#     evidence can never be silently overwritten or confused with a new
#     run's files.
#   - NO blanket `|| true`: the probe exits nonzero on EXECUTION failure
#     (P0_FINISHED never appeared). An expected negative protocol
#     response lives inside a completed run; a dead boot is now FATAL.
#     Transcripts must be non-empty.
#   - RAW-FRAME VERIFICATION is part of the verdict: decode +
#     integrity-verify both captures (md5s vs in-transcript values),
#     then require the deterministic session bytes (through CLOSE#2)
#     and the complete request streams to be IDENTICAL before OVERALL
#     PASS may print.
#   - The runner's own SHA-256 is printed with the invocation, and every
#     transcript header carries role, both pinned ELF digests, and the
#     exact probe invocation. Stage this file from the tracked source
#     (tools/bx510_gate2.sh) - never hand-edit a VM copy.
set -e
ORIG=~/sacd-verify/original/sacd_extract_160
REL=~/reconstruct/release/sacd_extract_160_release
PIN_ORIG=0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45
PIN_REL=e91720fbbbd592505bde6630843b0495ff82a93e40c0e427aaa70a081ff9ae22
RUNNER_SHA=$(sha256sum "$0" | cut -d' ' -f1)
STAMP=$(date +%Y%m%d-%H%M%S)
OUT=/tmp/gatev-$STAMP
mkdir -p "$OUT"
echo "GATE: output directory $OUT"
echo "GATE: runner sha256=$RUNNER_SHA"

SO=$(sha256sum $ORIG | cut -d' ' -f1)
SR=$(sha256sum $REL | cut -d' ' -f1)
echo "SHA original=$SO"
echo "SHA release=$SR"
[ "$SO" = "$PIN_ORIG" ] || { echo "GATE: FATAL original SHA mismatch"; exit 1; }
[ "$SR" = "$PIN_REL" ] || { echo "GATE: FATAL release SHA mismatch"; exit 1; }
echo "GATE: pinned ELF hashes verified (role-asserted per run)"

~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -std=gnu99 -o /tmp/gclient /tmp/bx510_guest_client.c
~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -std=gnu99 -o /tmp/mkfixture /tmp/bx510_mkfixture.c
~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -std=gnu99 -o /tmp/sacdstat /tmp/bx510_sacdstat.c
cd ~/bx510-emu/emulator
cp /tmp/bx510_phase0_probe.py .

run() {
  ref="$1"; role="$2"; flags="$3"; raw="$4"; log="$5"
  rc=0
  python3 bx510_phase0_probe.py \
    --qemu work/build/qemu-system-arm --images ../images \
    --role "$role" --reference "$ref" --shim /tmp/tmpredir.so --bgstart /tmp/bgstart \
    --stub /tmp/mod/bx510_bdpvirt.ko --mkfixture /tmp/mkfixture \
    --gclient /tmp/gclient --lo_up /tmp/lo_up --sacdstat /tmp/sacdstat \
    --timeout 900 $flags $raw --log "$log" > "$log.probe.out" 2>&1 || rc=$?
  if [ $rc -ne 0 ]; then
    echo "GATE: FATAL probe execution failure (role=$role, rc=$rc) — log: $log"
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
    echo "# invocation: bx510_phase0_probe.py --role $role --reference $ref $flags $raw"
  } > "$log.txt"
  sed -n '/P0_CLIENT_BEGIN/,/P0_CLIENT_END/p' "$log" | sed 's/port=[0-9]*/port=N/' >> "$log.txt"
  grep -m1 '^STAT:' "$log" >> "$log.txt" || { echo "GATE: FATAL no STAT record in $log"; exit 1; }
  [ -s "$log.txt" ] || { echo "GATE: FATAL empty transcript $log.txt"; exit 1; }
}

run $ORIG original "--corrupt-toc" "--rawdump" $OUT/g-orig-neg.log
run $REL  release "--corrupt-toc" "--rawdump" $OUT/g-rel-neg.log
run $ORIG original "" "--rawdump" $OUT/g-orig.log
run $REL  release "" "--rawdump" $OUT/g-rel.log
run $ORIG original "" "" $OUT/g-orig2.log
run $REL  release "" "" $OUT/g-rel2.log

pc=0; nc=0; sp1=0; sp2=0; rf1=0; rf2=0
echo "=== POSITIVE GATE + CROSS-BINARY DIFF ==="
python3 /tmp/bx510_gate_check.py positive $OUT/g-orig.log.txt $OUT/g-rel.log.txt || pc=$?
echo "=== NEGATIVE CONTROL (malformed TOC) ==="
python3 /tmp/bx510_gate_check.py negative $OUT/g-orig-neg.log.txt $OUT/g-rel-neg.log.txt || nc=$?
echo "=== SELF-PAIR original->original ==="
python3 /tmp/bx510_gate_check.py positive $OUT/g-orig.log.txt $OUT/g-orig2.log.txt || sp1=$?
echo "=== SELF-PAIR release->release ==="
python3 /tmp/bx510_gate_check.py positive $OUT/g-rel.log.txt $OUT/g-rel2.log.txt || sp2=$?
echo "=== RAW-FRAME VERIFICATION (positive) ==="
python3 /tmp/bx510_rawdecode.py --session-diff $OUT/g-orig.log $OUT/g-rel.log $OUT/g-orig $OUT/g-rel || rf1=$?
echo "=== RAW-FRAME VERIFICATION (negative) ==="
python3 /tmp/bx510_rawdecode.py --session-diff $OUT/g-orig-neg.log $OUT/g-rel-neg.log $OUT/g-orig-neg $OUT/g-rel-neg || rf2=$?

[ $pc -eq 0 ] && [ $nc -eq 0 ] && [ $sp1 -eq 0 ] && [ $sp2 -eq 0 ] \
  && [ $rf1 -eq 0 ] && [ $rf2 -eq 0 ] \
  && echo "GATE: OVERALL VERDICT: PASS (gates, self-pairs, raw-frame verification)" \
  || echo "GATE: OVERALL VERDICT: FAIL"
echo "GATE: evidence in $OUT (pull before next run)"
