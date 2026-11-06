#!/bin/sh
# bx510_hdsmoke.sh — HDHOST end-to-end smoke check (VM-side).
#
# Invoked via: make sacd-hdhost-smoke  (which stages every input first).
# Validates the QEMU device model (mt8560-hdhost.c) + guest block driver
# (bx510_hdhost.c) + host image plumbing end to end, before any daemon
# work: a 16 MiB image with five patterned sentinel sectors is served
# through the guest block node /dev/hdhost; the guest dd+md5 of each
# sentinel must equal the host-side expectation, and a read past capacity
# must FAIL (EIO), never a zero-filled success.
#
# Inputs (staged by make sacd-hdhost-smoke):
#   /tmp/bx510_phase0_probe.py     tracked probe (copied into the
#                                  emulator dir before the run — the
#                                  stale-probe lesson)
#   /tmp/hdmod/bx510_hdhost.ko     built by make sacd-hdhost-mod
#   the standard battery binaries  (/tmp/gclient, /tmp/mkfixture, ...)
set -e
OUT=/tmp/hdsmoke-$(date +%Y%m%d-%H%M%S)
mkdir -p "$OUT"

# 1. smoke image with host-side expectations (sparse; patterned sentinels)
python3 - "$OUT/img.bin" "$OUT/expect.txt" <<'PY'
import hashlib, sys
LSN = 2048
TOTAL = 8192          # 16 MiB
path, expect = sys.argv[1], sys.argv[2]
exp_lines = []
with open(path, 'wb') as f:
    f.truncate(TOTAL * LSN)
    def put(lsn, salt):
        f.seek(lsn * LSN)
        x = salt
        buf = bytearray(LSN)
        for i in range(0, LSN, 4):
            x ^= (x << 13) & 0xFFFFFFFF; x ^= x >> 17; x ^= (x << 5) & 0xFFFFFFFF
            buf[i:i+4] = x.to_bytes(4, 'little')
        f.write(buf)
        exp_lines.append(f"sector {lsn} md5 {hashlib.md5(bytes(buf)).hexdigest()}")
    put(0, 0x11111111)
    put(10, 0x22222222)
    put(5000, 0x33333333)
    put(8190, 0x44444444)
    put(8191, 0x55555555)
# the guest reads 8190 with count=2 (multi-sector transaction): its
# expectation is the CONCATENATION of the two sectors — replace the
# single-sector entry for 8190 IN PLACE (guest command order is
# 0, 10, 5000, 8190+count2, 8191)
import hashlib as _h
two = open(path, 'rb'); two.seek(8190 * 2048)
concat = "sector 8190+8191 md5 " + _h.md5(two.read(4096)).hexdigest()
exp_lines = [concat if l.startswith("sector 8190 ") else l
             for l in exp_lines]
open(expect, 'w').write("\n".join(exp_lines) + "\n")
print("HOST image:", path, TOTAL * LSN, "bytes,", TOTAL, "LSNs")
PY

# 2. boot the guest with HDHOST enabled (standard battery + HDHOST checks)
cd ~/bx510-emu/emulator
cp /tmp/bx510_phase0_probe.py .        # the stale-probe lesson, made explicit
python3 bx510_phase0_probe.py \
  --qemu work/build/qemu-system-arm --images ../images \
  --role original --reference ~/the verification tree/original/sacd_extract_160 \
  --shim /tmp/tmpredir.so --bgstart /tmp/bgstart \
  --stub /tmp/mod/bx510_bdpvirt.ko --mkfixture /tmp/mkfixture \
  --gclient /tmp/gclient --lo_up /tmp/lo_up --sacdstat /tmp/sacdstat \
  --hdhost "$OUT/img.bin" --hdmod /tmp/hdmod/bx510_hdhost.ko \
  --log "$OUT/uart.log" > "$OUT/probe.out" 2>&1 \
  || { echo "SMOKE: FAIL — probe execution failure"; tail -8 "$OUT/probe.out"; exit 1; }

# 3. verdict: guest sentinel md5s must equal host expectations, in order;
#    the past-capacity read must have failed.
python3 - "$OUT" <<'PY'
import re, sys
out = sys.argv[1]
expect = open(out + "/expect.txt").read().split("\n")
log = open(out + "/uart.log", errors="replace").read()
ok = True
# guest results: the md5sum lines following each sentinel dd, in order
guest_md5s = [m.group(1) for m in re.finditer(
    r"^([0-9a-f]{32})  -", re.search(
        r"P0_HD=\d(.*?)P0_HDDONE", log, re.S).group(1), re.M)]
host_md5s = [l.rsplit(None, 1)[1] for l in expect if l.strip()]
labels = [l.split()[1] for l in expect if l.strip()]
if len(guest_md5s) != 5:
    print(f"SMOKE: FAIL — expected 5 guest md5 lines, got {len(guest_md5s)}")
    sys.exit(1)
for label, want, got in zip(labels, host_md5s, guest_md5s):
    status = "OK " if want == got else "BAD"
    if want != got:
        ok = False
    print(f"  {status} sector {label}: host {want} guest {got}")
# beyond-capacity read must fail (EIO), never zero-filled success
oob = re.search(r"P0_HDOOB=(\d+)", log)
if oob is None or oob.group(1) == "0":
    print("  OOB read: DID NOT FAIL (or marker missing) — zero-filled success is a defect")
    ok = False
else:
    print(f"  OOB read: failed as required (rc={oob.group(1)})")
print("SMOKE: " + ("PASS" if ok else "FAIL"))
sys.exit(0 if ok else 1)
PY
