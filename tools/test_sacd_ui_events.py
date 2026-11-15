#!/usr/bin/env python3
"""Controls for the UI's event model (tools/sacd_ui.c, "the event model").

The C is the REFEREE: every assertion here reads a table the UI itself printed
when built with -DSACD_UI_EVENTS_TEST. The build adds UI-EVAPP lines — one per
APPLIED event, in apply order, carrying the state it produced — which is the
(event, state) pair the determinism rules are about. A guest run's own stdout
is a transcript of what it LOGGED, which cannot tell a transition from a
coincidence; that is why the trace exists.

Four classes of control:

  1. transitions   (event, state) -> state: tcp listen/connect/gone, the io
                   rate window and its decay, the watched-pid progress counter
                   and its 1 Hz log throttle. Table-driven, no screenshots.
  2. order         the loop's source order is FIXED (tick -> tcp -> io ->
                   progress) and every log line carries a monotone seq, so a
                   transcript's log order is assertable.
  3. determinism   the same SACD_UI_SIM_SCRIPT twice -> identical event trace
                   and identical frame bytes.
  4. frames        a state-identical repaint differs ONLY inside the motion
                   regions (lamp, cursor, RENDER line): the property the frame
                   goldens and the frame-to-frame diff rest on. The golden
                   itself (the argv episode's sha256) is asserted too, when this
                   machine still has the TOC fixtures.

Run: python3 tools/test_sacd_ui_events.py   (or via pytest)
"""
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent
SRC = HERE / "sacd_ui.c"
# The SIM font chain's default candidate, RELATIVE to the repo root — the UI
# prints the font path in the RENDER line, so the path itself is frame state and
# an absolute path is a different frame (that is how the golden moved once).
SIM_FONT = "evidence/bx510/display-payload/sony-font.ttf"

# The argv-episode frame golden (the SIM render every layout change is checked
# against). Byte-identical is the acceptance bar for a refactor: if the sha
# moves, rendering semantics changed, not just plumbing.
GOLDEN_SHA = "9f24414161b865dc97a48642433604801f954a5d0d61697fffa2bc6b0e828dcc"
FIXTURES = [Path("/tmp/mtoc.bin"), Path("/tmp/area1.bin"), Path("/tmp/area2.bin")]

# The motion regions — the canvas areas a STATE-IDENTICAL frame may differ in.
# Canonical home: the layout spec's `motion_regions` (tools/ui_layout_spec.json,
# logical 640x360 units), which is what this module reads when it is present.
# MOTION_FALLBACK is the deliberately GENEROUS superset for a tree where the
# spec has not landed; a spec box must be contained in its fallback box, so the
# two cannot drift into disagreeing about what may move.
MOTION_FALLBACK = [
    ("lamp", 618, 38, 8, 8),            # LAMP_X = CW-22, LAMP_Y, LAMP_W, LAMP_H
    ("cursor", 520, 336, 110, 18),      # left of the state chip, CURSOR_Y=341
    ("render_line", 12, 324, 616, 20),  # "RENDER %ux%u … %u frames %.1f fps t=…"
]
SPEC_PATH = HERE / "ui_layout_spec.json"


def motion_regions():
    """The spec's motion boxes if the spec is here, else the generous fallback."""
    if SPEC_PATH.exists():
        import json
        spec = json.loads(SPEC_PATH.read_text())
        motion = spec.get("motion_regions") or spec.get("motion")
        if motion:
            return [(m["name"], m["x"], m["y"], m["w"], m["h"]) for m in motion]
    return MOTION_FALLBACK

SIM_DEFS = ["-DSACD_UI_SIM"]
TEST_DEFS = SIM_DEFS + ["-DSACD_UI_EVENTS_TEST"]


def _cc(defs, out, extra=()):
    """Compile sacd_ui.c into `out`; returns the path or skips the module."""
    cc = shutil.which("cc") or shutil.which("clang") or shutil.which("gcc")
    if cc is None:
        return None
    r = subprocess.run([cc, "-O2", "-std=gnu99", "-Wall", *defs, *extra,
                        "-I", str(REPO), "-o", str(out), str(SRC), "-lm"],
                       capture_output=True, text=True)
    assert r.returncode == 0, f"cc failed:\n{r.stdout}\n{r.stderr}"
    return out


_BUILD = {}


def build(name, defs, extra=()):
    """Compile once per session into a temp dir."""
    if name in _BUILD:
        return _BUILD[name]
    d = Path(tempfile.mkdtemp(prefix="sacd_uiev-"))
    _BUILD[name] = _cc(defs, d / "sacd_ui", extra)
    return _BUILD[name]


def evbin():
    b = build("events", TEST_DEFS)
    if b is None:
        raise SystemExit("no C compiler: cannot referee the event model")
    return b


def simbin():
    b = build("sim", SIM_DEFS)
    if b is None:
        raise SystemExit("no C compiler: cannot render the SIM frame")
    return b


def run_replay(script, frames_dir=None, out=None, fixtures=False, binary=None):
    """Replay a scenario through the UI's own apply_event(); -> (rc, stdout, frames)."""
    binp = binary or evbin()
    d = Path(tempfile.mkdtemp(prefix="sacd_uiev-run-"))
    sp = d / "scenario.txt"
    sp.write_text(script if isinstance(script, str) else "\n".join(script) + "\n")
    outp = Path(out) if out else d / "final.ppm"
    frame_dir = Path(frames_dir) if frames_dir else d / "frames"
    frame_dir.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, SACD_UI_SIM_SCRIPT=str(sp),
               SACD_UI_SIM_FRAMES=str(frame_dir))
    env.pop("SACD_UI_FONT", None)
    argv = [str(binp)]
    if fixtures:
        argv += [str(p) for p in FIXTURES[:3]]
    argv.append(str(outp))
    r = subprocess.run(argv, capture_output=True, text=True, env=env,
                       cwd=str(REPO))
    frames = sorted(frame_dir.glob("frame-*.ppm"))
    return r, frames


FLOAT_STATE_KEYS = {"wire_mb", "rip_mb_s"}


def evapp(stdout):
    """-> [(kind, changed, {state})] in apply order, from the C's own trace."""
    rows = []
    for ln in stdout.splitlines():
        if not ln.startswith("UI-EVAPP "):
            continue
        kv = dict(tok.split("=", 1) for tok in ln.split()[1:])
        for k, v in kv.items():
            if k == "kind":
                continue
            if k in FLOAT_STATE_KEYS:
                kv[k] = float(v)
            else:
                try:
                    kv[k] = int(v)
                except ValueError:
                    pass
        rows.append((kv["kind"], int(kv["changed"]), kv))
    return rows


def evlog(stdout):
    """-> [(seq, t, mark, text)] in print order, from the UI-EV lines."""
    out = []
    for ln in stdout.splitlines():
        m = re.match(r"UI-EV (\d+) +([\d.]+) (.) (.*)$", ln)
        if m:
            out.append((int(m.group(1)), float(m.group(2)), m.group(3),
                        m.group(4)))
    return out


def read_ppm(path):
    """P6 PPM -> (w, h, bytes). The UI writes RGB888, one row after another."""
    raw = Path(path).read_bytes()
    parts = raw.split(b"\n", 3)
    assert parts[0] == b"P6", parts[0]
    w, h = (int(x) for x in parts[1].split())
    return w, h, parts[3]


def diff_pixels(a, b):
    """-> [(x, y)] where two same-size PPMs differ (per-channel)."""
    wa, ha, da = read_ppm(a)
    wb, hb, db = read_ppm(b)
    assert (wa, ha) == (wb, hb), (wa, ha, wb, hb)
    out = []
    for y in range(ha):
        row = y * wa * 3
        if da[row:row + wa * 3] == db[row:row + wa * 3]:
            continue
        for x in range(wa):
            o = row + x * 3
            if da[o:o + 3] != db[o:o + 3]:
                out.append((x, y))
    return out


def outside_regions(pixels, w, h, regions):
    scale = w // 640
    boxes = [(x * scale, y * scale, (x + bw) * scale, (y + bh) * scale)
             for _, x, y, bw, bh in regions]
    bad = []
    for (px, py) in pixels:
        if not any(x0 <= px < x1 and y0 <= py < y1 for x0, y0, x1, y1 in boxes):
            bad.append((px, py))
    return bad


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


# ---------------------------------------------------------------- transitions

def test_tcp_transitions():
    """listener up, a client arriving, the same sample twice, the client leaving."""
    r, _ = run_replay([
        "session ok",
        "tcp 1 0",          # listener up (0 -> 1)
        "tcp 1 0",          # identical sample: no state, no log, no repaint
        "tcp 1 1",          # a client connected
        "tcp 1 0",          # it left
    ])
    assert r.returncode == 0, r.stdout + r.stderr
    rows = evapp(r.stdout)
    assert [k for k, _, _ in rows] == ["session", "tcp", "tcp", "tcp", "tcp"]
    assert [c for _, c, _ in rows] == [1, 1, 0, 1, 1], rows
    assert rows[-1][2]["clients"] == 0 and rows[-1][2]["clients_seen"] == 1
    assert rows[-1][2]["listen"] == 1

    texts = [t for _, _, _, t in evlog(r.stdout)]
    assert "LISTENER :2002 UP" in texts
    assert "DAEMON CLIENT CONNECT (1 live)" in texts
    assert "DAEMON CLIENT GONE (0 live)" in texts
    # exactly one CONNECT/GONE per transition, never one per sample
    assert sum(1 for t in texts if t.startswith("DAEMON CLIENT")) == 2, texts


def test_wire_rate_window_and_decay():
    """MB/s is the bytes of ONE telemetry window over that window's length."""
    mib = 1024 * 1024
    r, _ = run_replay([
        "wire 0",
        f"wire {mib}",                    # 1 MiB in a 250 ms window = 4.0 MB/s
        f"wire {mib + mib // 2}",         # 0.5 MiB -> 2.0
        f"wire {mib + mib // 2}",         # no bytes -> decay halves
        f"wire {mib + mib // 2}",
    ])
    assert r.returncode == 0, r.stdout + r.stderr
    rates = [k["wire_mb"] for k, _, k in evapp(r.stdout)]
    assert rates[0] == 0.0, rates            # first sample: no delta, no rate
    assert abs(rates[1] - 4.0) < 1e-6, rates
    assert abs(rates[2] - 2.0) < 1e-6, rates
    assert abs(rates[3] - 1.0) < 1e-6, rates
    assert abs(rates[4] - 0.5) < 1e-6, rates


def test_finished_rip_reports_done_once():
    """A finished rip says so ONCE; a quiet sample is not another RIP line."""
    script = ["watch /tmp/rip.bin", "rip 0", "tick 1.0", "rip 2097152"]
    script += ["tick 0.25", "rip 2097152"] * 4      # four quiet samples (1 s)
    r, _ = run_replay(script)
    assert r.returncode == 0, r.stdout + r.stderr
    texts = [t for _, _, _, t in evlog(r.stdout)]
    assert texts.count("RIP DONE 1024 sectors") == 1, texts
    done_at = texts.index("RIP DONE 1024 sectors")
    assert not [t for t in texts[done_at + 1:] if re.match(r"^RIP ", t)], texts
    rows = evapp(r.stdout)
    prog = [k for k, _, k in rows if k["kind"] == "progress"]
    assert prog[-1]["rip_sectors"] == 1024, prog[-1]


def test_wire_counter_reset_is_a_new_counter():
    r, _ = run_replay(["wire 1000000", "wire 10"])
    rows = evapp(r.stdout)
    assert rows[-1][2]["wire_mb"] == 0.0
    assert rows[-1][1] == 1
    assert any("WIRE COUNTER RESET" in t for _, _, _, t in evlog(r.stdout))


def test_daemon_pid_is_one_event():
    r, _ = run_replay(["pid 822", "pid 822"])
    rows = evapp(r.stdout)
    assert [k for k, _, _ in rows] == ["pid", "pid"], rows
    assert [c for _, c, _ in rows] == [1, 0], rows
    assert rows[-1][2]["daemon_pid"] == 822
    texts = [t for _, _, _, t in evlog(r.stdout)]
    assert texts.count("DAEMON pid=822 (sacd_extract_160)") == 1, texts


def test_rip_progress_sectors_and_one_line_per_second():
    """The watched rip FILE: sectors from its size, RIP lines throttled to 1 Hz."""
    # the file grows 1 MiB every 250 ms for 2.5 s; 1 MiB = 512 sectors
    script = ["session ok", "watch /tmp/rip.bin", "rip 0"]
    size = 0
    for _ in range(10):
        size += 1024 * 1024
        script += ["tick 0.25", f"rip {size}"]
    r, _ = run_replay(script)
    assert r.returncode == 0, r.stdout + r.stderr
    rows = evapp(r.stdout)
    prog = [k for k, _, k in rows if k["kind"] == "progress"]
    assert prog[-1]["rip_bytes"] == 10 * 1024 * 1024, prog[-1]
    assert prog[-1]["rip_sectors"] == 10 * 512, prog[-1]
    assert abs(prog[-1]["rip_mb_s"] - 4.0) < 1e-6, prog[-1]

    rips = [t for _, _, _, t in evlog(r.stdout) if re.match(r"^RIP \d", t)]
    # the throttled lines: far fewer than the 11 samples that produced them
    assert 2 <= len(rips) <= 4, rips
    assert re.match(r"^RIP \d+ sectors \d+\.\d MB/s$", rips[-1]), rips[-1]
    # the watch-start line names the FILE, and appears exactly once
    watch = [t for _, _, _, t in evlog(r.stdout) if t.startswith("RIP WATCH")]
    assert watch == ["RIP WATCH file=/tmp/rip.bin"], watch


# ---------------------------------------------------------------------- order

def test_log_sequence_numbers_are_monotone_and_printed():
    r, _ = run_replay(["session ok", "tcp 1 0", "tcp 1 1"])
    seqs = [s for s, _, _, _ in evlog(r.stdout)]
    assert seqs, r.stdout
    assert seqs == sorted(seqs) and len(set(seqs)) == len(seqs), seqs
    assert seqs[0] == 1 and seqs == list(range(1, len(seqs) + 1)), seqs


def test_loop_source_order_is_fixed():
    """Wiring control: the guest loop pushes tick, tcp, pid, wire, rip in order."""
    src = SRC.read_text()
    loop = src.split("the loop: poll -> queue -> apply_event -> paint if dirty")[1]
    loop = loop.split("/* one last sample + apply")[0]
    order = [loop.index("ev_push_kind(EV_TICK)"),
             loop.index("ev_push_tcp("),
             loop.index("ev_push_pid("),
             loop.index("ev_push_bytes(EV_WIRE"),
             loop.index("ev_push_bytes(EV_PROGRESS")]
    assert order == sorted(order), order
    assert "ev_drain();" in loop
    # one cadence constant per source class, no bare literals in the loop
    assert "next_tick = t + FRAME_PERIOD_S" in loop
    assert "next_tel = t + TEL_PERIOD_S" in loop


def test_sources_are_the_ones_this_guest_has():
    """No silent fake: the C must read /proc/net/dev and a file, never the
    /proc/<pid>/io the BX510 kernel does not have (fires pio1/pio2)."""
    src = SRC.read_text()
    assert "/proc/net/dev" in src and "/res/proc/net/dev" in src
    assert "rchar" not in src.split("WHY THERE IS NO /proc/<pid>/io")[1]
    assert "SACD_UI_WATCH_FILE" in src and "tel_sample_file" in src


# ---------------------------------------------------------------- determinism

def test_replay_is_deterministic():
    script = [
        "session ok",
        "tcp 1 0",
        "pid 822",
        "wire 0",
        "tick 0.5",
        "wire 2097152",
        "watch /tmp/rip.bin",
        "rip 0",
        "tick 1.0",
        "rip 4194304",
        "tcp 1 1",
        "tcp 1 0",
        "tick 0.5",
    ]
    r1, f1 = run_replay(script)
    r2, f2 = run_replay(script)
    assert r1.returncode == 0 and r2.returncode == 0
    def strip(text):
        """stdout minus the two lines that name this run's temp paths."""
        out = []
        for ln in text.splitlines():
            if ln.startswith("UI: wrote "):
                continue
            if ln.startswith("SIM: replay "):
                ln = "SIM: replay <script> " + ln.split("events, ")[-1]
            out.append(ln)
        return "\n".join(out)
    assert strip(r1.stdout) == strip(r2.stdout)
    assert len(f1) == len(f2) >= 3, (f1, f2)
    assert [sha(p) for p in f1] == [sha(p) for p in f2]


def test_state_identical_frames_differ_only_in_motion_regions():
    """The clock moves, the state does not: only lamp + cursor + RENDER may move."""
    r, frames = run_replay(["session ok", "tcp 1 1",
                            "tick 0.5", "tick 0.5", "tick 0.5"])
    assert r.returncode == 0, r.stdout + r.stderr
    # t=0, the session event, the tcp event, then one paint per blink flip
    assert len(frames) == 6, [f.name for f in frames]
    settled = frames[3:]                      # state stopped changing here
    w, _, _ = read_ppm(settled[0])
    scale = w // 640
    lamp = motion_regions()[0]
    lamp_box = (lamp[1] * scale, lamp[2] * scale,
                (lamp[1] + lamp[3]) * scale, (lamp[2] + lamp[4]) * scale)
    for a, b in zip(settled, settled[1:]):
        px = diff_pixels(a, b)
        assert px, f"{a.name} and {b.name} are identical — the blink is dead"
        bad = outside_regions(px, w, 360 * scale, motion_regions())
        assert not bad, (f"{len(bad)} of {len(px)} differing pixels are outside "
                         f"the motion regions, first at {bad[0]}")
        assert any(lamp_box[0] <= x < lamp_box[2] and lamp_box[1] <= y < lamp_box[3]
                   for x, y in px), "the live-link lamp did not blink"


def test_motion_regions_agree_with_the_layout_spec():
    """The shared contract: the spec's motion boxes are inside the C's boxes,
    and the lamp is the C's own rectangle (same name, same numbers)."""
    if not SPEC_PATH.exists():
        return                               # the spec has not landed in this tree
    import json
    spec = json.loads(SPEC_PATH.read_text())
    motion = spec.get("motion_regions") or spec.get("motion")
    assert motion, "the layout spec must carry its motion_regions list"
    got = {m["name"]: (m["x"], m["y"], m["w"], m["h"]) for m in motion}
    fallback = {name: (x, y, w, h) for name, x, y, w, h in MOTION_FALLBACK}
    assert set(got) == set(fallback), (sorted(got), sorted(fallback))
    # the lamp is a fixed rectangle drawn from LAMP_X/Y/W/H: exact, not a band
    assert got["lamp"] == fallback["lamp"], (got["lamp"], fallback["lamp"])
    for name, (x, y, w, h) in got.items():
        fx, fy, fw, fh = fallback[name]
        assert fx <= x and fy <= y and x + w <= fx + fw and y + h <= fy + fh, \
            f"spec motion {name} {x, y, w, h} escapes the C's box {fallback[name]}"


def test_sim_font_is_the_golden_one():
    """The RENDER line carries the font path, so the chain must resolve the
    repo-relative candidate: an absolute SACD_UI_FONT is a different frame."""
    assert not Path(SIM_FONT).is_absolute()
    assert (REPO / SIM_FONT).exists(), "the SIM font candidate is missing"


def test_blink_period_is_two_hz():
    """The spec dump's pulse_hz is the C's own BLINK_HZ (shared constant)."""
    b = build("spec", SIM_DEFS + ["-DSACD_UI_SPEC_DUMP"])
    if b is None:
        raise SystemExit("no C compiler")
    if not all(p.exists() for p in FIXTURES):
        return
    d = Path(tempfile.mkdtemp(prefix="sacd_uiev-spec-"))
    env = dict(os.environ)
    env.pop("SACD_UI_FONT", None)
    r = subprocess.run([str(b), *[str(p) for p in FIXTURES], str(d / "f.ppm")],
                       capture_output=True, text=True, env=env, cwd=str(REPO))
    m = re.search(r"^SPEC canvas .*pulse_hz=(\S+)$", r.stdout, re.M)
    assert m and float(m.group(1)) == 2.0, r.stdout


# -------------------------------------------------------------------- golden

def test_sim_frame_golden_is_byte_identical():
    """The argv episode's frame: a refactor must not move a single pixel."""
    if not all(p.exists() for p in FIXTURES):
        return                                  # the TOC fixtures live on the VM
    d = Path(tempfile.mkdtemp(prefix="sacd_uiev-golden-"))
    out = d / "golden.ppm"
    env = dict(os.environ)
    env.pop("SACD_UI_FONT", None)
    r = subprocess.run([str(simbin()), *[str(p) for p in FIXTURES], str(out)],
                       capture_output=True, text=True, env=env, cwd=str(REPO))
    assert r.returncode == 0, r.stdout + r.stderr
    assert sha(out) == GOLDEN_SHA, sha(out)


if __name__ == "__main__":
    fails = 0
    for name, fn in sorted(globals().items()):
        if not name.startswith("test_") or not callable(fn):
            continue
        try:
            fn()
            print(f"PASS {name}")
        except AssertionError as exc:
            fails += 1
            print(f"FAIL {name}: {exc}")
    sys.exit(1 if fails else 0)
