#!/usr/bin/env python3
"""Regenerate every annotated listing the FW-load decode cites.

Writes decode/listings/<function>.txt so the markdown's instruction
addresses are reproducible from the pinned module rather than pasted.

Usage: sata_decode_listings.py [--out DIR]
"""
import argparse
import pathlib
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
TARGETS = [
    "sata_mt85xx_SocVerifyMainCode.clone.5",
    "sata_mt85xx_init_int_ldr",
    "sata_mt85xx_MTDRawRead.clone.6",
    "sata_mt85xx_parse_mtd_table",
    "sata_mt85xx_xfer_int_ldr_fw",
    "sata_mt85xx_port_start",
    "sata_mt85xx_init",
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=pathlib.Path, default=HERE / "listings")
    a = ap.parse_args()
    a.out.mkdir(parents=True, exist_ok=True)
    rc = 0
    for name in TARGETS:
        proc = subprocess.run(
            [sys.executable, str(HERE / "sata_decode_dis.py"), "--func", name],
            capture_output=True, text=True, timeout=180)
        dest = a.out / f"{name.replace('.', '_')}.txt"
        dest.write_text(proc.stdout + proc.stderr)
        lines = proc.stdout.count("\n")
        print(f"{dest.name}: {lines} lines rc={proc.returncode}")
        rc |= proc.returncode
    return rc


if __name__ == "__main__":
    sys.exit(main())
