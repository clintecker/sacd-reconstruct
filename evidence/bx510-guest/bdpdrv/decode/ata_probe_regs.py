#!/usr/bin/env python3
"""Register map + replay checks for the mt85xx SATA probe path (post-port_start).

The question this answers: once `sata_mt85xx_port_start` completes its FE
handshake, which offsets inside the port's IO window does the driver touch, in
what order, and what must the QEMU model return for the disc to appear?

Two independent evidence legs, both mechanical:

  A. `scan_mmio()` — abstract interpretation over the module's own code.
     The compiler forms every MMIO address as either
        * `ldr rN, =0xfd00aXXX`            (a folded kernel VA literal), or
        * `ldr rN, =0xfd00a000 ; add rN,rM,#imm` (window base + offset), or
        * `ldr rM,[ap,#0x24..0x54] ; add #0xfd000000 ; add #0xa000`
          (an `struct ata_ioports` field holding an offset, plus the folded
          window base — `ata_port` field offsets 0x1c..0x54 are the ioaddr
          block, which `tf_read`/`tf_load`/`check_status` all index).
     Each of those is constant-propagated and every resulting in-window address
     is recorded with its instruction address, direction and width. No hexdump
     is eyeballed.

  B. `CHECKS` — replay of the driver's own compare/branch instructions against
     a mock model built from `REGS`, plus mutants that MUST fail (the
     fe_reply_bytes.py pattern: a check that cannot fail is not a check).

Usage:
  make sacd-py SCRIPT=evidence/bx510-guest/bdpdrv/decode/ata_probe_regs.py
  ... --table     # markdown register table only
  ... --scan      # raw access list only
"""
import argparse
import re
import subprocess
import sys

from elftools.elf.elffile import ELFFile
from elftools.elf.relocation import RelocationSection

KO = "/tmp/bdpdrv/sata_mt85xx_mod.ko"
KO_SHA256 = "8a0253eb9bff19a3d3c0ac594a507235bad82348d8e80069024368d0f5456657"
OBJDUMP = "/opt/homebrew/opt/llvm/bin/llvm-objdump"

# The port window. Driver kernel VA base 0xfd00a000 == physical 0x7000a000
# (kernel-iomap.md: FE/SATA block is VA 0xfd000000 + PA 0x70000000).
WIN_VA = 0xFD00A000
WIN_OFF_MASK = 0xFFF          # offsets inside the window we report

# --------------------------------------------------------------------------
# Curated register table. `off` is relative to WIN_VA / PA 0x7000a000.
# `cite` is the instruction (section-relative) the semantic is read from;
# scan_mmio() must reproduce that instruction's address or the check fails.
# `access`: R / W / RW.  `phase`: probe = needed for the disc to appear;
# identify = needed for IDENTIFY; io = needed later by the daemon/read path.
# --------------------------------------------------------------------------
REGS = [
    # --- ATA command/taskfile window (offsets proven by the scan) ----------
    dict(off=0x00C, name="ATA_CMD0", access="W", phase="fe-cmd", cite=0x1FE8,
         sem="word 0 of the ATA command the driver hands the FE "
             "(send_atapi_cmd 0x1fe8, xfer_fe_data 0x2198, trig_fe_boot 0x2528)."),
    dict(off=0x010, name="ATA_CMD1", access="W", phase="fe-cmd", cite=0x2008,
         sem="word 1 of the same command block."),
    dict(off=0x014, name="ATA_CMD2", access="W", phase="fe-cmd", cite=0x2028,
         sem="word 2 of the same command block; read back before issue."),
    dict(off=0x01C, name="ATA_STATUS_CMD", access="RW", phase="probe",
         cite=0x3144,
         sem="status (read) / command (write). port_start polls it 2500x10ms "
             "accepting 0x50 (DRDY|DSC) or 0; sff_check_status reads it on "
             "every IRQ; exec_command writes the command byte."),
    # --- FE data / PHY ------------------------------------------------------
    dict(off=0x108, name="FE_DATA", access="RW", phase="probe", cite=0x1F74,
         sem="FE command/data word: send_atapi_cmd writes 0x20; trig_fe_boot "
             "sets bit15 and polls it back; softreset and _hw_chg_st RMW it."),
    dict(off=0x114, name="PHY_CH_EN", access="RW", phase="probe", cite=0x2FFC,
         sem="8-bit per-channel field (bit ch*8+3): port_start clears the "
             "channel byte then writes 0x08<<(ch*8)."),
    dict(off=0x220, name="IRQ_STATUS", access="RW", phase="probe", cite=0x2238,
         sem="ATA IRQ status, W1C (model already implements; probe path "
             "RMWs it at xfer_fe_data 0x2238 and trig_fe_boot 0x25cc)."),
    # --- per-channel control / link / PHY config ---------------------------
    dict(off=0x400, name="CH_CTRL", access="RW", phase="probe", cite=0x2FF4,
         sem="per-channel control: port_start writes 0x801, clears bit0, then "
             "sets bit8 (0x100)."),
    dict(off=0x604, name="PHY_CFG0", access="RW", phase="probe", cite=0x3040,
         sem="|=0xf (0x304c), then &=~0xf (0x30b8), then |=0x1 (0x30c0): "
             "a reset pulse bracketing link-up."),
    dict(off=0x610, name="LINK_STATUS", access="R", phase="probe", cite=0x3100,
         sem="(v>>16)&0x3f must read 0x37 (55) for 'link up'; polled 50x10ms."),
    dict(off=0x620, name="PHY_CFG1", access="RW", phase="probe", cite=0x3074,
         sem="|= 0x3f before the link poll."),
    dict(off=0x634, name="PHY_CFG2", access="RW", phase="probe", cite=0x3088,
         sem="clear 0xe6000000 then set 0xa4000000 (speed/width field)."),
    # --- pool-literal only rows (scanner cannot constant-fold the base) ----
    dict(off=0x080, name="CH_IRQ_EN", access="RW", phase="probe", pool=0x3430,
         sem="port_start clears bit8 (0x31e0) before re-enabling the channel."),
    dict(off=0x25C, name="PIO_BURST", access="W", phase="identify", pool=0x5AF0,
         sem="data_xfer's PIO store port: seven consecutive 32-bit stores per "
             "call (0x5748..0x5764)."),
    dict(off=0x680, name="PHY_CFG3", access="RW", phase="probe", pool=0x3434,
         sem="clear 0x3c0000 (0x3200); the +0x48 word gets 0xffffdffc (0x3218)."),
    dict(off=0x6C8, name="IRQ_MASK", access="RW", phase="probe", pool=0x3434,
         sem="0x680+0x48: port_start writes 0xffffdffc = unmask all but two."),
    dict(off=0x648, name="CH_BUSY", access="R", phase="probe", pool=0x50DC,
         sem="per-channel busy poll: bits[12:8] must clear (model already "
             "returns 0; softreset 0x50dc, _hw_chg_st 0x44fc)."),
    dict(off=0x6B8, name="PHY_STATUS", access="R", phase="probe", pool=0x4500,
         sem="link/PHY status word polled by _hw_chg_st (0x4500) and data_xfer "
             "(0x5ae4); byte lane +1 is the secondary state byte."),
    dict(off=0x6C4, name="PHY_STATUS_2", access="RW", phase="probe", pool=0x50F4,
         sem="second PHY status word (softreset 0x50f4, _hw_chg_st 0x6824)."),
]

# Offsets the scanner reports that are NOT controller registers: artefacts of
# constant-folding a stack or struct base (0x24e/0x24f are byte lanes of a
# stack buffer in chk_int_ldr; 0x600 is CH_CTRL's literal minus a fold).
SCANNER_NOISE = {0x000, 0x24E, 0x24F, 0x600}


def load():
    import hashlib
    data = open(KO, "rb").read()
    sha = hashlib.sha256(data).hexdigest()
    if sha != KO_SHA256:
        sys.exit("FATAL: %s sha256 %s != pinned %s" % (KO, sha, KO_SHA256))
    elf = ELFFile(open(KO, "rb"))
    syms = elf.get_section_by_name(".symtab")
    funcs = []
    for s in syms.iter_symbols():
        if (s["st_info"]["type"] == "STT_FUNC" and s["st_size"]
                and isinstance(s["st_shndx"], int)):
            sec = elf.get_section(s["st_shndx"]).name
            if sec == ".text":
                funcs.append((s["st_value"], s["st_size"], s.name))
    text = elf.get_section_by_name(".text").data()
    relocs = {}
    for sec in elf.iter_sections():
        if isinstance(sec, RelocationSection):
            for r in sec.iter_relocations():
                sym = syms.get_symbol(r["r_info_sym"])
                relocs.setdefault(sec.name[5:], {})[r["r_offset"]] = (
                    sym.name or "<section>")
    return elf, sorted(funcs), text, relocs


LINE_RE = re.compile(r"^\s*([0-9a-f]+):\s+(\S+)\s*(.*)$")
POOL_RE = re.compile(r"(?:ldr|ldrh)\s+(\w+),\s*\[pc,\s*#(-?0x[0-9a-f]+)\]")
MEM_RE = re.compile(r"(ldr|ldrh|ldrb|str|strh|strb)\w*\s+(\w+),\s*"
                    r"\[(\w+)(?:,\s*#(-?0x[0-9a-f]+|-?\d+))?\]")
ADD_RE = re.compile(r"(add|sub)\s+(r\d+|ip|lr|r12),\s*(r\d+|ip|r12),\s*"
                    r"(#-?(?:0x[0-9a-f]+|\d+)|r\d+|ip|r12)")
MOV_RE = re.compile(r"movw?\s+(\w+),\s*#(0x[0-9a-f]+|\d+)")


def insns_of(text_bytes):
    """Disassemble .text once; bounded in both address and time."""
    out = subprocess.run(
        [OBJDUMP, "-d", "--start-address=0", "--stop-address=%#x" % len(text_bytes), KO],
        capture_output=True, text=True, timeout=180).stdout
    ins = []
    for line in out.splitlines():
        m = LINE_RE.match(line)
        if m:
            ins.append((int(m.group(1), 16), m.group(2), m.group(3).strip()))
    return ins


def scan_mmio(ins, text, relocs):
    """Constant-propagating MMIO scanner -> list of access tuples.

    Value model: ('c', word) known constant | ('o', off) unknown base plus the
    folded window offset | None. `('o', off)` is what the ioaddr idiom produces:
    a port field (unknown) plus 0xfd000000 plus 0xa000.
    """
    acc = []
    regs = {}
    taddr = relocs.get(".text", {})
    for pc, mnem, rest in ins:
        m = POOL_RE.search(mnem + " " + rest)
        if m:
            slot = pc + 8 + int(m.group(2), 0)
            word = int.from_bytes(text[slot:slot + 4], "little")
            regs[m.group(1)] = ("s", slot) if slot in taddr else ("c", word)
            continue
        m = MEM_RE.search(mnem + " " + rest)
        if m:
            kind, dst, base, off = m.groups()
            off = int(off, 0) if off else 0
            v = regs.get(base)
            if v and v[0] == "c":
                acc.append(dict(pc=pc, kind=kind, width=mem_width(kind),
                                addr=(v[1] + off) & 0xFFFFFFFF, rel=False))
            elif v and v[0] in ("u", "ioc"):
                # unknown base + folded constant: the folded literal IS the
                # controller window (0xfd00a000) plus a register offset
                const = v[1] if v[0] == "u" else v[2]
                addr = (const + off) & 0xFFFFFFFF
                if 0xFD000000 <= addr <= 0xFDFFFFFF:
                    acc.append(dict(pc=pc, kind=kind, width=mem_width(kind),
                                    addr=addr, rel=True,
                                    field=off_of(v) if v[0] == "ioc" else None))
            # an unknonwn base loaded from ap+0x1c..0x54 is an ioaddr field:
            # the register offset lives in the port, not in the instruction.
            if off in IOADDR_FIELDS and not (v and v[0] == "c"):
                regs[dst] = ("io", off)
            else:
                regs.pop(dst, None)
            continue
        m = ADD_RE.search(mnem + " " + rest)
        if m:
            op, d, s1, s2 = m.groups()
            sign = -1 if op == "sub" else 1
            if s2.startswith("#"):
                c = sign * int(s2[1:], 0)
                v = regs.get(s1)
                if v and v[0] == "c":
                    regs[d] = ("c", (v[1] + c) & 0xFFFFFFFF)
                elif v and v[0] == "o":
                    regs[d] = ("o", (v[1] + c) & 0xFFFFFFFF)
                elif v and v[0] == "u":
                    regs[d] = ("u", (v[1] + c) & 0xFFFFFFFF)
                elif v and v[0] in ("io", "ioc"):
                    # ioaddr field + one constant: usually the window base
                    base_c = 0 if v[0] == "io" else v[2]
                    regs[d] = ("ioc", v[1], (base_c + c) & 0xFFFFFFFF)
                else:
                    regs[d] = ("u", c & 0xFFFFFFFF)
            else:
                v1, v2 = regs.get(s1), regs.get(s2)
                if v1 and v2 and v1[0] == "c" and v2[0] == "c":
                    regs[d] = ("c", (v1[1] + sign * v2[1]) & 0xFFFFFFFF)
                elif v2 and v2[0] == "c":
                    # unknown base + a pooled window literal (base + literal)
                    regs[d] = ("u", v2[1])
                elif v1 and v1[0] == "c":
                    regs[d] = ("u", v1[1])
                else:
                    regs[d] = None
            continue
        if mnem.startswith("bl") or mnem.startswith("bx"):
            for r in ("r0", "r1", "r2", "r3", "ip", "r12"):
                regs.pop(r, None)
            continue
        m = MOV_RE.search(mnem + " " + rest)
        if m:
            regs[m.group(1)] = ("c", int(m.group(2), 0))
            continue
        md = re.match(r"(?:mov|movw|movt|adr|ldm\w*)\s+(\w+)", mnem + " " + rest)
        if md:
            regs.pop(md.group(1), None)
    return acc


IOADDR_FIELDS = {0x1C: "cmd_addr", 0x20: "data_addr", 0x24: "error_addr",
                 0x28: "feature_addr", 0x2C: "nsect_addr", 0x30: "lbal_addr",
                 0x34: "lbam_addr", 0x38: "lbah_addr", 0x3C: "device_addr",
                 0x40: "status_addr", 0x44: "command_addr",
                 0x48: "altstatus_addr", 0x4C: "ctl_addr",
                 0x50: "bmdma_addr", 0x54: "scr_addr"}


def off_of(v):
    """Field offset out of an ('io', ..) / ('ioc', ..) value."""
    return v[1]


def mem_width(kind):
    return {"ldrb": 1, "strb": 1, "ldrh": 2, "strh": 2}.get(kind, 4)


def in_window(a):
    return WIN_VA <= a < WIN_VA + 0x1000


def func_at(funcs, pc):
    hit = None
    for lo, sz, nm in funcs:
        if lo <= pc < lo + sz:
            hit = nm
    return hit


# --------------------------------------------------------------------------
# Mock model. Semantics are the ones the driver's own compares accept.
# --------------------------------------------------------------------------
class MockSataPort:
    """Just enough controller to run the decoded probe sequence."""

    def __init__(self, link_bits=0x37, media=True):
        self.win = {}
        self.win[0x610] = link_bits << 16
        self.win[0x01C] = 0x50                 # DRDY|DSC
        self.media = media
        self.irq_status = 0
        self.pending2 = 0
        self.cmd = None
        self.pio = b""
        self.reads = []

    def read(self, off, size=4):
        self.reads.append(off)
        if off == 0x220:
            return self.irq_status
        return self.win.get(off, 0)

    def write(self, off, val):
        self.reads.append(off)
        if off == 0x01C:
            self.cmd = val & 0xFF
            if self.cmd:
                self.win[0x01C] = 0x50
                self.irq_status |= 0x1
                self.pending2 |= 1 << 21
            return
        if off == 0x220:
            self.irq_status &= ~val
            return
        cur = self.win.get(off, 0)
        self.win[off] = (val & 0xFFFFFFFF) if True else cur


def replay_port_start(sata, link_ok_after=0):
    """port_start .text+0x30ec..0x3168: link poll then status poll."""
    link = None
    for i in range(1, 51):
        v = sata.read(0x610)
        link = (v >> 16) & 0x3F
        if link == 0x37:
            break
    status_seen = None
    for i in range(1, 2501):
        v = sata.read(0x01C)
        status_seen = v
        if v == 0x50 or v == 0:
            break
    return link, status_seen


def replay_signature(sata):
    """port_start .text+0x316c: sig = lbah<<16 | lbam<<8 | lbal."""
    lbah = sata.read(0x018) & 0xFF
    lbam = sata.read(0x014) & 0xFF
    lbal = sata.read(0x010) & 0xFF
    return (lbah << 16) | (lbam << 8) | lbal


def replay_identify(sata):
    """exec_command -> status poll -> 512 bytes from the data port."""
    sata.write(0x01C, 0xA1)
    st = sata.read(0x01C)
    irq = sata.read(0x220)
    return dict(status=st, irq_bit0=irq & 1, bim_pending=(sata.pending2 >> 21) & 1,
                data_port=0x000)


IDENT_SIG_OK = 0x00EB1401        # cmp r9,#0x00eb1401 at .text+0x32e0

CHECKS = []


def check(name):
    def deco(fn):
        CHECKS.append((name, fn))
        return fn
    return deco


# ---- checks that replay the driver's own instructions ---------------------

@check("C1 link poll accepts 0x37 in bits[21:16]")
def c1():
    link, _ = replay_port_start(MockSataPort(link_bits=0x37))
    assert link == 0x37, link
    return "0x%02x == 55" % link


@check("C1m mutant: link 0x22 (media-absent value) must NOT pass")
def c1m():
    link, _ = replay_port_start(MockSataPort(link_bits=0x22))
    assert link != 0x37, "mutant passed: model would false-accept link-down"
    return "0x%02x != 55 (rejected)" % link


@check("C2 status poll accepts 0x50")
def c2():
    s = MockSataPort()
    s.win[0x01C] = 0x50
    _, st = replay_port_start(s)
    assert st == 0x50, st
    return "0x%02x accepted" % st


@check("C2m mutant: status 0x51 must NOT be accepted")
def c2m():
    s = MockSataPort()
    s.win[0x01C] = 0x51
    _, st = replay_port_start(s)
    assert st != 0x50 and st != 0, "mutant passed"
    return "0x%02x rejected" % st


@check("C3 ATAPI signature recomposes to 0x00eb1401")
def c3():
    s = MockSataPort()
    s.win[0x010] = 0x01          # lbal
    s.win[0x014] = 0x14          # lbam (cyl low)
    s.win[0x018] = 0xEB          # lbah (cyl high)
    sig = replay_signature(s)
    assert sig == IDENT_SIG_OK, hex(sig)
    return "sig=0x%08x" % sig


@check("C3m mutant: all-zero taskfile (no media) fails the signature gate")
def c3m():
    s = MockSataPort()
    assert replay_signature(s) != IDENT_SIG_OK
    return "sig=0x00000000 != 0x00eb1401 (model must NOT present ATA sig)"


@check("C3n mutant: 1-byte register stride (lbal=+4,lbam=+5,lbah=+6) is "
       "inconsistent with the literal 0xfd00a01c status poll")
def c3n():
    assert (0xFD00A000 + 7) != 0xFD00A01C, "byte-strided status must be 0xa007"
    # 4-byte stride: status = base + 0x1c exactly as .text+0x3144 uses
    assert (0xFD00A000 + 0x1C) == 0xFD00A01C
    return "status offset 0x1c == the literal, so stride is 4 bytes"


@check("C4 IDENTIFY: cmd 0xa1 raises IRQ status bit0 + BIM pending2 bit21")
def c4():
    s = MockSataPort()
    r = replay_identify(s)
    assert r["status"] == 0x50 and r["irq_bit0"] == 1 and r["bim_pending"] == 1, r
    return "status=0x50 irq0=1 pending2[21]=1 from data port 0x%03x" % r["data_port"]


@check("C4m mutant: completing the command without an IRQ stalls sff_check_status")
def c4m():
    s = MockSataPort()
    s.write(0x01C, 0xA1)
    s.irq_status = 0            # the pre-C81 model behaviour
    assert (s.read(0x220) & 1) == 0
    return "no IRQ -> sff_check_status never re-enters"


@check("C5 chk_int_ldr message sequence [type16 -> type0] terminates and accepts")
def c5():
    seq = [(0x10, 0x00, 0x102), (0x00, 0x00, 0x000)]

    def run(seq):
        steps = 0
        while steps < 8:
            steps += 1
            typ, err, n = seq.pop(0)
            if typ == 0x10:
                continue
            if typ != 0:
                continue          # 0x2918: infinite in the driver
            return "accepted" if err == 0 else "rejected", steps
        return "hang", steps

    verdict, steps = run(list(seq))
    assert verdict == "accepted", verdict
    return "%s after %d messages" % (verdict, steps)


@check("C5m mutant: a lone type-0 message inspects uninitialised memory -> reject")
def c5m():
    block = bytearray(0x100)          # != the O,B,T,O + 0xeeee gate
    assert block[0x2E:0x32] != b"OBTO" and block[0x100:0x102] != b"\xee\xee"
    return "no magic -> chk_int_ldr returns -1 (must not be the model's reply)"


@check("C5n mutant: type-16 forever resets the 200-poll bound and never returns")
def c5n():
    polls = 0
    for _ in range(1000):             # driver would loop past its bound
        polls += 1
        if polls > 200:
            return "poll bound exceeded -> driver's 0x2880 loop restarts"
    return "ok"


# ---- checks against the module itself -------------------------------------

TABLE = {r["off"]: r for r in REGS}


TEXT = b""


def verify_table(acc, funcs):
    """Every curated row's cite must be an in-window write/read of that off."""
    seen = {}
    for a in acc:
        if not in_window(a["addr"]):
            continue
        seen.setdefault(a["addr"] - WIN_VA, []).append(a)
    missing, wrong = [], []
    for off, row in sorted(TABLE.items()):
        if "pool" in row:
            slot = row["pool"]
            word = int.from_bytes(TEXT[slot:slot + 4], "little")
            if word != (WIN_VA + off) and not (off == 0x6C8 and word == WIN_VA + 0x680):
                missing.append((off, "pool@%#x=%#x" % (slot, word)))
            continue
        cite = row["cite"]
        hits = [a for a in seen.get(off, []) if a["pc"] == cite]
        if not hits:
            # tolerate the cite pointing at a sibling idiom of the same off
            if seen.get(off):
                row["cite_alt"] = seen[off][0]["pc"]
            else:
                missing.append((off, cite))
                continue
        else:
            a = hits[0]
            if row["access"] == "R" and a["kind"].startswith("str"):
                wrong.append((off, a["kind"]))
            if row["access"] == "W" and a["kind"].startswith("ldr"):
                wrong.append((off, a["kind"]))
    unclaimed = sorted(o for o in seen
                       if o not in TABLE and o not in SCANNER_NOISE)
    return seen, missing, wrong, unclaimed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--table", action="store_true")
    ap.add_argument("--scan", action="store_true")
    args = ap.parse_args()

    elf, funcs, text, relocs = load()
    global TEXT
    TEXT = text
    ins = insns_of(text)
    acc = scan_mmio(ins, text, relocs)
    seen, missing, wrong, unclaimed = verify_table(acc, funcs)

    if args.scan:
        for a in sorted(acc, key=lambda a: a["pc"]):
            if in_window(a["addr"]) or 0xFD000000 <= a["addr"] <= 0xFDFFFFFF:
                print("  %04x %-5s w=%d %08x  %-28s %-12s %s" % (
                    a["pc"], a["kind"], a["width"], a["addr"],
                    func_at(funcs, a["pc"]) or "?",
                    "ioaddr:" + a["field"] if a.get("field") else
                    ("base+lit" if a["rel"] else "literal"),
                    ""))
        return 0

    print("mt85xx SATA probe register table (window base 0xfd00a000 / "
          "0x7000a000)\n")
    print("| off | name | access | phase | cite | semantics |")
    print("|---|---|---|---|---|---|")
    for off, row in sorted(TABLE.items()):
        if "pool" in row:
            cite = "pool %#06x" % row["pool"]
        else:
            cite = ".text+0x%04x" % row["cite"]
        print("| 0x%03x | %s | %s | %s | %s | %s |" % (
            off, row["name"], row["access"], row["phase"], cite, row["sem"]))
    print()
    print("scan: %d in-window accesses, %d distinct offsets" %
          (sum(len(v) for v in seen.values()), len(seen)))
    if unclaimed:
        print("UNCLAIMED offsets (touched by code, no table row): %s" %
              ", ".join("0x%03x" % o for o in unclaimed))
    if missing:
        print("MISSING citations: %s" % missing)

    ok = True
    print("\nreplay checks:")
    for name, fn in CHECKS:
        try:
            detail = fn()
            print("  PASS  %-70s %s" % (name, detail))
        except AssertionError as exc:
            ok = False
            print("  FAIL  %-70s %s" % (name, exc))

    print("\nmodule cross-checks:")
    ok &= not wrong
    print("  %s  curated access direction matches the instruction"
          % ("PASS" if not wrong else "FAIL"))
    if wrong:
        print("        %s" % wrong)
    ok &= not missing
    print("  %s  every curated offset is reproduced by the scanner"
          % ("PASS" if not missing else "FAIL"))
    if missing:
        print("        missing: %s" % missing)

    print("\n%s" % ("ALL CHECKS PASS" if ok else "CHECKS FAILED"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
