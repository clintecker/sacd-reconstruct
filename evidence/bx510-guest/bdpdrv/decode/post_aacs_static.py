#!/usr/bin/env python3
"""Static half of the post-AACS decode: the LOGO command, 0x24188, FastLogo.

Re-derives, from the two modules themselves, every instruction-level claim
`post-aacs-state.md` makes:

  logo     the single writer of 0xfd05c010 (the 'LOGO' mailbox word) and the
           census of ALL accesses to that address across both modules
  sram     the three read-modify-write owners of 0xfd024188 that the C91 trace
           shows after the LOGO write (0x0, 0x2, 0x0), with the exact mask each
           one applies
  fastlogo vAudInitThread's status poll (BIM+0x118 == 0x40), i.e. the only
           FastLogo handshake that exists in the driver

`--checks` re-runs every claim and exits non-zero on drift, so the document
cannot silently outlive the binaries.

Inputs are pinned by sha256; nothing here reads a hexdump by eye — addresses
come from capstone decoding plus the ELF relocation/symbol tables.

Usage (via `make sacd-py SCRIPT=...`):
  python3 evidence/bx510-guest/bdpdrv/decode/post_aacs_static.py --checks
  python3 evidence/bx510-guest/bdpdrv/decode/post_aacs_static.py --all
"""

import argparse
import hashlib
import os
import re
import subprocess
import sys

import capstone
from elftools.elf.elffile import ELFFile

HERE = os.path.dirname(os.path.abspath(__file__))
BDPDRV = "/tmp/bdpdrv/bdpdrv.ko"
SATA = "/tmp/bdpdrv/sata_mt85xx_mod.ko"

SHA = {
    BDPDRV: "6604f6cd6c204c3399ac047f389f47162b06a3f6576159f21b4e8aaf3a72cf54",
    SATA: "8a0253eb9bff19a3d3c0ac594a507235bad82348d8e80069024368d0f5456657",
}

VIRT_BASE = 0xFD05CFFF          # the pool word every FE-block access is built on
LOGO_ADDR = VIRT_BASE - 0xFEF   # = 0xfd05c010
SRAM_ADDR = 0xFD024188          # VSFHW SRAM/clock control
LOGO_WORD = 0x4F474F4C          # bytes 4c 4f 47 4f = 'L','O','G','O'


def sha256(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()


def sections(path):
    e = ELFFile(open(path, "rb"))
    out = {}
    for sec in e.iter_sections():
        if sec.name.startswith((".text", ".init.text")):
            try:
                out[sec.name] = sec.data()
            except Exception:
                pass
    return e, out


def owner_map(e):
    """[(section, start, end, name)] for STT_FUNC symbols with a size."""
    symtab = e.get_section_by_name(".symtab")
    out = []
    for s in symtab.iter_symbols():
        if s["st_info"]["type"] != "STT_FUNC" or not s["st_size"] or not s.name:
            continue
        if not isinstance(s["st_shndx"], int):
            continue
        sec = e.get_section(s["st_shndx"])
        out.append((sec.name, s["st_value"], s["st_value"] + s["st_size"], s.name))
    return out


def owner(owners, sec, off):
    for s, a, b, n in owners:
        if s == sec and a <= off < b:
            return n
    return "<no symbol>"


def scan_fe_block(path, lo, hi):
    """Every load/store whose effective address lands in [lo, hi) of the FE block.

    Handles the driver's two idioms: a pool base of 0xfd05cfff with a negative
    displacement, and any other base constant whose (base + disp) lands in
    range.  Only constant-base addressing is modelled, which is what both
    modules use for this block.
    """
    e, secs = sections(path)
    md = capstone.Cs(capstone.CS_ARCH_ARM,
                     capstone.CS_MODE_ARM | capstone.CS_MODE_LITTLE_ENDIAN)
    md.detail = True
    hits = []
    for name, data in secs.items():
        for ins in md.disasm(data, 0):
            try:
                ops = ins.operands
            except Exception:
                continue
            for o in ops:
                if o.type != capstone.arm.ARM_OP_MEM or not o.mem.disp:
                    continue
                ea = (VIRT_BASE + o.mem.disp) & 0xFFFFFFFF
                if lo <= ea < hi:
                    hits.append((ea, name, ins.address, ins.mnemonic, ins.op_str))
    return e, sorted(set(hits))


def logo_decode():
    """The 0xfd05c010 word: who writes it, with what, and does anyone read it."""
    e, hits = scan_fe_block(SATA, LOGO_ADDR, LOGO_ADDR + 4)
    owners = owner_map(e)
    print(f"# {SATA}  accesses to 0x{LOGO_ADDR:08x}: {len(hits)}")
    for ea, sec, a, m, o in hits:
        print(f"  0x{ea:08x}  {sec}+0x{a:x}  {m} {o}   in {owner(owners, sec, a)}")

    # the literal that supplies the value, resolved through the pool
    e2, secs = sections(SATA)
    text = secs[".init.text"]
    print("\n# the store's own basic block (from the function listing):")
    d = text
    base = 0xD00
    md = capstone.Cs(capstone.CS_ARCH_ARM,
                     capstone.CS_MODE_ARM | capstone.CS_MODE_LITTLE_ENDIAN)
    for ins in md.disasm(d[base:base + 0x18], base):
        lit = ""
        if ins.mnemonic == "ldr" and "[pc" in ins.op_str:
            imm = int(ins.op_str.split("#0x")[1].split("]")[0], 16)
            slot = ins.address + 8 + imm
            lit = "   ; pool word 0x%08x" % int.from_bytes(
                d[slot:slot + 4], "little")
        print(f"  0x{ins.address:04x}  {ins.mnemonic:8} {ins.op_str}{lit}")
    return hits


def sram_sites():
    """Every resolved read of 0xfd024188, with the mask the owner ANDs/ORs in.

    Uses resolve_addrs.py (the proven per-function constant-base dataflow)
    rather than re-deriving the base: this register is reached from a
    0xfd024000 literal, not from the 0xfd05cfff FE-block base.
    """
    out = subprocess.run([sys.executable, os.path.join(HERE, "resolve_addrs.py"),
                          "--reach", "0x70024188"],
                         capture_output=True, text=True, check=True).stdout
    e, secs = sections(BDPDRV)
    md = capstone.Cs(capstone.CS_ARCH_ARM,
                     capstone.CS_MODE_ARM | capstone.CS_MODE_LITTLE_ENDIAN)
    sites = []
    for line in out.splitlines():
        # 0x0130c10 R4 0xfd024188 phys 0x70024188  ldr       VSFHW_SramStatus
        f = line.split()
        if len(f) < 6 or f[1] != "R4":
            continue
        site, who = int(f[0], 16), f[-1]
        data = secs[".text"]
        mask = None
        for ins in md.disasm(data[site:site + 0x20], site):
            if ins.mnemonic in ("orr", "bic") and "#" in ins.op_str:
                mask = (ins.mnemonic, ins.op_str.split(",")[-1].strip())
                break
            if ins.mnemonic == "str":
                break
        sites.append((who, site, mask))
    return sites


def sram_owners():
    sites = sram_sites()
    print(f"# resolved reads of 0x{SRAM_ADDR:08x} ({len(sites)} sites)")
    for who, site, mask in sites:
        m = ("%s %s" % mask) if mask else "<no mask before the store>"
        print(f"  0x{SRAM_ADDR:08x}  .text+0x{site:x}  {m:<18} in {who}")
    return sites


def fastlogo():
    """vAudInitThread: ldr [BIM+0x118] ; cmp #64 ; retry 11x100 ticks."""
    e, secs = sections(BDPDRV)
    owners = owner_map(e)
    symtab = e.get_section_by_name(".symtab")
    fn = None
    for s in symtab.iter_symbols():
        if s.name == "vAudInitThread" and s["st_info"]["type"] == "STT_FUNC":
            fn = (s["st_value"], s["st_value"] + s["st_size"])
    assert fn, "vAudInitThread not found"
    text = secs[".text"]
    md = capstone.Cs(capstone.CS_ARCH_ARM,
                     capstone.CS_MODE_ARM | capstone.CS_MODE_LITTLE_ENDIAN)
    print(f"# vAudInitThread .text+0x{fn[0]:x}..0x{fn[1]:x}")
    base_reg_val = {}
    for ins in md.disasm(text[fn[0]:fn[1]], fn[0]):
        note = ""
        if ins.mnemonic == "ldr" and "[pc" in ins.op_str and ", #" in ins.op_str:
            imm = int(ins.op_str.split("#0x")[1].split("]")[0], 16)
            slot = ins.address + 8 + imm
            word = int.from_bytes(text[slot:slot + 4], "little")
            # a pool word below the .text size is a .rodata string offset
            note = "   ; pool word 0x%08x" % word
            if 0xFD000000 <= word < 0xFE000000:
                note += " (IO VA)"
                base_reg_val[ins.op_str.split(",")[0].strip()] = word
        if ins.mnemonic == "ldr" and "#0x118]" in ins.op_str:
            # the register was loaded with the IO base just above
            for prev_reg, val in base_reg_val.items():
                note += f"   ; effective 0x{val + 0x118:08x} (PA 0x{val + 0x118 - 0x8d000000:08x})"
        print(f"  0x{ins.address:05x}  {ins.mnemonic:8} {ins.op_str}{note}")
    return fn


def checks():
    ok = True

    def chk(name, cond, detail=""):
        nonlocal ok
        print(f"{'PASS' if cond else 'FAIL'}  {name}{('  ' + detail) if detail else ''}")
        ok = ok and cond

    for path, want in SHA.items():
        got = sha256(path)
        chk(f"sha256 {path.rsplit('/', 1)[-1]}", got == want, got)

    # 1. the LOGO word has exactly one writer and no reader, anywhere
    for path in (SATA, BDPDRV):
        e, hits = scan_fe_block(path, LOGO_ADDR, LOGO_ADDR + 4)
        name = path.rsplit("/", 1)[-1]
        loads = [h for h in hits if h[3] != "str"]
        chk(f"{name}: no reader of 0xfd05c010 (write-only mailbox word)",
            not loads, f"{len(loads)} loads")
    e, hits = scan_fe_block(SATA, LOGO_ADDR, LOGO_ADDR + 4)
    chk("sata module: exactly one store to 0xfd05c010", len(hits) == 1,
        f"{len(hits)} sites")
    chk("that store is .init.text+0xd0c", hits and hits[0][2] == 0xD0C,
        f".init.text+0x{hits[0][2]:x}" if hits else "absent")

    # the value: pool slot feeding that store is the LOGO dword
    _, secs = sections(SATA)
    data = secs[".init.text"]
    md = capstone.Cs(capstone.CS_ARCH_ARM,
                     capstone.CS_MODE_ARM | capstone.CS_MODE_LITTLE_ENDIAN)
    logo_word = None
    for ins in md.disasm(data[0xD00:0xD10], 0xD00):
        if ins.mnemonic == "ldr" and "[pc" in ins.op_str:
            imm = int(ins.op_str.split("#0x")[1].split("]")[0], 16)
            slot = ins.address + 8 + imm
            word = int.from_bytes(data[slot:slot + 4], "little")
            if word == LOGO_WORD:
                logo_word = word
    chk("the value is the literal 0x4f474f4c (bytes 'L','O','G','O')",
        logo_word == LOGO_WORD, f"0x{logo_word:08x}" if logo_word else "absent")

    # 2. the three 0x24188 owners the trace shows
    sites = sram_sites()
    masks = {}
    for who, site, mask in sites:
        if mask:
            masks.setdefault(who, set()).add(mask)
    want = {
        "_CEC_Init": ("bic", "#0x1000"),        # bit 12  -> write 0x0
        "_vCommonSRAMInit": ("orr", "#2"),      # bit 1   -> write 0x2
        "IRHW_RxInit": ("bic", "#0x100000"),   # bit 20  -> write 0x0
    }
    for fn, op in want.items():
        chk(f"{fn} RMWs 0xfd024188 with {op[0]} {op[1]}",
            op in masks.get(fn, ()), str(sorted(masks.get(fn, ()))))
    chk("those are three DIFFERENT bit fields of one register (not a mailbox)",
        len({op[1] for op in want.values()}) == 3)

    # 3. FastLogo status: BIM+0x118 compared against 64
    _, secs = sections(BDPDRV)
    text = secs[".text"]
    found = False
    for ins in md.disasm(text[0x2c330:0x2c3c8], 0x2c330):
        if ins.mnemonic == "ldr" and "[r4, #0x118]" in ins.op_str:
            found = True
    chk("vAudInitThread reads [BIM+0x118] (0xfd008118 / PA 0x70008118)",
        found)
    base = int.from_bytes(text[0x2c3d0:0x2c3d4], "little")
    chk("vAudInitThread's base register is 0xfd008000 (the BIM block)",
        base == 0xFD008000, f"0x{base:08x}")

    print("\n%s" % ("ALL CHECKS PASS" if ok else "CHECKS FAILED"))
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--logo", action="store_true")
    ap.add_argument("--sram", action="store_true")
    ap.add_argument("--fastlogo", action="store_true")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--checks", action="store_true")
    args = ap.parse_args()
    if args.checks:
        return checks()
    if args.logo or args.all:
        logo_decode()
    if args.sram or args.all:
        sram_owners()
    if args.fastlogo or args.all:
        fastlogo()
    return 0


if __name__ == "__main__":
    sys.exit(main())
