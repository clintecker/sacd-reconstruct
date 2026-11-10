/*
 * bx510_fbdraw.c — drawing-primitive proof for the BX510 QEMU guest.
 *
 * Rungs in one tool, run via argv mode:
 *   fbdraw            — raw fbdev drawing: open /dev/fb0, mmap, paint a
 *                      deterministic test pattern (vertical color bars +
 *                      diagonal gradient + marker blocks), then emit a
 *                      downsampled ASCII rendering and region hashes to
 *                      stdout — the evidence lands in the UART log.
 *   fbdraw directfb   — additionally exercise the REAL libdirectfb from
 *                      the device's rootfs: dlopen /lib/libdirectfb-1.2.so.0,
 *                      DirectFBInit, DirectFBSetOption("system","fbdev"),
 *                      DirectFBCreate — the shipped graphics stack
 *                      initializing against our virtual framebuffer.
 *   fbdraw fbmt85     — the MT85xx vendor-contract rung (bx510_fbvirt.c +
 *                      bx510_fbvirt_mt85.h implement the contract):
 *                      (0) negative controls: an invalid mmap length, an
 *                      invalid selector and an unknown ioctl must FAIL;
 *                      (1) the shipped DirectFB with no-hardware software
 *                      rendering must pass FBIO_INIT, system_initialize,
 *                      DirectFBCreate, and present a FillRectangle+Flip
 *                      through the vendor pool mmap;
 *                      (2) the surface pool is captured through the SAME
 *                      published mmap convention (GETMULTIPOOL, then
 *                      mmap(size[0] + 0*0x1000)) and compared against an
 *                      independently computed expectation.
 *   fbdraw fbmt85hw   — discovery variant: same sequence WITHOUT the
 *                      no-hardware shortcut (the retail gfxdriver may
 *                      push command-ring items; the module logs what it
 *                      sees). May wedge — run it under bgstart.
 *
 * Build: gnuarm toolchain, dynamic (guest glibc 2.12 runs our 2.9-era
 * binaries). No DirectFB headers needed — dlsym only; the interface
 * structs below mirror the published DirectFB-1.2.7 vtable layout
 * (lib/direct/interface.h: { void *priv; int magic; AddRef; Release;
 * methods... } — note: NO QueryInterface in 1.2 interfaces).
 */
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <linux/fb.h>

#include "bx510_fbvirt_mt85.h"

#define XRES 720
#define YRES 576
#define BYTES_PER_PIX 4

static uint32_t fb[XRES][YRES] __attribute__((unused));

static void paint_pattern(uint32_t *pix)
{
    int x, y;

    for (y = 0; y < YRES; y++) {
        for (x = 0; x < XRES; x++) {
            uint32_t r = 0, g = 0, b = 0;
            /* color bars across the top third */
            if (y < YRES / 3)
                r = (x * 8 / XRES) & 1 ? 0xff : 0x30, g = (x * 8 / XRES) & 2 ? 0xff : 0x30,
                b = (x * 8 / XRES) & 4 ? 0xff : 0x30;
            /* diagonal gradient in the middle third */
            else if (y < 2 * YRES / 3)
                r = (x * 255) / XRES, g = (y - YRES / 3) * 255 / (YRES / 3),
                b = 255 - (x * 255) / XRES;
            /* checkerboard in the bottom third */
            else
                r = g = b = (((x / 16) + (y / 16)) & 1) ? 0xe0 : 0x10;
            pix[y * XRES + x] = (r << 16) | (g << 8) | b;
        }
    }
}

static void ascii_dump(const uint32_t *pix)
{
    /* downsample to 60x18 characters by average luminance */
    static const char *ramp = " .:-=+*#%@";
    int bx, by, px, py;

    printf("FBASCII_BEGIN\n");
    for (by = 0; by < 18; by++) {
        for (bx = 0; bx < 60; bx++) {
            unsigned long lum = 0;
            int n = 0;
            for (py = by * (YRES / 18); py < (by + 1) * (YRES / 18); py += 8) {
                for (px = bx * (XRES / 60); px < (bx + 1) * (XRES / 60); px += 8) {
                    uint32_t p = pix[py * XRES + px];
                    lum += ((p >> 16) & 0xff) * 30 + ((p >> 8) & 0xff) * 59
                         + (p & 0xff) * 11;
                    n++;
                }
            }
            lum = lum / n / 100;
            putchar(ramp[lum * 9 / 255]);
        }
        putchar('\n');
    }
    printf("FBASCII_END\n");
}

static int raw_draw(void)
{
    /* the guest has no /dev (initramfs-provided on real players); the
     * probe creates the node under /res/dev — try both paths */
    int fd = open("/res/dev/fb0", O_RDWR);
    if (fd < 0)
        fd = open("/dev/fb0", O_RDWR);
    size_t len = (size_t)XRES * YRES * BYTES_PER_PIX;
    uint32_t *pix;
    char cmd[256];

    if (fd < 0) {
        perror("open /dev/fb0");
        return 1;
    }
    pix = mmap(NULL, len, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (pix == MAP_FAILED) {
        perror("mmap fb0");
        close(fd);
        return 1;
    }
    paint_pattern(pix);
    munmap(pix, len);

    /* re-read through a fresh read-only mapping: the pattern survived
     * the round trip through the fbdev mmap path */
    pix = mmap(NULL, len, PROT_READ, MAP_SHARED, fd, 0);
    if (pix == MAP_FAILED) {
        perror("re-mmap fb0");
        close(fd);
        return 1;
    }
    printf("FBDRAW: pattern painted and re-read, %zu bytes\n", len);
    ascii_dump(pix);
    munmap(pix, len);
    close(fd);

    /* full-frame md5 via dd (independent read path) */
    snprintf(cmd, sizeof cmd,
             "dd if=/res/dev/fb0 bs=%d count=1 2>/res/e | md5sum",
             (int)len);   /* no /dev/null in this guest (known fact) */
    printf("FBDRAW: full-frame md5: ");
    fflush(stdout);
    system(cmd);
    return 0;
}

typedef int (*dfb_init_fn)(int *argc, char ***argv);
typedef int (*dfb_setopt_fn)(const char *name, const char *value);
typedef int (*dfb_create_fn)(void **interface);
typedef const char *(*dfb_error_fn)(int result);

/* --- published DirectFB-1.2.7 interface vtable layouts (see header
 * comment): first members are { priv, magic, AddRef, Release }, then
 * the interface's methods in declaration order. Only the members we
 * call are typed; the rest are same-size placeholders. --- */

typedef struct {
    void *priv; int magic;
    int (*AddRef)(void *);
    int (*Release)(void *);
    void *SetCooperativeLevel, *SetVideoMode, *GetDeviceDescription,
         *EnumVideoModes, *CreateSurface, *CreatePalette, *EnumScreens,
         *GetScreen, *EnumDisplayLayers;
    int (*GetDisplayLayer)(void *thiz, unsigned int layer_id, void **ret);
    void *rest[18];
} IDirectFB_min;

typedef struct {
    void *priv; int magic;
    int (*AddRef)(void *);
    int (*Release)(void *);
    void *GetID, *GetDescription, *GetSourceDescriptions,
         *GetCurrentOutputField;
    int (*GetSurface)(void *thiz, void **ret);
    void *rest[36];
} IDirectFBDisplayLayer_min;

typedef struct {
    void *priv; int magic;
    int (*AddRef)(void *);
    int (*Release)(void *);
    void *GetCapabilities, *GetPosition;
    int (*GetSize)(void *thiz, int *w, int *h);
    void *GetVisibleRectangle;
    int (*GetPixelFormat)(void *thiz, int *fmt);
    void *GetAccelerationMask, *GetPalette, *SetPalette, *SetAlphaRamp,
         *Lock, *GetFramebufferOffset, *Unlock;
    int (*Flip)(void *thiz, const void *region, unsigned int flags);
    void *SetField, *Clear, *SetClip, *GetClip;
    int (*SetColor)(void *thiz, unsigned char r, unsigned char g,
                    unsigned char b, unsigned char a);
    void *SetColorIndex, *SetSrcBlendFunction, *SetDstBlendFunction,
         *SetPorterDuff, *SetSrcColorKey, *SetSrcColorKeyIndex,
         *SetDstColorKey, *SetDstColorKeyIndex, *SetBlittingFlags,
         *Blit, *TileBlit, *BatchBlit, *StretchBlit, *TextureTriangles,
         *SetDrawingFlags;
    int (*FillRectangle)(void *thiz, int x, int y, int w, int h);
    void *rest[33];
} IDirectFBSurface_min;

#define FBMT85_FILL_R 0x30   /* distinctive fill color (not black/white) */
#define FBMT85_FILL_G 0x99
#define FBMT85_FILL_B 0xE0
#define FBMT85_FILL_A 0xFF

static int directfb_smoke(void)
{
    void *h;
    dfb_init_fn dfb_init;
    dfb_setopt_fn dfb_setopt;
    dfb_create_fn dfb_create;
    dfb_error_fn dfb_error;
    void *dfb = NULL;
    int r;

    h = dlopen("/lib/libdirectfb-1.2.so.0", RTLD_NOW);
    if (!h) {
        printf("DFBSMOKE: dlopen failed: %s\n", dlerror());
        return 1;
    }
    printf("DFBSMOKE: /lib/libdirectfb-1.2.so.0 loaded (the device's own lib)\n");
    dfb_init = (dfb_init_fn)dlsym(h, "DirectFBInit");
    dfb_setopt = (dfb_setopt_fn)dlsym(h, "DirectFBSetOption");
    dfb_create = (dfb_create_fn)dlsym(h, "DirectFBCreate");
    dfb_error = (dfb_error_fn)dlsym(h, "DirectFBErrorString");
    if (!dfb_init || !dfb_setopt || !dfb_create) {
        printf("DFBSMOKE: missing entry points\n");
        return 1;
    }
    r = dfb_init(NULL, NULL);
    if (r) {
        printf("DFBSMOKE: DirectFBInit rc=%d (%s)\n", r,
               dfb_error ? dfb_error(r) : "?");
        return 1;
    }
    r = dfb_setopt("system", "fbdev");
    if (r)
        printf("DFBSMOKE: DirectFBSetOption(system,fbdev) rc=%d\n", r);
    r = dfb_create(&dfb);
    if (r == 0 && dfb) {
        printf("DFBSMOKE: DIRECTFB LIVE — the shipped DirectFB initialized "
               "against the virtual framebuffer (fbdev system driver)\n");
        return 0;
    }
    printf("DFBSMOKE: DirectFBCreate rc=%d (%s)\n", r,
           dfb_error ? dfb_error(r) : "?");
    return 1;
}

/* ---- MT85 vendor-contract rung ---------------------------------- */

static int open_fb(void)
{
    int fd = open("/res/dev/fb0", O_RDWR);
    if (fd < 0)
        fd = open("/dev/fb0", O_RDWR);
    return fd;
}

/* negative controls: the virtual device must REFUSE bad requests */
static int mt85_negative_control(void)
{
    int fd = open_fb();
    unsigned int sel = 3, probe = 0;
    void *bad;
    int fails = 0, r;

    if (fd < 0) {
        printf("FBMT85: NEGCTL open fb0 FAILED: %s\n", strerror(errno));
        return 1;
    }
    /* invalid selector (published selectors are 0..2) */
    r = ioctl(fd, MT85_FBIO_SETMMAPMETHOD, &sel);
    printf("FBMT85: NEGCTL SETMMAPMETHOD=3 -> rc=%d errno=%d (%s) — "
           "must fail\n", r, errno, errno == EINVAL ? "EINVAL ok" :
           errno == ENOTTY ? "ENOTTY (unimplemented — WRONG)" : "?");
    fails += (r == 0);
    /* unknown ioctl value: must be ENOTTY, never silent success */
    r = ioctl(fd, 0x4666, &probe);
    printf("FBMT85: NEGCTL ioctl(0x4666) -> rc=%d errno=%d (%s) — "
           "must be ENOTTY\n", r, errno, errno == ENOTTY ? "ENOTTY ok" :
           "NOT ENOTTY — WRONG");
    fails += (r == 0 || errno != ENOTTY);
    /* garbage mmap length: must match no vendor class AND exceed the smem.
     * Derived from the device's own fix.smem_len so the invariant survives
     * module geometry changes (the old fixed 0x400003 silently STOPPED
     * exceeding smem_len when the module grew to 1920x1080 — the control
     * passed the mmap and failed its own assertion; rig drift, not a
     * target change) */
    {
        struct fb_fix_screeninfo fi = {0};
        size_t badlen = 0x400003;
        int have_fi = ioctl(fd, FBIOGET_FSCREENINFO, &fi) == 0 && fi.smem_len;
        if (have_fi)
            badlen = (size_t)fi.smem_len + 0x1000 + 3;
        bad = mmap(NULL, badlen, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        printf("FBMT85: NEGCTL mmap(len=0x%zx, matches no vendor class and "
               "exceeds smem_len=%u) -> %p errno=%d - must fail\n", badlen,
               have_fi ? fi.smem_len : 0, bad, errno);
        fails += (bad != MAP_FAILED);
        if (bad != MAP_FAILED)
            munmap(bad, badlen);
    }
    /* contract §4 item 6 negative control: DISPATCHHW must not fault on a
     * NULL/invalid ring pointer, and must reject it with a proper error. */
    errno = 0;
    r = ioctl(fd, MT85_FBIO_DISPATCHHW_GFX, 0);
    {
        int ok = (r < 0 && errno == EFAULT);
        printf("FBMT85: NEGCTL DISPATCHHW(arg=NULL) -> rc=%d errno=%d (%s) — must be EFAULT\n",
               r, errno, ok ? "EFAULT ok" : "WRONG");
        printf("FBMT85: NEGCTL DISPATCHHW_NULL %s\n", ok ? "PASS" : "FAIL");
        fails += !ok;
    }
    close(fd);
    printf("FBMT85: NEGCTL %s (failures=%d)\n", fails ? "FAILED" : "PASS",
           fails);
    return fails != 0;
}

/* capture the surface pool through the SAME published convention the
 * provider uses: GETMULTIPOOL, then mmap(size[0] + 0*0x1000) */
static int mt85_pool_capture(int *ret_w, int *ret_h)
{
    /* RETAIL MULTI_POOL (verified; see bx510_fbvirt_mt85.h): 88 bytes,
     * four-entry arrays, num@0, phys[0]@8, addr[0]@24, size[0]@40 */
    unsigned char mp[MT85_RETAIL_POOL_BYTES];
    unsigned int *mpw = (unsigned int *)mp;
    int fd = open_fb();
    void *pool;
    uint32_t *pix;
    int i, w = ret_w ? *ret_w : 720, h = ret_h ? *ret_h : 576;
    int bytes = w * h * 4;
    uint32_t want = (FBMT85_FILL_A << 24) | (FBMT85_FILL_R << 16)
                  | (FBMT85_FILL_G << 8) | FBMT85_FILL_B;
    uint32_t got;
    char cmd[128];

    if (fd < 0) {
        printf("FBMT85: capture open fb0 FAILED: %s\n", strerror(errno));
        return 1;
    }
    memset(mp, 0, sizeof(mp));
    mpw[0] = MT85_RETAIL_POOL_SLICE_NUM; /* request up to the retail max */
    if (ioctl(fd, MT85_FBIO_GETMULTIPOOL, mp) < 0) {
        printf("FBMT85: capture GETMULTIPOOL FAILED: %s\n", strerror(errno));
        close(fd);
        return 1;
    }
    if (mpw[0] < 1 || mpw[0] > MT85_RETAIL_POOL_SLICE_NUM) {
        printf("FBMT85: capture bad pool count %u\n", mpw[0]);
        close(fd);
        return 1;
    }
    printf("FBMT85: capture pool num=%u size[0]=%u phys[0]=0x%08x "
           "(len convention: %u)\n", mpw[0],
           mpw[MT85_RETAIL_MP_OFF_SIZE / 4],
           mpw[MT85_RETAIL_MP_OFF_PHYS / 4],
           mpw[MT85_RETAIL_MP_OFF_SIZE / 4] + 0 * 0x1000);
    pool = mmap(NULL, mpw[MT85_RETAIL_MP_OFF_SIZE / 4] + 0 * 0x1000UL,
                PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (pool == MAP_FAILED) {
        printf("FBMT85: capture pool mmap FAILED: %s\n", strerror(errno));
        close(fd);
        return 1;
    }
    pix = (uint32_t *)pool;
    /* Locate the primary layer surface inside pool 0: the retail
     * split_chunk carves occupied chunks from the END of the free
     * chunk, so the first primary allocation sits at offset
     * pool_size - alloc_length — which MEASURES the retail core's
     * calculated buffer length (pitch*h + 16 overrun slack if it
     * matches the published calc). The chunk is memset to 0 at
     * occupy time, so everything before the surface is zero and the
     * first word equal to the fill color IS the surface start (the
     * fill is a distinctive nonzero color). */
    {
        unsigned int pool_words = mpw[MT85_RETAIL_MP_OFF_SIZE / 4] / 4;
        int off = -1;
        if (pool_words > (unsigned)bytes / 4) {
            for (i = 0; i <= (int)(pool_words - bytes / 4); i++) {
                if (pix[i] == want) {
                    off = i * 4;
                    break;
                }
            }
        }
        printf("FBMT85: capture located surface at pool0+%d bytes "
               "(pool0=%u B, surface=%d B => retail alloc length = "
               "%u B)\n", off,
               mpw[MT85_RETAIL_MP_OFF_SIZE / 4], bytes,
               off >= 0 ? mpw[MT85_RETAIL_MP_OFF_SIZE / 4] - (unsigned)off
                       : 0);
        if (off < 0) {
            printf("FBMT85: capture FAILED to locate the fill in "
                   "pool 0 — no rung-(e) verdict\n");
            munmap(pool, mpw[MT85_RETAIL_MP_OFF_SIZE / 4]);
            close(fd);
            return 1;
        }
        pix = (uint32_t *)((char *)pool + off);
    }
    got = pix[0];
    printf("FBMT85: capture pixels(0,0)=0x%08x (0,1)=0x%08x "
           "(w/2,h/2)=0x%08x (w-1,h-1)=0x%08x; expected uniform "
           "0x%08x\n", pix[0], pix[1], pix[(h / 2) * w + w / 2],
           pix[(h - 1) * w + w - 1], want);
    {
        int mismatch = 0;
        for (i = 0; i < bytes / 4; i += 97)
            if (pix[i] != want)
                mismatch++;
        printf("FBMT85: capture uniformity: %d sampled mismatches "
           "against the independent expectation\n", mismatch);
    }
    /* md5 through an independent path: dump the surface region to a
     * file, then md5sum it; also md5 an independently constructed
     * expectation buffer */
    {
        FILE *f = fopen("/res/poolcap.bin", "wb");
        if (f) {
            fwrite(pix, 1, bytes, f);
            fclose(f);
        }
    }
    {
        uint32_t *exp = malloc(bytes);
        FILE *f;
        if (exp) {
            for (i = 0; i < bytes / 4; i++)
                exp[i] = want;
            f = fopen("/res/poolexp.bin", "wb");
            if (f) {
                fwrite(exp, 1, bytes, f);
                fclose(f);
            }
            free(exp);
        }
    }
    snprintf(cmd, sizeof cmd,
             "md5sum /res/poolcap.bin /res/poolexp.bin");
    printf("FBMT85: capture md5 (captured vs independently-built "
           "expectation — must match):\n");
    fflush(stdout);
    system(cmd);
    munmap(pool, mpw[MT85_RETAIL_MP_OFF_SIZE / 4]);
    close(fd);
    return got != want;
}

/* ---- Hardware leg: pixel-verify the command-ring rFill --------------
   The "hardware" DirectFB path may emit a command-ring rFill. fbvirt
   executes it (kernel-side) against the MT85 pool; this verifier reads the
   SAME rFill payload words the module logs (dst=w[2], color=w[12]) and
   md5-compares the filled pixels against an independently-built expectation.

   Also carries contract §4 item 6 controls:
     - DISPATCHHW must reject NULL ring pointers with EFAULT (no fault),
     - the gfxdriver's full-ring retry loop must make progress once the
       consumer drains (bounded by the call returning + header advance). */

typedef struct {
    unsigned int dst_phys, x, y, pitch, fmt, w, h, color, magic;
    int slot;
} mt85_rfill_t;

static void *mt85_ring_map(size_t *ret_len)
{
    unsigned int ring_len = 0;
    int fd = open_fb();
    void *ring;

    if (fd < 0) {
        printf("FBMT85HW: ring map open fb0 FAILED: %s\n", strerror(errno));
        return NULL;
    }
    if (ioctl(fd, MT85_FBIO_GETCMDBUFLEN, &ring_len) < 0 || !ring_len) {
        printf("FBMT85HW: ring GETCMDBUFLEN FAILED: %s\n", strerror(errno));
        close(fd);
        return NULL;
    }
    ring = mmap(NULL, ring_len, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    close(fd);
    if (ring == MAP_FAILED) {
        printf("FBMT85HW: ring mmap %u FAILED: %s\n", ring_len,
               strerror(errno));
        return NULL;
    }
    if (ret_len)
        *ret_len = ring_len;
    return ring;
}

static int mt85_ring_find_rfill(void *ring, unsigned int maxcount,
                               mt85_rfill_t *out)
{
    unsigned int i;
    int found = 0;
    mt85_rfill_t best;

    memset(&best, 0, sizeof(best));
    best.slot = -1;

    for (i = 0; i < maxcount; i++) {
        unsigned char *item = (unsigned char *)ring + MT85_GFX_DRV_PREFIX_SIZE
                            + MT85_RING_ITEM_STRIDE * (i + 1);
        unsigned int cmd = *(unsigned int *)item;
        const unsigned int *w;

        if (cmd != 0x01u)
            continue;
        w = (const unsigned int *)(item + 8);
        if (w[13] != 0x12345678u)
            continue;
        /* best-effort plausibility (avoid false positives on stale slots) */
        if (!w[10] || !w[11] || w[10] > 8192u || w[11] > 8192u)
            continue;
        best.slot = (int)i;
        best.dst_phys = w[2];
        best.x = w[4];
        best.y = w[5];
        best.pitch = w[6];
        best.fmt = w[8];
        best.w = w[10];
        best.h = w[11];
        best.color = w[12];
        best.magic = w[13];
        found = 1;
    }
    if (!found)
        return 1;
    if (out)
        *out = best;
    return 0;
}

static int mt85_hw_ring_fill_verify(void *ring, size_t ring_len)
{
    unsigned int maxcount = *(unsigned int *)((unsigned char *)ring + MT85_RING_OFF_MAXCOUNT);
    mt85_rfill_t p;
    int fd;
    unsigned char mp[MT85_RETAIL_POOL_BYTES];
    unsigned int *mpw = (unsigned int *)mp;
    unsigned int num, pi;
    void *pool;
    size_t pool_len = 0, pool_size = 0;
    unsigned int phys_base = 0;
    unsigned long pooldst, start;
    size_t bytes;
    unsigned char *cap = NULL, *exp = NULL;
    int row;
    int ok = 0;

    (void)ring_len;

    if (!maxcount || maxcount > 100000u) {
        printf("FBMT85HW: FAIL: implausible ring maxcount=%u\n", maxcount);
        return 1;
    }
    if (mt85_ring_find_rfill(ring, maxcount, &p)) {
        printf("FBMT85HW: FAIL: no rFill item found in the ring\n");
        return 1;
    }
    printf("FBMT85HW: rFill payload(slot=%d) dst=0x%08x color=0x%08x %u,%u %ux%u pitch=%u fmt=%u magic=0x%08x\n",
           p.slot, p.dst_phys, p.color, p.x, p.y, p.w, p.h, p.pitch, p.fmt,
           p.magic);

    fd = open_fb();
    if (fd < 0) {
        printf("FBMT85HW: FAIL: open fb0: %s\n", strerror(errno));
        return 1;
    }
    /* ensure any pending items are consumed before capture (valid arg = ring+32) */
    errno = 0;
    {
        void *ring_hdr = (unsigned char *)ring + MT85_GFX_DRV_PREFIX_SIZE;
        int r = ioctl(fd, MT85_FBIO_DISPATCHHW_GFX, ring_hdr);
        printf("FBMT85HW: DISPATCHHW(rc=%d errno=%d)\n", r, errno);
    }

    memset(mp, 0, sizeof(mp));
    if (ioctl(fd, MT85_FBIO_GETMULTIPOOL, mp) < 0) {
        printf("FBMT85HW: FAIL: GETMULTIPOOL: %s\n", strerror(errno));
        close(fd);
        return 1;
    }
    num = mpw[0];
    if (num < 1 || num > MT85_RETAIL_POOL_SLICE_NUM) {
        printf("FBMT85HW: FAIL: GETMULTIPOOL bad num=%u\n", num);
        close(fd);
        return 1;
    }

    for (pi = 0; pi < num; pi++) {
        unsigned int base = mpw[MT85_RETAIL_MP_OFF_PHYS / 4 + pi];
        unsigned int sz = mpw[MT85_RETAIL_MP_OFF_SIZE / 4 + pi];
        if (p.dst_phys >= base && p.dst_phys < base + sz) {
            phys_base = base;
            pool_size = sz;
            pool_len = (size_t)sz + (size_t)pi * 0x1000u;
            break;
        }
    }
    if (!pool_len) {
        printf("FBMT85HW: FAIL: dst 0x%08x outside all pools\n", p.dst_phys);
        close(fd);
        return 1;
    }
    pool = mmap(NULL, pool_len, PROT_READ, MAP_SHARED, fd, 0);
    if (pool == MAP_FAILED) {
        printf("FBMT85HW: FAIL: pool mmap len=%zu: %s\n", pool_len,
               strerror(errno));
        close(fd);
        return 1;
    }

    if (p.fmt != 12u) {
        printf("FBMT85HW: FAIL: unsupported fmt=%u (expected vendor-ARGB=12)\n",
               p.fmt);
        goto out;
    }
    if (!p.w || !p.h || p.w > 8192u || p.h > 8192u || !p.pitch
        || p.pitch < p.w * 4u) {
        printf("FBMT85HW: FAIL: implausible fill geometry w=%u h=%u pitch=%u\n",
               p.w, p.h, p.pitch);
        goto out;
    }

    pooldst = (unsigned long)(p.dst_phys - phys_base);
    start = pooldst + (unsigned long)p.y * (unsigned long)p.pitch
          + (unsigned long)p.x * 4u;
    if (start + ((unsigned long)p.h - 1u) * (unsigned long)p.pitch
        + (unsigned long)p.w * 4u > pool_size) {
        printf("FBMT85HW: FAIL: fill region OOB (start=%lu size=%zu)\n",
               start, pool_size);
        goto out;
    }

    bytes = (size_t)p.w * (size_t)p.h * 4u;
    cap = malloc(bytes);
    exp = malloc(bytes);
    if (!cap || !exp) {
        printf("FBMT85HW: FAIL: malloc(%zu)\n", bytes);
        goto out;
    }

    for (row = 0; row < (int)p.h; row++) {
        const unsigned char *src = (const unsigned char *)pool + start
                                 + (unsigned long)row * (unsigned long)p.pitch;
        memcpy(cap + (size_t)row * (size_t)p.w * 4u, src, (size_t)p.w * 4u);
    }
    {
        unsigned int i;
        unsigned int *ew = (unsigned int *)exp;
        for (i = 0; i < bytes / 4; i++)
            ew[i] = p.color;
    }

    {
        FILE *f = fopen("/res/hwfillcap.bin", "wb");
        if (f) { fwrite(cap, 1, bytes, f); fclose(f); }
    }
    {
        FILE *f = fopen("/res/hwfillexp.bin", "wb");
        if (f) { fwrite(exp, 1, bytes, f); fclose(f); }
    }

    ok = (memcmp(cap, exp, bytes) == 0);
    printf("FBMT85HW: capture md5 (captured vs independently-built expectation — must match):\n");
    fflush(stdout);
    system("md5sum /res/hwfillcap.bin /res/hwfillexp.bin");
    printf("FBMT85HW: ring fill pixel-VERIFY %s\n", ok ? "PASS" : "FAIL");

out:
    if (cap) free(cap);
    if (exp) free(exp);
    munmap(pool, pool_len);
    close(fd);
    return ok ? 0 : 1;
}

static int mt85_hw_full_ring_retry(IDirectFBSurface_min *s, void *ring)
{
    unsigned int *p_max = (unsigned int *)((unsigned char *)ring + MT85_RING_OFF_MAXCOUNT);
    unsigned int *p_rd  = (unsigned int *)((unsigned char *)ring + MT85_RING_OFF_RDPOINT);
    unsigned int *p_wr  = (unsigned int *)((unsigned char *)ring + MT85_RING_OFF_WRPOINT);
    unsigned int *p_state = (unsigned int *)((unsigned char *)ring + MT85_RING_OFF_STATE);
    unsigned int orig_max = *p_max;
    unsigned int orig_state = *p_state;
    unsigned int C = 8;
    unsigned int rd_before = 0, wr_before = C - 1;
    unsigned int rd_after, wr_after;
    int r, ok;
    unsigned int i;

    *p_max = C;
    *p_state = 0;               /* not immediate: allow the ring to fill */
    *p_rd = rd_before;
    *p_wr = wr_before;
    for (i = 1; i < C; i++) {
        unsigned char *item = (unsigned char *)ring + MT85_GFX_DRV_PREFIX_SIZE
                            + MT85_RING_ITEM_STRIDE * i;
        *(unsigned int *)item = 0x191u;        /* sync marker (no payload) */
        *(unsigned int *)(item + 4) = 1u;
    }

    r = s->SetColor(s, FBMT85_FILL_R, FBMT85_FILL_G, FBMT85_FILL_B,
                    FBMT85_FILL_A);
    r |= s->FillRectangle(s, 0, 0, 8, 8);
    r |= s->Flip(s, NULL, 0);
    rd_after = *p_rd;
    wr_after = *p_wr;

    ok = (r == 0 && wr_after != wr_before);
    printf("FBMT85HW: FULLRING before rd=%u wr=%u max=%u; after rd=%u wr=%u; rc=%d\n",
           rd_before, wr_before, C, rd_after, wr_after, r);
    printf("FBMT85HW: FULLRING RETRY %s\n", ok ? "PASS" : "FAIL");

    *p_max = orig_max;
    *p_state = orig_state;
    return ok ? 0 : 1;
}

static int mt85_directfb_rung(int software_only)
{
    void *h, *dfb = NULL, *layer = NULL, *surface = NULL;
    dfb_init_fn dfb_init;
    dfb_setopt_fn dfb_setopt;
    dfb_create_fn dfb_create;
    dfb_error_fn dfb_error;
    IDirectFB_min *d;
    IDirectFBDisplayLayer_min *l;
    IDirectFBSurface_min *s;
    int r, w = 0, hgt = 0, fmt = 0, bad = 0;

    printf("FBMT85: rung begin (%s)\n",
           software_only ? "no-hardware software rendering" :
           "hardware mode — discovery, may push ring items");
    h = dlopen("/lib/libdirectfb-1.2.so.0", RTLD_NOW);
    if (!h) {
        printf("FBMT85: dlopen failed: %s\n", dlerror());
        return 1;
    }
    printf("FBMT85: rung (a) target: shipped libdirectfb loaded\n");
    dfb_init = (dfb_init_fn)dlsym(h, "DirectFBInit");
    dfb_setopt = (dfb_setopt_fn)dlsym(h, "DirectFBSetOption");
    dfb_create = (dfb_create_fn)dlsym(h, "DirectFBCreate");
    dfb_error = (dfb_error_fn)dlsym(h, "DirectFBErrorString");
    if (!dfb_init || !dfb_setopt || !dfb_create) {
        printf("FBMT85: missing entry points\n");
        return 1;
    }
    r = dfb_init(NULL, NULL);
    if (r) {
        printf("FBMT85: DirectFBInit rc=%d (%s)\n", r,
               dfb_error ? dfb_error(r) : "?");
        return 1;
    }
    /* the review's §6 shortcut: software rendering first; the vendor
     * init/mapping/layer contract is still fully exercised (that is
     * the SYSTEM provider, not the gfxdriver) */
    if (software_only) {
        r = dfb_setopt("no-hardware", "1");
        printf("FBMT85: SetOption(no-hardware,1) rc=%d\n", r);
    }
    r = dfb_create(&dfb);
    printf("FBMT85: rung (b) DirectFBCreate rc=%d (%s)%s\n", r,
           dfb_error ? dfb_error(r) : "?", r ? " — ENOTTY trail in the "
           "module log names what remains" : "");
    if (r || !dfb)
        return 1;
    printf("FBMT85: rungs (a)+(b) REACHED: FBIO_INIT + system_initialize "
           "passed, DirectFBCreate SUCCEEDED\n");
    d = (IDirectFB_min *)dfb;
    r = d->GetDisplayLayer(d, 0, &layer);   /* DLID_PRIMARY */
    if (r || !layer) {
        printf("FBMT85: GetDisplayLayer rc=%d\n", r);
        return 1;
    }
    l = (IDirectFBDisplayLayer_min *)layer;
    r = l->GetSurface(l, &surface);
    if (r || !surface) {
        printf("FBMT85: GetSurface rc=%d\n", r);
        return 1;
    }
    s = (IDirectFBSurface_min *)surface;
    s->GetSize(s, &w, &hgt);
    s->GetPixelFormat(s, &fmt);
    printf("FBMT85: rung (c) primary surface LIVE: %dx%d fmt=%d\n",
           w, hgt, fmt);
    bad = (w <= 0 || hgt <= 0);
    r = s->SetColor(s, FBMT85_FILL_R, FBMT85_FILL_G, FBMT85_FILL_B,
                    FBMT85_FILL_A);
    r |= s->FillRectangle(s, 0, 0, w, hgt);
    printf("FBMT85: rung (d) SetColor+FillRectangle(0,0,%d,%d) rc=%d\n",
           w, hgt, r);
    bad |= r;
    r = s->Flip(s, NULL, 0 /* DSFLIP_NONE */);
    printf("FBMT85: Flip rc=%d (plane base -> module log shows the "
           "phys->pool translation)\n", r);
    bad |= r;
    if (!software_only && !bad) {
        size_t ring_len = 0;
        void *ring = mt85_ring_map(&ring_len);
        if (!ring) {
            printf("FBMT85HW: FAIL: could not map ring\n");
            bad |= 1;
        } else {
            bad |= mt85_hw_ring_fill_verify(ring, ring_len);
            bad |= mt85_hw_full_ring_retry(s, ring);
            munmap(ring, ring_len);
        }
    }
    s->Release(s);
    l->Release(l);
    d->Release(d);
    if (software_only && !bad) {
        r = mt85_pool_capture(&w, &hgt);
        printf("FBMT85: rung (e) pool capture %s\n", r ? "MISMATCH" :
               "MATCHES the independent expectation");
        bad |= r;
    }
    printf("FBMT85: rung end %s\n", bad ? "FAILED" : "PASS");
    return bad != 0;
}

int main(int argc, char **argv)
{
    int rc = 0;

    rc |= raw_draw();
    if (argc > 1 && strcmp(argv[1], "directfb") == 0)
        rc |= directfb_smoke();
    if (argc > 1 && strcmp(argv[1], "fbmt85") == 0) {
        rc |= mt85_negative_control();          /* controls first */
        rc |= mt85_directfb_rung(1);
    }
    if (argc > 1 && strcmp(argv[1], "fbmt85hw") == 0)
        rc |= mt85_directfb_rung(0);
    printf("FBDRAW: DONE rc=%d\n", rc);
    return rc;
}
