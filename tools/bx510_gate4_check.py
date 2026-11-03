#!/usr/bin/env python3
"""bx510_gate4_check.py — validator for the 5 GiB boundary-sentinel battery.

Usage:
    bx510_gate4_check.py positive A B    # valid-disc battery, per-binary
                                         # gates then transcript diff
    bx510_gate4_check.py negative A B    # malformed-TOC control

Same discipline as bx510_gate_check (hardened edition): per-binary
validation of the COMPLETE ordered sequence with computed payload
expectations BEFORE any transcript diff; sweep lines are reconnect
characterization (all 12 combos exactly once; delay=0 is the documented
race window); STAT record required with ret=0 errno=0 a=0.

Battery expectations (docs/large-image-interface.md):
  OPEN=0; SIZE=2621440;
  sentinel singles at 1048575/1048576 (2 GiB), 2097151/2097152 (4 GiB),
  2621439 (final) — hash-verified per LSN;
  128-sector straddle reads at 1048512 and 2097136 — hash of the joined
  synthetic span, crossing the 2 GiB and 4 GiB byte-offset boundaries;
  clamp at the track range: read 1048494 cnt=20 -> result=6, hash of
  synthetic(1048494..1048499);
  encrypted pair at 80000 (regression anchor inside the track range —
  the mock decrypt is verbatim, so expected = written bytes);
  beyond-EOF at 2621440 -> result=0;
  CLOSE, post-close EOF, reconnect OPEN#2/READ#2 (2GiB-high)/CLOSE#2,
  sweep, DONE.
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bx510_gate_check import (  # noqa: E402
    LSN, parse_text, check, expect_step, validate_sweep, validate_stat,
    validate_common_tail, protocol_steps, require_hash,
)

TOTAL = 2621440
MID_SENTINEL = 1048576
from bx510_gate_check import synthetic_sector, fnv1a64  # noqa: E402


def span_hash(lo, n):
    return fnv1a64(b"".join(synthetic_sector(i) for i in range(lo, lo + n)))


def expected(tag):
    m = re.match(r"lsn=(\d+) cnt=(\d+)", tag)
    lsn, cnt = int(m.group(1)), int(m.group(2))
    if tag.startswith("lsn=1048494"):
        return 6, span_hash(lsn, 6)          # clamp at track_start
    if tag.startswith("lsn=2621440"):
        return 0, None                        # beyond EOF: no payload
    return cnt, span_hash(lsn, cnt)


BIG_TAGS = [
    "lsn=1048575 cnt=1 (2GiB-low)",
    "lsn=1048576 cnt=1 (2GiB-high)",
    "lsn=2097151 cnt=1 (4GiB-low)",
    "lsn=2097152 cnt=1 (4GiB-high)",
    "lsn=2621439 cnt=1 (final)",
    "lsn=1048512 cnt=128 (2GiB-straddle)",
    "lsn=2097136 cnt=128 (4GiB-straddle)",
    "lsn=1048494 cnt=20 (clamp)",
    "lsn=80000 cnt=2 (encrypted)",
    "lsn=2621440 cnt=1 (beyond EOF)",
]


def validate_positive(text):
    steps, stat, hb, he = parse_text(text)
    errs = []
    what = "big-positive"
    check(hb and he, f"{what}: P0_CLIENT_BEGIN/END markers missing", errs)
    validate_stat(stat, errs, what)
    if not steps or not steps[0].startswith("GC: connected"):
        errs.append(f"{what}: missing 'GC: connected' as first step")
        return errs
    idx = 1
    expect_step(steps, idx, "GC: OPEN  -> ", dict(type=1, result=0, datalen=-1), errs, what)
    idx += 1
    expect_step(steps, idx, "GC: SIZE  -> ", dict(type=4, result=TOTAL, datalen=None), errs, what)
    idx += 1
    for tag in BIG_TAGS:
        res, hsh = expected(tag)
        fields = dict(type=3, result=res, datalen=res * LSN) if hsh \
            else dict(type=3, result=res, datalen=-1, fnv1a64=0)
        ln = expect_step(steps, idx, f"GC: READ {tag} -> ", fields, errs, what)
        if ln is not None and hsh:
            require_hash(ln, hsh, f"{what} step {idx}", errs)
        idx += 1
    expect_step(steps, idx, "GC: CLOSE -> ", dict(type=2, result=0, datalen=None), errs, what)
    idx += 1
    ln = steps[idx] if idx < len(steps) else ""
    check(ln == "GC: post-close read -> 0 (EOF)", f"{what} step {idx}: expected post-close EOF, got {ln!r}", errs)
    idx += 1
    ln = steps[idx] if idx < len(steps) else ""
    check(ln == "GC: reconnected", f"{what} step {idx}: expected 'GC: reconnected', got {ln!r}", errs)
    idx += 1
    expect_step(steps, idx, "GC: OPEN#2 -> ", dict(type=1, result=0, datalen=None), errs, what)
    idx += 1
    res, hsh = expected("lsn=1048576 cnt=1 (2GiB-high)")
    ln = expect_step(steps, idx, "GC: READ#2 lsn=1048576 -> ",
                     dict(type=3, result=1, datalen=LSN), errs, what)
    if ln is not None:
        require_hash(ln, hsh, f"{what} step {idx}", errs)
    idx += 1
    expect_step(steps, idx, "GC: CLOSE#2 -> ", dict(type=2, result=0, datalen=None), errs, what)
    idx += 1
    validate_common_tail(steps, idx, None, 0, errs, what)
    return errs


def validate_negative(text):
    steps, stat, hb, he = parse_text(text)
    errs = []
    what = "big-negative"
    check(hb and he, f"{what}: P0_CLIENT_BEGIN/END markers missing", errs)
    validate_stat(stat, errs, what)
    if not steps or not steps[0].startswith("GC: connected"):
        errs.append(f"{what}: missing 'GC: connected' as first step")
        return errs
    idx = 1
    expect_step(steps, idx, "GC: OPEN  -> ", dict(type=1, result=-1, datalen=-1), errs, what)
    idx += 1
    expect_step(steps, idx, "GC: SIZE  -> ", dict(type=4, result=TOTAL, datalen=None), errs, what)
    idx += 1
    for tag in BIG_TAGS:
        expect_step(steps, idx, f"GC: READ {tag} -> ",
                    dict(type=3, result=-1, datalen=-1, fnv1a64=0), errs, what)
        idx += 1
    expect_step(steps, idx, "GC: CLOSE -> ", dict(type=2, result=0, datalen=None), errs, what)
    idx += 1
    ln = steps[idx] if idx < len(steps) else ""
    check(ln == "GC: post-close read -> 0 (EOF)", f"{what} step {idx}: expected post-close EOF, got {ln!r}", errs)
    idx += 1
    ln = steps[idx] if idx < len(steps) else ""
    check(ln == "GC: reconnected", f"{what} step {idx}: expected 'GC: reconnected', got {ln!r}", errs)
    idx += 1
    expect_step(steps, idx, "GC: OPEN#2 -> ", dict(type=1, result=-1, datalen=None), errs, what)
    idx += 1
    expect_step(steps, idx, "GC: READ#2 lsn=1048576 -> ",
                dict(type=3, result=-1, datalen=-1, fnv1a64=0), errs, what)
    idx += 1
    expect_step(steps, idx, "GC: CLOSE#2 -> ", dict(type=2, result=0, datalen=None), errs, what)
    idx += 1
    validate_common_tail(steps, idx, None, -1, errs, what)
    return errs


def run(mode, text_a, text_b):
    out, errs = [], []
    for name, text, v in (("original", text_a, validate_positive),
                          ("release", text_b, validate_positive)) \
            if mode == "positive" else \
            (("original", text_a, validate_negative),
             ("release", text_b, validate_negative)):
        e = v(text)
        if e:
            out.append(f"GATE4: {mode.upper()}-FAIL {name}:")
            out.extend(f"  - {x}" for x in e)
            errs += e
        else:
            out.append(f"GATE4: {mode.upper()}-PASS {name} "
                        f"(complete ordered sequence, computed boundary hashes)")
    for name, text in (("original", text_a), ("release", text_b)):
        for s in parse_text(text)[0]:
            if s.startswith("GC: SWEEP") and "delay=0ms" in s:
                out.append(f"SWEEP[{name}] delay=0 (race window): {s[s.index('CLASS='):]}")
    if errs:
        return 1, out
    a_ns, b_ns = protocol_steps(text_a), protocol_steps(text_b)
    if a_ns == b_ns:
        out.append("DIFF: TRANSCRIPTS IDENTICAL (protocol steps; sweep reported above)")
        return 0, out
    out.append("DIFF: TRANSCRIPTS DIFFER")
    for a, b in zip(a_ns, b_ns):
        if a != b:
            out.append(f"  A: {a}")
            out.append(f"  B: {b}")
    return 1, out


def main():
    if len(sys.argv) != 4 or sys.argv[1] not in ("positive", "negative"):
        print(__doc__)
        return 2
    rc, out = run(sys.argv[1], open(sys.argv[2]).read(), open(sys.argv[3]).read())
    for line in out:
        print(line)
    return rc


if __name__ == "__main__":
    sys.exit(main())
