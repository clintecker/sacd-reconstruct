#!/usr/bin/env python3
"""Regression controls for the UI iteration loop (build -> fire -> shot).

The loop's expensive half is QEMU, so the controls run the whole chain against
a FILE-BACKED framebuffer: a raw ARGB32 image standing in for /dev/fb0's
contents. Everything downstream of the guest is then the real code —
bx510_ui_shot.py's decode, its PNG writer and its luminance verdict — which is
where a broken loop actually hides (a frame that arrives but decodes to black
looks exactly like a UI that drew nothing).

What CANNOT run here is the two VM legs (era build, QEMU fire). Those are
asserted at the wiring level instead: the make target must chain build -> fire
-> shot in that order, and each recipe must call the tool this file exercises.

Run directly (python3 tools/test_bx510_ui_loop.py) or via pytest.
"""
import struct
import subprocess
import sys
import zlib
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
REPO = TOOLS.parent
TEMPLATE = TOOLS / "bx510_ui_guest.sh.in"
RENDER = TOOLS / "bx510_ui_render.py"
SHOT = TOOLS / "bx510_ui_shot.py"
BUILD = TOOLS / "bx510_ui_build.sh"

FA_CLEAR = "/res/shim/sr_fa_mode /dev/sr0 clear"
DAEMON_LAUNCH = "./sacd_extract_160 -S"


def run(*args, **kw):
    return subprocess.run([sys.executable, *map(str, args)],
                          capture_output=True, text=True, **kw)


def run_sh(*args):
    return subprocess.run(["sh", *map(str, args)], capture_output=True, text=True)


def write_fake_fbdev(path, w=96, h=54, colour=(0x28, 0x6c, 0xd8), amp=3):
    """A file-backed framebuffer: raw ARGB32 little-endian, what fbdump mmaps.

    A gradient rather than a flat fill so a row-stride mistake in the decoder
    changes the pixels instead of hiding in one repeated value.
    """
    buf = bytearray()
    for y in range(h):
        for x in range(w):
            r = min(255, colour[0] + x * amp)
            g = min(255, colour[1] + y * amp)
            buf += bytes((colour[2], g, r, 0xFF))     # B, G, R, A
    Path(path).write_bytes(bytes(buf))
    return w, h


def fake_uart_transcript(path, frames, shot_marker=True):
    """A transcript shaped like a UI fire's, with one FBGEOM/FBPIX/FBEND per frame.

    frames: [(dev, w, h, pixels)]; pixels are (r, g, b) row-major, exactly the
    RGB888 fbdump prints (p[2]p[1]p[0] per pixel, every scale-th pixel).
    shot_marker=False drops the template's own end marker — the shape of a
    transcript lifted from a foreign run.
    """
    lines = ["UI_DUMP_FBDEV=0", "UI_DUMP_POOL=0", "CLIENT_RC=0", "UI_RC=0",
             "FA_MODE fa=0 rc=0 be_quiet=0 rc=0"]
    for dev, w, h, pixels in frames:
        lines.append(f"FBGEOM {dev} {w} {h} 32 {w * 4}")
        lines.append("FBPIX " + "".join("%02x%02x%02x" % px for px in pixels))
        lines.append("FBEND")
    lines += ["UI_FBDEV_END", "UI_POOL_END"]
    if shot_marker:
        lines += ["echo UI_SHOT_DONE", "UI_SHOT_DONE"]
    Path(path).write_text("\n".join(lines) + "\n")


def decode_png(path):
    """-> (w, h, raw scanlines) for the RGB8 PNGs bx510_ui_shot.py writes."""
    blob = Path(path).read_bytes()
    assert blob[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
    pos, idat, w, h = 8, b"", 0, 0
    while pos < len(blob):
        (length,) = struct.unpack(">I", blob[pos:pos + 4])
        tag = blob[pos + 4:pos + 8]
        data = blob[pos + 8:pos + 8 + length]
        if tag == b"IHDR":
            w, h = struct.unpack(">II", data[:8])
        elif tag == b"IDAT":
            idat += data
        pos += 12 + length
    return w, h, zlib.decompress(idat)


# ── the guest-command render: the FA-latch rule must be enforced, not hoped ──

def render_into(tmp_path, name="r", *extra):
    out = tmp_path / f"g-{name}.txt"
    script = tmp_path / f"bx510_ui_guest-{name}.sh"
    r = run(RENDER, "--runid", name, "--out", out, "--script", script, *extra)
    return r, out, script


def test_render_splits_into_a_staged_script_and_a_short_fire_command(tmp_path):
    """The guest console cannot carry the scenario, so the command must not try.

    Measured (run uiloop3): a ~1350-byte one-line guest command was cut at
    "/bin/sh: slee: not found" and the rest of the scenario silently never ran.
    """
    r, out, script = render_into(tmp_path)
    assert r.returncode == 0, r.stdout + r.stderr
    cmd = out.read_text().strip()
    assert "\n" not in cmd
    assert cmd.startswith("tar -xzf /res/shim/daemon_payload.tgz")
    assert script.name in cmd, "the fire command must run the staged script"
    assert len(cmd) < 300, f"the fire command is {len(cmd)} B — keep it far under the console limit"
    assert "sr_fa_mode" not in cmd, "the scenario belongs in the staged script, not the command"

    body = script.read_text()
    code = "\n".join(ln.strip() for ln in body.splitlines()
                      if ln.strip() and not ln.strip().startswith("#"))
    assert "@" not in code, "unrendered placeholder"
    assert FA_CLEAR in code
    assert code.index(FA_CLEAR) < code.index(DAEMON_LAUNCH), \
        "the clear must precede the daemon's /dev/sr0 open or it is thrown away"
    assert "mount -t tmpfs tmpfs /tmp" in code
    assert code.rstrip().endswith("echo UI_SHOT_DONE")


def test_render_refuses_a_template_without_the_fa_latch_clear(tmp_path):
    tmpl = tmp_path / "no-latch.sh.in"
    tmpl.write_text(TEMPLATE.read_text().replace(FA_CLEAR, "# (clear removed by the control)"))
    r = run(RENDER, "--runid", "c901", "--template", tmpl, "--print-only")
    assert r.returncode == 1, "a fire without the FA-latch clear must not render"
    assert "FA-latch" in r.stdout + r.stderr
    assert "c122f" in r.stderr


def test_render_refuses_a_clear_placed_after_the_daemon_launch(tmp_path):
    """Same lines, wrong order — the c122f shape one step further along."""
    lines = [ln for ln in TEMPLATE.read_text().splitlines()]
    clear = [ln for ln in lines if ln.strip() == FA_CLEAR]
    launch = [i for i, ln in enumerate(lines) if ln.strip().startswith(DAEMON_LAUNCH)]
    assert clear and launch
    moved = [ln for ln in lines if ln.strip() != FA_CLEAR]
    moved.insert(moved.index(lines[launch[0]]) + 1, clear[0])
    tmpl = tmp_path / "late-latch.sh.in"
    tmpl.write_text("\n".join(moved) + "\n")
    r = run(RENDER, "--runid", "c902", "--template", tmpl, "--print-only")
    assert r.returncode == 1
    assert "BEFORE the daemon" in r.stdout


def test_render_refuses_an_unknown_placeholder(tmp_path):
    tmpl = tmp_path / "typo.sh.in"
    tmpl.write_text(TEMPLATE.read_text().replace("@SCALE@", "@SCALEE@"))
    r = run(RENDER, "--runid", "c903", "--template", tmpl, "--print-only")
    assert r.returncode == 1
    assert "placeholder" in r.stderr


# ── the capture leg: fake framebuffer -> PNG + luminance verdict ────────────

def test_fake_fbdev_frame_becomes_a_png_with_a_pass_verdict(tmp_path):
    img = tmp_path / "fb0.img"
    w, h = write_fake_fbdev(img)
    out = tmp_path / "shots"
    r = run(SHOT, "--fbimage", img, "--geom", f"{w}x{h}", "--out", out,
            "--runid", "fake1")
    assert r.returncode == 0, r.stdout + r.stderr
    png = out / f"fbimage-{w}x{h}.png"
    assert png.exists()
    pw, ph, raw = decode_png(png)
    assert (pw, ph) == (w, h)
    assert len(raw) == h * (1 + w * 3)
    assert all(raw[y * (1 + w * 3)] == 0 for y in range(h)), "filter byte must be 0"
    # the first pixel round-trips through the ARGB32 write and the PNG write
    assert tuple(raw[1:4]) == (0x28, 0x6c & 0xFF, 0xd8)
    report = (out / "shot.md").read_text()
    assert "verdict: PASS" in report


def test_black_fake_fbdev_fails_the_verdict(tmp_path):
    img = tmp_path / "fb0-black.img"
    w, h = 96, 54
    img.write_bytes(bytes(w * h * 4))
    out = tmp_path / "shots"
    r = run(SHOT, "--fbimage", img, "--geom", f"{w}x{h}", "--out", out)
    assert r.returncode == 1, "a black frame must FAIL, not pass quietly"
    assert "BLACK" in (out / "shot.md").read_text()


def test_uart_transcript_yields_one_frame_per_buffer(tmp_path):
    """fbdev smem empty + pool primary drawn is the DirectFB-app shape."""
    w, h = 8, 4
    drawn = [(0x30, 0x90, 0x20)] * (w * h)
    empty = [(0, 0, 0)] * (w * h)
    log = tmp_path / "run.uart.log"
    fake_uart_transcript(log, [("/dev/fb0", w, h, empty),
                               ("/dev/fb0(pool)", w, h, drawn)])
    out = tmp_path / "shots"
    r = run(SHOT, "--uart", log, "--out", out, "--runid", "fake2")
    assert r.returncode == 0, r.stdout + r.stderr
    assert (out / f"fbdev-{w}x{h}.png").exists()
    assert (out / f"pool-{w}x{h}.png").exists()
    report = (out / "shot.md").read_text()
    assert "| fbdev |" in report and "| pool |" in report
    assert "UI_SHOT_DONE" in report, "run markers must land in the artifact"
    assert "verdict: PASS" in report


def test_row_mode_dump_survives_a_lost_row(tmp_path):
    """`fbdump --rows`: one interleaved console write costs a row, not the frame.

    Measured reason (c123c): a single 691 KB FBPIX line gets interleaved by the
    kernel's console writers and truncated mid-hex, so the whole dump is gone.
    Per-row lines confine the damage — and the decoder must say how much it
    lost instead of silently showing a zero row.
    """
    w, h, step = 90, 36, 6                 # -> 15 x 6 sampled pixels
    sw, sh = (w + step - 1) // step, (h + step - 1) // step
    lines = ["UI_SCALE=%d" % step, "UI_DUMP_FBDEV=0",
             f"FBGEOM /dev/fb0 {w} {h} 32 {w * 4}"]
    for i in range(sh):
        if i == 2:
            continue                        # the row the console ate
        y = i * step
        row = "".join("%02x%02x%02x" % (0x40, 0x80 + y, 0x20) for _ in range(sw))
        lines.append(f"FBPIXROW {y} {row}")
    lines += ["FBEND", "UI_FBDEV_END", "UI_SHOT_DONE"]
    log = tmp_path / "rows.uart.log"
    log.write_text("\n".join(lines) + "\n")
    out = tmp_path / "shots"
    r = run(SHOT, "--uart", log, "--out", out, "--runid", "rows")
    assert r.returncode == 0, r.stdout + r.stderr
    pw, ph, _raw = decode_png(out / f"fbdev-{sw}x{sh}.png")
    assert (pw, ph) == (sw, sh)
    report = (out / "shot.md").read_text()
    assert "1 of 6 sampled rows lost" in report
    assert "verdict: PASS" in report


def test_bare_fbdump_text_infers_the_row_step(tmp_path):
    """`--fbtext` (one /res/fb-*.txt pulled off the VM) has no UI_SCALE marker.

    Assuming step 1 there turns every sampled row into a "lost" row; the emitted
    row indices are the step, so the decoder must read it off them — and both
    egress paths must agree on the numbers for the same guest dump.
    """
    w, h, step = 90, 36, 6
    sw, sh = (w + step - 1) // step, (h + step - 1) // step
    lines = [f"FBGEOM /dev/fb0 {w} {h} 32 {w * 4}"]
    for i in range(sh):
        row = "".join("%02x%02x%02x" % (0x40, 0x80 + i * step, 0x20) for _ in range(sw))
        lines.append(f"FBPIXROW {i * step} {row}")
    lines.append("FBEND")
    fbtext = tmp_path / "fb-fbdev.txt"
    fbtext.write_text("\n".join(lines) + "\n")
    out = tmp_path / "shots"
    r = run(SHOT, "--fbtext", fbtext, "--out", out)
    assert r.returncode == 0, r.stdout + r.stderr
    assert (out / f"fbdev-{sw}x{sh}.png").exists()
    report = (out / "shot.md").read_text()
    assert "| fbdev | /dev/fb0 | 15x6 |" in report, report
    assert "sampled rows lost" not in report, "a complete dump is not lossy"


def test_foreign_transcript_is_not_read_as_a_verdict(tmp_path):
    """The wrong-run pull: frames present, but not this fire's run.

    Real event: a UI-lane fire pulled another lane's trace (same RUNID, shared
    /tmp/bdpdrv-run<RUNID>.*) and it carried FBGEOM blocks — a frame from a
    build nobody asked about. It must be a capture error, not a PASS.
    """
    w, h = 8, 4
    log = tmp_path / "foreign.uart.log"
    fake_uart_transcript(log, [("/dev/fb1(pool)", w, h, [(0x40, 0x80, 0x20)] * (w * h))],
                         shot_marker=False)
    out = tmp_path / "shots"
    r = run(SHOT, "--uart", log, "--out", out)
    assert r.returncode == 2, "a foreign transcript must not produce a verdict"
    assert "not a bx510-ui-fire run" in r.stderr
    assert not (out / "shot.md").exists()


def test_truncated_fbpix_is_a_capture_fault_not_a_black_frame(tmp_path):
    w, h = 8, 4
    log = tmp_path / "short.uart.log"
    fake_uart_transcript(log, [("/dev/fb0", w, h, [(9, 9, 9)] * 5)])   # 5 of 32
    r = run(SHOT, "--uart", log, "--out", tmp_path / "shots")
    assert r.returncode == 2, "a short dump is a capture fault (exit 2), not a verdict"
    assert "truncated" in r.stderr


# ── wiring: the targets must chain the tools in the loop's order ────────────

def test_loop_target_chains_build_fire_shot_in_order():
    makefile = (REPO / "Makefile").read_text()
    recipe = makefile.split("bx510-ui-loop:", 1)[1].split("\n## ", 1)[0]
    order = [recipe.find(f"bx510-ui-{stage}") for stage in ("build", "fire", "shot")]
    assert all(at >= 0 for at in order), f"bx510-ui-loop is missing a stage: {recipe}"
    assert order == sorted(order), "the loop must build, then fire, then shot"
    for target, tool in (("bx510-ui-build", "tools/bx510_ui_build.sh"),
                         ("bx510-ui-fire", "tools/bx510_ui_render.py"),
                         ("bx510-ui-shot", "tools/bx510_ui_shot.py")):
        block = makefile.split(f"{target}:", 1)[1].split("\n## ", 1)[0]
        assert tool in block, f"{target} does not call {tool}"


def test_ui_build_refuses_without_the_ui_source_without_touching_the_vm():
    """The build leg must fail on the Mac, before any ssh/scp reaches the VM."""
    r = subprocess.run(["sh", str(BUILD)], cwd=str(REPO), capture_output=True,
                       text=True,
                       env={"PATH": "/usr/bin:/bin",
                            "UI_SRC": "tools/does_not_exist.c"})
    assert r.returncode == 2, r.stdout + r.stderr
    assert "REFUSING" in r.stderr
    assert "ssh" not in (r.stdout + r.stderr).lower()


if __name__ == "__main__":
    sys.exit(subprocess.call([sys.executable, "-m", "pytest", __file__, "-q"]))
