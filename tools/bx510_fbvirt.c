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
 * Mode: 720x576, 32bpp XRGB (the platform's SD resolution; the layer
 * model in the device's directfbrc uses 720x576 for video layers).
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
 *   DISPATCHHW/WAITDONE plumbing answers, but no command interpreter
 *   runs this pass: DISPATCHHW advances RdPoint to WrPoint and logs
 *   what it consumed (honest no-op — the accelerated path is future
 *   work; rungs d/e use DirectFB's no-hardware software rendering).
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

#define FBVIRT_XRES 720
#define FBVIRT_YRES 576
#define FBVIRT_BPP  32

/* ---- MT85 virtual-device storage model ----
 *
 * One image pool of 32 MiB backs the DirectFB surface allocator. NOTE:
 * pool size is NOT the current rung-(e) blocker — 8 MiB, 32 MiB, and an
 * exact-one-surface 3686400-byte pool all fail identically downstream
 * (see MT85-RESULTS.md); 32 MiB is kept as the generous default. The
 * command ring is 512 KiB, debug info 4096 B — all three lengths are
 * distinct from each other and from the standard-fb smem_len so the
 * mmap dispatch below is unambiguous.
 */
#define MT85_POOL_SIZE      (32u * 1024 * 1024)
#define MT85_CMDBUF_SIZE    (512u * 1024)
#define MT85_DEBUG_SIZE     4096u
/* Advertised physical-address namespace for pool 0. CPU addr = the
 * userspace pool mmap base + offset; phys = this base + offset. The
 * layer FBIO_SET(BASE) translation maps this namespace back onto the
 * pool bytes. */
#define MT85_POOL0_PHYS     0x48000000u
/* Ring capacity in items, assuming 64-byte items (GFX_BUFF_CMD_ITEM_T
 * = payload union + 5 reserved words). Item size is published-source
 * only until the retail provider is observed pushing commands; the
 * value only affects the accelerated path, which this pass stubs. */
#define MT85_RING_ITEM_SIZE 64u

static void *mt85_pool_mem;    /* vmalloc, MT85_POOL_SIZE  */
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
         * by the published length conventions (see header comment):
         *   pool i  requested with exactly size[i] + i*0x1000
         *   ring    requested with exactly the GETCMDBUFLEN value
         *   debug   requested with exactly 4096 */
        if (len == MT85_POOL_SIZE + 0 * 0x1000UL) {
            which = mt85_pool_mem;
            printk(KERN_INFO "fbvirt-mt85: mmap pool0 len=%lu "
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
     * offset, bounded by smem_len (the raw-drawing regression gate) */
    if (off + len > info->fix.smem_len)
        return -EINVAL;
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
        ib.u4Size = MT85_POOL_SIZE;
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
         * mmap), size[0]@40, type[0]@56, handle[0]@72 */
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
        mpw[0] = 1;                            /* num      */
        mpw[1] = 1;                            /* ref_num  */
        mpw[MT85_RETAIL_MP_OFF_PHYS / 4] = MT85_POOL0_PHYS;
        /* addr[0] left 0: userspace stores its mmap result there */
        mpw[MT85_RETAIL_MP_OFF_SIZE / 4] = MT85_POOL_SIZE;
        mpw[MT85_RETAIL_MP_OFF_TYPE / 4] = MT85_FBMT_ONEZONE;
        if (copy_to_user((void __user *)arg, mp, sizeof(mp)))
            return -EFAULT;
        mt85_log_req(cmd);
        printk(KERN_INFO "fbvirt-mt85: GETMULTIPOOL(0x%x retail) -> "
               "num=1 size[0]=%u phys[0]=0x%08x (88-byte retail struct)\n",
               cmd, MT85_POOL_SIZE, MT85_POOL0_PHYS);
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
             * bytes: base must land inside pool 0 */
            if (set.rSetting.u4Base >= MT85_POOL0_PHYS
                && set.rSetting.u4Base < MT85_POOL0_PHYS + MT85_POOL_SIZE) {
                pl->base = set.rSetting.u4Base;
                printk(KERN_INFO "fbvirt-mt85: SET plane base "
                       "0x%08x -> pool0+%u (in bounds)\n",
                       set.rSetting.u4Base,
                       set.rSetting.u4Base - MT85_POOL0_PHYS);
            } else {
                printk(KERN_INFO "fbvirt-mt85: SET plane base 0x%08x "
                       "OUT OF POOL RANGE [0x%08x,0x%08x) — recorded, "
                       "not mapped\n", set.rSetting.u4Base,
                       MT85_POOL0_PHYS, MT85_POOL0_PHYS + MT85_POOL_SIZE);
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
        /* ring write lock/unlock: nothing contends in the virtual
         * model; record and answer success */
        mt85_log_req(cmd);
        printk(KERN_INFO "fbvirt-mt85: CMDBUF WR %s (0x%lx) -> 0\n",
               cmd == MT85_FBIO_CMDBUF_WR_LOCK ? "LOCK" : "UNLOCK", arg);
        return 0;
    case MT85_FBIO_DISPATCHHW_PUB: {
        /* consume the ring honestly: no command interpreter this pass.
         * Advance RdPoint to WrPoint (everything submitted is treated
         * as executed-as-nothing) and log how many items were claimed. */
        unsigned int rd = *(unsigned int *)(mt85_cmdbuf_mem
                                            + MT85_RING_OFF_RDPOINT);
        unsigned int wr = *(unsigned int *)(mt85_cmdbuf_mem
                                            + MT85_RING_OFF_WRPOINT);
        unsigned int max = *(unsigned int *)(mt85_cmdbuf_mem
                                              + MT85_RING_OFF_MAXCOUNT);
        unsigned int count = 0;
        if (max && wr != rd)
            count = (wr + max - rd) % max;
        *(unsigned int *)(mt85_cmdbuf_mem + MT85_RING_OFF_RDPOINT) = wr;
        mt85_log_req(cmd);
        printk(KERN_INFO "fbvirt-mt85: DISPATCHHW(0x%lx) -> consumed %u "
               "ring items WITHOUT executing them (rd=%u wr=%u max=%u) "
               "— honest no-op, no command interpreter this pass\n",
               arg, count, rd, wr, max);
        return 0;
    }
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
        .xres_virtual = FBVIRT_XRES,
        .yres_virtual = FBVIRT_YRES,
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
     * pool / command ring / debug info, each bounded independently) */
    mt85_pool_mem = vmalloc_32(MT85_POOL_SIZE);
    mt85_cmdbuf_mem = vmalloc_32(MT85_CMDBUF_SIZE);
    mt85_debug_mem = vmalloc_32(MT85_DEBUG_SIZE);
    if (!mt85_pool_mem || !mt85_cmdbuf_mem || !mt85_debug_mem) {
        ret = -ENOMEM;
        goto out_mt85;
    }
    memset(mt85_pool_mem, 0, MT85_POOL_SIZE);
    memset(mt85_cmdbuf_mem, 0, MT85_CMDBUF_SIZE);
    memset(mt85_debug_mem, 0, MT85_DEBUG_SIZE);
    /* initialize the shared ring header (GFX_DRV_CMDBUF_T prefix stays
     * zero — kernel pointers never leak — then GFX_LINUX_CMDBUF_T) */
    *(unsigned int *)(mt85_cmdbuf_mem + MT85_RING_OFF_MAXCOUNT) =
        (MT85_CMDBUF_SIZE - MT85_GFX_DRV_PREFIX_SIZE
         - MT85_GFX_RING_HDR_SIZE) / MT85_RING_ITEM_SIZE;

    ret = register_framebuffer(fbvirt_info);
    if (ret < 0)
        goto out_mt85;

    printk(KERN_INFO "fbvirt: virtual framebuffer %ux%u x %ubpp, "
           "%lu bytes at %p (fb%d)\n", FBVIRT_XRES, FBVIRT_YRES,
           FBVIRT_BPP, size, fbvirt_info->screen_base,
           fbvirt_info->node);
    printk(KERN_INFO "fbvirt-mt85: vendor contract up: pool %u B "
           "phys=0x%08x, ring %u B (maxcount %u), debug %u B; "
           "18 published requests, unknown -> ENOTTY\n",
           MT85_POOL_SIZE, MT85_POOL0_PHYS, MT85_CMDBUF_SIZE,
           *(unsigned int *)(mt85_cmdbuf_mem + MT85_RING_OFF_MAXCOUNT),
           MT85_DEBUG_SIZE);
    return 0;

out_mt85:
    if (mt85_pool_mem)
        vfree(mt85_pool_mem), mt85_pool_mem = NULL;
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
