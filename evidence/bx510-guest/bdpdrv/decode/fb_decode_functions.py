#!/usr/bin/env python3
"""Emit decode/fb-functions.txt: owning function + address for every finding.

The finding list is the decode's conclusion set; the ADDRESSES in it are the
instruction sites that were read, and the owning function is resolved here
from the module's own symtab -- so the table cannot drift from the binary
even though the findings themselves are curated.

Usage:
  fb_decode_functions.py > fb-functions.txt
"""
import fb_decode_common as C

# (section, addr, finding) — each addr is an instruction actually read during
# the decode; section-relative, as ET_REL addresses are.
FINDINGS = [
    (".text", 0x1460b4, "ldr r0,[_fb_info] -> the argument to register_framebuffer"),
    (".text", 0x1460b8, "register_framebuffer(&_fb_info): the ONLY registration site"),
    (".text", 0x147594, "unregister_framebuffer(&_fb_info), from _mt8530fb_probe_uninit"),
    (".text", 0x146118, "_mt8530fb_init_fbinfo: builds var/fix/fbops on the single _fb_info"),
    (".text", 0x146140, "str r7,[t_pal+0x720] -> fb_info+0x21c fbops = &_mt8530fb_ops"),
    (".text", 0x146160, "str r3,[t_pal+0x738] -> fb_info+0x234 pseudo_palette = &pseudo_palette"),
    (".text", 0x146164, "fb_info.flags = 1"),
    (".text", 0x14616c, "memcpy(fb_info+0xc0 = fix.id, \"mt8530\", 7)"),
    (".text", 0x1461a0, "fix.type = 0 (FB_TYPE_PACKED_PIXELS), fix.type_aux = 0"),
    (".text", 0x1461a8, "fix.line_length zeroed (rewritten with the real value at 0x14621c)"),
    (".text", 0x1461b4, "__memzero(var = fb_info+0x20, 160)"),
    (".text", 0x1461c0, "xres/line_length/bpp derived from the private `fbinfo` struct"),
    (".text", 0x1461fc, "var.yres_virtual = 2 * yres  (double buffered)"),
    (".text", 0x146204, "bitfield setup: R8 G8 B8 A8 (lengths 8, offsets 0/8/16/24)"),
    (".text", 0x14621c, "fix.line_length = xres*bits/8"),
    (".text", 0x14622c, "var.bits_per_pixel = 8 * bytesperpixel"),
    (".text", 0x146254, "var.vmode = 0 (cleared by the memzero, never set here)"),
    (".text", 0x1460a0, "_mt8530fb_probe"),
    (".text", 0x1460f4, "log \"_mt8530fb_probe() fail: cannot register mt53fb!\""),
    (".text", 0x145e88, "_mt8530fb_init(var): copies 160 B fb_var_screeninfo from USER space"),
    (".text", 0x145ecc, "__copy_from_user(sp, arg, 160)"),
    (".text", 0x145f04, "_mt8530fb_check_var(var, _fb_info)"),
    (".text", 0x145f78, "vmode switch (var->vmode at sp+0x84) -> colormode"),
    (".text", 0x145fd8, "_mt8530fb_getbytesperpixel(colormode)"),
    (".text", 0x145ff0, "fbinfo.line_length = xres * bytesperpixel"),
    (".text", 0x1459e8, "_mt8530fb_open: first-open allocates the whole surface"),
    (".text", 0x145a48, "x_alloc_aligned_ch1_mem(0x400000*n, 4096) type 5"),
    (".text", 0x145af4, "x_alloc_aligned_ch2_mem(0x400000*n, 4096) type 6"),
    (".text", 0x145ba8, "x_mem_aligned_alloc(0x400000*n, 4096) type 7"),
    (".text", 0x145c40, "x_mem_valloc(0x1800000) type 8 = the 24 MiB general pool"),
    (".text", 0x145cc4, "x_kmem_create_handle(buf, 0x1800000, 8)"),
    (".text", 0x145dd4, "fix.smem_start = pool.addr[0] + 0x40000000"),
    (".text", 0x145de0, "fix.smem_len = 0x1000000 (16 MiB)"),
    (".text", 0x145de4, "fb_info.screen_base = pool.addr[0]"),
    (".text", 0x1455d8, "_mt8530fb_mmap: class dispatch by vma LENGTH"),
    (".text", 0x1455e8, "length == gu4GfxCmdBufLen -> gfx command ring path"),
    (".text", 0x145634, "length == 4096 -> _pcDfbDebugInfo page path"),
    (".text", 0x145694, "idx = (length>>12)&0xF, valid 0..3"),
    (".text", 0x1456a8, "vma->vm_end -= idx*0x1000"),
    (".text", 0x145758, "remap_pfn_range(vma, vm_start, pool.addr[idx]>>12, pool.size[idx], prot)"),
    (".text", 0x145860, "remap_pfn_range per-page loop (page-table walk path, fmt==8)"),
    (".text", 0x146a84, "_mt8530fb_ioctl: 17-command compare chain"),
    (".text", 0x146c7c, "0x4627 SET: __copy_from_user(68 B)"),
    (".text", 0x145e88, "0x4630 INIT -> _mt8530fb_init(arg)"),
    (".text", 0x147320, "0x4652 GETMULTIPOOL: __copy_to_user(arg, sp, 88)"),
    (".text", 0x14737c, "0x464f GETCMDBUFLEN -> mt8530fb_CmdBuf_GetLen"),
    (".text", 0x147388, "0x464d CHECKFLUSH -> mt8530fb_CmdBuf_WaitDone"),
    (".text", 0x147370, "0x4651 DISPATCHHW -> mt8530fb_CmdBuf_DispatchHw"),
    (".text", 0x146bf0, "0x462d drawline_ioctl   (GX ioctl form)"),
    (".text", 0x146c04, "0x462f drawrect_ioctl"),
    (".text", 0x146c28, "0x4620 fillrect_ioctl"),
    (".text", 0x146c3c, "0x4621 copyarea_ioctl"),
    (".text", 0x146c50, "0x4622 imageblit_ioctl  (fb_imageblit is NULL - blit is ioctl-only)"),
    (".text", 0x1473ac, "default: log + return 0 (unknown ioctl is NOT an error)"),
    (".text", 0x14596c, "_mt8530fb_set_par: fix.line_length = var.xres*var.bpp/8, bpp in {1,2,4,8,16,32}"),
    (".text", 0x1458ec, "_mt8530fb_pan_display: OsdFlipPlaneInVsync(fbinfo.plane, 1, buf[yoffset?1:0])"),
    (".text", 0x14679c, "mt8530_OSD_init (reached from the ioctl INIT path)"),
    (".text", 0x2f7d00, "chip_cap_kinit: cdev_init/cdev_add (chardev 1 of 5)"),
    (".text", 0x2f8008, "wa_kinit: cdev_init/cdev_add (chardev 2 of 5)"),
    (".text", 0x2f8134, "usr_static_mem_kinit: cdev_init/cdev_add (chardev 3 of 5)"),
    (".text", 0x2f8328, "tz_intf_kinit: cdev_init/cdev_add (chardev 4 of 5)"),
    (".text", 0x30eea8, "MW_IRRX_Init: cdev_init/cdev_add (chardev 5 of 5)"),
    (".text", 0x2f8578, "vPmInit: device_register_proprietary (the pm node)"),
    (".init.text", 0x6ec, "SIF_SW_Init: cdev_init/cdev_add (SIF chardev)"),
    (".text", 0x30ec9c, "IRRC_DataProcessingThread: the thread live after bootup"),
    (".text", 0x30ef04, "MW_IRRX_Init: x_thread_create of the IR thread"),
]


def main():
    mod = C.Module()
    print("# fb-functions.txt — owning function + instruction address per finding")
    print("# bdpdrv.ko sha256 6604f6cd6c204c3399ac047f389f47162b06a3f6576159f21b4e8aaf3a72cf54")
    print("# addresses are SECTION-RELATIVE (ET_REL); regenerate with fb_decode_functions.py")
    print(f"# {'section':<11} {'addr':<11} {'owner':<34} finding")
    seen = set()
    for sec, addr, what in FINDINGS:
        fn, off = mod.func_at(sec, addr)
        owner = f"{fn}+{off:#x}" if fn else "(no enclosing STT_FUNC)"
        key = (sec, addr, what)
        if key in seen:
            continue
        seen.add(key)
        print(f"  {sec:<11} {addr:#09x}  {owner:<34} {what}")


if __name__ == "__main__":
    main()
