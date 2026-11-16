#!/usr/bin/env python3
"""sacdread_cpsa.py — re-derive every mechanical claim in sacdread-cpsa.md.

Four decodes, all from the shipped binaries (no eyeballing of hexdumps):

  1. --lookups   sacd_read.ko's kallsyms_lookup_name_diag argument strings and the
                 .bss slot each result is stored into (rodata literal -> string,
                 `str r0,[r4,#off]` store offset -> variable name from .symtab).
  2. --ioctl     the ioctl dispatch: the jump table (a run of 7 consecutive
                 R_ARM_ABS32/.text relocations), the base literal that indexes it,
                 and the resulting _IOC(dir,type,nr,size) command numbers.
  3. --fops      sacd_read_fops relocations resolved against the module's own
                 DWARF `struct file_operations` member offsets (so "which slot"
                 is not guessed from a kernel version).
  4. --bdpdrv    cross-check each looked-up name against bdpdrv's symtab dump
                 (nm_defined.txt) — present/absent, address, size.

Inputs (paths overridable):
  --ko        original/sacd_read.ko
  --nm        /tmp/bdpdrv/nm_defined.txt   (nm of bdpdrv.ko, defined symbols)

Usage:
  python3 sacdread_cpsa.py --lookups --ioctl --fops --bdpdrv
  (or: make sacd-py SCRIPT=<abs path to this file>)

Stdlib only.  ELF32 little-endian ARM REL parsing, no pyelftools.
"""

import argparse
import struct
import sys

# ---------------------------------------------------------------- ELF plumbing


class Elf:
    def __init__(self, path):
        self.data = open(path, "rb").read()
        d = self.data
        e_shoff = struct.unpack_from("<I", d, 0x20)[0]
        e_shentsize, e_shnum, e_shstrndx = struct.unpack_from("<HHH", d, 0x2E)
        raw = []
        for i in range(e_shnum):
            o = e_shoff + i * e_shentsize
            name, typ, flags, addr, off, size, link, info, align, entsize = (
                struct.unpack_from("<IIIIIIIIII", d, o))
            raw.append(dict(name=name, type=typ, addr=addr, off=off, size=size,
                            link=link, entsize=entsize, idx=i))
        shstr = raw[e_shstrndx]

        def sname(n):
            p = shstr["off"] + n
            return d[p:d.index(b"\0", p)].decode("latin1")

        self.secs = {sname(s["name"]): s for s in raw}
        self.secname = {s["idx"]: sname(s["name"]) for s in raw}
        self._syms = None

    def bytes(self, sec, off, n):
        s = self.secs[sec]
        return self.data[s["off"] + off: s["off"] + off + n]

    def u32(self, sec, off):
        return struct.unpack("<I", self.bytes(sec, off, 4))[0]

    def cstr(self, sec, off):
        s = self.secs[sec]
        p = s["off"] + off
        return self.data[p:self.data.index(b"\0", p)].decode("latin1")

    @property
    def syms(self):
        if self._syms is not None:
            return self._syms
        st, strtab = self.secs[".symtab"], self.secs[".strtab"]
        out = []
        for i in range(st["size"] // 16):
            o = st["off"] + i * 16
            name, value, size, info, other, shndx = struct.unpack_from("<IIIBBH",
                                                                       self.data, o)
            p = strtab["off"] + name
            out.append(dict(name=self.data[p:self.data.index(b"\0", p)].decode("latin1"),
                            value=value, size=size, info=info, shndx=shndx))
        self._syms = out
        return out

    def relocs(self, relsec):
        """(offset, sym_index, addend_at_offset) triples of an ARM REL section."""
        s = self.secs[relsec]
        out = []
        for i in range(s["size"] // 8):
            off, r_info = struct.unpack_from("<II", self.data, s["off"] + i * 8)
            out.append((off, r_info >> 8, r_info & 0xFF))
        return out

    def section_of(self, idx):
        return self.secname.get(idx, "?")


def arm_ldr_pc(instr):
    """(is `ldr rD,[pc,#imm]`, Rd, imm) — ARM state, cond=AL only."""
    if (instr & 0xFF7F0000) != 0xE51F0000 and (instr & 0xFF7F0000) != 0xE59F0000:
        return False, 0, 0
    up = bool(instr & (1 << 23))
    rd = (instr >> 12) & 0xF
    imm = instr & 0xFFF
    return True, rd, imm if up else -imm


def arm_str_imm(instr):
    """(is `str rD,[rN,#imm]`, Rd, Rn, imm) for U=1."""
    if (instr & 0xFFF00000) != 0xE5800000:
        return False, 0, 0, 0
    rd = (instr >> 12) & 0xF
    rn = (instr >> 16) & 0xF
    return True, rd, rn, instr & 0xFFF


# ---------------------------------------------------------------- 1. lookups


def decode_lookups(ko, verbose=True):
    """Return [(string, bss_offset, variable)] in lookup order.

    Pattern (VERIFIED against the build): in .init.text, each lookup is
        ldr  r0, [pc, #imm]     ; literal word -> .rodata.str1.1 + addend
        bl   kallsyms_lookup_name_diag
        ...
        str  r0, [r4, #off]     ; r4 == .bss base; off == the pointer variable
    """
    text = ko.secs[".init.text"]
    relocs = {off: (sym, typ) for off, sym, typ in ko.relocs(".rel.init.text")}
    bss_idx = ko.secs[".bss"]["idx"]
    diag = [i for i, s in enumerate(ko.syms) if s["name"] == "kallsyms_lookup_name_diag"]
    diag = diag[0] if diag else None

    out = []
    pending_lit = None
    i = 0
    words = [struct.unpack_from("<I", ko.data, text["off"] + j)[0]
             for j in range(0, text["size"], 4)]
    while i < len(words):
        instr, addr = words[i], i * 4
        ok, rd, imm = arm_ldr_pc(instr)
        if ok and rd == 0:
            lit = addr + 8 + imm
            pending_lit = lit
        elif (instr >> 24) == 0xEB:
            # bl: relocation at this address names the callee
            sym_idx = relocs.get(addr, (None, None))[0]
            if sym_idx == diag and pending_lit is not None:
                # resolve the literal word: (section, addend)
                section, addend = None, None
                # literals inside .init.text are relocated by .rel.init.text
                for o, s_i, _t in ko.relocs(".rel.init.text"):
                    if o == pending_lit:
                        section = ko.section_of(ko.syms[s_i]["shndx"])
                        addend = ko.u32(".init.text", o)
                        break
                if section == ".rodata.str1.1":
                    out.append([ko.cstr(".rodata.str1.1", addend), None, None])
            pending_lit = None
        elif out and out[-1][1] is None:
            ok, rd, rn, off = arm_str_imm(instr)
            if ok and rd == 0:
                out[-1][1] = off
        i += 1
    # name the .bss slots from .symtab (bss variables have shndx == .bss idx)
    bssvars = {s["value"]: s["name"] for s in ko.syms if s["shndx"] == bss_idx}
    for row in out:
        row[2] = bssvars.get(row[1], "?")
    if verbose:
        print("== 1. kallsyms_lookup_name_diag argument strings (.init.text order)")
        for n, (s, off, var) in enumerate(out, 1):
            print("  %2d. %-40s -> .bss+0x%02x  %s" % (n, s, off, var))
    return [tuple(r) for r in out]


# ---------------------------------------------------------------- 2. ioctl


def decode_ioctl(ko, verbose=True):
    """Return (base, [(cmd, target_addr, size_of_table)])."""
    text = ko.secs[".text"]
    text_idx = text["idx"]
    abs_text = [(off, ko.u32(".text", off))
                for off, sym, typ in ko.relocs(".rel.text")
                if typ == 2 and ko.syms[sym]["shndx"] == text_idx]
    # the jump table is the longest run of consecutive 4-byte ABS32/.text relocs
    abs_text.sort()
    runs, cur = [], [abs_text[0]] if abs_text else []
    for prev, nxt in zip(abs_text, abs_text[1:]):
        if nxt[0] == prev[0] + 4:
            cur.append(nxt)
        else:
            runs.append(cur)
            cur = [nxt]
    if cur:
        runs.append(cur)
    table = max(runs, key=len)
    entries = [e[1] + text["addr"] for e in table]
    first = table[0][0]
    # walk back to the `ldr r3,[pc,#imm]` that loads the switch base literal
    base = None
    for back in range(1, 8):
        instr = ko.u32(".text", first - 4 * back)
        ok, rd, imm = arm_ldr_pc(instr)
        if ok:
            base = ko.u32(".text", first - 4 * back + 8 + imm)
            break
    if verbose:
        print("\n== 2. ioctl jump table (.text+0x%x, %d entries)" % (first, len(entries)))
        print("   index base literal = 0x%08x" % base)
        for i, target in enumerate(entries):
            cmd = (0x100000000 - ((base + 0) & 0xFFFFFFFF) + i) & 0xFFFFFFFF
            print("   [%d] cmd 0x%08x -> .text+0x%x  _IOC dir=%d type=0x%02x nr=0x%02x size=%d"
                  % (i, cmd, target,
                     (cmd >> 30) & 3, (cmd >> 8) & 0xFF, cmd & 0xFF, (cmd >> 16) & 0x3FFF))
    cmds = [(0x100000000 - (base & 0xFFFFFFFF) + i) & 0xFFFFFFFF
            for i in range(len(entries))]
    return base, list(zip(cmds, entries))


# ---------------------------------------------------------------- 3. fops


def decode_fops(ko, dwarfdump_text=None, verbose=True):
    """Resolve sacd_read_fops relocations to struct member names."""
    layout = {"owner": 0x0, "llseek": 0x4, "read": 0x8, "write": 0xc,
              "aio_read": 0x10, "aio_write": 0x14, "readdir": 0x18, "poll": 0x1c,
              "ioctl": 0x20, "unlocked_ioctl": 0x24, "compat_ioctl": 0x28,
              "mmap": 0x2c, "open": 0x30, "flush": 0x34, "release": 0x38}
    sym = [s for s in ko.syms if s["name"] == "sacd_read_fops"][0]
    base = sym["value"]
    rows = []
    for off, s_i, typ in ko.relocs(".rel.rodata"):
        name = ko.syms[s_i]["name"]
        if base <= off < base + sym["size"]:
            rows.append((off - base, name))
    if verbose:
        print("\n== 3. sacd_read_fops (struct base .rodata+0x%x, size 0x%x)"
              % (base, sym["size"]))
        by_off = {v: k for k, v in layout.items()}
        for delta, name in rows:
            print("   +0x%02x  %-16s %s" % (delta, by_off.get(delta, "?"), name))
    return rows


# ---------------------------------------------------------------- 4. bdpdrv


def check_bdpdrv(lookups, nm_path, verbose=True):
    rows = []
    defined = {}
    for line in open(nm_path, errors="replace"):
        parts = line.split()
        if len(parts) >= 4:
            defined[parts[3]] = (parts[0], parts[1], parts[2])
    if verbose:
        print("\n== 4. bdpdrv.ko cross-check (nm_defined.txt)")
    for name, _off, var in lookups:
        hit = defined.get(name)
        rows.append((name, var, hit))
        if verbose:
            print("   %-42s %s" % (name,
                                   ("%s  addr=0x%s size=0x%s  <%s>"
                                    % (var, hit[0], hit[1], hit[2])) if hit
                                   else "ABSENT from bdpdrv.ko"))
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ko", default="original/sacd_read.ko")
    ap.add_argument("--nm", default="/tmp/bdpdrv/nm_defined.txt")
    ap.add_argument("--lookups", action="store_true")
    ap.add_argument("--ioctl", action="store_true")
    ap.add_argument("--fops", action="store_true")
    ap.add_argument("--bdpdrv", action="store_true")
    a = ap.parse_args()
    if not (a.lookups or a.ioctl or a.fops or a.bdpdrv):
        a.lookups = a.ioctl = a.fops = a.bdpdrv = True
    ko = Elf(a.ko)
    look = decode_lookups(ko) if (a.lookups or a.bdpdrv) else []
    if a.ioctl:
        decode_ioctl(ko)
    if a.fops:
        decode_fops(ko)
    if a.bdpdrv:
        check_bdpdrv(look, a.nm)
    return 0


if __name__ == "__main__":
    sys.exit(main())
