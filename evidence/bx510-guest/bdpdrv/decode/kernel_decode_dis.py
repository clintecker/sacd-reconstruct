#!/usr/bin/env python3
"""Symbol-scoped disassembly of the BX510 guest kernel.

Wraps the raw image as an ELF (llvm-objcopy) so llvm-objdump can disassemble
it, and resolves `bl`/literal targets against the kallsyms listing from
kernel_decode_kallsyms.py.  llvm-objdump only knows the synthetic section, so
branch targets print as `_binary_vmlinux_bin_start+0x...`; this script adds the
real symbol name and the literal-pool VALUE (which is what actually identifies
an iotable_init descriptor, an IRQ number, or an MMIO base).

Usage:
  kernel_decode_dis.py --prep                     # build ELF + kallsyms once
  kernel_decode_dis.py --sym mt85xx_map_io        # disassemble one function
  kernel_decode_dis.py --range 0xc000cd84 0xc000cdac
  kernel_decode_dis.py --grep 'irq|sata'         # search symbol names
"""
import os
import re
import struct
import subprocess
import sys

OBJDUMP = "/opt/homebrew/opt/llvm/bin/llvm-objcopy"
LLVM_OBJDUMP = "/opt/homebrew/opt/llvm/bin/llvm-objdump"
WORK = "/tmp/kdec"
RAW = os.path.join(WORK, "vmlinux.bin")
ELF = os.path.join(WORK, "vmlinux.elf")
KSYM = os.path.join(WORK, "kallsyms.txt")
TEXT_VA = 0xC0008000
HERE = os.path.dirname(os.path.abspath(__file__))

POOL_RE = re.compile(r"pc, #0x[0-9a-f]+\]\s+@ 0x([0-9a-f]+)")
BRANCH_RE = re.compile(r"\b(b|bl|bx)\s+0x([0-9a-f]+)")


def prep():
    subprocess.run([OBJDUMP, "-I", "binary", "-O", "elf32-littlearm",
                    "--binary-architecture=arm", RAW, ELF], check=True)
    with open(KSYM, "w") as f:
        subprocess.run([sys.executable,
                        os.path.join(HERE, "kernel_decode_kallsyms.py"), RAW],
                       stdout=f, check=True, stderr=subprocess.DEVNULL)


def load_syms():
    syms = []
    for line in open(KSYM):
        va, name = line.split(None, 1)
        syms.append((int(va, 16), name.strip()))
    syms.sort()
    return syms


def slice_for(syms, name):
    for k, (va, n) in enumerate(syms):
        if n == name:
            start = va
            end = syms[k + 1][0] if k + 1 < len(syms) else va + 0x400
            if end <= start:
                end = start + 0x400
            return start, end
    raise SystemExit("symbol not found: %s" % name)


SLICE = os.path.join(WORK, "vmlinux.slice.elf")


def disassemble(start, end, img, syms):
    """Disassemble [start,end) by wrapping just those bytes as a raw ELF.

    llvm-objdump ignores --start-address for a synthetic one-section binary,
    so the slice itself is the input; --adjust-vma restores the real VA.
    """
    with open(os.path.join(WORK, "slice.bin"), "wb") as f:
        f.write(img[start - TEXT_VA:end - TEXT_VA])
    subprocess.run([OBJDUMP, "-I", "binary", "-O", "elf32-littlearm",
                    "--binary-architecture=arm",
                    os.path.join(WORK, "slice.bin"), SLICE], check=True)
    out = subprocess.run(
        [LLVM_OBJDUMP, "-D", "-j", ".data", "--triple=armv7a-none-eabi",
         "--adjust-vma=%d" % start, SLICE],
        capture_output=True, text=True).stdout
    names = {va: n for va, n in syms}
    lines = []
    for line in out.splitlines():
        m = re.match(r"^\s*([0-9a-f]+):\s+([0-9a-f]{8})\s+(.*)$", line)
        if not m:
            continue
        va, word, rest = int(m.group(1), 16), int(m.group(2), 16), m.group(3)
        note = ""
        bm = BRANCH_RE.search(rest)
        if bm:
            tgt = int(bm.group(2), 16)
            note = "  -> %s" % names.get(tgt, "?")
        pm = POOL_RE.search(rest)
        if pm:
            # objdump prints the pool address section-relative; the slice was
            # wrapped at --adjust-vma=start, so shift it back into VA space.
            pool = start + int(pm.group(1), 16)
            val = struct.unpack_from("<I", img, pool - TEXT_VA)[0]
            meaning = ""
            if val in names:
                meaning = " = &%s" % names[val]
            elif 0xf0000000 <= val < 0xff000000:
                meaning = " = IO VA (phys %#x via -0x8d000000)" % (val - 0x8D000000)
            elif 0x70000000 <= val < 0x80000000:
                meaning = " = IO phys"
            note = "  pool[%#x]=%#010x%s" % (pool, val, meaning)
        lines.append("%08x %08x %-42s%s" % (va, word, rest.rstrip(), note))
    return "\n".join(lines)


if __name__ == "__main__":
    if not os.path.exists(ELF) or not os.path.exists(KSYM) or "--prep" in sys.argv:
        prep()
    syms = load_syms()
    img = open(RAW, "rb").read()
    if "--sym" in sys.argv:
        name = sys.argv[sys.argv.index("--sym") + 1]
        start, end = slice_for(syms, name)
        print("%s: %#010x..%#010x" % (name, start, end))
        print(disassemble(start, end, img, syms))
    elif "--range" in sys.argv:
        i = sys.argv.index("--range")
        start, end = int(sys.argv[i + 1], 0), int(sys.argv[i + 2], 0)
        print(disassemble(start, end, img, syms))
    elif "--grep" in sys.argv:
        pat = re.compile(sys.argv[sys.argv.index("--grep") + 1])
        for va, n in syms:
            if pat.search(n):
                print("%08x %s" % (va, n))
    else:
        print(__doc__)
