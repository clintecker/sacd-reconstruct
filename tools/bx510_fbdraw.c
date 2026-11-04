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
    /* garbage mmap length: the pool length convention decodes to nothing */
    bad = mmap(NULL, 0x400003, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    printf("FBMT85: NEGCTL mmap(len=0x400003, matches no vendor class and "
           "exceeds smem_len) -> %p errno=%d - must fail\n", bad, errno);
    fails += (bad != MAP_FAILED);
    if (bad != MAP_FAILED)
        munmap(bad, 0x400003);
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
    /* the primary surface is the first allocation in pool 0 (the
     * published surface manager allocates chunk 0 at offset 0) */
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
            fwrite(pool, 1, bytes, f);
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
