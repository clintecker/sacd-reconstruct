#!/usr/bin/env python3
"""bx510_ko_classify_matrix.py — run the symbol classifier across a directory
of .ko files and emit a matrix: for each symbol, which modules direct-call it,
deref-call it, or address it as data. Feeds OSAL stub export decisions: a
symbol that is direct-called in one module and deref-called in another needs
BOTH a function export and a function-pointer-variable export (the fnptr var
initialized with the function's address).

Usage: python3 bx510_ko_classify_matrix.py DIR/*.ko [--sym NAME ...]
Output: TSV lines sym<TAB>module<TAB>direct<N><TAB>abs32<N><TAB>deref<N>/<sites>
plus a summary block per symbol when --sym given.
"""
import argparse
import collections
import subprocess
import sys
import os

HERE = os.path.dirname(os.path.abspath(__file__))
CLASSIFY = os.path.join(HERE, 'bx510_ko_symbol_classify.py')


def classify_one(ko):
    """returns dict name -> (direct, abs32, deref, sites) for undefined syms"""
    out = subprocess.run([sys.executable, CLASSIFY, ko],
                         capture_output=True, text=True).stdout
    rows = {}
    for line in out.splitlines()[1:]:
        f = line.split()
        if len(f) < 6:
            continue
        name, direct, abs32, deref = f[0], int(f[1]), int(f[2]), f[3]
        d, s = deref.split('/')
        rows[name] = (direct, abs32, int(d), int(s))
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('kos', nargs='+')
    ap.add_argument('--sym', action='append')
    ap.add_argument('--tsv', action='store_true', help='machine TSV only')
    args = ap.parse_args()

    per_mod = {}
    for ko in args.kos:
        per_mod[os.path.basename(ko)] = classify_one(ko)

    allsyms = set()
    for rows in per_mod.values():
        allsyms.update(rows)
    if args.sym:
        allsyms = {s for s in allsyms if s in args.sym}

    # aggregate: symbol -> {kind: set(modules)}
    agg = collections.defaultdict(lambda: collections.defaultdict(set))
    for mod, rows in per_mod.items():
        for name, (d, a, der, sites) in rows.items():
            if name not in allsyms:
                continue
            if der > 0:
                agg[name]['deref'].add(mod)
            if d > 0:
                agg[name]['direct'].add(mod)
            if a > 0 and der == 0 and d == 0:
                agg[name]['data'].add(mod)

    if not args.tsv:
        print(f"{'symbol':40s} {'kind':10s} modules")
        for name in sorted(agg):
            for kind in ('deref', 'direct', 'data'):
                mods = agg[name].get(kind)
                if mods:
                    print(f"{name:40s} {kind:10s} {','.join(sorted(mods))}")
    else:
        for mod, rows in sorted(per_mod.items()):
            for name, (d, a, der, sites) in sorted(rows.items()):
                if name not in allsyms:
                    continue
                print(f"{name}\t{mod}\t{d}\t{a}\t{der}/{sites}")


if __name__ == '__main__':
    main()
