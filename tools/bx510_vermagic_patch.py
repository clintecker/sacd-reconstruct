#!/usr/bin/env python3
"""bx510_vermagic_patch.py — byte-patch a .ko's vermagic string ARMv7->ARMv6
(same length, in place). The BX510 guest kernel reports ARMv6 vermagic while
our VM-built modules carry ARMv7; the module loader rejects on mismatch.
Known recipe (Run C2): replace the 6-char substring "ARMv7 " with "ARMv6 "
wherever it appears in the .modinfo/.vermagic content — verify count and
SHA before/after.

Usage: python3 bx510_vermagic_patch.py MODULE.ko [--check]
  --check: report occurrences only, no write.
"""
import argparse
import hashlib

OLD = b"ARMv7 "
NEW = b"ARMv6 "
assert len(OLD) == len(NEW)


def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('ko')
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    data = open(args.ko, 'rb').read()
    n = data.count(OLD)
    m = data.count(NEW)
    print(f"{args.ko}: sha256={sha(args.ko)}")
    print(f"  ARMv7 occurrences: {n}   ARMv6 occurrences: {m}   size: {len(data)}")
    if args.check or n == 0:
        if n == 0:
            print("  nothing to patch" + (" (already patched?)" if m else ""))
        return
    patched = data.replace(OLD, NEW)
    with open(args.ko, 'wb') as f:
        f.write(patched)
    print(f"  patched {n} occurrence(s); new sha256={sha(args.ko)}")


if __name__ == '__main__':
    main()
