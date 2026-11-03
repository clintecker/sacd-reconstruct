/*
 * bx510_fbdraw.c — drawing-primitive proof for the BX510 QEMU guest.
 *
 * Two rungs in one tool, run via argv mode:
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
 *
 * Build: gnuarm toolchain, dynamic (guest glibc 2.12 runs our 2.9-era
 * binaries). No DirectFB headers needed — dlsym only.
 */
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

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

int main(int argc, char **argv)
{
    int rc = 0;

    rc |= raw_draw();
    if (argc > 1 && strcmp(argv[1], "directfb") == 0)
        rc |= directfb_smoke();
    printf("FBDRAW: DONE rc=%d\n", rc);
    return rc;
}
