#!/usr/bin/env python3
"""Decode BX510 interrupt routing: virq -> BIM register + bit.

Two independent halves, both read out of the binaries:

  A. Kernel side (BIM interrupt controller, arch/arm/mach-mt85xx).
     `mt85xx_init_irq` programs three pending/mask/clear register triples;
     `mt85xx_unmask_irq` / `mt85xx_mask_ack_irq` show the virq->group split;
     `__irq_svc` (the fast dispatcher installed by the `bim` chip) shows the
     virq formula (31 - clz, 63 - clz, 95 - clz, 127 - clz) and the cascade
     line (group-1 bit 20 == virq 52) into the secondary controller at
     0xfd024000 (+0x140 pending / +0x144 mask).

  B. Driver side (sata_mt85xx_mod.ko, ATAPI port + FE/SVOIF interface).
     The module registers its platform device with NO resources
     (platform_device_register_simple(name, id, NULL, 0)) and then calls
     ata_host_activate(host, irq = port_index + <imm>, ...) and
     disable_irq(port_index + <imm>).  The immediates are recovered from the
     instructions that feed those relocations, so the IRQ numbers are not
     transcribed from prose.

Usage: kernel_decode_irqmap.py [raw-image] [module.ko]
"""
import struct
import sys

from capstone import Cs, CS_ARCH_ARM, CS_MODE_ARM
from capstone.arm import ARM_REG_PC

TEXT_VA = 0xC0008000
RAW = sys.argv[1] if len(sys.argv) > 1 else "/tmp/kdec/vmlinux.bin"
MOD = sys.argv[2] if len(sys.argv) > 2 else "/tmp/bdpdrv/sata_mt85xx_mod.ko"
KSYM = "/tmp/kdec/kallsyms.txt"

md = Cs(CS_ARCH_ARM, CS_MODE_ARM)
md.detail = True


def kernel_syms():
    syms = []
    for line in open(KSYM):
        va, name = line.split(None, 1)
        syms.append((int(va, 16), name.strip()))
    syms.sort()
    return syms


def pool_loads(img, start, end):
    """{reg: value} for `ldr rX, [pc, #imm]` inside [start,end)."""
    out = {}
    for ins in md.disasm(img[start - TEXT_VA:end - TEXT_VA], start):
        if ins.mnemonic != "ldr" or len(ins.operands) != 2:
            continue
        mem = ins.operands[1]
        if mem.mem.base != ARM_REG_PC:
            continue
        pool = ins.address + 8 + mem.mem.disp
        out[ins.reg_name(ins.operands[0].reg)] = struct.unpack_from(
            "<I", img, pool - TEXT_VA)[0]
    return out


def str_offsets(img, start, end):
    """[(reg_base_name, byte_offset, source_reg)] for str/ldr [rB, #off]."""
    out = []
    for ins in md.disasm(img[start - TEXT_VA:end - TEXT_VA], start):
        if ins.mnemonic.split(".")[0] not in ("str", "ldr"):
            continue
        if len(ins.operands) != 2 or ins.operands[1].type != 3:
            continue
        mem = ins.operands[1]
        src = ins.reg_name(ins.operands[0].reg)
        out.append((ins.reg_name(mem.mem.base), mem.mem.disp, src,
                    ins.mnemonic))
    return out


def main():
    img = open(RAW, "rb").read()
    syms = kernel_syms()
    byname = {n: a for a, n in syms}
    order = [a for a, _ in syms]

    def span(name):
        a = byname[name]
        nxt = min([x for x in order if x > a], default=a + 0x400)
        return a, nxt

    # ---- A. BIM register groups -------------------------------------
    init_a, init_b = span("mt85xx_init_irq")
    pools = pool_loads(img, init_a, init_b)
    bim = {v for v in pools.values() if v >= 0xFD000000}
    assert bim == {0xFD008000}, "unexpected BIM base pools: %s" % \
        [hex(v) for v in bim]
    # Single pass: track register constants as they are set, then label each
    # store to a BIM offset with the value live at that point (a later
    # `mov r2,#0` in the same function must not rewrite history).
    masks, clears, regs = [], [], {}
    const = {}
    for ins in md.disasm(img[init_a - TEXT_VA:init_b - TEXT_VA], init_a):
        if ins.mnemonic in ("mov", "mvn") and ins.op_str.startswith("r") \
                and ", #" in ins.op_str:
            reg, imm = ins.op_str.split(", #")
            const[reg] = (int(imm, 0) if ins.mnemonic == "mov"
                          else (~int(imm, 0)) & 0xFFFFFFFF)
        elif ins.mnemonic == "str" and len(ins.operands) == 2 \
                and ins.operands[1].type == 3:
            mem = ins.operands[1]
            off = mem.mem.disp
            val = const.get(ins.reg_name(ins.operands[0].reg))
            regs[off] = val
            if val == 0:
                masks.append(off)
            elif val == 0xFFFFFFFF:
                clears.append(off)
    masks, clears = sorted(set(masks)), sorted(set(clears))
    print("BIM base (mt85xx_init_irq pool): 0x%08x  (PA 0x%08x)"
          % (0xFD008000, 0xFD008000 - 0x8D000000))
    print("  programmed with 0    (mask regs): %s"
          % ", ".join("+0x%03x" % o for o in masks))
    print("  programmed with ones (pend/clear): %s"
          % ", ".join("+0x%03x" % o for o in clears))
    pending = [0x30, 0x138, 0x154]
    print("  groups (pending/mask/clear): %s"
          % ", ".join("(0x%03x/0x%03x/0x%03x)" % (p, p + 4, p + 8)
                      for p in pending))

    unm_a, unm_b = span("mt85xx_unmask_irq")
    bounds = []
    for ins in md.disasm(img[unm_a - TEXT_VA:unm_b - TEXT_VA], unm_a):
        if ins.mnemonic in ("cmp", "sub") and ", #" in ins.op_str:
            try:
                imm = int(ins.op_str.split(", #")[-1], 0)
            except ValueError:
                continue
            if imm in (31, 32, 64, 96):
                bounds.append(imm)
    print("  group boundaries in mt85xx_unmask_irq: %s"
          % sorted(set(bounds)))
    sec = pool_loads(img, unm_a, unm_b)
    sec_vas = sorted({v for v in sec.values() if v >= 0xFD000000})
    print("  blocks touched by unmask: %s"
          % ", ".join("0x%08x(PA 0x%08x)" % (v, v - 0x8D000000)
                      for v in sec_vas))

    svc_a, svc_b = span("__irq_svc")
    fmt = []
    for ins in md.disasm(img[svc_a - TEXT_VA:svc_b - TEXT_VA], svc_a):
        if ins.mnemonic == "rsb" and "#" in ins.op_str:
            fmt.append(int(ins.op_str.split("#")[-1], 0))
    print("  virq formula constants in __irq_svc (31-clz, 63-clz, ...): %s"
          % fmt)
    svc_pools = sorted({v for v in pool_loads(img, svc_a, svc_b).values()
                        if v >= 0xFD000000})
    print("  dispatcher pools: %s"
          % ", ".join("0x%08x(PA 0x%08x)" % (v, v - 0x8D000000)
                      for v in svc_pools))

    # ---- B. driver IRQ numbers ---------------------------------------
    irqs = module_irqs()
    print("\nsata_mt85xx_mod.ko interrupt registrations:")
    for name, delta, site in irqs:
        print("  %-28s irq = port_index + %-3d  (%s)" % (name, delta, site))

    def describe(virq):
        if virq < 32:
            g, bit, pend, mask = 0, virq, 0x30, 0x34
        elif virq < 64:
            g, bit, pend, mask = 1, virq - 32, 0x138, 0x13C
        elif virq < 96:
            g, bit, pend, mask = 2, virq - 64, 0x154, 0x158
        else:
            g, bit, pend, mask = 3, virq - 96, 0x140, 0x144
            print("  virq %d -> secondary controller 0x%08x pending +0x%03x "
                  "bit %d (reached via BIM group-1 bit 20 == virq 52)"
                  % (virq, 0xFD024000, pend, bit))
            return
        print("  virq %d -> BIM group %d pending +0x%03x bit %d "
              "(mask +0x%03x bit %d, PA 0x%08x/0x%08x)"
              % (virq, g, pend, bit, mask, bit, 0x70008000 + pend,
                 0x70008000 + mask))

    print("\nmap the driver's lines onto the controller:")
    for delta in sorted({d for _, d, _ in irqs}):
        describe(delta)  # port_index 0 -> the base number


def module_irqs():
    """Recover port_index + imm feeding ata_host_activate / disable_irq."""
    from elftools.elf.elffile import ELFFile
    f = open(MOD, "rb")
    e = ELFFile(f)
    symtab = e.get_section_by_name(".symtab")
    out = []
    for sec in e.iter_sections():
        if not sec.name.startswith(".text") and sec.name != ".init.text":
            continue
        data = sec.data()
        relocs = []
        relsec = e.get_section_by_name(".rel" + sec.name)
        if relsec is None:
            continue
        for r in relsec.iter_relocations():
            sym = symtab.get_symbol(r["r_info_sym"]).name
            if sym in ("ata_host_activate", "disable_irq"):
                relocs.append((r["r_offset"], sym))
        for off, sym in relocs:
            # walk back for `add rX, rY, #imm` setting the irq argument
            prev = list(md.disasm(data[max(0, off - 24):off], off - 24))
            delta = None
            for ins in reversed(prev):
                if ins.mnemonic == "add" and len(ins.operands) == 3 \
                        and ins.reg_name(ins.operands[0].reg) == "r1" \
                        and ", #" in ins.op_str:
                    delta = int(ins.op_str.split("#")[-1], 0)
                    break
            if delta is not None:
                out.append((sym, delta, "%s+0x%x" % (sec.name, off)))
    return sorted(set(out))


main()
