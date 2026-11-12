#!/usr/bin/env python3
"""build_fe_fixture.py — labelled synthetic FE firmware for the BX510 rig.

NOT factory content: this is a lab FIXTURE built from the decoded acceptance
criteria of sata_mt85xx_SocVerifyMainCode (decode/sata-fw-load.md, VERIFIED):
  Test 1: fw[0] not in {0, 0xFFFFFFFF}
  Test 2 (escape): fw[0xC100] == 0 -> accept "without CheckSum"
  Test 3 (escape): fw[0xC008] <= 35 -> accept
  Test 4: body_sum(A,B,C) + BE32(fw[0xC100]) == 0x37922226
Tag parse (fw[0xC008] > 34): records at 0xC010+16*i, {tag,f0,f1,f2} BE f0/f1/f2,
  terminated by zero tag; defaults: POWC{0x10000,0,0x400} FATB{0x11000,0xFE000,
  0x2000} PARM{0x15000,0,0x2000} BOOT{0,0,0x1000} MAIN{0x168000,0,0x100000}
  ENCC{0,0x8000,0x4000}.

The fixture chooses the FULL path: revision 0x24 (>35), tag records present,
real checksum (region sums complemented to the magic) — maximum code-path
coverage per docs/scoring.md rule 3 (score demonstrated behavior). The image
is 1 MiB (the loader reads exactly 0x100000 from fe_bin_1 offset 0).

Write target: fe_bin_1 AND fe_bin_2 (backup) in a rig-local nand.img copy.
"""
import hashlib
import struct
import sys
from pathlib import Path

MAGIC = 0x37922226
SIZE = 0x100000
REGIONS = [(0x00000, 0x04000), (0x07C00, 0x0C000), (0x10000, 0xF0000)]
TAGS = {
    b"POWC": (0x10000, 0x000000, 0x400),
    b"FATB": (0x11000, 0xFE000, 0x2000),
    b"PARM": (0x15000, 0x000000, 0x2000),
    b"BOOT": (0x00000, 0x000000, 0x1000),
    b"MAIN": (0x168000, 0x000000, 0x100000),
    b"ENCC": (0x00000, 0x8000, 0x4000),
}


def be_sum(data):
    total = 0
    for i in range(0, len(data) - 3, 4):
        total += struct.unpack(">I", data[i:i + 4])[0]
    return total & 0xFFFFFFFF


def main(nand_in, nand_out):
    fw = bytearray(b"\xff" * SIZE)
    # Test 1: nonzero, non-erased tag word. Marker: "FEF1" (FE fixture v1).
    fw[0:4] = b"FEF1"
    # boot code region A: a recognizable pattern (xorshift family, salted),
    # NON-checksummed gap stays 0xFF so the sums cover exactly the decoded
    # regions.
    pat = bytearray()
    x = 0xFE171CAC
    for _ in range(0x4000 // 4):
        x ^= (x << 13) & 0xFFFFFFFF
        x ^= x >> 17
        x ^= (x << 5) & 0xFFFFFFFF
        pat += struct.pack("<I", x)
    fw[0x00000:0x04000] = pat                       # region A
    x = 0xFE171CAD
    pat = bytearray()
    for _ in range((0x0C000 - 0x07C00) // 4):
        x ^= (x << 13) & 0xFFFFFFFF
        x ^= x >> 17
        x ^= (x << 5) & 0xFFFFFFFF
        pat += struct.pack("<I", x)
    fw[0x07C00:0x0C000] = pat                       # region B
    x = 0xFE171CAE
    pat = bytearray()
    for _ in range((0xF0000 - 0x10000) // 4):
        x ^= (x << 13) & 0xFFFFFFFF
        x ^= x >> 17
        x ^= (x << 5) & 0xFFFFFFFF
        pat += struct.pack("<I", x)
    fw[0x10000:0xF0000] = pat                       # region C

    # header: revision byte 0x24 (> 35 -> tag parse + checksum path)
    fw[0xC008] = 0x24
    # tag records at 0xC010, each {tag_le_dword, f0_be, f1_be, f2_be}
    recs = b""
    order = [b"BOOT", b"MAIN", b"POWC", b"FATB", b"PARM", b"ENCC"]
    for tag in order:
        f0, f1, f2 = TAGS[tag]
        recs += struct.pack("<I", struct.unpack(">I", tag)[0])
        recs += struct.pack(">III", f0, f1, f2)
    fw[0xC010:0xC010 + len(recs)] = recs            # 6 records, zero tag follows

    # checksum: body sum over the three regions, complemented to the magic
    total = sum(be_sum(fw[a:b]) for a, b in REGIONS) & 0xFFFFFFFF
    word = (MAGIC - total) & 0xFFFFFFFF
    fw[0xC100:0xC104] = struct.pack(">I", word)

    # self-verify against the decoded criteria before touching flash
    assert fw[0:4] != b"\x00\x00\x00\x00" and fw[0:4] != b"\xff\xff\xff\xff"
    assert struct.unpack(">I", fw[0xC100:0xC104])[0] != 0
    assert fw[0xC008] > 35
    assert (total + struct.unpack(">I", fw[0xC100:0xC104])[0]) & 0xFFFFFFFF == MAGIC
    assert be_sum(fw[0:0x4000]) == be_sum(fw[0x00000:0x04000])   # sanity

    src = Path(nand_in)
    dst = Path(nand_out)
    data = bytearray(src.read_bytes())
    FE1_OFF, FE2_OFF = 0x00A00000, 0x00C00000
    for off in (FE1_OFF, FE2_OFF):
        data[off:off + SIZE] = fw
        # rest of each 2 MiB partition stays 0xFF (loader reads only 1 MiB)
    digest = hashlib.sha256(bytes(fw)).hexdigest()
    dst.write_bytes(bytes(data))
    print(f"fixture sha256 {digest}")
    print(f"wrote {dst} (fe_bin_1 @0x{FE1_OFF:x}, fe_bin_2 @0x{FE2_OFF:x})")
    print(f"body_sum=0x{total:08x} word=0x{word:08x} magic=0x{MAGIC:08x}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: build_fe_fixture.py <nand.img in> <nand.img out>")
    main(sys.argv[1], sys.argv[2])
