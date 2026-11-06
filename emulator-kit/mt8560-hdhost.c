/*
 * mt8560-hdhost.c — HDHOST: synthetic read-only host-image interface.
 *
 * A one-page MMIO block device for the sony-bx510 machine (design:
 * docs/large-image-interface.md in the sacd tree). QEMU opens the host
 * image O_RDONLY; the device has no write path at all. Each transaction
 * carries an explicit 64-bit sector (no shared seek position) and a
 * bounded sector count (<= 128, the daemon's MAX_PROCESSING_BLOCK_SIZE);
 * the doorbell write executes synchronously: bounds-check, pread from
 * the host file, DMA into guest RAM, set STATUS. Out-of-bounds and I/O
 * errors surface as status codes so the guest block driver propagates
 * EIO — missing data must never become a successful zero-filled read.
 *
 * Register map (32-bit accesses, LE):
 *   +0x00 SECTOR_LO   +0x04 SECTOR_HI   transaction target (LSN, 2048B units)
 *   +0x08 COUNT       sectors in this transaction, 1..128
 *   +0x0C BUF_LO      +0x10 BUF_HI      guest physical address of the transfer buffer
 *   +0x14 CAP_LO      +0x18 CAP_HI      (RO) capacity in sectors
 *   +0x1C CMD/STATUS  write: doorbell (value = command, 0 = READ);
 *                     read: status (bit0 busy — never set, the device is
 *                     synchronous; bits[3:1] reserved; code in bits[7:4])
 *   +0x20 MAGIC       (RO) 0x48444853 'SHDH'
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */
#include "qemu/osdep.h"
#include "qemu/error-report.h"
#include "exec/address-spaces.h"
#include "sysemu/dma.h"
#include "mt8560-hdhost.h"

enum {
    HD_SECTOR_LO = 0x00,
    HD_SECTOR_HI = 0x04,
    HD_COUNT     = 0x08,
    HD_BUF_LO    = 0x0c,
    HD_BUF_HI    = 0x10,
    HD_CAP_LO    = 0x14,
    HD_CAP_HI    = 0x18,
    HD_CMD       = 0x1c,
    HD_MAGIC     = 0x20,
};

static MemTxResult hdhost_dma(Mt8560Hdhost *h, uint64_t buf, uint32_t len)
{
    return dma_memory_write(&address_space_memory, buf, h->bounce, len,
                            MEMTXATTRS_UNSPECIFIED);
}

static void hdhost_execute(Mt8560Hdhost *h)
{
    uint64_t sector = ((uint64_t)h->sector_hi << 32) | h->sector_lo;
    uint64_t buf = ((uint64_t)h->buf_hi << 32) | h->buf_lo;
    uint32_t len;
    ssize_t n;

    if (h->count == 0 || h->count > HDHOST_MAX_COUNT) {
        h->status = HDHOST_ST_OOB;
        return;
    }
    if (sector > h->cap_sect || h->count > h->cap_sect - sector) {
        h->status = HDHOST_ST_OOB;
        return;
    }
    len = h->count * HDHOST_SECT_SIZE;
    n = pread(h->fd, h->bounce, len, (off_t)sector * HDHOST_SECT_SIZE);
    if (n != (ssize_t)len) {
        /* short read or host I/O error: EIO, never zero-fill */
        h->status = HDHOST_ST_IOERR;
        return;
    }
    if (hdhost_dma(h, buf, len) != MEMTX_OK) {
        h->status = HDHOST_ST_IOERR;
        return;
    }
    h->status = HDHOST_ST_OK;
}

static uint64_t hdhost_read(void *opaque, hwaddr offset, unsigned size)
{
    Mt8560Hdhost *h = opaque;

    switch (offset) {
    case HD_SECTOR_LO: return h->sector_lo;
    case HD_SECTOR_HI: return h->sector_hi;
    case HD_COUNT:     return h->count;
    case HD_BUF_LO:    return h->buf_lo;
    case HD_BUF_HI:    return h->buf_hi;
    case HD_CAP_LO:    return (uint32_t)h->cap_sect;
    case HD_CAP_HI:    return (uint32_t)(h->cap_sect >> 32);
    case HD_CMD:       return h->status;
    case HD_MAGIC:     return HDHOST_MAGIC_VAL;
    default:           return 0;
    }
}

static void hdhost_write(void *opaque, hwaddr offset, uint64_t val,
                         unsigned size)
{
    Mt8560Hdhost *h = opaque;

    switch (offset) {
    case HD_SECTOR_LO: h->sector_lo = (uint32_t)val; break;
    case HD_SECTOR_HI: h->sector_hi = (uint32_t)val; break;
    case HD_COUNT:     h->count = (uint32_t)val; break;
    case HD_BUF_LO:    h->buf_lo = (uint32_t)val; break;
    case HD_BUF_HI:    h->buf_hi = (uint32_t)val; break;
    case HD_CMD:
        /* doorbell: the write is the go signal; registers are only
         * interpreted at this moment (command 0 = READ — the only
         * command; the device is read-only by construction). */
        hdhost_execute(h);
        break;
    default: break;
    }
}

static const MemoryRegionOps hdhost_ops = {
    .read = hdhost_read,
    .write = hdhost_write,
    .endianness = DEVICE_LITTLE_ENDIAN,
    .impl = {
        .min_access_size = 4,
        .max_access_size = 4,
    },
};

void mt8560_hdhost_init(Mt8560Hdhost *h, Object *owner, const char *path)
{
    struct stat st;

    h->fd = open(path, O_RDONLY);
    if (h->fd < 0) {
        error_report("hdhost: cannot open host image '%s' read-only: %s",
                     path, strerror(errno));
        exit(1);
    }
    if (fstat(h->fd, &st) < 0) {
        error_report("hdhost: cannot stat host image '%s': %s",
                     path, strerror(errno));
        exit(1);
    }
    if ((uint64_t)st.st_size % HDHOST_SECT_SIZE) {
        error_report("hdhost: host image '%s' size %lld is not a multiple "
                     "of the %u-byte sector size",
                     path, (long long)st.st_size, HDHOST_SECT_SIZE);
        exit(1);
    }
    h->cap_sect = (uint64_t)st.st_size / HDHOST_SECT_SIZE;
    h->status = HDHOST_ST_OK;
    memset(h->bounce, 0, sizeof(h->bounce));
    memory_region_init_io(&h->regs, owner, &hdhost_ops, h,
                          "mt8560.hdhost", HDHOST_SIZE);
}
