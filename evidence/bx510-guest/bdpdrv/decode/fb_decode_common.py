#!/usr/bin/env python3
"""Shared ELF/disassembly access for the bdpdrv framebuffer-surface decode.

bdpdrv.ko is an ET_REL ARM relocatable module: every section has VMA 0, so
`llvm-nm` and `st_value` addresses are SECTION-RELATIVE. Two consequences the
callers rely on:

  * a symbol address must always be paired with its section name, and
  * code addresses are offsets into `.text` (or `.init.text`), which is what
    llvm-objdump prints too.

Call targets are recovered from the R_ARM_CALL/PC24/THM relocations that
llvm-objdump -dr emits on the line after each `bl`, not from the `bl 0x...`
operand -- in a relocatable object the operand is a placeholder for
cross-section calls.

Usage as a library only; each fb_decode_*.py is a thin report on top.
"""
import bisect
import re
import subprocess

from elftools.elf.elffile import ELFFile

KO = "/tmp/bdpdrv/bdpdrv.ko"
OBJDUMP = "/opt/homebrew/opt/llvm/bin/llvm-objdump"
EVID = "/Users/clint/code/sacd-reconstruct/evidence/bx510-guest/bdpdrv"

INSN_RE = re.compile(r"^\s*([0-9a-f]+):\s+(\S+)\s*(.*)$")
SYM_RE = re.compile(r"^([0-9a-f]{8}) <(.+)>:")
RELOC_RE = re.compile(r"^\s*([0-9a-f]+):\s+R_ARM_(\S+)\s+(\S+)")


class Insn:
    """One instruction, with the relocation that annotates it (if any)."""

    __slots__ = ("addr", "mn", "ops", "reloc", "reloc_sym", "section")

    def __init__(self, addr, mn, ops, section):
        self.addr = addr
        self.mn = mn
        self.ops = ops.split("@")[0].strip()
        self.reloc = None
        self.reloc_sym = None
        self.section = section

    def __repr__(self):
        r = f" reloc={self.reloc}:{self.reloc_sym}" if self.reloc else ""
        return f"{self.addr:#08x} [{self.section}] {self.mn} {self.ops}{r}"


class Module:
    def __init__(self, path=KO):
        self.fh = open(path, "rb")
        self.elf = ELFFile(self.fh)
        self.sections = {s.name: s for s in self.elf.iter_sections()}
        self.section_names = [s.name for s in self.elf.iter_sections()]
        self._symtab = self.elf.get_section_by_name(".symtab")
        self.insns = {}       # section -> [Insn] sorted by addr
        self._labels = {}     # section -> {addr: name}
        self.syms_by_section = {}
        self._load_symbols()
        self._load_disassembly()

    # ---- symbols -------------------------------------------------------
    def _load_symbols(self):
        for s in self._symtab.iter_symbols():
            if not isinstance(s["st_shndx"], int):
                continue
            sec = self.section_names[s["st_shndx"]]
            ent = (s["st_value"] & ~1, s["st_size"], s.name,
                   s["st_info"]["type"], s["st_info"]["bind"])
            self.syms_by_section.setdefault(sec, []).append(ent)
        for sec, lst in self.syms_by_section.items():
            lst.sort()

    def sym(self, name, section=".text"):
        for addr, size, nm, typ, bind in self.syms_by_section.get(section, []):
            if nm == name:
                return addr, size
        return None, None

    def func_at(self, section, addr):
        """(name, offset_into_function) for the STT_FUNC containing addr."""
        cands = [s for s in self.syms_by_section.get(section, [])
                 if s[3] == "STT_FUNC" and s[1]]
        starts = [c[0] for c in cands]
        i = bisect.bisect_right(starts, addr) - 1
        if i < 0:
            return None, None
        a, size, nm, _t, _b = cands[i]
        if addr < a + size:
            return nm, addr - a
        return None, None

    # ---- disassembly ---------------------------------------------------
    def _load_disassembly(self):
        p = subprocess.run(
            [OBJDUMP, "-dr", "--no-show-raw-insn",
             "-j", ".text", "-j", ".init.text", "-j", ".exit.text", KO],
            capture_output=True, text=True, check=True)
        cur_sec = None
        cur_label = None
        last = None
        for ln in p.stdout.splitlines():
            if ln.startswith("Disassembly of section "):
                cur_sec = ln.split()[-1].rstrip(":")
                self.insns.setdefault(cur_sec, [])
                self._labels.setdefault(cur_sec, {})
                continue
            m = SYM_RE.match(ln)
            if m:
                cur_label = m.group(2)
                self._labels.setdefault(cur_sec, {})[int(m.group(1), 16)] = cur_label
                last = None
                continue
            m = RELOC_RE.match(ln)
            if m and last is not None:
                last.reloc = m.group(2)
                last.reloc_sym = m.group(3)
                continue
            m = INSN_RE.match(ln)
            if m and cur_sec:
                last = Insn(int(m.group(1), 16), m.group(2), m.group(3), cur_sec)
                self.insns[cur_sec].append(last)

    def range(self, section, lo, hi):
        return [i for i in self.insns.get(section, []) if lo <= i.addr < hi]

    def func_insns(self, name, section=".text"):
        addr, size = self.sym(name, section)
        if addr is None:
            return []
        return self.range(section, addr, addr + size)

    def label(self, section, addr):
        return self._labels.get(section, {}).get(addr)

    def calls_from(self, name, section=".text"):
        """[(addr, callee_name)] for every relocated call inside a function."""
        return [(i.addr, i.reloc_sym) for i in self.func_insns(name, section)
                if i.reloc and i.reloc.startswith(("CALL", "PC24", "THM"))]

    def callers_of(self, target, section=".text"):
        """[(func, addr)] for every function whose body relocates a call to target."""
        out = []
        for i in self.insns.get(section, []):
            if i.reloc_sym == target and i.reloc.startswith(("CALL", "PC24", "THM")):
                fn, off = self.func_at(section, i.addr)
                out.append((fn, i.addr, off))
        return out

    # ---- data ----------------------------------------------------------
    def data_word(self, section, off):
        data = self.sections[section].data()
        return int.from_bytes(data[off:off + 4], "little")

    def reloc_map(self, section):
        """{offset: [(rtype, symname)]} for the REL section covering `section`."""
        rel = self.sections.get(".rel" + section)
        if rel is None:
            return {}
        out = {}
        for r in rel.iter_relocations():
            sy = self._symtab.get_symbol(r["r_info_sym"])
            # STT_SECTION symbols carry no name -- report the section they index,
            # which is what llvm-objdump prints and what callers match on.
            nm = sy.name
            if not nm and isinstance(sy["st_shndx"], int):
                nm = self.section_names[sy["st_shndx"]]
            out.setdefault(r["r_offset"], []).append((r["r_info_type"], nm))
        return out

    def strings(self):
        """(section, offset, text) for every printable run >= 4 chars."""
        out = []
        for name, s in self.sections.items():
            if s["sh_type"] != "SHT_PROGBITS":
                continue
            try:
                d = s.data()
            except Exception:
                continue
            for m in re.finditer(rb"[\x20-\x7e]{4,120}", d):
                out.append((name, m.start(), m.group().decode()))
        return out

    def str_at(self, section, off):
        """NUL-terminated string in section at offset."""
        d = self.sections[section].data()
        end = d.find(b"\0", off)
        return d[off:end].decode("latin-1") if end > off else ""

    def refs_to_string(self, text):
        """Every place in code that loads the ADDRESS of a string containing text.

        Works through the literal pools: a load whose literal-pool slot carries
        a relocation to .rodata/.rodata.str1.1 is a string reference; the string
        is read at that symbol's start, so callers match by SUBSTRING.
        """
        hits = []
        relstr = {}
        for sec in (".rodata", ".rodata.str1.1", ".rodata.str1.4"):
            for off, rl in self.reloc_map(sec).items():
                for _t, nm in rl:
                    tgt = self.sym(nm, ".rodata.str1.1") or self.sym(nm, ".rodata")
                    if tgt[0] is None:
                        continue
                    relstr[(sec, off)] = (nm, self.str_at(sec, off))
        # literal-pool slots in .text that point into a string section
        text_rel = self.reloc_map(".text")
        slot_to_str = {}
        for off, rl in text_rel.items():
            for _t, nm in rl:
                for sec in (".rodata", ".rodata.str1.1", ".rodata.str1.4"):
                    a, _sz = self.sym(nm, sec)
                    if a is None:
                        continue
                    sraw = self.str_at(sec, a)
                    if text in sraw:
                        slot_to_str.setdefault(off, []).append((nm, sraw))
                        break
        for i in self.insns.get(".text", []):
            m = re.search(r"pc,\s*#(-?\d+)", i.ops)
            if not m:
                continue
            lit = i.addr + 4 + _align4(int(m.group(1)))
            if lit in slot_to_str:
                hits.append((i.addr, slot_to_str[lit]))
        return hits


def _align4(v):
    """ARM pc-relative literal offset: pc is addr+8 (ARM) or +4 (thumb)."""
    return v


def dump(mod, section, lo, hi, out):
    """Pretty-print a disassembly range with function + reloc labels."""
    cur = None
    for i in mod.range(section, lo, hi):
        fn = mod.label(section, i.addr)
        if fn and fn != cur:
            out.append(f"\n{section} {i.addr:#010x} <{fn}>:")
            cur = fn
        rel = f"   ; {i.reloc} {i.reloc_sym}" if i.reloc else ""
        out.append(f"  {i.addr:#010x}: {i.mn:9s} {i.ops}{rel}")


def imm(ops, reg=None):
    """All #immediates in an operand string, as ints."""
    vals = []
    for m in re.finditer(r"#(-?0x[0-9a-fA-F]+|-?\d+)", ops):
        t = m.group(1)
        vals.append(int(t, 16) if t.lstrip("-").startswith("0x") else int(t))
    return vals


def mem_offset(ops):
    """(base_reg, offset) for an `[rN, #off]` operand, else (None, None)."""
    m = re.search(r"\[(\w+)(?:,\s*#?(-?(?:0x[0-9a-fA-F]+|\d+)))?", ops)
    if not m:
        return None, None
    off = m.group(2)
    if off is None:
        return m.group(1), 0
    return m.group(1), (int(off, 16) if off.lstrip("-").startswith("0x") else int(off))


if __name__ == "__main__":
    m = Module()
    print(f"sections: {len(m.sections)}  .text insns: {len(m.insns['.text'])}")
    for sec in (".init.text", ".exit.text"):
        print(f"{sec}: {len(m.insns.get(sec, []))} insns")
    print(f"symbols: {sum(len(v) for v in m.syms_by_section.values())}")
