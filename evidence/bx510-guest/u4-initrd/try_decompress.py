#!/usr/bin/env python3
"""Try common decompressors against initrd_1.bin.

Goal: distinguish "encrypted/opaque" from "headerless/raw compressed".

We record both SUCCESS and FAILURE (including exception types) into a text
report so the negative results are evidenced.

NOTE: Many formats require magic headers; a clean failure here does not
prove encryption.
"""

from __future__ import annotations

import argparse
import bz2
import gzip
import lzma
import zlib
from pathlib import Path

import zstandard


def try_one(name: str, fn, data: bytes):
    try:
        out = fn(data)
        return (name, True, len(out), None)
    except Exception as e:  # noqa: BLE001 - evidence wants full type
        return (name, False, None, f"{type(e).__name__}: {e}")


def scan_plaintext_tells(data: bytes) -> list[str]:
    tells = []
    if data.startswith(b"070701") or data.startswith(b"070702"):
        tells.append("cpio_newc_magic_at_offset0")
    if data.startswith(b"\x1f\x8b\x08"):
        tells.append("gzip_magic_at_offset0")
    if b"070701" in data[:4096]:
        tells.append("cpio_newc_magic_within_first4k")
    return tells


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("blob", type=Path)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()

    src = args.blob.read_bytes()

    attempts = [
        ("zlib_wbits+15", lambda b: zlib.decompress(b, wbits=15)),
        ("zlib_raw_wbits-15", lambda b: zlib.decompress(b, wbits=-15)),
        ("gzip_wrapper", gzip.decompress),
        ("bz2", bz2.decompress),
        ("lzma_auto", lambda b: lzma.decompress(b, format=lzma.FORMAT_AUTO)),
        (
            "zstd_frame",
            lambda b: zstandard.ZstdDecompressor().decompress(b, max_output_size=128 * 1024 * 1024),
        ),
    ]

    lines: list[str] = []
    lines.append(f"file: {args.blob}")
    lines.append(f"size_bytes: {len(src)}")
    lines.append("")

    for name, fn in attempts:
        (n, ok, out_len, err) = try_one(name, fn, src)
        if ok:
            # If we succeed, write the output next to the report for follow-up.
            out_path = args.out.parent / f"{args.blob.name}.{name}.out"
            out = fn(src)
            out_path.write_bytes(out)
            tells = scan_plaintext_tells(out)
            lines.append(f"{n}: SUCCESS out_len={out_len} out_path={out_path}")
            if tells:
                lines.append(f"  plaintext_tells: {', '.join(tells)}")
        else:
            lines.append(f"{n}: FAIL {err}")
        lines.append("")

    args.out.write_text("\n".join(lines))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
