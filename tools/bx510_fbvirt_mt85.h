/*
 * bx510_fbvirt_mt85.h — MT85xx vendor fbdev ABI (shared kernel/userspace).
 *
 * Extracted from Sony's published DirectFB-1.2.7 source drop
 * (bd_inc/mt85xx_fb.h, systems/mtk/mt85.h, systems/mtk/x_gfx_mt85_comm.h;
 * archive SHA-256 990cc75e...). Constants verified against the retail
 * provider bytes (10/18 verbatim; see ANALYSIS.md alongside the REVIEW).
 *
 * ABI notes (all measured ILP32 on ARM — the published x_typedef.h defines
 * UINT32 as unsigned long, which is 4 bytes on this target):
 *   struct mt85fb_imagebuffer  = 12 bytes
 *   struct mt85fb_setting      = 64 bytes (16 x unsigned int)
 *   struct mt85fb_set          = 68 bytes (mask at 64)
 *   struct mt85fb_get          = 12 bytes (get_data at 8)
 *   MULTI_POOL                 = 312 bytes (15-entry arrays)
 *   GFX_DRV_CMDBUF_T           = 32 bytes (driver prefix before the ring)
 *   GFX_LINUX_CMDBUF_T         = 192 bytes (capacity@4, rd@16, wr@64,
 *                                      fgWaitFlipDone@128)
 *
 * Includeable from the kernel module (bx510_fbvirt.c) and from the guest
 * test tool (bx510_fbdraw.c): it deliberately uses only ILP32-safe plain
 * types (no kernel headers).
 */
#ifndef BX510_FBVIRT_MT85_H
#define BX510_FBVIRT_MT85_H

/* ---- vendor request numbers (values carry no _IOR/_IOW encoding) ----
 *
 * Two numbering revisions exist and they DIFFER in the 0x464f-0x4654
 * block. The published DirectFB-1.2.7 source drop says GETMULTIPOOL
 * 0x4654 / GETCMDBUFLEN 0x4651 / RELCMDBUF 0x4652 / CMDBUFWAITDONE
 * 0x464f. The SHIPPED retail libdirectfb_mtk.so (disassembly, this
 * session: system_initialize issues 0x4652 right after the
 * "UUU:CONFIG_DIRECTFB_MULTI_MEM_POOL" printf and the pool-mmap loop
 * that follows reads its length from it; mt85AdapterCmdBufGetCmdBuf
 * issues 0x464f into &_gui4CmdbufLen and mmaps with that value;
 * mt85AdapterCmdBufUninit issues 0x4650) uses the RENAMED values below.
 * The module serves the RETAIL names (that is the binary that must
 * run); the published-only numbers stay -ENOTTY and get logged if any
 * caller ever issues them (discovery, never silent success).
 */
#define MT85_FBIO_GFX_FLUSH             0x4640
#define MT85_FBIO_GFX_WAIT              0x4641
#define MT85_FBIO_GET_PLANE_ORDER       0x4642
#define MT85_FBIO_SET_PLANE_ORDER       0x4643
#define MT85_FBIO_SET_OSD_PLANE_ORDER   0x4644
#define MT85_FBIO_GET                   0x4645
/* retail-verified: */
#define MT85_FBIO_GETCMDBUFLEN          0x464f  /* retail; published 0x4651 */
#define MT85_FBIO_RELCMDBUF             0x4650  /* retail (Uninit site); published 0x4652 */
#define MT85_FBIO_GETMULTIPOOL          0x4652  /* retail; published 0x4654 */
#define MT85_FBIO_INIT                  0x4630
#define MT85_FBIO_GETIMAGEBUFFER        0x4629
#define MT85_FBIO_SET                   0x4627
#define MT85_FBIO_CMDBUF_WR_LOCK        0x4900
#define MT85_FBIO_CMDBUF_WR_UNLOCK      0x4901
/* retail gfxdriver ring requests (libdirectfb_mt85.so; decoded 2026-11-08,
 * docs/mt85xx-fbdev-graphics-contract.md §1.2 — all literal-pool VERIFIED).
 * The gfxdriver is a different vendor source revision from the sys provider:
 * it issues DISPATCHHW as 0x4651 and _mt85CheckFlush as 0x464d. Neither
 * number collides with anything the sys provider issues (its GETCMDBUFLEN
 * is 0x464f), so one dispatch table serves both modules. */
#define MT85_FBIO_DISPATCHHW_GFX        0x4651  /* gfxdriver DISPATCHHW; published GETCMDBUFLEN reused this number */
#define MT85_FBIO_CHECKFLUSH            0x464d  /* gfxdriver _mt85CheckFlush (consume + wait) */
/* published-only (retail-never-observed; unimplemented, logged): */
#define MT85_FBIO_GETCMDBUF_PUB         0x4650  /* published GETCMDBUF = retail RELCMDBUF value */
#define MT85_FBIO_DISPATCHHW_PUB        0x4653
#define MT85_FBIO_GETMULTIPOOL_PUB      0x4654
#define MT85_FBIO_SETMMAPMETHOD         0x4655  /* retail init never issues it */
#define MT85_FBIO_PALETTE               0x4628

/* ---- mmap selector protocol (mt8530fb_mmap_method) ---- */
#define MT85_FB_MMAP_MEMPOOL            0
#define MT85_FB_MMAP_GFXCMDBUF          1
#define MT85_FB_MMAP_DEBUGINFO          2

/* ---- FBIO_SET field mask bits (struct mt85fb_set.mask) ---- */
#define MT85_SET_X               (1u << 0)
#define MT85_SET_Y               (1u << 1)
#define MT85_SET_W               (1u << 2)
#define MT85_SET_H               (1u << 3)
#define MT85_SET_VIRT_W          (1u << 4)
#define MT85_SET_VIRT_H          (1u << 5)
#define MT85_SET_OFFSET_X        (1u << 6)
#define MT85_SET_OFFSET_Y        (1u << 7)
#define MT85_SET_BPP             (1u << 8)
#define MT85_SET_CM              (1u << 9)
#define MT85_SET_VISIBLE         (1u << 10)
#define MT85_SET_BASE            (1u << 11)
#define MT85_SET_PITCH           (1u << 12)
#define MT85_SET_ORDER           (1u << 13)
#define MT85_SET_OPACITY         (1u << 14)
#define MT85_SET_MIXSEL          (1u << 15)
#define MT85_SET_COLORKEYEN      (1u << 16)
#define MT85_SET_COLORKEY        (1u << 17)
#define MT85_SET_PLANE_ID        (1u << 18)
#define MT85_SET_SAFETY          (1u << 19)
#define MT85_SET_WAIT_VSYNC      (1u << 20)
#define MT85_SET_NO_WAIT_VSYNC   (1u << 21)

#define MT85_GET_PANEL_SIZE       0

/* ---- vendor structs (ILP32 layouts, offsets per the header comment) ---- */

struct mt85fb_imagebuffer {
    unsigned int u4Size;      /* +0 */
    unsigned int u4VirtAddr;  /* +4 */
    unsigned int u4PhyAddr;   /* +8 */
};                           /* 12 */

struct mt85fb_setting {       /* 16 x unsigned int = 64 bytes */
    unsigned int u4Pitch;
    unsigned int u1CM;
    unsigned int u2X;
    unsigned int u2Y;
    unsigned int u2W;
    unsigned int u2H;
    unsigned int u2OffsetX;
    unsigned int u2OffsetY;
    unsigned int fgVisible;
    unsigned int u4Base;
    unsigned int u4Order;
    unsigned int u4Opacity;
    unsigned int u4MixSel;
    unsigned int u4ColorKey;
    unsigned int u4ColorKeyEn;
    unsigned int u4OsdPlaneID;
};

struct mt85fb_set {
    struct mt85fb_setting rSetting;  /* +0 */
    unsigned int mask;               /* +64 */
};                                  /* 68 */

struct mt85fb_get {
    unsigned int get_type;   /* +0 */
    unsigned int get_size;   /* +4 */
    unsigned int *get_data;  /* +8 (nested USERSPACE pointer) */
};                           /* 12 */

/* FB_MEM_TYPE (mt85.h) */
#define MT85_FBMT_CH1        5
#define MT85_FBMT_CH2        6
#define MT85_FBMT_LIN        7
#define MT85_FBMT_ONEZONE    8
#define MT85_FBMT_VALLOC     9

/*
 * RETAIL MULTI_POOL (verified from the shipped provider, NOT the
 * published source): the retail mt85_multi_pool symbol is 88 bytes —
 * num, ref_num, then FOUR-entry arrays (the published struct has 15):
 *   num@0, ref_num@4, phys[4]@8, addr[4]@24, size[4]@40,
 *   type[4]@56, handle[4]@72
 * Verified three ways in the retail binary: system_initialize's pool
 * loop reads the mmap length from 40+4i and stores the mmap results at
 * 24+4i (addr); mt85Lock computes lock->phys = *(mp+8+4*poolno)+offset
 * and lock->addr = *(mp+24+4*poolno)+offset; readelf pins the symbol
 * size at 88.
 */
#define MT85_RETAIL_POOL_SLICE_NUM 4
#define MT85_RETAIL_POOL_BYTES     88
#define MT85_RETAIL_MP_OFF_PHYS   8
#define MT85_RETAIL_MP_OFF_ADDR   24
#define MT85_RETAIL_MP_OFF_SIZE   40
#define MT85_RETAIL_MP_OFF_TYPE   56
#define MT85_RETAIL_MP_OFF_HANDLE 72

/*
 * The published 312-byte 15-entry MULTI_POOL (kept for reference and
 * for any published-source consumer):
 *   num@0, ref_num@4, iommu_support_flag@8 (1-byte BOOL),
 *   phys[15]@12, addr[15]@72, size[15]@132, type[15]@192, handle[15]@252
 */
#define MT85_FB_MEM_SLICE_NUM 15

/*
 * Command-ring geometry, retail-VERIFIED from the gfxdriver's emit
 * function (docs/mt85xx-fbdev-graphics-contract.md §2 — replaces the
 * published-source estimates below in priority):
 *   - item slots are 160 bytes, NOT 64 (the largest payload memcpy is
 *     132 bytes at item+8; a 64-byte slot cannot hold it);
 *   - the writer writes slot (Wr+1) UNWRAPPED at mmap + 32 + 160*(Wr+1)
 *     (VERIFIED emitter arithmetic: add r11, r8, #1; add r0, r7, r11,
 *     lsl #5), so slots occupy addresses 160*1 .. 160*maxcount past the
 *     header and the worst-case write ends at 192 + 160*maxcount;
 *   - maxcount therefore must be (ring_len - 192) / 160 (for the
 *     512 KiB ring: (524288-192)/160 = 3275 floor);
 *   - header fields (offsets from the ring pointer = mmap+32):
 *     maxcount@+0x04, RdPoint@+0x10 (kernel-owned), state@+0x30,
 *     WrPoint@+0x40 (writer-owned), flag echo@+0x60.
 * The published GFX_LINUX_CMDBUF_T is declared 192 bytes, but the retail
 * gfxdriver only honors the first 160 bytes of it and item slot 1 begins
 * at mmap+192 — the struct's tail overlaps the first item. That overlap
 * is retail behavior, not a bug to fix.
 */
#define MT85_GFX_DRV_PREFIX_SIZE   32
#define MT85_GFX_RING_HDR_SIZE     192   /* published struct size (reference) */
#define MT85_RING_ITEM_STRIDE      160   /* retail-VERIFIED item stride */
#define MT85_RING_ITEMS_BASE       192   /* mmap offset of item slot 1: 32 + 160 */
#define MT85_RING_OFF_MAXCOUNT     (MT85_GFX_DRV_PREFIX_SIZE + 4)
#define MT85_RING_OFF_RDPOINT      (MT85_GFX_DRV_PREFIX_SIZE + 16)
#define MT85_RING_OFF_STATE        (MT85_GFX_DRV_PREFIX_SIZE + 48)   /* +0x30: dispatch policy */
#define MT85_RING_OFF_WRPOINT      (MT85_GFX_DRV_PREFIX_SIZE + 64)
#define MT85_RING_OFF_ECHO         (MT85_GFX_DRV_PREFIX_SIZE + 96)   /* +0x60: writer flag echo */

#endif /* BX510_FBVIRT_MT85_H */
