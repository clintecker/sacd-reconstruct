/*
 * bx510_sawman_probe.c — SaWMan coexistence probe (second DirectFB app).
 *
 * Goal (S2-SAWMAN-PLAN.md): prove that a second DirectFB client can create a
 * window via the SaWMan WM (wm=sawman) without taking over the primary, draw a
 * recognizable pattern, then exit cleanly.
 *
 * Evidence discipline: print step markers ("SAWMAN-PROBE: ...") for UART logs.
 *
 * Build (on the lab VM, dynamic):
 *   DFB=~/mt85src/DirectFB-1.2.7
 *   ~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall \
 *       -I$DFB/include -I$DFB/lib -o sawman_probe bx510_sawman_probe.c \
 *       -L/tmp/rootfs/lib -ldirectfb -ldirect -lfusion -lpthread
 */
#include <directfb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <errno.h>

static void mark(const char *msg) {
    printf("SAWMAN-PROBE: %s\n", msg);
    fflush(stdout);
}

static void logr(const char *what, DFBResult r) {
    printf("SAWMAN-PROBE: %s: rc=%d (%s)\n", what, r, DirectFBErrorString(r));
    fflush(stdout);
}

static int arg_int(int *argc, char ***argv, const char *key, int *out) {
    int i;
    for (i = 1; i < *argc; i++) {
        if (!strcmp((*argv)[i], key) && i + 1 < *argc) {
            *out = atoi((*argv)[i + 1]);
            /* remove key + value so DirectFBInit still sees --dfb:* args */
            memmove(&(*argv)[i], &(*argv)[i + 2], (size_t)(*argc - (i + 2)) * sizeof(char *));
            *argc -= 2;
            return 1;
        }
        if (!strncmp((*argv)[i], key, strlen(key)) && (*argv)[i][strlen(key)] == '=') {
            *out = atoi((*argv)[i] + strlen(key) + 1);
            memmove(&(*argv)[i], &(*argv)[i + 1], (size_t)(*argc - (i + 1)) * sizeof(char *));
            *argc -= 1;
            return 1;
        }
    }
    return 0;
}

static const char *arg_str(int *argc, char ***argv, const char *key) {
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

static int arg_flag(int *argc, char ***argv, const char *key) {
    int i;
    for (i = 1; i < *argc; i++) {
        if (!strcmp((*argv)[i], key)) {
            memmove(&(*argv)[i], &(*argv)[i + 1], (size_t)(*argc - (i + 1)) * sizeof(char *));
            *argc -= 1;
            return 1;
        }
    }
    return 0;
}

static void draw_pattern(IDirectFBSurface *s, int id, int w, int h) {
    int i;
    /* background */
    if (id == 1)
        s->SetColor(s, 0x10, 0x10, 0x10, 0xff);
    else if (id == 2)
        s->SetColor(s, 0x00, 0x20, 0x40, 0xff);
    else
        s->SetColor(s, 0x20, 0x00, 0x20, 0xff);
    s->FillRectangle(s, 0, 0, w, h);

    /* bars */
    {
        int margin = w / 16;
        int gap = w / 48;
        int bw = (w - 2 * margin - 2 * gap) / 3;
        int bh = (h * 2) / 3;
        int by = h / 6;
        s->SetColor(s, 0xff, 0x40, 0x40, 0xff);
        s->FillRectangle(s, margin, by, bw, bh);
        s->SetColor(s, 0x40, 0xff, 0x40, 0xff);
        s->FillRectangle(s, margin + bw + gap, by, bw, bh);
        s->SetColor(s, 0x40, 0x40, 0xff, 0xff);
        s->FillRectangle(s, margin + 2 * (bw + gap), by, bw, bh);
    }

    /* border */
    s->SetColor(s, 0xff, 0xff, 0xff, 0xff);
    for (i = 0; i < 4; i++)
        s->DrawRectangle(s, i, i, w - 2 * i, h - 2 * i);

    /* ID tick: a small colored square in the bottom-right */
    if (id == 1)
        s->SetColor(s, 0xff, 0xff, 0x00, 0xff);
    else if (id == 2)
        s->SetColor(s, 0x00, 0xff, 0xff, 0xff);
    else
        s->SetColor(s, 0xff, 0x80, 0xff, 0xff);
    s->FillRectangle(s, w - 40, h - 40, 32, 32);
}

static int bpp_for_fmt(DFBSurfacePixelFormat fmt) {
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

static int dump_surface_raw(IDirectFBSurface *s, const char *path) {
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
        printf("SAWMAN-PROBE: dump: GetSize rc=%d (%s)\n", r, DirectFBErrorString(r));
        return 1;
    }
    s->GetPixelFormat(s, &fmt);
    bpp = bpp_for_fmt(fmt);

    mark("DUMP_LOCK");
    r = s->Lock(s, DSLF_READ, &ptr, &pitch);
    logr("Surface.Lock(READ)", r);
    if (r != DFB_OK)
        return 2;

    f = fopen(path, "wb");
    if (!f) {
        printf("SAWMAN-PROBE: dump: fopen %s: %s\n", path, strerror(errno));
        s->Unlock(s);
        return 3;
    }

    for (y = 0; y < h; y++) {
        size_t want = (size_t)w * (size_t)bpp;
        unsigned char *row = (unsigned char *)ptr + (size_t)y * (size_t)pitch;
        if (fwrite(row, 1, want, f) != want) {
            printf("SAWMAN-PROBE: dump: fwrite: short write\n");
            break;
        }
    }
    fclose(f);
    s->Unlock(s);
    printf("SAWMAN-PROBE: dump: wrote %s (%dx%d fmt=0x%x pitch=%d)\n",
           path, w, h, (unsigned)fmt, pitch);
    fflush(stdout);
    return 0;
}

int main(int argc, char **argv) {
    IDirectFB *dfb = NULL;
    IDirectFBDisplayLayer *layer = NULL;
    IDirectFBWindow *win = NULL;
    IDirectFBSurface *ws = NULL;
    DFBResult r;

    int x = 80, y = 80;
    int w = 640, h = 240;
    int hold = 6;
    int id = 1;
    int want_alpha = 1;
    const char *dump_path = NULL;

    arg_int(&argc, &argv, "--x", &x);
    arg_int(&argc, &argv, "--y", &y);
    arg_int(&argc, &argv, "--w", &w);
    arg_int(&argc, &argv, "--h", &h);
    arg_int(&argc, &argv, "--hold", &hold);
    arg_int(&argc, &argv, "--id", &id);
    dump_path = arg_str(&argc, &argv, "--dump");
    if (arg_flag(&argc, &argv, "--no-alpha"))
        want_alpha = 0;

    if (hold < 1) hold = 1;
    if (hold > 60) hold = 60;
    if (w < 32) w = 32;
    if (h < 32) h = 32;

    mark("BEGIN");

    r = DirectFBInit(&argc, &argv);
    logr("DirectFBInit", r);
    if (r) return 1;

    r = DirectFBCreate(&dfb);
    logr("DirectFBCreate", r);
    if (r) return 2;

    /* Explicitly request the normal cooperative level (window stack). */
    r = dfb->SetCooperativeLevel(dfb, DFSCL_NORMAL);
    logr("SetCooperativeLevel(DFSCL_NORMAL)", r);

    r = dfb->GetDisplayLayer(dfb, DLID_PRIMARY, &layer);
    logr("GetDisplayLayer(DLID_PRIMARY)", r);
    if (r) goto out;

    r = layer->SetCooperativeLevel(layer, DLSCL_SHARED);
    logr("Layer.SetCooperativeLevel(DLSCL_SHARED)", r);

    {
        DFBDisplayLayerConfig cfg;
        memset(&cfg, 0, sizeof(cfg));
        r = layer->GetConfiguration(layer, &cfg);
        if (r == DFB_OK) {
            printf("SAWMAN-PROBE: layer cfg: %dx%d bufmode=%d options=0x%x\n",
                   cfg.width, cfg.height, cfg.buffermode, cfg.options);
            fflush(stdout);
        } else {
            logr("Layer.GetConfiguration", r);
        }
    }

    mark("CreateWindow(attempt#1)");
    {
        DFBWindowDescription desc;
        memset(&desc, 0, sizeof(desc));
        desc.flags = DWDESC_POSX | DWDESC_POSY | DWDESC_WIDTH | DWDESC_HEIGHT | DWDESC_CAPS;
        desc.posx = x;
        desc.posy = y;
        desc.width = w;
        desc.height = h;
        desc.caps = want_alpha ? DWCAPS_ALPHACHANNEL : DWCAPS_NONE;
        r = layer->CreateWindow(layer, &desc, &win);
        logr("Layer.CreateWindow", r);
    }

    if (r != DFB_OK && want_alpha) {
        mark("CreateWindow(attempt#2 no-alpha)");
        {
            DFBWindowDescription desc;
            memset(&desc, 0, sizeof(desc));
            desc.flags = DWDESC_POSX | DWDESC_POSY | DWDESC_WIDTH | DWDESC_HEIGHT;
            desc.posx = x;
            desc.posy = y;
            desc.width = w;
            desc.height = h;
            r = layer->CreateWindow(layer, &desc, &win);
            logr("Layer.CreateWindow(no-alpha)", r);
        }
    }

    if (r != DFB_OK) {
        /* Falsification path hook: in some provider builds, window creation
         * requires administrative cooperative level. Try it (still NOT
         * exclusive takeover). */
        mark("CreateWindow(attempt#3 layer coop=DLSCL_ADMINISTRATIVE)");
        {
            DFBWindowDescription desc;
            memset(&desc, 0, sizeof(desc));
            layer->SetCooperativeLevel(layer, DLSCL_ADMINISTRATIVE);
            desc.flags = DWDESC_POSX | DWDESC_POSY | DWDESC_WIDTH | DWDESC_HEIGHT;
            desc.posx = x;
            desc.posy = y;
            desc.width = w;
            desc.height = h;
            r = layer->CreateWindow(layer, &desc, &win);
            logr("Layer.CreateWindow(admin)", r);
        }
    }

    if (r != DFB_OK || !win) goto out;

    mark("Window.RaiseToTop");
    r = win->RaiseToTop(win);
    logr("Window.RaiseToTop", r);

    mark("Window.SetOpacity(0xff)");
    r = win->SetOpacity(win, 0xff);
    logr("Window.SetOpacity", r);

    mark("Window.GetSurface");
    r = win->GetSurface(win, &ws);
    logr("Window.GetSurface", r);
    if (r) goto out;

    {
        int sw = 0, sh = 0;
        ws->GetSize(ws, &sw, &sh);
        printf("SAWMAN-PROBE: window surface %dx%d (requested %dx%d @%d,%d) id=%d\n",
               sw, sh, w, h, x, y, id);
        fflush(stdout);
        draw_pattern(ws, id, sw, sh);
    }

    mark("Surface.Flip");
    r = ws->Flip(ws, NULL, DSFLIP_NONE);
    logr("Surface.Flip", r);

    if (dump_path) {
        char cmd[512];
        int drc;
        mark("DUMP_BEGIN");
        drc = dump_surface_raw(ws, dump_path);
        printf("SAWMAN-PROBE: dump rc=%d\n", drc);
        fflush(stdout);
        snprintf(cmd, sizeof(cmd), "/usr/bin/md5sum %s", dump_path);
        mark("DUMP_MD5SUM");
        printf("SAWMAN-PROBE: md5sum cmd=%s\n", cmd);
        fflush(stdout);
        printf("SAWMAN-PROBE: md5sum rc=%d\n", system(cmd));
        fflush(stdout);
        mark("DUMP_END");
    }

    printf("SAWMAN-PROBE: HOLDING %ds\n", hold);
    fflush(stdout);
    sleep((unsigned)hold);

    mark("DestroyWindow");
    r = win->Destroy(win);
    logr("Window.Destroy", r);

out:
    mark("CLEANUP");
    if (ws) ws->Release(ws);
    if (win) win->Release(win);
    if (layer) layer->Release(layer);
    if (dfb) dfb->Release(dfb);
    mark("END");
    return (r == DFB_OK) ? 0 : 4;
}
