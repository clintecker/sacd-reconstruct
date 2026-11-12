#!/usr/bin/env python3
"""Decode the Run C91 MMIO trace tail: the post-AACS sequence and the stall.

Run C91 is the first rig run in which the FE boot chain completes end to end:
FE firmware accepted, SRAM verify OK, port 0 up, AACS download, FE IRQ drain.
The run then parks.  This script turns the trace into the four artifacts the
`post-aacs-state.md` document cites:

  --phases     compressed timeline: runs of identical (op, addr) collapsed,
               each address labelled with the driver functions that can own it
               (owner map derived mechanically by resolve_addrs.py --all)
  --regions    address-block histogram for a line window
  --new        addresses in C91 that never appear in the C50 trace, i.e. blocks
               the model has never been asked about before
  --rmw        every read-modify-write round on a named shared register
  --tail       which addresses stay alive at the end of the run (thread map)
  --checks     assertions the document depends on; exit 1 if any fails

All MMIO addresses are printed as guest-physical (PA).  The driver stores
kernel VAs; PA = VA - 0x8d000000 (model-spec.md §1).

Usage (CWD = repo root, via `make sacd-py`):
  python3 evidence/bx510-guest/bdpdrv/decode/post_aacs_trace.py --phases
  python3 evidence/bx510-guest/bdpdrv/decode/post_aacs_trace.py --new
"""

import argparse
import collections
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.dirname(HERE)                      # evidence/bx510-guest/bdpdrv
TRACE_C91 = os.path.join(BASE, "bdpdrv-runC91.mmio.log")
TRACE_C50 = os.path.join(BASE, "bdpdrv-runC50.mmio.log")
RESOLVE = os.path.join(HERE, "resolve_addrs.py")
OWNER_CACHE = "/tmp/post_aacs_owners.txt"

# The two markers that bound the post-AACS window (line numbers found, then
# asserted in --checks; they are facts about this trace, not conventions).
LOGO_VALUE = 0x4F474F4C          # "LOGO" in the driver's own byte order
LOGO_ADDR = 0x7005C010
FE_IRQ_CLR_ALL = 0x7005C800      # port_start's final "clear all FE interrupts"

READ_RE = re.compile(r"unimplemented read (0x[0-9a-f]+)")
WRITE_RE = re.compile(r"unimplemented write (0x[0-9a-f]+) = (0x[0-9a-f]+)")

Event = collections.namedtuple("Event", "line op addr value")

# Block names inside the 0x70000000..0x70ffffff IO window.  Keys are the
# 0x1000-aligned base; everything not listed is reported by raw address.
BLOCKS = {
    0x70000000: "CKGEN/clock+PWM",
    0x70003000: "video path (gamma 0x3810 prefix, 0x3740/0x35c* ctrl)",
    0x70004000: "audio clock/IEC958 (0x50c0 prefix)",
    0x70021000: "HDMI TX (0x2117c/0x21184/0x21188 prefix)",
    0x70024000: "FE shared control (IR/CEC/DDC/SIF/IRQ)",
    0x70032000: "SATA/SVOIF port window",
    0x70037000: "video sequencer",
    0x70042000: "video plane 0 (0x424xx table walk)",
    0x70043000: "video plane 1 (0x434xx table walk)",
    0x70044000: "video NR / _vNRHW* (0x44804 reset, 0x44e00 nonstd)",
    0x70047000: "audio DSP load port",
    0x70050000: "VFD front-panel MCU (SIF command interface)",
    0x7005c000: "FE/IDE control block (command 0x5c00x, DRAM win 0x5c5xx)",
    0x7005f000: "graphics/IOMMU (0x5f0xx)",
    0x70081000: "BIM interrupt controller",
    0x70090000: "DRAM wrapper",
}


def block_of(addr):
    """Nearest declared block base at or below addr (1 MiB granularity)."""
    if not 0x70000000 <= addr < 0x71000000:
        return "outside IO window"
    # prefer the 0x1000 page, then the 0x10000 region, then the 0x100000 one
    for shift in (12, 16, 20):
        key = (addr >> shift) << shift
        if key in BLOCKS:
            return BLOCKS[key]
    return "unclassified 0x%08x" % ((addr >> 20) << 20)


def parse(path):
    ev = []
    with open(path, "r", errors="replace") as fh:
        for n, line in enumerate(fh, 1):
            m = WRITE_RE.search(line)
            if m:
                ev.append(Event(n, "W", int(m.group(1), 16), int(m.group(2), 16)))
                continue
            m = READ_RE.search(line)
            if m:
                ev.append(Event(n, "R", int(m.group(1), 16), None))
    return ev


def owners():
    """addr -> sorted list of owning function names, from resolve_addrs --all."""
    if not os.path.exists(OWNER_CACHE):
        out = subprocess.run([sys.executable, RESOLVE, "--all"],
                             capture_output=True, text=True, check=True).stdout
        with open(OWNER_CACHE, "w") as fh:
            fh.write(out)
    table = collections.defaultdict(set)
    with open(OWNER_CACHE) as fh:
        for line in fh:
            # 0x0130bf8 W4 0xfd024188 phys 0x70024188  str       VSFHW_SramClk
            m = re.match(r"\S+\s+\S+\s+\S+\s+\S+\s+(0x[0-9a-f]+)\s+.*?\s(\S+)$", line)
            if m:
                table[int(m.group(1), 16)].add(m.group(2))
    return table


def marker_lines(ev):
    return {
        "logo": [e.line for e in ev
                 if e.addr == LOGO_ADDR and e.op == "W" and e.value == LOGO_VALUE],
        "fe_clr_all": [e.line for e in ev
                       if e.addr == FE_IRQ_CLR_ALL and e.value == 0xFFFFFFF0],
        "aacs_end": [e.line for e in ev
                     if e.addr == 0x700324B00 % (1 << 32)],  # 0x70324b00 loader-done
    }


def phases(ev, lo, hi, own, min_run=1):
    """Compressed timeline; consecutive identical (op, addr) collapse."""
    win = [e for e in ev if lo <= e.line <= hi]
    runs = []
    for e in win:
        if runs and runs[-1][0].op == e.op and runs[-1][0].addr == e.addr:
            runs[-1][1] = e.line
            runs[-1][2] += 1
            runs[-1][3].append(e.value)
        else:
            runs.append([e, e.line, 1, [e.value]])
    print(f"# compressed timeline lines {lo}..{hi}: {len(win)} events, {len(runs)} runs")
    print(f"{'lines':>17}  {'n':>5}  {'op':2} {'addr':10}  value(s)")
    for first, last, n, vals in runs:
        if n < min_run:
            continue
        uniq = sorted({v for v in vals if v is not None})
        vtxt = ",".join("0x%x" % v for v in uniq[:4])
        if len(uniq) > 4:
            vtxt += ",…(%d)" % len(uniq)
        who = ",".join(sorted(own.get(first.addr, ())))[:70]
        print(f"{first.line:>7}-{last:<9} {n:>5}  {first.op:2} "
              f"0x{first.addr:08x}  {vtxt:<28} {who}")


def regions(ev, lo, hi):
    win = [e for e in ev if lo <= e.line <= hi]
    c = collections.Counter()
    first = {}
    for e in win:
        k = (e.addr >> 12) << 12
        c[k] += 1
        first.setdefault(k, e.line)
    print(f"# 4 KiB-page histogram, lines {lo}..{hi} ({len(win)} events)")
    print(f"{'page':12} {'n':>6} {'first':>7}  block")
    for k, n in c.most_common():
        print(f"0x{k:08x} {n:>8} {first[k]:>7}  {block_of(k)}")


def new_addresses(ev_c91, ev_c50):
    seen50 = {e.addr for e in ev_c50}
    new = collections.OrderedDict()
    for e in ev_c91:
        if e.addr not in seen50 and e.addr not in new:
            new[e.addr] = e.line
    print(f"# addresses present in C91 and absent from C50: {len(new)}")
    by_block = collections.defaultdict(list)
    for a, ln in new.items():
        by_block[block_of(a)].append((ln, a))
    for blk in sorted(by_block, key=lambda b: min(x[0] for x in by_block[b])):
        items = sorted(by_block[blk])
        print(f"\n## {blk}: {len(items)} addresses, first at line {items[0][0]}")
        for ln, a in items:
            print(f"   line {ln:>7}  0x{a:08x}")


def rmw(ev, addr):
    """Every read immediately followed by a write of the same address."""
    print(f"# read-modify-write rounds on 0x{addr:08x}")
    for i in range(len(ev) - 1):
        a, b = ev[i], ev[i + 1]
        if a.addr == addr and a.op == "R" and b.addr == addr and b.op == "W":
            print(f"  lines {a.line}/{b.line}: read -> write 0x{b.value:x}")


def subsystems(ev, lo, hi, own, min_events=8):
    """Run-length the block label; report each run with its likeliest owners.

    A run = consecutive events in the same block.  Owners are ranked by how many
    distinct addresses of the run they touch (resolve_addrs --all), so a run of
    CEC registers names _CEC_Init and not a neighbour that shares one address.
    """
    win = [e for e in ev if lo <= e.line <= hi]
    runs = []
    for e in win:
        b = block_of(e.addr)
        if runs and runs[-1][0] == b:
            runs[-1][1] = e.line
            runs[-1][2].append(e.addr)
            runs[-1][3] += 1
        else:
            runs.append([b, e.line, [e.addr], 1])
    print(f"# subsystem runs, lines {lo}..{hi} ({len(win)} events)")
    print(f"{'lines':>17} {'n':>6}  block / likeliest owners")
    for blk, last, addrs, n in runs:
        if n < min_events:
            continue
        score = collections.Counter()
        for a in set(addrs):
            score.update(own.get(a, ()))
        top = ", ".join(f"{f}({c})" for f, c in score.most_common(4))
        print(f"{last - n + 1:>7}-{last:<9} {n:>6}  {blk}  {top}")


def tail(ev, last_n):
    win = ev[-last_n:]
    c = collections.Counter((e.op, e.addr) for e in win)
    print(f"# last {last_n} events (line {win[0].line}..{win[-1].line})")
    print(f"{'op':2} {'addr':12} {'n':>6}  last line")
    last = {}
    for e in win:
        last[(e.op, e.addr)] = e.line
    for (op, addr), n in c.most_common(20):
        print(f"{op:2} 0x{addr:08x} {n:>8}  {last[(op, addr)]}")


def thread_map(ev, lo, hi, own):
    """Per-address last-seen inside a window: which poll stopped when."""
    first, last, n = {}, {}, collections.Counter()
    for e in ev:
        if not lo <= e.line <= hi:
            continue
        first.setdefault(e.addr, e.line)
        last[e.addr] = e.line
        n[e.addr] += 1
    print(f"# per-address first/last inside lines {lo}..{hi}")
    print(f"{'addr':12} {'n':>6} {'first':>7} {'last':>7}  owners")
    for a in sorted(first, key=lambda a: -n[a]):
        who = ",".join(sorted(own.get(a, ())))[:60]
        print(f"0x{a:08x} {n[a]:>6} {first[a]:>7} {last[a]:>7}  {who}")


def checks(ev):
    """Assertions post-aacs-state.md depends on.  Exit non-zero on any failure."""
    ok = True

    def chk(name, cond, detail=""):
        nonlocal ok
        print(f"{'PASS' if cond else 'FAIL'}  {name}{('  ' + detail) if detail else ''}")
        ok = ok and cond

    logo = [e for e in ev if e.addr == LOGO_ADDR]
    chk("0x5c010 is written exactly once", len(logo) == 1, f"n={len(logo)}")
    chk("0x5c010 is never read", all(e.op == "W" for e in logo))
    chk("the write value is 0x4f474f4c ('LOGO')",
        logo and logo[0].value == LOGO_VALUE,
        "0x%x" % logo[0].value if logo else "absent")

    reads_5c804 = [e for e in ev if e.addr == 0x7005C804]
    chk("0x5c804 is never read (top half only writes back)",
        all(e.op == "W" for e in reads_5c804),
        f"{len(reads_5c804)} accesses")
    chk("0x5c804 drains to 0 after the LOGO write",
        reads_5c804 and reads_5c804[-1].value == 0,
        f"last=0x{reads_5c804[-1].value:x}" if reads_5c804 else "absent")

    # 0x24188 RMW rounds: read followed by write, after the LOGO write
    rounds = []
    for i in range(len(ev) - 1):
        a, b = ev[i], ev[i + 1]
        if a.addr == 0x70024188 and a.op == "R" and b.addr == 0x70024188 and b.op == "W":
            rounds.append((a.line, b.value))
    post = [r for r in rounds if logo and r[0] > logo[0].line]
    chk("three 0x24188 RMW rounds after the LOGO write",
        len(post) == 3, str([(ln, hex(v)) for ln, v in post]))
    chk("they write 0x0, 0x2, 0x0",
        [v for _, v in post] == [0x0, 0x2, 0x0],
        str([hex(v) for _, v in post]))

    # The 0x5c704 FE reset-release must precede everything in this window.
    # Its WRITES are modelled (sony-bx510.c case 0x5c704) so they never reach
    # the -d unimp log; only the driver's READS are visible.
    r5c704 = [e for e in ev if e.addr == 0x7005C704]
    chk("0x5c704 appears in the log only as reads (the write is modelled)",
        r5c704 and all(e.op == "R" for e in r5c704),
        str([(e.line, e.op) for e in r5c704]))

    # Owner attribution of the three 0x24188 rounds, from the instruction
    # stream that follows/precedes each one (see post-aacs-state.md §3).
    def window(centre, span):
        return [e for e in ev if centre < e.line <= centre + span]

    def has(evs, addr, value=None):
        return any(e.op == "W" and e.addr == addr
                   and (value is None or e.value == value) for e in evs)

    if len(post) == 3:
        cec = window(post[0][0], 12)
        chk("round 1 is _CEC_Init's bic #4096 (CEC block follows)",
            has(cec, 0x70024504, 0xF) and has(cec, 0x700245BC, 0x40004019),
            "0x24504=0xf, 0x245bc=0x40004019")
        chk("round 2 is _vCommonSRAMInit's orr #2 (video/NR reset follows)",
            has([e for e in ev if post[1][0] - 3 < e.line <= post[1][0]], 0x70044804),
            "0x70044804 (_vNRHWReset) immediately before")
        ir = [e for e in ev if post[2][0] - 8 < e.line < post[2][0]]
        chk("round 3 is IRHW_RxInit's bic #2^20 (IR config triple before)",
            has(ir, 0x7002420C, 0x111) and has(ir, 0x70024210, 0xE1),
            "0x2420c=0x111, 0x24210=0xe1 immediately before")

    # The 200-iteration chk_int_ldr poll that produced the UART timeout: every
    # 0x5c804 write between the last pre-port_start event and port_start's own
    # 0x5c800 clear-all must be that one loop (it writes r6 once per iteration
    # and is bounded at 200 by `cmp r7,#200` at .text+0x289c).
    clr = [e.line for e in ev if e.addr == FE_IRQ_CLR_ALL and e.value == 0xFFFFFFF0][0]
    poll = [e for e in ev if e.addr == 0x7005C804 and e.op == "W"
            and e.line < clr and e.line > 83600]
    chk("201 0x5c804 writes before the port_start clear-all = 1 message-A "
        "iteration + chk_int_ldr's 200 x msleep(10) message-B poll",
        len(poll) == 201, f"n={len(poll)}")
    chk("that poll saw bit16 only on its first read (message A), then never",
        poll and poll[0].value == 0x10000 and all(e.value == 0 for e in poll[1:]),
        f"first=0x{poll[0].value:x}" if poll else "absent")

    # Steady state: nothing but the two poll threads after the VFD pump starts.
    first_vfd = min((e.line for e in ev if e.addr == 0x70050300), default=0)
    after = {e.addr for e in ev if e.line > first_vfd + 1000}
    steady_ok = all((a >> 12) in (0x70024, 0x70050, 0x70000, 0x70008)
                    for a in after)
    chk("after the VFD pump starts, all traffic is the 0x70024/0x70050 poll set",
        steady_ok, f"unexpected blocks: "
        f"{sorted({hex((a>>12)<<12) for a in after if (a>>12) not in (0x70024,0x70050,0x70000,0x70008)})}")

    print("\n%s" % ("ALL CHECKS PASS" if ok else "CHECKS FAILED"))
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--phases", action="store_true")
    ap.add_argument("--regions", action="store_true")
    ap.add_argument("--new", action="store_true")
    ap.add_argument("--rmw", action="store_true")
    ap.add_argument("--tail", action="store_true")
    ap.add_argument("--subsystems", action="store_true")
    ap.add_argument("--min-events", type=int, default=8)
    ap.add_argument("--thread-map", action="store_true")
    ap.add_argument("--checks", action="store_true")
    ap.add_argument("--lo", type=int, default=0)
    ap.add_argument("--hi", type=int, default=1 << 30)
    ap.add_argument("--last-n", type=int, default=400)
    ap.add_argument("--min-run", type=int, default=1)
    args = ap.parse_args()

    ev = parse(TRACE_C91)
    print(f"# {TRACE_C91}: {len(ev)} MMIO events, lines 1..{ev[-1].line}")

    own = owners() if (args.phases or args.thread_map or args.subsystems) else {}

    if args.checks:
        return checks(ev)
    if args.phases:
        phases(ev, args.lo or 1, args.hi, own, args.min_run)
    if args.regions:
        regions(ev, args.lo or 1, args.hi)
    if args.new:
        new_addresses(ev, parse(TRACE_C50))
    if args.rmw:
        rmw(ev, 0x70024188)
    if args.subsystems:
        subsystems(ev, args.lo or 1, args.hi, own, args.min_events)
    if args.tail:
        tail(ev, args.last_n)
    if args.thread_map:
        thread_map(ev, args.lo or 1, args.hi, own)
    return 0


if __name__ == "__main__":
    sys.exit(main())
