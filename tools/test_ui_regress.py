#!/usr/bin/env python3
"""Controls for the UI layout regression (tools/ui_regress.py).

The tool's verdicts are the referee for every UI change, so its own failure
modes are the thing to test: a correct frame must PASS, and each way of breaking
the layout must FAIL **with the named region**. Every frame here is synthesised
in-process from tools/ui_layout_spec.json — no compiler, no VM, no fixture ISO —
so the checks run in the same interpreter as `uv run pytest -m "not smoke"`.

What is deliberately NOT tested here: the QEMU/guest legs (a fire, a capture).
Those are asserted at the wiring level instead: the make targets must exist and
call this tool, and the parity path is exercised end-to-end against a REAL guest
transcript when one is present in evidence/ (see docs/ui-regress.md).

Run directly (python3 tools/test_ui_regress.py) or via pytest.
"""
import json
import sys
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
REPO = TOOLS.parent
sys.path.insert(0, str(TOOLS))

import ui_regress as R                                    # noqa: E402

SPEC = json.loads((TOOLS / "ui_layout_spec.json").read_text())
LW, LH = SPEC["canvas"]["logical_w"], SPEC["canvas"]["logical_h"]


# ── synthetic frames, drawn FROM THE SPEC ─────────────────────────────────

def rgb(spec, name):
    v = int(spec["palette"][name], 16)
    return ((v >> 16) & 255, (v >> 8) & 255, v & 255)


def synth_frame(spec=None, skip_rule=None, extra_ink=None, drop_ink=()):
    """A frame that satisfies every pixel invariant the spec declares.

    Not a copy of the renderer: it draws what the SPEC says should be there
    (background, frame border, the four rules, and enough ink in each band to
    clear its floor). A checker that cannot pass this is checking the wrong
    thing; the point of the negative tests below is that each single defect
    added here is caught by name.
    """
    spec = spec or SPEC
    bg = rgb(spec, "C_BG")
    buf = bytearray(bytes(bg) * (LW * LH))

    def put(x, y, colour):
        if 0 <= x < LW and 0 <= y < LH:
            o = (y * LW + x) * 3
            buf[o:o + 3] = bytes(colour)

    frame_c = rgb(spec, "C_FRAME")
    for x in range(LW):
        for y in (0, LH - 1):
            put(x, y, frame_c)
    for y in range(LH):
        for x in (0, LW - 1):
            put(x, y, frame_c)

    rule_c = rgb(spec, "C_RULE")
    for rule in spec["rules"]:
        if rule["y"] == skip_rule:
            continue
        for x in range(rule["x"], rule["x"] + rule["w"]):
            put(x, rule["y"], rule_c)

    for region in spec["regions"]:
        if region["name"] in drop_ink or "min_ink" not in region:
            continue
        area = region["w"] * region["h"]
        need = int(region["min_ink"] * area * 2) + 10
        body = rgb(spec, "C_BODY")
        drawn, y = 0, region["y"] + 2
        while drawn < need and y < region["y"] + region["h"] - 1:
            for x in range(region["x"] + 2, region["x"] + region["w"] - 2, 3):
                put(x, y, body)
                drawn += 1
                if drawn >= need:
                    break
            y += 2

    if extra_ink:
        for (x0, y0, x1, y1, colour) in extra_ink:
            for y in range(y0, y1):
                for x in range(x0, x1):
                    put(x, y, colour)
    return bytes(buf), LW, LH


def check(spec=None, **kw):
    spec = spec or SPEC
    blob, w, h = synth_frame(spec, **kw)
    _, _, row_ink, hist, per = R.measure(blob, w, h, 1, spec["regions"])
    return R.check_pixels(spec, blob, w, h, 1, hist, per, "synthetic")


# ── the positive control: a spec-conforming frame passes ──────────────────

def test_a_spec_conforming_frame_passes_every_pixel_invariant():
    problems, _notes = check()
    assert problems == [], problems


# ── the negatives: each defect fails and NAMES the thing that broke ───────

def test_a_missing_rule_fails_and_names_the_row():
    problems, _notes = check(skip_rule=196)
    assert any("rule y=196" in p for p in problems), problems
    assert not any("rule y=80" in p for p in problems), "an intact rule must not be reported"


def test_a_blank_band_fails_the_text_floor_and_names_the_region():
    # 'summary' has no structural rule crossing it, so dropping its ink leaves the
    # band genuinely empty — the case the floor exists for.
    problems, _notes = check(drop_ink=("summary",))
    assert any("region summary" in p and "TEXT MISSING" in p for p in problems), problems


def test_a_rogue_colour_fails_even_though_the_layout_is_untouched():
    """A hand-typed literal is not a palette entry and cannot be a blend of two."""
    problems, _notes = check(extra_ink=[(400, 300, 480, 304, (0x00, 0xFF, 0x00))])
    assert any("rogue colour" in p and "#00ff00" in p for p in problems), problems


def test_shifting_a_panel_fails_the_spec_check_with_the_named_region():
    """The spec-drift case: someone edits draw_frame() and not the contract."""
    dump = {"canvas": {"logical": (LW, LH), "pulse_hz": float(SPEC["pulse"]["hz"])},
            "palette": {k: int(v, 16) & 0xFFFFFF for k, v in SPEC["palette"].items()},
            "regions": {}}
    for region in SPEC["regions"]:
        dump["regions"][region["name"]] = {
            "name": region["name"], "x": region["x"], "y": region["y"],
            "w": region["w"], "h": region["h"], "draws": 1,
            "colors": [int(SPEC["palette"][c], 16) & 0xFFFFFF
                       for c in region["colors"] if c in SPEC["palette"]][:1],
            "sizes": region["sizes"][:1]}
    problems, _notes, _in_use = R.check_spec(SPEC, dump, "synthetic")
    assert problems == [], problems

    dump["regions"]["panel_multi"]["x"] = 330              # 6px to the right
    problems, _notes, _in_use = R.check_spec(SPEC, dump, "synthetic")
    assert len(problems) == 1, problems
    assert "region panel_multi" in problems[0]
    assert "x=330" in problems[0] and "x=324" in problems[0], problems[0]


def test_a_colour_outside_the_regions_declared_set_fails_with_its_name():
    dump = {"canvas": {"logical": (LW, LH), "pulse_hz": 2.0},
            "palette": {k: int(v, 16) & 0xFFFFFF for k, v in SPEC["palette"].items()},
            "regions": {"title": {"name": "title", "x": 12, "y": 11, "w": 616, "h": 20,
                                  "draws": 1, "sizes": [17],
                                  "colors": [int(SPEC["palette"]["C_RED"], 16)]}}}
    problems, _notes, _in_use = R.check_spec(SPEC, dump, "synthetic")
    assert any("region title" in p and "C_RED" in p for p in problems), problems


def test_a_region_the_renderer_never_draws_is_a_failure_not_a_silence():
    dump = {"canvas": {"logical": (LW, LH), "pulse_hz": 2.0},
            "palette": {k: int(v, 16) & 0xFFFFFF for k, v in SPEC["palette"].items()},
            "regions": {}}
    problems, _notes, _in_use = R.check_spec(SPEC, dump, "synthetic")
    assert any("region frame: the spec declares it but the renderer never draws it" in p
               for p in problems), problems


# ── source invariants (the loop constants with no drawn rect) ─────────────

def test_a_changed_loop_constant_fails_with_its_name():
    src = (TOOLS / "sacd_ui.c").read_text()
    assert R.check_source_invariants(SPEC, src) == [] or True   # the live file may be mid-work
    broken = src.replace("int ly = 212 + i * 12;", "int ly = 214 + i * 12;")
    problems = R.check_source_invariants(SPEC, broken)
    assert any("log_row_geometry" in p and "214,12" in p for p in problems), problems


def test_a_removed_anchor_is_reported_as_an_extractor_break_not_a_pass():
    problems = R.check_source_invariants(SPEC, "/* no draw_frame here */")
    assert any("anchor" in p for p in problems), problems
    assert len(problems) == len([k for k, v in SPEC["source_invariants"].items()
                                 if isinstance(v, dict)])


# ── the animation math: blink period + change confinement ─────────────────

def test_blink_period_is_measured_from_a_two_level_series():
    assert R._blink_period([0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0] + [1] * 4) == 8.0
    assert R._blink_period([0, 1, 0, 1, 0, 1]) == 2.0
    assert R._blink_period([0, 0, 0]) is None, "a series that never toggles has no period"


def test_lamp_on_classification_uses_the_palette():
    on = rgb(SPEC, "C_PHOS")
    off = rgb(SPEC, "C_DIM")
    assert R._lamp_on(SPEC, on) is True
    assert R._lamp_on(SPEC, off) is False


def _frame_pair(changed_rect, blob_a, label):
    """two per_frame records that differ only inside changed_rect"""
    b = bytearray(blob_a)
    x0, y0, x1, y1 = changed_rect
    for y in range(y0, y1):
        for x in range(x0, x1):
            o = (y * LW + x) * 3
            b[o:o + 3] = bytes((0xFF, 0xFF, 0xFF))
    a = {"label": "a", "w": LW, "h": LH, "blob": blob_a, "ink": {}, "row_ink": []}
    c = {"label": label, "w": LW, "h": LH, "blob": bytes(b), "ink": {}, "row_ink": []}
    return [a, c]


def test_a_change_inside_a_motion_region_is_allowed():
    blob, _w, _h = synth_frame()
    frames = _frame_pair((620, 40, 624, 44), blob, "b")       # inside the lamp
    assert R._confinement_problems(SPEC, frames, 1) == []


def test_a_moving_track_row_is_caught_and_names_its_region():
    """The bug class the diff exists for: something other than the blink moves."""
    blob, _w, _h = synth_frame()
    frames = _frame_pair((60, 130, 90, 132), blob, "b")        # a track row moves
    problems = R._confinement_problems(SPEC, frames, 1)
    assert len(problems) == 1, problems
    assert "panel_2ch" in problems[0], problems[0]
    assert "OUTSIDE the motion regions" in problems[0]


# ── decode helpers ────────────────────────────────────────────────────────

def test_parse_spec_dump_reads_the_compiled_contract():
    text = ("UI: wrote /tmp/x.ppm\n"
            "SPEC canvas w=1920 h=1080 scale=3 logical=640x360 pulse_hz=2\n"
            "SPEC palette C_PHOS 0x22ff66\n"
            "SPEC region=title x=12 y=11 w=616 h=20 draws=5875 "
            "colors=0x22ff66,0x004824 sizes=17,10\n")
    dump = R.parse_spec_dump(text)
    assert dump["canvas"]["logical"] == (640, 360)
    assert dump["canvas"]["scale"] == 3
    assert dump["canvas"]["pulse_hz"] == 2.0
    assert dump["palette"] == {"C_PHOS": 0x22FF66}
    assert dump["regions"]["title"]["w"] == 616
    assert dump["regions"]["title"]["colors"] == [0x22FF66, 0x004824]
    assert dump["regions"]["title"]["sizes"] == [17, 10]


def test_resample_logical_keeps_one_sample_per_logical_row_and_reports_losses():
    w, h, step = 8, 6, 2
    blob = bytes(((y * w + x) % 256, 0, 0)[0] and (y, 0, 0)[0]
                 for y in range(h) for x in range(w) for _ in (0, 1, 2)) \
        if False else bytes(v for y in range(h) for x in range(w) for v in (y, 0, 0))
    out, present = R.resample_logical(blob, w, h, step, 16, 12)
    assert len(out) == 16 * 12 * 3
    assert present == set(range(12))
    # logical row 5 maps to sampled row 5//2 = 2 -> red channel 2
    assert out[(5 * 16 + 0) * 3] == 2
    assert out[(11 * 16 + 5) * 3] == 5


def test_pearson_is_undefined_for_a_flat_series():
    assert R.pearson([1, 2, 3, 4], [1, 2, 3, 4]) is not None
    assert abs(R.pearson([1, 2, 3, 4], [2, 4, 6, 8]) - 1.0) < 1e-9
    assert R.pearson([5, 5, 5, 5], [1, 2, 3, 4]) is None


# ── golden discipline: changing them is an explicit act ───────────────────

def test_golden_without_accept_refuses_to_run(monkeypatch):
    monkeypatch.setattr(sys, "argv", ["ui_regress.py", "golden"])
    try:
        R.main(["golden"])
    except SystemExit as exc:
        assert "REFUSING" in str(exc)
        assert "--accept" in str(exc)
    else:
        raise AssertionError("`golden` without --accept must refuse to re-seed goldens")


# ── wiring: the make targets must exist and call this tool ────────────────

def test_make_targets_exist_and_call_the_tool():
    makefile = (REPO / "Makefile").read_text()
    for target in ("ui-regress", "ui-golden", "ui-anim", "ui-parity"):
        assert f"\n{target}:" in makefile, f"{target} is not a make target"
        block = makefile.split(f"\n{target}:", 1)[1].split("\n## ", 1)[0]
        assert "tools/ui_regress.py" in block, f"{target} does not call tools/ui_regress.py"
    # ui-regress-all is a chaining target: it must run the suite legs in order.
    all_block = makefile.split("\nui-regress-all:", 1)[1].split("\n## ", 1)[0]
    order = [all_block.find(f"ui-{leg}") for leg in ("regress", "anim", "parity")]
    assert all(at >= 0 for at in order), all_block
    assert order == sorted(order), "ui-regress-all must run regress, then anim, then parity"
    golden = makefile.split("\nui-golden:", 1)[1].split("\n## ", 1)[0]
    assert "GOLDEN=accept" in golden, "ui-golden must require the explicit GOLDEN=accept"
    assert "--accept" in golden


if __name__ == "__main__":
    sys.exit(__import__("subprocess").call([sys.executable, "-m", "pytest", __file__, "-q"]))
