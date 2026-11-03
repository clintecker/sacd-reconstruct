#!/usr/bin/env python3
"""bx510 in-guest validation gate (team-review hardened edition).

Usage:
    bx510_gate_check.py positive A B     # valid-disc: gates per binary, then diff
    bx510_gate_check.py negative A B     # malformed-TOC control

A and B are transcript files (the .txt extracts produced by the gate
runner: protocol steps + STAT record; headers/marker noise tolerated).

Hardening (virtual-drive team review, altered-log fuzzing):
  1. The COMPLETE ORDERED sequence is required, with the expected
     response type on every step, both CLOSEs, the reconnect READ length,
     and the GC: DONE completion marker. Identically-malformed
     transcripts still fail (validation is per-binary, before any diff).
  2. The STAT record is REQUIRED in every transcript: syscall success
     (ret=0, errno=0) AND the module's operation result in arg[0]
     (a=0, signed). Successful payload reads do not cover this contract.
  3. Sweep responses are validated explicitly: all 12 delay/attempt
     combinations present exactly once, in the client's att-major order;
     delay>=100ms must be CLASS=ok with type=1 and result 0 (positive)
     or -1 (negative); delay=0ms is the documented teardown-race window
     (eof, or ok with the mode's result). A missing result is a FAILURE,
     not a pass (no None!=0 laxity).
  4. Boundary and encrypted-range sectors carry distinct nonzero data,
     so wrong-sector reads and packing failures cannot hide in zeros.
"""
import re
import sys

LSN = 2048
TOTAL_SECTORS = 86200
MID = 43100
AREA_LSN = 600
SWEEP_DELAYS = (0, 100, 300, 1000)
SWEEP_ATTS = (0, 1, 2)


def synthetic_sector(lsn):
    x = (lsn ^ 0x5ACD5ACD) & 0xFFFFFFFF
    out = bytearray(LSN)
    for i in range(0, LSN, 4):
        x ^= (x << 13) & 0xFFFFFFFF
        x ^= x >> 17
        x ^= (x << 5) & 0xFFFFFFFF
        out[i:i + 4] = x.to_bytes(4, "little")
    return bytes(out)


def enc_sector(lsn):
    """Distinct nonzero pattern for the encrypted range (mock decrypt is
    a verbatim copy, so these are also the expected wire bytes)."""
    x = (lsn ^ 0xDEAD5ACD) & 0xFFFFFFFF
    out = bytearray(LSN)
    for i in range(0, LSN, 4):
        x ^= (x << 13) & 0xFFFFFFFF
        x ^= x >> 17
        x ^= (x << 5) & 0xFFFFFFFF
        out[i:i + 4] = x.to_bytes(4, "little")
    return bytes(out)


def fnv1a64(data):
    h = 0xcbf29ce484222325
    for b in data:
        h ^= b
        h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF
    return h


def expected_payloads():
    e = {
        "lsn0": fnv1a64(synthetic_sector(0)),
        "lsnmid": fnv1a64(synthetic_sector(MID)),
        "lsn0x128": fnv1a64(b"".join(synthetic_sector(i) for i in range(128))),
        "boundary": fnv1a64(b"".join(synthetic_sector(i) for i in range(79990, 80000))),
        "encrypted": fnv1a64(b"".join(enc_sector(i) for i in range(80000, 80002))),
    }
    return e


def field(line, name):
    m = re.search(rf"\b{name}=(-?\d+)", line)
    return int(m.group(1)) if m else None


def field_hex(line, name):
    m = re.search(rf"\b{name}=([0-9a-f]{{16}})", line)
    return int(m.group(1), 16) if m else None


def parse_text(text):
    """Return (gc_steps, stat_line, has_begin, has_end)."""
    steps = []
    stat = None
    has_begin = has_end = False
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("GC: "):
            steps.append(line)
        elif line.startswith("STAT:"):
            stat = line
        elif line == "P0_CLIENT_BEGIN":
            has_begin = True
        elif line == "P0_CLIENT_END":
            has_end = True
    return steps, stat, has_begin, has_end


def check(cond, what, errs):
    if not cond:
        errs.append(what)


def require_field(line, name, want, what, errs):
    got = field(line, name)
    check(got is not None, f"{what}: field {name} missing", errs)
    if got is not None:
        check(got == want, f"{what}: {name}={got} != {want}", errs)


def require_hash(line, want, what, errs):
    got = field_hex(line, "fnv1a64")
    check(got is not None, f"{what}: fnv1a64 missing", errs)
    if got is not None:
        check(got == want, f"{what}: payload hash {got:016x} != {want:016x}", errs)


def expect_step(steps, idx, prefix, fields, errs, what, hashes=None):
    """steps[idx] must start with prefix and carry exactly the required
    field values. `fields` maps name->required value; a value of None
    means the field must be ABSENT."""
    if idx >= len(steps):
        errs.append(f"{what}: transcript ends before step {idx} ({prefix.strip()})")
        return None
    line = steps[idx]
    what_i = f"{what} step {idx}"
    check(line.startswith(prefix), f"{what_i}: expected {prefix.strip()!r}, got {line!r}", errs)
    for name, want in fields.items():
        if want is None:
            check(field(line, name) is None and field_hex(line, name) is None,
                  f"{what_i}: field {name} must be absent", errs)
        else:
            require_field(line, name, want, what_i, errs)
    if hashes:
        require_hash(line, hashes, what_i, errs)
    return line


def validate_sweep(steps, idx, ok_result, errs, what):
    """All 12 (att, delay) combos, att-major order, exactly once."""
    expected_order = [(a, d) for a in SWEEP_ATTS for d in SWEEP_DELAYS]
    seen = []
    n = 0
    for (a, d) in expected_order:
        if idx + n >= len(steps):
            errs.append(f"{what}: sweep incomplete (want att={a} delay={d})")
            break
        line = steps[idx + n]
        m = re.match(r"GC: SWEEP delay=(\d+)ms att=(\d+) port=\S+ CLASS=(\S+)(.*)$", line)
        if not m:
            errs.append(f"{what}: expected sweep line att={a} delay={d}, got {line!r}")
            return idx + n
        delay, att, cls, rest = int(m.group(1)), int(m.group(2)), m.group(3), m.group(4)
        seen.append((att, delay))
        what_s = f"{what} sweep att={att} delay={delay}"
        if (att, delay) != (a, d):
            errs.append(f"{what_s}: out of expected order")
        if delay == 0:
            # documented teardown-race window: eof or ok
            check(cls in ("eof", "ok"), f"{what_s}: unexpected CLASS={cls}", errs)
            if cls == "ok":
                require_field(rest, "type", 1, what_s, errs)
                require_field(rest, "result", ok_result, what_s, errs)
        else:
            check(cls == "ok", f"{what_s}: must be CLASS=ok, got {cls}", errs)
            if cls == "ok":
                require_field(rest, "type", 1, what_s, errs)
                require_field(rest, "result", ok_result, what_s, errs)
        n += 1
    dup = [x for x in set(seen) if seen.count(x) > 1]
    for x in dup:
        errs.append(f"{what}: sweep combination {x} appears more than once")
    return idx + n


def validate_stat(stat, errs, what):
    check(stat is not None, f"{what}: STAT record missing", errs)
    if stat is None:
        return
    m = re.match(r"STAT: ioctl\(5307\) ret=(-?\d+) errno=(-?\d+) a=(-?\d+)", stat)
    check(m is not None, f"{what}: STAT record malformed: {stat!r}", errs)
    if m:
        ret, errno, a = int(m.group(1)), int(m.group(2)), int(m.group(3))
        check(ret == 0, f"{what}: STAT ret={ret} != 0 (syscall must succeed)", errs)
        check(errno == 0, f"{what}: STAT errno={errno} != 0", errs)
        check(a == 0, f"{what}: STAT arg[0]={a} != 0 (module operation result)", errs)


def validate_common_tail(steps, idx, exp, ok_result, errs, what):
    idx = validate_sweep(steps, idx, ok_result, errs, what)
    check(idx < len(steps), f"{what}: missing GC: DONE completion marker", errs)
    if idx < len(steps):
        check(steps[idx] == "GC: DONE", f"{what}: expected GC: DONE after sweep, got {steps[idx]!r}", errs)
        idx += 1
    check(idx == len(steps), f"{what}: {len(steps) - idx} unexpected trailing GC lines", errs)


def validate_positive(text, exp):
    """Full ordered-sequence positive validation. Returns error list."""
    steps, stat, has_begin, has_end = parse_text(text)
    errs = []
    what = "positive"
    check(has_begin and has_end, f"{what}: P0_CLIENT_BEGIN/END markers missing", errs)
    validate_stat(stat, errs, what)

    if steps and steps[0].startswith("GC: connected"):
        idx = 1
    else:
        errs.append(f"{what}: missing 'GC: connected' as first step")
        idx = 0

    expect_step(steps, idx, "GC: OPEN  -> ", dict(type=1, result=0, datalen=-1), errs, what)
    idx += 1
    expect_step(steps, idx, "GC: SIZE  -> ", dict(type=4, result=TOTAL_SECTORS, datalen=None), errs, what)
    idx += 1
    expect_step(steps, idx, "GC: READ lsn=0 cnt=1 -> ",
                dict(type=3, result=1, datalen=LSN), errs, what, hashes=exp["lsn0"])
    idx += 1
    # data[0..15] line: first 16 payload bytes vs the generator
    ln = steps[idx] if idx < len(steps) else ""
    check(ln.startswith("GC: data[0..15]: "), f"{what} step {idx}: missing data[0..15] line", errs)
    if ln.startswith("GC: data[0..15]: "):
        want16 = synthetic_sector(0)[:16]
        toks = ln[len("GC: data[0..15]: "):].split(" fnv1a64=")[0].split()
        got16 = bytes(int(t, 16) for t in toks[:16])
        check(got16 == want16, f"{what} step {idx}: data[0..15] mismatch vs generator", errs)
        require_hash(ln, exp["lsn0"], f"{what} step {idx}", errs)
    idx += 1
    expect_step(steps, idx, "GC: READ lsn=43100 cnt=1 -> ",
                dict(type=3, result=1, datalen=LSN), errs, what, hashes=exp["lsnmid"])
    idx += 1
    expect_step(steps, idx, "GC: READ lsn=0 cnt=128 -> ",
                dict(type=3, result=128, datalen=128 * LSN), errs, what, hashes=exp["lsn0x128"])
    idx += 1
    expect_step(steps, idx, "GC: READ lsn=79990 cnt=20 (boundary) -> ",
                dict(type=3, result=10, datalen=10 * LSN), errs, what, hashes=exp["boundary"])
    idx += 1
    expect_step(steps, idx, "GC: READ lsn=80000 cnt=2 (encrypted) -> ",
                dict(type=3, result=2, datalen=2 * LSN), errs, what, hashes=exp["encrypted"])
    idx += 1
    expect_step(steps, idx, "GC: READ lsn=86300 (beyond EOF) -> ",
                dict(type=3, result=0, datalen=-1, fnv1a64=None), errs, what)
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
    expect_step(steps, idx, "GC: READ#2 lsn=43100 -> ",
                dict(type=3, result=1, datalen=LSN), errs, what, hashes=exp["lsnmid"])
    idx += 1
    expect_step(steps, idx, "GC: CLOSE#2 -> ", dict(type=2, result=0, datalen=None), errs, what)
    idx += 1
    validate_common_tail(steps, idx, exp, 0, errs, what)
    return errs


def validate_negative(text):
    """Malformed-TOC control: the documented failure sequence."""
    steps, stat, has_begin, has_end = parse_text(text)
    errs = []
    what = "negative"
    check(has_begin and has_end, f"{what}: P0_CLIENT_BEGIN/END markers missing", errs)
    validate_stat(stat, errs, what)

    if not steps or not steps[0].startswith("GC: connected"):
        errs.append(f"{what}: missing 'GC: connected' as first step")
        return errs
    idx = 1
    expect_step(steps, idx, "GC: OPEN  -> ", dict(type=1, result=-1, datalen=-1), errs, what)
    idx += 1
    expect_step(steps, idx, "GC: SIZE  -> ", dict(type=4, result=TOTAL_SECTORS, datalen=None), errs, what)
    idx += 1
    for tag in ("lsn=0 cnt=1", "lsn=43100 cnt=1", "lsn=0 cnt=128",
                "lsn=79990 cnt=20 (boundary)", "lsn=80000 cnt=2 (encrypted)"):
        expect_step(steps, idx, f"GC: READ {tag} -> ",
                    dict(type=3, result=-1, datalen=-1, fnv1a64=0), errs, what)
        idx += 1
    expect_step(steps, idx, "GC: READ lsn=86300 (beyond EOF) -> ",
                dict(type=3, result=-1, datalen=-1, fnv1a64=None), errs, what)
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
    expect_step(steps, idx, "GC: READ#2 lsn=43100 -> ",
                dict(type=3, result=-1, datalen=-1, fnv1a64=0), errs, what)
    idx += 1
    expect_step(steps, idx, "GC: CLOSE#2 -> ", dict(type=2, result=0, datalen=None), errs, what)
    idx += 1
    validate_common_tail(steps, idx, None, -1, errs, what)
    return errs


def protocol_steps(text):
    """GC steps excluding sweep lines, normalized (for the diff)."""
    return [s for s in parse_text(text)[0] if not s.startswith("GC: SWEEP")]


def run(mode, text_a, text_b):
    """Full check: per-binary gates BEFORE any diff. Returns (exit, lines)."""
    out = []
    errs = []
    exp = expected_payloads()
    if mode == "positive":
        for name, text in (("original", text_a), ("release", text_b)):
            e = validate_positive(text, exp)
            if e:
                out.append(f"GATE: POSITIVE-FAIL {name}:")
                out.extend(f"  - {x}" for x in e)
                errs += e
            else:
                out.append(f"GATE: POSITIVE-PASS {name} (complete ordered sequence, computed hashes)")
    else:
        for name, text in (("original", text_a), ("release", text_b)):
            e = validate_negative(text)
            if e:
                out.append(f"GATE: NEGATIVE-FAIL {name}:")
                out.extend(f"  - {x}" for x in e)
                errs += e
            else:
                out.append(f"GATE: NEGATIVE-PASS {name} (documented failure sequence)")
        out.append("GATE: NEGATIVE-CONTROL — successful-disc parity NOT awarded "
                   "(equal-failure-equal is explicitly rejected as a parity claim)")

    # sweep race-window report (characterization, not parity)
    for name, text in (("original", text_a), ("release", text_b)):
        for s in parse_text(text)[0]:
            if s.startswith("GC: SWEEP") and "delay=0ms" in s:
                cls = s[s.index("CLASS="):]
                out.append(f"SWEEP[{name}] delay=0 (race window): {cls}")

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
    mode, pa, pb = sys.argv[1], sys.argv[2], sys.argv[3]
    rc, out = run(mode, open(pa).read(), open(pb).read())
    for line in out:
        print(line)
    return rc


if __name__ == "__main__":
    sys.exit(main())
