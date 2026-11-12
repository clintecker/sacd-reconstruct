#!/usr/bin/env python3
"""uImage -> zImage -> raw vmlinux for the BX510 guest kernel.

Three layers, each verified rather than assumed:

  1. uImage: 64-byte legacy header (magic 0x27051956, big-endian fields).
     `comp` is 0 ("none") at this layer because the payload is a
     self-decompressing ARM zImage, not because the payload is executable
     as-is.
  2. zImage: ARM boot header at +0x24 holds magic 0x016f2818, +0x28 start
     and +0x2c end. The compressed payload is a gzip member whose offset is
     found by magic scan (0x43d5 here), not by a fixed guess.
  3. Raw image: zlib inflates it to 4,676,960 bytes of ARM code with no ELF
     headers (objcopy -O binary vmlinux). File offset 0 == stext, whose VA
     (0xc0008000) is recovered independently by kernel_decode_kallsyms.py.

Usage:
  kernel_decode_image.py <kernel.uImage> [outdir=/tmp/kdec]
Prints the header decode and the recovered offsets; writes <outdir>/zImage.bin
and <outdir>/vmlinux.bin.
"""
import os
import struct
import sys
import zlib

ZIMAGE_MAGIC = 0x016F2818
GZIP_MAGIC = b"\x1f\x8b\x08"


def main():
    uimg = sys.argv[1]
    outdir = sys.argv[2] if len(sys.argv) > 2 else "/tmp/kdec"
    os.makedirs(outdir, exist_ok=True)
    d = open(uimg, "rb").read()
    def be(o):
        return struct.unpack(">I", d[o:o + 4])[0]

    assert be(0) == 0x27051956, "not a uImage"
    size, load, ep, dcrc = be(12), be(16), be(20), be(24)
    os_, arch, typ, comp = d[28], d[29], d[30], d[31]
    print("uImage: size=%d load=%#x ep=%#x dcrc=%#08x os=%d arch=%d "
          "type=%d comp=%d" % (size, load, ep, dcrc, os_, arch, typ, comp))
    zimg = d[64:64 + size]
    open(os.path.join(outdir, "zImage.bin"), "wb").write(zimg)
    zm = struct.unpack_from("<I", zimg, 0x24)[0]
    assert zm == ZIMAGE_MAGIC, "zImage magic missing: %#x" % zm
    zstart, zend = struct.unpack_from("<II", zimg, 0x28)
    print("zImage: magic=%#x start=%#x end=%#x bytes=%d"
          % (zm, zstart, zend, len(zimg)))
    g = zimg.find(GZIP_MAGIC)
    assert g > 0, "no gzip member in zImage"
    print("zImage: gzip member at %#x" % g)
    out = zlib.decompressobj(47).decompress(zimg[g:])
    open(os.path.join(outdir, "vmlinux.bin"), "wb").write(out)
    print("raw image: %d bytes (%#x) -> %s/vmlinux.bin"
          % (len(out), len(out), outdir))
    print("raw image: first words %s (ARM code, not a vector table)"
          % " ".join("%08x" % w for w in struct.unpack_from("<4I", out, 0)))


main()
