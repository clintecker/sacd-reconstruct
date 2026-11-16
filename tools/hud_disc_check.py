#!/usr/bin/env python3
"""Pixel-probe gate for the merged disc-console HUD scene (sacd-hud-disc-sim).

The hud_guest_gate rule applies on the Mac too: a black or inkless region
FAILS instead of being eyeballed. Probes the regions scene_disc draws and
the palette the vibe requires (phosphor title, cyan/magenta area heads,
telemetry progress bar). Usage: hud_disc_check.py /path/to/frame.ppm
"""
import sys

def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/hud_disc.ppm"
    d = open(path, "rb").read()
    parts = d.split(b"\n", 3)
    if parts[0] != b"P6":
        sys.exit(f"FAIL {path}: not a P6 PPM")
    w, h = map(int, parts[1].split())
    if (w, h) != (1920, 1080):
        sys.exit(f"FAIL {path}: expected the 1920x1080 pool geometry, got {w}x{h}")
    px = parts[3]

    def lum(x0, y0, x1, y1):
        tot = n = 0
        for y in range(y0, y1, 4):
            for x in range(x0, x1, 4):
                i = (y * w + x) * 3
                tot += 0.299 * px[i] + 0.587 * px[i + 1] + 0.114 * px[i + 2]
                n += 1
        return tot / n

    def has(x0, y0, x1, y1, pred):
        for y in range(y0, y1, 2):
            for x in range(x0, x1, 2):
                i = (y * w + x) * 3
                if pred(px[i], px[i + 1], px[i + 2]):
                    return True
        return False

    checks = [
        # (name, region, min mean luminance)
        ("title",    (30, 20, 700, 90),     8.0),
        ("status",   (30, 100, 1500, 260),  8.0),
        ("panel-2ch",(40, 270, 940, 570),   10.0),
        ("panel-multi", (980, 270, 1880, 570), 10.0),
        ("eventlog", (40, 610, 1150, 860),  8.0),
        ("telemetry",(980, 610, 1880, 860), 12.0),
        ("summary",  (30, 900, 1500, 1000), 6.0),
    ]
    failed = []
    for name, (x0, y0, x1, y1), floor in checks:
        m = lum(x0, y0, x1, y1)
        ok = m >= floor
        print(f"{'PASS' if ok else 'FAIL'} {name:12s} mean_lum={m:6.1f} (floor {floor})")
        if not ok:
            failed.append(name)

    palette = [
        ("phosphor-title", (30, 20, 700, 90),
         lambda r, g, b: g > 150 and r < 120),
        ("cyan-or-magenta-heads", (40, 270, 1880, 310),
         lambda r, g, b: (b > 140 and g > 140 and r < 110)
         or (r > 60 and b > 140 and g < 110)),
        ("telemetry-bar", (980, 630, 1880, 660),
         lambda r, g, b: g > 120 and r < 120),
    ]
    for name, (x0, y0, x1, y1), pred in palette:
        ok = has(x0, y0, x1, y1, pred)
        print(f"{'PASS' if ok else 'FAIL'} {name}")
        if not ok:
            failed.append(name)

    if failed:
        sys.exit(f"FAIL: {', '.join(failed)}")
    print("hud_disc_check: all region + palette probes PASS")

if __name__ == "__main__":
    main()
