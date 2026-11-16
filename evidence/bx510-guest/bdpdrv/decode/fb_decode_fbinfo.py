#!/usr/bin/env python3
"""Decode how bdpdrv builds its framebuffer: the fb_info field map.

The driver never references `_fb_info` directly in these functions. It loads
ONE `.bss` base -- `t_pal` at .bss+0x81d30 -- and reaches everything with
`[rBase, #imm]`:

    _fb_info       = .bss+0x82234 = t_pal + 0x504
    pseudo_palette = .bss+0x8247c = t_pal + 0x74c
    fbinfo (private struct)        = .bss+0x82190 = t_pal + 0x460

So an imm in `str rX,[r4,#imm]` decoded against t_pal tells you the exact
target field. This script prints that decoding for the three functions that
populate the surface (init_fbinfo / init / open), resolving each stored value
to its source instruction.

The fb_var_screeninfo / fb_fix_screeninfo field names are the Linux 2.6.35
uapi layouts, which are stable and not a guess: var starts at fb_info+0x20
(node/flags/lock/mm_lock precede it) and fix at fb_info+0xc0.

Usage:
  fb_decode_fbinfo.py                # all three functions
  fb_decode_fbinfo.py --fn _mt8530fb_open
"""
import argparse
import re

import fb_decode_common as C

# .bss anchors: symbol -> (offset, size), from the module's own symtab
BASE_SYM = "t_pal"
FB_INFO = ("_fb_info", 0x504, 0x248)
PSEUDO = ("pseudo_palette", 0x74c, 0x400)
FBINFO = ("fbinfo", 0x460, 0xa0)

VAR_FIELDS = {
    0x00: "var.xres", 0x04: "var.yres", 0x08: "var.xres_virtual",
    0x0c: "var.yres_virtual", 0x10: "var.xoffset", 0x14: "var.yoffset",
    0x18: "var.bits_per_pixel", 0x1c: "var.grayscale",
    0x20: "var.red.offset", 0x24: "var.red.length", 0x28: "var.red.msb_right",
    0x2c: "var.green.offset", 0x30: "var.green.length", 0x34: "var.green.msb_right",
    0x38: "var.blue.offset", 0x3c: "var.blue.length", 0x40: "var.blue.msb_right",
    0x44: "var.transp.offset", 0x48: "var.transp.length", 0x4c: "var.transp.msb_right",
    0x50: "var.nonstd", 0x54: "var.activate",
    0x58: "var.height", 0x5c: "var.width", 0x60: "var.accel_flags",
    0x64: "var.pixclock", 0x68: "var.left_margin", 0x6c: "var.right_margin",
    0x70: "var.upper_margin", 0x74: "var.lower_margin",
    0x78: "var.hsync_len", 0x7c: "var.vsync_len",
    0x80: "var.sync", 0x84: "var.vmode", 0x88: "var.rotate",
}
FIX_FIELDS = {
    0x00: "fix.id", 0x10: "fix.smem_start", 0x14: "fix.smem_len",
    0x18: "fix.type", 0x1c: "fix.type_aux", 0x20: "fix.visual",
    0x24: "fix.xpanstep", 0x26: "fix.ypanstep", 0x28: "fix.ywrapstep",
    0x2c: "fix.line_length", 0x30: "fix.mmio_start", 0x34: "fix.mmio_len",
    0x38: "fix.accel",
}
# fb_info scalars after fix (offsets are anchored by the two stores that name
# themselves: fbops <- &_mt8530fb_ops and pseudo_palette <- &pseudo_palette)
INFO_FIELDS = {
    0x04: "flags", 0x21c: "fbops", 0x22c: "screen_base",
    0x230: "screen_size", 0x234: "pseudo_palette",
}


def classify(imm):
    """(struct, field_name, relative_offset) for a t_pal-relative immediate."""
    for name, base, size in (FB_INFO, PSEUDO, FBINFO):
        if base <= imm < base + size:
            rel = imm - base
            if name == "_fb_info":
                if 0x20 <= rel < 0x20 + 160:
                    return name, VAR_FIELDS.get(rel - 0x20, f"var+{rel - 0x20:#x}"), rel
                if 0xc0 <= rel < 0xc0 + 0x44:
                    return name, FIX_FIELDS.get(rel - 0xc0, f"fix+{rel - 0xc0:#x}"), rel
                return name, INFO_FIELDS.get(rel, f"info+{rel:#x}"), rel
            return name, f"{name}+{rel:#x}", rel
    return None, None, imm


def decode(fn):
    mod = C.Module()
    insns = mod.func_insns(fn)
    if not insns:
        print(f"{fn}: not found")
        return
    rel = mod.reloc_map(".text")
    base_addr, _sz = mod.sym(BASE_SYM, ".bss")
    base_reg = None
    regs = {}
    print(f"\n=== {fn} ===")
    for i in insns:
        m = re.search(r"pc,\s*#(-?(?:0x[0-9a-fA-F]+|\d+))", i.ops)
        if i.mn.startswith("ldr") and m:
            off = m.group(1)
            off = int(off, 16) if off.lstrip("-").startswith("0x") else int(off)
            a = i.addr + 8 + off
            dest = i.ops.split(",")[0].strip()
            w = mod.data_word(".text", a)
            sym = rel.get(a)
            sname = sym[0][1] if sym else None
            if w == base_addr and sname == ".bss":
                base_reg = dest
                print(f"  {i.addr:#09x} base register {dest} = {sname} (.bss)")
            regs[dest] = (w, sname, i.addr)
            continue
        if i.mn.startswith("str") and base_reg and f"[{base_reg}" in i.ops:
            mm = re.search(r"\[" + base_reg + r",\s*#(0x[0-9a-fA-F]+|\d+)", i.ops)
            if not mm:
                continue
            imm = int(mm.group(1), 16) if mm.group(1).startswith("0x") else int(mm.group(1))
            width = "b" if i.mn == "strb" else ("h" if i.mn == "strh" else "")
            src = i.ops.split(",")[1].strip()
            struct, field, rel_off = classify(imm)
            prov = regs.get(src)
            pv = ""
            if prov:
                w, sname, addr = prov
                pv = f"  <- {src} from {addr:#09x}"
                if sname:
                    pv += f" ({sname})"
            print(f"  {i.addr:#09x} str{width:<1s} [{base_reg}+{imm:#05x}] "
                  f"{struct}.{field}  (rel {rel_off:#05x}){pv}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--fn")
    a = ap.parse_args()
    for fn in ([a.fn] if a.fn else
               ["_mt8530fb_init_fbinfo", "_mt8530fb_init", "_mt8530fb_open",
                "_mt8530fb_probe", "_mt8530fb_set_par"]):
        decode(fn)


if __name__ == "__main__":
    main()
