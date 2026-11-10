/*
 * bx510_fbvirt.c — virtual framebuffer for the BX510 guest (the
 * "display-model" rung of the drawing-primitive work).
 *
 * The sony-bx510 QEMU machine has no display-controller model (and the
 * real display driver cannot load without the initrd's OSAL base), so
 * this module stands in for the MT85xx fbdev device the way bdpvirt
 * stands in for bdpdrv: it registers a STANDARD 2.6.35 framebuffer
 * (register_framebuffer -> /dev/fbN, major 29) backed by vmalloc'd RAM.
 * User space draws via the normal fbdev interface (open/mmap or write);
 * the pixels live in guest RAM where the probe can hash and downsample
 * them into the UART log. The real libdirectfb from the device's
 * rootfs can then be exercised against it with system=fbdev.
 *
 * Mode: 1920x1080, 32bpp (stride 7680), virtual 1920x2160 — MODE PARITY
 * with the player: fb0 on hardware reports 1920x1080 / stride 7680 /
 * virtual 1920x2160 (hw-session sysfs capture), so a rig at any other
 * geometry could not reproduce row-shear/pitch behavior. The rig must
 * advertise what the panel advertises. (Earlier: 1280x720, 32bpp XRGB — MODE PARITY with the player (2026-11-05): the
 * panel's layer is 1280x720 and DirectFB's primary comes back 1280x720, while
 * this module used to advertise 720x576. That mismatch hid every pitch/size bug
 * we hit on hardware (a 1280-wide surface over a 720-wide fbdev, lock pitch
 * 5120 vs 2880). The rig must advertise what the panel advertises.
 *
 * MT85xx vendor contract (this session's extension — see
 * bx510_fbvirt_mt85.h for the ABI and evidence/bx510-guest/graphics/
 * MT85-RESULTS.md for the demonstrated rungs): the same fbdev node now
 * also answers the 18 vendor requests the retail libdirectfb_mtk.so
 * issues, with three mmap classes (image pool / command ring / debug
 * info) dispatched by the published length conventions.
 *
 * Design choices (deliberate, documented):
 *
 * - ONE advertised mode: 720x576 @32bpp, identical in fb_var and fb_fix,
 *   identical to the pre-MT85 module so the raw-fbdev regression gate
 *   (fbdraw md5 7d19af14...) stays byte-stable. FBIO_INIT's requested
 *   mode (the provider passes 1280x720x4) is validated and accepted as
 *   a request, but the virtual device keeps advertising its single
 *   consistent mode; the provider never re-reads VSCREENINFO after INIT.
 *
 * - MT85 MULTI-POOL MODEL (the rung-(d) decode, 2026-11-04 session;
 *   full condition list in MT85-SEARCHPOOL-DECODE.md): the retail
 *   dfb_surfacemanager_allocate (0x40e0) dispatches on
 *   buffer->surface->config.caps & (DSCAPS_PRIMARY|DSCAPS_VIDEOONLY)
 *   == 5 — and EVERY primary layer region surface carries exactly
 *   those caps (published layer_context.c:1509 builds the layer
 *   surface with DSCAPS_VIDEOONLY|DSCAPS_PRIMARY). That branch
 *   computes num-2 and returns DR_TEMPUNAVAIL (26) if num < 2:
 *   primary/video-only surfaces may ONLY allocate from pools
 *   0..num-2. With the one-pool GETMULTIPOOL response the primary
 *   layer surface could NEVER allocate — which is why 8 MiB, 32 MiB
 *   and exact-fit pools all failed identically (the gate fires
 *   before any size comparison). The real MT85xx driver reports
 *   multiple memory slices (the ABI is named MULTI_MEM_POOL;
 *   FB_MEM_SLICE_NUM=4 in the retail revision), so num=2 is the
 *   minimal hardware-true topology: pool 0 is the slice primary/
 *   video-only surfaces allocate from, pool 1 is the "last" slice
 *   the retail skips for them (the retail allocate never reads
 *   type[]; its skip-last rule embodies the published IOMMU branch's
 *   "skip FBMT_VALLOC pools" rule, so pool 1 is declared VALLOC).
 *   Pool 0 is sized exactly one primary surface: pitch*height + 16
 *   bytes overrun slack per the core's dfb_gfxcard_calc_buffer_size
 *   (5120*720+16 = 3686416; the +16 prefetch slack is published-
 *   source, limits zeroed in no-hardware mode), page-aligned up to
 *   3690496 (901 pages) — mmap lengths are PAGE_ALIGN'd by the kernel before the
 *   vma exists, so a non-page-multiple size[i] can NEVER match the
 *   length dispatch (run5's lesson: the provider's first pool mmap
 *   came back EINVAL and its own "Could not mmap pool!" aborted
 *   init). The primary allocation carves from the END of the free
 *   chunk (offset = pool_size - alloc_length), which the rung-(e)
 *   capture's scan-locate turns into a length measurement of the
 *   retail core's calculated buffer size.
 *
 * - Selector lifetime: this 2.6.35 kernel's fb_ops carries NO struct
 *   file* into fb_ioctl or fb_mmap (verified in the Sony tree:
 *   fb_ioctl(info, cmd, arg); fb_mmap(info, vma)), so true per-open-file
 *   selector state is not reachable through the fbdev API. The model is
 *   therefore: FBIO_SETMMAPMETHOD validates + records the requested
 *   selector as a global cross-check, and fb_mmap dispatches by the
 *   published, collision-free length conventions (pool i is requested
 *   with exactly size[i] + i*0x1000; the ring with exactly the
 *   GETCMDBUFLEN value; debug info with exactly 4096). The retail
 *   provider's call sequence is strictly ordered on one fd and these
 *   lengths are unique per class here, so the observable behavior for
 *   the shipped provider is indistinguishable from per-fd selectors.
 *
 * - The command ring is mapped, bounded, and its WR_LOCK/UNLOCK/
 *   DISPATCHHW/CHECKFLUSH plumbing answers. Since the S3 contract decode
 *   (docs/mt85xx-fbdev-graphics-contract.md) DISPATCHHW is a REAL consumer:
 *   the retail gfxdriver's ring ioctls (0x4651 DISPATCHHW, 0x464d
 *   _mt85CheckFlush) drain the ring (Rd,Wr] in order and EXECUTE the items
 *   the contract pinned: cmd 0x191 (sync/flush marker, no-op) and cmd 0x01
 *   (rFill — fill rect into the vendor pool at the payload's dst phys).
 *   Unknown ids advance the ring and are logged (never EINVAL mid-ring —
 *   the gfxdriver would retry forever against a full ring). The published
 *   DISPATCHHW number 0x4653 shares the same consumer so both vendor
 *   revisions work.
 *
 * - Unknown request numbers stay -ENOTTY and get logged with their
 *   arguments: the log IS the discovery instrument.
 *
 * Build: the proven module pipeline (native-armv6 flags; no exports,
 * no bdpswap, no vermagic patch).
 */
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/errno.h>
#include <linux/fb.h>
#include <linux/init.h>
#include <linux/vmalloc.h>
#include <linux/mm.h>
#include <linux/io.h>
#include <linux/uaccess.h>

#include "bx510_fbvirt_mt85.h"

#define FBVIRT_XRES 1920
#define FBVIRT_YRES 1080
/* virtual geometry parity: hardware fb0 sysfs reports virtual 1920x2160.
 * fix.smem_len stays sized to the VISIBLE frame only — the raw-fbdev
 * regression gate (fbdraw full-frame md5) is byte-pinned to it and nothing
 * in the retail provider ever pans. */
#define FBVIRT_XVIRT 1920
#define FBVIRT_YVIRT 2160
#define FBVIRT_BPP  32

/* ---- MT85 virtual-device storage model ----
 *
 * TWO image pools (the retail allocate's primary/video-only gate
 * requires num >= 2 — see the rung-(d) decode in the header comment
 * and MT85-SEARCHPOOL-DECODE.md):
 *   pool 0 = one 1280x720 ARGB surface incl. the core's +16-byte
 *           overrun slack, PAGE-ALIGNED (the kernel rounds mmap
 *           lengths up to page multiples before the vma exists, so
 *           every size[] must be page-aligned or the length
 *           dispatch below never matches — run5's lesson);
 *   pool 1 = 16 MiB general slice (normal surfaces scan it FIRST:
 *           the retail checks m_avail[num-1] before any other pool),
 *           skipped for primary/video-only surfaces, VALLOC type.
 * The command ring is 512 KiB, debug info 4096 B — every mmap
 * length is distinct and page-aligned (pool0 8298496, pool1
 * 16781312 = size+0x1000, ring 524288, debug 4096, fbdev smem
 * 8294400) so the length dispatch below stays unambiguous.
 */
#define MT85_POOL0_SIZE     (1920u * 1080u * 4u + 0x1000u)  /* 8298496: pitch*height + one page — the module convention tools/bx510_fbdump.c --pool maps by (fbdump lesson: pool0 must equal exactly what the dump tool requests or the length dispatch never matches) */
#define MT85_POOL1_SIZE     (16u * 1024 * 1024)
#define MT85_CMDBUF_SIZE    (512u * 1024)
#define MT85_DEBUG_SIZE     4096u
/* Advertised physical-address namespaces, one per pool. CPU addr =
 * the userspace pool mmap base + offset; phys = these bases + offset.
 * The layer FBIO_SET(BASE) translation maps these namespaces back
 * onto the pool bytes. */
#define MT85_POOL0_PHYS     0x48000000u
#define MT85_POOL1_PHYS     0x4A000000u
/* Ring capacity in ITEMS and stride are RETAIL-VERIFIED (S3 contract §2):
 * items are 160 bytes (largest payload memcpy is 132 at item+8) and the
 * writer addresses slot (Wr+1) unwrapped, so the worst-case write ends at
 * 192 + 160*maxcount — capacity must be (ring_len - 192)/160. The old
 * 64-byte-item estimate (maxcount 8188) let the gfxdriver scribble ~1.3 MB
 * into the 512 KiB mmap = the provider SIGSEGV in the guest. */
#define MT85_RING_ITEM_SIZE 160u

static void *mt85_pool_mem;    /* vmalloc, MT85_POOL0_SIZE */
static void *mt85_pool1_mem;   /* vmalloc, MT85_POOL1_SIZE */
static void *mt85_cmdbuf_mem;  /* vmalloc, MT85_CMDBUF_SIZE */
static void *mt85_debug_mem;   /* vmalloc, MT85_DEBUG_SIZE */
static unsigned int mt85_selector = MT85_FB_MMAP_MEMPOOL;

/* per-plane layer state (FBIO_SET, masked); 3 OSD planes per the
 * provider's MT85_MAX_OSD_PLANE assert */
struct mt85_plane_state {
    unsigned int base;      /* last advertised phys base */
    unsigned int pitch;
    unsigned int cm;
    unsigned int w, h;
    unsigned int visible;
};
static struct mt85_plane_state mt85_planes[3];
static unsigned int mt85_plane_order[5] = { 3, 4, 5, 0, 1 };
static unsigned int mt85_osd_plane_order[5] = { 3, 4, 5, 0, 1 };

static struct fb_info *fbvirt_info;

/* ---- retail gfxdriver command-ring consumer (S3) -----------------
 *
 * Layout and handshake decoded from the retail libdirectfb_mt85.so
 * emitter (docs/mt85xx-fbdev-graphics-contract.md §2/§3; the arithmetic
 * was re-verified against the objdump listing before implementing):
 *   - ring header = mmap+32; maxcount@+0x04, RdPoint@+0x10, state@+0x30,
 *     WrPoint@+0x40, writer flag echo@+0x60;
 *   - items are 160 bytes; the writer writes slot (Wr+1) UNWRAPPED at
 *     mmap + 32 + 160*(Wr+1) (VERIFIED: add r11, r8, #1 / add r0, r7,
 *     r11, lsl #5 at 0x1028/0x1054), then stores Wr = (Wr+1) % maxcount
 *     — so slots live at addresses 160*1 .. 160*maxcount past the header
 *     and the mirror consumer reads the item after Rd at 160*(Rd+1),
 *     advancing Rd = (Rd+1) % maxcount. The consumer half is INFERRED
 *     (no kernel binary in hand); it is the only convention consistent
 *     with the writer's arithmetic (Wr==Rd empty, (Wr+1)%maxcount==Rd
 *     full, write-then-advance).
 */
#define MT85_RING_LOG_ITEMS 32u     /* per-item detail lines: first N only */
#define MT85_DSPF_ARGB      0x418c04u  /* retail provider DSPF table, VERIFIED */

static unsigned int mt85_items_logged;
static unsigned int mt85_dispatch_calls;
static unsigned int mt85_item_count[0x200];   /* per-command-id totals */

static unsigned int mt85_cmd_payload_bytes(unsigned int cmd)
{
    switch (cmd) {
    case 0x01: return 56;   /* rFill          */
    case 0x02: return 124;  /* rBitblt        */
    case 0x03: return 128;  /* rBitblt        */
    case 0x04: return 108;  /* OPEN           */
    case 0x0f: return 108;  /* rStretch       */
    case 0x15: return 132;  /* OPEN           */
    case 0x16: return 132;  /* rStretch       */
    case 0x1d: return 132;  /* OPEN           */
    case 0x27: return 128;  /* rFillBlend     */
    case 0x28: return 56;   /* rFill          */
    case 0x29: return 128;  /* rFillBlend     */
    case 0x2c: return 64;   /* rFill          */
    case 0x2d: return 72;   /* rFill          */
    case 0x2e: return 112;  /* rBitblt        */
    case 0x2f: return 120;  /* rStretch       */
    case 0x30: return 60;   /* rFillBlend     */
    case 0x31: return 132;  /* rStretch       */
    case 0x32: return 56;   /* OPEN           */
    case 0x34: return 128;  /* BlitPM         */
    case 0x35: return 128;  /* BlitBlendPM    */
    case 0x36: return 128;  /* StretchBlitPM  */
    case 0x38: return 128;  /* StretchBlendPM */
    case 0x3a: return 124;  /* rBitblt        */
    case 0x12e: return 108; /* OPEN           */
    case 0x191: return 0;   /* sync marker: cmd+flag only, NO memcpy */
    default:   return 0;
    }
}

/* rFill (cmd 0x01) — payload field map, EMPIRICALLY PINNED from the first
 * live retail item (s3-run2.log: dst=0x48465ff0 matches the module's own
 * FBIO_SET plane base, pitch=5120 and 1280x720 match the SET response, the
 * +0x30 word 0xff3099e0 matches the rung's SetColor, +0x34 = 0x12345678):
 *   +0x00 OPEN (0x174c0 observed — NOT the color; contract §3.2's
 *           "color at +0x00" is disproven by observation),
 *   +0x04 = 1, +0x08 = dst phys, +0x10/+0x14 = x/y, +0x18 = pitch,
 *   +0x20 = VENDOR format code from the gfxdriver's own DSPF→MT85 switch
 *   (VERIFIED literal pool: 0x418c04 DSPF_ARGB → 12; also 0x214612→11,
 *   0x4011040b→8, 0x200801→9, 0x211780→10), +0x28/+0x2c = w/h,
 *   +0x30 = ARGB color, +0x34 = 0x12345678 sentinel.
 * Executed insofar as it can be verified: magic, format and
 * destination-bounds checks gate every write; anything that fails a check
 * is logged and skipped, never guessed at. */
#define MT85_FMT_ARGVB   12u   /* vendor code for DSPF_ARGB, 4 B/px */
#define MT85_FILL_LOG_LIMIT 32u
static unsigned int mt85_fill_logs;
#define FILLLOG(args...) \
    do { if (mt85_fill_logs < MT85_FILL_LOG_LIMIT) { \
             mt85_fill_logs++; printk(KERN_INFO "fbvirt-mt85: rFill " args); } \
    } while (0)

static void mt85_exec_fill(const unsigned char *payload)
{
    const unsigned int *w = (const unsigned int *)payload;
    unsigned int dst_phys = w[2];   /* +0x08, VERIFIED vs FBIO_SET base */
    unsigned int x = w[4], y = w[5];        /* +0x10/+0x14 */
    unsigned int pitch = w[6];      /* +0x18, VERIFIED vs SET pitch */
    unsigned int fmt = w[8];        /* +0x20, vendor code */
    unsigned int width = w[10], height = w[11];  /* +0x28/+0x2c VERIFIED */
    unsigned int color = w[12];     /* +0x30, VERIFIED vs SetColor */
    unsigned int magic = w[13];     /* +0x34 = 0x12345678 sentinel */
    unsigned char *base;
    unsigned long avail, pooldst, rowoff;
    unsigned int row, col;

    if (magic != 0x12345678u) {
        FILLLOG("magic 0x%08x != 0x12345678 - skipped\n", magic);
        return;
    }
    if (fmt != MT85_FMT_ARGVB) {
        /* vendor codes other than 12 (ARGB4444/RGB16/ARGB1555/LUT8) have
         * no decoded color translation — log and skip, never guess */
        FILLLOG("fmt %u not vendor-ARGB(12) - skipped\n", fmt);
        return;
    }
    if (x > 8191u || y > 8191u || !width || width > 8192u
        || !height || height > 8192u) {
        FILLLOG("implausible rect %u,%u %ux%u - skipped\n", x, y, width,
                height);
        return;
    }
    if (!pitch || pitch < width * 4u) {
        FILLLOG("pitch %u < width %u*4 - skipped\n", pitch, width);
        return;
    }
    if (dst_phys >= MT85_POOL0_PHYS
        && dst_phys < MT85_POOL0_PHYS + MT85_POOL0_SIZE) {
        base = mt85_pool_mem;
        pooldst = dst_phys - MT85_POOL0_PHYS;
        avail = MT85_POOL0_SIZE - pooldst;
    } else if (dst_phys >= MT85_POOL1_PHYS
               && dst_phys < MT85_POOL1_PHYS + MT85_POOL1_SIZE) {
        base = mt85_pool1_mem;
        pooldst = dst_phys - MT85_POOL1_PHYS;
        avail = MT85_POOL1_SIZE - pooldst;
    } else {
        FILLLOG("dst 0x%08x outside both pools - skipped\n", dst_phys);
        return;
    }
    {
        /* one-line payload dump for the first fills: field semantics get
         * verified against the module's own SET-panel ground truth */
        char line[160];
        unsigned int i, len = 0;
        for (i = 0; i < 14 && len + 12 < sizeof(line); i++) {
            int add = snprintf(line + len, sizeof(line) - len, "%08x ",
                               w[i]);
            if (add > 0)
                len += add;
        }
        FILLLOG("payload %s\n", line);
    }
    FILLLOG("fill dst=0x%08x color=0x%08x %u,%u %ux%u pitch=%u fmt=%u\n",
            dst_phys, color, x, y, width, height, pitch, fmt);
    for (row = 0; row < height; row++) {
        unsigned char *q;
        /* rowoff is relative to the DESTINATION (avail is what remains of
         * the pool from dst on); never add the dst offset twice */
        rowoff = (unsigned long)(y + row) * pitch + (unsigned long)x * 4u;
        if (rowoff + (unsigned long)width * 4u > avail) {
            FILLLOG("row %u clips pool (off %lu + %u > %lu) - truncated\n",
                    row, rowoff, width * 4u, avail);
            break;
        }
        q = base + pooldst + rowoff;
        for (col = 0; col < width; col++) {
            /* byte stores: rowoff need not be 4-aligned and a kernel-mode
             * unaligned word access on this ARMv6 build is a fixup+warn,
             * not a silent write */
            q[0] = color & 0xff;
            q[1] = (color >> 8) & 0xff;
            q[2] = (color >> 16) & 0xff;
            q[3] = (color >> 24) & 0xff;
            q += 4;
        }
    }
}

/* drain the ring (Rd, Wr] in order, executing what the contract pinned;
 * unknown ids advance anyway (never EINVAL mid-ring — the gfxdriver's
 * full-ring path retries forever against an un-drained ring) */
static unsigned int mt85_ring_consume(const char *req)
{
    unsigned int max = *(unsigned int *)(mt85_cmdbuf_mem
                                         + MT85_RING_OFF_MAXCOUNT);
    unsigned int rd = *(unsigned int *)(mt85_cmdbuf_mem
                                         + MT85_RING_OFF_RDPOINT);
    unsigned int wr = *(unsigned int *)(mt85_cmdbuf_mem
                                         + MT85_RING_OFF_WRPOINT);
    unsigned int n = 0;

    /* rd/wr come from a userspace-writable MAP_SHARED header (retail never
     * writes RdPoint — contract §2.1 VERIFIED — but a buggy/hostile writer
     * must not send the kernel OOB outside the ring vmalloc region) */
    if (!max || rd >= max || wr >= max) {
        printk(KERN_INFO "fbvirt-mt85: %s ring indices out of range "
               "(max=%u rd=%u wr=%u) - consuming nothing\n", req, max, rd, wr);
        return 0;
    }
    while (rd != wr && n < max) {
        unsigned char *item = mt85_cmdbuf_mem + MT85_GFX_DRV_PREFIX_SIZE
                              + MT85_RING_ITEM_STRIDE * (rd + 1);
        unsigned int cmd = *(unsigned int *)item;
        unsigned int flag = *(unsigned int *)(item + 4);

        if (mt85_items_logged < MT85_RING_LOG_ITEMS) {
            mt85_items_logged++;
            printk(KERN_INFO "fbvirt-mt85: %s item[%u] cmd=0x%x flag=%u "
                   "(payload %u B)\n", req, n, cmd, flag,
                   mt85_cmd_payload_bytes(cmd));
        }
        if (cmd < 0x200u)
            mt85_item_count[cmd]++;
        if (cmd == 0x191u) {
            /* sync/flush marker {0x191, 1}: no payload, no-op (VERIFIED) */
        } else if (cmd == 0x01u) {
            mt85_exec_fill(item + 8);
        }
        rd = (rd + 1) % max;
        n++;
    }
    *(unsigned int *)(mt85_cmdbuf_mem + MT85_RING_OFF_RDPOINT) = rd;
    return n;
}

static void mt85_ring_dump_counts(void)
{
    char line[512];
    unsigned int i, len = 0;

    for (i = 0; i < 0x200u; i++)
        if (mt85_item_count[i]
            && len + 24 < sizeof(line)) {
            int add = snprintf(line + len, sizeof(line) - len,
                               " 0x%x=%u", i, mt85_item_count[i]);
            if (add > 0)
                len += add;
        }
    printk(KERN_INFO "fbvirt-mt85: ring items consumed by cmd:%s\n",
           len ? line : " (none)");
}

static int fbvirt_setcolreg(unsigned regno, unsigned red, unsigned green,
                            unsigned blue, unsigned transp,
                            struct fb_info *info)
{
    /* truecolor, no palette */
    return 0;
}

static int fbvirt_mmap(struct fb_info *info, struct vm_area_struct *vma)
{
    /* the classic vfb.c mapping: explicit vmalloc_to_pfn + one-page
     * remap_pfn_range steps (remap_vmalloc_range returned EINVAL on
     * this 2.6.35 armv6 build; the manual walk is version-proof) */
    unsigned long off = vma->vm_pgoff << PAGE_SHIFT;
    unsigned long pos = (unsigned long)info->screen_base + off;
    unsigned long len = vma->vm_end - vma->vm_start;
    void *which = NULL;

    if (off == 0) {
        /* MT85 vendor mapping classes — all at file offset 0, dispatched
         * by the retail-verified length conventions (retail pool-mmap
         * loop at 0x27b0-0x27d4 computes length = size[i] + i*0x1000):
         *   pool 0  requested with exactly size[0]      (+ 0*0x1000)
         *   pool 1  requested with exactly size[1]+0x1000
         *   ring    requested with exactly the GETCMDBUFLEN value
         *   debug   requested with exactly 4096 */
        if (len == MT85_POOL0_SIZE + 0 * 0x1000UL) {
            which = mt85_pool_mem;
            printk(KERN_INFO "fbvirt-mt85: mmap pool0 len=%lu "
                   "(selector=%u)\n", len, mt85_selector);
        } else if (len == MT85_POOL1_SIZE + 1 * 0x1000UL) {
            which = mt85_pool1_mem;
            printk(KERN_INFO "fbvirt-mt85: mmap pool1 len=%lu "
                   "(selector=%u)\n", len, mt85_selector);
        } else if (len == MT85_CMDBUF_SIZE) {
            which = mt85_cmdbuf_mem;
            printk(KERN_INFO "fbvirt-mt85: mmap gfxcmdbuf len=%lu "
                   "(selector=%u)\n", len, mt85_selector);
        } else if (len == MT85_DEBUG_SIZE) {
            which = mt85_debug_mem;
            printk(KERN_INFO "fbvirt-mt85: mmap debuginfo len=%lu "
                   "(selector=%u)\n", len, mt85_selector);
        }
    }
    if (which) {
        unsigned long vaddr = vma->vm_start;
        unsigned long p = (unsigned long)which;
        unsigned long remain = len;
        while (remain > 0) {
            unsigned long pfn = vmalloc_to_pfn((void *)p);
            if (remap_pfn_range(vma, vaddr, pfn, PAGE_SIZE,
                                vma->vm_page_prot))
                return -EAGAIN;
            vaddr += PAGE_SIZE;
            p += PAGE_SIZE;
            remain -= PAGE_SIZE;
        }
        return 0;
    }

    /* standard fbdev path unchanged: map screen_base at the requested
     * offset, bounded by smem_len (the raw-drawing regression gate).
     * A rejected mmap is LOGGED — an unmatched vendor length must be
     * visible in the module log, not a silent EINVAL (run5's lesson:
     * the pool mmap failure was invisible until the provider's own
     * "Could not mmap pool!" named it). */
    if (off + len > info->fix.smem_len) {
        printk(KERN_INFO "fbvirt-mt85: mmap REJECTED off=%lu len=%lu "
               "(matches no vendor class; smem_len=%u) -> EINVAL\n",
               off, len, info->fix.smem_len);
        return -EINVAL;
    }
    {
        /* local cursor: never mutate vma->vm_start (the zero-length
         * VMA left by the classic vfb mutation pattern gets torn down
         * by this kernel's mm core, zapping the PTEs -> SIGSEGV on
         * first access) */
        unsigned long vaddr = vma->vm_start;
        while (len > 0) {
            unsigned long pfn = vmalloc_to_pfn((void *)pos);
            if (remap_pfn_range(vma, vaddr, pfn, PAGE_SIZE,
                                vma->vm_page_prot))
                return -EAGAIN;
            vaddr += PAGE_SIZE;
            pos += PAGE_SIZE;
            len -= PAGE_SIZE;
        }
    }
    return 0;
}

/* ---- MT85xx vendor ioctl handler --------------------------------
 *
 * fbmem's do_fb_ioctl hands every non-standard request here with the
 * raw userspace arg. Every request is logged (first occurrence in
 * detail; unhandled codes with their args — the discovery instrument).
 */
static unsigned int mt85_seen_map[512];   /* request -> seen count, by bit */

static void mt85_log_req(unsigned int cmd)
{
    unsigned int idx = (cmd - 0x4620) >> 5;  /* 0x4620..0x493f buckets */

    if (cmd < 0x4620 || cmd > 0x493f)
        return;
    if (mt85_seen_map[idx] & (1u << (cmd & 31)))
        return;
    mt85_seen_map[idx] |= 1u << (cmd & 31);
    printk(KERN_INFO "fbvirt-mt85: first request 0x%x\n", cmd);
}

static int mt85_ioctl(struct fb_info *info, unsigned int cmd,
                      unsigned long arg)
{
    int ret = -ENOTTY;

    switch (cmd) {
    case MT85_FBIO_INIT: {
        struct fb_var_screeninfo var;
        if (copy_from_user(&var, (void __user *)arg, sizeof(var)))
            return -EFAULT;
        /* validate, do not adopt: the device advertises ONE consistent
         * mode (see header comment); the request is honored as a
         * no-op-with-validation so a broken caller is still visible */
        if (!var.xres || !var.yres || var.xres > 4096 || var.yres > 4096
            || var.bits_per_pixel != 32
            || var.xres_virtual < var.xres || var.yres_virtual < var.yres) {
            printk(KERN_INFO "fbvirt-mt85: FBIO_INIT REJECTED "
                   "%ux%u-%uvirt bpp=%u\n", var.xres, var.yres,
                   var.yres_virtual, var.bits_per_pixel);
            return -EINVAL;
        }
        mt85_log_req(cmd);
        printk(KERN_INFO "fbvirt-mt85: FBIO_INIT ok (requested "
               "%ux%u x%u virt, bpp %u; advertised mode stays "
               "%ux%u@%u)\n", var.xres, var.yres, var.yres_virtual,
               var.bits_per_pixel, FBVIRT_XRES, FBVIRT_YRES, FBVIRT_BPP);
        return 0;
    }
    case MT85_FBIO_GETIMAGEBUFFER: {
        struct mt85fb_imagebuffer ib;
        if (copy_from_user(&ib, (void __user *)arg, sizeof(ib)))
            return -EFAULT;
        ib.u4Size = MT85_POOL0_SIZE;
        ib.u4VirtAddr = 0;                 /* provider never reads it */
        ib.u4PhyAddr = MT85_POOL0_PHYS;
        if (copy_to_user((void __user *)arg, &ib, sizeof(ib)))
            return -EFAULT;
        mt85_log_req(cmd);
        printk(KERN_INFO "fbvirt-mt85: GETIMAGEBUFFER -> size=%u "
               "phys=0x%08x\n", ib.u4Size, ib.u4PhyAddr);
        return 0;
    }
    case MT85_FBIO_GETMULTIPOOL: {
        /* RETAIL layout (verified; see header): 88 bytes, four-entry
         * arrays, phys[0]@8, addr[0]@24 (caller overwrites with its
         * mmap), size[0]@40, type[0]@56, handle[0]@72.
         * TWO pools: the retail allocate's primary/video-only branch
         * (caps & 5 == 5 — every primary layer region surface) can
         * only use pools 0..num-2 and declines with TEMPUNAVAIL when
         * num < 2, so a one-pool answer made the primary layer
         * surface unallocatable (rung (d) blocker). */
        unsigned char mp[MT85_RETAIL_POOL_BYTES];
        unsigned int *mpw = (unsigned int *)mp;
        if (copy_from_user(mp, (void __user *)arg, sizeof(mp)))
            return -EFAULT;
        if (mpw[0] > MT85_RETAIL_POOL_SLICE_NUM) {
            printk(KERN_INFO "fbvirt-mt85: GETMULTIPOOL REJECTED "
                   "num=%u (> %d)\n", mpw[0], MT85_RETAIL_POOL_SLICE_NUM);
            return -EINVAL;
        }
        memset(mp, 0, sizeof(mp));
        mpw[0] = 2;                            /* num      */
        mpw[1] = 1;                            /* ref_num  */
        /* phys[] */
        mpw[MT85_RETAIL_MP_OFF_PHYS / 4 + 0] = MT85_POOL0_PHYS;
        mpw[MT85_RETAIL_MP_OFF_PHYS / 4 + 1] = MT85_POOL1_PHYS;
        /* addr[] left 0: userspace stores its mmap results there */
        /* size[] */
        mpw[MT85_RETAIL_MP_OFF_SIZE / 4 + 0] = MT85_POOL0_SIZE;
        mpw[MT85_RETAIL_MP_OFF_SIZE / 4 + 1] = MT85_POOL1_SIZE;
        /* type[]: nothing in the retail allocate reads it (verified in
         * the decode); pool 1 declared VALLOC to record the skip-last
         * convention the retail's primary/video-only branch embodies */
        mpw[MT85_RETAIL_MP_OFF_TYPE / 4 + 0] = MT85_FBMT_ONEZONE;
        mpw[MT85_RETAIL_MP_OFF_TYPE / 4 + 1] = MT85_FBMT_VALLOC;
        if (copy_to_user((void __user *)arg, mp, sizeof(mp)))
            return -EFAULT;
        mt85_log_req(cmd);
        printk(KERN_INFO "fbvirt-mt85: GETMULTIPOOL(0x%x retail) -> "
               "num=2 size[0]=%u phys[0]=0x%08x size[1]=%u "
               "phys[1]=0x%08x (88-byte retail struct)\n",
               cmd, MT85_POOL0_SIZE, MT85_POOL0_PHYS,
               MT85_POOL1_SIZE, MT85_POOL1_PHYS);
        return 0;
    }
    case MT85_FBIO_SETMMAPMETHOD: {
        unsigned int sel;
        if (copy_from_user(&sel, (void __user *)arg, sizeof(sel)))
            return -EFAULT;
        if (sel > MT85_FB_MMAP_DEBUGINFO) {
            printk(KERN_INFO "fbvirt-mt85: SETMMAPMETHOD REJECTED "
                   "selector=%u\n", sel);
            return -EINVAL;
        }
        mt85_selector = sel;
        mt85_log_req(cmd);
        printk(KERN_INFO "fbvirt-mt85: SETMMAPMETHOD -> %u "
               "(recorded as cross-check; mmap dispatches by length)\n",
               sel);
        return 0;
    }
    case MT85_FBIO_GETCMDBUFLEN: {
        /* retail number 0x464f (published 0x4651); the retail provider
         * stores this u32 and mmaps the ring with it */
        unsigned int len = MT85_CMDBUF_SIZE;
        if (copy_to_user((void __user *)arg, &len, sizeof(len)))
            return -EFAULT;
        mt85_log_req(cmd);
        printk(KERN_INFO "fbvirt-mt85: GETCMDBUFLEN(0x%x retail) -> %u\n",
               cmd, len);
        return 0;
    }
    case MT85_FBIO_RELCMDBUF:
        /* retail 0x4650 (published 0x4652): release of the command
         * ring; nothing is exclusively held in the virtual model, so
         * the release is trivially satisfied. Retail Uninit passes the
         * (already-munmapped) ring pointer as arg; never dereferenced.
         */
        mt85_log_req(cmd);
        printk(KERN_INFO "fbvirt-mt85: RELCMDBUF(0x%x retail, 0x%lx) -> 0 "
               "(no-op release; ring unmapped by caller first)\n", cmd,
               arg);
        return 0;
    case MT85_FBIO_GET: {
        struct mt85fb_get get;
        if (copy_from_user(&get, (void __user *)arg, sizeof(get)))
            return -EFAULT;
        if (get.get_type != MT85_GET_PANEL_SIZE) {
            printk(KERN_INFO "fbvirt-mt85: FBIO_GET REJECTED "
                   "get_type=%u\n", get.get_type);
            return -EINVAL;
        }
        if (get.get_size != 8 || !get.get_data) {
            printk(KERN_INFO "fbvirt-mt85: FBIO_GET REJECTED size=%u "
                   "data=%p\n", get.get_size, get.get_data);
            return -EINVAL;
        }
        /* the single advertised mode, consistently */
        if (put_user((unsigned int)FBVIRT_XRES, get.get_data)
            || put_user((unsigned int)FBVIRT_YRES, get.get_data + 1))
            return -EFAULT;
        mt85_log_req(cmd);
        printk(KERN_INFO "fbvirt-mt85: FBIO_GET panel size -> "
               "%ux%u\n", FBVIRT_XRES, FBVIRT_YRES);
        return 0;
    }
    case MT85_FBIO_SET: {
        struct mt85fb_set set;
        struct mt85_plane_state *pl;
        if (copy_from_user(&set, (void __user *)arg, sizeof(set)))
            return -EFAULT;
        /* masked apply: only fields named by the mask are honored */
        pl = &mt85_planes[0];
        if (set.mask & MT85_SET_PLANE_ID) {
            if (set.rSetting.u4OsdPlaneID >= 3) {
                printk(KERN_INFO "fbvirt-mt85: SET REJECTED plane=%u\n",
                       set.rSetting.u4OsdPlaneID);
                return -EINVAL;
            }
            pl = &mt85_planes[set.rSetting.u4OsdPlaneID];
        }
        if (set.mask & MT85_SET_PITCH)   pl->pitch = set.rSetting.u4Pitch;
        if (set.mask & MT85_SET_CM)      pl->cm = set.rSetting.u1CM;
        if (set.mask & MT85_SET_W)      pl->w = set.rSetting.u2W;
        if (set.mask & MT85_SET_H)      pl->h = set.rSetting.u2H;
        if (set.mask & MT85_SET_VISIBLE) pl->visible = set.rSetting.fgVisible;
        if (set.mask & MT85_SET_BASE) {
            /* translate the advertised phys namespace back onto pool
             * bytes: base must land inside one of the two pools */
            if (set.rSetting.u4Base >= MT85_POOL0_PHYS
                && set.rSetting.u4Base < MT85_POOL0_PHYS + MT85_POOL0_SIZE) {
                pl->base = set.rSetting.u4Base;
                printk(KERN_INFO "fbvirt-mt85: SET plane base "
                       "0x%08x -> pool0+%u (in bounds)\n",
                       set.rSetting.u4Base,
                       set.rSetting.u4Base - MT85_POOL0_PHYS);
            } else if (set.rSetting.u4Base >= MT85_POOL1_PHYS
                       && set.rSetting.u4Base
                       < MT85_POOL1_PHYS + MT85_POOL1_SIZE) {
                pl->base = set.rSetting.u4Base;
                printk(KERN_INFO "fbvirt-mt85: SET plane base "
                       "0x%08x -> pool1+%u (in bounds)\n",
                       set.rSetting.u4Base,
                       set.rSetting.u4Base - MT85_POOL1_PHYS);
            } else {
                printk(KERN_INFO "fbvirt-mt85: SET plane base 0x%08x "
                       "OUT OF POOL RANGE [0x%08x,0x%08x)/[0x%08x,0x%08x) "
                       "— recorded, not mapped\n", set.rSetting.u4Base,
                       MT85_POOL0_PHYS, MT85_POOL0_PHYS + MT85_POOL0_SIZE,
                       MT85_POOL1_PHYS, MT85_POOL1_PHYS + MT85_POOL1_SIZE);
                pl->base = set.rSetting.u4Base;
            }
        }
        mt85_log_req(cmd);
        printk(KERN_INFO "fbvirt-mt85: SET mask=0x%x plane: pitch=%u "
               "cm=%u %ux%u vis=%u base=0x%08x\n", set.mask,
               pl->pitch, pl->cm, pl->w, pl->h, pl->visible, pl->base);
        return 0;
    }
    case MT85_FBIO_GET_PLANE_ORDER:
        if (copy_to_user((void __user *)arg, mt85_plane_order,
                         sizeof(mt85_plane_order)))
            return -EFAULT;
        mt85_log_req(cmd);
        return 0;
    case MT85_FBIO_SET_PLANE_ORDER:
        if (copy_from_user(mt85_plane_order, (void __user *)arg,
                           sizeof(mt85_plane_order)))
            return -EFAULT;
        mt85_log_req(cmd);
        printk(KERN_INFO "fbvirt-mt85: SET plane order "
               "%u,%u,%u,%u,%u\n", mt85_plane_order[0],
               mt85_plane_order[1], mt85_plane_order[2],
               mt85_plane_order[3], mt85_plane_order[4]);
        return 0;
    case MT85_FBIO_SET_OSD_PLANE_ORDER:
        if (copy_from_user(mt85_osd_plane_order, (void __user *)arg,
                           sizeof(mt85_osd_plane_order)))
            return -EFAULT;
        mt85_log_req(cmd);
        printk(KERN_INFO "fbvirt-mt85: SET OSD plane order "
               "%u,%u,%u,%u,%u\n", mt85_osd_plane_order[0],
               mt85_osd_plane_order[1], mt85_osd_plane_order[2],
               mt85_osd_plane_order[3], mt85_osd_plane_order[4]);
        return 0;
    case MT85_FBIO_CMDBUF_WR_LOCK:
    case MT85_FBIO_CMDBUF_WR_UNLOCK:
        /* ring write lock/unlock: the retail gfxdriver brackets EVERY emit
         * iteration with these (returns never checked), so per-call printks
         * would flood the console — quiet success, first occurrence logged
         * by mt85_log_req */
        mt85_log_req(cmd);
        return 0;
    case MT85_FBIO_DISPATCHHW_GFX:
    case MT85_FBIO_CHECKFLUSH:
    case MT85_FBIO_DISPATCHHW_PUB: {
        /* 0x4651 = retail gfxdriver DISPATCHHW; 0x464d = retail gfxdriver
         * _mt85CheckFlush (consume + wait — satisfied by synchronous
         * consumption); 0x4653 = the published-revision DISPATCHHW kept
         * for any published-source consumer.
         *
         * All three take the ring header pointer as arg, but the module
         * consumes from its own ring base. Still, a NULL/invalid userspace
         * pointer must not be silently accepted: reject it with -EFAULT
         * without faulting (contract §4 item 6 negative control). */
        unsigned char probe;
        if (!arg || copy_from_user(&probe, (void __user *)arg, 1)) {
            printk(KERN_INFO "fbvirt-mt85: DISPATCH 0x%x rejected bad ring arg 0x%lx\n",
                   cmd, arg);
            return -EFAULT;
        }

        {
            unsigned int count = mt85_ring_consume("dispatch");
            mt85_dispatch_calls++;
            if (mt85_dispatch_calls <= 16 || (mt85_dispatch_calls & 0xffu) == 0) {
                printk(KERN_INFO "fbvirt-mt85: DISPATCH 0x%x call #%u consumed "
                       "%u items (rd=%u wr=%u)\n", cmd, mt85_dispatch_calls,
                       count,
                       *(unsigned int *)(mt85_cmdbuf_mem + MT85_RING_OFF_RDPOINT),
                       *(unsigned int *)(mt85_cmdbuf_mem + MT85_RING_OFF_WRPOINT));
                if ((mt85_dispatch_calls & 0xffu) == 0)
                    mt85_ring_dump_counts();
            }
        }
        return 0;
    }
    case MT85_FBIO_PALETTE:
        /* retail 0x4628, issued by _mapColorFormat: 256 ARGB entries + one
         * leading word; the provider IGNORES the return value (VERIFIED:
         * mov r0, #0 immediately after the call site) — accept and log is
         * the honest contract */
        mt85_log_req(cmd);
        printk(KERN_INFO "fbvirt-mt85: PALETTE(0x4628) accepted "
               "(provider ignores the result)\n");
        return 0;
    case MT85_FBIO_GFX_FLUSH:
    case MT85_FBIO_GFX_WAIT:
        /* legacy flush/wait: with no hardware, completing immediately
         * is the truthful semantics */
        mt85_log_req(cmd);
        printk(KERN_INFO "fbvirt-mt85: GFX %s(0x%lx) -> 0 (no hardware)\n",
               cmd == MT85_FBIO_GFX_FLUSH ? "FLUSH" : "WAIT", arg);
        return 0;
    default:
        printk(KERN_INFO "fbvirt-mt85: UNHANDLED request 0x%x "
               "arg=0x%lx -> ENOTTY\n", cmd, arg);
        return -ENOTTY;
    }
    return ret;
}

static struct fb_ops fbvirt_ops = {
    .owner = THIS_MODULE,
    .fb_read = NULL,          /* default fb_sys_read via fbmem? use sys */
    .fb_write = NULL,
    .fb_setcolreg = fbvirt_setcolreg,
    .fb_mmap = fbvirt_mmap,
    .fb_ioctl = mt85_ioctl,
    /* no cfb_* accel ops: this kernel does not export the generic
     * software blit helpers (CONFIG_FB_CFB_* off; its own display
     * driver never used them) and our drawing path is user-space
     * mmap — the fb_* ioctls simply report unsupported */
};

static int __init fbvirt_init(void)
{
    unsigned long size = FBVIRT_XRES * FBVIRT_YRES * (FBVIRT_BPP / 8);
    int ret;

    fbvirt_info = framebuffer_alloc(0, NULL);
    if (!fbvirt_info)
        return -ENOMEM;

    fbvirt_info->screen_base = vmalloc_32(size);
    if (!fbvirt_info->screen_base) {
        ret = -ENOMEM;
        goto out_free;
    }
    memset(fbvirt_info->screen_base, 0, size);

    fbvirt_info->fix = (struct fb_fix_screeninfo) {
        .id = "fbvirt",
        .type = FB_TYPE_PACKED_PIXELS,
        .visual = FB_VISUAL_TRUECOLOR,
        .accel = FB_ACCEL_NONE,
        .line_length = FBVIRT_XRES * (FBVIRT_BPP / 8),
        .smem_start = 0,          /* vmalloc; mmap handled in fbvirt_mmap */
        .smem_len = size,
    };
    fbvirt_info->var = (struct fb_var_screeninfo) {
        .xres = FBVIRT_XRES,
        .yres = FBVIRT_YRES,
        .xres_virtual = FBVIRT_XVIRT,
        .yres_virtual = FBVIRT_YVIRT,
        .bits_per_pixel = FBVIRT_BPP,
        .red = { .offset = 16, .length = 8 },
        .green = { .offset = 8, .length = 8 },
        .blue = { .offset = 0, .length = 8 },
        .transp = { .offset = 24, .length = 8 },
        .activate = FB_ACTIVATE_NOW,
        .height = -1, .width = -1,
        .pixclock = 10000,
        .left_margin = 16, .right_margin = 16,
        .upper_margin = 16, .lower_margin = 16,
        .hsync_len = 8, .vsync_len = 8,
        .vmode = FB_VMODE_NONINTERLACED,
    };
    fbvirt_info->fbops = &fbvirt_ops;
    fbvirt_info->flags = FBINFO_DEFAULT | FBINFO_VIRTFB;
    fbvirt_info->pseudo_palette = NULL;

    /* MT85 vendor storage (separate from the standard fbdev screen:
     * pool 0 / pool 1 / command ring / debug info, each bounded
     * independently) */
    mt85_pool_mem = vmalloc_32(MT85_POOL0_SIZE);
    mt85_pool1_mem = vmalloc_32(MT85_POOL1_SIZE);
    mt85_cmdbuf_mem = vmalloc_32(MT85_CMDBUF_SIZE);
    mt85_debug_mem = vmalloc_32(MT85_DEBUG_SIZE);
    if (!mt85_pool_mem || !mt85_pool1_mem || !mt85_cmdbuf_mem
        || !mt85_debug_mem) {
        ret = -ENOMEM;
        goto out_mt85;
    }
    memset(mt85_pool_mem, 0, MT85_POOL0_SIZE);
    memset(mt85_pool1_mem, 0, MT85_POOL1_SIZE);
    memset(mt85_cmdbuf_mem, 0, MT85_CMDBUF_SIZE);
    memset(mt85_debug_mem, 0, MT85_DEBUG_SIZE);
    /* initialize the shared ring header (GFX_DRV_CMDBUF_T prefix stays
     * zero — kernel pointers never leak — then the ring header proper):
     * maxcount per the retail stride arithmetic, RdPoint/WrPoint 0, and
     * state=1 = immediate-dispatch policy (the gfxdriver then issues
     * DISPATCHHW after every item — VERIFIED path, and the simplest
     * correct behavior for a software interpreter) */
    *(unsigned int *)(mt85_cmdbuf_mem + MT85_RING_OFF_MAXCOUNT) =
        (MT85_CMDBUF_SIZE - MT85_RING_ITEMS_BASE) / MT85_RING_ITEM_SIZE;
    *(unsigned int *)(mt85_cmdbuf_mem + MT85_RING_OFF_STATE) = 1;

    ret = register_framebuffer(fbvirt_info);
    if (ret < 0)
        goto out_mt85;

    printk(KERN_INFO "fbvirt: virtual framebuffer %ux%u x %ubpp, "
           "%lu bytes at %p (fb%d)\n", FBVIRT_XRES, FBVIRT_YRES,
           FBVIRT_BPP, size, fbvirt_info->screen_base,
           fbvirt_info->node);
    printk(KERN_INFO "fbvirt-mt85: vendor contract up: 2 pools "
           "(p0 %u B phys=0x%08x primary/video-only slice, p1 %u B "
           "phys=0x%08x general slice), ring %u B (maxcount %u x %u B "
           "items, state=1 immediate), gfxdriver ring ioctls 0x4651/0x464d/"
           "0x4900/0x4901 live, debug %u B; retail requests served, "
           "unknown -> ENOTTY\n",
           MT85_POOL0_SIZE, MT85_POOL0_PHYS, MT85_POOL1_SIZE,
           MT85_POOL1_PHYS, MT85_CMDBUF_SIZE,
           *(unsigned int *)(mt85_cmdbuf_mem + MT85_RING_OFF_MAXCOUNT),
           MT85_RING_ITEM_SIZE, MT85_DEBUG_SIZE);
    return 0;

out_mt85:
    if (mt85_pool_mem)
        vfree(mt85_pool_mem), mt85_pool_mem = NULL;
    if (mt85_pool1_mem)
        vfree(mt85_pool1_mem), mt85_pool1_mem = NULL;
    if (mt85_cmdbuf_mem)
        vfree(mt85_cmdbuf_mem), mt85_cmdbuf_mem = NULL;
    if (mt85_debug_mem)
        vfree(mt85_debug_mem), mt85_debug_mem = NULL;

out_vfree:
    vfree(fbvirt_info->screen_base);
out_free:
    framebuffer_release(fbvirt_info);
    return ret;
}

static void __exit fbvirt_exit(void)
{
    unregister_framebuffer(fbvirt_info);
    if (mt85_pool_mem)
        vfree(mt85_pool_mem);
    if (mt85_pool1_mem)
        vfree(mt85_pool1_mem);
    if (mt85_cmdbuf_mem)
        vfree(mt85_cmdbuf_mem);
    if (mt85_debug_mem)
        vfree(mt85_debug_mem);
    vfree(fbvirt_info->screen_base);
    framebuffer_release(fbvirt_info);
}

module_init(fbvirt_init);
module_exit(fbvirt_exit);

MODULE_DESCRIPTION("Virtual framebuffer for the BX510 QEMU guest (drawing-primitive proof)");
MODULE_LICENSE("GPL");
