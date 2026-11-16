#!/usr/bin/env python3
"""bdpdrv init walk: call graph, per-function UART strings, per-function MMIO.

Everything here is read out of the module's own bytes; nothing is guessed from
objdump text or from the run logs (the logs are the *corroboration*, not the
source).

WHY RELOCATIONS ARE THE ONLY WAY TO GET THIS RIGHT
  bdpdrv is an ARM ET_REL. A `bl` target, a string pointer and a global pointer
  are all literal-pool/instruction fields filled by a relocation, and an
  SHT_REL relocation stores its addend IN THE SLOT, not in the relocation. A
  naive scan therefore sees `.word 0x0002ae2c` (which looks like an address
  literal) where the truth is `.rodata.str1.1 + 0` (a format string). This
  script joins slot word -> (symbol section + slot value) and prints the string.

OUTPUTS
  --tree ROOT          indented call tree with each function's format strings
  --funcs ROOT         every function reachable from ROOT
  --strings ROOT       func: format strings under ROOT
  --mmio-of ROOT       MMIO windows touched by reachable functions, from
                       /tmp/bdpdrv/all_access.txt (resolve_addrs.py --all;
                       that file is the dataflow-resolved literal+offset map --
                       this script only groups it by init stage)

Usage:
  python3 init_walk_graph.py --tree vDriverInit --depth 2
  python3 init_walk_graph.py --mmio-of i4IdeDrvInit
"""
import argparse
import os
from collections import defaultdict

from elftools.elf.elffile import ELFFile

KO = "/tmp/bdpdrv/bdpdrv.ko"
ACCESS_MAP = "/tmp/bdpdrv/all_access.txt"
CALLLIKE = {28, 29, 30}   # R_ARM_CALL, R_ARM_JUMP24, R_ARM_PC24
MOVE = 2                  # R_ARM_ABS32


class Module:
    def __init__(self, path=KO):
        self.f = open(path, "rb")
        self.e = ELFFile(self.f)
        self.secs = list(self.e.iter_sections())
        self.idx2name = {i: s.name for i, s in enumerate(self.secs)}
        self.syms = list(self.e.get_section_by_name(".symtab").iter_symbols())
        self.relocs = defaultdict(dict)
        for s in self.secs:
            if s["sh_type"] != "SHT_REL":
                continue
            for r in s.iter_relocations():
                sym = self.syms[r["r_info_sym"]]
                self.relocs[s["sh_info"]][r["r_offset"]] = (
                    sym.name, sym["st_value"], sym["st_shndx"], r["r_info_type"])
        self.funcs = {}
        self.ranges = defaultdict(list)
        for s in self.syms:
            if s["st_info"]["type"] == "STT_FUNC" and s.name and s["st_size"]:
                start = s["st_value"] & ~1
                sec = self.idx2name.get(s["st_shndx"])
                self.funcs[(sec, start)] = (s.name, start, s["st_size"])
                if sec:
                    self.ranges[sec].append((start, start + s["st_size"], s.name))
        for k in self.ranges:
            self.ranges[k].sort()
        self._data = {}

    def data(self, secname):
        if secname not in self._data:
            s = self.e.get_section_by_name(secname)
            self._data[secname] = s.data() if s else b""
        return self._data[secname]

    def cstr(self, secname, off):
        d = self.data(secname)
        if off >= len(d):
            return None
        end = d.find(b"\0", off)
        try:
            return d[off:end].decode("latin1")
        except UnicodeDecodeError:
            return None

    def owner(self, secname, off):
        """Function whose range holds `off`, else the nearest preceding one.

        Literal pools sit just after the last instruction of the function that
        uses them, i.e. outside the symbol's st_size; those are marked with a
        trailing '~' and folded back onto the function by the callers.
        """
        best = None
        for start, end, name in self.ranges.get(secname, []):
            if start <= off:
                best = (start, end, name)
            else:
                break
        if best is None:
            return None
        return best[2] + ("" if off < best[1] else "~")


def build(path=KO):
    mod = Module(path)
    sites = defaultdict(list)
    callees = defaultdict(set)
    strings = defaultdict(set)
    for secname in (".text", ".init.text"):
        idx = [i for i, s in enumerate(mod.secs) if s.name == secname][0]
        raw = mod.data(secname)
        for off, (symname, symval, symsec, typ) in sorted(mod.relocs[idx].items()):
            owner = mod.owner(secname, off)
            if not owner:
                continue
            caller = owner.rstrip("~")
            tgt = mod.idx2name.get(symsec)
            if typ in CALLLIKE or (typ == MOVE and tgt == ".text"):
                fn = mod.funcs.get((tgt, symval & ~1))
                if fn:
                    sites[caller].append((off, fn[0]))
                    callees[caller].add(fn[0])
                continue
            slot = int.from_bytes(raw[off:off + 4], "little") if off + 4 <= len(raw) else 0
            if typ == MOVE and tgt and tgt.startswith(".rodata"):
                st = mod.cstr(tgt, slot + symval)
                if st:
                    strings[caller].add(st)
    return mod, sites, callees, strings


MOD, SITES, CALLEES, STRINGS = build()


def reach(root, maxdepth=99):
    seen = {}

    def walk(f, d):
        if f in seen and seen[f] <= d:
            return
        seen[f] = d
        if d >= maxdepth:
            return
        for ch in sorted(CALLEES.get(f, ())):
            walk(ch, d + 1)
    walk(root, 0)
    return seen


def uart_strings(f):
    """Format strings that can reach the console (drop asserts/SourceFile names)."""
    out = []
    for s in sorted(STRINGS.get(f, ())):
        if s.endswith(".c") or s.startswith("src/"):
            continue
        out.append(s)
    return out


def print_tree(root, maxdepth):
    seen = set()

    def walk(f, d):
        dup = "   (already shown above)" if f in seen else ""
        seen.add(f)
        print("  " * d + f + dup)
        for s in uart_strings(f)[:6]:
            print("  " * d + "    | " + repr(s))
        if d >= maxdepth:
            return
        for _off, c in sorted(SITES.get(f, ())):
            walk(c, d + 1)
    walk(root, 0)


def mmio(root, maxdepth):
    if not os.path.exists(ACCESS_MAP):
        raise SystemExit(f"missing {ACCESS_MAP}: run `resolve_addrs.py --all > {ACCESS_MAP}`")
    per_fn = defaultdict(lambda: defaultdict(lambda: [0, set()]))
    for line in open(ACCESS_MAP):
        p = line.split()
        if len(p) < 7 or p[3] != "phys":
            continue
        fn = line.rsplit(None, 1)[-1]
        addr = int(p[4], 16)
        per_fn[fn][addr & ~0xFFFF][0] += 1
        per_fn[fn][addr & ~0xFFFF][1].add(addr)
    seen = reach(root, maxdepth)
    tot = defaultdict(lambda: [0, set(), set()])
    for f, win in per_fn.items():
        if f not in seen:
            continue
        for w, (n, addrs) in win.items():
            tot[w][0] += n
            tot[w][1] |= addrs
            tot[w][2].add(f)
    reach_mmio = sorted(f for f in per_fn if f in seen)
    print(f"root={root} reachable_functions={len(seen)} "
          f"functions_touching_mmio={len(reach_mmio)}")
    for w in sorted(tot):
        n, addrs, fns = tot[w]
        print(f"  0x{w:08x} accesses={n:5d} distinct={len(addrs):4d} "
              f"funcs={','.join(sorted(fns))}")
    print("--- per-function detail")
    for f in reach_mmio:
        d = ", ".join(f"0x{w:08x}({len(a)})" for w, (_n, a) in sorted(per_fn[f].items()))
        print(f"  {f}: {d}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree")
    ap.add_argument("--mmio-of")
    ap.add_argument("--depth", type=int, default=99)
    ap.add_argument("--funcs")
    ap.add_argument("--strings")
    a = ap.parse_args()
    if a.tree:
        print_tree(a.tree, a.depth)
    if a.mmio_of:
        mmio(a.mmio_of, a.depth)
    if a.funcs:
        for f, d in sorted(reach(a.funcs, a.depth).items(), key=lambda kv: (kv[1], kv[0])):
            print(f"{d}  {f}")
    if a.strings:
        for f in sorted(reach(a.strings, a.depth)):
            for s in uart_strings(f):
                print(f"{f}: {s!r}")


if __name__ == "__main__":
    main()
