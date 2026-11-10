/*
 * bx510_dfbhello.c — Tier-1 display test on the BX510's OWN graphics stack.
 *
 * Why this exists: cyberdraw paints /dev/fb0 directly and the pixels never
 * reach the TV. /dev/fb0 is the mt8530 fbdev (1920x1080, stride 7680), while
 * the appliance composites through the MT85xx image pool — mmap'd by the
 * retail libdirectfb_mtk.so provider. So the only user-space path to the
 * scan-out is the retail DirectFB stack itself (the same one we proved
 * end-to-end in the guest against fbvirt's emulated vendor contract).
 *
 * What it does, logging every step so a failure names itself:
 *   1. DirectFBInit / DirectFBCreate            (provider negotiation)
 *   2. device description + chosen system module
 *   3. primary surface at the panel's geometry   (CreateSurface)
 *   4. fills: bright full-screen background, three big colour blocks,
 *      a white border — an unmistakeable, camera-safe pattern
 *   5. Flip, then hold for HOLD_SECS so a photo can be taken, Flip again
 *   6. clean release and exit
 *
 * Nothing here is guest-specific: it links the player's own
 * libdirectfb-1.2.so.0 / libdirect-1.2.so.0 / libfusion-1.2.so.0.
 *
 * Build (gnuarm 2009q3, dynamic — static breaks the retail provider's dlopen):
 *   ~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall \
 *       -I<DirectFB-1.2.7>/include -o dfbhello bx510_dfbhello.c \
 *       -L/tmp/rootfs/lib -ldirectfb -ldirect -lfusion -lpthread
 *   ~/gnuarm/bin/arm-none-linux-gnueabi-strip dfbhello
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <errno.h>

#include <directfb.h>

static IDirectFB *dfb = NULL;
static IDirectFBSurface *primary = NULL;

static const char *arg_str(int *argc, char ***argv, const char *key)
{
    int i;
    for (i = 1; i < *argc; i++) {
        if (!strcmp((*argv)[i], key) && i + 1 < *argc) {
            const char *v = (*argv)[i + 1];
            memmove(&(*argv)[i], &(*argv)[i + 2], (size_t)(*argc - (i + 2)) * sizeof(char *));
            *argc -= 2;
            return v;
        }
        if (!strncmp((*argv)[i], key, strlen(key)) && (*argv)[i][strlen(key)] == '=') {
            const char *v = (*argv)[i] + strlen(key) + 1;
            memmove(&(*argv)[i], &(*argv)[i + 1], (size_t)(*argc - (i + 1)) * sizeof(char *));
            *argc -= 1;
            return v;
        }
    }
    return NULL;
}

static int arg_int_opt(int *argc, char ***argv, const char *key, int *out)
{
    const char *v = arg_str(argc, argv, key);
    if (!v)
        return 0;
    *out = atoi(v);
    return 1;
}

static int bpp_for_fmt(DFBSurfacePixelFormat fmt)
{
    switch (fmt) {
    case DSPF_RGB16:
    case DSPF_ARGB1555:
    case DSPF_ARGB4444:
    case DSPF_RGB555:
    case DSPF_BGR555:
        return 2;
    case DSPF_RGB24:
        return 3;
    case DSPF_RGB32:
    case DSPF_ARGB:
        return 4;
    default:
        return 4;
    }
}

static int dump_surface_raw(IDirectFBSurface *s, const char *path)
{
    void *ptr = NULL;
    int pitch = 0;
    int w = 0, h = 0;
    DFBSurfacePixelFormat fmt = DSPF_UNKNOWN;
    DFBResult r;
    FILE *f;
    int bpp;
    int y;

    if (!path || !*path)
        return 0;

    r = s->GetSize(s, &w, &h);
    if (r != DFB_OK) {
        fprintf(stderr, "DFBHELLO: dump: GetSize rc=%d (%s)\n", r, DirectFBErrorString(r));
        return 1;
    }
    s->GetPixelFormat(s, &fmt);
    bpp = bpp_for_fmt(fmt);

    r = s->Lock(s, DSLF_READ, &ptr, &pitch);
    if (r != DFB_OK) {
        fprintf(stderr, "DFBHELLO: dump: Lock rc=%d (%s)\n", r, DirectFBErrorString(r));
        return 2;
    }

    f = fopen(path, "wb");
    if (!f) {
        fprintf(stderr, "DFBHELLO: dump: fopen %s: %s\n", path, strerror(errno));
        s->Unlock(s);
        return 3;
    }

    for (y = 0; y < h; y++) {
        size_t want = (size_t)w * (size_t)bpp;
        unsigned char *row = (unsigned char *)ptr + (size_t)y * (size_t)pitch;
        if (fwrite(row, 1, want, f) != want) {
            fprintf(stderr, "DFBHELLO: dump: fwrite: short write\n");
            break;
        }
    }

    fclose(f);
    s->Unlock(s);

    printf("DFBHELLO: dump wrote %s (%dx%d fmt=0x%x pitch=%d)\n",
           path, w, h, (unsigned)fmt, pitch);
    fflush(stdout);
    return 0;
}

static void logi(const char *what, int v) { printf("DFBHELLO: %s: %d\n", what, v); }
static void logr(const char *what, DFBResult r) { printf("DFBHELLO: %s: rc=%d (%s)\n", what, r, DirectFBErrorString(r)); }

int main(int argc, char **argv)
{
    DFBSurfaceDescription dsc;
    DFBResult ret;
    int width = 1920, height = 1080;
    int hold = 25;
    int i;

    const char *dump1 = NULL;
    const char *dump2 = NULL;
    int dump1_delay = 1;
    int dump2_delay = 12;

    if (argc > 1) width = atoi(argv[1]);
    if (argc > 2) height = atoi(argv[2]);
    if (argc > 3) hold = atoi(argv[3]);
    if (hold < 1) hold = 1;
    if (hold > 100) hold = 100;

    /* optional dumps (must be stripped before DirectFBInit parses args) */
    dump1 = arg_str(&argc, &argv, "--dump1");
    dump2 = arg_str(&argc, &argv, "--dump2");
    arg_int_opt(&argc, &argv, "--dump1-delay", &dump1_delay);
    arg_int_opt(&argc, &argv, "--dump2-delay", &dump2_delay);

    fflush(stdout);
    ret = DirectFBInit(&argc, &argv);
    logr("DirectFBInit", ret);
    if (ret) return 1;

    ret = DirectFBCreate(&dfb);
    logr("DirectFBCreate", ret);
    if (ret) return 2;

    {
        DFBGraphicsDeviceDescription gdd;
        memset(&gdd, 0, sizeof(gdd));
        ret = dfb->GetDeviceDescription(dfb, &gdd);
        if (ret == DFB_OK) {
            printf("DFBHELLO: device: name=%s vendor=%s\n", gdd.name, gdd.vendor);
            printf("DFBHELLO: device: blit_flags=0x%x draw_flags=0x%x\n",
                   (unsigned)gdd.blitting_flags, (unsigned)gdd.drawing_flags);
        } else {
            logr("GetDeviceDescription", ret);
        }
    }

    memset(&dsc, 0, sizeof(dsc));
    dsc.flags = DSDESC_CAPS | DSDESC_WIDTH | DSDESC_HEIGHT;
    dsc.caps = DSCAPS_PRIMARY;
    dsc.width = width;
    dsc.height = height;

    ret = dfb->CreateSurface(dfb, &dsc, &primary);
    logr("CreateSurface(primary)", ret);
    if (ret) {
        /* fall back to a plain primary with provider-chosen geometry */
        memset(&dsc, 0, sizeof(dsc));
        dsc.flags = DSDESC_CAPS;
        dsc.caps = DSCAPS_PRIMARY | DSCAPS_FLIPPING;
        ret = dfb->CreateSurface(dfb, &dsc, &primary);
        logr("CreateSurface(primary, fallback)", ret);
        if (ret) { dfb->Release(dfb); return 3; }
    }

    {
        DFBSurfacePixelFormat fmt = DSPF_UNKNOWN;
        primary->GetSize(primary, &width, &height);
        primary->GetPixelFormat(primary, &fmt);
        printf("DFBHELLO: primary surface %dx%d fmt=0x%x\n",
               width, height, (unsigned)fmt);
    }

    /* the pattern: bright background + three colour blocks + white frame,
       laid out from the ACTUAL surface size so nothing falls off the edge */
    {
        int margin = width / 24;
        int gap = width / 48;
        int bw = (width - 2 * margin - 2 * gap) / 3;
        int bh = height / 2;
        int by = height / 9;
        primary->SetColor(primary, 0x00, 0x40, 0x60, 0xff);   /* deep teal   */
        primary->FillRectangle(primary, 0, 0, width, height);
        primary->SetColor(primary, 0xff, 0x20, 0x20, 0xff);   /* red block   */
        primary->FillRectangle(primary, margin, by, bw, bh);
        primary->SetColor(primary, 0x20, 0xff, 0x20, 0xff);   /* green block */
        primary->FillRectangle(primary, margin + bw + gap, by, bw, bh);
        primary->SetColor(primary, 0x30, 0x30, 0xff, 0xff);   /* blue block  */
        primary->FillRectangle(primary, margin + 2 * (bw + gap), by, bw, bh);
    }
    primary->SetColor(primary, 0xff, 0xff, 0xff, 0xff);   /* white frame */
    for (i = 0; i < 8; i++)
        primary->DrawRectangle(primary, i, i, width - 2 * i, height - 2 * i);

    ret = primary->Flip(primary, NULL, DSFLIP_WAITFORSYNC);
    logr("Flip#1", ret);
    if (ret) {
        ret = primary->Flip(primary, NULL, DSFLIP_NONE);
        logr("Flip#1 (retry DSFLIP_NONE)", ret);
    }

    printf("DFBHELLO: HOLDING %ds — pattern should be on the panel now\n", hold);
    fflush(stdout);

    {
        int elapsed = 0;
        char cmd[512];

        if (dump1 && dump1_delay > 0 && dump1_delay <= hold) {
            sleep((unsigned)dump1_delay);
            elapsed = dump1_delay;
            printf("DFBHELLO: DUMP1 path=%s t=%d\n", dump1, elapsed);
            fflush(stdout);
            dump_surface_raw(primary, dump1);
            snprintf(cmd, sizeof(cmd), "/usr/bin/md5sum %s", dump1);
            printf("DFBHELLO: DUMP1_MD5SUM cmd=%s\n", cmd);
            fflush(stdout);
            system(cmd);
        }

        if (dump2 && dump2_delay > elapsed && dump2_delay <= hold) {
            sleep((unsigned)(dump2_delay - elapsed));
            elapsed = dump2_delay;
            printf("DFBHELLO: DUMP2 path=%s t=%d\n", dump2, elapsed);
            fflush(stdout);
            dump_surface_raw(primary, dump2);
            snprintf(cmd, sizeof(cmd), "/usr/bin/md5sum %s", dump2);
            printf("DFBHELLO: DUMP2_MD5SUM cmd=%s\n", cmd);
            fflush(stdout);
            system(cmd);
        }

        if (hold > elapsed)
            sleep((unsigned)(hold - elapsed));
    }

    /* second flip: catches "first flip latched, panel needs a re-flip" */
    primary->SetColor(primary, 0x00, 0x00, 0x00, 0xff);
    primary->FillRectangle(primary, width / 3, height / 2 + 160, width / 3, 120);
    primary->SetColor(primary, 0xff, 0xff, 0x00, 0xff);
    primary->FillRectangle(primary, width / 3 + 20, height / 2 + 180, width / 3 - 40, 80);
    ret = primary->Flip(primary, NULL, DSFLIP_NONE);
    logr("Flip#2", ret);
    printf("DFBHELLO: DONE\n");
    fflush(stdout);

    primary->Release(primary);
    dfb->Release(dfb);
    return 0;
}
