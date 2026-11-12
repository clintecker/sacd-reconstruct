#!/usr/bin/env python3
"""Inventory the userspace surface bdpdrv.ko creates: chardevs, notifiers, threads.

Two evidence sources, both static:

  * `cdev_init`/`cdev_add`/`cdev_del` and `device_register_proprietary`
    call sites -- the only ways this module can create a /dev node -- with the
    owning function named;
  * for each such owner, every string it references (string literals come from
    literal-pool words whose relocation target is a string section, so the
    pool word IS the offset within that section -- for an ET_REL object the
    addend is implicit).

`x_thread_create` call sites mark the kernel threads (the surface that keeps
running after i4IdeDrvBootup returns).

Usage:
  fb_decode_chardev.py            # full inventory
  fb_decode_chardev.py --fn NAME  # one function's calls + strings
"""
import argparse
import re

import fb_decode_common as C

STR_SECS = (".rodata.str1.1", ".rodata.str1.4", ".rodata")
CREATE = ("cdev_init", "cdev_add", "device_register_proprietary",
          "misc_register", "register_chrdev")
CALLTYPES = ("CALL", "PC24", "THM")
LIT_RE = re.compile(r"pc,\s*#(-?(?:0x[0-9a-fA-F]+|\d+))")

_MOD = None


def module():
    global _MOD
    if _MOD is None:
        _MOD = C.Module()
    return _MOD


def dec(tok):
    return int(tok, 16) if tok.lstrip("-").startswith("0x") else int(tok)


def strref(mod, i):
    """String literal loaded by an `ldr rX,[pc,#n]` whose pool slot is relocated
    into a string section (ET_REL: the pool word carries the section offset)."""
    m = LIT_RE.search(i.ops)
    if not m:
        return None
    a = i.addr + 8 + dec(m.group(1))
    text = mod.sections[".text"].data()
    if not (0 <= a <= len(text) - 4):
        return None
    w = mod.data_word(".text", a)
    # the relocation on the pool slot names the section it points into
    rl = mod.reloc_map(".text").get(a) or []
    for _t, sec in rl:
        if sec in STR_SECS:
            try:
                s = mod.str_at(sec, w)
            except Exception:
                return None
            if s and s.isprintable():
                return s
    return None


def report(fn, section=".text"):
    mod = module()
    print(f"=== {fn} ===")
    if not mod.func_insns(fn, section):
        print("  (not found)")
        return
    for i in mod.func_insns(fn, section):
        if i.reloc and i.reloc.startswith(CALLTYPES):
            print(f"  call {i.reloc_sym}")
        s = strref(mod, i)
        if s and len(s) > 2:
            print(f"    str {s!r}")


def surface():
    mod = module()
    print("## chardev / device creators and their callers\n")
    for tgt in CREATE:
        sites = mod.callers_of(tgt)
        if not sites:
            continue
        print(f"{tgt}:")
        for fn, addr, off in sites:
            print(f"  {addr:#010x}  in {fn}+{off:#x}" if fn else f"  {addr:#010x}")
        print()
    print("## threads created by the module (x_thread_create call sites)\n")
    for fn, addr, off in mod.callers_of("x_thread_create"):
        print(f"  {addr:#010x}  in {fn}+{off:#x}" if fn else f"  {addr:#010x}")
    for sec in (".init.text",):
        for fn, addr, off in mod.callers_of("x_thread_create", sec):
            print(f"  {sec} {addr:#010x}  in {fn}+{off:#x}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--fn")
    a = ap.parse_args()
    if a.fn:
        report(a.fn)
        return
    surface()


if __name__ == "__main__":
    main()
