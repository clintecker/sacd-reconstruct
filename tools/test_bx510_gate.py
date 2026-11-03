#!/usr/bin/env python3
"""Regression controls for the bx510 gate: altered-log fuzzing.

The virtual-drive team demonstrated that the earlier gate accepted
invalid evidence: applying specific alterations to BOTH transcripts of
a pair still produced PASS. Each alteration here is a permanent
control — the gate must FAIL every one of them, and must PASS the
unaltered baseline.

The baseline transcripts are constructed programmatically from the
gate's own generators (expected hashes are computed, not copied from a
run), in the exact line formats the in-guest client prints. The
real-run transcripts must match this template; if the client format
drifts, the real run fails loudly and this file is updated in the same
commit.

Run directly (python3 tools/test_bx510_gate.py) or via pytest.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bx510_gate_check as gate  # noqa: E402


def _sweep_lines(ok_result):
    lines = []
    for att in (0, 1, 2):
        for delay in (0, 100, 300, 1000):
            if delay == 0:
                # baseline uses the race-window eof outcome; ok-with-result
                # is equally valid per the gate rules
                lines.append(f"GC: SWEEP delay=0ms att={att} port=N CLASS=eof")
            else:
                lines.append(f"GC: SWEEP delay={delay}ms att={att} port=N "
                             f"CLASS=ok OPEN type=1 result={ok_result}")
    return lines


def baseline_positive():
    e = gate.expected_payloads()
    s0 = gate.synthetic_sector(0)
    hex16 = " ".join(f"{b:02x}" for b in s0[:16])
    lines = [
        "P0_CLIENT_BEGIN",
        "GC: connected 127.0.0.1:2002",
        "GC: OPEN  -> type=1 result=0 datalen=-1",
        "GC: SIZE  -> type=4 result=86200 (sectors)",
        f"GC: READ lsn=0 cnt=1 -> type=3 result=1 datalen=2048 fnv1a64={e['lsn0']:016x}",
        f"GC: data[0..15]: {hex16} fnv1a64={e['lsn0']:016x}",
        f"GC: READ lsn=43100 cnt=1 -> type=3 result=1 datalen=2048 fnv1a64={e['lsnmid']:016x}",
        f"GC: READ lsn=0 cnt=128 -> type=3 result=128 datalen=262144 fnv1a64={e['lsn0x128']:016x}",
        f"GC: READ lsn=79990 cnt=20 (boundary) -> type=3 result=10 datalen=20480 fnv1a64={e['boundary']:016x}",
        f"GC: READ lsn=80000 cnt=2 (encrypted) -> type=3 result=2 datalen=4096 fnv1a64={e['encrypted']:016x}",
        "GC: READ lsn=86300 (beyond EOF) -> type=3 result=0 datalen=-1",
        "GC: CLOSE -> type=2 result=0",
        "GC: post-close read -> 0 (EOF)",
        "GC: reconnected",
        "GC: OPEN#2 -> type=1 result=0",
        f"GC: READ#2 lsn=43100 -> type=3 result=1 datalen=2048 fnv1a64={e['lsnmid']:016x}",
        "GC: CLOSE#2 -> type=2 result=0",
    ]
    lines += _sweep_lines(0)
    lines += ["GC: DONE", "P0_CLIENT_END",
              "STAT: ioctl(5307) ret=0 errno=0 a=0 b=0 c=0 d=0"]
    return "\n".join(lines) + "\n"


def baseline_negative():
    lines = [
        "P0_CLIENT_BEGIN",
        "GC: connected 127.0.0.1:2002",
        "GC: OPEN  -> type=1 result=-1 datalen=-1",
        "GC: SIZE  -> type=4 result=86200 (sectors)",
        "GC: READ lsn=0 cnt=1 -> type=3 result=-1 datalen=-1 fnv1a64=0000000000000000",
        "GC: READ lsn=43100 cnt=1 -> type=3 result=-1 datalen=-1 fnv1a64=0000000000000000",
        "GC: READ lsn=0 cnt=128 -> type=3 result=-1 datalen=-1 fnv1a64=0000000000000000",
        "GC: READ lsn=79990 cnt=20 (boundary) -> type=3 result=-1 datalen=-1 fnv1a64=0000000000000000",
        "GC: READ lsn=80000 cnt=2 (encrypted) -> type=3 result=-1 datalen=-1 fnv1a64=0000000000000000",
        "GC: READ lsn=86300 (beyond EOF) -> type=3 result=-1 datalen=-1",
        "GC: CLOSE -> type=2 result=0",
        "GC: post-close read -> 0 (EOF)",
        "GC: reconnected",
        "GC: OPEN#2 -> type=1 result=-1",
        "GC: READ#2 lsn=43100 -> type=3 result=-1 datalen=-1 fnv1a64=0000000000000000",
        "GC: CLOSE#2 -> type=2 result=0",
    ]
    lines += _sweep_lines(-1)
    lines += ["GC: DONE", "P0_CLIENT_END",
              "STAT: ioctl(5307) ret=0 errno=0 a=0 b=0 c=0 d=0"]
    return "\n".join(lines) + "\n"


def _must_pass(mode, a, b, label):
    rc, out = gate.run(mode, a, b)
    assert rc == 0, f"{label}: expected PASS, got FAIL:\n" + "\n".join(out)
    return out


def _must_fail(mode, a, b, label):
    rc, out = gate.run(mode, a, b)
    assert rc != 0, f"{label}: gate accepted invalid evidence (must FAIL)"
    return out


# ---- baseline: unaltered transcripts must pass both modes ----

def test_baseline_positive_passes():
    _must_pass("positive", baseline_positive(), baseline_positive(),
               "baseline positive")


def test_baseline_negative_passes():
    _must_pass("negative", baseline_negative(), baseline_negative(),
               "baseline negative")


# ---- team-review alteration 1: remove STAT record and CLOSE#2 ----

def test_alteration_remove_stat_and_close2():
    def alter(text):
        lines = [ln for ln in text.splitlines()
                 if not ln.startswith("STAT:") and ln != "GC: CLOSE#2 -> type=2 result=0"]
        return "\n".join(lines) + "\n"
    _must_fail("positive", alter(baseline_positive()), alter(baseline_positive()),
               "remove STAT + CLOSE#2")


# ---- team-review alteration 2: every response type becomes 99 ----

def test_alteration_types_99():
    import re

    def alter(text):
        return re.sub(r"type=-?\d+", "type=99", text)
    _must_fail("positive", alter(baseline_positive()), alter(baseline_positive()),
               "types=99")


# ---- team-review alteration 3: positive sweep reports result=-1 ----

def test_alteration_positive_sweep_failure_result():
    def alter(text):
        return text.replace("CLASS=ok OPEN type=1 result=0",
                            "CLASS=ok OPEN type=1 result=-1")
    _must_fail("positive", alter(baseline_positive()), alter(baseline_positive()),
               "positive sweep result=-1")


# ---- team-review alteration 4: negative OPEN result removed entirely ----

def test_alteration_negative_open_result_removed():
    def alter(text):
        return text.replace("GC: OPEN  -> type=1 result=-1 datalen=-1",
                            "GC: OPEN  -> type=1 datalen=-1")
    _must_fail("negative", alter(baseline_negative()), alter(baseline_negative()),
               "negative OPEN result removed")


# ---- additional controls: sequence/done/sweep-integrity ----

def test_alteration_missing_done_marker():
    def alter(text):
        return "\n".join(ln for ln in text.splitlines() if ln != "GC: DONE") + "\n"
    _must_fail("positive", alter(baseline_positive()), alter(baseline_positive()),
               "missing GC: DONE")


def test_alteration_duplicated_sweep_combo():
    def alter(text):
        lines = text.splitlines()
        for i, ln in enumerate(lines):
            if ln.startswith("GC: SWEEP delay=100ms att=0"):
                lines.insert(i, ln)
                break
        return "\n".join(lines) + "\n"
    _must_fail("positive", alter(baseline_positive()), alter(baseline_positive()),
               "duplicated sweep combination")


def test_alteration_reordered_reads():
    def alter(text):
        lines = text.splitlines()
        i1 = next(i for i, ln in enumerate(lines) if ln.startswith("GC: READ lsn=0 cnt=1"))
        i2 = next(i for i, ln in enumerate(lines) if ln.startswith("GC: READ lsn=43100"))
        lines[i1], lines[i2] = lines[i2], lines[i1]
        return "\n".join(lines) + "\n"
    _must_fail("positive", alter(baseline_positive()), alter(baseline_positive()),
               "reordered READ steps")


def test_alteration_stat_op_result_nonzero():
    def alter(text):
        return text.replace("a=0 b=0", "a=-5 b=0")
    _must_fail("positive", alter(baseline_positive()), alter(baseline_positive()),
               "STAT arg[0] nonzero")


def test_fixture_generators_agree():
    """The C guest fixture and the python reference must produce identical
    boundary/encrypted bytes (salt-level parity of the generators)."""
    import struct

    def py_enc(lsn):
        x = (lsn ^ 0xDEAD5ACD) & 0xFFFFFFFF
        out = bytearray(gate.LSN)
        for i in range(0, gate.LSN, 4):
            x ^= (x << 13) & 0xFFFFFFFF
            x ^= x >> 17
            x ^= (x << 5) & 0xFFFFFFFF
            out[i:i + 4] = struct.pack("<I", x)
        return bytes(out)
    assert gate.enc_sector(80000) == py_enc(80000)
    assert gate.enc_sector(80001) == py_enc(80001)
    assert gate.enc_sector(80000) != gate.synthetic_sector(80000)


def main():
    tests = [(k, v) for k, v in sorted(globals().items()) if k.startswith("test_")]
    failed = 0
    for name, fn in tests:
        try:
            fn()
            print(f"PASS  {name}")
        except AssertionError as e:
            failed += 1
            print(f"FAIL  {name}: {e}")
    print(f"\n{len(tests) - failed}/{len(tests)} passed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
