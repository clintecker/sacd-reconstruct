#!/bin/sh
# bx510_gate2.sh — the canonical in-guest validation runner (6 boots).
#
# Runs the full-system guest: for each of the four primary boots the
# pinned binary (role-asserted by the probe AND here) serves the
# synthetic disc through its own real sacd_read.ko; two additional
# self-pair boots give explicit original->original and
# release->release repeatability diffs. Positive gates (complete
# ordered sequence + computed payload hashes) must pass for BOTH
# binaries before any transcript diff; the malformed-TOC negative
# control must fail OPEN on both. Verdict requires all four
# comparisons to pass.
#
# Evidence per run: transcript headers carry the role, the run's own
# digest, BOTH pinned digests, and the exact invocation; the STAT
# record is appended to every transcript; --rawdump pushes the full
# both-direction wire capture (decode: bx510_rawdecode.py).
set -e
ORIG=~/sacd-verify/original/sacd_extract_160
REL=~/reconstruct/release/sacd_extract_160_release
PIN_ORIG=0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45
PIN_REL=e91720fbbbd592505bde6630843b0495ff82a93e40c0e427aaa70a081ff9ae22
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
  python3 bx510_phase0_probe.py \
    --qemu work/build/qemu-system-arm --images ../images \
    --role "$role" --reference "$ref" --shim /tmp/tmpredir.so --bgstart /tmp/bgstart \
    --stub /tmp/mod/bx510_bdpvirt.ko --mkfixture /tmp/mkfixture \
    --gclient /tmp/gclient --lo_up /tmp/lo_up --sacdstat /tmp/sacdstat \
    --timeout 900 $flags $raw --log "$log" >/dev/null 2>&1 || true
  {
    echo "# role=$role"
    echo "# reference=$ref"
    echo "# sha256($role)=$(sha256sum "$ref" | cut -d' ' -f1)"
    echo "# sha256(original)=$PIN_ORIG"
    echo "# sha256(release)=$PIN_REL"
    echo "# invocation: bx510_phase0_probe.py --role $role --reference $ref $flags $raw"
  } > "$log.txt"
  sed -n '/P0_CLIENT_BEGIN/,/P0_CLIENT_END/p' "$log" | sed 's/port=[0-9]*/port=N/' >> "$log.txt"
  grep -m1 '^STAT:' "$log" >> "$log.txt" || { echo "GATE: FATAL no STAT record in $log"; exit 1; }
}

run $ORIG original "--corrupt-toc" "--rawdump" /tmp/g-orig-neg.log
run $REL  release "--corrupt-toc" "--rawdump" /tmp/g-rel-neg.log
run $ORIG original "" "--rawdump" /tmp/g-orig.log
run $REL  release "" "--rawdump" /tmp/g-rel.log
run $ORIG original "" "" /tmp/g-orig2.log
run $REL  release "" "" /tmp/g-rel2.log

echo "=== POSITIVE GATE + CROSS-BINARY DIFF ==="
python3 /tmp/bx510_gate_check.py positive /tmp/g-orig.log.txt /tmp/g-rel.log.txt; pc=$?
echo "=== NEGATIVE CONTROL (malformed TOC) ==="
python3 /tmp/bx510_gate_check.py negative /tmp/g-orig-neg.log.txt /tmp/g-rel-neg.log.txt; nc=$?
echo "=== SELF-PAIR original->original ==="
python3 /tmp/bx510_gate_check.py positive /tmp/g-orig.log.txt /tmp/g-orig2.log.txt; sp1=$?
echo "=== SELF-PAIR release->release ==="
python3 /tmp/bx510_gate_check.py positive /tmp/g-rel.log.txt /tmp/g-rel2.log.txt; sp2=$?
[ $pc -eq 0 ] && [ $nc -eq 0 ] && [ $sp1 -eq 0 ] && [ $sp2 -eq 0 ] \
  && echo "GATE: OVERALL VERDICT: PASS" || echo "GATE: OVERALL VERDICT: FAIL"
