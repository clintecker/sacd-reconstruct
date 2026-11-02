#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyelftools==0.33", "unicorn==2.1.4"]
# ///
"""Run the four integer-division routines in one or more unstripped ARM ELFs.

    uv run verify_sacd_div.py sacd_extract_160 path/to/rebuilt.elf

Each image uses its own symbol addresses and the same deterministic test cases.
The runner executes only the selected function and its in-image callees. It
supports little-endian ARM-state ET_EXEC binaries with self-contained division
routines, such as the AutoScript _160, without loading a guest libc or kernel.
"""

from __future__ import annotations

import argparse
import hashlib
import random
import struct
import sys
from io import BytesIO
from pathlib import Path

from elftools.elf.elffile import ELFFile
from unicorn import Uc, UcError, UC_ARCH_ARM, UC_MODE_ARM
from unicorn.arm_const import (
    UC_ARM_REG_LR, UC_ARM_REG_PC, UC_ARM_REG_SP,
    UC_ARM_REG_R0, UC_ARM_REG_R1, UC_ARM_REG_R2, UC_ARM_REG_R3,
    UC_ARM_REG_R4, UC_ARM_REG_R5, UC_ARM_REG_R6, UC_ARM_REG_R7,
    UC_ARM_REG_R8, UC_ARM_REG_R9, UC_ARM_REG_R10, UC_ARM_REG_R11,
)

MASK32 = (1 << 32) - 1
MASK64 = (1 << 64) - 1
PAGE = 4096
CALLEE_SAVED = (
    UC_ARM_REG_R4, UC_ARM_REG_R5, UC_ARM_REG_R6, UC_ARM_REG_R7,
    UC_ARM_REG_R8, UC_ARM_REG_R9, UC_ARM_REG_R10, UC_ARM_REG_R11,
)
FUNCTIONS = (
    ("__divdi3", True, False),
    ("__udivdi3", False, False),
    ("__gnu_ldivmod_helper", True, True),
    ("__gnu_uldivmod_helper", False, True),
)


def operands() -> list[tuple[int, int]]:
    # Boundary pairs exercise sign handling, word carries and one-word divisors.
    edge = [
        0, 1, 2, 3, 7, 31, 32, 33, 63, 64, 65, 127, 128, 255, 256, 257,
        (1 << 16) - 1, 1 << 16, (1 << 31) - 1, 1 << 31, MASK32,
        1 << 32, (1 << 32) + 1, (1 << 48) - 1, (1 << 63) - 1,
        1 << 63, (1 << 63) + 1, MASK64 - 1, MASK64,
    ]
    pairs = [(a, b) for a in edge for b in edge if b]
    rng = random.Random(2389)
    for divisor_bits, count in ((64, 1200), (31, 300)):
        pairs.extend((rng.getrandbits(64), rng.getrandbits(divisor_bits) or 1)
                     for _ in range(count))
    return list(dict.fromkeys(pairs))


def interpret(bits: int, signed: bool) -> int:
    return bits - (1 << 64) if signed and bits >= 1 << 63 else bits


def verify(path: Path, pairs: list[tuple[int, int]]) -> None:
    data = path.read_bytes()
    elf = ELFFile(BytesIO(data))
    if (elf.elfclass, elf.little_endian, elf["e_machine"], elf["e_type"]) != (
        32, True, "EM_ARM", "ET_EXEC",
    ):
        raise ValueError("expected a little-endian ARM ELF32 ET_EXEC")
    symbols = elf.get_section_by_name(".symtab")
    if symbols is None:
        raise ValueError("requires an unstripped .symtab with the libgcc symbols")

    # Map overlapping ELF load pages once. BSS starts zeroed in Unicorn.
    cpu = Uc(UC_ARCH_ARM, UC_MODE_ARM)
    loads = [s for s in elf.iter_segments() if s["p_type"] == "PT_LOAD" and s["p_memsz"]]
    pages: set[int] = set()
    for seg in loads:
        start = seg["p_vaddr"]
        pages.update(range(start & -PAGE, start + seg["p_memsz"], PAGE))
    if not pages:
        raise ValueError("ELF has no loadable memory")
    for page in sorted(pages):
        cpu.mem_map(page, PAGE)
    for seg in loads:
        if seg["p_filesz"]:
            cpu.mem_write(seg["p_vaddr"], seg.data())

    # Keep the test stack, output and return sentinel outside the loaded image.
    scratch = max(pages) + 2 * PAGE
    if scratch + 4 * PAGE >= 1 << 32:
        raise ValueError("no room for the test stack above this image")
    cpu.mem_map(scratch, 4 * PAGE)
    stop, sp, out = scratch, scratch + 2 * PAGE, scratch + 3 * PAGE + 8
    saved = tuple(0xDEAD0010 + i for i in range(len(CALLEE_SAVED)))
    guard = bytes.fromhex("c5d19a72")
    print(f"{path}  sha256={hashlib.sha256(data).hexdigest()}", flush=True)

    for name, signed, stores_remainder in FUNCTIONS:
        entries = [sym for sym in symbols.get_symbol_by_name(name) or []
                   if sym["st_shndx"] != "SHN_UNDEF" and sym["st_value"]]
        if len({sym["st_value"] for sym in entries}) != 1:
            raise ValueError(f"cannot identify a unique in-image {name}")
        address = entries[0]["st_value"]
        if address & 3:
            raise ValueError(f"{name} is not at an ARM-state word address")

        passed = 0
        for x, y in pairs:
            a, b = interpret(x, signed), interpret(y, signed)
            # Division by zero is excluded by operands(). This signed overflow
            # case also lacks a representable C result. Test traps separately.
            if signed and a == -(1 << 63) and b == -1:
                continue
            quotient = abs(a) // abs(b)
            if (a < 0) != (b < 0):
                quotient = -quotient
            remainder = a - b * quotient

            # AAPCS32 passes two 64-bit arguments in r0:r1 and r2:r3 and
            # the optional fifth word (the remainder pointer) at the entry SP.
            for reg, word in zip((UC_ARM_REG_R0, UC_ARM_REG_R1, UC_ARM_REG_R2, UC_ARM_REG_R3),
                                 (x & MASK32, x >> 32, y & MASK32, y >> 32)):
                cpu.reg_write(reg, word)
            for reg, value in zip(CALLEE_SAVED, saved):
                cpu.reg_write(reg, value)
            cpu.reg_write(UC_ARM_REG_SP, sp)
            cpu.reg_write(UC_ARM_REG_LR, stop)
            cpu.mem_write(sp, struct.pack("<I", out))
            # Invert the expected value so unwritten bytes cannot pass by chance.
            initial = struct.pack("<Q", (~remainder) & MASK64)
            cpu.mem_write(out - len(guard), guard + initial + guard)
            case = f"{name}({a}, {b})"
            try:
                cpu.emu_start(address, stop, count=12000)
            except UcError as exc:
                raise ValueError(f"{case}: emulation failed at {cpu.reg_read(UC_ARM_REG_PC):#x}: {exc}") from exc

            actual = cpu.reg_read(UC_ARM_REG_R0) | (cpu.reg_read(UC_ARM_REG_R1) << 32)
            if cpu.reg_read(UC_ARM_REG_PC) != stop:
                raise ValueError(f"{case}: did not return within the instruction limit")
            if actual != quotient & MASK64:
                raise ValueError(f"{case}: quotient {actual:#x}; expected {quotient & MASK64:#x}")
            if cpu.reg_read(UC_ARM_REG_SP) != sp or tuple(cpu.reg_read(r) for r in CALLEE_SAVED) != saved:
                raise ValueError(f"{case}: SP or r4-r11 changed across the call")
            expected = struct.pack("<Q", remainder & MASK64) if stores_remainder else initial
            if cpu.mem_read(out - len(guard), 16) != guard + expected + guard:
                raise ValueError(f"{case}: incorrect remainder write or clobbered guard")
            passed += 1
        print(f"  {name:<24} {passed:>4} passed")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("elf", type=Path, nargs="+")
    cases = operands()
    for path in parser.parse_args().elf:
        try:
            verify(path, cases)
        except (OSError, ValueError, UcError) as exc:
            print(f"{path}: {exc}", file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
