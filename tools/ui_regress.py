#!/usr/bin/env python3
"""ui_regress.py — the SACD console UI's layout regression: one spec, five checks.

`tools/sacd_ui.c`'s draw_frame() is the renderer; `tools/ui_layout_spec.json` is
the CONTRACT (regions, palette, font sizes, rules, loop geometry, motion
regions). This tool renders the scene inventory and proves that three things
still agree — the spec, what the compiled renderer actually draws, and the
pixels:

  A. SCENES      every scene rendered into evidence/.../regress/scenes/ from
                 real fixture TOC bytes, each with its sha256 + a manifest
                 (inputs, font, code sha, spec sha, the compiled spec dump).
  B. GOLDENS     golden/<scene>.ppm.sha256 is the referee. A default run only
                 COMPARES; a mismatch FAILS naming the scene and writes a diff
                 PNG + a per-region ink-delta table. Rewriting goldens needs an
                 explicit `--accept` (`make ui-golden GOLDEN=accept`).
  C. INVARIANTS  hash-free checks that survive an intentional change in flight:
                 per-region ink bands (vs golden, with tolerance) and the text
                 floor per region, rogue-colour detection (compiled dump +
                 sampled pixels on the palette-blend manifold), the four 1px
                 structural rules + the frame border, scale independence
                 (s4-scale1 vs s1-full), and the loop constants read back out
                 of the source.
  D. ANIMATION   a frame SEQUENCE -> per-region ink time series, blink-period
                 detection (must match spec.pulse.hz +/-10%), the RENDER line's
                 per-frame change cadence, and confinement of every frame-to-
                 frame change to spec.motion_regions (a moving track row = BUG).
  E. PARITY      a GUEST capture vs the SIM golden at the same scene: per-region
                 ink correlation >= 0.85 on the rows the capture actually
                 carried, damaged rows reported separately.

Every verdict here is computed. Images are artifacts; hashes are the referee.

Substrate: the spec dump only exists in sacd_ui.c with tools/sacd_ui_spec_dump.patch
applied (it is byte-inert — the frame sha256 is identical with and without
-DSACD_UI_SPEC_DUMP). `--src` selects the renderer to regress, so a pinned ref
or a candidate file can be checked without touching the working tree.

Usage:
  ui_regress.py regress                    # A+B+C (the default)
  ui_regress.py golden --accept            # re-seed goldens (explicit!)
  ui_regress.py anim --seq-dir DIR         # a rendered sequence (has seq.json)
  ui_regress.py anim --uart LOG --dt 0.25  # a guest fire's transcript
  ui_regress.py parity --uart LOG --scene s1-full
  ui_regress.py scenes                     # just A (artifacts + manifest)

Exit: 0 pass, 1 FAIL, 2 usage/input fault (missing fixture, no spec dump in the
renderer, undecodable capture). Stdlib only, by repo rule.
"""
import argparse
import hashlib
import json
import os
import re
import struct
import subprocess
import sys
import zlib
from collections import Counter
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
REPO = TOOLS.parent
DEFAULT_SPEC = TOOLS / "ui_layout_spec.json"
DEFAULT_SRC = TOOLS / "sacd_ui.c"
DEFAULT_ART = REPO / "evidence/bx510-guest/graphics/regress"
DEFAULT_FONT = REPO / "evidence/bx510/display-payload/sony-font.ttf"
PATCH = TOOLS / "sacd_ui_spec_dump.patch"

INK_LUM = 90                      # ink = luminance above this (the guest gate's rule)
INK_TOL_ABS = 0.010               # per-region ink drift allowed vs golden ...
INK_TOL_REL = 0.35                # ... or this fraction of the golden's ink
SCALE_TOL_ABS = 0.015             # scale-1 vs scale-3 ink agreement ...
SCALE_TOL_REL = 0.35              # ... or this fraction of the scale-3 ink
SCALE_BBOX_ORIGIN_PX = 3          # a band's origin must not move with the scale
SCALE_BBOX_EXTENT_FRAC = 0.15     # its extent may (glyph rasterisation at 1/3 size)
PARITY_MIN_CORR = 0.85            # guest-vs-golden per-row ink correlation
ROGUE_MIN_PX = 200                # a sampled colour needs this many px to be judged
ROGUE_TOL = 8                     # ... and must lie this close to a palette blend

sys.path.insert(0, str(TOOLS))


# ── helpers: hashes, files, ppm ─────────────────────────────────────────────

def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def sha256_bytes(blob):
    return hashlib.sha256(blob).hexdigest()


def read_ppm(path):
    """P6 -> (w, h, rgb bytes). Raises ValueError on anything else."""
    blob = Path(path).read_bytes()
    if not blob.startswith(b"P6\n"):
        raise ValueError(f"{path}: not a binary PPM (P6)")
    pos, fields = 2, []
    while len(fields) < 3:
        end = blob.index(b"\n", pos)
        line = blob[pos:end]
        pos = end + 1
        if line.startswith(b"#"):
            continue
        fields.extend(line.split())
    w, h, maxval = (int(v) for v in fields[:3])
    if maxval != 255:
        raise ValueError(f"{path}: maxval {maxval} != 255")
    body = blob[pos:]
    if len(body) != w * h * 3:
        raise ValueError(f"{path}: {len(body)} B for {w}x{h}x3")
    return w, h, body


def write_png(path, w, h, rgb):
    """RGB8 PNG, filter 0 — the stdlib writer the other UI tools use."""

    def chunk(tag, data):
        body = tag + data
        return (struct.pack(">I", len(data)) + body
                + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF))

    raw = bytearray()
    for y in range(h):
        raw.append(0)
        raw += rgb[y * w * 3:(y + 1) * w * 3]
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    Path(path).write_bytes(png)


def read_png(path):
    """RGB8 PNG -> (w, h, rgb bytes). Only the shape write_png emits (filter 0).

    The goldens are stored as PNG, not PPM: a 1920x1080 PPM is 6.2 MB per scene
    and the referee is meant to live in the repo. The HASH is still taken over
    the PPM bytes, so the frame identity does not depend on the container.
    """
    blob = Path(path).read_bytes()
    if blob[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path}: not a PNG")
    pos, idat, w, h = 8, b"", 0, 0
    while pos < len(blob):
        (length,) = struct.unpack(">I", blob[pos:pos + 4])
        tag = blob[pos + 4:pos + 8]
        data = blob[pos + 8:pos + 8 + length]
        if tag == b"IHDR":
            w, h, depth, colour = struct.unpack(">IIBB", data[:10])
            if depth != 8 or colour != 2:
                raise ValueError(f"{path}: {depth}bpp colour type {colour}, not RGB8")
        elif tag == b"IDAT":
            idat += data
        pos += 12 + length
    raw = zlib.decompress(idat)
    stride = w * 3
    if len(raw) != h * (stride + 1):
        raise ValueError(f"{path}: {len(raw)} B of scanlines for {w}x{h}")
    out = bytearray()
    for y in range(h):
        row = raw[y * (stride + 1):(y + 1) * (stride + 1)]
        if row[0] != 0:
            raise ValueError(f"{path}: filter {row[0]} on row {y} — only filter 0 is written here")
        out += row[1:]
    return w, h, bytes(out)


def luminance(px):
    return (px[0] * 30 + px[1] * 59 + px[2] * 11) // 100


def colour_name(spec, value):
    value &= 0xFFFFFF
    for name, hexval in spec["palette"].items():
        if int(hexval, 16) & 0xFFFFFF == value:
            return name
    return None


# ── image measurement (all on the LOGICAL grid: one sample per logical px) ──

def sample(blob, w, h, scale, ly, lx):
    o = ((ly * scale) * w + lx * scale) * 3
    return blob[o], blob[o + 1], blob[o + 2]


def measure(blob, w, h, scale, regions):
    """-> (logical_w, logical_h, row_ink, histogram, per_region_ink).

    row_ink is the ink count of every logical row (whole width);
    histogram counts sampled colours; per_region_ink is {region: (count, frac)}
    over the region's own rect — all from the same one-sample-per-logical-px
    convention, so a band's FRACTION is directly comparable across scales.
    """
    lw, lh = w // scale, h // scale
    row_ink = []
    hist = Counter()
    for ly in range(lh):
        n = 0
        for lx in range(lw):
            rgb = blob[((ly * scale) * w + lx * scale) * 3:][:3]
            hist[rgb] += 1
            if luminance(rgb) > INK_LUM:
                n += 1
        row_ink.append(n)
    per = {}
    for r in regions:
        x, y, rw, rh = r["x"], r["y"], r["w"], r["h"]
        cnt = tot = 0
        for ly in range(y, min(y + rh, lh)):
            for lx in range(x, min(x + rw, lw)):
                # The 1px frame border is STRUCTURAL, not content: counting it
                # would let a blank band pass on its own edge (measured: the
                # title band's border alone is 0.034 of the band).
                if ly in (0, lh - 1) or lx in (0, lw - 1):
                    continue
                tot += 1
                if luminance(sample(blob, w, h, scale, ly, lx)) > INK_LUM:
                    cnt += 1
        per[r["name"]] = (cnt, cnt / tot if tot else 0.0)
    return lw, lh, row_ink, hist, per


def band_ink(blob, w, h, scale, ly, lx0, lx1):
    """fraction of INKED logical px in one logical row segment"""
    tot = n = 0
    for lx in range(lx0, lx1):
        tot += 1
        if luminance(sample(blob, w, h, scale, ly, lx)) > INK_LUM:
            n += 1
    return n / tot if tot else 0.0


def resample_logical(blob, w, h, step, logical_w, logical_h):
    """A guest capture on the LOGICAL grid: (blob, present logical rows).

    fbdump samples every `step`-th device px, so one captured row covers
    `step / scale` logical rows. Nearest-neighbour with the sample position kept
    (no averaging) so an ink count keeps its meaning; rows the capture lost are
    reported, never silently zero-filled into the analysis.
    """
    lstep = max(1, step)
    out = bytearray(logical_w * logical_h * 3)
    present = set()
    for ly in range(logical_h):
        sy = ly // lstep
        if sy >= h:
            continue
        present.add(ly)
        for lx in range(logical_w):
            sx = lx // lstep
            if sx >= w:
                continue
            o = (sy * w + sx) * 3
            d = (ly * logical_w + lx) * 3
            out[d:d + 3] = blob[o:o + 3]
    return bytes(out), present


def non_bg_fraction(blob, w, h, scale, logical_row, x0, x1, bg_rgb):
    """fraction of sampled px on that logical row that are NOT the background"""
    tot = n = 0
    for lx in range(x0, x1):
        tot += 1
        if sample(blob, w, h, scale, logical_row, lx) != bg_rgb:
            n += 1
    return n / tot if tot else 0.0


def bbox_contains(outer, inner):
    ox, oy, ow, oh = outer
    ix, iy, iw, ih = inner
    return ix >= ox and iy >= oy and ix + iw <= ox + ow and iy + ih <= oy + oh


def point_segment_distance(c, p, q):
    """Euclidean distance from colour c to segment pq (RGB as 3-space)."""
    d = [q[i] - p[i] for i in range(3)]
    denom = sum(v * v for v in d)
    if denom == 0:
        t = 0.0
    else:
        t = sum((c[i] - p[i]) * d[i] for i in range(3)) / denom
        t = max(0.0, min(1.0, t))
    proj = [p[i] + t * d[i] for i in range(3)]
    return sum((c[i] - proj[i]) ** 2 for i in range(3)) ** 0.5


def pearson(a, b):
    n = len(a)
    if n < 3:
        return None
    ma, mb = sum(a) / n, sum(b) / n
    va = sum((x - ma) ** 2 for x in a)
    vb = sum((x - mb) ** 2 for x in b)
    if va == 0 or vb == 0:
        return None
    cov = sum((a[i] - ma) * (b[i] - mb) for i in range(n))
    return cov / (va ** 0.5 * vb ** 0.5)


# ── the compiled spec dump → dict ──────────────────────────────────────────

def parse_spec_dump(text):
    """`SPEC ...` lines -> {"canvas": {}, "palette": {name: 0xRRGGBB}, "regions": {}}"""
    out = {"canvas": {}, "palette": {}, "regions": {}}
    for line in text.splitlines():
        if not line.startswith("SPEC "):
            continue
        parts = line.split()
        head = parts[1]
        if head == "canvas":
            for kv in parts[2:]:
                k, _, v = kv.partition("=")
                if k == "logical":
                    out["canvas"]["logical"] = tuple(int(v) for v in v.split("x"))
                elif k == "pulse_hz":
                    out["canvas"]["pulse_hz"] = float(v)
                else:
                    out["canvas"][k] = int(v)
        elif head == "palette":
            out["palette"][parts[2]] = int(parts[3], 16)
        elif head.startswith("region="):
            rec = {"name": head.split("=", 1)[1], "colors": [], "sizes": []}
            for kv in parts[2:]:
                k, _, v = kv.partition("=")
                if k in ("x", "y", "w", "h", "draws"):
                    rec[k] = int(v)
                elif k == "colors":
                    rec["colors"] = [int(t, 16) for t in v.split(",") if t]
                elif k == "sizes":
                    rec["sizes"] = [int(t) for t in v.split(",") if t]
            out["regions"][rec["name"]] = rec
    return out


# ── check C: spec contract (compiled dump vs committed spec) ───────────────

def check_spec(spec, dump, scene):
    """-> (problems, notes, overflows_in_use).

    overflows_in_use are the declared_overflow rects this scene actually drew,
    so downstream pixel checks skip a probe for a reason that exists in THIS
    frame instead of one that might.
    """
    problems, notes = [], []
    overflows_in_use = []
    canvas = dump["canvas"]
    if canvas.get("logical") != (spec["canvas"]["logical_w"], spec["canvas"]["logical_h"]):
        problems.append(f"canvas: renderer logical canvas {canvas.get('logical')} but the spec says "
                        f"{(spec['canvas']['logical_w'], spec['canvas']['logical_h'])}")
    if canvas.get("pulse_hz") != float(spec["pulse"]["hz"]):
        problems.append(f"pulse: renderer blink {canvas.get('pulse_hz')} Hz but the spec says {spec['pulse']['hz']} Hz")

    for name, hexval in spec["palette"].items():
        got = dump["palette"].get(name)
        if got is None:
            problems.append(f"palette: {name} is in the spec but the renderer emits no such colour")
        elif got != int(hexval, 16) & 0xFFFFFF:
            problems.append(f"palette: {name} spec {hexval} renderer 0x{got:06x}")
    for name, got in dump["palette"].items():
        if name not in spec["palette"]:
            problems.append(f"palette: {name} (0x{got:06x}) is emitted by the renderer but absent from the spec")

    declared = {r["name"]: r for r in spec["regions"]}
    for name in dump["regions"]:
        if name not in declared:
            problems.append(f"region {name}: drawn by the renderer but not declared in the spec")
    for name, want in declared.items():
        got = dump["regions"].get(name)
        if not got:
            problems.append(f"region {name}: the spec declares it but the renderer never draws it")
            continue
        rect_got = (got["x"], got["y"], got["w"], got["h"])
        rect_want = (want["x"], want["y"], want["w"], want["h"])
        if want["mode"] == "exact":
            if rect_got == rect_want:
                pass
            else:
                union = list(rect_want)
                for ov in want.get("declared_overflow", []):
                    ox, oy, ow, oh = ov["x"], ov["y"], ov["w"], ov["h"]
                    x1 = max(union[0] + union[2], ox + ow)
                    y1 = max(union[1] + union[3], oy + oh)
                    union[0] = min(union[0], ox)
                    union[1] = min(union[1], oy)
                    union[2] = x1 - union[0]
                    union[3] = y1 - union[1]
                if bbox_contains(tuple(union), rect_got):
                    overflows_in_use += [(ov, name) for ov in want.get("declared_overflow", [])]
                    notes.append(f"FINDING region {name} ({scene}): drawn x={got['x']} y={got['y']} "
                                 f"w={got['w']} h={got['h']} != spec {rect_want} but inside a "
                                 f"declared_overflow — see spec.declared_overflow")
                else:
                    problems.append(
                        f"region {name} ({scene}): the renderer draws x={got['x']} y={got['y']} "
                        f"w={got['w']} h={got['h']} but the spec says x={want['x']} y={want['y']} "
                        f"w={want['w']} h={want['h']}")
        else:
            if not bbox_contains(rect_want, rect_got):
                problems.append(
                    f"region {name} ({scene}): ink at x={got['x']} y={got['y']} w={got['w']} "
                    f"h={got['h']} spills outside its declared band {rect_want}")
        for col in got["colors"]:
            nm = colour_name(spec, col)
            if nm is None:
                problems.append(f"region {name} ({scene}): colour 0x{col:06x} is not a palette "
                                f"entry — rogue colour in the renderer")
            elif nm not in want["colors"]:
                problems.append(f"region {name} ({scene}): draws {nm} but the spec allows only "
                                f"{', '.join(want['colors'])}")
        for size in got["sizes"]:
            if size not in want["sizes"]:
                problems.append(f"region {name} ({scene}): text drawn at {size}px but the spec "
                                f"declares {want['sizes']}")
    return problems, notes, overflows_in_use


# ── check C: pixel-level invariants ───────────────────────────────────────

def check_pixels(spec, blob, w, h, scale, hist, per_region, scene, overflows_in_use=()):
    problems, notes = [], []
    bg_value = int(spec["palette"]["C_BG"], 16) & 0xFFFFFF
    bg = ((bg_value >> 16) & 255, (bg_value >> 8) & 255, bg_value & 255)
    overflow = [ov for ov, _owner in overflows_in_use]
    for want in spec["regions"]:
        cnt, frac = per_region[want["name"]]
        floor = want.get("min_ink")
        if floor is not None and frac < floor:
            problems.append(f"region {want['name']} ({scene}): TEXT MISSING — ink {frac:.4f} "
                            f"< the {floor} floor (the region drew nothing legible)")
    # the four 1px rules: present on their row, absent two rows below
    for rule in spec["rules"]:
        y = rule["y"]
        got = non_bg_fraction(blob, w, h, scale, y, rule["x"], rule["x"] + rule["w"], bg)
        if got < 0.95:
            problems.append(f"rule y={y} ({scene}): only {got:.0%} of the row is inked — the "
                            f"structural rule is missing")
        cleared = y + 2
        blocker = next((ov for ov in overflow
                        if ov["y"] <= cleared < ov["y"] + ov["h"]
                        and ov["x"] < rule["x"] + rule["w"]), None)
        if blocker is not None:
            # A declared_overflow rect legitimately draws below its region: the
            # 1px-locality probe would be measuring the declared deviation, so
            # it is skipped BY NAME rather than silently loosened.
            notes.append(f"rule y={y} ({scene}): 1px-locality probe skipped — row {cleared} is "
                         f"inside the declared overflow '{blocker['name']}'")
            continue
        below = non_bg_fraction(blob, w, h, scale, cleared, rule["x"], rule["x"] + rule["w"], bg)
        if below > 0.5:
            problems.append(f"rule y={y} ({scene}): rows {y} and {cleared} are both inked — the "
                            f"rule is no longer 1px")
    # the frame border
    frame = int(spec["palette"]["C_FRAME"], 16) & 0xFFFFFF
    lw, lh = w // scale, h // scale
    border = 0
    for ly in range(lh):
        for lx in (0, lw - 1):
            if int.from_bytes(bytes(sample(blob, w, h, scale, ly, lx)), "big") == frame:
                border += 1
    for lx in range(lw):
        for ly in (0, lh - 1):
            if int.from_bytes(bytes(sample(blob, w, h, scale, ly, lx)), "big") == frame:
                border += 1
    need = int(0.95 * 2 * (lh + lw))
    if border < need:
        problems.append(f"frame border ({scene}): only {border} of {2 * (lh + lw)} border "
                        f"samples are C_FRAME — the panel frame is broken")
    # rogue colours: a sampled colour that is neither a palette entry nor a blend
    # of two palette entries (px_blend can only produce those) is not ours.
    pal = [int(v, 16) & 0xFFFFFF for v in spec["palette"].values()]
    pal_rgb = [((v >> 16) & 255, (v >> 8) & 255, v & 255) for v in pal]
    rogue = []
    for rgb, cnt in hist.items():
        if cnt < ROGUE_MIN_PX:
            continue
        c = tuple(rgb)
        best = min(point_segment_distance(c, pal_rgb[i], pal_rgb[j])
                   for i in range(len(pal_rgb)) for j in range(i, len(pal_rgb)))
        if best > ROGUE_TOL:
            rogue.append((f"#{rgb.hex()}", cnt, round(best, 1)))
    if rogue:
        rogue.sort(key=lambda t: -t[1])
        listed = ", ".join(f"{name} x{cnt} (off the palette by {d})" for name, cnt, d in rogue[:6])
        problems.append(f"rogue colour ({scene}): {len(rogue)} sampled colour(s) are not a palette "
                        f"entry or a blend of two — {listed}")
    return problems, notes


def check_source_invariants(spec, src_text):
    """Loop constants have no drawn rect; verify them against the source text."""
    problems = []
    for name, probe in spec.get("source_invariants", {}).items():
        if not isinstance(probe, dict):
            continue
        want = probe["equals"]
        found = re.search(probe["regex"], src_text)
        if not found:
            problems.append(f"source invariant {name}: the anchor {probe['regex']!r} is gone from "
                            f"the renderer — the extractor must be updated")
            continue
        got = ",".join(found.groups()) if found.groups() else found.group(0)
        if got != want:
            problems.append(f"source invariant {name}: source says {got} but the spec says {want}")
    return problems


def check_scale_independence(spec, scaled, base, name_a, name_b):
    """scale-1 must lay out like scale-3: same bands, same ink (within tolerance)."""
    problems, notes = [], []
    for want in spec["regions"]:
        ra = scaled["spec_dump"]["regions"].get(want["name"])
        rb = base["spec_dump"]["regions"].get(want["name"])
        if not (ra and rb):
            continue
        rect_a = (ra["x"], ra["y"], ra["w"], ra["h"])
        rect_b = (rb["x"], rb["y"], rb["w"], rb["h"])
        if want["mode"] == "exact":
            if rect_a != rect_b:
                problems.append(f"scale independence {want['name']}: {name_a} draws {rect_a} but "
                                f"{name_b} draws {rect_b}")
            continue
        origin = max(abs(rect_a[0] - rect_b[0]), abs(rect_a[1] - rect_b[1]))
        extent = max(abs(rect_a[2] - rect_b[2]), abs(rect_a[3] - rect_b[3]))
        drift = max(origin, extent)
        if origin > SCALE_BBOX_ORIGIN_PX:
            problems.append(f"scale independence {want['name']}: origin {rect_a[:2]} at {name_a} "
                            f"vs {rect_b[:2]} at {name_b} — {origin}px drift (an ORIGIN must not "
                            f"follow the scale)")
        elif extent > SCALE_BBOX_EXTENT_FRAC * max(rect_b[2], rect_b[3]):
            problems.append(f"scale independence {want['name']}: extent {rect_a[2:]} at {name_a} "
                            f"vs {rect_b[2:]} at {name_b} — the band's size is scale dependent "
                            f"(text rasterisation alone cannot explain it)")
        ia = scaled["ink"][want["name"]]
        ib = base["ink"][want["name"]]
        if abs(ia - ib) > max(SCALE_TOL_ABS, SCALE_TOL_REL * max(ib, 1e-6)):
            problems.append(f"scale independence {want['name']}: ink {ia:.4f} at {name_a} vs "
                            f"{ib:.4f} at {name_b} — the layout does not survive the scale change")
        else:
            notes.append(f"scale independence {want['name']}: ink {ia:.4f} vs {ib:.4f}, bbox drift "
                         f"{drift}px")
    return problems, notes


# ── scenes ────────────────────────────────────────────────────────────────

def scene_defs(fixtures):
    """The scene inventory (also documented in tools/ui_layout_spec.json).

    args are the SIM binary's argv: <mtoc> <area1> <area2> <out>. An empty
    string is "absent" — the SIM's fopen("") fails and the renderer takes its
    no-area path, which is exactly the state a disc without that area has.
    """
    mtoc = fixtures["mtoc"]
    a1 = fixtures["area1"]
    a2 = fixtures["area2"]
    many = fixtures.get("area1_many_tracks")
    return [
        {"name": "s1-full", "args": [mtoc, a1, a2], "env": {},
         "about": "all three fixture TOC files — the default SIM scene"},
        {"name": "s2-no-areas", "args": [mtoc, "", ""], "env": {},
         "about": "master TOC only: both panels take the 'no area TOC' path"},
        {"name": "s3-session-fail", "args": [mtoc, a1, a2], "env": {"SACD_UI_SIM_FAIL": "1"},
         "about": "the failed-session screen (red DISC line + red state chip)"},
        {"name": "s4-scale1", "args": [mtoc, a1, a2], "env": {"SACD_UI_SCALE": "1"},
         "about": "640x360 (scale 1): scale independence"},
        {"name": "s5-many-tracks", "args": [mtoc, many or a1, a2], "env": {},
         "about": "area1 track_count forced to 9: six rows + the '+3 more' row"},
    ]


def fixtures_dir():
    return Path(os.environ.get("SACD_UI_FIXTURES", "/tmp"))


def make_many_tracks_fixture(area1, out):
    """area1's TOC with track_count (byte 69) forced to 9 — the >6-row branch.

    A byte mutation, not a synthesised file: the track table rows themselves
    stay the real disc's, so the scene renders real data with one field moved.
    """
    blob = bytearray(Path(area1).read_bytes())
    if len(blob) < 70 or blob[:8] not in (b"TWOCHTOC", b"MULCHTOC"):
        raise SystemExit(f"REFUSING: {area1} is not an area TOC (no TWOCHTOC/MULCHTOC tag)")
    blob[69] = 9
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(bytes(blob))
    return out


def resolve_fixtures(art):
    fx = fixtures_dir()
    got = {"mtoc": fx / "mtoc.bin", "area1": fx / "area1.bin", "area2": fx / "area2.bin"}
    missing = [str(p) for p in got.values() if not p.exists()]
    if missing:
        raise SystemExit(
            "FATAL: fixture TOC slices missing: %s\n"
            "They are three dd slices of the Firebird ISO (LBA 510 x10, 544 x40, 353804 x40,\n"
            "2048 B sectors). On the Mac with the ISO present:\n"
            "  dd if=firebird.iso of=/tmp/mtoc.bin  bs=2048 skip=510    count=10\n"
            "  dd if=firebird.iso of=/tmp/area1.bin bs=2048 skip=544    count=40\n"
            "  dd if=firebird.iso of=/tmp/area2.bin bs=2048 skip=353804 count=40\n"
            "With the ISO only on the VM (preferred, 4.6 GB stays put):\n"
            "  make vm-exec CMD='dd if=/home/aftermath/sacd-verify/firebird.iso of=/tmp/mtoc.bin "
            "bs=2048 skip=510 count=10'\n"
            "  make vm-pull-file FILE=/tmp/mtoc.bin DEST=/tmp   (same for area1/area2)\n"
            "Or point SACD_UI_FIXTURES at a directory that holds them."
            % ", ".join(missing))
    got["area1_many_tracks"] = make_many_tracks_fixture(
        got["area1"], art / "scenes" / "fixtures" / "area1-tracks9.bin")
    return got


# ── build + render ────────────────────────────────────────────────────────

def build(src, art, spec_dump):
    """Compile the SIM renderer (and the spec-dump variant). Returns paths."""
    src_text = Path(src).read_text()
    if spec_dump and "SACD_UI_SPEC_DUMP" not in src_text:
        raise SystemExit(
            f"FATAL: {src} has no SACD_UI_SPEC_DUMP support — the layout check has nothing to\n"
            f"compare the spec against. Apply the instrumentation patch:\n"
            f"  git apply {PATCH.relative_to(REPO)}      (byte-inert: the frame sha256 does\n"
            f"  not change, verified at b39b521)")
    art.mkdir(parents=True, exist_ok=True)
    out = art / ("sacd_uim_spec" if spec_dump else "sacd_uim")
    cmd = [os.environ.get("CC", "cc"), "-O2", "-std=gnu99", "-Wall",
           (f"-I{TOOLS}")]
    if spec_dump:
        cmd.append("-DSACD_UI_SPEC_DUMP")
    cmd += ["-DSACD_UI_SIM", "-o", str(out), str(src), "-lm"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit(f"FATAL: build failed ({' '.join(cmd)}):\n{r.stderr}")
    if r.stderr.strip():
        raise SystemExit(f"FATAL: the renderer does not build warning-free "
                         f"(-Wall):\n{r.stderr}")
    return out


def run_scene(binary, scene, out_ppm, font):
    """Render one scene. The font path is passed REPO-RELATIVE and the cwd is the
    repo root, because draw_frame() prints it on the RENDER line: an absolute
    path would put the checkout's location into the pixels and the golden would
    not survive a move."""
    env = dict(os.environ)
    try:
        font_arg = str(Path(font).resolve().relative_to(REPO))
    except ValueError:
        font_arg = str(font)
    env["SACD_UI_FONT"] = font_arg
    env.pop("SACD_UI_SCALE", None)
    env.pop("SACD_UI_SIM_FAIL", None)
    env.update(scene["env"])
    argv = [str(binary), *[str(a) for a in scene["args"]], str(Path(out_ppm).resolve())]
    r = subprocess.run(argv, capture_output=True, text=True, env=env, cwd=str(REPO))
    if r.returncode != 0:
        raise SystemExit(f"FATAL: scene {scene['name']} render failed rc={r.returncode}:"
                         f"\n{r.stdout}\n{r.stderr}")
    return r.stdout


def render_until_stable(binary, scene, ppm, font, tries=4):
    """Render until two CONSECUTIVE frames agree -> (sha256, stdout, attempts).

    draw_frame() prints ev_log() timestamps read from CLOCK_MONOTONIC with '%6.2f'
    (10 ms granularity), so on a loaded machine a log row reads 0.01 instead of
    0.00 and the frame changes by ~100 rows of event-log ink (artifact:
    regress/findings/nondeterministic-s2-render.ppm). Nothing here can fix that
    — the event clock in tools/sacd_ui.c does — so the control is: a hash is
    trusted only after the same binary reproduced it. The attempt count is
    recorded per scene, so a machine that needed retries is visible in the
    manifest instead of invisible in a green run.
    """
    prev = None
    text = ""
    for attempt in range(1, tries + 1):
        text = run_scene(binary, scene, ppm, font)
        cur = sha256_file(ppm)
        if prev == cur:
            return cur, text, attempt
        prev = cur
    return None, text, tries


def render_scenes(args, spec, src_bin, src_spec, art, font):
    fixtures_used = {k: {"path": str(v), "sha256": sha256_file(v)}
                    for k, v in args["fixtures"].items()}
    scenes = scene_defs(args["fixtures"])
    out_dir = art / "scenes"
    out_dir.mkdir(parents=True, exist_ok=True)
    records = []
    for scene in scenes:
        ppm = out_dir / f"{scene['name']}.ppm"
        # Two controls before any hash is trusted: (1) the SAME binary must
        # reproduce the frame, and (2) the instrumentation build must equal the
        # plain build (the dump observes, it does not draw).
        ours, text, attempts = render_until_stable(src_spec, scene, ppm, font)
        if ours is None:
            raise SystemExit(
                f"FATAL: {scene['name']} is NOT reproducible — {attempts} renders of the same "
                f"binary on the same bytes never agreed twice in a row.\n"
                f"  Cause (proven, see {art / 'findings'}): draw_frame() prints ev_log() "
                f"timestamps from CLOCK_MONOTONIC at '%6.2f' — 10 ms granularity — so a loaded "
                f"machine changes a log row and with it ~100 rows of pixels. Re-run with the "
                f"machine idle; the event clock in tools/sacd_ui.c removes the dependency.")
        cross = out_dir / f".cross-{scene['name']}.ppm"
        cross_hash, default_text, cross_attempts = render_until_stable(src_bin, scene, cross, font)
        if cross_hash is None:
            raise SystemExit(f"FATAL: {scene['name']}: the plain build is not reproducible either "
                             f"— see the message above")
        cross.unlink()
        if cross_hash != ours:
            raise SystemExit(
                f"FATAL: {scene['name']}: the frame changes when SACD_UI_SPEC_DUMP is defined "
                f"({cross_hash[:12]} vs {ours[:12]}) — the instrumentation is not byte-inert and "
                f"cannot be trusted as an observer")
        w, h, blob = read_ppm(ppm)
        scale = w // spec["canvas"]["logical_w"]
        dump = parse_spec_dump(text)
        lw, lh, row_ink, hist, per = measure(blob, w, h, scale, spec["regions"])
        rec = {
            "scene": scene["name"],
            "about": scene["about"],
            "argv": [str(a) for a in scene["args"]],
            "env": scene["env"],
            "font": str(font),
            "geometry": [w, h],
            "scale": scale,
            "ppm_sha256": ours,
            "determinism": {"attempts": attempts, "plain_build_attempts": cross_attempts,
                            "control": "two consecutive renders must agree; the plain build must "
                                       "equal the dump build"},
            # the same frame built WITHOUT the instrumentation: proof the dump
            # flag does not change a single rendered byte.
            "cross_check_sha256": cross_hash,
            "source_sha256": args["src_sha"],
            "spec_sha256": args["spec_sha"],
            "spec_dump": dump,
            "ink": {k: round(v[1], 6) for k, v in per.items()},
            "ink_px": {k: v[0] for k, v in per.items()},
            "stdout_tail": [ln for ln in default_text.splitlines() if ln.startswith("UI:")][-2:],
        }
        records.append(rec)
        print(f"scene {scene['name']:16s} {w}x{h} sha256 {rec['ppm_sha256'][:16]}…")
    manifest = {
        "schema": "sacd-ui-regress-scenes/1",
        "generated": _now(),
        "renderer": {"path": str(args["src"]), "sha256": args["src_sha"],
                     "dump_enabled": True},
        "spec": {"path": str(args["spec_path"]), "sha256": args["spec_sha"]},
        "font": {"path": str(font), "sha256": sha256_file(font)},
        "fixtures": fixtures_used,
        "scenes": records,
    }
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return records


def _now():
    import datetime
    return datetime.datetime.now().astimezone().isoformat(timespec="seconds")


# ── goldens ───────────────────────────────────────────────────────────────

def golden_paths(art, scene):
    return art / "golden" / f"{scene}.ppm.sha256"


def write_goldens(records, art, args, font):
    gdir = art / "golden"
    gdir.mkdir(parents=True, exist_ok=True)
    for rec in records:
        golden_paths(art, rec["scene"]).write_text(
            f"{rec['ppm_sha256']}  scenes/{rec['scene']}.ppm\n")
    manifest = {
        "schema": "sacd-ui-regress-golden/1",
        "accepted": _now(),
        "why": "seeded by `make ui-golden GOLDEN=accept` — goldens change ONLY on an explicit accept",
        "renderer": {"path": str(args["src"]), "sha256": args["src_sha"]},
        "patch": {"path": str(PATCH.relative_to(REPO)),
                  "sha256": sha256_file(PATCH) if PATCH.exists() else None},
        "spec": {"path": str(args["spec_path"]), "sha256": args["spec_sha"]},
        "font": {"path": str(font), "sha256": sha256_file(font)},
        "scenes": {rec["scene"]: {"ppm_sha256": rec["ppm_sha256"],
                                  "geometry": rec["geometry"],
                                  "ink": rec["ink"]} for rec in records},
    }
    (gdir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


def load_golden(art, scene):
    p = golden_paths(art, scene)
    if not p.exists():
        return None
    return p.read_text().split()[0]


def diff_png(path, a, b, w, h):
    """Red where the pixels differ, dim grey-green where they agree."""
    out = bytearray(w * h * 3)
    changed = 0
    for i in range(0, w * h * 3, 3):
        if a[i:i + 3] != b[i:i + 3]:
            out[i] = 0xFF
            out[i + 1] = 0x20
            out[i + 2] = 0x20
            changed += 1
        else:
            out[i] = a[i] >> 2
            out[i + 1] = a[i + 1] >> 2
            out[i + 2] = a[i + 2] >> 2
    write_png(path, w, h, bytes(out))
    return changed


# ── command: regress / golden / scenes ────────────────────────────────────

def run_regress(args):
    spec = json.loads(Path(args["spec_path"]).read_text())
    art = Path(args["art"])
    font = Path(args["font"])
    if not font.exists():
        raise SystemExit(f"FATAL: font missing: {font} (the panels' text comes from it)")
    art.mkdir(parents=True, exist_ok=True)
    src_bin = build(args["src"], art, spec_dump=False)
    src_spec = build(args["src"], art, spec_dump=True)
    records = render_scenes(args, spec, src_bin, src_spec, art, font)

    problems, notes = [], []
    for rec in records:
        p, n, in_use = check_spec(spec, rec["spec_dump"], rec["scene"])
        problems += p
        notes += n
        w, h, blob = read_ppm(art / "scenes" / f"{rec['scene']}.ppm")
        scale = rec["scale"]
        _, _, _row_ink, hist, per = measure(blob, w, h, scale, spec["regions"])
        p, n = check_pixels(spec, blob, w, h, scale, hist, per, rec["scene"], in_use)
        problems += p
        notes += n

    problems += check_source_invariants(spec, Path(args["src"]).read_text())

    by_scene = {r["scene"]: r for r in records}
    if "s1-full" in by_scene and "s4-scale1" in by_scene:
        p, n = check_scale_independence(spec, by_scene["s4-scale1"], by_scene["s1-full"],
                                        "s4-scale1", "s1-full")
        problems += p
        notes += n

    # ---- B: golden compare ----
    # A green run must not inherit a previous failure's artifacts: the diff dir
    # is emptied first (the demo diffs worth keeping are copied into findings/).
    diff_dir = art / "diff"
    if diff_dir.exists():
        for stale in diff_dir.glob("*.diff.png"):
            stale.unlink()
    diff_lines = []
    golden_missing = []
    for rec in records:
        want = load_golden(art, rec["scene"])
        if want is None:
            golden_missing.append(rec["scene"])
            continue
        if want == rec["ppm_sha256"]:
            continue
        ddir = art / "diff"
        ddir.mkdir(parents=True, exist_ok=True)
        gppm = art / "golden" / f"{rec['scene']}.png"
        # the golden's pixels come from the scenes dir of the accepted run: the
        # hash is the referee, so on a mismatch we diff against the last
        # accepted FRAME stored alongside the hash (scenes/ is overwritten).
        if not gppm.exists():
            problems.append(f"GOLDEN MISMATCH {rec['scene']}: {rec['ppm_sha256'][:16]}… != "
                            f"golden {want[:16]}… (no golden frame stored to diff against)")
            continue
        gw, gh, gblob = read_png(gppm)
        w, h, blob = read_ppm(art / "scenes" / f"{rec['scene']}.ppm")
        if (gw, gh) != (w, h):
            problems.append(f"GOLDEN MISMATCH {rec['scene']}: geometry {w}x{h} != golden "
                            f"{gw}x{gh}")
            continue
        changed = diff_png(ddir / f"{rec['scene']}.diff.png", gblob, blob, w, h)
        scale = rec["scale"]
        _, _, _, _, gold_per = measure(gblob, gw, gh, scale, spec["regions"])
        # Which REGION did the change land in? A pure translation moves ink out
        # of one band and into another without changing either band's total very
        # much, so the changed-pixel count per region is the honest ranking.
        rows = ["| region | changed px | golden ink | now ink | ink delta |",
                "|---|---|---|---|---|"]
        ranked = []
        for want_region in spec["regions"]:
            nm = want_region["name"]
            x, y, rw, rh = want_region["x"], want_region["y"], want_region["w"], want_region["h"]
            n = 0
            for ly in range(y, min(y + rh, h // scale)):
                for lx in range(x, min(x + rw, w // scale)):
                    if sample(gblob, gw, gh, scale, ly, lx) != sample(blob, w, h, scale, ly, lx):
                        n += 1
            ranked.append((n, nm))
            g = gold_per[nm][1]
            c = rec["ink"][nm]
            rows.append(f"| {nm} | {n} | {g:.4f} | {c:.4f} | {c - g:+.4f} |")
        ranked.sort(reverse=True)
        # A container region (one that fully contains another) always out-counts
        # the bands inside it; it is dropped so the failure names a specific band.
        containers = set()
        for outer in spec["regions"]:
            for inner in spec["regions"]:
                if inner is not outer and bbox_contains(
                        (outer["x"], outer["y"], outer["w"], outer["h"]),
                        (inner["x"], inner["y"], inner["w"], inner["h"])):
                    containers.add(outer["name"])
        specific = [(n, nm) for n, nm in ranked if nm not in containers] or ranked
        where = (f"worst region {specific[0][1]} ({specific[0][0]:,} changed px)"
                 if specific and specific[0][0] else "no region-localised change")
        problems.append(
            f"GOLDEN MISMATCH {rec['scene']}: {rec['ppm_sha256'][:16]}… != golden {want[:16]}… "
            f"— {changed:,} px changed, {where}; diff: {ddir / (rec['scene'] + '.diff.png')}")
        diff_lines += [f"\n#### {rec['scene']}", ""] + rows

    if golden_missing and not args["accept"]:
        problems.append("NO GOLDENS for: " + ", ".join(golden_missing)
                        + " — seed them once with `make ui-golden GOLDEN=accept`")

    # ---- invariants vs golden ink (C's tolerance layer) ----
    # Not during an accept: the accept IS the new baseline, so comparing the run
    # to the baseline it is replacing would report the change twice.
    gman_path = art / "golden" / "manifest.json"
    if gman_path.exists() and not args["accept"]:
        gman = json.loads(gman_path.read_text())
        for rec in records:
            g = gman["scenes"].get(rec["scene"])
            if not g:
                continue
            for nm, cur in rec["ink"].items():
                old = g["ink"].get(nm)
                if old is None:
                    continue
                if abs(cur - old) > max(INK_TOL_ABS, INK_TOL_REL * max(old, 1e-6)):
                    problems.append(
                        f"ink drift {nm} ({rec['scene']}): {cur:.4f} vs golden {old:.4f} — "
                        f"beyond {INK_TOL_REL:.0%} / {INK_TOL_ABS} (layout breakage, not a "
                        f"colour tweak)")

    # ---- accept ----
    if args["accept"]:
        gdir = art / "golden"
        gdir.mkdir(parents=True, exist_ok=True)
        for rec in records:
            w, h, blob = read_ppm(art / "scenes" / f"{rec['scene']}.ppm")
            write_png(gdir / f"{rec['scene']}.png", w, h, blob)
        manifest = write_goldens(records, art, args, font)
        print(f"ACCEPTED {len(records)} goldens (renderer {args['src_sha'][:16]}…, "
              f"{manifest['accepted']})")

    # ---- the report ----
    verdict = "PASS" if not problems else "FAIL"
    lines = [f"# UI layout regression — {verdict}", "",
             f"- renderer: `{args['src']}` sha256 `{args['src_sha']}`",
             f"- spec: `{args['spec_path']}` sha256 `{args['spec_sha']}`",
             f"- font: `{font}` sha256 `{sha256_file(font)}`",
             f"- run: {_now()}", "",
             "## scenes", "", "| scene | geometry | sha256 | about |", "|---|---|---|---|"]
    for rec in records:
        lines.append(f"| {rec['scene']} | {rec['geometry'][0]}x{rec['geometry'][1]} | "
                     f"`{rec['ppm_sha256'][:16]}…` | {rec['about']} |")
    lines += ["", "## per-region ink (sampled logical grid)", "",
              "| scene | " + " | ".join(r["name"] for r in spec["regions"]) + " |",
              "|---" * (len(spec["regions"]) + 1) + "|"]
    for rec in records:
        lines.append("| " + rec["scene"] + " | "
                     + " | ".join(f"{rec['ink'][r['name']]:.4f}" for r in spec["regions"]) + " |")
    if notes:
        lines += ["", "## notes / recorded findings", ""] + [f"- {n}" for n in notes]
    if problems:
        lines += ["", "## FAILURES", ""] + [f"- {p}" for p in problems]
    if diff_lines:
        lines += ["", "## golden mismatch, per-region ink", ""] + diff_lines
    (art / "report.md").write_text("\n".join(lines) + "\n")

    for n in notes:
        print(f"note: {n}")
    for p in problems:
        print(f"FAIL: {p}", file=sys.stderr)
    print(f"verdict: {verdict} ({len(records)} scenes, {len(problems)} problem(s)) "
          f"-> {art / 'report.md'}")
    if not problems:
        # A passing run's raw frames are reproducible byte-for-byte and a 1080p PPM
        # is 6.2 MB: the accepted frame is kept as golden/<scene>.png, so the
        # transient copies go. A FAILING run keeps them for the diff.
        for rec in records:
            (art / "scenes" / f"{rec['scene']}.ppm").unlink(missing_ok=True)
    return 0 if not problems else 1


# ── command: anim (D) ─────────────────────────────────────────────────────

def load_sequence(seq_dir):
    seq_dir = Path(seq_dir)
    frames = sorted(seq_dir.glob("*.ppm"))
    if not frames:
        raise SystemExit(f"FATAL: no PPM frames in {seq_dir}")
    meta = {}
    sidecar = seq_dir / "seq.json"
    if sidecar.exists():
        meta = json.loads(sidecar.read_text())
    return frames, meta


def cmd_anim(args):
    spec = json.loads(Path(args["spec_path"]).read_text())
    out = Path(args["art"]) / "anim" / args["runid"]
    out.mkdir(parents=True, exist_ok=True)
    if args["seq_dir"]:
        paths, meta = load_sequence(args["seq_dir"])
        images = [read_ppm(p) for p in paths]
        labels = [p.name for p in paths]
        dt = args["dt"] or meta.get("dt")
        source = f"sequence {args['seq_dir']} ({len(paths)} frames, dt={dt})"
    else:
        from bx510_ui_shot import parse_frames, lift_markers, row_step
        text = Path(args["uart"]).read_text(errors="replace")
        frames, faults = parse_frames(text, row_step(lift_markers(text), text))
        if faults:
            raise SystemExit("FATAL: capture fault: " + "; ".join(faults))
        step = frames[0]["full_geometry"][2] or 1
        gscale = frames[0]["full_geometry"][0] // spec["canvas"]["logical_w"] or 1
        lstep = max(1, step // gscale)
        images = []
        for f in frames:
            raw = bytes(v for px in f["pixels"] for v in px)
            images.append((spec["canvas"]["logical_w"], spec["canvas"]["logical_h"],
                           resample_logical(raw, f["w"], f["h"], lstep,
                                            spec["canvas"]["logical_w"],
                                            spec["canvas"]["logical_h"])[0]))
        labels = [f"{f['label']}-{f['w']}x{f['h']}" for f in frames]
        dt = args["dt"]
        source = (f"guest capture {args['uart']} ({len(frames)} frame(s), device row step "
                  f"{step} = {lstep} logical row(s)/sample, dt={dt or 'UNKNOWN'})")

    problems, notes = [], []
    scale = images[0][0] // spec["canvas"]["logical_w"]
    if scale < 1:
        scale = 1
    per_frame = []
    for (w, h, blob), label in zip(images, labels):
        _, _, row_ink, hist, per = measure(blob, w, h, scale, spec["regions"])
        lamp = next(r for r in spec["motion_regions"] if r["name"] == "lamp")
        lc = sample(blob, w, h, scale, lamp["y"] + lamp["h"] // 2, lamp["x"] + lamp["w"] // 2)
        render = next(r for r in spec["motion_regions"] if r["name"] == "render_line")
        digest = hashlib.sha256()
        for ly in range(render["y"], render["y"] + render["h"]):
            for lx in range(render["x"], render["x"] + render["w"]):
                digest.update(bytes(sample(blob, w, h, scale, ly, lx)))
        per_frame.append({"label": label, "ink": {k: v[1] for k, v in per.items()},
                          "row_ink": row_ink, "lamp_rgb": lc,
                          "lamp_on": _lamp_on(spec, lc),
                          "render_digest": digest.hexdigest(), "w": w, "h": h, "blob": blob})

    # 1. blink period
    states = [f["lamp_on"] for f in per_frame]
    period_frames = _blink_period(states)
    report = [f"# UI animation diff — {args['runid'] or '(sequence)'}", "", f"- source: {source}",
              f"- renderer spec: `{args['spec_path']}`", f"- scale: {scale}", ""]
    report += ["| frame | " + " | ".join(r["name"] for r in spec["regions"]) + " | lamp |",
               "|---" * (len(spec["regions"]) + 2) + "|"]
    for f in per_frame:
        report.append(f"| {f['label']} | "
                      + " | ".join(f"{f['ink'][r['name']]:.4f}" for r in spec["regions"])
                      + f" | {'ON' if f['lamp_on'] else 'off'} |")
    if len(per_frame) < 3:
        # Not a verdict: there is nothing to diff. A single-frame capture is the
        # shape of today's guest template (one dump per buffer, step 10 of
        # tools/bx510_ui_guest.sh.in), so say so and refuse to score it.
        problems.append(
            f"the capture carries {len(per_frame)} frame(s): a time series needs >= 3. The guest "
            f"template dumps one frame per buffer (tools/bx510_ui_guest.sh.in step 10), so a guest "
            f"animation run needs a multi-dump capture; a SIM sequence "
            f"(make ui-anim -> SACD_UI_SIM_SEQ/SACD_UI_SIM_DT) is the ground-truth "
            f"substrate today")
        not_measurable = True
    else:
        not_measurable = False
        if period_frames:
            on = sum(states)
            note = (f"lamp toggles {len([1 for a, b in zip(states, states[1:]) if a != b])} "
                    f"times over {len(states)} frames; period {period_frames:.2f} frames")
            if dt:
                cycle = period_frames * float(dt)
                want = float(spec["pulse"]["cycle_period_s"])
                note += (f" = a {cycle:.3f} s cycle ({2.0 / cycle:.2f} Hz toggle rate) vs the "
                         f"spec's {want} s cycle / {spec['pulse']['hz']} Hz toggle")
                if abs(cycle - want) > 0.10 * want:
                    problems.append(f"blink cycle {cycle:.3f} s is outside 10% of the spec's "
                                    f"{want} s ({note})")
            else:
                note += " (no dt: the capture does not declare its cadence, so no Hz assertion)"
            notes.append(note)
            if on in (0, len(states)):
                problems.append(f"the lamp never toggles ({on}/{len(states)} frames ON) — the "
                                f"pulse is not reaching the framebuffer")
        else:
            problems.append("no blink period could be measured from the lamp pixels")

        # 2. the RENDER line must change every frame; everything else must not
        for i in range(1, len(per_frame)):
            prev, cur = per_frame[i - 1], per_frame[i]
            if prev["render_digest"] == cur["render_digest"]:
                problems.append(f"frame {i}: the RENDER line did not change ({cur['label']}) — "
                                f"the frame/fps/t counters are frozen")
        changed_out = _confinement_problems(spec, per_frame, scale)
        problems += changed_out

        # 3. a GIF of the sequence (ffmpeg if present, never required)
        gif = _gif(out, [p for p in (Path(args["seq_dir"]).glob("*.ppm") if args["seq_dir"] else [])])
        if gif:
            notes.append(f"animation artifact: {gif}")

    report += ["", "## verdict", ""]
    report += [f"- {n}" for n in notes]
    report += [f"- FAIL {p}" for p in problems]
    verdict = "NOT MEASURABLE (capture fault)" if not_measurable else (
        "PASS" if not problems else "FAIL")
    report += ["", f"**{verdict}**"]
    (out / "anim.md").write_text("\n".join(report) + "\n")
    for n in notes:
        print(f"note: {n}")
    for p in problems:
        print(f"FAIL: {p}", file=sys.stderr)
    print(f"verdict: {verdict} -> {out / 'anim.md'}")
    if not_measurable:
        return 2
    if not problems and args["seq_dir"]:
        for frame in sorted(Path(args["seq_dir"]).glob("*.ppm")):
            frame.unlink()          # reproducible from seq.json + the renderer
    return 0 if not problems else 1


def _lamp_on(spec, rgb):
    on = int(spec["palette"]["C_PHOS"], 16) & 0xFFFFFF
    off = int(spec["palette"]["C_DIM"], 16) & 0xFFFFFF
    c = (rgb[0], rgb[1], rgb[2])
    d_on = sum((c[i] - ((on >> (16 - 8 * i)) & 255)) ** 2 for i in range(3))
    d_off = sum((c[i] - ((off >> (16 - 8 * i)) & 255)) ** 2 for i in range(3))
    return d_on <= d_off


def _blink_period(states):
    """mean full cycle length of a two-level series, in frames"""
    runs, cur, n = [], states[0], 1
    for s in states[1:]:
        if s == cur:
            n += 1
        else:
            runs.append((cur, n))
            cur, n = s, 1
    runs.append((cur, n))
    if len(runs) < 3:
        return None
    cycles = [runs[i][1] + runs[i + 1][1] for i in range(len(runs) - 1)]
    return sum(cycles) / len(cycles)


def _confinement_problems(spec, per_frame, scale):
    """Every frame-to-frame change must land inside a declared motion region."""
    problems = []
    allowed = spec["motion_regions"]
    for i in range(1, len(per_frame)):
        a, b = per_frame[i - 1], per_frame[i]
        w, h = a["w"], a["h"]
        lw, lh = w // scale, h // scale
        offenders = {}
        for ly in range(lh):
            xs = []
            for lx in range(lw):
                if sample(a["blob"], w, h, scale, ly, lx) != sample(b["blob"], w, h, scale, ly, lx):
                    xs.append(lx)
            if not xs:
                continue
            x0, x1 = min(xs), max(xs)
            for region in allowed:
                if (region["y"] <= ly < region["y"] + region["h"]
                        and region["x"] <= x0 and x1 < region["x"] + region["w"]):
                    break
            else:
                offenders.setdefault(ly, (x0, x1))
        if offenders:
            rows = sorted(offenders)
            first = rows[0]
            named = []
            for want in spec["regions"]:
                if want["y"] <= first < want["y"] + want["h"]:
                    named.append(want["name"])
            problems.append(
                f"frame {i} ({b['label']}): {len(rows)} row(s) changed OUTSIDE the motion "
                f"regions — first row y={first} x={offenders[first][0]}..{offenders[first][1]} "
                f"in region {'/'.join(named) or '(none)'}. A static scene may only move the "
                f"lamp, the cursor and the RENDER line")
    return problems


def _gif(out, frames):
    if len(frames) < 2:
        return None
    if subprocess.run(["which", "ffmpeg"], capture_output=True).returncode != 0:
        return None
    gif = out / "frames.gif"
    cmd = ["ffmpeg", "-y", "-loglevel", "quiet", "-framerate", "8", "-pattern_type",
           "glob", "-i", str(Path(frames[0]).parent / "*.ppm"),
           "-vf", "scale=480:-1:flags=neighbor", str(gif)]
    if subprocess.run(cmd, capture_output=True).returncode == 0:
        return gif
    return None


# ── command: parity (E) ───────────────────────────────────────────────────

def cmd_parity(args):
    spec = json.loads(Path(args["spec_path"]).read_text())
    art = Path(args["art"])
    out = art / "parity" / args["runid"]
    out.mkdir(parents=True, exist_ok=True)
    scene = args["scene"]
    gppm = art / "golden" / f"{scene}.png"
    if not gppm.exists():
        raise SystemExit(f"FATAL: no golden frame for {scene} at {gppm} — run `make ui-regress` "
                         f"(or `make ui-golden GOLDEN=accept` once) first")
    from bx510_ui_shot import parse_frames, lift_markers, row_step
    text = Path(args["uart"]).read_text(errors="replace")
    frames, faults = parse_frames(text, row_step(lift_markers(text), text))
    if not frames:
        raise SystemExit("FATAL: no decodable frame in the capture" + (": " + "; ".join(faults)
                                                                       if faults else ""))
    present = {(int(m.group(1))) for m in re.finditer(r"^FBPIXROW\s+(\d+)\s+[0-9a-fA-F]+$",
                                                      text, re.M)}

    gw, gh, gblob = read_png(gppm)
    gscale = gw // spec["canvas"]["logical_w"] or 1
    lw, lh = spec["canvas"]["logical_w"], spec["canvas"]["logical_h"]
    problems, rows = [], []
    best = None
    for fr in frames:
        dev_w, dev_h, step = fr["full_geometry"]
        step = step or 1
        lstep = max(1, step // gscale)
        raw = bytes(v for px in fr["pixels"] for v in px)
        guest, present = resample_logical(raw, fr["w"], fr["h"], lstep, lw, lh)
        results = []
        for want in spec["regions"]:
            series_guest, series_gold = [], []
            missing = 0
            for ly in range(want["y"], want["y"] + want["h"]):
                if ly not in present:
                    missing += 1
                    continue
                g = sum(1 for lx in range(want["x"], want["x"] + want["w"])
                        if luminance(sample(guest, lw, lh, 1, ly, lx)) > INK_LUM)
                m = sum(1 for lx in range(want["x"], want["x"] + want["w"])
                        if luminance(sample(gblob, gw, gh, gscale, ly, lx)) > INK_LUM)
                series_guest.append(g)
                series_gold.append(m)
            corr = pearson(series_gold, series_guest)
            guest_ink, gold_ink = sum(series_guest), sum(series_gold)
            if corr is None:
                # No variance in one of the series (a blank band): fall back to
                # comparing total ink instead of pretending a correlation exists.
                ok = abs(guest_ink - gold_ink) <= max(0.10 * gold_ink, 20)
                reason = (f"correlation undefined (a flat series); ink {guest_ink} vs golden "
                          f"{gold_ink} px")
            else:
                ok = corr >= PARITY_MIN_CORR
                reason = f"corr {corr:.3f} over {len(series_guest)} rows; ink {guest_ink} vs golden {gold_ink} px"
            # A region that carries a quarter of the predicted ink is not a
            # layout difference, it is missing content — correlation alone can
            # be fooled by two sparse rows.
            if gold_ink and guest_ink < 0.25 * gold_ink:
                ok = False
                reason += " — the guest region carries under a quarter of the predicted ink"
            if missing:
                reason += f"; {missing} predicted row(s) not in the capture"
            results.append((want["name"], ok, reason))
            if corr is not None and (best is None or corr < best[1]):
                best = (want["name"], corr)
        rows.append((fr["label"], fr["w"], fr["h"], step, fr["lost_rows"], results))
        for name, ok, reason in results:
            if not ok:
                problems.append(f"parity {name} ({fr['label']}): {reason}")

    report = [f"# UI guest parity — {args['runid'] or '(capture)'}", "",
              f"- guest capture: `{args['uart']}` (row step {frames[0]['full_geometry'][2]})",
              f"- SIM golden: `{gppm}` ({gw}x{gh})", f"- scene: {scene}", "",
              "## per-frame, per-region", ""]
    for label, w, h, step, lost, results in rows:
        report.append(f"### {label} — {w}x{h}, row step {step}, {lost} damaged row(s)")
        report.append("")
        report.append("| region | verdict | evidence |")
        report.append("|---|---|---|")
        for name, ok, reason in results:
            report.append(f"| {name} | {'PASS' if ok else 'FAIL'} | {reason} |")
        report.append("")
    verdict = "PASS" if not problems else "FAIL"
    report += [f"**verdict: {verdict}** — the guest renders what the Mac predicts when every "
               f"region correlates >= {PARITY_MIN_CORR}"]
    if best:
        report.append("")
        report.append(f"weakest region: {best[0]} (corr {best[1]:.3f})")
    (out / "parity.md").write_text("\n".join(report) + "\n")
    for label, w, h, step, lost, results in rows:
        print(f"{label}: {len(results)} regions, {lost} damaged rows")
    for p in problems:
        print(f"FAIL: {p}", file=sys.stderr)
    print(f"verdict: {verdict} -> {out / 'parity.md'}")
    return 0 if not problems else 1


# ── command: seq (render a SIM sequence for the animation diff) ───────────

def cmd_seq(args):
    art = Path(args["art"])
    font = Path(args["font"])
    binary = build(args["src"], art, spec_dump=False)
    fixtures = resolve_fixtures(art)
    out = art / "anim" / (args["runid"] or "sim-sequence") / "frames"
    if out.exists():
        for old in out.glob("*.ppm"):
            old.unlink()
    out.mkdir(parents=True, exist_ok=True)
    scene = next(s for s in scene_defs(fixtures) if s["name"] == "s1-full")
    env = dict(os.environ)
    env["SACD_UI_FONT"] = str(font)
    env.update(scene["env"])
    env["SACD_UI_SIM_SEQ"] = str(args["frames"])
    env["SACD_UI_SIM_DT"] = str(args["dt"])
    env["SACD_UI_SCALE"] = str(args["scale"])
    argv = [str(binary), *[str(a) for a in scene["args"]], str(out)]
    r = subprocess.run(argv, capture_output=True, text=True, env=env)
    if r.returncode != 0:
        raise SystemExit(f"FATAL: sequence render failed rc={r.returncode}:\n{r.stderr}")
    (out / "seq.json").write_text(json.dumps({
        "schema": "sacd-ui-regress-seq/1",
        "generated": _now(),
        "scene": scene["name"],
        "dt": args["dt"],
        "frames": args["frames"],
        "scale": args["scale"],
        "renderer_sha256": args["src_sha"],
        "note": "SIM ground truth for the animation diff: t_k = k*dt is exact, so the 2 Hz "
                "pulse has an analytically known period",
    }, indent=2) + "\n")
    print(f"rendered {args['frames']} frames dt={args['dt']} -> {out}")
    print(f"now: ui_regress.py anim --seq-dir {out}")
    return 0


# ── main ──────────────────────────────────────────────────────────────────

def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("cmd", nargs="?", default="regress",
                    choices=["regress", "golden", "scenes", "anim", "parity", "seq"])
    ap.add_argument("--spec", default=str(DEFAULT_SPEC))
    ap.add_argument("--src", default=str(DEFAULT_SRC),
                    help="the renderer to regress (default tools/sacd_ui.c; a pinned ref works)")
    ap.add_argument("--art", default=str(DEFAULT_ART))
    ap.add_argument("--font", default=str(DEFAULT_FONT))
    ap.add_argument("--accept", action="store_true", help="re-seed the goldens (explicit!)")
    ap.add_argument("--seq-dir", default=None, help="anim: a rendered PPM sequence")
    ap.add_argument("--uart", default=None, help="anim/parity: a fire's UART transcript")
    ap.add_argument("--dt", type=float, default=None,
                    help="anim: seconds between captured frames (a guest capture has no clock)")
    ap.add_argument("--frames", type=int, default=12, help="seq: frame count (default 12)")
    ap.add_argument("--scale", type=int, default=1, help="seq: logical->device scale (default 1)")
    ap.add_argument("--runid", default="", help="artifact subdirectory name")
    ap.add_argument("--scene", default="s1-full", help="parity: the scene the capture shows")
    a = ap.parse_args(argv)

    src = Path(a.src)
    if not src.exists():
        raise SystemExit(f"FATAL: renderer source not found: {src}")
    args = {"src": src, "src_sha": sha256_file(src), "spec_path": Path(a.spec),
            "spec_sha": sha256_file(a.spec), "art": a.art, "font": a.font,
            "accept": a.accept, "fixtures": None}
    args["fixtures"] = resolve_fixtures(Path(a.art))

    if a.cmd in ("regress", "golden", "scenes"):
        if a.cmd == "golden" and not a.accept:
            raise SystemExit("REFUSING: `golden` without --accept. Goldens change only on an "
                             "explicit accept (`make ui-golden GOLDEN=accept`).")
        if a.cmd == "scenes":
            spec = json.loads(Path(a.spec).read_text())
            art = Path(a.art)
            font = Path(a.font)
            art.mkdir(parents=True, exist_ok=True)
            render_scenes(args, spec, build(src, art, False), build(src, art, True), art, font)
            return 0
        if a.cmd == "golden":
            args["accept"] = True
        return run_regress(args)
    if a.cmd == "seq":
        args["runid"] = a.runid
        args["frames"] = a.frames
        args["dt"] = a.dt or 0.125
        args["scale"] = a.scale
        return cmd_seq(args)
    if a.cmd == "anim":
        return cmd_anim({"spec_path": a.spec, "art": a.art, "runid": a.runid,
                         "seq_dir": a.seq_dir, "uart": a.uart, "dt": a.dt})
    return cmd_parity({"spec_path": a.spec, "art": a.art, "runid": a.runid,
                       "uart": a.uart, "scene": a.scene})


if __name__ == "__main__":
    sys.exit(main())
