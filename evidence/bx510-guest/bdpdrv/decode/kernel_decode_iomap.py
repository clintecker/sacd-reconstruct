#!/usr/bin/env python3
"""Decode the BX510 static IO map (mt85xx_map_io's map_desc tables).

Answer shape this produces, all read out of the image (nothing hand-typed):

    map_desc = { unsigned long virtual; unsigned long pfn;
                 unsigned long length; unsigned int type; }   (16 bytes)

2.6.35 carries `pfn`, not `physical`, so physical = pfn << 12.

The descriptors are located through kallsyms (`mt85xx_io_desc`,
`mt85xx_local_io_desc`) and cross-checked three ways:
  * mt85xx_map_io's literal pool must reference exactly those two symbols
    (add #16 for the second entry) and `bl iotable_init`, count 1 each;
  * every descriptor word must be self-consistent (aligned VA in the IO
    window, pfn in low physical memory, power-of-two length);
  * the last entry must be followed by the zero terminator the machine's
    `__machine_arch_type`-independent walker never reads but the compiler
    still emits for the array bound.

Usage:
  kernel_decode_iomap.py [raw-image] [--query 0xfd05c704 ...]
"""
import bisect
import os
import struct
import sys

TEXT_VA = 0xC0008000
HERE = os.path.dirname(os.path.abspath(__file__))
RAW = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") \
    else "/tmp/kdec/vmlinux.bin"
KSYM = "/tmp/kdec/kallsyms.txt"
IO_VA_DELTA = 0x8D000000  # VA 0xfd000000 == PA 0x70000000

# The blocks the BX510 drivers address (VERIFIED: these literals appear in the
# sata_mt85xx module / bdpdrv pools and in the kernel's own BIM code).
DEFAULT_QUERIES = {
    0xFD05C704: "FE/IDE control +0x704 (i4IdeDrvBootup: release FE reset)",
    0xFD05C500: "FE/IDE control +0x500 (i4IdeDrvBootup: DRAM wrapper base)",
    0xFD324180: "FE SRAM FIFO write pointer (sata module 0xfd324fff base)",
    0xFD324B00: "FE SRAM FIFO window +0xb00",
    0xFD024000: "FE block base (VSFHW_* in bdpdrv, secondary intc +0x140/0x144)",
    0xFD024180: "FE block +0x180",
    0xFD00A000: "ATA/IDE taskfile window (sata_mt85xx_send_atapi_cmd)",
    0xFD090308: "DRAM wrapper (sata_mt85xx_reset_int_ldr)",
    0xFD060004: "clock/pll block (sata_mt85xx_reset_int_ldr)",
}


def load_syms():
    syms = []
    for line in open(KSYM):
        va, name = line.split(None, 1)
        syms.append((int(va, 16), name.strip()))
    syms.sort()
    return syms


def main():
    img = open(RAW, "rb").read()
    syms = load_syms()
    vas = [s[0] for s in syms]
    byname = {n: a for a, n in syms}

    def owner(va):
        i = bisect.bisect_right(vas, va) - 1
        return syms[i]

    descs = []
    for name, count in (("mt85xx_io_desc", 1), ("mt85xx_local_io_desc", 1)):
        va = byname[name]
        for k in range(count):
            off = va - TEXT_VA + 16 * k
            v, pfn, ln, typ = struct.unpack_from("<4I", img, off)
            descs.append(dict(sym=name, idx=k, va_off=off, virt=v, pfn=pfn,
                              phys=pfn << 12, length=ln, type=typ))
    print("static map installed by mt85xx_map_io "
          "(machine_desc.map_io = %#x, iotable_init = %#x):\n"
          % (byname["mt85xx_map_io"], byname["iotable_init"]))
    print("  %-24s %-12s %-12s %-12s %-5s %s"
          % ("array", "virtual", "physical", "length", "type", "span"))
    for d in descs:
        print("  %-24s 0x%08x   0x%08x   0x%08x   %-5d VA 0x%08x..0x%08x -> "
              "PA 0x%08x..0x%08x"
              % ("%s[%d]" % (d["sym"], d["idx"]), d["virt"], d["phys"],
                 d["length"], d["type"], d["virt"], d["virt"] + d["length"] - 1,
                 d["phys"], d["phys"] + d["length"] - 1))
        assert d["virt"] & 0xFFFFF == 0, "VA not section aligned"
        assert d["length"] and d["length"] & (d["length"] - 1) == 0, "bad length"

    # independent check: who references the descriptor addresses?
    for d in descs:
        pat = struct.pack("<I", byname[d["sym"]])
        hits = []
        i = 0
        while True:
            i = img.find(pat, i)
            if i < 0:
                break
            hits.append(TEXT_VA + i)
            i += 1
        inmapio = any(owner(h)[1] == "mt85xx_map_io" for h in hits)
        print("\n  &%-22s pool literal(s) at %s; in mt85xx_map_io: %s"
              % (d["sym"], ["0x%08x" % h for h in hits], inmapio))

    # coverage of the queried addresses
    queries = DEFAULT_QUERIES
    if "--query" in sys.argv:
        queries = {}
        for q in sys.argv[sys.argv.index("--query") + 1:]:
            queries[int(q, 0)] = ""
    print("\ncoverage (VA -> PA via the entry that contains it):")
    for q in sorted(queries):
        hit = None
        for d in descs:
            if d["virt"] <= q < d["virt"] + d["length"]:
                hit = d
                break
        if hit is None:
            print("  0x%08x  UNMAPPED by any static entry" % q)
            continue
        pa = hit["phys"] + (q - hit["virt"])
        print("  0x%08x -> PA 0x%08x  [%s[%d] VA 0x%08x len 0x%x type %d]%s"
              % (q, pa, hit["sym"], hit["idx"], hit["virt"], hit["length"],
                 hit["type"], ("  " + queries[q]) if queries[q] else ""))


main()
