#!/usr/bin/env python3
"""H3 host-push round-trip controls (docs/HUD-DESIGN.md phase H3).

Three legs, cheapest first:

1. formatters -> parse_host_push() mirror (pure python, no sockets)
2. hud_push.py --selftest: formatters -> real UDP datagrams on 127.0.0.1 ->
   mirror parser (the send path)
3. formatters -> HUD_SIM build of tools/bx510_sacd_hud.c via the HUD_INGEST
   hook -> host_push_parse() (the REAL C parser the guest HUD uses), plus a
   rendered-frame diff proving the host-push line reaches the panel

Leg 3 compiles the HUD simulator with the host cc (no VM, no DirectFB — the
HUD_SIM build is font/software-only). If no C compiler is present the leg is
skipped, loudly: the loopback legs still run everywhere.
"""
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

TOOLS = Path(__file__).resolve().parent
ROOT = TOOLS.parent
sys.path.insert(0, str(TOOLS))
import hud_push  # noqa: E402

CC = shutil.which("cc") or shutil.which("gcc")
_SIM_DIR = None


def _build_sim():
    """Compile the HUD simulator once per session; None if no compiler."""
    global _SIM_DIR
    if not CC:
        return None
    if _SIM_DIR is None:
        out = Path("/tmp/hudsim-selftest")
        out.mkdir(exist_ok=True)
        exe = out / "hudsim"
        r = subprocess.run(
            [CC, "-DHUD_SIM", "-I.", "-o", str(exe), "bx510_sacd_hud.c", "-lm"],
            cwd=TOOLS, capture_output=True, text=True)
        if r.returncode != 0:
            raise AssertionError(f"HUD_SIM build failed:\n{r.stderr}")
        _SIM_DIR = out
    return _SIM_DIR / "hudsim"


def run_sim(sim, out_ppm, ingest=None):
    env = dict(os.environ, HUD_FX="0", HUD_FONT="/nonexistent")
    if ingest:
        env["HUD_INGEST"] = str(ingest)
    r = subprocess.run([str(sim), str(out_ppm), "1"], capture_output=True,
                       text=True, timeout=120, env=env)
    assert r.returncode == 0, r.stdout + r.stderr
    return r.stdout


# ---- leg 1: formatters vs the parser mirror --------------------------------
def test_grammar_formatters_roundtrip():
    assert hud_push.parse_host_push(hud_push.range_line(532104, 1064208)) == \
        {"verb": "RANGE", "done": 532104, "total": 1064208}
    assert hud_push.parse_host_push(hud_push.rate_line(4.7)) == \
        {"verb": "RATE", "mbs": 4.7}
    assert hud_push.parse_host_push(hud_push.verify_line("ok")) == \
        {"verb": "VERIFY", "status": "ok"}
    assert hud_push.parse_host_push(hud_push.verify_line("fail", bad=3)) == \
        {"verb": "VERIFY", "status": "fail"}
    assert hud_push.parse_host_push(hud_push.eta_line(120)) == \
        {"verb": "ETA", "s": 120}


def test_grammar_negatives_fall_through():
    # unknown verb / malformed body -> None (HUD keeps legacy handling)
    assert hud_push.parse_host_push("WAT done=1 total=2") is None
    assert hud_push.parse_host_push("RANGE done=1") is None
    assert hud_push.parse_host_push("VERIFY status=") is None
    # legacy client-report lines must NOT be swallowed by the host-push parser
    assert hud_push.parse_host_push("READ lsn=532104 n=128 got=128") is None


def test_demo_progression_is_wellformed():
    lines = hud_push.demo_lines(steps=5)
    assert lines[-1] == "VERIFY status=ok"
    for ln in lines:
        assert hud_push.parse_host_push(ln) is not None, ln


# ---- leg 2: pusher loopback (real UDP) --------------------------------------
def test_pusher_selftest_loopback():
    r = subprocess.run([sys.executable, str(TOOLS / "hud_push.py"), "--selftest"],
                       capture_output=True, text=True, timeout=60)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "SELFTEST: PASS" in r.stdout


# ---- leg 3: the REAL C parser (HUD_SIM build) -------------------------------
@pytest.mark.skipif(not CC, reason="no C compiler on this host")
def test_c_host_push_parse_roundtrip(tmp_path):
    sim = _build_sim()
    lines = [hud_push.range_line(532104, 1064208),
             hud_push.rate_line(4.7),
             hud_push.verify_line("ok"),
             hud_push.eta_line(120)]
    ing = tmp_path / "push.txt"
    ing.write_text("\n".join(lines) + "\n")

    base_out = run_sim(sim, tmp_path / "base.ppm")
    push_out = run_sim(sim, tmp_path / "pushed.ppm", ingest=ing)

    m = re.search(r"HOSTPUSH: have=(\d) done=(\d+) total=(\d+) "
                  r"mbps=([\d.]+) eta=(\d+) verify=(\S+)", push_out)
    assert m, push_out
    assert int(m.group(1)) == 1
    assert int(m.group(2)) == 532104
    assert int(m.group(3)) == 1064208
    assert float(m.group(4)) == 4.7
    assert int(m.group(5)) == 120
    assert m.group(6) == "ok"
    # control: without ingest the parser must report nothing seen
    assert "HOSTPUSH: have=0" in base_out


@pytest.mark.skipif(not CC, reason="no C compiler on this host")
def test_host_push_line_reaches_the_panel(tmp_path):
    """The host-push line must change the rendered frame (H3 observable)."""
    sim = _build_sim()
    ing = tmp_path / "push.txt"
    ing.write_text("\n".join([hud_push.range_line(532104, 1064208),
                              hud_push.rate_line(4.7),
                              hud_push.verify_line("ok"),
                              hud_push.eta_line(120)]) + "\n")
    run_sim(sim, tmp_path / "base.ppm")
    run_sim(sim, tmp_path / "pushed.ppm", ingest=ing)
    run_sim(sim, tmp_path / "pushed2.ppm", ingest=ing)   # determinism control
    base = (tmp_path / "base.ppm").read_bytes()
    pushed = (tmp_path / "pushed.ppm").read_bytes()
    assert base != pushed, "host-push ingest did not change the frame"
    assert pushed == (tmp_path / "pushed2.ppm").read_bytes(), \
        "two identical ingests rendered differently (render is not deterministic)"
    # the host-push line is drawn in C_CYAN (0x33e0ff): the ingest run must
    # contain strictly more cyan pixels than the baseline
    cyan = bytes((0x33, 0xE0, 0xFF))
    assert pushed.count(cyan) > base.count(cyan)
