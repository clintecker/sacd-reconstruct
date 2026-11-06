/*
 * mt8560-hdhost.h — HDHOST: synthetic read-only host-image interface
 * for the player.local machine. See docs/large-image-interface.md.
 * SPDX-License-Identifier: GPL-2.0-or-later
 */
#ifndef MT8560_HDHOST_H
#define MT8560_HDHOST_H

#include "exec/memory.h"

#define HDHOST_BASE      0x70020000u
#define HDHOST_SIZE      0x1000u
#define HDHOST_MAGIC_VAL 0x48444853u   /* 'SHDH' */
#define HDHOST_MAX_COUNT 128u         /* sectors per transaction (== MAX_PROCESSING_BLOCK_SIZE) */
#define HDHOST_SECT_SIZE 2048u

/* status codes (read from CMD/STATUS) */
#define HDHOST_ST_OK     0u
#define HDHOST_ST_OOB    1u           /* out of bounds: sector+count > capacity, or count invalid */
#define HDHOST_ST_IOERR  2u           /* host I/O error or guest DMA error */

typedef struct Mt8560Hdhost {
    MemoryRegion regs;
    int fd;                  /* host image, O_RDONLY */
    uint64_t cap_sect;       /* capacity in 2048-byte sectors */
    uint32_t sector_lo, sector_hi;
    uint32_t count;
    uint32_t buf_lo, buf_hi;
    uint32_t status;
    uint8_t bounce[HDHOST_MAX_COUNT * HDHOST_SECT_SIZE];
} Mt8560Hdhost;

/* Open the host image read-only and map the register page. Errors are
 * fatal: a configured HDHOST that cannot open its image must not boot
 * into a silently-absent device. */
void mt8560_hdhost_init(Mt8560Hdhost *h, Object *owner, const char *path);

#endif
