#!/usr/bin/env python3
"""hud_guest_gate.py — PASS/FAIL gate for a HUD render run (guest or player).

A HUD run is only a pass if ALL of:
  1. the HUD process exited 0 (no SIGSEGV in the provider),
  2. it reported a primary surface and a successful first frame,
  3. the dumped framebuffer is not (nearly) black.

Usage: hud_guest_gate.py <log> [--min-lum 4] [--rc-pattern HR_HUD=]
Exit 0 = PASS, 1 = FAIL (with the reason), 2 = usage/parse error.
"""
import argparse
import re
import sys

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("log")
    ap.add_argument("--min-lum", type=float, default=4.0)
    ap.add_argument("--rc-pattern", default=r"HR_HUD=(\d+)")
    a = ap.parse_args()

    txt = open(a.log, encoding="utf-8", errors="replace").read()
    m = re.search(a.rc_pattern, txt)
    if not m:
        print("FAIL: no rc marker matched %r (run did not complete)" % a.rc_pattern)
        return 2
    rc = int(m.group(1))
    if rc != 0:
        print("FAIL: HUD rc=%d (139 = SIGSEGV in the provider)" % rc)
        return 1

    ok_evidence = ("SELFTEST: PASS" in txt or "HUD: panel" in txt
                   or "HUD: pool" in txt or "POOL-RENDER DONE" in txt)
    if not ok_evidence:
        print("FAIL: no surface/self-test/pool evidence in the log")
        return 1

    hm = re.search(r"FBPIX\s+([0-9a-fA-F]+)", txt)
    if not hm:
        print("FAIL: no FBPIX dump")
        return 1
    hx = hm.group(1)
    hx = hx[: (len(hx) // 3) * 3]
    step = max(3, (len(hx) // 3 // 20000) * 3)   # sample ~20k pixels
    total = n = 0
    for i in range(0, len(hx) - 5, step):
        chunk = hx[i:i + 6]
        if len(chunk) < 6:
            break
        r, g, b = int(chunk[0:2], 16), int(chunk[2:4], 16), int(chunk[4:6], 16)
        total += (r * 30 + g * 59 + b * 11) // 100
        n += 1
    lum = total / n if n else 0.0
    if lum < a.min_lum:
        print("FAIL: framebuffer is black (mean luminance %.2f < %.2f)" % (lum, a.min_lum))
        return 1
    print("PASS: rc=0, surface present, mean luminance %.2f" % lum)
    return 0

if __name__ == "__main__":
    sys.exit(main())
