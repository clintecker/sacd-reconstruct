#!/usr/bin/env python3
"""fn_diff.py — per-function disassembly parity between two ARM ELF32 binaries.

Normalizes away: addresses, absolute call targets (kept as symbolic names),
register aliasing (fp==r11 etc), whitespace.

Usage: fn_diff.py ORIGINAL RECONSTRUCTED [--verbose] [--only NAME ...]
Exit 0 if all functions present in both match; prints a parity report.
"""
import argparse
import re
import subprocess
import sys

def functions(path):
    """name -> list of normalized instruction lines"""
    out = subprocess.run(
        ["/opt/homebrew/opt/llvm@22/bin/llvm-objdump", "-d", "--no-show-raw-insn", path],
        capture_output=True, text=True, check=True).stdout
    fnre = re.compile(r"^([0-9a-f]+) <([^>]+)>:$")
    cur, res = None, {}
    for line in out.splitlines():
        m = fnre.match(line.strip())
        if m:
            cur = m.group(2)
            res.setdefault(cur, [])
            continue
        if cur is None:
            continue
        # instruction line: "  1234: mnemonic operands  @ comment"
        im = re.match(r"^\s*[0-9a-f]+:\s+(.*)$", line)
        if im:
            res[cur].append(normalize(im.group(1)))
    return res

def normalize(insn):
    # branches/calls first (before comment stripping eats "@plt>"): keep symbolic target
    insn = re.sub(r"(b[a-z]{0,3}\s+)0x[0-9a-f]+ <([^>+]+?)(\+0x[0-9a-f]+)?>", r"\1<\2\3>", insn)
    # .word literal pool entries: keep only the symbolic form
    insn = re.sub(r"\.word\s+0x[0-9a-f]+\s+<([^>+]+?)(\+0x[0-9a-f]+)?>", r".word <\1\2>", insn)
    insn = re.sub(r"\.word\s+0x[0-9a-f]+", ".word", insn)
    # raw-byte column printed for data-in-code lines: "f8 52 03 00  .word ..."
    insn = re.sub(r"^[0-9a-f]{2}( [0-9a-f]{2}){1,3}\s+\.word$", ".word", insn)
    # strip trailing comment
    insn = insn.split("@")[0].strip()
    # normalize register aliases
    for a, b in [("fp", "r11"), ("sp", "r13"), ("lr", "r14"), ("pc", "r15"),
                 ("sl", "r10"), ("sb", "r9"), ("ip", "r12")]:
        insn = re.sub(r"\b%s\b" % a, b, insn)
    # pc-relative literal loads: drop the offset (pool placement is layout-dependent)
    insn = re.sub(r"\[r15, #0x[0-9a-fA-F]+\]", "[r15]", insn)
    # undecodable spots (llvm quirk on umull encodings from old libgcc): wildcard
    if insn.startswith("<unknown>"):
        return "?"
    return insn

def strip_pad(insns):
    """Drop trailing zero-padding words (andeq r0,r0,r0 = 0x00000000) so
    symbol-size/padding differences don't count as mismatches."""
    while insns and insns[-1] == "andeq	r0, r0, r0":
        insns = insns[:-1]
    return insns

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("original")
    ap.add_argument("reconstructed")
    ap.add_argument("--only", nargs="*", default=None)
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    A = functions(args.original)
    B = functions(args.reconstructed)
    only = set(args.only) if args.only else None

    skip_plt = re.compile(r"@plt$|^\.|^_init$|^_fini$")
    names = [n for n in A if not skip_plt.search(n)]
    if only:
        names = [n for n in names if n in only]
    match, mismatch, missing = [], [], []
    for n in names:
        if n not in B:
            missing.append(n)
            continue
        a, b = strip_pad(A[n]), strip_pad(B[n])
        if len(a) != len(b):
            mismatch.append(n); continue
        same = all(x == y or x == "?" or y == "?" for x, y in zip(a, b))
        if same:
            match.append(n)
        else:
            mismatch.append(n)
    print(f"match: {len(match)}  mismatch: {len(mismatch)}  missing-in-recon: {len(missing)}")
    if missing:
        print("MISSING:", " ".join(sorted(missing)))
    if mismatch:
        print("MISMATCH:", " ".join(sorted(mismatch)))
        if args.verbose:
            for n in sorted(mismatch):
                print(f"\n=== {n} ===")
                la, lb = strip_pad(A[n]), strip_pad(B[n])
                for i in range(max(len(la), len(lb))):
                    x = la[i] if i < len(la) else "<none>"
                    y = lb[i] if i < len(lb) else "<none>"
                    mark = " " if x == y else "*"
                    print(f"  {mark} O: {x}")
                    if x != y:
                        print(f"    R: {y}")
    return 0 if not (mismatch or missing) else 1

if __name__ == "__main__":
    sys.exit(main())
