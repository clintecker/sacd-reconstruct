/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef HW_ARM_MT8560_NFI_H
#define HW_ARM_MT8560_NFI_H
#include "exec/memory.h"
#include "hw/irq.h"
#include "hw/qdev-core.h"

typedef struct Mt8560Nfi {
    MemoryRegion regs, ecc;
    DeviceState *chip;
    qemu_irq irq;
    uint32_t cfg, page_fmt, control, irq_en, intr;
    uint32_t col, row, dma, cs, last_count, cmd;
    uint32_t fdm[32], ecc_cfg;
} Mt8560Nfi;
void mt8560_nfi_reset(Mt8560Nfi *n);
void mt8560_nfi_init(Mt8560Nfi *n, Object *owner, MemoryRegion *mem, qemu_irq irq);
#endif
