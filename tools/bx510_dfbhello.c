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
#include <directfb.h>

static IDirectFB *dfb = NULL;
static IDirectFBSurface *primary = NULL;

static void logi(const char *what, int v) { printf("DFBHELLO: %s: %d\n", what, v); }
static void logr(const char *what, DFBResult r) { printf("DFBHELLO: %s: rc=%d (%s)\n", what, r, DirectFBErrorString(r)); }

int main(int argc, char **argv)
{
    DFBSurfaceDescription dsc;
    DFBResult ret;
    int width = 1920, height = 1080;
    int hold = 25;
    int i;

    if (argc > 1) width = atoi(argv[1]);
    if (argc > 2) height = atoi(argv[2]);
    if (argc > 3) hold = atoi(argv[3]);
    if (hold < 1) hold = 1;
    if (hold > 100) hold = 100;

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
    sleep((unsigned)hold);

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
