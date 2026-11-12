#!/usr/bin/env python3
"""Decode `_mt8530fb_ioctl`'s dispatch chain in bdpdrv.ko.

The dispatcher is a hand-built binary search over the raw `cmd` value, not a
jump table: gcc emits `cmp r1, r3` against a literal-loaded constant
sometimes decremented by `sub r3,#imm`, followed by `beq <handler>`.

So the constants are recovered the same way the compiler produced them:
track the accumulator register's constant value through
  ldr r3,[pc,#x]   -> literal-pool word
  sub/add r3,#imm  -> arithmetic on the tracked value
and pair every `cmp r1,<tracked>` (or `cmp r1,#imm`) with the conditional
branch that follows it. Each `beq` target is then decoded for the function it
calls and the log string it prints -- which is how a number gets a NAME
without relying on any external header.

Usage:
  fb_decode_ioctl.py                 # the dispatch table
  fb_decode_ioctl.py --block 0x146c7c   # decode one handler block
"""
import argparse
import re

import fb_decode_common as C

FN = "_mt8530fb_ioctl"

_MOD = None
_RELMAP = None


def module():
    """Parse the module once per process; every query reuses it."""
    global _MOD, _RELMAP
    if _MOD is None:
        _MOD = C.Module()
        _RELMAP = _MOD.reloc_map(".text")
    return _MOD, _RELMAP
COND = ("beq", "bne", "bhi", "bls", "bgt", "ble", "bge", "blt", "bhs", "blo")
LIT_RE = re.compile(r"pc,\s*#(-?(?:0x[0-9a-fA-F]+|\d+))")


def dec(tok):
    return int(tok, 16) if tok.lstrip("-").startswith("0x") else int(tok)


def lit(mod, i):
    """(pool_addr, word, reloc_symbol) for an `ldr rX,[pc,#n]` instruction."""
    m = LIT_RE.search(i.ops)
    if not m:
        return None
    a = i.addr + 8 + dec(m.group(1))
    text = mod.sections[".text"].data()
    if not (0 <= a <= len(text) - 4):
        return None
    rl = _RELMAP.get(a)
    return a, mod.data_word(".text", a), (rl[0][1] if rl else None)


def target_of_branch(i):
    """Branch target of a `beq`/`b` instruction (operand is a bare address)."""
    # llvm-objdump appends " <sym+off>" to intra-function branch targets
    m = re.match(r"(?:0x)?([0-9a-f]+)", i.ops)
    return int(m.group(1), 16) if m else None


def chain(mod):
    """[(cmd_value, branch_mnemonic, target_addr, cmp_addr)]"""
    insns = mod.func_insns(FN)
    regs = {}          # reg -> known constant (None = unknown)
    got = []
    for idx, i in enumerate(insns):
        mn, ops = i.mn, i.ops
        if mn.startswith("ldr") and "pc" in ops:
            dest = ops.split(",")[0].strip()
            lv = lit(mod, i)
            if lv and lv[2] is None:
                regs[dest] = lv[1]
            else:
                regs[dest] = None
            continue
        m = re.match(r"(\w+),\s*(\w+),\s*#(-?(?:0x[0-9a-fA-F]+|\d+))", ops)
        if m and mn in ("sub", "add"):
            dst, src, imm = m.groups()
            base = regs.get(src)
            if base is None:
                regs[dst] = None
            elif mn == "sub":
                regs[dst] = (base - dec(imm)) & 0xFFFFFFFF
            else:
                regs[dst] = (base + dec(imm)) & 0xFFFFFFFF
            continue
        if mn.startswith("cmp"):
            m = re.match(r"r1,\s*(r\d+|#(?:0x[0-9a-fA-F]+|\d+))", ops)
            if m:
                rhs = m.group(1)
                val = regs.get(rhs) if rhs.startswith("r") else dec(rhs[1:])
                # the branch that consumes this comparison is the next one
                for j in range(idx + 1, min(idx + 4, len(insns))):
                    if insns[j].mn in COND or insns[j].mn == "b":
                        t = target_of_branch(insns[j])
                        if val is not None and t is not None:
                            got.append((val, insns[j].mn, t, i.addr))
                        break
            continue
        if re.match(r"(mov|movs)\s+(\w+),\s*#", ops):
            dst = ops.split(",")[1].strip()
            regs[dst] = None
    return got


def block(mod, start, limit=60):
    """(callees, first_log_string, strong_calls) for a handler block."""
    insns = mod.range(".text", start, start + limit * 4)
    out, strs, strong = [], [], []
    for i in insns:
        if i.reloc and i.reloc.startswith(("CALL", "PC24", "THM")):
            out.append((i.addr, i.reloc_sym))
            if i.reloc_sym.startswith(("mt8530", "_mt8530", "Mt8530",
                                       "OsdFlip", "MT8530")):
                strong.append(i.reloc_sym)
        if i.mn == "ldr" and "pc" in i.ops and not i.reloc:
            lv = lit(mod, i)
            if lv:
                w = lv[1]
                for sec in (".rodata.str1.1", ".rodata.str1.4", ".rodata"):
                    try:
                        s = mod.str_at(sec, w)
                    except Exception:
                        continue
                    if len(s) > 6 and s.isprintable():
                        strs.append(s.strip())
                        break
        if i.mn.startswith(("pop",)) or (i.mn == "b" and i.addr > start + 8):
            break
    return out, strs, strong


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--block", type=lambda s: int(s, 0))
    a = ap.parse_args()
    mod, _rel = module()

    if a.block is not None:
        calls, strs, strong = block(mod, a.block, 200)
        print(f"block {a.block:#x}:")
        for addr, nm in calls:
            print(f"  {addr:#09x} -> {nm}")
        for s in strs[:6]:
            print(f"  str: {s!r}")
        return

    print(f"{FN}: dispatch constants (value, branch, target)\n")
    rows = chain(mod)
    seen = {}
    for val, cond, tgt, cmp_addr in rows:
        if cond != "beq":
            continue
        calls, strs, strong = block(mod, tgt)
        name = strong[0] if strong else (strs[0] if strs else "-")
        seen.setdefault(val, (tgt, name, strs[:1]))
    print(f"{'cmd':>8}  {'handler@':>10}  handler / first log string")
    for val in sorted(seen):
        tgt, name, strs = seen[val]
        print(f"{val:#8x}  {tgt:#10x}  {name}")
    print(f"\n{len(seen)} distinct handled commands; "
          f"fall-through default at 0x1473ac returns the unsupported code.")
    # every conditional in the chain, for auditability
    print("\nall comparisons:")
    for val, cond, tgt, cmp_addr in rows:
        print(f"  cmp@ {cmp_addr:#09x}  {val:#8x}  {cond:4s} -> {tgt:#010x}")


if __name__ == "__main__":
    main()
