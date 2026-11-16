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
import re
import struct
import subprocess
import sys
import time
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
    assert "echo UI_SHOT_DONE" in code
    # the script ends with the second daemon.out read (the in-daemon HUD's
    # rip-progress lines land after the first cat)
    assert code.rstrip().endswith("echo DAEMON_OUT_END2")


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
    # the template carries the @DAEMON_LAUNCH@ placeholder (the renderer owns
    # the actual line); the invariant check runs on the RENDERED code
    launch = [i for i, ln in enumerate(lines) if ln.strip().startswith("@DAEMON_LAUNCH@")]
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


# ── issue #13: the UI kill is MARKER-gated, never a fixed sleep ─────────────
#
# The UI's first frame includes its own client session (DISC_OPEN alone measured
# 22 s in c123/c132/c133), so `sleep <n>` before `kill $U` is the wrong
# mechanism on both sides: too short misses the frame entirely (uiloop7's honest
# BLACK verdict at UI_WAIT=3 s) and too long wastes fire time (c126 needed 150 s
# to cover a 35 s rip). The UI now writes /res/ui-frame.done once its first
# frame is painted; the number is only the fallback bound.

UI_TEMPLATES = ("bx510_ui_guest.sh.in", "bx510_ui_reactive_guest.sh.in",
                "bx510_client_c_overlap.sh.in", "bx510_client_d_arearead.sh.in")
CLIENT_TEMPLATES = ("bx510_client_a_reconnect.sh.in", "bx510_client_b_readfail.sh.in",
                    "bx510_client_c_overlap.sh.in", "bx510_client_d_arearead.sh.in")
ALL_TEMPLATES = UI_TEMPLATES + tuple(t for t in CLIENT_TEMPLATES if t not in UI_TEMPLATES)
FRAME_MARKER = "/res/ui-frame.done"
UNBOUNDED_WAIT = re.compile(r"while \[ ! -f [^\]]+ \]; do sleep 1; done")
WAIT_LINE = re.compile(r"^i=0; while .*\[ ! -f %s \].*\[ \$i -lt \d+ \]; "
                       r"do sleep 1; i=\$\(\(i\+1\)\); done$" % re.escape(FRAME_MARKER))


def render_text(tmp_path, template, name, *extra):
    script = tmp_path / f"{name}.sh"
    r = run(RENDER, "--runid", name, "--template", TOOLS / template,
            "--out", tmp_path / f"{name}.cmd", "--script", script,
            "--ui-args", "127.0.0.1 90", *extra)
    assert r.returncode == 0, r.stdout + r.stderr
    return script.read_text()


def code_lines(text):
    return [ln.strip() for ln in text.splitlines()
            if ln.strip() and not ln.strip().startswith("#")]


def test_every_ui_template_kills_on_the_first_frame_marker(tmp_path):
    """All four UI templates: marker wait + bounded fallback, no bare sleep."""
    for template in UI_TEMPLATES:
        code = code_lines(render_text(tmp_path, template, template.split(".")[0]))
        wait = [ln for ln in code if WAIT_LINE.match(ln)]
        assert wait, f"{template}: no bounded first-frame marker wait:\n" + "\n".join(code)
        launch = next(i for i, ln in enumerate(code) if "./sacd_ui " in ln or ln.endswith("./sacd_ui"))
        kill = next(i for i, ln in enumerate(code) if ln.startswith("kill $U"))
        wait_at = code.index(wait[0])
        assert launch < wait_at < kill, f"{template}: the wait must sit between launch and kill"
        assert any(ln.startswith("rm -f ") and FRAME_MARKER in ln for ln in code[:launch]), \
            f"{template}: a stale {FRAME_MARKER} from an earlier step must be removed first"
        bare = [ln for ln in code[launch:kill] if re.fullmatch(r"sleep \d+", ln)]
        assert not bare, f"{template}: a fixed sleep came back before the kill: {bare}"


def test_watch_templates_hold_the_ui_until_the_scenario_marker_too(tmp_path):
    """Watch mode waits on the frame marker AND the client's own rc marker.

    Killing on the frame alone would end a reactive fire ~1 s after the UI's
    session, before the watched rip moved — exactly the observation window
    c126 verified (RIP 128 -> 1600 sectors, DAEMON CLIENT GONE).
    """
    expected = {
        "bx510_ui_reactive_guest.sh.in": ("/res/rip.rc",),
        "bx510_client_c_overlap.sh.in": ("/res/a.rc", "/res/b.rc"),
        "bx510_client_d_arearead.sh.in": ("/res/rip.rc",),
    }
    for template, markers in expected.items():
        code = code_lines(render_text(tmp_path, template, template.split(".")[0]))
        wait = next(ln for ln in code if WAIT_LINE.match(ln))
        assert "SACD_UI_WATCH_FILE=" in "\n".join(code), template
        for marker in markers:
            assert f"! -f {marker} ]" in wait, \
                f"{template}: the kill wait ignores its scenario marker {marker}: {wait}"


def test_marker_wait_requires_every_marker_and_ends_on_the_bound(tmp_path):
    """Executed, not eyeballed: AND semantics, and the fallback really bounds it."""
    code = code_lines(render_text(tmp_path, "bx510_ui_reactive_guest.sh.in", "beh",
                                  "--ui-wait-max", "2"))
    line = next(ln for ln in code if WAIT_LINE.match(ln))
    # the guest paths are absolute; point them at this test's own directory
    path = tmp_path / "wait.sh"
    path.write_text(re.sub(r"/res/([A-Za-z0-9_.-]+)",
                           lambda m: str(tmp_path / m.group(1)), line)
                    + "\necho ITERS=$i\n")
    frame, scenario = tmp_path / "ui-frame.done", tmp_path / "rip.rc"

    def wait_case(*present):
        for marker in (frame, scenario):
            marker.unlink(missing_ok=True)
        for marker in present:
            marker.touch()
        t0 = time.monotonic()
        r = run_sh(path)
        assert r.returncode == 0, r.stdout + r.stderr
        return r.stdout.strip(), time.monotonic() - t0

    out, elapsed = wait_case()
    assert out == "ITERS=2", out
    assert elapsed >= 2, "the bound is what ends a UI that never paints"
    out, elapsed = wait_case(frame)
    assert out == "ITERS=2", f"the frame marker alone must not end a watch-mode wait: {out}"
    out, elapsed = wait_case(frame, scenario)
    assert out == "ITERS=0", out
    assert elapsed < 2, "both markers present must end the wait immediately"


def test_render_refuses_a_fixed_sleep_before_the_ui_kill(tmp_path):
    """The gate must fail the old shape, not just pass the new one."""
    text = TEMPLATE.read_text()
    wait = next(ln for ln in text.splitlines() if ln.strip().startswith("i=0; while"))
    tmpl = tmp_path / "sleep-kill.sh.in"
    tmpl.write_text(text.replace(wait, "sleep @UI_WAIT_MAX@"))
    r = run(RENDER, "--runid", "c904", "--template", tmpl, "--print-only")
    assert r.returncode == 1, "a fixed sleep before the UI kill must not render"
    assert "first-frame marker" in r.stdout


# ── the scenario waits around the UI: bounded, and rc captured ONCE ─────────
#
# Reviewer findings on the c132 receipts: an unbounded `while [ ! -f marker ]`
# turns a UI that never opens into a silent probe timeout (nothing in the
# transcript says which wait expired), and `echo RC=$? >f; echo RC=$?` prints
# the FIRST echo's status — always 0 — so c132's console read `B_RC=0` while
# `cat /res/b.rc` said `B_RC=1`.

def test_every_marker_wait_in_every_template_is_bounded(tmp_path):
    for template in ALL_TEMPLATES:
        code = code_lines(render_text(tmp_path, template, template.split(".")[0]))
        unbounded = [ln for ln in code if UNBOUNDED_WAIT.search(ln)]
        assert not unbounded, f"{template}: unbounded marker wait: {unbounded}"
        for line in (ln for ln in code if "do sleep 1; i=$((i+1)); done" in ln):
            assert "[ $i -lt " in line, f"{template}: a wait with no bound: {line}"


def test_scenario_waits_report_their_own_expiry(tmp_path):
    """The three watch-mode templates: a wait that expires says so."""
    for template, marker in (("bx510_ui_reactive_guest.sh.in", "RIP_WAIT_TIMEOUT"),
                             ("bx510_client_c_overlap.sh.in", "A_WAIT_TIMEOUT"),
                             ("bx510_client_d_arearead.sh.in", "RIP_WAIT_TIMEOUT")):
        code = "\n".join(code_lines(render_text(tmp_path, template,
                                                template.split(".")[0])))
        assert f"echo {marker}=$i" in code, f"{template}: an expired wait is silent"


def test_client_rc_is_captured_once_not_by_a_second_dollar_question(tmp_path):
    for template in ("bx510_ui_reactive_guest.sh.in", "bx510_client_c_overlap.sh.in",
                     "bx510_client_d_arearead.sh.in"):
        code = "\n".join(code_lines(render_text(tmp_path, template,
                                                template.split(".")[0])))
        assert not re.search(r"echo \w+_RC=\$\? >", code), \
            f"{template}: `echo RC=$? >f` then a second `echo RC=$?` reports the echo's status"
        assert "rc=$?; echo " in code, f"{template}: the client rc must be captured once"


def test_render_refuses_an_unbounded_marker_wait(tmp_path):
    """The bound gate must fail the old shape, not just pass the new one."""
    text = (TOOLS / "bx510_client_d_arearead.sh.in").read_text()
    bounded = "i=0; while [ ! -f /res/ui-session.done ] && [ $i -lt 60 ]; do sleep 1; i=$((i+1)); done"
    assert bounded in text
    tmpl = tmp_path / "unbounded.sh.in"
    tmpl.write_text(text.replace(
        bounded, "while [ ! -f /res/ui-session.done ]; do sleep 1; done"))
    r = run(RENDER, "--runid", "c905", "--template", tmpl, "--print-only")
    assert r.returncode == 1, "an unbounded marker wait must not render"
    assert "unbounded" in r.stdout


# ── the seam the reviewer caught in A/B: one pool geometry, one spelling ─────

def test_pool_geometry_is_a_placeholder_in_every_client_template(tmp_path):
    """A/B hardcoded `4096 1920 1080` while C/D took @POOL_ARGS@.

    Same knob, two spellings: a fire that moves the pool offset would silently
    decode A/B's frame from the wrong bytes. Render with a distinctive geometry
    and require every template to carry it.
    """
    for template in ALL_TEMPLATES:
        code = "\n".join(code_lines(render_text(tmp_path, template, template.split(".")[0],
                                                "--pool-ofs", "8192", "--pool-w", "800",
                                                "--pool-h", "600")))
        assert "8192 800 600" in code, f"{template}: pool geometry is not @POOL_ARGS@"
        assert "4096 1920 1080" not in code, f"{template}: a hardcoded pool geometry came back"


def test_overlap_template_states_the_measured_expectation_not_the_refuted_one():
    """c132 REFUTED the corruption prediction that this header used to assert."""
    text = (TOOLS / "bx510_client_c_overlap.sh.in").read_text()
    assert "run-c130-c134.md" in text, "the expectation must cite the run that measured it"
    assert "result=-1" in text, "the second client is REFUSED at DISC_OPEN (c132)"
    assert "WEDGES" in text, "the first client wedges mid-transfer (c132)"
    assert "corruption is the" not in text, "the refuted prediction must not survive in the header"


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
