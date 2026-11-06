#!/usr/bin/env python3
"""bx510_font_carve.py — carve the TrueType out of Sony's /res/font.bin.

font.bin is a 12-byte wrapper followed by a normal sfnt (TrueType) whose table
offsets are relative to that embedded start: version 0x00010000, tables
FFTM (Sony's own), GDEF/GPOS/GSUB, OS/2, cmap, glyf, head, hhea, hmtx, loca...

Deterministic: refuses to write unless the embedded table directory parses.

Usage: bx510_font_carve.py <font.bin> <out.ttf>
"""
import struct
import sys


def carve(src, dst):
    d = open(src, "rb").read()
    off = None
    for i in range(0, min(len(d), 4096)):
        if d[i:i + 4] != b"\x00\x01\x00\x00":
            continue
        n = struct.unpack(">H", d[i + 4:i + 6])[0]
        if not (1 <= n <= 64):
            continue
        ok = 0
        for t in range(min(n, 8)):
            tag = d[i + 12 + t * 16:i + 16 + t * 16]
            if len(tag) == 4 and all(32 <= c < 127 for c in tag):
                ok += 1
        if ok >= 5:
            off = i
            break
    if off is None:
        raise SystemExit("no embedded sfnt found")
    ttf = d[off:]
    n = struct.unpack(">H", ttf[4:6])[0]
    for t in range(n):
        tag = ttf[12 + t * 16:16 + t * 16].decode("latin1")
        _ck, o, l = struct.unpack(">III", ttf[16 + t * 16:28 + t * 16])
        if o + l > len(ttf):
            raise SystemExit("table %s overruns the carved image" % tag)
    open(dst, "wb").write(ttf)
    print("embedded sfnt at %d, %d tables, %d bytes -> %s" % (off, n, len(ttf), dst))


if __name__ == "__main__":
    carve(sys.argv[1], sys.argv[2])
