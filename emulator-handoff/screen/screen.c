/* Paint our own 32-bit pixels on a Sony BX510 DirectFB window.
 * SPDX-License-Identifier: GPL-2.0-or-later */
#define _GNU_SOURCE
#include <directfb.h>
#include <fcntl.h>
#include <linux/fb.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

static volatile sig_atomic_t stopping;
static void stop(int signo) { (void)signo; stopping = 1; }

static const uint32_t colors[] = {
    0xffffffff, 0xffffff00, 0xff00ffff, 0xff00ff00,
    0xffff00ff, 0xffff0000, 0xff0000ff, 0xff202020
};

static int paint(void *pixels, int pitch, int width, int height)
{
    if (!pixels || width < 1 || height < 1 || width > 8192 || height > 4320 ||
        pitch < width * 4 || pitch > 128 * 1024 || pitch % 4 || (uintptr_t)pixels % 4)
        return -1;
    for (int y = 0; y < height; ++y) {
        uint32_t *row = (uint32_t *)((unsigned char *)pixels + (size_t)y * pitch);
        for (int x = 0; x < width; ++x) row[x] = colors[x * 8 / width];
    }
    return 0;
}

static int selftest(void)
{
    uint32_t rows[3][12];
    memset(rows, 0xa5, sizeof(rows));
    if (paint(rows, sizeof(rows[0]), 8, 3)) return 1;
    for (int y = 0; y < 3; ++y)
        for (int x = 0; x < 12; ++x)
            if (rows[y][x] != (x < 8 ? colors[x] : 0xa5a5a5a5)) return 1;
    if (!paint(rows, 8, 8, 3)) return 1;
    puts("PASS ARGB bars, row padding, invalid pitch");
    return 0;
}

static int info(void)
{
    printf("DirectFB library %u.%u.%u\n", directfb_major_version,
           directfb_minor_version, directfb_micro_version);
    int fd = open("/dev/fb0", O_RDONLY);
    if (fd < 0) fd = open("/dev/fb/0", O_RDONLY);
    if (fd < 0) { perror("open framebuffer"); return 1; }
    struct fb_fix_screeninfo fix;
    struct fb_var_screeninfo var;
    int rc = ioctl(fd, FBIOGET_FSCREENINFO, &fix);
    if (!rc) rc = ioctl(fd, FBIOGET_VSCREENINFO, &var);
    if (rc < 0) perror("framebuffer info");
    else { printf("fb %.16s: %ux%u virtual=%ux%u offset=%u,%u bpp=%u "
                "line_length=%u bytes smem_len=%u\n",
                fix.id, var.xres, var.yres, var.xres_virtual, var.yres_virtual,
                var.xoffset, var.yoffset, var.bits_per_pixel, fix.line_length, fix.smem_len);
        printf("fb type=%u visual=%u panstep=%u,%u ywrapstep=%u "
               "R=%u:%u G=%u:%u B=%u:%u A=%u:%u (offset:bits)\n",
               fix.type, fix.visual, fix.xpanstep, fix.ypanstep, fix.ywrapstep,
               var.red.offset, var.red.length, var.green.offset, var.green.length,
               var.blue.offset, var.blue.length, var.transp.offset, var.transp.length);
    }
    close(fd);
    return rc < 0;
}

static int draw(int full)
{
    IDirectFB *dfb = NULL;
    IDirectFBDisplayLayer *layer = NULL;
    IDirectFBWindow *window = NULL;
    IDirectFBSurface *surface = NULL;
    DFBDisplayLayerConfig config;
    DFBSurfacePixelFormat format;
    int width, height, pitch, result = 1;
    void *pixels;
    DFBResult err;
#define CALL(op) do { fprintf(stderr, "BEGIN %s\n", #op); fflush(stderr); alarm(12); \
    err = (op); alarm(0); fprintf(stderr, "END %s => %d\n", #op, err); fflush(stderr); \
    if (err != DFB_OK) { \
    fprintf(stderr, "%s: %s (%d)\n", #op, DirectFBErrorString(err), err); goto done; } \
} while (0)
    /* Old Fusion can wait for a display master. Never create a new master. */
    CALL(DirectFBInit(NULL, NULL));
    CALL(DirectFBSetOption("force-slave", NULL));
    CALL(DirectFBCreate(&dfb));
    CALL(dfb->GetDisplayLayer(dfb, DLID_PRIMARY, &layer));
    CALL(layer->GetConfiguration(layer, &config));
    if (config.width < 1 || config.height < 1 || config.width > 8192 ||
        config.height > 4320) { fprintf(stderr, "Unexpected layer geometry\n"); goto done; }
    DFBWindowDescription desc = {0};
    desc.flags = DWDESC_WIDTH | DWDESC_HEIGHT | DWDESC_POSX | DWDESC_POSY |
                 DWDESC_PIXELFORMAT | DWDESC_OPTIONS | DWDESC_STACKING;
    desc.width = full || config.width < 320 ? config.width : 320;
    desc.height = full || config.height < 96 ? config.height : 96;
    desc.posx = (config.width - desc.width) / 2;
    desc.posy = (config.height - desc.height) / 2;
    desc.pixelformat = DSPF_ARGB;
    desc.options = DWOP_GHOST; /* no focus or input */
    desc.stacking = DWSC_UPPER;
    CALL(layer->CreateWindow(layer, &desc, &window));
    CALL(window->GetSurface(window, &surface));
    CALL(surface->GetSize(surface, &width, &height));
    CALL(surface->GetPixelFormat(surface, &format));
    if (format != DSPF_ARGB) { fprintf(stderr, "Surface is not ARGB8888\n"); goto done; }
    CALL(surface->Lock(surface, DSLF_WRITE, &pixels, &pitch));
    int painted = paint(pixels, pitch, width, height);
    CALL(surface->Unlock(surface));
    if (painted) { fprintf(stderr, "Invalid pixel layout\n"); goto done; }
    CALL(surface->Flip(surface, NULL, DSFLIP_NONE));
    CALL(window->SetOpacity(window, 255));
    printf("Presented %dx%d ARGB bars, pitch %d. Closing in three seconds.\n", width, height, pitch);
    fflush(stdout);
    for (int i = 0; i < 3 && !stopping; i++) sleep(1);
    result = 0;
done:
    fprintf(stderr, "BEGIN release window/surface/layer/session\n");
    fflush(stderr);
    alarm(5);
    if (window) window->SetOpacity(window, 0);
    if (surface) surface->Release(surface);
    if (window) window->Release(window);
    if (layer) layer->Release(layer);
    if (dfb) dfb->Release(dfb);
    alarm(0);
    fprintf(stderr, "END release\n");
    return result;
#undef CALL
}

int main(int argc, char **argv)
{
    if (argc == 2 && !strcmp(argv[1], "--selftest")) return selftest();
    if (argc == 1 || (argc == 2 && !strcmp(argv[1], "--info"))) return info();
    if (argc == 2 && (!strcmp(argv[1], "--bars") || !strcmp(argv[1], "--fullscreen"))) {
        signal(SIGINT, stop);
        signal(SIGTERM, stop);
        return draw(!strcmp(argv[1], "--fullscreen"));
    }
    fprintf(stderr, "Usage: %s [--info|--bars|--fullscreen|--selftest]\n", argv[0]);
    return 2;
}
