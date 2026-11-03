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

MD5 = re.compile(r"^([0-9a-f]{32})  -", re.M)


def big_expectations():
    """5 GiB battery: sentinel md5s computed from the generators —
    the guest's dd through HDHOST must return exactly these."""
    import hashlib
    from pathlib import Path
    import sys
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from bx510_gate_check import synthetic_sector
    import fixture_gen
    e = [
        ("510 (master TOC)", hashlib.md5(fixture_gen.master_toc_sector()).hexdigest()),
        ("1048575+1048576 (2GiB pair)",
         hashlib.md5(synthetic_sector(1048575) + synthetic_sector(1048576)).hexdigest()),
        ("2097151+2097152 (4GiB pair)",
         hashlib.md5(synthetic_sector(2097151) + synthetic_sector(2097152)).hexdigest()),
        ("2621439 (final)", hashlib.md5(synthetic_sector(2621439)).hexdigest()),
    ]
    return e


def check_big(logfile, corrupt=False):
    log = open(logfile, errors="replace").read()
    m = re.search(r"P0_HDBIG_BEGIN(.*?)P0_HDBIG_END", log, re.S)
    if not m:
        print(f"{logfile}: no P0_HDBIG block (not a --big boot?)")
        return 1
    got = [x.group(1) for x in MD5.finditer(m.group(1))]
    want = big_expectations()
    if corrupt:
        # negative-control image: the SACDMTOC magic is destroyed by
        # design (8x0xAA at sector 510 offset 0); every other sentinel
        # must still hold — the transport is intact even when the
        # disc is invalid.
        import hashlib
        import fixture_gen
        toc = bytearray(fixture_gen.master_toc_sector())
        toc[0:8] = b"\xAA" * 8
        want[0] = ("510 (corrupted master TOC)",
                   hashlib.md5(bytes(toc)).hexdigest())
    if len(got) != len(want):
        print(f"{logfile}: P0_HDBIG malformed ({len(got)} md5s, want {len(want)})")
        return 1
    ok = True
    for (label, w), g in zip(want, got):
        same = w == g
        ok = ok and same
        print(f"  {'OK ' if same else 'BAD'} {label}: want {w} got {g}")
    print(f"{logfile}: 5GiB sentinel identity " + ("holds" if ok else "FAILS"))
    return 0 if ok else 1


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "--big":
        return check_big(sys.argv[2])
    if len(sys.argv) == 3 and sys.argv[1] == "--big-corrupt":
        return check_big(sys.argv[2], corrupt=True)
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    log = open(sys.argv[1], errors="replace").read()
    m = re.search(r"P0_HDID_BEGIN(.*?)P0_HDID_END", log, re.S)
    if not m:
        print(f"{sys.argv[1]}: no P0_HDID block (not an HDHOST rig boot?)")
        return 1
    hashes = [x.group(1) for x in MD5.finditer(m.group(1))]
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
