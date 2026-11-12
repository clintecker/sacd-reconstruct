#!/usr/bin/env python3
"""fe_reply_bytes.py — the FE status-reply byte set the QEMU model must produce.

Source of truth: `sata_mt85xx_chk_int_ldr` (.text+0x2810, size 0x294) in
`/tmp/bdpdrv/sata_mt85xx_mod.ko`, sha256
8a0253eb9bff19a3d3c0ac594a507235bad82348d8e80069024368d0f5456657.
The full decode, with the instruction address behind every requirement below,
is `decode/fe-status-handshake.md` in this directory.

What the driver does (all addresses section-relative, .text):

  0x28a4  poll 0x7005c804, OR-accumulate, exit when bit16 (0x10000) is seen
  0x28b8  read the four status words 0x7005c040 / c044 / c048 / c04c
  0x28c4  type  = byte2 of word0     (`ldrb r2,[r8,#2]`), tested at 0x28d0
  0x28e4  err   = byte3 of word0     (`ldrb r2,[r8,#3]`), tested at 0x28e8
  0x2914  type == 16 -> table-data transfer, then poll again (0x2974 -> 0x2880)
  0x299c  type == 0 && err == 0 -> inspect the copied block:
            0x29a4 buf[0x2f] == 'B'   0x29f8 buf[0x2e] == 'O'
            0x2a04 buf[0x31] == 'O'   0x2a10 buf[0x30] == 'T'
            0x29b0 LE16(buf[0x100]) == 0xeeee  -> *out = 1
  0x29a0  return byte3 of word0 (0 here)  =>  0 == "status accepted"

So a passing reply is three things, not one:

  (1) bit16 of 0x7005c804 set while a message is pending   (the poll gate)
  (2) message A: word0 byte2 == 16, word1 = DRAM offset, word2 = length
      -> the driver copies min(word2, 512) bytes from
         `*svoif_int_ldr_dram + word1` (0x291c/0x2938) into a fresh
         non-zeroed kmalloc buffer (0x2820) and ACKs it (0x2968)
  (3) message B: word0 == 0 -> the block copied by (2) is inspected;
      it must carry the boot-mode magic, or the return value is -1 and
      port_start skips `sata_mt85xx_xfer_int_ldr_fw` (0x32fc `bne`).

The block does not come from the FE status registers at all: the FE is
expected to DMA it into the internal-loader DRAM window (base =
(*(u32*)0x7005c500 & 0xff) << 22, written by xfer_int_ldr_fw at 0x1940).
The model therefore has to place these bytes there when it posts message A.

Usage:
  fe_reply_bytes.py              # emit the reply table + run the selftest
  fe_reply_bytes.py --emit-c     # print the C snippet for emulator-kit/sony-bx510.c
  fe_reply_bytes.py --selftest   # selftest only (exit 0 == PASS)
"""

import argparse
import struct
import sys

# ---------------------------------------------------------------- the reply --
#
# bit16 of the interrupt/status register 0x7005c804: "an FE message is pending".
# The value is deliberately NOT sticky: with a message pending the read is
# 0x00010000, with the sequence drained it is 0x00000000, because the FE IRQ
# top half drains that register in a loop that only ends on a zero read
# (`svoif_mt85xx_interrupt` .text+0x34b4..0x34c8). A permanently non-zero read
# is the observed 4.4 GB `unimplemented write 0x7005c804 = 0x10000` storm.
FE_STATUS_PENDING = 0x00010000
FE_STATUS_IDLE = 0x00000000

# FE message sequence, one pair per `sata_mt85xx_chk_int_ldr` call. Each word is
# one 32-bit register read: 0x7005c040, c044, c048, c04c.
#   word0 = {byte3 = err/code, byte2 = message type, byte1..0 = unused by both
#            readers of this block (chk_int_ldr and the threaded FE handler)}
#   word1 = DRAM offset of the reply block  (source of the memcpy at 0x2938)
#   word2 = block length                    (clamped to 512 at 0x2924)
#   word3 = unused (read at 0x28d8, never read again)
FE_MSG_TABLE_DATA = 0x10   # byte2 == 16: "read my table block out of DRAM"
FE_MSG_STATUS = 0x00       # byte2 == 0, byte3 == 0: "inspect the block"

FE_MESSAGES = [
    # A: table-data offer. type 16 (0x2914), offset inside the FE DRAM window,
    # length 0x200 = the driver's own clamp (0x292c) and >= 0x102.
    (0x00 << 24 | FE_MSG_TABLE_DATA << 16 | 0x0000, 0x00001000, 0x00000200, 0x00000000),
    # B: status ready. type 0 and err 0 are both mandatory (0x28e0 / 0x28ec);
    # err is also the return value (0x29a0), so it must be 0 for chk to pass.
    (0x00 << 24 | FE_MSG_STATUS << 16 | 0x0000, 0x00000000, 0x00000000, 0x00000000),
]

FE_REPLY_OFF = FE_MESSAGES[0][1]     # 0x1000, the DRAM offset named in word1
FE_REPLY_LEN = FE_MESSAGES[0][2]     # 0x200, the length named in word2

# The 512-byte block the FE DMAs into DRAM at FE_REPLY_OFF. Only six bytes are
# ever inspected by the driver; everything else is filler.
#   VERIFIED-required  buf[0x2e..0x31] = 'O','B','T','O'   (0x29a4/0x29f8/0x2a04/0x2a10)
#   VERIFIED-required  buf[0x100..0x101] = 0xEE,0xEE       (LE16 == 0xeeee, 0x29b0)
#   INFERRED-filler    every other byte = 0
# The magic byte order is O,B,T,O and not "BOOT": the four compares are in that
# order, which is what a big-endian producer writing the 16-bit halfwords
# 'BO','OT' looks like through a little-endian read.
BOOT_MODE_BYTES = {0x2E: ord("O"), 0x2F: ord("B"), 0x30: ord("T"), 0x31: ord("O")}
MANUFACTURE_MODE_LEN = 0xEEEE


def build_reply_block():
    """The exact 512 bytes to DMA to FE DRAM window + FE_REPLY_OFF."""
    blk = bytearray(FE_REPLY_LEN)
    for off, val in BOOT_MODE_BYTES.items():
        blk[off] = val
    blk[0x100] = MANUFACTURE_MODE_LEN & 0xFF
    blk[0x101] = MANUFACTURE_MODE_LEN >> 8
    return bytes(blk)


# ------------------------------------------------------------------ replay --
#
# A faithful replay of sata_mt85xx_chk_int_ldr's decision structure, written
# against the instruction addresses so every branch below is citable. It takes
# the model's reply (status messages + DRAM contents + register value) and
# produces the same (return value, *out) pair the driver would produce.
class DriverVerdict(object):
    def __init__(self, rc, out, log):
        self.rc = rc          # r4 at 0x2908: 0 = accepted, -1 = rejected
        self.out = out        # *arg1 (port+0x208) when written, else None
        self.log = log        # strings the driver would printk


def replay_chk_int_ldr(messages, dram, status_reg_reads, guard_iterations=64):
    """Replay the driver against one answer set.

    messages           -- list of 4-word tuples, consumed in order
    dram               -- dict {offset: bytes} standing for *svoif_int_ldr_dram
    status_reg_reads   -- iterable of 0x7005c804 read values
    """
    log = []
    polled = [v & FE_STATUS_PENDING for v in status_reg_reads]
    if not any(polled):
        # 0x2890..0x28a0: 200 x msleep(10) -> 0x297c "wait status interrupt timeout !"
        return DriverVerdict(-1, None, ["wait status interrupt timeout !"])

    buf = bytearray(1320)        # 0x2820: kmem_cache_alloc, NOT zeroed
    for _ in range(guard_iterations):
        if not messages:
            # The driver would spin at 0x2880 forever waiting for the next
            # message; a bounded reply set must always end on message B.
            return DriverVerdict(None, None, ["<driver spins waiting for a message>"])
        w0, w1, w2, w3 = messages[0]
        messages = messages[1:]
        b2 = (w0 >> 16) & 0xFF   # 0x28c4 ldrb r2,[r8,#2]
        b3 = (w0 >> 24) & 0xFF   # 0x28e4 ldrb r2,[r8,#3]

        if b2 != 0:
            if b2 != FE_MSG_TABLE_DATA:        # 0x2914 cmp r2,#16 / 0x2918 bne 0x2880
                return DriverVerdict(None, None, ["<driver re-polls on unknown message type>"])
            n = min(w2, 0x200)                 # 0x2924..0x292c
            src = dram.get(w1)
            if src is None:
                return DriverVerdict(None, None, ["<no DRAM block at word1>"])
            n = min(n, len(src))
            buf[0:n] = src[0:n]                # 0x2960 memcpy(buf, dram + w1, n)
            log.append("send_table_data_ack_cmd")   # 0x2968
            continue                           # 0x296c/0x2974: b2 != 0 -> 0x2880

        if b3 != 0:                            # 0x28e8 beq 0x299c
            log.append("Command Error !!(0x%02x, 0x%06x)" % (b3, w1))   # 0x2a64
            return DriverVerdict(-1, None, log)

        # ---- 0x299c: the acceptance gate on the copied block ----
        rc = b3                                # 0x29a0 mov r4,r2  (r2 == b3 == 0)
        if buf[0x2F] != 0x42:                  # 0x29a4
            rc = -1                            # 0x29ac
        elif not (buf[0x2E] == 0x4F            # 0x29f8
                  and buf[0x31] == 0x4F        # 0x2a04
                  and buf[0x30] == 0x54):      # 0x2a10
            rc = -1
        else:
            log.append("Internal loader boot code mode")     # 0x2a28
        length = buf[0x100] | (buf[0x101] << 8)              # 0x29b0..0x29b8
        if length != MANUFACTURE_MODE_LEN:                   # 0x29c0
            return DriverVerdict(rc, 0, log)                 # 0x29c4..0x29d0
        log.append("----- Loader is in manufacture mode !! -----")   # 0x2a34
        return DriverVerdict(rc, 1, log)                     # 0x29e4..0x29f0

    return DriverVerdict(None, None, ["<replay guard exhausted>"])


# ---------------------------------------------------------------- selftest --
CHECKS = []


def check(what, cond, cite):
    CHECKS.append((what, bool(cond), cite))
    return cond


def selftest():
    del CHECKS[:]
    block = build_reply_block()
    dram = {FE_REPLY_OFF: block}

    # -- 1. the poll gate: bit16 present while a message is pending -----------
    check("0x7005c804 pending read has bit16",
          FE_STATUS_PENDING & 0x10000,
          ".text+0x28ac tst r6,#65536")
    check("0x7005c804 drained read is 0 (FE IRQ drain loop terminates)",
          FE_STATUS_IDLE == 0,
          ".text+0x34bc cmp r3,#0 / 0x34c8 bne (svoif_mt85xx_interrupt)")

    # -- 2. message A is a well-formed table-data offer ----------------------
    w0, w1, w2, w3 = FE_MESSAGES[0]
    check("message A type byte == 16", (w0 >> 16) & 0xFF == 16,
          ".text+0x2914 cmp r2,#16")
    check("message A length covers buf[0x2e..0x31] and buf[0x100..0x101]",
          min(w2, 0x200) >= 0x102,
          ".text+0x2924 cmp r3,#512 / 0x2928 movlo (short copy = silent *out=0)")
    check("message A offset has a DRAM block behind it", w1 in dram,
          ".text+0x2938 add r6,r6,r0 (dram + word1)")

    # -- 3. message B is an error-free status ---------------------------------
    w0b = FE_MESSAGES[1][0]
    check("message B type byte == 0", (w0b >> 16) & 0xFF == 0,
          ".text+0x28d0 cmp r2,#0 / 0x28e0 bne")
    check("message B err byte == 0 (also the return value)", (w0b >> 24) & 0xFF == 0,
          ".text+0x28e8 cmp r2,#0 / 0x29a0 mov r4,r2")

    # -- 4. the block itself, byte by byte -----------------------------------
    check("block[0x2f] == 'B'", block[0x2F] == 66, ".text+0x29a4 cmp r3,#66")
    check("block[0x2e] == 'O'", block[0x2E] == 79, ".text+0x29f8 cmp r3,#79")
    check("block[0x31] == 'O'", block[0x31] == 79, ".text+0x2a04 cmp r3,#79")
    check("block[0x30] == 'T'", block[0x30] == 84, ".text+0x2a10 cmp r3,#84")
    check("LE16(block[0x100]) == 0xeeee",
          (block[0x100] | (block[0x101] << 8)) == 0xEEEE,
          ".text+0x29b0 ldrb/ldrb/add r2,r3,r2,lsl #8 / 0x29c0 cmp")
    check("no byte outside the inspected set is non-zero",
          sorted(i for i, b in enumerate(block) if b) == [0x2E, 0x2F, 0x30, 0x31, 0x100, 0x101],
          "minimality: 0x299c..0x2a20 is the only reader of the block")

    # -- 5. behavioural replay: the driver's own verdict ---------------------
    v = replay_chk_int_ldr(list(FE_MESSAGES), dram, [FE_STATUS_PENDING, FE_STATUS_PENDING])
    check("replay returns 0 (chk_int_ldr accepted)", v.rc == 0, ".text+0x2908 mov r0,r4")
    check("replay sets *out = 1", v.out == 1, ".text+0x29e8 mov r3,#1 / 0x29ec str")
    check("replay takes the table-data path then the gate",
          v.log == ["send_table_data_ack_cmd", "Internal loader boot code mode",
                    "----- Loader is in manufacture mode !! -----"],
          ".text+0x2968 / 0x2a28 / 0x2a34 printks")

    # -- 6. mutants: each must be caught ------------------------------------
    # m1: a fresh (un-zeroed, here zero-filled) kmalloc buffer, i.e. the model
    #     as it stands today: no table-data message, nothing in the block.
    v1 = replay_chk_int_ldr([FE_MESSAGES[1]], {}, [FE_STATUS_PENDING])
    check("mutant: no table-data message -> rejected", v1.rc == -1 and v1.out == 0,
          ".text+0x29ac mvn r4,#0")
    # m2: magic one byte early
    bad = bytearray(block)
    bad[0x2D], bad[0x2E], bad[0x2F], bad[0x30] = bad[0x2E], bad[0x2F], bad[0x30], bad[0x31]
    bad[0x31] = 0
    v2 = replay_chk_int_ldr(list(FE_MESSAGES), {FE_REPLY_OFF: bytes(bad)}, [FE_STATUS_PENDING])
    check("mutant: magic shifted by one byte -> rejected", v2.rc == -1, ".text+0x29a4")
    # m3: the naive ASCII order "BOOT" at 0x2e must FAIL (O,B,T,O is required)
    bad3 = bytearray(block)
    bad3[0x2E:0x32] = b"BOOT"
    v3 = replay_chk_int_ldr(list(FE_MESSAGES), {FE_REPLY_OFF: bytes(bad3)}, [FE_STATUS_PENDING])
    check("mutant: literal 'BOOT' order -> rejected", v3.rc == -1, ".text+0x29f8/0x2a04")
    # m4: the two length floors. 0x32 still satisfies the return code (the
    # BOOT magic is all it needs) but loses *out = 1; below 0x32 the magic is
    # outside the copy and chk rejects.
    short = FE_MESSAGES[0][0], FE_MESSAGES[0][1], 0x32, 0
    v4 = replay_chk_int_ldr([short, FE_MESSAGES[1]], dram, [FE_STATUS_PENDING])
    check("mutant: length 0x32 -> rc 0 but *out 0 (degraded variant)",
          v4.rc == 0 and v4.out == 0, ".text+0x29c4 strne r3,[r2]")
    shorter = FE_MESSAGES[0][0], FE_MESSAGES[0][1], 0x31, 0
    v4b = replay_chk_int_ldr([shorter, FE_MESSAGES[1]], dram, [FE_STATUS_PENDING])
    check("mutant: length 0x31 leaves the magic outside the copy -> rejected",
          v4b.rc == -1, ".text+0x2924 clamp + 0x29a4")
    # m5: a type byte that is neither 0 nor 16 re-polls forever (the storm loop)
    bad5 = (0x00030000, 0, 0, 0)
    v5 = replay_chk_int_ldr([bad5, FE_MESSAGES[1]], dram, [FE_STATUS_PENDING])
    check("mutant: unknown type byte -> driver never terminates", v5.rc is None,
          ".text+0x2918 bne 0x2880")
    # m6: bit16 never observed -> 200 x 10 ms timeout, return -1
    v6 = replay_chk_int_ldr(list(FE_MESSAGES), dram, [FE_STATUS_IDLE])
    check("mutant: no bit16 -> timeout, rejected", v6.rc == -1,
          ".text+0x289c/0x28a0 -> 0x297c")

    width = max(len(w) for w, _, _ in CHECKS)
    ok = True
    for what, passed, cite in CHECKS:
        print("  %-*s  %s   (%s)" % (width, what, "PASS" if passed else "FAIL", cite))
        ok = ok and passed
    print("\n%d checks, %d failed -> %s"
          % (len(CHECKS), sum(1 for _, p, _ in CHECKS if not p), "PASS" if ok else "FAIL"))
    return ok


# -------------------------------------------------------------------- emit --
def emit_table():
    print("FE status reply — words to program into the model")
    print("=" * 72)
    print("read 0x7005c804 while a message is pending : 0x%08x" % FE_STATUS_PENDING)
    print("read 0x7005c804 when drained               : 0x%08x" % FE_STATUS_IDLE)
    for i, (w0, w1, w2, w3) in enumerate(FE_MESSAGES):
        name = "A (table data request)" if i == 0 else "B (status ready)"
        print("\nmessage %s" % name)
        for reg, w in zip((0x40, 0x44, 0x48, 0x4C), (w0, w1, w2, w3)):
            print("  read 0x7005c0%02x = 0x%08x   bytes %s"
                  % (reg, w, " ".join("%02x" % b for b in struct.pack("<I", w))))
    blk = build_reply_block()
    print("\nblock to DMA to FE DRAM window + 0x%04x (%d bytes)" % (FE_REPLY_OFF, len(blk)))
    nz = [(i, b) for i, b in enumerate(blk) if b]
    print("  non-zero bytes only: %s"
          % ", ".join("[0x%02x]=0x%02x" % (i, b) for i, b in nz))
    print("  everything else 0x00")


def emit_c():
    blk = build_reply_block()
    print("/* decode/fe-status-handshake.md — FE internal-loader status mailbox.")
    print(" * Generated by decode/fe_reply_bytes.py; the driver-side proofs are cited")
    print(" * in that document (.text+0x28a4..0x2a38 of sata_mt85xx_chk_int_ldr). */")
    print("#define FE_REPLY_OFF  0x%04xu   /* word1 of message A */" % FE_REPLY_OFF)
    print("#define FE_REPLY_LEN  0x%04xu   /* word2 of message A */" % FE_REPLY_LEN)
    print("#define FE_STATUS_BIT16 0x%08xu" % FE_STATUS_PENDING)
    print("static const uint32_t fe_msg_words[%d][4] = {" % len(FE_MESSAGES))
    for i, words in enumerate(FE_MESSAGES):
        body = ", ".join("0x%08xu" % w for w in words)
        tail = ("  /* A: type 16, DRAM block offered */" if i == 0
                else "  /* B: type 0, err 0 */")
        print("    { %s },%s" % (body, tail))
    print("};")
    print("static const uint8_t fe_reply_block[FE_REPLY_LEN] = {")
    for row in range(0, len(blk), 16):
        print("    " + " ".join("0x%02x," % b for b in blk[row:row + 16]))
    print("};")
    print("""
/* mailbox: 0x5c000..c00c = 16-byte command block, 0x5c020 bit0 = doorbell,
 *          0x5c040..c04c = status block, 0x5c804 bit16 = "message pending".
 * The command block uses the same byte layout: byte3 = code, byte2 = type.
 *   chk_int_ldr entry  : word0 byte3 = 0xa1 (port->[0x29c], .text+0x2858)
 *   table-data ack     : word0 byte2 = 0x10 (.text+0x3c58)
 * Sequence: on the 0xa1 doorbell set fe_msg = 0; on the 0x10 doorbell advance
 * fe_msg. 0x5c804 reads bit16 while fe_msg < 2, and 0 once drained (the FE IRQ
 * top half loops until a zero read at .text+0x34bc).
 * Posting message A also has to place fe_reply_block at
 *   phys = ((*(u32*)0x7005c500 & 0xff) << 22) + FE_REPLY_OFF
 * (the window page number the driver hands the FE at .text+0x1940); skip the
 * write when 0x5c500 has never been programmed rather than scribbling low RAM. */""")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--emit-c", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.emit_c:
        emit_c()
        return 0
    emit_table()
    print("\nselftest (replays the driver's own compares)")
    print("-" * 72)
    return 0 if selftest() else 1


if __name__ == "__main__":
    sys.exit(main())
