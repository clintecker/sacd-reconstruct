#!/usr/bin/env python3
"""fn_diff.py — per-function disassembly parity between two ARM ELF32 binaries.

Normalizes away: addresses, register aliasing (fp==r11 etc), whitespace,
comment syntax (llvm "@" vs GNU ";"), raw-byte columns, pool-load offsets.

Branch targets: both llvm-objdump and GNU objdump print the absolute target
address. Targets inside the current function are rewritten to a function-
relative form (<in+0xNN>) because the same address can otherwise anchor to
different symbols in the two files (e.g. an absolute _binary_*_size symbol
whose value happens to fall inside the function range — the original's
ReadTableSegmentData straddles _binary_sacd_read_ko_size). Cross-function
targets keep their symbolic name.

Works with llvm-objdump and GNU objdump (OBJDUMP env or --objdump).

Usage: fn_diff.py ORIGINAL RECONSTRUCTED [--verbose] [--only NAME ...]
Exit 0 if all functions present in both match; prints a parity report.
"""
import argparse
import os
import re
import subprocess
import sys

DEFAULT_OBJDUMP = "/opt/homebrew/opt/llvm@22/bin/llvm-objdump"


def functions(path, objdump=None):
    """name -> list of normalized instruction lines"""
    objdump = objdump or os.environ.get("OBJDUMP", DEFAULT_OBJDUMP)
    out = subprocess.run(
        [objdump, "-d", "--no-show-raw-insn", path],
        capture_output=True, text=True, check=True).stdout
    fnre = re.compile(r"^([0-9a-f]+) <([^>]+)>:$")
    raw, order = {}, []
    cur = None
    for line in out.splitlines():
        m = fnre.match(line.strip())
        if m:
            cur = m.group(2)
            if cur not in raw:
                raw[cur] = []
                order.append(cur)
            continue
        if cur is None:
            continue
        # instruction line: "  1234: mnemonic operands  @ comment"
        im = re.match(r"^\s*([0-9a-f]+):\s+(.*)$", line)
        if im:
            raw[cur].append((int(im.group(1), 16), im.group(2)))
    # finalize with function ranges: a function spans [its first insn addr,
    # the next function's first insn addr)
    res = {}
    for i, name in enumerate(order):
        if not raw[name]:
            res[name] = []
            continue
        start = raw[name][0][0]
        end = raw[order[i + 1]][0][0] if i + 1 < len(order) else (1 << 30)
        res[name] = [normalize(text, start, end) for _, text in raw[name]]
    return res


BRANCH_RE = re.compile(
    r"((?:blx|bl|bx|b)(?:eq|ne|cs|hs|cc|lo|mi|pl|vs|vc|hi|ls|ge|lt|gt|le|al)?)"
    r"\s+(?:0x)?([0-9a-f]+)(?:\s+<([^>]+)>)?")


def normalize(insn, fn_start=None, fn_end=None):
    # collapse whitespace (GNU objdump separates fields with tabs)
    insn = re.sub(r"\s+", " ", insn).strip()
    # branches/calls first (before comment stripping eats "@plt>").
    m = BRANCH_RE.match(insn)
    if m:
        mnem, target_s, annot = m.group(1), m.group(2), m.group(3)
        try:
            target = int(target_s, 16)
        except ValueError:
            target = None
        if target is not None and fn_start is not None \
                and fn_start <= target < fn_end:
            insn = "%s <in+%#x>" % (mnem, target - fn_start)
        elif annot:
            # cross-function: keep the symbol, normalize its +off suffix
            sym = re.sub(r"\+0x[0-9a-f]+$", "", annot)
            insn = "%s <%s>" % (mnem, sym)
        else:
            insn = "%s <?>" % mnem
    # .word literal pool entries: keep only the symbolic form
    insn = re.sub(r"\.word\s+0x[0-9a-f]+\s+<([^>+]+?)(\+0x[0-9a-f]+)?>",
                  r".word <\1\2>", insn)
    insn = re.sub(r"\.word\s+0x[0-9a-f]+", ".word", insn)
    # raw-byte column printed for data-in-code lines: "f8 52 03 00  .word ..."
    insn = re.sub(r"^[0-9a-f]{2}( [0-9a-f]{2}){1,3}\s+\.word$", ".word", insn)
    # strip trailing comment (llvm: "@" annotations; GNU ARM: ";")
    insn = insn.split("@")[0].split(";")[0].strip()
    # normalize register aliases
    for a, b in [("fp", "r11"), ("sp", "r13"), ("lr", "r14"), ("pc", "r15"),
                 ("sl", "r10"), ("sb", "r9"), ("ip", "r12")]:
        insn = re.sub(r"\b%s\b" % a, b, insn)
    # pc-relative literal loads: drop the offset (pool placement is
    # layout-dependent); GNU prints decimal, llvm hex
    insn = re.sub(r"\[r15, #-?(?:0x[0-9a-fA-F]+|\d+)\]", "[r15]", insn)
    # undecodable spots (llvm "<unknown>", GNU "(bad)"): wildcard
    if insn.startswith("<unknown>") or insn.startswith("(bad)"):
        return "?"
    return insn


def strip_pad(insns):
    """Drop trailing zero-padding words (andeq r0,r0,r0 = 0x00000000) so
    symbol-size/padding differences don't count as mismatches."""
    while insns and re.sub(r"\s+", " ", insns[-1]).strip() == "andeq r0, r0, r0":
        insns = insns[:-1]
    return insns


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("original")
    ap.add_argument("reconstructed")
    ap.add_argument("--only", nargs="*", default=None)
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--objdump", default=os.environ.get(
        "OBJDUMP", DEFAULT_OBJDUMP))
    args = ap.parse_args()

    functions.objdump = args.objdump
    A = functions(args.original, args.objdump)
    B = functions(args.reconstructed, args.objdump)
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
            mismatch.append(n)
            continue
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
