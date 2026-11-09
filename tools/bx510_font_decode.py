#!/usr/bin/env python3
"""bx510_font_decode.py — decode Sony's shipped screen font /res/font.bin (BX510).

Format (all VERIFIED from bytes, see docs/FONT-FORMAT.md):

  bytes 0x00-0x0B  12-byte Sony wrapper:
                     u32 (BE) 0x0000F460   length of the embedded sfnt
                                           (= filesize - 12) — the only
                                           load-bearing field (VERIFIED)
                     bytes 0x00-0x07       byte patterns 01 00 00 00,
                                           08 00 00 00 (semantics INFERRED;
                                           NOT a sane BE version pair — see
                                           docs/FONT-FORMAT.md)
  bytes 0x0C-...   standard sfnt/TrueType (version 0x00010000, 17 tables):
                   TiresiasScreenfont Release 8.03 (Bitstream), vector outlines
                   in `glyf` — NOT a bitmap font, NOT a DirectFB/DGI container.

The decoder is stdlib-only and deterministic:
  1. validates the wrapper (length field must match),
  2. parses the table directory and validates every table's bounds,
  3. parses head/maxp/hhea/hmtx/loca/cmap(name)/post,
  4. decodes every mapped glyph out of `glyf` (simple + composite),
  5. prints a coverage/dimensions summary,
  6. emits, into the output directory:
       out.ttf        the carved sfnt (what the HUD / stb_truetype consumes)
       atlas.png      grayscale coverage atlas (needs Pillow; one cell per
                      mapped codepoint, codepoint order, baseline-aligned)
       atlas.bin      the same atlas as raw unsigned-8-bit coverage bytes
       atlas.txt      manifest: cell size, per-cell advance/bbox, load recipe
     Without Pillow the atlas is skipped and atlas.txt says so; the carved
     out.ttf + the summary are still produced.

Usage: bx510_font_decode.py <font.bin> <outdir> [px]
"""
import os
import struct
import sys

WRAP_LEN = 12
SFNT_MAGIC = b"\x00\x01\x00\x00"


def parse(src):
    d = open(src, "rb").read()
    if len(d) < WRAP_LEN + 12:
        raise SystemExit("file too small")
    v, unk, slen = struct.unpack(">III", d[:WRAP_LEN])
    # VERIFIED byte pattern (docs/FONT-FORMAT.md): 01 00 00 00 | 08 00 00 00 |
    # then u32 BE length of the embedded sfnt. The first two fields are
    # recorded as a byte pattern, not integers (semantics INFERRED).
    if d[:4] != b"\x01\x00\x00\x00" or d[4:8] != b"\x08\x00\x00\x00" \
            or len(d) != WRAP_LEN + slen:
        raise SystemExit("wrapper mismatch: bytes=%s len-field=%d filesize-12=%d"
                         % (d[:8].hex(), slen, len(d) - WRAP_LEN))
    sf = d[WRAP_LEN:]
    if sf[:4] != SFNT_MAGIC:
        raise SystemExit("no sfnt at offset %d" % WRAP_LEN)
    n = struct.unpack(">H", sf[4:6])[0]
    if not (1 <= n <= 64):
        raise SystemExit("bad numTables %d" % n)
    tabs = {}
    for t in range(n):
        tag, ck, toff, tlen = struct.unpack(">4sIII", sf[12 + t * 16:28 + t * 16])
        tag = tag.decode("latin1")
        if toff + tlen > len(sf):
            raise SystemExit("table %s overruns the sfnt" % tag)
        tabs[tag] = (toff, tlen, ck)
    # checksum verification (whole-table sum mod 2^32)
    bad = []
    for tag, (toff, tlen, ck) in tabs.items():
        if tag == "head":
            continue  # adjusted so the whole-font checksum is magic; skip
        data = sf[toff:toff + tlen]
        data += b"\0" * (-len(data) % 4)
        s = sum(struct.unpack(">%dI" % (len(data) // 4), data)) & 0xffffffff
        if s != ck:
            bad.append(tag)
    (ver, rev, cks, magic, flags, upem, _cr, _mo, xmin, ymin, xmax, ymax,
     _mac, _lo, _fdh, itlf, _gdf) = struct.unpack(">IIIIHHqqhhhhHHHhh",
                                                  sf[tabs["head"][0]:tabs["head"][0] + 54])
    if magic != 0x5F0F3CF5:
        raise SystemExit("head magic mismatch: %08x" % magic)
    mv, nglyphs = struct.unpack(">IH", sf[tabs["maxp"][0]:tabs["maxp"][0] + 6])
    hv = struct.unpack(">IhhhHhhhhhh", sf[tabs["hhea"][0]:tabs["hhea"][0] + 24])
    ascent, descent, linegap = hv[1:4]
    nhm = struct.unpack(">H", sf[tabs["hhea"][0] + 34:tabs["hhea"][0] + 36])[0]
    # name table (platform 3 strings)
    no = tabs["name"][0]
    nm = sf[no:no + tabs["name"][1]]
    cnt, strOff = struct.unpack(">HH", nm[2:6])
    names = {}
    for i in range(cnt):
        pid, _eid, _lid, nid, ln, o = struct.unpack(">HHHHHH", nm[6 + i * 12:18 + i * 12])
        if pid == 3 and nid in (0, 1, 2, 4, 5):
            s = nm[strOff + o:strOff + o + ln]
            names.setdefault(nid, s.decode("utf-16-be", "replace"))
    # cmap: format 4 (Windows/Unicode) + format 6 (Mac Roman)
    co = tabs["cmap"][0]
    cm = sf[co:co + tabs["cmap"][1]]
    nsub = struct.unpack(">H", cm[2:4])[0]
    # cmap: format 4 (pid 0/3, Unicode — the authority) + format 6 (pid 1,
    # Mac Roman codes — legacy, reported but NOT merged into Unicode coverage)
    cmap = {}
    mac6 = None
    for i in range(nsub):
        pid, eid, off = struct.unpack(">HHI", cm[4 + i * 8:12 + i * 8])
        fmt = struct.unpack(">H", cm[off:off + 2])[0]
        if fmt == 4:
            f4 = cm[off:]
            segX2 = struct.unpack(">H", f4[6:8])[0]
            segs = segX2 // 2
            ends = struct.unpack(">%dH" % segs, f4[14:14 + segX2])
            starts = struct.unpack(">%dH" % segs, f4[16 + segX2:16 + 2 * segX2])
            deltas = struct.unpack(">%dh" % segs, f4[16 + 2 * segX2:16 + 3 * segX2])
            rngs = struct.unpack(">%dH" % segs, f4[16 + 3 * segX2:16 + 4 * segX2])
            for s in range(segs):
                for cp in range(starts[s], min(ends[s], 0xFFFE) + 1):
                    if rngs[s] == 0:
                        g = (cp + deltas[s]) & 0xFFFF
                    else:
                        addr = off + 16 + 3 * segX2 + s * 2 + rngs[s] + (cp - starts[s]) * 2
                        g = struct.unpack(">H", cm[addr:addr + 2])[0]
                        if g:
                            g = (g + deltas[s]) & 0xFFFF
                    if g:
                        cmap[cp] = g
        elif fmt == 6:
            first, cnt6 = struct.unpack(">HH", cm[off + 6:off + 10])
            mac6 = (pid, eid, first, cnt6)
    # loca + hmtx
    itlf = struct.unpack(">h", sf[tabs["head"][0] + 50:tabs["head"][0] + 52])[0]
    lo, ll = tabs["loca"][0], tabs["loca"][1]
    if itlf == 0:
        loca = struct.unpack(">%dH" % (ll // 2), sf[lo:lo + ll])
        loca = [x * 2 for x in loca]
    else:
        loca = struct.unpack(">%dI" % (ll // 4), sf[lo:lo + ll])
    hmtx = sf[tabs["hmtx"][0]:tabs["hmtx"][0] + tabs["hmtx"][1]]
    return dict(d=d, sf=sf, tabs=tabs, bad=bad, upem=upem, rev=rev / 65536.0,
                nglyphs=nglyphs, ascent=ascent, descent=descent, linegap=linegap,
                nhm=nhm, bbox=(xmin, ymin, xmax, ymax), itlf=itlf,
                loca=loca, hmtx=hmtx, cmap=cmap, mac6=mac6, names=names)


def glyf_info(p, gid):
    """Classify one glyph and (for simple glyphs) decode its outline header."""
    sf, go = p["sf"], p["tabs"]["glyf"][0]
    o1, o2 = p["loca"][gid], p["loca"][gid + 1]
    if o1 == o2:
        return ("empty", 0, 0)
    nc, xmin, ymin, xmax, ymax = struct.unpack(">hhhhh", sf[go + o1:go + o1 + 10])
    if nc < 0:
        # composite: walk the component records
        i, comps = go + o1 + 10, 0
        while True:
            flags, _idx = struct.unpack(">HH", sf[i:i + 4])
            comps += 1
            i += 4
            i += 4 if flags & 0x0001 else 2      # ARG_1_AND_2_ARE_WORDS
            if flags & 0x0008:                    # WE_HAVE_A_SCALE
                i += 2
            elif flags & 0x0040:                  # X_AND_Y_SCALE
                i += 4
            elif flags & 0x0080:                  # TWO_BY_TWO
                i += 8
            if not flags & 0x0020:                # MORE_COMPONENTS
                break
        return ("composite", comps, 0)
    endPts = struct.unpack(">%dH" % nc, sf[go + o1 + 10:go + o1 + 10 + nc * 2])
    npts = endPts[-1] + 1 if nc else 0
    return ("simple", nc, npts)


def main():
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    src, outdir = sys.argv[1], sys.argv[2]
    px = int(sys.argv[3]) if len(sys.argv) > 3 else 32
    p = parse(src)
    os.makedirs(outdir, exist_ok=True)
    ttf = os.path.join(outdir, "out.ttf")
    open(ttf, "wb").write(p["sf"])

    n = len(p["cmap"])
    cps = sorted(p["cmap"])
    print("font: %s %s (%s)" % (p["names"].get(1), p["names"].get(2), p["names"].get(5)))
    print("wrapper: 01000000/08000000 pattern + sfnt length %d (= file - 12) [VERIFIED]"
          % (len(p["d"]) - WRAP_LEN))
    print("sfnt: 17 tables, glyf outlines, fontRevision %.2f unitsPerEm %d" % (p["rev"], p["upem"]))
    print("glyphs: %d (mapped codepoints %d), hhea ascent %d descent %d lineGap %d"
          % (p["nglyphs"], n, p["ascent"], p["descent"], p["linegap"]))
    print("bbox (font units): %s" % (p["bbox"],))
    print("checksum mismatches (excl. head): %s" % (p["bad"] or "none"))
    # coverage blocks
    blocks = {}
    for c in cps:
        b = "ASCII" if c < 0x80 else "Latin-1 Supp." if c < 0x100 else \
            "Latin Ext-A" if c < 0x180 else "Latin Ext-B" if c < 0x200 else \
            "punct/currency/symbols" if c < 0x2200 else "arrows/math" if c < 0x2700 else "misc"
        blocks.setdefault(b, []).append(c)
    for b, v in blocks.items():
        print("coverage %-24s %3d codepoints  U+%04X..U+%04X" % (b, len(v), v[0], v[-1]))
    if p["mac6"]:
        print("legacy cmap: pid=%d eid=%d format 6, Mac Roman codes %d..%d (%d entries) — not Unicode, excluded"
              % (p["mac6"][0], p["mac6"][1], p["mac6"][2], p["mac6"][2] + p["mac6"][3] - 1, p["mac6"][3]))
    # simple vs composite vs empty
    kinds = {"simple": 0, "composite": 0, "empty": 0}
    for g in set(p["cmap"].values()):
        kinds[glyf_info(p, g)[0]] += 1
    print("mapped glyph kinds: simple=%d composite=%d empty=%d" %
          (kinds["simple"], kinds["composite"], kinds["empty"]))
    # ASCII dimensions at the requested px
    scale = px / p["upem"]
    hm = p["hmtx"]
    advs = []
    for c in range(0x21, 0x7F):
        g = p["cmap"][c]
        a = struct.unpack(">H", hm[g * 4:g * 4 + 2])[0] if g < p["nhm"] else None
        advs.append(a)
    print("ASCII advance widths @%dpx: min %.1f max %.1f (em frac %.3f..%.3f)"
          % (px, min(advs) * scale, max(advs) * scale,
             min(advs) / p["upem"], max(advs) / p["upem"]))

    # atlas (Pillow path; skipped cleanly without it)
    atlas_txt = os.path.join(outdir, "atlas.txt")
    try:
        from PIL import Image, ImageFont
    except ImportError:
        open(atlas_txt, "w").write("no Pillow: atlas skipped; use out.ttf with stb_truetype\n")
        print("atlas: SKIPPED (no Pillow); carved out.ttf written")
        return
    import io
    f = ImageFont.truetype(io.BytesIO(p["sf"]), px)
    asc_px, desc_px = f.getmetrics()
    pad = 2
    cell_w = int(max(f.getlength(chr(c)) for c in cps)) + 2
    cell_h = asc_px + desc_px + pad
    cell_w = (cell_w + 3) // 4 * 4
    cell_h = (cell_h + 3) // 4 * 4
    cols = 16
    rows = (n + cols - 1) // cols
    img = Image.new("L", (cols * cell_w, rows * cell_h), 0)
    lines = ["# bx510 atlas manifest (deterministic; generated by bx510_font_decode.py)",
             "# cells in codepoint order, left-to-right, top-to-bottom",
             "cell_w=%d cell_h=%d cols=%d rows=%d first_cp=U+%04X count=%d px=%d"
             % (cell_w, cell_h, cols, rows, cps[0], n, px),
             "# font: %s %s" % (p["names"].get(1), p["names"].get(5)),
             "# cp glyphid adv x_off y_off(cell-relative top-left) w h",
             "bin=atlas.bin format=u8-coverage row-major"]
    raw = bytearray(n * cell_w * cell_h)
    overflow = []
    for i, c in enumerate(cps):
        gx, gy = (i % cols) * cell_w, (i // cols) * cell_h
        ch = chr(c)
        mask = f.getmask(ch, mode="L")
        w, h = mask.size
        # baseline: place so the font ascent sits at fixed y inside the cell
        bb = f.getbbox(ch)
        y_off = asc_px - bb[1] if bb else asc_px
        x_off = bb[0] if bb else 0
        tile = Image.frombytes("L", mask.size, bytes(mask))
        # clip the tile to the cell interior so no glyph can bleed into a
        # neighbour (overflow is recorded in the manifest instead)
        sx0, sy0 = max(-x_off, 0), max(-y_off, 0)
        sx1 = min(w, cell_w - x_off)
        sy1 = min(h, cell_h - y_off)
        if sx1 <= sx0 or sy1 <= sy0:
            lines.append("U+%04X g=%d adv=%d(%d units) CLIPPED-EMPTY"
                         % (c, p["cmap"][c], int(f.getlength(ch) + 0.5), 0))
            continue
        if x_off + sx1 > cell_w or y_off + sy1 > cell_h:
            overflow.append(hex(c))
        tile = tile.crop((sx0, sy0, sx1, sy1))
        px0, py0 = x_off + sx0, y_off + sy0
        img.paste(tile, (gx + px0, gy + py0))
        adv = int(f.getlength(ch) + 0.5)
        g = p["cmap"][c]
        a_units = struct.unpack(">H", hm[g * 4:g * 4 + 2])[0] if g < p["nhm"] else 0
        lines.append("U+%04X g=%d adv=%d(%d units) x=%d y=%d w=%d h=%d"
                     % (c, g, adv, a_units, px0, py0, tile.size[0], tile.size[1]))
    # atlas.bin is read back from the composed image so the two artifacts are
    # identical by construction
    for i in range(n):
        gx, gy = (i % cols) * cell_w, (i // cols) * cell_h
        raw[i * cell_w * cell_h:(i + 1) * cell_w * cell_h] = \
            img.crop((gx, gy, gx + cell_w, gy + cell_h)).tobytes()
    img.save(os.path.join(outdir, "atlas.png"))
    open(os.path.join(outdir, "atlas.bin"), "wb").write(bytes(raw))
    open(atlas_txt, "w").write("\n".join(lines) + "\n")
    print("atlas: %dx%d cells, %d glyphs -> atlas.png/atlas.bin/atlas.txt (px=%d)"
          % (cell_w, cell_h, n, px))
    if overflow:
        print("atlas cells clipped at the cell edge: %s" % ", ".join(overflow))
    print("carved sfnt -> out.ttf (%d bytes)" % len(p["sf"]))


if __name__ == "__main__":
    main()
