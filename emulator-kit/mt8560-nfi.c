/*
 * MT8560 NAND Flash Interface. Register map from Sony's GPL Linux 2.6.35
 * NFI2.h and NFIECC2.h. QEMU's NAND chip stores the actual page contents.
 * SPDX-License-Identifier: GPL-2.0-or-later
 */
#include "qemu/osdep.h"
#include "hw/block/flash.h"
#include "mt8560-nfi.h"
#include "exec/address-spaces.h"
#include "sysemu/blockdev.h"
#include "qemu/log.h"

#define NFI_BASE 0x7001e400u
#define ECC_BASE 0x7001ec00u
#define NAND_PAGE 2048u
#define NAND_OOB 64u

static void nfi_irq(Mt8560Nfi *n)
{
    qemu_set_irq(n->irq, !!(n->intr & n->irq_en));
}

static void nfi_bus_write(Mt8560Nfi *n, bool cle, bool ale, uint8_t value)
{
    nand_setpins(n->chip, cle, ale, n->cs != 0, 1, 1);
    nand_setio(n->chip, value);
}

static uint8_t nfi_bus_read(Mt8560Nfi *n)
{
    if (n->cs != 0) {
        return 0xff;
    }
    nand_setpins(n->chip, 0, 0, 0, 1, 1);
    return nand_getio(n->chip);
}

/* The machine model's own flag (BX510_TRACE=1) opens the NAND window too:
 * without it this MemoryRegion logs nothing and no page can be named from a
 * trace (decode/tagfix-mtd-trace.md §1 — 3.5 M lines, zero NFI accesses). */
static bool nfi_traced(void)
{
    static int traced = -1;

    if (traced < 0) {
        traced = getenv("BX510_TRACE") != NULL;
    }
    return traced;
}

static void nfi_transfer(Mt8560Nfi *n, bool writing)
{
    uint8_t data[NAND_PAGE + NAND_OOB];
    uint32_t sectors = (n->control >> 12) & 15;
    unsigned sector_bytes = (n->cfg & 0x20) ? 512 : 1024;
    unsigned size = sectors * sector_bytes;
    unsigned len;
    hwaddr addr = n->dma & 0x3fffffff;

    if (!size || size > NAND_PAGE || !(n->cfg & 1)) {
        qemu_log_mask(LOG_UNIMP, "mt8560-nfi: unsupported transfer cfg=%x ctrl=%x\n",
                      n->cfg, n->control);
        return;
    }
    bool automatic = n->cfg & 0x200;
    unsigned per_sector = NAND_OOB / sectors;
    unsigned metadata = MIN((n->page_fmt >> 6) & 31, MIN(per_sector, 16));
    MemTxResult tx;

    /* row/col are the address registers case 0x30 pushes to the chip, and
     * nand.c assembles them as addr = col | (row << 16) with
     * PAGE(addr) = addr >> ADDR_SHIFT (ADDR_SHIFT = 16 for the 2048-byte page
     * this board uses) — so the row register is the page the chip serves. The
     * chip's own s->addr is not reachable from here. */
    if (nfi_traced()) {
        if (writing) {
            qemu_log_mask(LOG_GUEST_ERROR,
                          "nfi-xfer: wr cfg=%x ctrl=%x sectors=%u size=%u dma=%x"
                          " aut=%u row=0x%x col=0x%x\n",
                          n->cfg, n->control, sectors, size, n->dma, automatic,
                          n->row, n->col);
        } else {
            qemu_log_mask(LOG_GUEST_ERROR,
                          "nfi-xfer: rd cfg=%x ctrl=%x sectors=%u size=%u dma=%x"
                          " aut=%u row=0x%x col=0x%x page=%u\n",
                          n->cfg, n->control, sectors, size, n->dma, automatic,
                          n->row, n->col, n->row);
        }
    }

    len = automatic ? size : size + NAND_OOB;
    if (writing) {
        tx = address_space_read(&address_space_memory, addr, MEMTXATTRS_UNSPECIFIED,
                                data, len);
        if (tx == MEMTX_OK) {
            for (unsigned i = 0; i < len; i++) {
                nfi_bus_write(n, false, false, data[i]);
            }
        }
    } else {
        for (unsigned i = 0; i < len; i++) {
            data[i] = nfi_bus_read(n);
        }
        tx = address_space_write(&address_space_memory, addr, MEMTXATTRS_UNSPECIFIED,
                                 data, len);
    }
    if (tx != MEMTX_OK) {
        qemu_log_mask(LOG_GUEST_ERROR, "mt8560-nfi: DMA failed at 0x%" HWADDR_PRIx "\n", addr);
        n->intr |= 0x20; /* access fault */
        nfi_irq(n);
        return;
    }
    if (automatic && size == NAND_PAGE) {
        for (unsigned i = 0; i < NAND_OOB; i++) {
            unsigned lane = i % per_sector;
            unsigned reg = (i / per_sector) * 4 + lane / 4;
            unsigned shift = (lane % 4) * 8;
            if (writing) {
                uint8_t v = lane < metadata ? n->fdm[reg] >> shift : 0xff;
                nfi_bus_write(n, false, false, v);
            } else {
                uint8_t v = nfi_bus_read(n);
                if (lane < metadata) {
                    n->fdm[reg] = (n->fdm[reg] & ~(0xffu << shift)) |
                                  ((uint32_t)v << shift);
                }
            }
        }
    }
    n->last_count = sectors;
    n->intr |= 0x40;
    nfi_irq(n);
}

static uint64_t nfi_read(void *opaque, hwaddr off, unsigned width)
{
    Mt8560Nfi *n = opaque;
    uint32_t data = 0;
    if (off >= 0x200 && off < 0x280) {
        return n->fdm[(off - 0x200) / 4];
    }
    switch (off) {
    case 0x00: return n->cfg;
    case 0x04: return n->page_fmt;
    case 0x08: return n->control;
    case 0x10: return n->irq_en;
    case 0x14: return n->intr;
    case 0x54:
        for (unsigned i = 0; i < width; i++) {
            data |= (uint32_t)nfi_bus_read(n) << (8 * i);
        }
        return data;
    case 0x60: return 0; /* command/address/data complete */
    case 0x64: return 0;
    case 0x70: case 0x84: return n->last_count << 12;
    case 0x80: return n->dma;
    case 0x90: return n->cs;
    default: return 0;
    }
}

static void nfi_write(void *opaque, hwaddr off, uint64_t val, unsigned width)
{
    Mt8560Nfi *n = opaque;
    unsigned i;
    if (off >= 0x200 && off < 0x280) {
        n->fdm[(off - 0x200) / 4] = val;
        return;
    }
    switch (off) {
    case 0x00: n->cfg = val; break;
    case 0x04: n->page_fmt = val; break;
    case 0x08:
        n->control = val;
        if (val & 0x100) {
            nfi_transfer(n, false);
        } else if (val & 0x200) {
            nfi_transfer(n, true);
        }
        break;
    case 0x10: n->irq_en = val; nfi_irq(n); break;
    case 0x14: n->intr &= ~val; nfi_irq(n); break;
    case 0x20:
        n->cmd = val;
        nfi_bus_write(n, true, false, val);
        if (val == 0xff) { n->intr |= 4; }
        if (val == 0x10) { n->intr |= 2; }
        if (val == 0xd0) { n->intr |= 8; }
        nfi_irq(n);
        break;
    case 0x30:
        for (i = 0; i < MIN(val & 15, 4); i++) {
            nfi_bus_write(n, false, true, n->col >> (8 * i));
        }
        for (i = 0; i < MIN((val >> 4) & 15, 4); i++) {
            nfi_bus_write(n, false, true, n->row >> (8 * i));
        }
        break;
    case 0x34:
        n->col = val;
        if (nfi_traced()) {
            qemu_log_mask(LOG_GUEST_ERROR, "nfi: col=0x%x\n", (unsigned)val);
        }
        break;
    case 0x38:
        n->row = val;
        if (nfi_traced()) {
            qemu_log_mask(LOG_GUEST_ERROR, "nfi: row=0x%x\n", (unsigned)val);
        }
        break;
    case 0x50:
        for (i = 0; i < width; i++) {
            nfi_bus_write(n, false, false, val >> (8 * i));
        }
        break;
    case 0x80: n->dma = val; break;
    case 0x90: n->cs = val; break;
    }
}

/* Error-free image transport. Real BCH error correction is not modeled. */
static uint64_t ecc_read(void *opaque, hwaddr off, unsigned width)
{
    Mt8560Nfi *n = opaque;
    switch (off) {
    case 0x0c: case 0x10c: return 1;
    case 0x104: return n->ecc_cfg;
    case 0x118: return (1u << n->last_count) - 1;
    default: return 0;
    }
}
static void ecc_write(void *opaque, hwaddr off, uint64_t val, unsigned width)
{
    Mt8560Nfi *n = opaque;
    if (off == 0x104) {
        n->ecc_cfg = val;
    }
}

static const MemoryRegionOps nfi_ops = {
    .read = nfi_read, .write = nfi_write, .endianness = DEVICE_LITTLE_ENDIAN,
};
static const MemoryRegionOps ecc_ops = {
    .read = ecc_read, .write = ecc_write, .endianness = DEVICE_LITTLE_ENDIAN,
};
void mt8560_nfi_reset(Mt8560Nfi *n)
{
    n->cfg = n->page_fmt = n->control = n->irq_en = n->intr = 0;
    n->col = n->row = n->dma = n->cs = n->last_count = n->cmd = n->ecc_cfg = 0;
    memset(n->fdm, 0xff, sizeof(n->fdm));
    nfi_irq(n);
}

void mt8560_nfi_init(Mt8560Nfi *n, Object *owner, MemoryRegion *mem, qemu_irq irq)
{
    DriveInfo *d = drive_get(IF_MTD, 0, 0);
    n->chip = nand_init(d ? blk_by_legacy_dinfo(d) : NULL, NAND_MFR_SAMSUNG, 0xda);
    n->irq = irq;
    memory_region_init_io(&n->regs, owner, &nfi_ops, n, "mt8560.nfi", 0x400);
    memory_region_init_io(&n->ecc, owner, &ecc_ops, n, "mt8560.ecc", 0x200);
    memory_region_add_subregion_overlap(mem, NFI_BASE, &n->regs, 1);
    memory_region_add_subregion_overlap(mem, ECC_BASE, &n->ecc, 1);
}
