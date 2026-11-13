#!/usr/bin/env python3
"""Byte provenance for the three FE tag partitions in nand.img.

Reads the raw image (never mounts it) and reports, for each partition the
driver binds by name:
  - the first 32 bytes at the partition offset (what the tag check sees)
  - every offset in the whole image where the observed mismatch byte string
    occurs (tells us whether the read landed in the right partition at all)
"""
import sys

IMG = "/tmp/images-fe/nand.img"
PARTS = {
    "fe_bin_1":      0x00A00000,
    "fe_bin_2":      0x00C00000,
    "fe_test_data":  0x00E00000,
    "fe_parameters": 0x00F00000,
    "fe_power_curve": 0x01000000,
}
# observed mismatch payloads, from the C95 UART (%c%c%c%c of the read buffer)
OBSERVED = {
    "SocReadPowerCurve": bytes([0xB6, 0x7A, 0x75, 0x2C]),
    "SocReadFaTable":    b"shim",
    "SocReadParameter":  b"\xff\xff\xff\xff",
}

def main():
    img = open(IMG, "rb").read()
    print(f"image {IMG} size={len(img):#x}")
    for name, off in PARTS.items():
        head = img[off:off + 32]
        uniq = len(set(img[off:off + 0x100000]))
        print(f"\n{name} @ {off:#010x}: head={head.hex()} "
              f"distinct-bytes-in-1MiB={uniq}")
    for fn, pat in OBSERVED.items():
        hits = []
        start = 0
        while True:
            i = img.find(pat, start)
            if i < 0:
                break
            hits.append(i)
            start = i + 1
        print(f"\n{fn} observed={pat.hex()} ({pat!r}) occurrences={len(hits)}")
        for h in hits[:8]:
            owner = None
            for name, off in sorted(PARTS.items(), key=lambda kv: -kv[1]):
                if h >= off:
                    owner = f"{name}+{h - off:#x}"
                    break
            print(f"   {h:#010x}  ({owner})")

if __name__ == "__main__":
    main()
