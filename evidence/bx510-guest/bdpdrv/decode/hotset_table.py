#!/usr/bin/env python3
"""Emit hotset-functions.txt: owning function(s) and instruction address(es) for
every target register.

Two distinct facts are reported, because this driver keeps them distinct:

  ALL OWNERS   every function in bdpdrv.ko with a resolved load/store to the
               address. Recomputed from the binary on every run.

  EXECUTED     the function the Run C50 trace actually shows running, derived by
               matching the trace's per-iteration read/write ORDER against the
               disassembly (see model-spec.md, "How the executed owner is
               established"). Static site counts are NOT a proxy for this: a
               one-site function inside a 12,000-iteration loop outranks a
               six-site init function, so the mapping is stated explicitly with
               the instruction address that produced each traced access.

Regenerate with:  hotset_table.py > hotset-functions.txt
"""
import resolve_addrs as ra
import trace_stats as ts

# addr -> (function, instruction, why this is the executed one)
EXECUTED = {
    0x7002420C: ("IRRX_PollMtkIr", 0x3102DC,
                 "single ldr + tst #0x40000 per call, once per IRRC thread loop = 12013 reads"),
    0x700240F4: ("i4VfdScanKeyWithDriver", 0x31A2F4,
                 "ldr/bic #15/str pair before every VFD burst = the 1234 RMW pairs"),
    0x70050300: ("i4VFDIndirectSIFCmdRegMode", 0x31901C,
                 "cmd word0 write, first in each 22-23 line trace cycle"),
    0x70050304: ("i4VFDIndirectSIFCmdRegMode", 0x319038,
                 "cmd word1 write, immediately after 0x300"),
    0x70050308: ("i4VFDIndirectSIFCmdRegMode", 0x319058,
                 "readback word0 after the 0x31/0x30 kick"),
    0x7005030C: ("i4VFDIndirectSIFCmdRegMode", 0x31907C, "readback word1"),
    0x70050310: ("i4VFDIndirectSIFCmdRegMode", 0x31909C, "readback word2"),
    0x70050314: ("i4VFDIndirectSIFCmdRegMode", 0x3190BC, "readback word3"),
    0x70050320: ("i4VFDTrigRegModeStart", 0x318C8C,
                 "write 0x31 then 0x30 (0x318cb4) per cycle; read by i4VFDWaitBusy @0x318af8"),
    0x70047108: ("vAudHalSetDspLoadTable", 0x4B544,
                 "table word write (0x4b544) then readback (0x4b568) per entry"),
    0x70047110: ("vAudHalSetDspLoadTable", 0x4B538,
                 "index port: 0-write + index-write per entry = 907 writes"),
}

TARGETS = [
    0x7002420C, 0x700240F4,
    0x70050300, 0x70050304, 0x70050308, 0x7005030C,
    0x70050310, 0x70050314, 0x70050320,
    0x70047108, 0x70047110,
    # secondary
    0x700000C0, 0x700000C8, 0x700000CC,
    0x70000180, 0x700001A0,
    0x7002117C, 0x70021184, 0x70021188,
    0x70005028, 0x700050C0, 0x700050CC,
    0x70003810, 0x70047028,
    0x70024580, 0x70024594,
    0x70024188, 0x70024144, 0x700241CC,
]


def main():
    reads, writes, _wv, _wd, _o = ts.load()
    mod = ra.Module()
    events = ra.resolve_all(mod, ra.parse(ra.disassemble()))

    by_addr = {}
    for insn, kind, _t, phys, width, _val, mn, fn in events:
        if phys is None:
            continue
        by_addr.setdefault(phys, []).append((insn, kind, fn))

    for addr in TARGETS:
        sites = by_addr.get(addr, [])
        r, w = reads.get(addr, 0), writes.get(addr, 0)
        ex = EXECUTED.get(addr)
        print(f"{addr:#010x}  R={r:<6d} W={w:<6d}")
        if ex:
            print(f"    executed: {ex[0]} @ {ex[1]:#08x}   -- {ex[2]}")
        else:
            print("    executed: NOT ESTABLISHED")
        if sites:
            per = {}
            for insn, kind, fn in sites:
                per.setdefault(fn, []).append((insn, kind))
            parts = [f"{fn}({'/'.join(sorted({f'{i:#x}{k}' for i, k in v}))})"
                     for fn, v in sorted(per.items())]
            print("    all owners: " + ", ".join(parts))
        else:
            print("    all owners: NONE RESOLVED")


if __name__ == "__main__":
    main()
