#!/usr/bin/env python3
"""pool_audit.py — literal-pool parity, load-site by load-site.

For each function, resolve each `ldr rX, [pc, #imm]` to its pool word, then
classify the word and compare the ORIGINAL and REBUILD at that same load
site. fn_diff drops pool words to a bare `.word` (their value is either a
link-time address or a non-encodable scalar), so this tool owns the whole
pool-literal contract — including the two misreads that motivated it
(L"c" vs L"connected", issue #1; __FILE__ assert paths):

  * string object (narrow/wide/empty) -> decoded content, exact
  * function entry address            -> symbol identity, layout-free
  * one-past-a-section-end value      -> section identity (`_edata`)
  * other mapped object               -> masked content (structural)
  * value with no section behind it    -> scalar VALUE, exact

The identity classes matter: two functions with byte-identical bodies are
different objects, so a function-pointer swap must fail even though both
sides address "some .text address".

The embedded sacd_read.ko blob is not code to either tool (install_modules
writes it to /tmp and insmods it), so module parity is byte identity of the
blob — checked here as well: `module blob: identical|DIFFERS|absent`.

Full policy + the mutants that pin it: evidence/status-test/
fn-diff-literal-policy.md.

Usage: python3 tools/pool_audit.py original.elf rebuilt.elf [--only FN]
       python3 tools/pool_audit.py --module original.elf rebuilt.elf
"""
import argparse
import hashlib
import os
import re
import struct
import subprocess
import sys

OBJDUMP = os.environ.get(
    "OBJDUMP", "/opt/homebrew/opt/llvm@22/bin/llvm-objdump")


class ELF:
    def __init__(self, path):
        self.path = path
        self.data = open(path, "rb").read()
        self.sections = []  # (name, addr, offset, size)
        self.symbols = {}   # addr -> name
        self._read_sections()
        self._read_symbols()

    def _read_sections(self):
        out = subprocess.run(
            ["/opt/homebrew/opt/llvm@22/bin/llvm-readelf", "-S", self.path],
            capture_output=True, text=True).stdout
        for line in out.splitlines():
            m = re.match(
                r"\s*\[\s*\d+\]\s+(\S+)\s+(\S+)\s+([0-9a-f]+)\s+([0-9a-f]+)\s+([0-9a-f]+)",
                line)
            if m:
                name = m.group(1)
                addr = int(m.group(3), 16)
                off = int(m.group(4), 16)
                size = int(m.group(5), 16)
                self.sections.append((name, addr, off, size))

    def _read_symbols(self):
        out = subprocess.run(
            ["/opt/homebrew/opt/llvm@22/bin/llvm-readelf", "-s", self.path],
            capture_output=True, text=True).stdout
        self.symbols = {}
        self.symbol_sizes = {}  # (addr, size) -> name
        self.sym_by_name = {}   # name -> addr (first definition wins)
        self.func_starts = {}   # addr -> name, FUNC entry points
        self.section_ends = {}  # addr -> section name (one-past-end words)
        for line in out.splitlines():
            m = re.match(
                r"\s*\d+:\s+([0-9a-f]+)\s+(\d+)\s+(\S+)\s+(\S+)\s+\S+\s+\S+\s+(\S+)",
                line)
            if m:
                addr = int(m.group(1), 16)
                size = int(m.group(2))
                typ, name = m.group(3), m.group(5)
                if addr and name:
                    if addr not in self.symbols:
                        self.symbols[addr] = name
                    if size:
                        self.symbol_sizes[(addr, size)] = name
                    self.sym_by_name.setdefault(name, addr)
                    if typ == "FUNC" and size and not name.startswith("$"):
                        self.func_starts.setdefault(addr, name)
        for name, addr, _, size in self.sections:
            if addr and size:
                self.section_ends.setdefault(addr + size, name)

    def image_end(self):
        return max((a + s for _, a, _, s in self.sections), default=0)

    def va2off(self, va):
        for name, addr, off, size in self.sections:
            if addr != 0 and addr <= va < addr + size:
                if name in (".bss", ".sbss") or name.startswith(".bss"):
                    return -1, name  # NOBITS: content is zeros, no file bytes
                return off + (va - addr), name
        return None, None

    def read_word(self, va):
        off, sec = self.va2off(va)
        if off is None or off < 0:
            return None, sec
        return struct.unpack("<I", self.data[off:off + 4])[0], sec

    def read_bytes(self, va, n):
        off, sec = self.va2off(va)
        if off is None or off < 0:
            if off == -1:
                return b"\x00" * n  # .bss reads as zeros
            return None
        return self.data[off:off + n]

    def sym_at(self, va):
        """nearest symbol at or below va"""
        best = None
        for addr, name in self.symbols.items():
            if addr <= va and (best is None or addr > best[0]):
                best = (addr, name)
        if best is None:
            return None
        return best[1] + ("+0x%x" % (va - best[0]) if va != best[0] else "")

    def describe_word(self, word):
        """classify a resolved pool word -> layout-free comparable key

        Order is the policy (evidence/status-test/fn-diff-literal-policy.md):
        string content first (content is what a string literal IS), then
        identity (a function entry, a section boundary), then structural
        content, then the raw value for words that address nothing in this
        image.
        """
        if word is None:
            return "<unmapped>"
        k = self.content_key(word)
        # 1. string objects: the decoded content is authoritative
        if k is not None and (k == "empty-string" or k.startswith("ascii:")
                              or k.startswith("wide:")):
            return k
        # 2. code addresses: symbol identity, never "some address in .text".
        #    Only an exact function entry counts — a taken function address
        #    is always one, while a scalar constant can land inside .text by
        #    coincidence (0xffff, 0xfeff, 0xdfff do) and must not be read as
        #    an identity.
        if k == "code-ptr":
            return "code:%s" % self.func_starts[word] \
                if word in self.func_starts else "code-ptr"
        # 3. one-past-the-end values (`_edata`, `_binary_sacd_read_ko_end`):
        #    the address moves with the layout, the relation to the section
        #    end does not. Section-end identity is name- and order-free.
        if word in self.section_ends:
            return "secend:%s" % self.section_ends[word]
        if k is not None and k != "layout-ptr":
            return k
        # 4. inside the image range but behind no section: not a valid
        #    pointer in THIS image, so it is a scalar constant -> its value
        #    is the identity (catches a mutated module end/size literal that
        #    fn_diff drops with the rest of the pool)
        return "scalar:%#x" % word

    def embedded_module(self):
        """bytes of the module blob the daemon ships (ld -b binary / .incbin)."""
        start = self.sym_by_name.get("_binary_sacd_read_ko_start")
        end = self.sym_by_name.get("_binary_sacd_read_ko_end")
        if start is None or end is None or end < start:
            return None
        return self.read_bytes(start, end - start)

    def content_key(self, word):
        """Content-based comparison key for a pool word's target.

        - string targets: decoded string (catches wrong-literal bugs like
          L"c" vs L"connected")
        - other mapped targets: 32 bytes with plausible vaddr words masked
          out (layout-independent structural compare)
        - None when the word is not a mapped address
        """
        if word is None or not (0x1000 <= word < 0x8000000):
            return None
        off, sec = self.va2off(word)
        if off is None:
            if word < self.image_end():
                return "layout-ptr"
            return None
        # code-bearing sections (either binary may classify the same raw
        # value differently): uniformly layout-dependent
        if sec.startswith(".text") or sec.startswith(".plt"):
            return "code-ptr"
        b = self.read_bytes(word, 256)
        if b is None:
            return None
        if sec and (sec == ".bss" or sec.startswith(".bss")):
            # NOBITS: content is zeros by definition. Keep it apart from the
            # shared "" literal so a global-buffer pointer never aliases a
            # zero-length string constant (identity is unrecoverable here).
            return "bss-zero"
        if b[:4] == b"\x00\x00\x00\x00":
            return "empty-string"  # the shared "" literal (full word of NULs)
        # narrow (char) string: through the NUL terminator
        s = b.split(b"\x00")[0]
        if s and all(32 <= c < 127 or c in (10, 13, 9) for c in s) and len(s) >= 2:
            return "ascii:%r" % s.decode("ascii", "replace")
        # wide string: ARM EABI wchar_t is 4 bytes (UTF-32LE). Decode
        # through the 4-byte terminator, not a fixed window, so every
        # character of the string participates in the comparison.
        if len(b) >= 8 and b[1] == 0 and b[2] == 0 and b[3] == 0 and b[0] != 0:
            chars = []
            for i in range(0, len(b) - 3, 4):
                val = int.from_bytes(b[i:i + 4], "little")
                if val == 0:
                    break
                if not (32 <= val < 127 or val in (10, 13, 9)):
                    break
                chars.append(chr(val))
            if len(chars) >= 1:
                return "wide:%r" % "".join(chars)
        # at or inside a known symbol: compare the symbol's content
        # (masked), not a window that may straddle neighbors
        snap = self.containing_symbol(word)
        if snap is None:
            snap = self.symbol_at_start(word)
        if snap is not None:
            saddr, ssize = snap
            sb = self.read_bytes(saddr, min(ssize, 48))
            if sb is not None:
                masked = self.masked_bytes(sb)
                return "symcontent:%s" % masked.hex()
        return "content:%s:%s" % (sec, self.masked_bytes(b[:48]).hex())

    @staticmethod
    def masked_bytes(b):
        # structural compare with address words masked (sliding: interior
        # pointers may be unaligned relative to this window)
        masked = bytearray(b)
        for i in range(0, max(0, len(b) - 3)):
            w = int.from_bytes(b[i:i + 4], "little")
            if 0x8000 <= w < 0x100000:
                for j in range(i, min(i + 4, len(masked))):
                    masked[j] = 0x00
                masked[i:i + 4] = b"\xde\xad\x00\x00"[:4]
        return bytes(masked)

    def containing_symbol(self, va):
        """(addr, size) of a sized symbol strictly containing va."""
        best = None
        for (addr, size), name in self.symbol_sizes.items():
            if addr < va < addr + size:
                if best is None or addr > best[0]:
                    best = (addr, size)
        return best

    def symbol_at_start(self, va):
        """(addr, size) of a sized symbol starting exactly at va."""
        for (addr, size), name in self.symbol_sizes.items():
            if addr == va:
                return (addr, size)
        return None

    def functions(self):
        raise NotImplementedError

    def disasm_functions(self):
        """yield (fname, [(addr, text), ...]) for all defined FUNC symbols"""
        # symbol table FUNC entries
        out = subprocess.run(
            ["/opt/homebrew/opt/llvm@22/bin/llvm-readelf", "-s", self.path],
            capture_output=True, text=True).stdout
        funcs = []
        for line in out.splitlines():
            m = re.match(
                r"\s*\d+:\s+([0-9a-f]+)\s+(\d+)\s+(FUNC)\s+\S+\s+\S+\s+\S+\s+(\S+)", line)
            if m and int(m.group(2)) > 0:
                funcs.append((m.group(4), int(m.group(1), 16), int(m.group(2))))
        full = subprocess.run(
            [OBJDUMP, "-d", "--no-show-raw-insn", self.path],
            capture_output=True, text=True).stdout
        by_name = {}
        cur = None
        for line in full.splitlines():
            m = re.match(r"^([0-9a-f]+) <(\S+?)>:", line)
            if m:
                cur = m.group(2)
                by_name.setdefault(cur, [])
                continue
            if cur is not None:
                m2 = re.match(r"^\s*([0-9a-f]+):\s+(.+?)\s*(?:@ .*)?$", line)
                if m2 and not m2.group(2).startswith(".word"):
                    by_name[cur].append((int(m2.group(1), 16), m2.group(2).strip()))
        for name, addr, size in funcs:
            if name in by_name and by_name[name]:
                yield name, by_name[name]

    def pool_loads(self, fname, insns):
        """return list of (va, pool_addr, word, desc) for PC-relative ldr."""
        res = []
        for va, text in insns:
            m = re.match(r"ldr\s+(\w+), \[pc, #(\-?0x[0-9a-f]+|\d+)\]", text)
            if m:
                imm = int(m.group(2), 0)
                pool_va = va + 8 + imm
                word, sec = self.read_word(pool_va)
                res.append((va, pool_va, word))
        return res


def normalize_desc(desc):
    return desc


# Descriptions whose equality means "the same literal" regardless of where the
# linker put it: decoded string content, a function entry, a section boundary,
# a zero-initialised global. Everything else (`content:`, `symcontent:`,
# `scalar:`) is a layout-dependent reading of one raw VALUE.
IDENTITY_CLASSES = ("ascii:", "wide:", "empty-string", "bss-zero",
                    "code:", "secend:")


def site_failures(o, r, o_pools, r_pools):
    """Load sites whose literals are not the same literal.

    Returns (i, orig_word, orig_desc, rebuild_word, rebuild_desc) per failing
    site. Shared by the audit and by the regression mutants so the tests
    exercise the real comparison, not a copy of it.
    """
    fails = []
    for i, ((_, _, oword), (_, _, rword)) in enumerate(zip(o_pools, r_pools)):
        odesc = o.describe_word(oword)
        rdesc = r.describe_word(rword)
        if odesc == rdesc:
            continue
        if oword == rword:
            # Same raw value: only identity classes can contradict each other.
            # A data window that reads into link-order-dependent neighbours
            # (the documented benign .data-order class, DELTA.md), a scalar
            # constant that coincides with a .data address, and a value that is
            # inside a section in one layout but not the other are all one
            # value seen through two layouts.
            if odesc.startswith(IDENTITY_CLASSES) \
                    and rdesc.startswith(IDENTITY_CLASSES):
                fails.append((i, oword, odesc, rword, rdesc))
            continue
        fails.append((i, oword, odesc, rword, rdesc))
    return fails


def check_module_blob(o, r):
    """Byte identity of the embedded sacd_read.ko blob.

    Neither tool sees the module as code: the daemon embeds it as data
    (`ld -b binary` / `.incbin`) and install_modules writes the blob to /tmp
    and insmods it, so module parity IS blob parity. Returns (ok, line).
    """
    ob, rb = o.embedded_module(), r.embedded_module()
    if ob is None and rb is None:
        return True, "module blob: absent in both ELFs (not checked)"
    if ob is None or rb is None:
        return False, "module blob: DIFFERS — present in only one ELF"
    digest = hashlib.sha256(ob).hexdigest()
    if ob == rb:
        return True, "module blob: identical (%d B, sha256 %s)" % (
            len(ob), digest)
    diff = next((i for i, (x, y) in enumerate(zip(ob, rb)) if x != y), 0)
    return False, (
        "module blob: DIFFERS — orig %d B sha256 %s, rebuild %d B sha256 %s,"
        " first differing byte at blob offset %#x" %
        (len(ob), digest, len(rb), hashlib.sha256(rb).hexdigest(), diff))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("original")
    ap.add_argument("rebuilt")
    ap.add_argument("--only")
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--module", action="store_true",
                    help="only check the embedded module blob")
    args = ap.parse_args()

    o = ELF(args.original)
    r = ELF(args.rebuilt)

    ok, line = check_module_blob(o, r)
    if args.module:
        print(line)
        return 0 if ok else 1

    o_funcs = dict(o.disasm_functions())
    r_funcs = dict(r.disasm_functions())

    match = mismatch = missing = 0
    mismatches = []
    for name in o_funcs:
        if args.only and name != args.only:
            continue
        if name not in r_funcs:
            missing += 1
            continue
        o_pools = o.pool_loads(name, o_funcs[name])
        r_pools = r.pool_loads(name, r_funcs[name])
        if len(o_pools) != len(r_pools):
            mismatch += 1
            mismatches.append(name)
            print("MISMATCH(count) %s: orig %d pools, rebuild %d" %
                  (name, len(o_pools), len(r_pools)))
            continue
        # Compare literals AT THEIR LOAD SITES (per review): a swapped
        # pointer pair must fail even though the multiset is unchanged.
        site_fail = site_failures(o, r, o_pools, r_pools)
        if not site_fail:
            match += 1
            continue
        okeys = sorted(str(o.describe_word(w)) for _, _, w in o_pools)
        rkeys = sorted(str(r.describe_word(w)) for _, _, w in r_pools)
        kind = "ORDER" if okeys == rkeys else "CONTENT"
        mismatch += 1
        mismatches.append(name)
        if args.verbose:
            for (i, ow, od, rw, rd) in site_fail:
                print("  %s[%s] site %d: orig %#x -> %s | rebuild %#x -> %s" %
                      (name, kind, i, ow or 0, od, rw or 0, rd))
    print("pool audit: match %d  mismatch %d  missing %d" %
          (match, mismatch, missing))
    print(line)
    if mismatches:
        print("MISMATCH:", " ".join(mismatches))
    if mismatches or missing or not ok:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
