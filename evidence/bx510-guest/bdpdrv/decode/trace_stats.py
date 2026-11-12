#!/usr/bin/env python3
"""Per-address read/write counts and written-value histograms from a QEMU
`-d unimp` MMIO trace (bdpdrv Run C50 format).

Input line format:
    bx510: unimplemented read  0x7002420c (4)
    bx510: unimplemented write 0x70024144 = 0x100 (4)

Usage:
  trace_stats.py                      # whole-hot-set summary
  trace_stats.py --addr 0x7002420c    # one register, with value histogram
  trace_stats.py --values             # value histograms for every register
"""
import argparse
import re
from collections import Counter, defaultdict

TRACE = ("/Users/clint/code/sacd-reconstruct/evidence/bx510-guest/"
         "bdpdrv/bdpdrv-runC50.mmio.log")
RE_R = re.compile(r"unimplemented read\s+0x([0-9a-f]+)\s+\((\d+)\)")
RE_W = re.compile(r"unimplemented write\s+0x([0-9a-f]+)\s+=\s+0x([0-9a-f]+)\s+\((\d+)\)")


def load(path=TRACE):
    reads, writes, widths, wvals = Counter(), Counter(), {}, defaultdict(Counter)
    order = []
    with open(path) as fh:
        for line in fh:
            m = RE_W.search(line)
            if m:
                a, v, w = int(m.group(1), 16), int(m.group(2), 16), int(m.group(3))
                writes[a] += 1
                wvals[a][v] += 1
                widths.setdefault(a, w)
                if a not in order:
                    order.append(a)
                continue
            m = RE_R.search(line)
            if m:
                a, w = int(m.group(1), 16), int(m.group(2))
                reads[a] += 1
                widths.setdefault(a, w)
                if a not in order:
                    order.append(a)
    return reads, writes, wvals, widths, order


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--addr", type=lambda s: int(s, 0))
    ap.add_argument("--values", action="store_true")
    ap.add_argument("--top", type=int, default=40)
    a = ap.parse_args()

    reads, writes, wvals, widths, order = load()

    if a.addr is not None:
        print(f"{a.addr:#010x}  R={reads[a.addr]}  W={writes[a.addr]}  "
              f"width={widths.get(a.addr)}")
        for v, c in wvals[a.addr].most_common(20):
            print(f"    writes {v:#010x} x{c}")
        return

    addrs = sorted(set(reads) | set(writes), key=lambda x: -(reads[x] + writes[x]))
    print(f"{'address':>12} {'R':>7} {'W':>7}  width  top values")
    print(f"{'total':>12} {sum(reads.values()):>7} {sum(writes.values()):>7}")
    print(f"{'distinct':>12} {len(reads):>7} {len(writes):>7}")
    print("-" * 78)
    for addr in addrs[:a.top]:
        vals = wvals[addr].most_common(4)
        vs = " ".join(f"{v:#x}x{c}" for v, c in vals)
        print(f"{addr:#012x} {reads[addr]:7d} {writes[addr]:7d}  {widths.get(addr):5d}  {vs}")
    if a.values:
        print()
        for addr in addrs:
            for v, c in wvals[addr].most_common():
                print(f"{addr:#010x} {v:#010x} x{c}")


if __name__ == "__main__":
    main()
