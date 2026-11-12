#!/usr/bin/env python3
"""Decide the `SocVerifyMainCode` firmware-tag branch by ARM flag semantics.

The decode of the accept/reject test at .init.text 0x08..0x14 is:

    ldr  r3, [r0]        ; r3 = first 32-bit word of the FE firmware image
    sub  r3, r3, #1      ; r3 = v - 1            (SUBS: flags set)
    cmn  r3, #3          ; flags = r3 + 3         (ADDS with carry-in 0)
    bls  <checksum path> ; branch if C==0 or Z==1

Reading that by eye is how branch polarity gets inverted, so this script
executes the exact ARM data-processing flag rules for every input class and
prints which half of the function each value reaches. Values are the ones a
NAND dump can actually produce: erased flash (all 0xff), an unwritten region
(all 0x00), and the small integers a real header would carry.

Usage: sata_decode_flags.py [--all]
"""
import sys


def add_flags(a, b, carry_in=0):
    """ARM ADDS/CMP/CMN flag computation on 32-bit operands."""
    u = a + b + carry_in
    result = u & 0xFFFFFFFF
    carry = 1 if u > 0xFFFFFFFF else 0
    # V: signed overflow when both operands' signs agree and differ from result
    sa, sb, sr = a >> 31, b >> 31, result >> 31
    overflow = 1 if (sa == sb and sr != sa) else 0
    zero = 1 if result == 0 else 0
    negative = sr
    return result, negative, zero, carry, overflow


def sub_flags(a, b):
    """ARM SUBS a, b -> a + ~b + 1."""
    return add_flags(a, (~b) & 0xFFFFFFFF, 1)


def bls_taken(n, z, c, v):
    """BLS == 'branch if unsigned lower or same' == C==0 or Z==1."""
    return c == 0 or z == 1


def classify(v, image_note=""):
    r3, _, _, _, _ = sub_flags(v, 1)          # sub r3, r3, #1
    _, n, z, c, ov = add_flags(r3, 3, 0)      # cmn r3, #3
    taken = bls_taken(n, z, c, ov)
    path = "CHECKSUM PATH (0x38)" if taken else "REJECT: 'yifan FE firmware without CheckSum..' (0x18)"
    return r3, (n, z, c, ov), path


def main():
    cases = [
        (0x00000000, "all-zero region / unwritten page"),
        (0xFFFFFFFF, "erased NAND (every byte 0xff)"),
        (0xFFFFFFFE, "0xFFFFFFFE"),
        (0xFFFFFFFD, "0xFFFFFFFD"),
        (0x00000001, "small tag version 1"),
        (0x00000004, "small tag version 4"),
        (0x00000022, "0x22 (a plausible header revision)"),
        (0x4E414659, "plausible magic ('YFAN' little-endian)"),
    ]
    print(f"{'v (fw[0])':>12}  {'v-1':>10}  {'N Z C V':>8}  path")
    for v, note in cases:
        r3, flags, path = classify(v)
        n, z, c, ov = flags
        print(f"0x{v:08X} 0x{r3:08X}  {n} {z} {c} {ov}   {path}")
        print(f"{'':>12}  {note}")
    print()
    print("Both realistic empty-flash contents (0x00 and 0xff) land on the")
    print("REJECT branch, which is the branch the C55 UART shows.")


if __name__ == "__main__":
    sys.exit(main())
