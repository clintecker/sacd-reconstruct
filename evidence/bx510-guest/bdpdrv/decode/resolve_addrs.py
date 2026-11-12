#!/usr/bin/env python3
"""Resolve bdpdrv.ko's MMIO address expressions to concrete physical addresses.

bdpdrv is an ET_REL ARM module: it never stores a physical address in a literal
pool. It stores a *virtual* address -- the kernel's static IO mapping of the
AXI window at 0xfd000000.. -- then reaches registers as `[rBase, #imm]`,
frequently with a NEGATIVE immediate against a base pre-biased to a block's
last byte (pool word 0xfd039fff + `[r1, #-0xfff]` = 0xfd039000).

This script does the only thing that reliably recovers the mapping: a forward
register-value dataflow over the disassembly, per function, computing
literal + immediate for every load/store whose base register holds a constant.

virt -> phys is `v - 0x8d000000`, calibrated and cross-checked against the
Run C50 QEMU trace (`--calibrate`).

Two fidelity rules that matter:
  * A literal-pool slot covered by a relocation is NOT a constant (it is a
    zero in the file and a pointer after load). Those slots are treated as
    unknown, which is what keeps struct-field accesses out of the results.
  * Register constants are NOT cleared at branches (poll loops revisit the
    body with the base still live in a callee-saved register). At a call only
    the AAPCS caller-saved set (r0-r3, r12) is invalidated -- r4-r11 survive,
    and bdpdrv really does keep MMIO bases in r4/r5/r8 across `bl`.

Usage:
  resolve_addrs.py --calibrate            # re-derive the virt->phys delta
  resolve_addrs.py --reach 0x7002420c     # functions + instructions reaching it
  resolve_addrs.py --lo A --hi B          # all resolved accesses in a window
  resolve_addrs.py --func NAME            # all resolved accesses in one function
  resolve_addrs.py --all > accesses.txt   # full resolved access list
"""
import argparse
import bisect
import re
import subprocess
import sys

from elftools.elf.elffile import ELFFile

KO = "/tmp/bdpdrv/bdpdrv.ko"
OBJDUMP = "/opt/homebrew/opt/llvm/bin/llvm-objdump"
TRACE = ("/Users/clint/code/sacd-reconstruct/evidence/bx510-guest/"
         "bdpdrv/bdpdrv-runC50.mmio.log")
TEXT_SIZE = 0x31D81C
VIRT_BASE = 0xFD000000
PHYS_BASE = 0x70000000
DELTA = VIRT_BASE - PHYS_BASE  # 0x8d000000, verified by --calibrate

LINE_RE = re.compile(r"^\s*([0-9a-f]+):\s+(\S+)\s*(.*)$")
COMMENT_RE = re.compile(r"@\s*0x([0-9a-f]+)")
MEM_RE = re.compile(r"\[(\w+)(?:,\s*#?(-?0x[0-9a-f]+|-?\d+))?\]")
IMM_RE = re.compile(r"#(-?0x[0-9a-f]+|-?\d+)")

CALLER_SAVED = ("r0", "r1", "r2", "r3", "r12")
LOAD_FAMS = ("ldr", "ldrb", "ldrh", "ldrsb", "ldrsh", "ldrt", "ldrbt")
STORE_FAMS = ("str", "strb", "strh", "strt", "strbt")
FAMILIES = LOAD_FAMS + STORE_FAMS


def dec(tok):
    return int(tok, 16) if tok.lower().lstrip("-").startswith("0x") else int(tok)


class Module:
    def __init__(self, path=KO):
        self.fh = open(path, "rb")
        self.elf = ELFFile(self.fh)
        self.text = self.elf.get_section_by_name(".text").data()
        self.text_idx = next(i for i, s in enumerate(self.elf.iter_sections())
                             if s.name == ".text")
        self.relocs = self._text_relocs()
        self.funcs = self._load_functions()
        self.starts = [f[0] for f in self.funcs]

    def _text_relocs(self):
        sec = self.elf.get_section_by_name(".rel.text")
        return {r["r_offset"] for r in sec.iter_relocations()}

    def _load_functions(self):
        sym = self.elf.get_section_by_name(".symtab")
        out = []
        for s in sym.iter_symbols():
            if s["st_info"]["type"] != "STT_FUNC":
                continue
            if s["st_shndx"] != self.text_idx or not s.name or not s["st_size"]:
                continue
            start = s["st_value"] & ~1
            out.append((start, start + s["st_size"], s.name))
        out.sort()
        return out

    def word(self, addr):
        """Literal-pool word, or None when the slot is relocation-covered."""
        if not (0 <= addr <= TEXT_SIZE - 4):
            return None
        if addr in self.relocs:
            return None
        return int.from_bytes(self.text[addr:addr + 4], "little")

    def func_at(self, addr):
        i = bisect.bisect_right(self.starts, addr) - 1
        if i < 0:
            return None
        start, end, name = self.funcs[i]
        return name if addr < end else name + " (nearest-preceding)"


def disassemble(path=KO):
    p = subprocess.run([OBJDUMP, "-d", "--no-show-raw-insn", "-j", ".text", path],
                       capture_output=True, text=True)
    if p.returncode != 0:
        sys.exit("llvm-objdump failed: " + p.stderr)
    return p.stdout.splitlines()


def parse(lines):
    """[(addr, mnemonic, operand_text, comment_addr_or_None)]"""
    out = []
    for ln in lines:
        m = LINE_RE.match(ln)
        if not m:
            continue
        ops = m.group(3)
        cm = COMMENT_RE.search(ops)
        out.append((int(m.group(1), 16), m.group(2),
                    ops.split("@")[0].strip(),
                    int(cm.group(1), 16) if cm else None))
    return out


def family(mn):
    """(LOAD/STORE family, condition) or (None, None)."""
    for fam in FAMILIES:
        if mn == fam:
            return fam, ""
        if mn.startswith(fam) and len(mn) - len(fam) <= 2:
            return fam, mn[len(fam):]
    return None, None


def resolve_all(mod, insns):
    """Single forward pass; returns every load/store whose base resolves."""
    events = []
    regs = {}
    for addr, mn, ops, cmt in insns:
        fam, _cond = family(mn)
        parts = [p.strip() for p in ops.split(",")] if ops else []
        dest = parts[0] if parts else None

        # calls invalidate caller-saved registers only; branches none at all
        if mn.startswith(("bl", "blx", "bx")):
            for r in CALLER_SAVED:
                regs.pop(r, None)
            continue

        if fam in LOAD_FAMS and "pc" in ops:
            regs[dest] = mod.word(cmt) if cmt is not None else None
            continue

        if mn.startswith("movw") and len(parts) >= 2:
            imm = IMM_RE.search(parts[1])
            regs[dest] = dec(imm.group(1)) & 0xFFFF if imm and dest else None
            continue
        if mn.startswith("movt") and len(parts) >= 2:
            imm = IMM_RE.search(parts[1])
            regs[dest] = ((regs.get(dest) or 0) & 0xFFFF) | ((dec(imm.group(1)) & 0xFFFF) << 16) \
                if imm and dest in regs else None
            continue
        if mn.startswith("mov") and len(parts) >= 2 and dest:
            imm = IMM_RE.search(parts[1])
            if imm:
                regs[dest] = dec(imm.group(1))
            elif parts[1] in regs:
                regs[dest] = regs[parts[1]]
            else:
                regs[dest] = None
            continue
        if mn.startswith(("add", "sub", "orr", "and", "eor", "lsl", "lsr", "asr")):
            if len(parts) >= 3 and dest and regs.get(parts[1]) is not None:
                imm = IMM_RE.search(parts[2])
                if imm:
                    d = dec(imm.group(1))
                elif parts[2] in regs and regs[parts[2]] is not None:
                    d = regs[parts[2]]
                else:
                    regs[dest] = None
                    continue
                b = regs[parts[1]]
                if mn.startswith("sub"):
                    regs[dest] = b - d
                elif mn.startswith("add"):
                    regs[dest] = b + d
                elif mn.startswith("orr"):
                    regs[dest] = b | d
                elif mn.startswith("and"):
                    regs[dest] = b & d
                elif mn.startswith("eor"):
                    regs[dest] = b ^ d
                elif mn.startswith("lsl"):
                    regs[dest] = b << d
                elif mn.startswith("lsr"):
                    regs[dest] = b >> d
                elif mn.startswith("asr"):
                    regs[dest] = b >> d
            elif dest:
                regs[dest] = None
            continue

        if fam:
            m = MEM_RE.search(ops)
            is_read = fam in LOAD_FAMS
            if m:
                base_reg, off = m.group(1), (dec(m.group(2)) if m.group(2) else 0)
                if regs.get(base_reg) is not None:
                    target = (regs[base_reg] + off) & 0xFFFFFFFF
                    width = 1 if fam.endswith("b") else (2 if fam.endswith("h") else 4)
                    val = None
                    if not is_read and len(parts) >= 2:
                        src = parts[1]
                        if src.startswith("#"):
                            val = dec(src[1:])
                        elif src in regs:
                            val = regs[src]
                    phys = target - DELTA if (target & 0xFF000000) == VIRT_BASE else None
                    events.append((addr, "R" if is_read else "W", target, phys,
                                   width, val, mn, mod.func_at(addr)))
            if is_read and dest and dest.startswith("r"):
                regs[dest] = None
            continue

        if dest and dest.startswith("r"):
            regs[dest] = None
    return events


def calibrate(mod, insns):
    trace = set()
    for line in open(TRACE):
        m = re.search(r"0x([0-9a-f]+)", line)
        if m:
            trace.add(int(m.group(1), 16))
    lits = {mod.word(cmt) for _a, mn, ops, cmt in insns
            if cmt is not None and "pc" in ops and mod.word(cmt) is not None}
    lits = {v for v in lits if (v & 0xFF000000) == VIRT_BASE}
    print("distinct 0xfd literal words referenced by .text:", len(lits))
    print("distinct addresses in the Run C50 trace:", len(trace))
    for d in (0x8D000000, 0x8C000000, 0x8E000000, 0x8F000000, 0x88000000, 0x90000000):
        hits = [v - d for v in lits if (v - d) in trace]
        print(f"  delta {d:#010x}: {len(hits):4d} literal words land exactly on a traced address")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--calibrate", action="store_true")
    ap.add_argument("--reach", type=lambda s: int(s, 0))
    ap.add_argument("--func")
    ap.add_argument("--lo", type=lambda s: int(s, 0))
    ap.add_argument("--hi", type=lambda s: int(s, 0))
    ap.add_argument("--all", action="store_true")
    a = ap.parse_args()

    mod = Module()
    insns = parse(disassemble())

    if a.calibrate:
        calibrate(mod, insns)
        return

    events = resolve_all(mod, insns)
    lo, hi = a.lo, a.hi
    if a.reach is not None:
        lo, hi = a.reach, a.reach + 1

    for addr, kind, target, phys, width, val, mn, fname in events:
        if lo is not None and (phys is None or not (lo <= phys < hi)):
            continue
        if a.func and fname != a.func:
            continue
        if lo is None and not a.func and not a.all and phys is None:
            continue
        pv = f"phys {phys:#010x}" if phys is not None else "NOT-MMIO"
        vs = "" if val is None else f" = {val:#x}"
        print(f"0x{addr:07x} {kind}{width} {target:#010x} {pv}{vs}  {mn:9s} {fname}")


if __name__ == "__main__":
    main()
