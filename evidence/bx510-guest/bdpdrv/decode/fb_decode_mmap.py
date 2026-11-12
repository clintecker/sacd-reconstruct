#!/usr/bin/env python3
"""Decode `_mt8530fb_mmap`: the mmap CLASS dispatch, and what a pfn means here.

fb_mmap is called as fb_mmap(info, vma) (2.6.35 fb_ops has no struct file*).
The driver does NOT look at vm_pgoff to choose a class: it dispatches on the
LENGTH of the requested mapping, in this order:

  length == gu4GfxCmdBufLen          -> the gfx command ring     (mrc p15 walk / remap)
  length == 4096                     -> the DFB debug-info page  (_pcDfbDebugInfo)
  otherwise: idx = (length >> 12) & 0xF, VM_END -= idx*0x1000, then
       remap_pfn_range(vma, vm_start, pool.addr[idx] >> 12, pool.size[idx], prot)
                                       -> image memory pool slot idx (0..3)

This script prints every literal of the function with its value so the sizes
and the addresses above can be re-derived from the binary, plus the call sites
that do the remapping.

Usage:  fb_decode_mmap.py
"""
import fb_decode_common as C
import re

FN = "_mt8530fb_mmap"
LIT_RE = re.compile(r"pc,\s*#(-?(?:0x[0-9a-fA-F]+|\d+))")


def dec(tok):
    return int(tok, 16) if tok.lstrip("-").startswith("0x") else int(tok)


def main():
    mod = C.Module()
    rel = mod.reloc_map(".text")
    print(f"{FN} — literals and stores\n")
    for i in mod.func_insns(FN):
        m = LIT_RE.search(i.ops)
        note = ""
        if m and i.mn.startswith("ldr"):
            a = i.addr + 8 + dec(m.group(1))
            w = mod.data_word(".text", a)
            sym = rel.get(a)
            sname = sym[0][1] if sym else None
            val = ""
            if sname is None:
                val = f"{w:#010x}"
                if w in (0x4000, 0x1000, 4096, 0x40000000, 0x10000000):
                    val += "  (flag/size constant)"
            else:
                val = f"&{sname}"
            note = f"   ; lit {a:#09x} = {val}"
        if i.reloc and i.reloc.startswith(("CALL", "PC24", "THM")):
            note = f"   ; -> {i.reloc_sym}"
        print(f"  {i.addr:#09x} {i.mn:9s} {i.ops}{note}")


if __name__ == "__main__":
    main()
