#!/bin/sh
# apply_tag_fixtures.sh — VM-side writer for the three FE tag-partition fixtures.
#
# Writes the page-0 fixture records built by decode/build_fe_tag_fixtures.py into
# the rig image's fe_power_curve / fe_test_data / fe_parameters partitions, at the
# offsets the image's OWN manifest.json declares. The offsets quoted in
# decode/fe-tags.md §4.2 are printed as a cross-check and never used for addressing.
#
# Nothing here fires an emulator: this only changes image bytes on disk.
#
# Stage + run from the Mac (repo root):
#   make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/fixtures/fe_power_curve.bin
#   make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/fixtures/fe_test_data.bin
#   make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/fixtures/fe_parameters.bin
#   make vm-script SCRIPT=evidence/bx510-guest/bdpdrv/decode/apply_tag_fixtures.sh
#
# Restore to the pre-fixture image (NOT done automatically — the parent owns runs):
#   cp /tmp/nand.img.bak-TAGFIX /tmp/images-fe/nand.img
set -eu

IMG=${IMG:-/tmp/images-fe/nand.img}
MANIFEST=${MANIFEST:-/tmp/images-fe/manifest.json}
BAK=${BAK:-/tmp/nand.img.bak-TAGFIX}
FIXDIR=${FIXDIR:-/tmp}
PYTHON=${PYTHON:-python3}

# Fixture file stem == manifest partition name; that is the only mapping this
# script relies on (the builder names its outputs after the partition).
PARTS="fe_power_curve fe_test_data fe_parameters"

die() { echo "FAIL: $*" >&2; exit 1; }

# manifest attribute for a partition, by name (offset | size)
part_attr() {
  "$PYTHON" -c 'import json,sys; m=json.load(open(sys.argv[1]));
print([p[sys.argv[3]] for p in m["partitions"] if p["name"]==sys.argv[2]][0])' \
    "$MANIFEST" "$1" "$2"
}

# fe-tags.md §4.2 offsets — cross-check only, never used as an address.
recipe_offset() {
  case $1 in
    fe_power_curve) echo 16777216 ;;   # 0x01000000
    fe_test_data)   echo 14680064 ;;   # 0x00e00000
    fe_parameters)  echo 15728640 ;;   # 0x00f00000
  esac
}

region_md5() {  # <offset> <len>
  dd if="$IMG" bs=1 skip="$1" count="$2" 2>/dev/null | md5sum | cut -d' ' -f1
}

[ -f "$IMG" ]      || die "image not found: $IMG"
[ -f "$MANIFEST" ] || die "manifest not found: $MANIFEST"
for name in $PARTS; do
  [ -f "$FIXDIR/$name.bin" ] || die "fixture not staged: $FIXDIR/$name.bin"
done

echo "== image state before =="
echo "image:       $IMG ($(wc -c < "$IMG") B)"
echo "image md5:   $(md5sum "$IMG" | cut -d' ' -f1)"

# ── backup (skip if it exists: the pre-fixture bytes must survive re-runs) ──
if [ -f "$BAK" ]; then
  echo "backup:      $BAK already exists — NOT overwritten"
  echo "backup md5:  $(md5sum "$BAK" | cut -d' ' -f1)"
else
  cp "$IMG" "$BAK"
  echo "backup:      wrote $BAK ($(wc -c < "$BAK") B, md5 $(md5sum "$BAK" | cut -d' ' -f1))"
fi
if [ "$(md5sum "$IMG" | cut -d' ' -f1)" = "$(md5sum "$BAK" | cut -d' ' -f1)" ]; then
  echo "state:       image still identical to backup (fixtures not applied before)"
else
  echo "state:       image already differs from backup (fixtures applied earlier; this run re-writes them)"
fi

# ── write ──────────────────────────────────────────────────────────────────
echo
echo "== write =="
for name in $PARTS; do
  off=$(part_attr "$name" offset)
  psize=$(part_attr "$name" size)
  fix="$FIXDIR/$name.bin"
  fsize=$(wc -c < "$fix")
  [ "$psize" -ge "$fsize" ] || die "$name: fixture ($fsize B) does not fit partition ($psize B)"
  roff=$(recipe_offset "$name")
  match=SAME
  [ "$off" = "$roff" ] || match=DIFFERS
  echo "$name: manifest offset 0x$(printf '%08x' "$off") (fe-tags.md §4.2: 0x$(printf '%08x' "$roff") — $match), partition 0x$(printf '%x' "$psize") B, fixture 0x$(printf '%x' "$fsize") B"
  dd if="$fix" of="$IMG" bs=1 seek="$off" conv=notrunc 2>/dev/null \
    || die "$name: dd write failed at offset 0x$(printf '%08x' "$off")"
done

# ── verification: read the bytes back out of the image and compare ──────────
echo
echo "== verify (dd readback vs fixture) =="
rc=0
for name in $PARTS; do
  off=$(part_attr "$name" offset)
  fix="$FIXDIR/$name.bin"
  fsize=$(wc -c < "$fix")
  want=$(md5sum "$fix" | cut -d' ' -f1)
  got=$(region_md5 "$off" "$fsize")
  if [ "$want" = "$got" ]; then verdict=OK; else verdict=MISMATCH; rc=1; fi
  echo "$name @ 0x$(printf '%08x' "$off") len 0x$(printf '%x' "$fsize")"
  echo "  fixture md5 $want"
  echo "  image   md5 $got  $verdict"
  echo "  header: $(dd if="$IMG" bs=1 skip="$off" count=16 2>/dev/null | od -An -tx1 | tr -s ' ')"
done

# ── the three region md5s, restated for the record ─────────────────────────
echo
echo "== region md5s in $IMG =="
for name in $PARTS; do
  off=$(part_attr "$name" offset)
  fsize=$(wc -c < "$FIXDIR/$name.bin")
  echo "$name 0x$(printf '%08x' "$off")+0x$(printf '%x' "$fsize") $(region_md5 "$off" "$fsize")"
done

# Informational: today the FA table reaches FE DRAM from fe_bin_1+0xFE000 via the
# driver's fallback (fe-tags.md §1.2). Recorded so the fixture's DRAM 0x11000 delta
# is measurable rather than assumed.
fb1=$(part_attr fe_bin_1 offset)
echo
echo "== reference: embedded FA table in fe_bin_1 (fe-tags.md §1.2 fallback source) =="
echo "fe_bin_1+0xfe000 md5 $(region_md5 $((fb1 + 0xFE000)) 8192)"

echo
echo "image md5 after: $(md5sum "$IMG" | cut -d' ' -f1)"
[ "$rc" -eq 0 ] || die "one or more regions did not verify"
echo "APPLIED — three fixtures verified in place; backup at $BAK"
