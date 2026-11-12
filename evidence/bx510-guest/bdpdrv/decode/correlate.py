#!/usr/bin/env python3
"""Correlate the Run C50 MMIO trace against bdpdrv's resolved access sites.

For every address QEMU logged as unimplemented, report:
  * read / write counts and the written-value histogram (from the trace)
  * every .ko instruction that resolves to that address, with its owning
    function and vendor symbol name (from resolve_addrs.py)

This is the join that turns "the driver poked 0x7002420c 12,013 times" into
"IRRX_PollMtkIr tests bit 18 of the IR RX status register".

Usage:
  correlate.py                 # every traced address, hottest first
  correlate.py --lo 0x70024000 --hi 0x70025000
  correlate.py --summary       # coverage / confidence numbers only
"""
import argparse
import sys
from collections import defaultdict

import resolve_addrs as ra
import trace_stats as ts


def owner_table(events):
    """addr -> {kind: [(insn_addr, func, mnemonic, value)]}"""
    out = defaultdict(lambda: {"R": [], "W": []})
    for addr, kind, _target, phys, width, val, mn, fname in events:
        if phys is None:
            continue
        out[phys][kind].append((addr, fname, mn, val, width))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lo", type=lambda s: int(s, 0))
    ap.add_argument("--hi", type=lambda s: int(s, 0))
    ap.add_argument("--summary", action="store_true")
    a = ap.parse_args()

    reads, writes, wvals, widths, _order = ts.load()
    mod = ra.Module()
    events = ra.resolve_all(mod, ra.parse(ra.disassemble()))
    owners = owner_table(events)

    traced = sorted(set(reads) | set(writes), key=lambda x: -(reads[x] + writes[x]))
    covered = [t for t in traced if t in owners]
    print(f"traced addresses:            {len(traced)}")
    print(f"  with >=1 resolved access:  {len(covered)} "
          f"({100.0 * len(covered) / len(traced):.1f}%)")
    kinds = defaultdict(int)
    for t in traced:
        o = owners.get(t)
        if not o:
            kinds["unresolved"] += 1
        else:
            if o["R"] and reads.get(t):
                kinds["read-site matched"] += 1
            if o["W"] and writes.get(t):
                kinds["write-site matched"] += 1
            if not o["R"] and reads.get(t):
                kinds["traced-read, no read site"] += 1
            if not o["W"] and writes.get(t):
                kinds["traced-write, no write site"] += 1
    for k, v in sorted(kinds.items()):
        print(f"  {k:32s} {v}")
    if a.summary:
        return

    lo, hi = a.lo, a.hi
    for t in traced:
        if lo is not None and not (lo <= t < hi):
            continue
        o = owners.get(t)
        fn_r = sorted({x[1] for x in o["R"]}) if o else []
        fn_w = sorted({x[1] for x in o["W"]}) if o else []
        print(f"\n{t:#010x}  R={reads.get(t, 0)}  W={writes.get(t, 0)}  width={widths.get(t)}")
        if wvals.get(t):
            vs = " ".join(f"{v:#x}x{c}" for v, c in wvals[t].most_common(6))
            print(f"    writes: {vs}")
        for fn in fn_r:
            sites = [x for x in o["R"] if x[1] == fn]
            print(f"    R  {fn}  @ " + ", ".join(f"{x[0]:#x}/{x[2]}/{x[4]}B" for x in sites))
        for fn in fn_w:
            sites = [x for x in o["W"] if x[1] == fn]
            print(f"    W  {fn}  @ " + ", ".join(
                f"{x[0]:#x}/{x[2]}" + (f"={x[3]:#x}" if x[3] is not None else "")
                for x in sites))
        if not o:
            print("    (no resolved access site -- see model-spec.md unresolved list)")


if __name__ == "__main__":
    sys.exit(main())
