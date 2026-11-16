#!/usr/bin/env python3
"""bx510_ui_shot.py — captured frame(s) -> PNG/GIF + a luminance verdict.

The egress leg of the UI loop. The guest dumps its framebuffer with
tools/bx510_fbdump.c as text over the UART:

    FBGEOM <dev> <w> <h> <bpp> <stride>
    FBPIX  <hex>        RGB888 row-major, every Nth pixel (fbdump's scale)
    FBEND

so any capture that carries those lines decodes here — the whole UART
transcript of a fire (bx510-fire pulls it into evidence/) or one
/res/fb-*.txt pulled off the VM.

Three input modes, same decode path:
  --uart LOG      the pulled UART transcript (the normal path)
  --fbtext FILE   one raw fbdump text file
  --fbimage FILE  a FILE-BACKED framebuffer: the raw device contents
                  (--geom WxH, 32bpp ARGB little-endian = fbdump's p[2]p[1]p[0]).
                  This is the fake fbdev the loop's smoke test runs against —
                  no QEMU, no VM, the same decode and the same verdict.

Output (--out DIR): <label>-<w>x<h>.ppm + .png per frame, plus .gif when there
is more than one frame and ffmpeg is on PATH, plus shot.md (geometry, mean
luminance, verdict per frame, and the run's verdict markers lifted out of the
transcript — FIRE_RC / CLIENT_RC / UI_RC / UI_DUMP_* / FA_MODE).

Verdict: a frame PASSES when its mean luminance is >= --min-lum (default 4.0,
the guest-gate threshold in tools/hud_guest_gate.py — same r*30+g*59+b*11
weights, no sampling needed here because the pixels are already decoded).
Exit: 0 at least one frame passed, 1 frames found but all black, 2 no
frame / a capture fault (truncated dump) / a transcript that is not this fire.

Pure stdlib (zlib PNG writer) on purpose: `uv run pytest -m "not smoke"` has no
PIL, and the verdict must be runnable in the same interpreter as the tests.
"""
import argparse
import re
import struct
import subprocess
import sys
import zlib
from pathlib import Path

FBGEOM_RE = re.compile(r"FBGEOM\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)")
FBPIX_RE = re.compile(r"FBPIX\s+([0-9a-fA-F]+)")
FBPIXROW_RE = re.compile(r"FBPIXROW\s+(\d+)\s+([0-9a-fA-F]+)")

# The markers the UI fire's guest command emits (tools/bx510_ui_guest.sh.in).
# Lifted into shot.md so the artifact says WHY a frame is what it is: a black
# frame from a failed client read and a black frame from an empty UI are
# different problems.
MARKERS = ("FIRE_RC", "FA_MODE", "DAEMON_PID", "DAEMON_ORACLE", "CLIENT_RC",
           "CLIENT_PASS", "UI_RC", "UI_SCALE", "UI_DUMP_FBDEV", "UI_DUMP_POOL",
           "UI_SHOT_DONE", "UI_PID")


def mean_luminance(pixels):
    """Mean luminance of an iterable of (r, g, b). Same weights as the guest gate."""
    total = n = 0
    for r, g, b in pixels:
        total += (r * 30 + g * 59 + b * 11) // 100
        n += 1
    return total / n if n else 0.0


def hex_to_pixels(hexstr, w, h, label):
    """FBPIX hex -> [(r,g,b)] row-major, for the SAMPLED geometry w x h.

    Raises ValueError on a short buffer: a dump that does not match its own
    geometry was cut off mid-frame, which is a capture fault and must never be
    reported as a black (drawn-nothing) screen.
    """
    wrap = 6
    want = w * h
    got = len(hexstr) // wrap
    if got != want:
        raise ValueError(
            f"{label}: FBPIX holds {got} pixels, sampled geometry says "
            f"{w}x{h}={want} (the dump was truncated — a short UART read, not "
            "a blank screen)")
    return [(int(hexstr[i:i + 2], 16), int(hexstr[i + 2:i + 4], 16),
             int(hexstr[i + 4:i + 6], 16)) for i in range(0, want * wrap, wrap)]


def row_step(markers, text=""):
    """The dump's row step: the guest's UI_SCALE marker, else the row deltas.

    A bare fbdump text file (`--fbtext`, one /res/fb-*.txt pulled off the VM)
    carries no scale marker, and assuming step 1 turns every sampled row into a
    "lost" row. The emitted row indices ARE the step, so read it off them.
    """
    m = re.search(r"UI_SCALE=(\d+)", markers.get("UI_SCALE", ""))
    if m:
        return max(1, int(m.group(1)))
    ys = sorted({int(m.group(1)) for m in (FBPIXROW_RE.search(ln) for ln in text.splitlines()) if m})
    deltas = [b - a for a, b in zip(ys, ys[1:]) if b > a]
    return min(deltas) if deltas else 1


def sampled_dims(w, h, step):
    """Full geometry -> the dims fbdump's every-<step>-th-pixel dump covers."""
    return (w + step - 1) // step, (h + step - 1) // step


def parse_frames(text, step=1):
    """Every FBGEOM/FBPIXROW|FBPIX/FBEND block -> (frames, faults).

    Two shapes, because the guest's console interleaves:
      FBPIX     <one long hex>      the pre-c123c shape; any interleaving
                                    truncates it and the frame is lost
      FBPIXROW  <y> <row hex>       one line per sampled row (`fbdump --rows`);
                                    a lost row costs a row, and the loss is
                                    counted into the frame's report
    A block that cannot be reconstructed at all (short FBPIX, no rows) becomes a
    FAULT: the other buffer's frame is still worth seeing, but the run is a
    capture fault and must not read as "the UI drew nothing".
    """
    frames, faults, geom = [], [], None
    pix, rows = None, {}
    for line in text.splitlines():
        m = FBGEOM_RE.search(line)
        if m:
            geom = (m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(4)),
                    int(m.group(5)))
            pix, rows = None, {}
            continue
        if geom is None:
            continue
        m = FBPIXROW_RE.search(line)
        if m:
            rows[int(m.group(1))] = m.group(2)
            continue
        m = FBPIX_RE.search(line)
        if m:
            pix = m.group(1)
            continue
        if "FBEND" not in line or (pix is None and not rows):
            continue

        dev, w, h, bpp, stride = geom
        label = "pool" if "(pool)" in dev else "fbdev"
        sw, sh = sampled_dims(w, h, step)
        if pix is not None:
            try:
                frames.append({"label": label, "dev": dev, "w": sw, "h": sh,
                               "bpp": bpp, "stride": stride, "lost_rows": 0,
                               "full_geometry": (w, h, step),
                               "pixels": hex_to_pixels(pix, sw, sh, label)})
            except ValueError as exc:
                faults.append(str(exc))
        else:
            lost = []          # filled by the row loop below, once per lost row
            width = len(next(iter(rows.values()))) // 6
            blank = [(0, 0, 0)] * width
            pixels = []
            for i in range(sh):
                hexrow = rows.get(i * step)
                # A row that is missing OR cut short by a console write is a
                # LOST row, not a fault: row granularity is the whole reason
                # the dump is emitted per row (c123c), and every real fire
                # loses a handful. The count lands in the report.
                row_pixels = None
                if hexrow is not None and len(hexrow) // 6 == width:
                    row_pixels = hex_to_pixels(hexrow, width, 1, f"{label} row {i * step}")
                if row_pixels is None:
                    pixels.extend(blank)
                    lost.append(i)
                    continue
                pixels.extend(row_pixels)
            if len(rows) == 0:
                faults.append(f"{label}: no rows")
            else:
                frames.append({"label": label, "dev": dev, "w": width, "h": sh,
                               "bpp": bpp, "stride": stride,
                               "lost_rows": len(lost),
                               "full_geometry": (w, h, step),
                               "pixels": pixels})
        geom, pix, rows = None, None, {}
    return frames, faults


def fbimage_pixels(path, w, h):
    """A file-backed framebuffer's raw contents -> [(r,g,b)] (ARGB32 LE = BGRA bytes)."""
    blob = Path(path).read_bytes()
    need = w * h * 4
    if len(blob) < need:
        raise ValueError(f"{path}: {len(blob)} B is short of {need} B for {w}x{h}x32bpp")
    out = []
    for i in range(0, need, 4):
        out.append((blob[i + 2], blob[i + 1], blob[i]))     # fbdump prints p[2]p[1]p[0]
    return out


def write_ppm(path, w, h, pixels):
    body = bytearray()
    for r, g, b in pixels:
        body += bytes((r, g, b))
    Path(path).write_bytes(f"P6\n{w} {h}\n255\n".encode() + bytes(body))


def write_png(path, w, h, pixels):
    """Minimal RGB8 PNG (filter 0 per row) — no third-party dependency."""
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        for r, g, b in pixels[y * w:(y + 1) * w]:
            raw += bytes((r, g, b))

    def chunk(tag, data):
        body = tag + data
        return (struct.pack(">I", len(data)) + body
                + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF))

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    Path(path).write_bytes(png)


def write_gif(out_dir, frames, scale_width=480):
    """Animated GIF from the PNG/PPM frames — only if ffmpeg is on PATH."""
    ffmpeg = subprocess.run(["which", "ffmpeg"], capture_output=True, text=True)
    if ffmpeg.returncode != 0:
        return None
    gif = Path(out_dir) / "frames.gif"
    cmd = ["ffmpeg", "-y", "-loglevel", "quiet", "-framerate", "2",
           "-pattern_type", "glob", "-i", str(Path(out_dir) / "*-*.ppm"),
           "-vf", f"scale={scale_width}:-1:flags=neighbor", str(gif)]
    if subprocess.run(cmd, capture_output=True).returncode == 0:
        return gif
    return None


def lift_markers(text):
    """LAST occurrence of each run marker -> {name: 'line'} (verdict context).

    Last, not first: the guest console echoes the whole one-line command before
    running it, so the first match for e.g. UI_SHOT_DONE is the echo. The
    prompt-prefixed lines ('/ # ...') are that echo and are skipped outright.
    """
    found = {}
    for line in text.splitlines():
        if line.lstrip().startswith("/ # "):
            continue
        for name in MARKERS:
            if name in line:
                found[name] = line.strip()[:200]
    return found


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--uart", type=Path, help="the fire's UART transcript")
    src.add_argument("--fbtext", type=Path, help="one raw fbdump text file")
    src.add_argument("--fbimage", type=Path,
                     help="a file-backed framebuffer (raw ARGB32 device contents)")
    ap.add_argument("--geom", default="1920x1080", help="--fbimage geometry (WxH)")
    ap.add_argument("--out", type=Path, required=True, help="artifact directory")
    ap.add_argument("--runid", default="", help="run id for the report/markers")
    ap.add_argument("--min-lum", type=float, default=4.0,
                    help="black-frame threshold (guest-gate default: 4.0)")
    a = ap.parse_args(argv)

    a.out.mkdir(parents=True, exist_ok=True)
    notes, markers, faults = [], {}, []
    try:
        if a.fbimage:
            w, h = (int(v) for v in a.geom.lower().split("x"))
            text = ""
            frames = [{"label": "fbimage", "dev": str(a.fbimage), "w": w, "h": h,
                       "bpp": 32, "stride": w * 4,
                       "pixels": fbimage_pixels(a.fbimage, w, h)}]
        else:
            text = a.uart.read_text(errors="replace") if a.uart else a.fbtext.read_text(errors="replace")
            markers = lift_markers(text)
            frames, faults = parse_frames(text, row_step(markers, text))
    except (OSError, ValueError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 2

    # Capture identity. Traces live at /tmp/bdpdrv-run<RUNID>.* on the VM and a
    # second lane that reuses a RUNID overwrites yours — observed for real: a
    # UI-lane fire pulled another lane's transcript, which happened to carry
    # FBGEOM blocks and would have "passed" as a frame from a build nobody
    # asked about. The template's own last marker makes that impossible to
    # mistake for a verdict.
    if a.uart and "UI_SHOT_DONE" not in markers:
        print("FAIL: this transcript is not a bx510-ui-fire run (no "
              "UI_SHOT_DONE marker) — wrong RUNID pulled, or the fire died "
              "before the capture step", file=sys.stderr)
        return 2

    if not frames:
        for fault in faults:
            print(f"FAIL: {fault}", file=sys.stderr)
        print("FAIL: no decodable FBGEOM/FBPIX/FBEND frame in the capture — the "
              "egress step did not run, or its output never reached the "
              "transcript", file=sys.stderr)
        return 2

    report = [f"# UI shot — run {a.runid or '(unspecified)'}", ""]
    if a.uart:
        report.append(f"capture: `{a.uart}` (UART transcript)")
    elif a.fbtext:
        report.append(f"capture: `{a.fbtext}` (fbdump text)")
    else:
        report.append(f"capture: `{a.fbimage}` (file-backed framebuffer, "
                      f"{frames[0]['w']}x{frames[0]['h']}x32) — the off-QEMU path")
    report += ["", "| frame | buffer | geometry | mean luminance | verdict | png |",
               "|---|---|---|---|---|---|"]

    passed = []
    for fr in frames:
        lum = mean_luminance(fr["pixels"])
        ok = lum >= a.min_lum
        stem = f"{fr['label']}-{fr['w']}x{fr['h']}"
        ppm = a.out / f"{stem}.ppm"
        png = a.out / f"{stem}.png"
        write_ppm(ppm, fr["w"], fr["h"], fr["pixels"])
        write_png(png, fr["w"], fr["h"], fr["pixels"])
        verdict = "PASS" if ok else "BLACK"
        report.append(f"| {fr['label']} | {fr['dev']} | {fr['w']}x{fr['h']} | "
                      f"{lum:.2f} | {verdict} | `{png.name}` |")
        if ok:
            passed.append(png)
        note = f"{fr['label']}: mean luminance {lum:.2f} -> {verdict}"
        if fr.get("lost_rows"):
            g = fr["full_geometry"]
            note += (f" ({fr['lost_rows']} of {fr['h']} sampled rows lost to "
                     f"console interleaving; zero-filled — geometry {g[0]}x{g[1]}"
                     f" / {g[2]})")
        notes.append(note)

    gif = write_gif(a.out, frames) if len(frames) > 1 else None
    if gif:
        report += ["", f"animation: `{gif.name}` ({len(frames)} frames)"]

    if markers:
        report += ["", "## run markers", ""]
        for name in MARKERS:
            if name in markers:
                report.append(f"- `{name}`: `{markers[name]}`")
        missing = [n for n in MARKERS if n not in markers]
        if missing:
            report.append(f"- absent: {', '.join(missing)}")

    for fault in faults:
        report += ["", f"**capture fault:** {fault}"]
    overall = "PASS" if passed else "FAIL"
    if faults:
        overall += " (with a capture fault)"
    report += ["", f"**verdict: {overall}** — " + "; ".join(notes)]
    (a.out / "shot.md").write_text("\n".join(report) + "\n")

    for line in notes:
        print(line)
    for fault in faults:
        print(f"capture fault: {fault}", file=sys.stderr)
    print(f"verdict: {overall} ({len(frames)} frame(s) -> {a.out})")
    if gif:
        print(f"animation: {gif}")
    # A truncated dump outranks the frame that did land: exit 2 = capture fault
    # (the frames are still written; the report says which buffer is missing).
    if faults:
        return 2
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
