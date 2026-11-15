#!/usr/bin/env python3
"""sacd_ui_gate.py — PASS/FAIL gate + frame artifact for a sacd_ui guest run.

A UI run is only a pass if ALL of:
  1. the UI process exited 0 (UI_RC=0 — the code keeps 3 for "rendered but the
     client session failed", so a red screen cannot pass),
  2. it reported the pool canvas it drew into (UI: vendor pool mapped / geom),
  3. the framebuffer dump is not (nearly) black (mean luminance),
  4. TEXT IS PRESENT IN THE PIXELS: the title band and the track-table band
     each carry a minimum count of bright pixels. That is the HUD's
     pixel-verify idea applied to text — a blank-but-lit panel would pass (3)
     and fail (4).

It also writes the frame as a PNG (no third-party deps: zlib + struct) so the
result is something a human can LOOK at, and prints per-region ink counts.

Usage: sacd_ui_gate.py <uart-log> [--png out.png] [--min-lum 4.0]
Exit 0 = PASS, 1 = FAIL, 2 = usage/parse error.
"""
import argparse
import re
import struct
import sys
import zlib


def parse_dump(txt, scale=3):
    """FBGEOM + (FBPIX | FBPIXROW ...) -> (w, h, rows of RGB, missing_rows).

    Two dump shapes are accepted because the frame can be read back either way:
      - FBPIX   <hex>            one long line (a quiet guest; the HUD lane)
      - FBPIXROW <y> <hex>       one line per sampled row (--rows; the busy
                                 guest, where kernel console writers interleave
                                 into a long line and truncate it)
    Row mode reports how many rows were lost to interleaving instead of failing
    outright: a frame with a handful of damaged rows is still evidence.
    """
    g = re.search(r"FBGEOM\s+(\S+?)(\(pool\))?\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)", txt)
    if not g:
        return None
    w, h = int(g.group(3)), int(g.group(4))
    sw, sh = w // scale, h // scale
    need = sw * 6

    rows_by_y = {}
    for m in re.finditer(r"^FBPIXROW\s+(\d+)\s+([0-9a-fA-F]+)$", txt, re.M):
        y = int(m.group(1)) // scale
        hx = m.group(2)
        if y < sh and len(hx) >= need:
            rows_by_y[y] = hx[:need]
    if not rows_by_y:
        px = re.search(r"FBPIX\s+([0-9a-fA-F]+)", txt)
        if not px:
            return None
        hexs = px.group(1)
        if sw * sh != len(hexs) // 6:
            raise SystemExit("FAIL: dump size %d px does not match %dx%d every %dth "
                             "pixel (%d) — line truncated by interleaved console "
                             "output? use fbdump --rows"
                             % (len(hexs) // 6, w, h, scale, sw * sh))
        for y in range(sh):
            rows_by_y[y] = hexs[y * sw * 6:(y + 1) * sw * 6]

    rows = []
    missing = 0
    for y in range(sh):
        hx = rows_by_y.get(y)
        if hx is None:
            missing += 1
            rows.append(bytes(sw * 3))
            continue
        row = bytearray()
        for x in range(sw):
            o = x * 6
            row += bytes((int(hx[o:o + 2], 16), int(hx[o + 2:o + 4], 16),
                          int(hx[o + 4:o + 6], 16)))
        rows.append(bytes(row))
    return sw, sh, rows, missing


def write_png(path, w, h, rows):
    raw = b"".join(b"\x00" + r for r in rows)

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)

    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw, 9))
           + chunk(b"IEND", b""))
    with open(path, "wb") as f:
        f.write(png)


def ink(rows, y0, y1, thr=90):
    """count pixels brighter than thr in a row band (fraction of the band)"""
    n = 0
    tot = 0
    for r in rows[y0:y1]:
        for i in range(0, len(r), 3):
            lum = (r[i] * 30 + r[i + 1] * 59 + r[i + 2] * 11) // 100
            tot += 1
            if lum > thr:
                n += 1
    return n, (n / tot if tot else 0.0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("log")
    ap.add_argument("--png", default=None)
    ap.add_argument("--min-lum", type=float, default=4.0)
    ap.add_argument("--scale", type=int, default=3,
                    help="fbdump sampling step used in the fire (default 3)")
    ap.add_argument("--min-ink", type=float, default=0.004,
                    help="bright-pixel fraction required in the text bands")
    a = ap.parse_args()

    txt = open(a.log, encoding="utf-8", errors="replace").read()
    m = re.search(r"UI_RC=(\d+)", txt)
    if not m:
        print("FAIL: no UI_RC marker (the UI never finished)")
        return 2
    rc = int(m.group(1))
    if rc != 0:
        print("FAIL: UI_RC=%d (3 = frame rendered but the client session failed;"
              " 139 = SIGSEGV)" % rc)
        return 1
    if "vendor pool mapped" not in txt and "UI: geom" not in txt:
        print("FAIL: no pool/canvas evidence in the log")
        return 1
    if re.search(r"UI_PASS_MARKER=0", txt):
        print("FAIL: the UI did not print UI_PASS")
        return 1
    if not re.search(r"UI_CLIENT_RC=0", txt) or "CLIENT_PASS" not in txt:
        print("FAIL: the second client (sacdclient) did not pass")
        return 1

    dump = parse_dump(txt, a.scale)
    if not dump:
        print("FAIL: no FBGEOM/FBPIX pool dump")
        return 1
    sw, sh, rows, missing = dump
    if missing > sh // 20:
        print("FAIL: %d of %d frame rows were lost to interleaving (>5%%)" % (missing, sh))
        return 1

    total = 0
    n = 0
    for r in rows:
        for i in range(0, len(r), 3):
            total += (r[i] * 30 + r[i + 1] * 59 + r[i + 2] * 11) // 100
            n += 1
    lum = total / n if n else 0.0
    if lum < a.min_lum:
        print("FAIL: framebuffer is black (mean luminance %.2f < %.2f)" % (lum, a.min_lum))
        return 1

    # Bands are the UI's LOGICAL canvas rows: the dump samples every scale-th
    # device pixel, so one sampled row == one logical row (canvas is CW x CH
    # logical at scale x scale device block).
    title = ink(rows, 8, 30)       # "SACD RECONSTRUCT" + right-hand label
    status = ink(rows, 37, 79)     # DAEMON / DISC / ALBUM lines
    tracks = ink(rows, 114, 194)   # both area panels' track tables
    print("frame %dx%d  mean luminance %.2f  damaged rows %d/%d"
          % (sw, sh, lum, missing, sh))
    print("ink  title band %.4f (%d px)   status band %.4f (%d px)   "
          "track band %.4f (%d px)" % (title[1], title[0], status[1], status[0],
                                       tracks[1], tracks[0]))
    for name, (cnt, frac) in (("title", title), ("status", status), ("track-table", tracks)):
        if frac < a.min_ink:
            print("FAIL: no rendered text in the %s band (ink %.4f < %.4f)"
                  % (name, frac, a.min_ink))
            return 1

    if a.png:
        write_png(a.png, sw, sh, rows)
        print("wrote %s" % a.png)
    print("PASS: rc=0, pool canvas, luminance %.2f, text present in 3 bands" % lum)
    return 0


if __name__ == "__main__":
    sys.exit(main())
