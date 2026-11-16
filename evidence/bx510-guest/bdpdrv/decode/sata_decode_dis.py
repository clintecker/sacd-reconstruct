#!/usr/bin/env python3
"""Annotated disassembly of sata_mt85xx_mod.ko functions.

The module is ARM ET_REL: every function's string/global reference goes
through a literal pool slot (`ldr rN, [pc, #imm]  @ 0xADDR`). objdump shows
the slot ADDRESS but not its content, and the slot's meaning lives in the
relocation that covers it. Eyeballing slot addresses is how string-to-branch
mapping goes wrong, so this script does the join mechanically:

  slot word  --(R_ARM_ABS32 reloc)-->  target section + addend
                                     -> printable content of that target
  slot word  --(no reloc)---------->  literal constant (print in hex + as
                                      float if it looks like one)

Also resolves `mov rN, #imm` rotated-immediate encodings into the plain hex
the source would have written (ARM folds 0xc100 into a rotate form).

Usage:
  sata_decode_dis.py --func sata_mt85xx_init_int_ldr
  sata_decode_dis.py --sec .init.text --start 0x204 --stop 0x788
  sata_decode_dis.py --sec .text --start 0x484 --stop 0xadc
  sata_decode_dis.py --list                 # function ranges in the module
"""
import argparse
import re
import struct
import subprocess
import sys

from elftools.elf.elffile import ELFFile

KO = "/tmp/bdpdrv/sata_mt85xx_mod.ko"
OBJDUMP = "/opt/homebrew/opt/llvm/bin/llvm-objdump"

LINE_RE = re.compile(r"^\s*([0-9a-f]+):\s+(\S+)\s*(.*?)\s*$")
PCREL_RE = re.compile(r"ldr\w*\s+(r\d+|r12|lr),\s*\[pc,\s*#(-?0x[0-9a-f]+|-?\d+)\]")
POOL_ADDR_RE = re.compile(r"@\s*0x([0-9a-f]+)")
MOVIMM_RE = re.compile(r"movw?\s+(r\d+|r12|lr|ip),\s*#(\d+|0x[0-9a-f]+)")
TARGET_RE = re.compile(r"@\s*0x([0-9a-f]+)\s*<([^>]*)>")


class Mod:
    def __init__(self, path=KO):
        self.fh = open(path, "rb")
        self.elf = ELFFile(self.fh)
        self.secs = {}
        for i, s in enumerate(self.elf.iter_sections()):
            self.secs[i] = s
        # map section name -> (index, data)
        self.byname = {}
        self.index = {}
        for i, s in enumerate(self.elf.iter_sections()):
            self.byname[s.name] = s
            self.index[s.name] = i
        # relocations keyed by (target_section_index, r_offset)
        self.symtab = self.elf.get_section_by_name(".symtab")
        self.symbols = list(self.symtab.iter_symbols())
        self.relocs = {}
        for s in self.elf.iter_sections():
            if s["sh_type"] not in ("SHT_REL", "SHT_RELA"):
                continue
            tgt = s["sh_info"]
            for r in s.iter_relocations():
                sym = self.symbols[r["r_info_sym"]]
                self.relocs[(tgt, r["r_offset"])] = (sym, r)

    def func_by_name(self, name):
        for s in self.symbols:
            if s.name == name and s["st_info"]["type"] == "STT_FUNC":
                return self.secs[s["st_shndx"]].name, s["st_value"], s["st_size"]
        return None

    def read_word(self, secname, off):
        s = self.byname.get(secname)
        if s is None:
            return None
        d = s.data()
        if off + 4 > len(d):
            return None
        return struct.unpack_from("<I", d, off)[0]

    def printable_at(self, secname, off, maxlen=120):
        s = self.byname.get(secname)
        if s is None:
            return None
        d = s.data()
        if off >= len(d):
            return None
        end = d.find(b"\x00", off, off + maxlen)
        if end < 0:
            end = min(off + maxlen, len(d))
        raw = d[off:end]
        if len(raw) >= 3 and all(0x20 <= b <= 0x7E for b in raw):
            return raw.decode()
        return None

    def resolve_pool(self, secname, pool_off):
        """Return (kind, text) for a literal-pool slot."""
        si = self.index.get(secname)
        rel = self.relocs.get((si, pool_off))
        if rel is not None:
            sym, r = rel
            # Section symbol: target = section + addend. Named symbol in a data
            # section: target = symbol value (+ addend on RELA).
            if not isinstance(sym["st_shndx"], int):
                return "rel", (str(sym["st_shndx"]), 0, sym.name, None)
            tsec = self.secs[sym["st_shndx"]].name
            addend = r["r_addend"] if r.entry.get("r_addend") is not None else 0
            symname = sym.name or tsec
            # For a section symbol the addend is in the word itself (REL).
            word = self.read_word(secname, pool_off) or 0
            if sym["st_info"]["type"] == "STT_SECTION" or sym.name == "":
                target_off = word + addend
                txt = self.printable_at(tsec, target_off)
                return "rel", (tsec, target_off, symname, txt)
            target_off = sym["st_value"] + addend
            txt = self.printable_at(tsec, target_off)
            return "rel", (tsec, target_off, symname, txt)
        w = self.read_word(secname, pool_off)
        if w is None:
            return "unknown", None
        fl = struct.unpack("<f", struct.pack("<I", w))[0]
        return "const", (w, fl)


def dis(mod, secname, start, stop):
    cmd = [OBJDUMP, "-d", "-r", "--no-show-raw-insn",
           f"--section={secname}", f"--start-address={start:#x}",
           f"--stop-address={stop:#x}", KO]
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=120).stdout
    return out.splitlines()


def annotate(mod, lines, secname):
    for ln in lines:
        m = LINE_RE.match(ln)
        if m:
            addr = int(m.group(1), 16)
            mn = m.group(2)
            rest = m.group(3)
            note = ""
            pm = POOL_ADDR_RE.search(rest)
            if pm and PCREL_RE.search(ln):
                pool = int(pm.group(1), 16)
                kind, val = mod.resolve_pool(secname, pool)
                if kind == "rel":
                    tsec, toff, symname, txt = val
                    note = f"  ; POOL[{pool:#x}] -> {tsec}+{toff:#x}"
                    if txt:
                        note += f'  "{txt}"'
                    note += f"  ({symname})"
                elif kind == "const":
                    w, fl = val
                    note = f"  ; POOL[{pool:#x}] = {w:#010x} ({w})"
                    if 1e-30 < abs(fl) < 1e30:
                        note += f" float={fl:.6g}"
            else:
                mm = MOVIMM_RE.search(rest)
                if mm:
                    note = f"  ; imm = {int(mm.group(2), 0):#x}"
                else:
                    tm = TARGET_RE.search(rest)
                    if tm:
                        note = f"  ; -> {tm.group(2)}"
            print(f"{addr:08x}  {mn:<10s} {rest}{note}")
        else:
            # relocation lines and labels pass through
            print(ln)
            continue


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ko", default=KO)
    ap.add_argument("--func")
    ap.add_argument("--sec")
    ap.add_argument("--start", type=lambda x: int(x, 0))
    ap.add_argument("--stop", type=lambda x: int(x, 0))
    ap.add_argument("--list", action="store_true")
    a = ap.parse_args()
    mod = Mod(a.ko)
    if a.list:
        for s in mod.elf.get_section_by_name(".symtab").iter_symbols():
            if s["st_info"]["type"] == "STT_FUNC" and s["st_size"]:
                print(f"{mod.secs[s['st_shndx']].name:16s} "
                      f"{s['st_value']:#08x} +{s['st_size']:#07x} {s.name}")
        return
    if a.func:
        got = mod.func_by_name(a.func)
        if not got:
            sys.exit(f"no such function: {a.func}")
        secname, v, sz = got
        start, stop = v, v + sz
    else:
        secname, start, stop = a.sec, a.start, a.stop
    lines = dis(mod, secname, start, stop)
    annotate(mod, lines, secname)


if __name__ == "__main__":
    main()
