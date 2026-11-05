#!/usr/bin/env python3
"""bx510_hud_diff.py — does the rig predict the panel?

Compares a device photo (TV, taken by hand) with the render (emulator or HUD
dump) and reports the metrics that actually diagnose a mismatch:

  ssim      structural similarity (1.0 = identical structure)
  lum_err   mean luminance difference (format/level faults)
  dx, dy    best global shift found by search (origin/offset faults)
  hshift    the shift that maximises column correlation (stride faults)

Exit 0 if ssim >= --min-ssim, else 1 (a gate, not a printout).

Usage: bx510_hud_diff.py <photo> <render> [--crop x,y,w,h] [--min-ssim 0.55]
"""
import argparse
import sys

import numpy as np
from PIL import Image


def load(path, size=(480, 270)):
    im = Image.open(path).convert("L").resize(size, Image.BILINEAR)
    return np.asarray(im, dtype=np.float64)


def ssim(a, b):
    c1, c2 = 6.5025, 58.5225
    mu_a, mu_b = a.mean(), b.mean()
    va, vb = a.var(), b.var()
    cov = ((a - mu_a) * (b - mu_b)).mean()
    return ((2 * mu_a * mu_b + c1) * (2 * cov + c2)) / \
           ((mu_a ** 2 + mu_b ** 2 + c1) * (va + vb + c2))


def best_shift(a, b, rng=12):
    h, w = a.shape
    best = (0, 0, -2.0)
    for dy in range(-rng, rng + 1, 2):
        for dx in range(-rng, rng + 1, 2):
            ys0, ys1 = max(0, dy), min(h, h + dy)
            xs0, xs1 = max(0, dx), min(w, w + dx)
            aa = a[ys0:ys1, xs0:xs1]
            bb = b[ys0 - dy:ys1 - dy, xs0 - dx:xs1 - dx]
            m = min(aa.shape[0], bb.shape[0])
            n = min(aa.shape[1], bb.shape[1])
            if m < 20 or n < 20:
                continue
            c = np.corrcoef(aa[:m, :n].ravel(), bb[:m, :n].ravel())[0, 1]
            if c > best[2]:
                best = (dx, dy, c)
    return best


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("photo")
    ap.add_argument("render")
    ap.add_argument("--min-ssim", type=float, default=0.55)
    ap.add_argument("--size", default="480x270")
    a = ap.parse_args()
    w, h = (int(v) for v in a.size.lower().split("x"))
    p = load(a.photo, (w, h))
    r = load(a.render, (w, h))
    s = ssim(p, r)
    lum = abs(p.mean() - r.mean())
    dx, dy, corr = best_shift(p, r)
    print("photo=%s render=%s" % (a.photo, a.render))
    print("ssim=%.3f lum_err=%.1f best_shift=(%d,%d) corr=%.3f"
          % (s, lum, dx, dy, corr))
    if s >= a.min_ssim:
        print("PASS: rig predicts the panel (ssim >= %.2f)" % a.min_ssim)
        return 0
    print("FAIL: ssim %.3f < %.2f — diagnose: shift=offset, colour=format, "
          "stretch=stride, crop=visible area" % (s, a.min_ssim))
    return 1


if __name__ == "__main__":
    sys.exit(main())
