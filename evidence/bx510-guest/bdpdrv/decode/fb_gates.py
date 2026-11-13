#!/usr/bin/env python3
"""fb_gates.py — do the fb/GFX gates fire on this run?

The fb lane's question (fb-surface.md §4.3, §7 step 1) is narrow: does the
guest's own fb/GFX code already run against the modelled machine, or is the
model the thing in the way? This script answers it from one MMIO log, per
gate, with counts.

Input — a BX510_TRACE=1 run (`emulator-kit/sony-bx510.c` bx510_read/write):

    bx510: MMIO R 004000 sz4                <- offset = phys - 0x70000000
    bx510: MMIO W 004000 sz4 = a0000000
    bx510: unimplemented read 0x70004004 (4)     <- default-arm noise, ignored
    bx510: unimplemented write 0x70004008 = 0x975e0000 (4)   when MMIO absent

Two things a log of this shape can and cannot prove:
  * READS CARRY NO VALUE. The status-poll verdict is not in the trace; only
    that the poll happened. Gates are therefore structural (which offset, in
    which order, with which write value), never "the poll returned idle".
  * With BX510_TRACE=1 every access is logged, so ABSENCE of an access in a
    complete log is evidence of absence — unlike a missing UART line, which
    is not evidence of anything (fb-surface.md §2.1).
A `-d unimp`-only log (no `MMIO ` lines) is accepted as a fallback, but there
the log carries only the UNIMPLEMENTED accesses: a gate that PASSes is real,
a gate that FAILs may just be "that register is modelled". The report says
which source it used.

Usage:
  fb_gates.py TRACE                     # gates from one MMIO log
  fb_gates.py TRACE --uart UART.log     # + G2 (the UART-string gate)
  fb_gates.py TRACE -v --dump           # per-leg detail + every gfx access
  fb_gates.py --selftest                # synthetic fixtures, exit 0 == PASS

Exit status: 0 when every gate PASSes, 1 when any gate is FAIL or
INDETERMINATE (a gate harness that cannot answer is not a pass).
"""

import argparse
import gzip
import os
import re
import sys
import tempfile

BX_IO_BASE = 0x70000000
GFX_LO, GFX_HI = 0x4000, 0x5000          # engine-0 window (fb-surface.md §4.1)
ENGINE1 = {0x40000, 0x40004, 0x40010}    # R11: engine 1, unmodelled

# Gate G2's three UART skins (fb-surface.md §2.1: literals .rodata.str1.1
# +0x54ea5 fail / +0x54ed6 success, logged through vFBDbgLog).
UART_TAG = "_mt8530fb_probe"
UART_FAIL = "_mt8530fb_probe() fail"
UART_OK = "_mt8530fb_probe(): probe init OK!"

RE_MMIO = re.compile(r"bx510: MMIO ([RW]) ([0-9a-f]+) sz(\d+)(?: = ([0-9a-f]+))?")
RE_UNIMP = re.compile(
    r"bx510: unimplemented (read|write) 0x([0-9a-f]+)(?: = 0x([0-9a-f]+))? \((\d+)\)")

PASS, FAIL, INDET = "PASS", "FAIL", "INDETERMINATE"


class Ev:
    """One MMIO access in the gfX window (kind, offset, write value or None)."""
    __slots__ = ("kind", "off", "val")

    def __init__(self, kind, off, val):
        self.kind, self.off, self.val = kind, off, val

    def __repr__(self):
        v = "" if self.val is None else " = %#x" % self.val
        return "%s %#06x%s" % (self.kind, self.off, v)


class Trace:
    def __init__(self):
        self.ev_mmio = []                 # gfx-window events from `MMIO` lines
        self.ev_unimp = []                # ... and from `unimplemented` lines
        self.events = []                  # whichever set the log can serve
        self.lines = 0
        self.mmio_lines = 0
        self.unimp_lines = 0
        self.engine1 = 0
        self.src = "none"                 # "BX510_TRACE" | "unimp" | "none"


def _open(path):
    with open(path, "rb") as fh:
        magic = fh.read(2)
    if magic == b"\x1f\x8b":
        return gzip.open(path, "rt", errors="replace")
    return open(path, "r", errors="replace")


def parse(path):
    """Scan a log once, keeping only the gfx-window events (a C9x log is 5M
    lines; keeping every event would cost ~GBs for no extra gate)."""
    t = Trace()
    for line in _open(path):
        t.lines += 1
        if "bx510: MMIO " in line:
            m = RE_MMIO.search(line)
            if not m:
                continue
            t.mmio_lines += 1
            off = int(m.group(2), 16)
            val = int(m.group(4), 16) if m.group(4) else None
            if GFX_LO <= off < GFX_HI:
                t.ev_mmio.append(Ev(m.group(1), off, val))
            elif off in ENGINE1:
                t.engine1 += 1
        elif "unimplemented " in line:
            m = RE_UNIMP.search(line)
            if not m:
                continue
            t.unimp_lines += 1
            off = int(m.group(2), 16) - BX_IO_BASE
            val = int(m.group(3), 16) if m.group(3) else None
            kind = "R" if m.group(1) == "read" else "W"
            if GFX_LO <= off < GFX_HI:
                t.ev_unimp.append(Ev(kind, off, val))
            elif off in ENGINE1:
                t.engine1 += 1
    # A BX510_TRACE log logs BOTH shapes for an unmodelled register — the
    # `MMIO R/W` line and the default arm's `unimplemented` line for the same
    # access (Run C95 line pairs 2616804/2616805 and 2616806/2616807). Taking
    # both would double every count on exactly the registers the gates are
    # about, so the MMIO set wins whenever the log has one.
    if t.ev_mmio:
        t.events, t.src = t.ev_mmio, "BX510_TRACE"
    elif t.ev_unimp:
        t.events, t.src = t.ev_unimp, "unimp"
    return t


def count(events, kind, off):
    return sum(1 for e in events if e.kind == kind and e.off == off)


# ---------------------------------------------------------------- the gates --
# Every leg below names the instruction that issues the access; the phys
# address behind it comes from `resolve_addrs.py --reach 0x70004xxx` against
# /tmp/bdpdrv/bdpdrv.ko (sha256 6604f6cd…, the fb-surface.md subject).

G1_LEGS = [
    ("W 0x4000 = 0xa0000000", "reset command word",     ".text 0x176898", lambda e: e.kind == "W" and e.off == 0x4000 and e.val == 0xa0000000),
    ("W 0x4010",              "engine control word",    ".text 0x1768d4", lambda e: e.kind == "W" and e.off == 0x4010),
    ("R 0x4000",              "status poll",            ".text 0x176958", lambda e: e.kind == "R" and e.off == 0x4000),
    ("R 0x400c",              "RMW read",               ".text 0x176a14", lambda e: e.kind == "R" and e.off == 0x400c),
    ("W 0x400c",              "RMW write | 0x10000000", ".text 0x176a2c", lambda e: e.kind == "W" and e.off == 0x400c),
    ("R 0x4134",              "read before write",      ".text 0x176a3c", lambda e: e.kind == "R" and e.off == 0x4134),
    ("W 0x4134",              "write back",             ".text 0x176a78", lambda e: e.kind == "W" and e.off == 0x4134),
]

def gate_g1(events):
    """G1 — GFX_HwReset ran to its end. The body is an ordered access
    sequence (0x176898 .. 0x176a78); reaching the last leg means the poll
    loop at 0x17694c-0x17697c was satisfied and the function returned
    instead of wedging. Note the 0x176a98 0x4010 write is skipped unless the
    caller passed r5 == 0x10 (`cmp r5,#16 / bne 0x176a9c`), so it is not a
    leg. The poll `ldr` at 0x176958 reads whichever engine the r4 argument
    selects (`cmp r4,#0 / moveq r3,<0xfd004000> / movne r3,<0xfd040000>` at
    0x17694c-0x176954) — `resolve_addrs.py --func GFX_HwReset` reports the
    engine-1 address there because it resolves the `movne` path, but Run C95
    ran with r4 == 0 and had 0 engine-1 accesses."""
    legs, i = [], 0
    for k, (label, why, cite, pred) in enumerate(G1_LEGS):
        hit = None
        while i < len(events):
            if pred(events[i]):
                hit = i
                break
            i += 1
        if hit is None:
            legs.append((label, why, cite, None))
            for rest in G1_LEGS[k + 1:]:
                legs.append((rest[0], rest[1], rest[2], None))
            break
        legs.append((label, why, cite, hit))
        i = hit + 1
    n = sum(1 for leg in legs if leg[3] is not None)
    detail = ["%d/%d legs: %s" % (n, len(G1_LEGS),
                                  ", ".join(leg[0] for leg in legs if leg[3] is not None))]
    for label, why, cite, at in legs:
        detail.append("%s %-22s %-20s %s" % (
            "leg" if at is not None else "MISSING",
            label, cite, why if at is None else "%s (event #%d)" % (why, at)))
    return (PASS if n == len(G1_LEGS) else FAIL), detail


def _split_400c(events):
    """Separate the two owners of 0x400c by shape:
      * GFX_HwReset reads it, ORs in 0x10000000 and writes it back
        (`ldr r2,[r3]` 0x176a14 / `orr r2,r2,#0x10000000` 0x176a20 /
         `str r2,[r3]` 0x176a2c) -> the write is PAIRED with a read;
      * GFX_CmdQueAction computes its value on the stack and writes it with
        no read of 0x400c anywhere in the function (`str r2,[r3]` 0x175bcc,
        the only 0x400c access `resolve_addrs.py --reach` reports for it)
        -> the write is UNPAIRED.
    Pairing is per-offset, not per-adjacent-line: other streams (SATA, BIM)
    interleave freely in a trace_all log."""
    paired, unpaired, pending = [], [], False
    for e in events:
        if e.off != 0x400c:
            continue
        if e.kind == "R":
            pending = True
        else:
            (paired if pending else unpaired).append(e.val)
            pending = False
    return paired, unpaired


def gate_g3(events):
    """G3 — GFX_CmdQueAction executed (the ring got an action)."""
    paired, unpaired = _split_400c(events)
    qbase = [e.val for e in events if e.kind == "W" and e.off == 0x4008]
    detail = [
        "0x400c writes: %d paired (HwReset RMW)%s, %d unpaired (CmdQueAction)%s"
        % (len(paired), _vals(paired), len(unpaired), _vals(unpaired)),
        "0x4008 queue-base writes (G3 context, owners GFX_CmdQue{Reset,Restore,"
        "Change} .text 0x1756d8/0x17607c/0x176130): %d%s" % (len(qbase), _vals(qbase)),
    ]
    return (PASS if unpaired else FAIL), detail


def gate_g4(events):
    """G4 — GFX_HwGetIdle ran (it is the only 0x4004 reader, .text 0x177074,
    `and r3,r3,#1` at 0x177084; polarity of bit0 is INFERRED per
    fb-surface.md §4.2 R2, which is why the model row needs this gate first)."""
    n = count(events, "R", 0x4004)
    detail = ["0x4004 reads (GFX_HwGetIdle): %d" % n]
    return (PASS if n else FAIL), detail


def gate_g2(uart_text):
    """G2 — register_framebuffer's success path, from the UART log.

    fb-surface.md §2.1 is explicit that absence of the success line is NOT
    evidence, so "fail line absent" alone cannot be a PASS: the probe's lines
    go through vFBDbgLog, which returns immediately unless a `.bss` enable
    byte is set (`ldrb r3,[r3] / cmp r3,#0 / beq` at .text 0x14a010-0x14a01c,
    literals 0x14a050/0x14a054). With that flag at its default the driver is
    silent, which is exactly what every captured run shows."""
    if uart_text is None:
        return INDET, ["no --uart log given"]
    has_fail = UART_FAIL in uart_text
    has_ok = UART_OK in uart_text
    has_tag = UART_TAG in uart_text
    detail = ["fail line: %s | success line: %s | any probe tag: %s"
              % (has_fail, has_ok, has_tag)]
    if has_fail:
        return FAIL, detail + ["probe returned -6 (ENXIO): fb registration failed"]
    if has_ok:
        return PASS, detail + ["registered; /proc/fb + sysfs are the follow-up"]
    if has_tag:
        return INDET, detail + ["probe tag seen but neither terminal line"]
    return INDET, detail + [
        "probe tag absent — vFBDbgLog's enable flag is off in captured runs, "
        "so this gate cannot fire from UART; use /proc/fb + sysfs (fb-surface.md "
        "§4.3 G3/G4) or the MMIO gates here"]


def _vals(vals):
    return (" [" + " ".join("%#x" % v if v is not None else "?" for v in vals[:6])
            + ("…" if len(vals) > 6 else "") + "]") if vals else ""


def evaluate(trace, uart_text):
    res = []
    for name, fn in (("G1 HwReset-complete", lambda: gate_g1(trace.events)),
                     ("G2 fb-registered (UART)", lambda: gate_g2(uart_text)),
                     ("G3 CmdQueAction", lambda: gate_g3(trace.events)),
                     ("G4 HwGetIdle", lambda: gate_g4(trace.events))):
        status, detail = fn()
        res.append((name, status, detail))
    return res


def report(path, trace, res, verbose, dump):
    print("trace:  %s" % path)
    print("source: %s lines (%d MMIO, %d unimplemented) in %d lines"
          % (trace.src, trace.mmio_lines, trace.unimp_lines, trace.lines))
    if trace.src == "unimp":
        print("NOTE:   an unimplemented-only log cannot show modelled registers,"
              " so a FAIL here may mean 'answered by the model', not 'not run'")
    print("gfx:    %d events in 0x%04x..0x%04x; engine-1 (0x40000+) events: %d"
          % (len(trace.events), GFX_LO, GFX_HI, trace.engine1))
    if dump:
        for n, e in enumerate(trace.events):
            print("  #%-4d %r" % (n, e))
    print("")
    for name, status, detail in res:
        print("%-24s %s" % (name, status))
        if verbose or status != PASS:
            for d in detail:
                print("    %s" % d)
    bad = [n for n, s, _ in res if s != PASS]
    print("")
    if bad:
        print("VERDICT: %d of 4 gates not PASS (%s)" % (len(bad), ", ".join(bad)))
    else:
        print("VERDICT: all 4 gates PASS")
    return 0 if not bad else 1


# ---------------------------------------------------------------- selftest --
CHECKS = []


def check(what, cond, cite):
    CHECKS.append((what, bool(cond), cite))
    return cond


def _trace_from(lines):
    """Run the real parser over a synthetic log (fixture = the model's own
    line shapes, so the parser is part of what the selftest checks)."""
    with tempfile.NamedTemporaryFile("w", suffix=".mmio.log", delete=False) as fh:
        fh.write("".join(line + "\n" for line in lines))
        path = fh.name
    try:
        return parse(path)
    finally:
        os.unlink(path)


def _status(res, name):
    return next(s for n, s, _ in res if n.startswith(name))


def selftest():
    del CHECKS[:]

    # 1. the Run C95 shape: HwReset complete, no CmdQueAction, no HwGetIdle.
    c95 = _trace_from([
        "bx510: MMIO W 008034 sz4 = 44000",
        "bx510: MMIO W 004000 sz4 = a0000000",
        "bx510: MMIO W 004010 sz4 = c00001f0",
        "bx510: MMIO R 004000 sz4",
        "bx510: MMIO W 004000 sz4 = f0000000",
        "bx510: MMIO W 004000 sz4 = 0",
        "bx510: MMIO R 004000 sz4",
        "bx510: MMIO W 004000 sz4 = a000029e",
        "bx510: MMIO R 00400c sz4",
        "bx510: unimplemented read 0x7000400c (4)",
        "bx510: MMIO W 00400c sz4 = 10000000",
        "bx510: MMIO R 004134 sz4",
        "bx510: unimplemented read 0x70004134 (4)",
        "bx510: MMIO W 004134 sz4 = 0",
        "bx510: MMIO W 004008 sz4 = 975e0000",
    ])
    r = evaluate(c95, None)
    check("C95 shape: G1 PASS", _status(r, "G1") == PASS, "all 7 HwReset legs present in order")
    check("C95 shape: G2 INDETERMINATE without a UART log", _status(r, "G2") == INDET, "gate_g2(None)")
    check("C95 shape: G3 FAIL", _status(r, "G3") == FAIL, "the one 0x400c write is read-paired (HwReset RMW)")
    check("C95 shape: G4 FAIL", _status(r, "G4") == FAIL, "no 0x4004 read")
    check("C95 shape: the unimplemented 0x4134/0x400c echoes are not double-counted",
          sum(1 for e in c95.events if e.off == 0x400c) == 2
          and sum(1 for e in c95.events if e.off == 0x4134) == 2,
          "four lines -> two accesses per offset when MMIO lines win")
    check("C95 shape: src is BX510_TRACE", c95.src == "BX510_TRACE", "ev_mmio wins over ev_unimp")

    # 1b. an unimplemented-only log (a plain `-d unimp` run, e.g. Run C50)
    # still yields gate evidence — every line there IS an unimplemented one.
    unimp = _trace_from([
        "bx510: unimplemented read 0x70004004 (4)",
        "bx510: unimplemented write 0x70004008 = 0x975e0000 (4)",
    ])
    check("unimplemented-only log: parsed with src=unimp and both events",
          unimp.src == "unimp" and len(unimp.events) == 2, "fallback path")

    # 2. the post-R2/R3/R4/R7 shape: CmdQueAction ran, HwGetIdle ran.
    full = _trace_from([
        "bx510: MMIO W 004000 sz4 = a0000000",
        "bx510: MMIO W 004010 sz4 = c00001f0",
        "bx510: MMIO R 004000 sz4",
        "bx510: MMIO R 00400c sz4",
        "bx510: MMIO W 00400c sz4 = 10000000",
        "bx510: MMIO R 004134 sz4",
        "bx510: MMIO W 004134 sz4 = 0",
        "bx510: MMIO W 004008 sz4 = 975e0000",
        "bx510: MMIO W 00400c sz4 = 2",
        "bx510: MMIO R 004004 sz4",
        "bx510: MMIO R 004004 sz4",
    ])
    r = evaluate(full, None)
    check("post-rows shape: G1 PASS", _status(r, "G1") == PASS, "same ordered legs")
    check("post-rows shape: G3 PASS on the unpaired 0x400c write (=0x2)",
          _status(r, "G3") == PASS, "GFX_CmdQueAction's str at .text 0x175bcc has no paired read")
    check("post-rows shape: G4 PASS on 0x4004 reads", _status(r, "G4") == PASS, ".text 0x177074")

    # 3. the wedge shape: the poll is entered but the body never completes.
    wedge = _trace_from([
        "bx510: MMIO W 004000 sz4 = a0000000",
        "bx510: MMIO W 004010 sz4 = c00001f0",
        "bx510: MMIO R 004000 sz4",
        "bx510: MMIO R 004000 sz4",
        "bx510: MMIO R 004000 sz4",
    ])
    r = evaluate(wedge, None)
    check("wedge shape: G1 FAIL with 3/7 legs", _status(r, "G1") == FAIL, "the 0x400c/0x4134 legs never appear")
    check("wedge shape: G3/G4 FAIL", _status(r, "G3") == FAIL and _status(r, "G4") == FAIL, "no ring action, no idle read")

    # 4. G2, all four UART skins.
    check("G2 PASS on the success line",
          gate_g2(UART_OK + "\n")[0] == PASS, ".rodata.str1.1+0x54ed6")
    check("G2 FAIL on the fail line",
          gate_g2(UART_FAIL + "\n" + UART_OK + "\n")[0] == FAIL, ".rodata.str1.1+0x54ea5 wins over a later OK")
    check("G2 INDETERMINATE on a silent log (absence is not evidence)",
          gate_g2("[FBM] Init FBMS\n")[0] == INDET, "fb-surface.md §2.1")
    check("G2 INDETERMINATE on tag-only",
          gate_g2("x _mt8530fb_probe y\n")[0] == INDET, "reached the probe, no terminal line")

    print("fb_gates selftest")
    ok = True
    for what, good, cite in CHECKS:
        print("  %-4s %-64s %s" % ("ok" if good else "FAIL", what, cite))
        ok = ok and good
    print("  %d/%d checks" % (sum(1 for _, g, _ in CHECKS if g), len(CHECKS)))
    print("selftest %s" % ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("trace", nargs="?", help="MMIO log (.gz or plain)")
    ap.add_argument("--uart", help="UART log for gate G2")
    ap.add_argument("-v", "--verbose", action="store_true")
    ap.add_argument("--dump", action="store_true",
                    help="print every gfx-window access in file order")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()

    if a.selftest:
        return selftest()
    if not a.trace:
        ap.error("a trace path is required (or --selftest)")

    trace = parse(a.trace)
    if trace.src == "none":
        print("no bx510 MMIO lines in %s — not a QEMU -d log for this machine" % a.trace)
        return 1
    uart = None
    if a.uart:
        with _open(a.uart) as fh:
            uart = fh.read()
    return report(a.trace, trace, evaluate(trace, uart), a.verbose, a.dump)


if __name__ == "__main__":
    sys.exit(main())
