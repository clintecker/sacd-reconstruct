#!/usr/bin/env python3
"""hud_scenarios.py — generate per-frame ingest scenarios for HUD captures.

Each scenario is a directory of files ev-000..ev-<N-1>; frame i of the
host simulator ingests ev-<i> through host_push_parse() (the same parser
the UDP 20023 path uses), so the GIF shows the HUD's state machines
moving: capture progress, event storms, verify failures.

Scenarios:
  capture      RANGE 0->100% with RATE/ETA, ends VERIFY status=ok
  verify-fail  same ramp, ends VERIFY status=fail bad=7 (ERROR class)
  storm        client event bursts (READ/CLOSE) with quiet gaps
  quiet        no ingest files (pure effects demo)

Usage: hud_scenarios.py <name> <outdir> [--frames N]
"""
import os
import sys

TOTAL = 1064208  # firebird disc sectors (baseline manifest)


def scenario_frames(name, n):
    """Return list of per-frame line-lists (index = frame)."""
    evs = [[] for _ in range(n)]
    if name in ("capture", "verify-fail"):
        for i in range(n):
            done = int(TOTAL * (i + 1) / n)
            evs[i].append("RANGE done=%d total=%d" % (done, TOTAL))
            evs[i].append("RATE mbs=%.1f" % (4.0 + 2.5 * ((i % 7) / 6.0)))
            eta = max(0, int((TOTAL - done) / (4.7 * 2048)))
            evs[i].append("ETA s=%d" % eta)
        evs[n - 1].append("VERIFY status=ok" if name == "capture"
                          else "VERIFY status=fail bad=7")
    elif name == "storm":
        lsn = 532104
        for i in range(n):
            burst = (i % 3 != 2)  # every 3rd frame quiet (gap pattern)
            if burst:
                for _ in range(3):
                    evs[i].append("READ lsn=%d n=128 (256K)" % lsn)
                    lsn += 128
                if i % 2 == 0:
                    evs[i].append("CLOSE rc=0")
            elif i % 5 == 0:
                evs[i].append("CLIENT CONNECTED")
    elif name == "quiet":
        pass
    else:
        raise SystemExit("unknown scenario: %s" % name)
    return evs


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    name, outdir = sys.argv[1], sys.argv[2]
    n = 40
    if len(sys.argv) > 4 and sys.argv[3] == "--frames":
        n = int(sys.argv[4])
    evs = scenario_frames(name, n)
    os.makedirs(outdir, exist_ok=True)
    written = 0
    for i, lines in enumerate(evs):
        if not lines:
            continue
        with open(os.path.join(outdir, "ev-%03d" % i), "w") as f:
            f.write("\n".join(lines) + "\n")
        written += 1
    print("scenario %s: %d/%d frames staged in %s" % (name, written, n, outdir))
    return 0


if __name__ == "__main__":
    sys.exit(main())
