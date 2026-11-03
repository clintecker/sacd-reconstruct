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

#define FBVIRT_XRES 720
#define FBVIRT_YRES 576
#define FBVIRT_BPP  32

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

static struct fb_ops fbvirt_ops = {
    .owner = THIS_MODULE,
    .fb_read = NULL,          /* default fb_sys_read via fbmem? use sys */
    .fb_write = NULL,
    .fb_setcolreg = fbvirt_setcolreg,
    .fb_mmap = fbvirt_mmap,
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

    ret = register_framebuffer(fbvirt_info);
    if (ret < 0)
        goto out_vfree;

    printk(KERN_INFO "fbvirt: virtual framebuffer %ux%u x %ubpp, "
           "%lu bytes at %p (fb%d)\n", FBVIRT_XRES, FBVIRT_YRES,
           FBVIRT_BPP, size, fbvirt_info->screen_base,
           fbvirt_info->node);
    return 0;

out_vfree:
    vfree(fbvirt_info->screen_base);
out_free:
    framebuffer_release(fbvirt_info);
    return ret;
}

static void __exit fbvirt_exit(void)
{
    unregister_framebuffer(fbvirt_info);
    vfree(fbvirt_info->screen_base);
    framebuffer_release(fbvirt_info);
}

module_init(fbvirt_init);
module_exit(fbvirt_exit);

MODULE_DESCRIPTION("Virtual framebuffer for the BX510 QEMU guest (drawing-primitive proof)");
MODULE_LICENSE("GPL");
