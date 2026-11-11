#!/usr/bin/env python3
"""Blob classifier for BX510 initrd/enc partitions.

This is intentionally simple and deterministic:
- Shannon entropy + chi^2 vs uniform for the whole file and per-block.
- Duplicate-block counts (ECB / repeated plaintext tell).
- Period match ratios (byte[i] == byte[i+period]) as a weak periodicity tell.
- A few checksum hypotheses (xor/crc over data excluding the last 4 bytes).
- Tiny XOR-known-plaintext guesses at offset 0 for common archive magics.

Outputs human-readable text suitable for evidence bundling.
"""

from __future__ import annotations

import argparse
import binascii
import collections
import hashlib
import math
import statistics
from dataclasses import dataclass
from pathlib import Path


MAGICS = {
    "cpio_newc_070701": b"070701",
    "cpio_newc_070702": b"070702",
    "gzip": b"\x1f\x8b\x08",
    "xz": b"\xfd7zXZ\x00",
    "lz4_frame": b"\x04\x22\x4d\x18",
    "zstd_frame": b"\x28\xb5\x2f\xfd",
    "lzop": b"\x89LZO\x00\r\n\x1a\n",
}


def shannon_entropy(data: bytes) -> float:
    if not data:
        return 0.0
    c = collections.Counter(data)
    n = len(data)
    ent = 0.0
    for v in c.values():
        p = v / n
        ent -= p * math.log2(p)
    return ent


def chi2_uniform_256(data: bytes) -> float:
    if not data:
        return 0.0
    c = collections.Counter(data)
    n = len(data)
    exp = n / 256.0
    chi2 = 0.0
    for b in range(256):
        obs = c.get(b, 0)
        chi2 += (obs - exp) ** 2 / exp
    return chi2


@dataclass(frozen=True)
class DupStat:
    block_size: int
    blocks: int
    unique: int
    dupes: int
    top_dupe_count: int


def duplicate_blocks(data: bytes, block_size: int) -> DupStat:
    if block_size <= 0:
        raise ValueError("block_size must be > 0")
    n = len(data) // block_size
    if n == 0:
        return DupStat(block_size, 0, 0, 0, 0)

    counts: dict[bytes, int] = {}
    for i in range(n):
        blk = data[i * block_size : (i + 1) * block_size]
        h = hashlib.blake2b(blk, digest_size=16).digest()
        counts[h] = counts.get(h, 0) + 1

    unique = len(counts)
    dupes = n - unique
    top = max(counts.values())
    return DupStat(block_size, n, unique, dupes, top)


def period_match_ratio(data: bytes, period: int) -> float:
    if period <= 0:
        raise ValueError("period must be > 0")
    if len(data) <= period:
        return 0.0
    matches = 0
    total = len(data) - period
    # Byte-by-byte is fine at these sizes.
    for i in range(total):
        if data[i] == data[i + period]:
            matches += 1
    return matches / total


def xor32_le(buf: bytes) -> int:
    x = 0
    for i in range(0, len(buf) - (len(buf) % 4), 4):
        x ^= int.from_bytes(buf[i : i + 4], "little")
    return x & 0xFFFFFFFF


def tail_u32_views(data: bytes) -> dict[str, int]:
    if len(data) < 4:
        return {}
    tail = data[-4:]
    return {
        "tail_le": int.from_bytes(tail, "little"),
        "tail_be": int.from_bytes(tail, "big"),
    }


def magic_xor_guess_offset0(data: bytes, key_len: int, magic: bytes) -> bytes | None:
    if key_len <= 0:
        return None
    if len(data) < len(magic):
        return None
    key = bytearray([0] * key_len)
    seen = [False] * key_len
    for i, want in enumerate(magic):
        ki = i % key_len
        kb = data[i] ^ want
        if seen[ki] and key[ki] != kb:
            return None
        key[ki] = kb
        seen[ki] = True
    return bytes(key)


def fmt_hex_u32(x: int) -> str:
    return f"0x{x:08x}"


def analyze(path: Path, block_size: int) -> str:
    data = path.read_bytes()

    out: list[str] = []
    out.append(f"file: {path}")
    out.append(f"size_bytes: {len(data)}")
    out.append("")

    ent = shannon_entropy(data)
    chi2 = chi2_uniform_256(data)
    out.append(f"overall_entropy_bits_per_byte: {ent:.6f}")
    out.append(f"overall_chi2_uniform_256: {chi2:.2f} (df=255)")
    out.append("")

    # Per-block entropy.
    blocks = [data[i : i + block_size] for i in range(0, len(data), block_size)]
    bents = [shannon_entropy(b) for b in blocks if b]
    if bents:
        out.append(f"block_entropy_bits_per_byte: block_size={block_size}")
        out.append(f"  blocks: {len(bents)}")
        out.append(f"  min: {min(bents):.6f}")
        out.append(f"  max: {max(bents):.6f}")
        out.append(f"  mean: {statistics.mean(bents):.6f}")
        out.append(f"  stdev: {statistics.pstdev(bents):.6f}")
    out.append("")

    out.append("duplicate_blocks:")
    for bs in (8, 16, 32, 64, 256, 4096):
        ds = duplicate_blocks(data, bs)
        out.append(
            f"  bs={ds.block_size:<5} blocks={ds.blocks:<8} unique={ds.unique:<8} dupes={ds.dupes:<8} top_dupe_count={ds.top_dupe_count}"
        )
    out.append("")

    out.append("period_match_ratio: (expected ~0.00390625 for random)")
    for p in (1, 2, 3, 4, 8, 16, 32):
        out.append(f"  period={p:<2} ratio={period_match_ratio(data, p):.6f}")
    out.append("")

    tails = tail_u32_views(data)
    if tails:
        out.append("tail_u32:")
        out.append(f"  tail_le: {fmt_hex_u32(tails['tail_le'])}")
        out.append(f"  tail_be: {fmt_hex_u32(tails['tail_be'])}")
        out.append("")

    if len(data) >= 8:
        # A couple plausible checksum conventions.
        body = data[:-4]
        tail_le = tails.get("tail_le")
        tail_be = tails.get("tail_be")
        x = xor32_le(body)
        crc = binascii.crc32(body) & 0xFFFFFFFF
        out.append("checksum_hypotheses_over_data_excluding_last4:")
        out.append(f"  xor32_le(body): {fmt_hex_u32(x)} match_tail_le={x == tail_le} match_tail_be={x == tail_be}")
        out.append(f"  crc32(body):    {fmt_hex_u32(crc)} match_tail_le={crc == tail_le} match_tail_be={crc == tail_be}")
        out.append("")

    out.append("xor_known_plaintext_offset0_guesses:")
    out.append("  NOTE: Only reports repeating-key lengths k where k < len(magic) (to avoid the trivial k==len(magic) always-fit case).")
    for magic_name, magic in MAGICS.items():
        out.append(f"  magic={magic_name} len={len(magic)}")
        found_any = False
        max_k = min(32, len(magic) - 1)
        if max_k <= 0:
            out.append("    (magic too short)")
            continue
        for key_len in range(1, max_k + 1):
            key = magic_xor_guess_offset0(data, key_len, magic)
            if key is None:
                continue
            dec = bytes(data[i] ^ key[i % key_len] for i in range(len(magic)))
            if dec == magic:
                out.append(f"    key_len={key_len:<2} key_hex={key.hex()}")
                found_any = True
        if not found_any:
            out.append("    (no consistent repeating-key length found)")
    out.append("")

    # A couple fixed-offset filesystem tells (these are *weak* heuristics; absence is normal for encrypted blobs).
    # ext2/ext3/ext4: superblock at 0x400, magic at 0x438.
    if len(data) >= 0x43A:
        ext_magic = int.from_bytes(data[0x438:0x43A], 'little')
        out.append("fixed_offset_fs_tells:")
        out.append(f"  ext_superblock_magic_at_0x438: 0x{ext_magic:04x} (expected 0xef53)")
        out.append("")

    return "\n".join(out)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("blob", type=Path)
    ap.add_argument("--block", type=int, default=4096)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()

    report = analyze(args.blob, args.block)
    args.out.write_text(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
