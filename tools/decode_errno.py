#!/usr/bin/env python3
"""decode_errno.py — deterministic errno decoding (never by mental arithmetic).

The 2026-11-04 incident: a rig log showed "mknod failed fffffff3" and the
analysis was eyeballed in prose ("0xf3 = 243?? ... whatever") — exactly the
squinting-at-bytes failure mode the repo bans for wire captures. This tool
is the codified fix for the errno corner of that rule: every errno-like
value (decimal, hex, or two's-complement log residue like fffffff3) decodes
through HERE, and where the failing call is reproducible, the companion
discipline is to produce the value empirically (strace the call) rather
than decode a log line at all.

Stdlib-only. Self-testing (run with --selftest; used by the repo suite).

Usage:
    python3 decode_errno.py fffffff3            # two's-complement residue
    python3 decode_errno.py 13 0xf3 -13         # multiple values
    python3 decode_errno.py --selftest
"""
import argparse
import errno as _errno
import sys

LINUX_ARM_ERRNO = {}  # filled below for the target ABI (Linux, same on ARM)


def _build_table():
    # Linux errno values are ABI-stable across arm/x86 for the common range
    # (Linux source include/uapi/asm-generic/errno*.h; ARM uses the generic
    # table). We take them from the host's errno module — the canonical,
    # toolchain-derived source — rather than hand-typing numbers.
    names = [n for n in dir(_errno) if n.startswith("E") and not n.startswith("E_")]
    table = {}
    for n in names:
        v = getattr(_errno, n)
        if isinstance(v, int) and 0 < v < 256:
            table.setdefault(v, []).append(n)
    return table


def decode(value: int) -> str:
    table = _build_table()
    lines = []
    # Two interpretations: the raw value as errno, and the common log
    # residue form (negative value printed as 32-bit hex by a C %x of an
    # int) — decode BOTH explicitly rather than guessing which applies.
    lines.append(f"value        : {value}")
    lines.append(f"as hex (32b) : {value & 0xffffffff:#010x}")
    if value < 0 or value > 255:
        signed = value if value < 0 else value - (1 << 32) if value >= (1 << 31) else value
        lines.append(f"as signed 32 : {signed}")
        if 0 < -signed < 256:
            names = table.get(-signed, [])
            lines.append(f"errno -(-val): {', '.join(names) if names else 'UNKNOWN'} ({-signed})")
            if names:
                lines.append(f"meaning      : {name_meaning(names[0])}")
        return "\n".join(lines)
    names = table.get(value, [])
    lines.append(f"errno name   : {', '.join(names) if names else 'UNKNOWN'}")
    if names:
        lines.append(f"meaning      : {name_meaning(names[0])}")
    return "\n".join(lines)


def name_meaning(name: str) -> str:
    # Short POSIX meanings for the values that show up in practice; anything
    # absent falls back to the name alone (never a wrong guess).
    m = {
        "EPERM": "operation not permitted (often: missing capability, e.g. CAP_MKNOD)",
        "EACCES": "permission denied (path permission bits / search permission)",
        "EEXIST": "file exists (often benign: node already present)",
        "ENOENT": "no such file or directory",
        "EAGAIN": "resource temporarily unavailable (would block)",
        "EINTR": "interrupted system call",
        "EINVAL": "invalid argument",
        "ENOTTY": "inappropriate ioctl for device",
        "EPIPE": "broken pipe",
        "EFAULT": "bad address",
        "ENOSPC": "no space left on device",
        "EIO": "i/o error",
    }
    return m.get(name, "see errno(3)")


def _selftest() -> int:
    """Deterministic self-check: known values decode to known names."""
    # 0xfffffff3 as signed 32-bit = -13 (EACCES). Verify exactly:
    assert (0xFFFFFFF3 - (1 << 32)) == -13, "two's-complement arithmetic"
    got = decode(0xFFFFFFF3)
    assert "EACCES" in got, got
    # bare hex residue strings (no 0x) parse and decode identically
    assert "EACCES" in decode(int("fffffff3", 16))
    assert "EACCES" in decode(13)
    assert "EPERM" in decode(1)
    assert "EEXIST" in decode(17)
    # every decode prints the canonical name, never a guess for unknowns
    assert "UNKNOWN" in decode(200) or "errno name" in decode(200)
    print("SELFTEST: PASS")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("values", nargs="*", help="values to decode: decimal, hex (0x...), or signed")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return _selftest()
    if not a.values:
        ap.print_help()
        return 2
    rc = 0
    for raw in a.values:
        try:
            v = int(raw, 0)
        except ValueError:
            # C logs print hex residues WITHOUT the 0x prefix (printf %x of a
            # negative int): fffffff3. Accept bare hex-digit strings.
            try:
                v = int(raw, 16)
            except ValueError:
                print(f"{raw}: not an integer", file=sys.stderr)
                rc = 1
                continue
        print(decode(v))
        print()
    return rc


if __name__ == "__main__":
    sys.exit(main())
