#!/bin/sh
# bx510_gate3.sh — HDHOST intermediate gate: the canonical 6-boot
# validation with the disc served through the HDHOST host-image
# interface instead of the guest tmpfs fixture.
#
# Staging insight (todo #9): the EXISTING fixture content and the
# EXISTING gate expectations are reused unchanged — only the transport
# changes (tmpfs file -> host-backed block node through hdhost.ko).
# If this gate passes with byte-identical results to the regression
# gate, the whole large-image transport is proven with known
# expectations; the 5 GiB round then changes only geometry.
#
# Per-run rig differences from gate2:
#   - the disc image is built VM-side by fixture_gen.py (byte-identity
#     vs the C guest fixture is ASSERTED in-guest per boot: same
#     sectors read from /res/dev/sr0 (C) and /res/dev/hdhost (PY))
#   - the daemon reads /dev/sr0 -> /res/dev/hdhost via
#     TMPREDIR_SR0_TARGET (tmpredir env knob)
#   - bdpvirt OddRead reads the same node via its target= module param
#   - the negative control corrupts the HOST image variant (the guest
#     mkfixture corrupts only the tmpfs fixture)
set -e
ORIG=~/sacd-verify/original/sacd_extract_160
REL=~/reconstruct/release/sacd_extract_160_release
PIN_ORIG=0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45
PIN_REL=e91720fbbbd592505bde6630843b0495ff82a93e40c0e427aaa70a081ff9ae22
RUNNER_SHA=$(sha256sum "$0" | cut -d' ' -f1)
STAMP=$(date +%Y%m%d-%H%M%S)
OUT=/tmp/gate3v-$STAMP
mkdir -p "$OUT"
echo "GATE3: output directory $OUT"
echo "GATE3: runner sha256=$RUNNER_SHA"

SO=$(sha256sum $ORIG | cut -d' ' -f1)
SR=$(sha256sum $REL | cut -d' ' -f1)
echo "SHA original=$SO"
echo "SHA release=$SR"
[ "$SO" = "$PIN_ORIG" ] || { echo "GATE3: FATAL original SHA mismatch"; exit 1; }
[ "$SR" = "$PIN_REL" ] || { echo "GATE3: FATAL release SHA mismatch"; exit 1; }
echo "GATE3: pinned ELF hashes verified (role-asserted per run)"

# --- build the guest-side pieces (tracked sources staged by make) ---
~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -std=gnu99 -o /tmp/gclient /tmp/bx510_guest_client.c
~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -std=gnu99 -o /tmp/mkfixture /tmp/bx510_mkfixture.c
~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -std=gnu99 -o /tmp/sacdstat /tmp/bx510_sacdstat.c
~/gnuarm/bin/arm-none-linux-gnueabi-gcc -shared -fPIC -O2 -Wall -std=gnu99 -o /tmp/tmpredir.so /tmp/bx510_tmpredir.c -ldl

# bdpvirt with the target= knob, native-armv6 recipe + bdpswap
mkdir -p /tmp/mod3
cp /tmp/bx510_bdpvirt.c /tmp/mod3/
echo 'obj-m := bx510_bdpvirt.o' > /tmp/mod3/Makefile
cd ~/sony-kernel/linux-2.6.35
export CROSS_COMPILE=~/gnuarm/bin/arm-none-linux-gnueabi-
make ARCH=arm M=/tmp/mod3 modules \
  EXTRA_CFLAGS="-U__LINUX_ARM_ARCH__ -D__LINUX_ARM_ARCH__=6 -march=armv6 -Wa,-march=armv6" \
  >/tmp/bdpbuild3.log 2>&1 || { grep -iE "error" /tmp/bdpbuild3.log | head -8; exit 1; }
~/gnuarm/bin/arm-none-linux-gnueabi-strings /tmp/mod3/bx510_bdpvirt.ko | grep vermagic
python3 /tmp/bdpswap.py /tmp/mod3/bx510_bdpvirt.ko bdpvirt_tail_marker_2

# --- host disc images (PY generator; the C fixture stays as in-guest
#     reference and byte-identity control) ---
python3 /tmp/fixture_gen.py "$OUT/hdfixture.bin"
python3 - "$OUT/hdfixture.bin" "$OUT/hdfixture-corrupt.bin" <<'PY'
import shutil, sys
shutil.copyfile(sys.argv[1], sys.argv[2])
# mirror of the C mkfixture negative control: destroy the SACDMTOC magic
with open(sys.argv[2], "r+b") as f:
    f.seek(510 * 2048)
    f.write(b"\xAA" * 8)
print("negative image: SACDMTOC magic destroyed")
PY
IMG_ID=$(sha256sum "$OUT/hdfixture.bin" | cut -d' ' -f1)
echo "GATE3: host image sha256=$IMG_ID (86200 sectors, sparse)"

cd ~/bx510-emu/emulator
cp /tmp/bx510_phase0_probe.py .

run() {
  ref="$1"; role="$2"; flags="$3"; raw="$4"; img="$5"; log="$6"
  rc=0
  python3 bx510_phase0_probe.py \
    --qemu work/build/qemu-system-arm --images ../images \
    --role "$role" --reference "$ref" --shim /tmp/tmpredir.so --bgstart /tmp/bgstart \
    --stub /tmp/mod3/bx510_bdpvirt.ko --mkfixture /tmp/mkfixture \
    --gclient /tmp/gclient --lo_up /tmp/lo_up --sacdstat /tmp/sacdstat \
    --hdhost "$img" --hdmod /tmp/hdmod/bx510_hdhost.ko \
    --sr0-target /res/dev/hdhost \
    --timeout 900 $flags $raw --log "$log" > "$log.probe.out" 2>&1 || rc=$?
  if [ $rc -ne 0 ]; then
    echo "GATE3: FATAL probe execution failure (role=$role, rc=$rc) — log: $log"
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
    echo "# host image sha256=$IMG_ID"
    echo "# rig: HDHOST transport (sr0 -> /res/dev/hdhost)"
    echo "# invocation: bx510_phase0_probe.py --role $role --reference $ref --hdhost <img> --sr0-target /res/dev/hdhost $flags $raw"
  } > "$log.txt"
  sed -n '/P0_CLIENT_BEGIN/,/P0_CLIENT_END/p' "$log" | sed 's/port=[0-9]*/port=N/' >> "$log.txt"
  grep -m1 '^STAT:' "$log" >> "$log.txt" || { echo "GATE3: FATAL no STAT record in $log"; exit 1; }
  [ -s "$log.txt" ] || { echo "GATE3: FATAL empty transcript $log.txt"; exit 1; }
}

run $REL  release "--corrupt-toc" "--rawdump" "$OUT/hdfixture-corrupt.bin" $OUT/g-rel-neg.log
run $ORIG original "--corrupt-toc" "--rawdump" "$OUT/hdfixture-corrupt.bin" $OUT/g-orig-neg.log
run $ORIG original "" "--rawdump" "$OUT/hdfixture.bin" $OUT/g-orig.log
run $REL  release "" "--rawdump" "$OUT/hdfixture.bin" $OUT/g-rel.log
run $ORIG original "" "" "$OUT/hdfixture.bin" $OUT/g-orig2.log
run $REL  release "" "" "$OUT/hdfixture.bin" $OUT/g-rel2.log

echo "=== BYTE-IDENTITY (C fixture vs PY host image, per boot) ==="
rcid=0
for lg in $OUT/g-*.log; do
  python3 /tmp/bx510_gate3_idcheck.py "$lg" || rcid=1
done
[ $rcid -eq 0 ] && echo "BYTE-IDENTITY: PASS (C generator == PY generator == host bytes, every boot)" \
  || echo "BYTE-IDENTITY: FAIL"

echo "=== POSITIVE GATE + CROSS-BINARY DIFF ==="
python3 /tmp/bx510_gate_check.py positive $OUT/g-orig.log.txt $OUT/g-rel.log.txt || pc=$?
echo "=== NEGATIVE CONTROL (malformed TOC, host image variant) ==="
python3 /tmp/bx510_gate_check.py negative $OUT/g-orig-neg.log.txt $OUT/g-rel-neg.log.txt || nc=$?
echo "=== SELF-PAIR original->original ==="
python3 /tmp/bx510_gate_check.py positive $OUT/g-orig.log.txt $OUT/g-orig2.log.txt || sp1=$?
echo "=== SELF-PAIR release->release ==="
python3 /tmp/bx510_gate_check.py positive $OUT/g-rel.log.txt $OUT/g-rel2.log.txt || sp2=$?
echo "=== RAW-FRAME VERIFICATION (positive) ==="
python3 /tmp/bx510_rawdecode.py --session-diff $OUT/g-orig.log $OUT/g-rel.log $OUT/g-orig $OUT/g-rel || rf1=$?
echo "=== RAW-FRAME VERIFICATION (negative) ==="
python3 /tmp/bx510_rawdecode.py --session-diff $OUT/g-orig-neg.log $OUT/g-rel-neg.log $OUT/g-orig-neg $OUT/g-rel-neg || rf2=$?

[ ${pc:-0} -eq 0 ] && [ ${nc:-0} -eq 0 ] && [ ${sp1:-0} -eq 0 ] && [ ${sp2:-0} -eq 0 ] \
  && [ ${rf1:-0} -eq 0 ] && [ ${rf2:-0} -eq 0 ] && [ $rcid -eq 0 ] \
  && echo "GATE3: OVERALL VERDICT: PASS (gates, self-pairs, raw-frame, byte-identity)" \
  || echo "GATE3: OVERALL VERDICT: FAIL"
# The host disc images are REGENERABLE artifacts (fixture_gen.py + the
# documented 8-byte corrupt patch) whose identity is recorded by SHA in
# every transcript header and the verdict — remove them from the
# evidence dir so pulls never drag multi-hundred-MB binaries into git
# (GitHub's 100MB limit rejected the first push of this gate's
# evidence; the 5GiB battery would be far worse).
rm -f "$OUT"/hdfixture.bin "$OUT"/hdfixture-corrupt.bin
echo "GATE3: evidence in $OUT (pull before next run; disc images removed — regenerable, SHA-recorded)"
