/*
 * bx510_hdhost.c — HDHOST guest block driver (Sony BX510 guest kernel).
 *
 * Exposes the HDHOST MMIO read-only host-image device (see
 * docs/large-image-interface.md; QEMU side: mt8560-hdhost.c) as a Linux
 * block device. The queue is serialized under the request lock; each
 * transaction carries an explicit 64-bit LSN (no shared seek position)
 * and at most 128 sectors (= the daemon's MAX_PROCESSING_BLOCK_SIZE).
 * Hardsect size is 2048 bytes so the block layer speaks the device's
 * LSN units natively. Writes are rejected with EIO — the device is
 * read-only by construction. Out-of-bounds and host I/O errors surface
 * as EIO: missing data must never become a successful zero-filled read.
 *
 * Build: the proven guest-module pipeline (Sony GPL 2.6.35 tree,
 * mediatek_defconfig, SMP off, -march=armv6, vermagic token patch).
 * No exported symbols, so no bdpswap tail-marker step is needed.
 */
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/spinlock.h>
#include <linux/fs.h>
#include <linux/blkdev.h>
#include <linux/bio.h>
#include <linux/genhd.h>
#include <linux/io.h>

#define HD_BASE        0x70020000ul
#define HD_REG_SIZE    0x1000u
#define HD_SECT_SIZE   2048u
#define HD_MAX_COUNT   128u
#define HD_MAGIC       0x48444853u

/* register offsets (must mirror mt8560-hdhost.c) */
#define HD_SECTOR_LO   0x00u
#define HD_SECTOR_HI   0x04u
#define HD_COUNT       0x08u
#define HD_BUF_LO      0x0cu
#define HD_BUF_HI      0x10u
#define HD_CAP_LO      0x14u
#define HD_CAP_HI      0x18u
#define HD_CMD         0x1cu
#define HD_MAGIC_OFF   0x20u

#define HD_ST_OK       0u
#define HD_ST_OOB      1u
#define HD_ST_IOERR    2u

static void __iomem *hd_regs;
static int hd_major;
static spinlock_t hd_lock;
static struct request_queue *hd_queue;
static struct gendisk *hd_disk;

static inline void hd_wr(u32 off, u32 v)
{
    writel(v, hd_regs + off);
}

static inline u32 hd_rd(u32 off)
{
    return readl(hd_regs + off);
}

static u64 hd_capacity_sect(void)
{
    u32 lo = hd_rd(HD_CAP_LO);
    u32 hi = hd_rd(HD_CAP_HI);
    return ((u64)hi << 32) | lo;
}

/* one transaction: explicit LSN, bounded count, guest phys buffer */
static int hd_xfer(u64 lsn, u32 count, u64 buf)
{
    hd_wr(HD_SECTOR_LO, (u32)lsn);
    hd_wr(HD_SECTOR_HI, (u32)(lsn >> 32));
    hd_wr(HD_COUNT, count);
    hd_wr(HD_BUF_LO, (u32)buf);
    hd_wr(HD_BUF_HI, (u32)(buf >> 32));
    wmb();
    hd_wr(HD_CMD, 0);          /* doorbell: command 0 = READ */
    return (int)hd_rd(HD_CMD);  /* synchronous device: status on read */
}

static void do_hd_request(struct request_queue *q)
{
    struct request *req;
    int err = 0;

    while ((req = blk_fetch_request(q)) != NULL) {
        struct bio *bio;

        if (rq_data_dir(req) != READ) {
            /* read-only device: writes cannot be served */
            __blk_end_request_all(req, -EIO);
            continue;
        }
        err = 0;
        __rq_for_each_bio(bio, req) {
            struct bio_vec *bvec;
            int i;

            /* bio->bi_sector is in 512-byte units (verified against
             * this kernel's fs/block_dev.c: i_size = capacity << 9).
             * HDHOST LSNs are 2048-byte units: all I/O here is
             * 2048-aligned by construction (page cache and the daemon
             * both operate at LSN granularity), so a misaligned bio is
             * a bug to surface, not to round. */
            if (bio->bi_sector & 3) {
                err = -EIO;
                goto end_req;
            }
            bio_for_each_segment(bvec, bio, i) {
                sector_t lsn = bio->bi_sector >> 2;
                u32 done = 0;

                if (bvec->bv_len % HD_SECT_SIZE ||
                    (bvec->bv_offset + done) % HD_SECT_SIZE) {
                    err = -EIO;
                    goto end_req;
                }
                while (done < bvec->bv_len) {
                    u64 phys = page_to_phys(bvec->bv_page) +
                               bvec->bv_offset + done;
                    u32 remain = (bvec->bv_len - done) / HD_SECT_SIZE;
                    u32 n = remain > HD_MAX_COUNT ? HD_MAX_COUNT : remain;
                    int st = hd_xfer(lsn, n, phys);

                    if (st != HD_ST_OK) {
                        err = -EIO;
                        goto end_req;
                    }
                    lsn += n;
                    done += n * HD_SECT_SIZE;
                }
            }
        }
end_req:
        __blk_end_request_all(req, err);
    }
}

static int hd_open(struct block_device *bdev, fmode_t mode)
{
    return 0;
}

static int hd_release(struct gendisk *gd, fmode_t mode)
{
    return 0;
}

static struct block_device_operations hd_fops = {
    .owner = THIS_MODULE,
    .open = hd_open,
    .release = hd_release,
};

static int __init hd_init(void)
{
    u64 cap;
    int rc;

    hd_regs = ioremap(HD_BASE, HD_REG_SIZE);
    if (!hd_regs)
        return -ENOMEM;
    if (hd_rd(HD_MAGIC_OFF) != HD_MAGIC) {
        printk(KERN_ERR "hdhost: no device magic at %#lx\n", HD_BASE);
        iounmap(hd_regs);
        return -ENODEV;
    }
    cap = hd_capacity_sect();
    if (!cap) {
        printk(KERN_ERR "hdhost: device reports zero capacity\n");
        iounmap(hd_regs);
        return -ENODEV;
    }

    hd_major = register_blkdev(0, "hdhost");
    if (hd_major <= 0) {
        iounmap(hd_regs);
        return -EBUSY;
    }

    spin_lock_init(&hd_lock);
    hd_queue = blk_init_queue(do_hd_request, &hd_lock);
    if (!hd_queue) {
        rc = -ENOMEM;
        goto out_unreg;
    }
    blk_queue_logical_block_size(hd_queue, HD_SECT_SIZE);
    /* transaction bound enforced per-chunk in do_hd_request (the queue
     * may split requests however it likes; each MMIO transaction is
     * independently <= 128 sectors) */

    hd_disk = alloc_disk(1);
    if (!hd_disk) {
        rc = -ENOMEM;
        goto out_queue;
    }
    hd_disk->major = hd_major;
    hd_disk->first_minor = 0;
    hd_disk->fops = &hd_fops;
    hd_disk->queue = hd_queue;
    strcpy(hd_disk->disk_name, "hdhost");
    set_capacity(hd_disk, cap * 4);  /* kernel-wide units are 512-byte
                                      * sectors (fs/block_dev.c: i_size =
                                      * capacity << 9); cap is in 2048-byte
                                      * LSNs, so x4 */
    add_disk(hd_disk);

    printk(KERN_INFO "hdhost: read-only host image, %llu sectors x %u bytes "
           "(major %d)\n", (unsigned long long)cap, HD_SECT_SIZE, hd_major);
    return 0;

out_queue:
    blk_cleanup_queue(hd_queue);
out_unreg:
    unregister_blkdev(hd_major, "hdhost");
    iounmap(hd_regs);
    return rc;
}

static void __exit hd_exit(void)
{
    if (hd_disk) {
        del_gendisk(hd_disk);
        put_disk(hd_disk);
    }
    if (hd_queue)
        blk_cleanup_queue(hd_queue);
    unregister_blkdev(hd_major, "hdhost");
    if (hd_regs)
        iounmap(hd_regs);
}

module_init(hd_init);
module_exit(hd_exit);

MODULE_DESCRIPTION("HDHOST read-only host-image block driver (BX510 guest)");
MODULE_LICENSE("GPL");
