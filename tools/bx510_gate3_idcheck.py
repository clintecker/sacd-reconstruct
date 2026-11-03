#!/usr/bin/env python3
"""bx510_gate3_idcheck.py — per-boot C-vs-PY byte-identity check.

In the HDHOST rig every boot builds the C fixture in the guest tmpfs
(/res/dev/sr0, written by bx510_mkfixture) AND serves the PY-generated
host image through the block node (/res/dev/hdhost, written by
fixture_gen.py, transported by HDHOST). The probe reads the same
sectors from both nodes; this tool requires every sr0/hdhost md5 pair
in the P0_HDID block to agree. Agreement proves three things at once:
the C and PY generators agree, HDHOST transports the host bytes
faithfully, and the guest block node serves them faithfully.

Usage: bx510_gate3_idcheck.py LOG   (exit 0 = identity holds)
"""
import re
import sys

MD5 = re.compile(r"^([0-9a-f]{32})  -")


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    log = open(sys.argv[1], errors="replace").read()
    m = re.search(r"P0_HDID_BEGIN(.*?)P0_HDID_END", log, re.S)
    if not m:
        print(f"{sys.argv[1]}: no P0_HDID block (not an HDHOST rig boot?)")
        return 1
    hashes = [x.group(1) for x in re.finditer(MD5, m.group(1), re.M)]
    if len(hashes) % 2 or not hashes:
        print(f"{sys.argv[1]}: P0_HDID block malformed "
              f"({len(hashes)} md5 lines, want even > 0)")
        return 1
    lsns = ["510 (master TOC)", "0", "43100", "80000+80001 (encrypted x2)"]
    ok = True
    for i in range(0, len(hashes), 2):
        c, p = hashes[i], hashes[i + 1]
        label = lsns[i // 2] if i // 2 < len(lsns) else f"pair {i // 2}"
        same = c == p
        ok = ok and same
        print(f"  {'OK ' if same else 'BAD'} sector {label}: "
              f"C {c} PY {p}")
    print(f"{sys.argv[1]}: byte-identity " + ("holds" if ok else "FAILS"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
