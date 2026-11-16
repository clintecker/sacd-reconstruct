/*
 * sacd_ui.c — the enhanced SACD daemon UI: a CLIENT-DRIVEN console that runs
 * INSIDE the Sony guest on the emulated BX510 and paints disc state, the
 * Master TOC + both area TOCs, and live daemon/client activity onto the panel
 * framebuffer.
 *
 * Architecture (decided once, here, because the daemon cannot be touched):
 * this process IS a daemon client. It connects to 127.0.0.1:2002, does
 * DISC_OPEN / DISC_SIZE, reads the Master TOC bundle (LBA 510 x10) and both
 * area-TOC blocks the Master TOC points at, then DISC_CLOSE. Everything it
 * shows about the disc is bytes it read off that socket — no ISO file, no
 * /dev/sr0, no daemon modification.
 *
 * Live activity comes from two honest sources:
 *   - its OWN reads (each one logged with lba/count/bytes/ms),
 *   - /proc/net/tcp :2002 (listener state + established connections) and
 *     /proc/<pid>/io for the daemon's own byte counter. Reading /proc is not
 *     a second client: the daemon's accept loop parks connections in ONE
 *     shared slot (decode/daemon-socket-protocol.md §0.6), so a second
 *     simultaneous connection would corrupt BOTH sessions. The UI therefore
 *     holds one short session and then observes from the outside. That is
 *     also how it watches a SECOND client rip (SACD_UI_WATCH_PID): it reads
 *     that pid's /proc io counter and never opens a session of its own.
 *
 * The loop is an explicit event loop ("the event model", below): polled
 * sources -> a fixed ring of typed events -> ONE apply_event() that moves
 * state and logs transitions -> a repaint only when the state actually
 * changed. No threads, no locks, no allocation inside the loop. Two
 * consequences the rest of the tooling depends on: a scene is replayable from
 * a text file (SACD_UI_SIM_SCRIPT), and a state-identical repaint is
 * byte-identical (the frame goldens and the frame-to-frame diff rely on it).
 *
 * Rendering reuses the proven guest-HUD path (tools/bx510_sacd_hud.c):
 * fbdev geometry read, the vendor MT85 pool slice mapped by length
 * (pixels at +0x1000), the carved Sony font through stb_truetype, and plain
 * software pixel writes — no DirectFB, no command ring, no Flip.
 * Text is rasterized at DEVICE pixel size and blitted 1:1 (not block-scaled)
 * so a text-dense panel stays legible at 1080p.
 *
 * Wire protocol: decode/daemon-socket-protocol.md §9 (nanopb protobuf, one
 * 0x00 terminator per message both directions, ops 1=OPEN 2=CLOSE 3=READ
 * 4=SIZE, DISC_READ <= 128 sectors, result is a 64-bit two's complement
 * varint). The client code is adapted from tools/sacdclient.c (proven in
 * c122g), made non-fatal: a failed step is a rendered red status line, not
 * an exit, and the run's exit code keeps the difference (0 = session OK and
 * a frame rendered, 3 = frame rendered but the session failed).
 *
 * TOC offsets are the fixture-VERIFIED ones (evidence/bx510-guest/bdpdrv/
 * decode/master-toc-structure.md §2 + the ISO dump in sacd-ui-run.md §parser):
 * Master TOC big-endian fields at 0x18/0x40/0x48/0x54/0x56/0x58/0x78,
 * SACDText string offsets at sector-1 +0x10, area TOC at @32 channels,
 * @64 MSF playtime, @69 track_count, @72/@76 track range, and the
 * SACDTRL1/SACDTRL2 tag blocks inside the area buffer (track_start_lsn/
 * track_length_lsn at +8/+1028, MSF start/duration likewise).
 *
 * Build: tools/sacd_ui_build.sh (era gnuarm toolchain, dynamic link — the
 * guest rootfs has the libs). Layout iteration on the Mac:
 *   cc -O2 -std=gnu99 -Wall -DSACD_UI_SIM -I. -o /tmp/sacd_uim \
 *      tools/sacd_ui.c -lm
 *   SACD_UI_FONT=evidence/bx510/display-payload/sony-font.ttf \
 *     /tmp/sacd_uim /tmp/mtoc.bin /tmp/area1.bin /tmp/area2.bin /tmp/ui.ppm
 *
 * Usage (guest): sacd_ui [host] [hold_seconds]
 *   hold_seconds is RENDER time, counted from the end of the client session
 *   (the session length is a function of the rig, not of a sleep guess).
 *   env: SACD_UI_FB         framebuffer device (default /dev/fb0, then /res/dev/fb0)
 *        SACD_UI_FONT       preferred font (chain falls back to the staged copy)
 *        SACD_UI_SCALE      logical->device scale override (default: panel_width/640)
 *        SACD_UI_DONE_FILE  session-closed marker (default /res/ui-session.done)
 *        SACD_UI_FRAME_FILE first-frame marker (default /res/ui-frame.done): written
 *                           ONCE, after the first painted frame of the render loop
 *        SACD_UI_WATCH_FILE a second client's OUTPUT FILE: its size becomes the
 *                           event log's RIP progress lines (opt-in; the UI never
 *                           opens a session for it)
 * Layout iteration on the Mac (SIM):
 *        SACD_UI_SIM_SCRIPT a text file of synthetic EVENTS replayed through
 *                           the guest's own apply_event() (grammar: sim_replay())
 *        SACD_UI_SIM_FRAMES a directory: every painted replay frame lands there
 *                           as frame-NNN.ppm
 */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <math.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#ifndef SACD_UI_SIM
#include <linux/fb.h>
#include <sys/ioctl.h>
#endif

#define STB_TRUETYPE_IMPLEMENTATION
#include "third_party/stb_truetype.h"

/* theme (declared up here so the SACD_UI_SPEC_DUMP palette table can name the
   C_* macros directly — it must emit the macros' values, never a retyped
   copy) */
#define C_BG      0x00020604u
#define C_PANELBG 0x000a1410u
#define C_FRAME   0x0000b34du
#define C_RULE    0x00004824u
#define C_DIM     0x000a7a30u
#define C_BODY    0x0050c878u
#define C_PHOS    0x0022ff66u
#define C_BRIGHT  0x00d8ffe0u
#define C_CYAN    0x0033e0ffu
#define C_MAGENTA 0x00ff66ccu
#define C_AMBER   0x00ffb000u
#define C_RED     0x00ff3344u
#define C_GREY    0x00607a6cu

#define CW 640                 /* logical canvas */
#define CH 360
#define PORT 2002
#define MAX_CHUNK 128          /* MAX_PROCESSING_BLOCK_SIZE (protocol §3) */
#define SECTOR 2048
#define MAX_TRACKS 16
#define LOG_RING 24
#define LOG_SHOWN 7

/* ---- the event model's cadences (see "the event model", below) ---- */
#define FRAME_PERIOD_S 0.030   /* EV_TICK: the frame clock — the only periodic EVENT */
#define FRAME_SLEEP_US 30000   /* the loop's sleep; painting is gated on dirty, not on this */
#define TEL_PERIOD_S   0.250   /* the three /proc sources: one sample every 250 ms */
#define BLINK_HZ       2.0     /* lamp + cursor blink; the one motion that repaints a static scene */
#define EVQ_N          16      /* fixed event ring (depth is <= 4 by construction) */
#define PROGRESS_LOG_S 1.0     /* one RIP line per second of event time, not per sample */
#define DAEMON_CMD     "sacd_extract_160"
#define FRAME_MARKER   "/res/ui-frame.done"   /* written once, on the first painted frame */

/* The canvas regions a STATE-IDENTICAL frame may differ in — the live-link
   lamp, the blinking cursor, and the RENDER line whose frame/fps/t counters
   advance with the clock. The machine-readable home of this list is the layout
   spec (tools/ui_layout_spec.json, logical 640x360 units), which the
   frame-to-frame diff regression reads; the numbers below are the C side of
   that same contract, so a change here is a change there. */
#define LAMP_X (CW - 22)
#define LAMP_Y 38
#define LAMP_W 8
#define LAMP_H 8
#define CURSOR_W 5
#define CURSOR_H 7
#define CURSOR_Y 341

/* ================= canvas ============================================== */
static unsigned int *fb;
static int pitch_px;
static int SCAL = 3;           /* device px per logical px (from the panel) */
static int g_visible_w, g_visible_h;

/* ================= layout spec recording (SACD_UI_SPEC_DUMP) ==========
 * The layout regression (`make ui-regress`) asserts that three things agree:
 * tools/ui_layout_spec.json (the committed contract), THIS dump (what the
 * compiled draw_frame() actually draws) and the rendered pixels. The dump is
 * only compiled in with -DSACD_UI_SPEC_DUMP; every other build sees
 * `spec_begin()` as a no-op, so the renderer's bytes are unchanged (verified:
 * the SIM frame's sha256 is identical with and without the flag).
 *
 * Rectangles are recorded by the PRIMITIVES (rect() and px_blend()), not by a
 * hand-written table, so the dump cannot drift from the drawing calls: the
 * only thing draw_frame() declares is which named region it is drawing. */
#ifdef SACD_UI_SPEC_DUMP
typedef struct {
    const char *name;
    int x0, y0, x1, y1, draws, ncol, nsizes;
    unsigned colors[16];       /* 0xRRGGBB, first-seen order */
    int sizes[8];              /* logical px text sizes drawn in the region */
} spec_region_t;

#define SPEC_REGIONS 32
static spec_region_t g_spec[SPEC_REGIONS];
static int g_spec_n;
static int g_spec_cur = -1;

static void spec_begin(const char *name)
{
    int i;
    for (i = 0; i < g_spec_n; i++)
        if (!strcmp(g_spec[i].name, name)) { g_spec_cur = i; return; }
    if (g_spec_n >= SPEC_REGIONS) { g_spec_cur = -1; return; }
    g_spec_cur = g_spec_n++;
    memset(&g_spec[g_spec_cur], 0, sizeof g_spec[0]);
    g_spec[g_spec_cur].name = name;
}

static void spec_touch(int x, int y, int w, int h, unsigned c)
{
    spec_region_t *r;
    int i;
    c &= 0xffffffu;
    if (g_spec_cur < 0 || w <= 0 || h <= 0) return;
    r = &g_spec[g_spec_cur];
    if (!r->draws) {
        r->x0 = x; r->y0 = y; r->x1 = x + w; r->y1 = y + h;
    } else {
        if (x < r->x0) r->x0 = x;
        if (y < r->y0) r->y0 = y;
        if (x + w > r->x1) r->x1 = x + w;
        if (y + h > r->y1) r->y1 = y + h;
    }
    r->draws++;
    for (i = 0; i < r->ncol; i++)
        if (r->colors[i] == c) return;
    if (r->ncol < (int)(sizeof r->colors / sizeof r->colors[0]))
        r->colors[r->ncol++] = c;
}

static void spec_size(int lp)
{
    spec_region_t *r;
    int i;
    if (g_spec_cur < 0) return;
    r = &g_spec[g_spec_cur];
    for (i = 0; i < r->nsizes; i++)
        if (r->sizes[i] == lp) return;
    if (r->nsizes < (int)(sizeof r->sizes / sizeof r->sizes[0]))
        r->sizes[r->nsizes++] = lp;
}

/* the palette is emitted from the C_* macros themselves, never retyped */
static const struct { const char *name; unsigned value; } g_spec_palette[] = {
    { "C_BG", C_BG }, { "C_PANELBG", C_PANELBG }, { "C_FRAME", C_FRAME },
    { "C_RULE", C_RULE }, { "C_DIM", C_DIM }, { "C_BODY", C_BODY },
    { "C_PHOS", C_PHOS }, { "C_BRIGHT", C_BRIGHT }, { "C_CYAN", C_CYAN },
    { "C_MAGENTA", C_MAGENTA }, { "C_AMBER", C_AMBER }, { "C_RED", C_RED },
    { "C_GREY", C_GREY },
};

static void spec_dump(void)
{
    int i, j;
    printf("SPEC canvas w=%d h=%d scale=%d logical=%dx%d pulse_hz=%.0f\n",
           g_visible_w, CH * SCAL, SCAL, CW, CH, BLINK_HZ);
    for (i = 0; i < (int)(sizeof g_spec_palette / sizeof g_spec_palette[0]); i++)
        printf("SPEC palette %s 0x%06x\n", g_spec_palette[i].name,
               g_spec_palette[i].value & 0xffffffu);
    for (i = 0; i < g_spec_n; i++) {
        spec_region_t *r = &g_spec[i];
        printf("SPEC region=%s x=%d y=%d w=%d h=%d draws=%d colors=",
               r->name, r->x0, r->y0, r->x1 - r->x0, r->y1 - r->y0, r->draws);
        for (j = 0; j < r->ncol; j++)
            printf("%s0x%06x", j ? "," : "", r->colors[j]);
        printf(" sizes=");
        for (j = 0; j < r->nsizes; j++)
            printf("%s%d", j ? "," : "", r->sizes[j]);
        printf("\n");
    }
    fflush(stdout);
}
#else
#define spec_begin(name) ((void)0)
#endif

/* ================= the Sony font (proven loader, copied from the HUD) === */
static stbtt_fontinfo g_font;
static unsigned char *g_ttf;
static int g_font_ok;
static char g_font_path[128];

static unsigned be32u(const unsigned char *p)
{
    return ((unsigned)p[0] << 24) | ((unsigned)p[1] << 16) |
           ((unsigned)p[2] << 8) | (unsigned)p[3];
}

/* Load a carved sfnt (ttf/otf) or Sony's /res/font.bin wrapper (12-byte
   prefix + embedded sfnt; docs/FONT-FORMAT.md). */
static int font_load(const char *path)
{
    FILE *f;
    unsigned char *raw = NULL, *sf = NULL;
    size_t n = 0, sf_n = 0;

    if (!path || !path[0]) return 0;
    f = fopen(path, "rb");
    if (!f) return 0;
    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return 0; }
    n = (size_t)ftell(f);
    if (fseek(f, 0, SEEK_SET) != 0) { fclose(f); return 0; }
    if (n < 16) { fclose(f); return 0; }
    raw = (unsigned char *)malloc(n);
    if (!raw) { fclose(f); return 0; }
    if (fread(raw, 1, n, f) != n) { fclose(f); free(raw); return 0; }
    fclose(f);

    if (memcmp(raw + 12, "\x00\x01\x00\x00", 4) == 0) {
        unsigned decl = be32u(raw + 8);
        sf = raw + 12;
        sf_n = (decl && 12u + (size_t)decl <= n) ? (size_t)decl : (n - 12);
    } else {
        sf = raw;
        sf_n = n;
    }
    if (g_ttf) free(g_ttf);
    memset(&g_font, 0, sizeof g_font);
    g_ttf = (unsigned char *)malloc(sf_n);
    if (!g_ttf) { free(raw); return 0; }
    memcpy(g_ttf, sf, sf_n);
    free(raw);
    if (!stbtt_InitFont(&g_font, g_ttf, stbtt_GetFontOffsetForIndex(g_ttf, 0))) {
        free(g_ttf);
        g_ttf = NULL;
        return 0;
    }
    g_font_ok = 1;
    snprintf(g_font_path, sizeof g_font_path, "%s", path);
    return 1;
}

static int font_load_chain(const char *preferred)
{
    const char *cands[8];
    int n = 0, i;
    if (preferred && preferred[0]) cands[n++] = preferred;
#ifndef SACD_UI_SIM
    cands[n++] = "/res/shim/sony-font.ttf";
    cands[n++] = "/tmp/sony-font.ttf";
    cands[n++] = "/res/font.bin";
#else
    cands[n++] = "evidence/bx510/display-payload/sony-font.ttf";
    cands[n++] = "sony-font.ttf";
#endif
    for (i = 0; i < n; i++)
        if (font_load(cands[i])) return 1;
    return 0;
}

/* ================= pixel primitives (device space) ===================== */
static void px_blend(int xd, int yd, unsigned int c, unsigned a)
{
    unsigned int *o, r, g, b, dr, dg, db;
    if (xd < 0 || yd < 0 || xd >= g_visible_w || yd >= CH * SCAL) return;
    if (yd >= CH * SCAL) return;
#ifdef SACD_UI_SPEC_DUMP
    spec_touch(xd / SCAL, yd / SCAL, 1, 1, c);
#endif
    o = fb + (size_t)yd * pitch_px + xd;
    dr = (*o >> 16) & 0xff; dg = (*o >> 8) & 0xff; db = *o & 0xff;
    r = ((c >> 16) & 0xff) * a / 255 + dr * (255 - a) / 255;
    g = ((c >> 8) & 0xff) * a / 255 + dg * (255 - a) / 255;
    b = (c & 0xff) * a / 255 + db * (255 - a) / 255;
    *o = (r << 16) | (g << 8) | b;
}

/* logical-coordinate rectangle: every logical px is a SCAL x SCAL block */
static void rect(int x, int y, int w, int h, unsigned int c)
{
    int dy, dx, ddx;
    unsigned int *row;
    if (x < 0) { w += x; x = 0; }
    if (y < 0) { h += y; y = 0; }
    if (x + w > CW) w = CW - x;
    if (y + h > CH) h = CH - y;
    if (w <= 0 || h <= 0) return;
#ifdef SACD_UI_SPEC_DUMP
    spec_touch(x, y, w, h, c);
#endif
    row = fb + (size_t)(y * SCAL) * pitch_px + (size_t)(x * SCAL);
    for (dy = 0; dy < h * SCAL; dy++) {
        unsigned int *o = row + (size_t)dy * pitch_px;
        for (dx = 0; dx < w; dx++)
            for (ddx = 0; ddx < SCAL; ddx++) o[dx * SCAL + ddx] = c;
    }
}

static void box(int x, int y, int w, int h, unsigned int c)
{
    rect(x, y, w, 1, c);
    rect(x, y + h - 1, w, 1, c);
    rect(x, y, 1, h, c);
    rect(x + w - 1, y, 1, h, c);
}

/* whole canvas in one pass (device rows) */
static void clear_canvas(unsigned int c)
{
    int y, x;
    for (y = 0; y < CH * SCAL; y++) {
        unsigned int *row = fb + (size_t)y * pitch_px;
        for (x = 0; x < g_visible_w; x++) row[x] = c;
    }
}

/* ================= text: rasterize at DEVICE px, blit 1:1 ============== */
static int text_w(const char *s, int dev_px)
{
    float sc;
    int w = 0;
    if (!g_font_ok) return (int)strlen(s) * (dev_px / 2);
    sc = stbtt_ScaleForPixelHeight(&g_font, (float)dev_px);
    for (; *s; s++) {
        int adv, lsb;
        stbtt_GetCodepointHMetrics(&g_font, *s, &adv, &lsb);
        w += (int)(adv * sc);
    }
    return w;
}

/* Glyph cache. Without it every frame re-rasterizes every glyph through
   stb_truetype — measured 0.4 fps in the guest (c123c, 13 frames in 31.5 s).
   The cache is keyed by (character, logical px size); the sizes in use are a
   handful, so it holds the whole alphabet several times over. */
typedef struct {
    char ch;
    int lp;
    int gw, gh, xo, yo, adv;
    unsigned char *bmp;
} glyph_cache_t;

#define GLYPH_CACHE_N 768
static glyph_cache_t g_gc[GLYPH_CACHE_N];
static int g_gc_n;

static glyph_cache_t *glyph_get(char ch, int lp, float sc)
{
    int i;
    glyph_cache_t *g;
    for (i = 0; i < g_gc_n; i++)
        if (g_gc[i].ch == ch && g_gc[i].lp == lp)
            return &g_gc[i];
    if (g_gc_n >= GLYPH_CACHE_N)
        return NULL;
    g = &g_gc[g_gc_n];
    memset(g, 0, sizeof *g);
    g->ch = ch;
    g->lp = lp;
    g->bmp = stbtt_GetCodepointBitmap(&g_font, sc, sc, ch, &g->gw, &g->gh,
                                      &g->xo, &g->yo);
    stbtt_GetCodepointHMetrics(&g_font, ch, &g->adv, &(int){0});
    g_gc_n++;
    return g;
}

/* x,y in LOGICAL px; the glyphs land at (x*SCAL, y*SCAL) at lp*SCAL height */
static int text_top(const char *s, int x, int ytop, int lp, unsigned int col)
{
    int cx = x * SCAL, ydev, asc;
    float sc;
#ifdef SACD_UI_SPEC_DUMP
    spec_size(lp);
#endif
    if (!g_font_ok) return 0;
    sc = stbtt_ScaleForPixelHeight(&g_font, (float)(lp * SCAL));
    stbtt_GetFontVMetrics(&g_font, &asc, NULL, NULL);
    ydev = ytop * SCAL + (int)(asc * sc);
    for (; *s; s++) {
        glyph_cache_t *g = glyph_get(*s, lp, sc);
        if (!g) break;
        if (g->bmp) {
            int yy, xx;
            for (yy = 0; yy < g->gh; yy++)
                for (xx = 0; xx < g->gw; xx++) {
                    unsigned char a = g->bmp[yy * g->gw + xx];
                    if (a) px_blend(cx + g->xo + xx, ydev + g->yo + yy, col, a);
                }
        }
        cx += (int)(g->adv * sc);
    }
    return (cx / SCAL) - x;
}

static void text_right(const char *s, int xr, int ytop, int lp, unsigned int col)
{
    int w = text_w(s, lp * SCAL) / SCAL;
    text_top(s, xr - w, ytop, lp, col);
}

/* ================= theme ============================================== */
/* the C_* values live at the top of the file (the spec-dump palette table
   emits them); this is the theme's documentation block. */

/* ================= event log ========================================== */
typedef struct {
    unsigned seq;              /* monotone: makes the transcript's ORDER assertable */
    double t;
    char mark;                 /* '>' info  '!' fail  '*' live */
    char text[96];
} ev_t;

static ev_t g_log[LOG_RING];
static int g_log_head, g_log_n;
static double g_t0;

static double now_s(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec / 1e9;
}

/* The EVENT CLOCK — the time base of every UI-EV line and of the progress
   throttle. A real run advances it with CLOCK_MONOTONIC; a SIM run advances
   it from its own script (g_clock_sim), which is what makes a replayed scene
   byte-reproducible run to run (no wall clock ever reaches a frame). */
static int g_clock_sim;
static double g_clock_v;

static double ev_clock(void)
{
    if (g_clock_sim) return g_clock_v;
    return now_s() - g_t0;
}

static unsigned g_ev_seq;

static void ev_log(char mark, const char *fmt, ...)
{
    va_list ap;
    ev_t *e = &g_log[g_log_head];
    e->seq = ++g_ev_seq;
    e->t = ev_clock();
    e->mark = mark;
    va_start(ap, fmt);
    vsnprintf(e->text, sizeof e->text, fmt, ap);
    va_end(ap);
    g_log_head = (g_log_head + 1) % LOG_RING;
    if (g_log_n < LOG_RING) g_log_n++;
    printf("UI-EV %04u %6.2f %c %s\n", e->seq, e->t, mark, e->text);
    fflush(stdout);
}

/* ================= the disc model =================================== */
typedef struct {
    unsigned lsn, len;         /* SACDTRL1 track start / length (LSN units) */
    unsigned m, s, f;          /* SACDTRL2 start MSF */
    unsigned dm, ds, df;       /* SACDTRL2 duration MSF */
} trk_t;

typedef struct {
    int present;
    char id[9];                /* TWOCHTOC / MULCHTOC */
    int channels, max_avail, frame_format, sample_freq;
    unsigned max_byte_rate;
    unsigned play_m, play_s, play_f;
    int track_count;
    unsigned toc_lba, toc_count;   /* where the block came from */
    unsigned trk_start, trk_end;   /* area audio range (BE32 @72 / @76) */
    trk_t trk[MAX_TRACKS];
    int have_tracklist;
    unsigned bytes;
    double ms;
} area_t;

typedef struct {
    int session_ok;
    char err[96];
    unsigned long long sectors;
    int ver_major, ver_minor;
    char album_cat[17], disc_cat[17];
    char album[48], artist[48];     /* SACDText lang-0 slots 0/1 (roles INFERRED) */
    int have_text;
    int year, month, day;
    int disc_type, text_area_count;
    char locale[8];
    unsigned mtoc_lba, mtoc_count;
    unsigned bytes_mtoc;
    double ms_open, ms_size, ms_mtoc, ms_area[2], ms_close;
    unsigned long long bytes_wire;   /* payload bytes this UI pulled */
    int nareas;
    area_t area[2];
} disc_t;

static void msf(char *out, size_t n, unsigned m, unsigned s, unsigned f)
{
    snprintf(out, n, "%u:%02u:%02u", m, s, f);
}

static void thousands(char *out, size_t n, unsigned long long v)
{
    char raw[32], buf[40];
    int i, len, o = 0;
    snprintf(raw, sizeof raw, "%llu", v);
    len = (int)strlen(raw);
    for (i = 0; i < len; i++) {
        buf[o++] = raw[i];
        if ((len - 1 - i) % 3 == 0 && i != len - 1 && o < (int)sizeof(buf) - 1)
            buf[o++] = ',';
    }
    buf[o] = 0;
    snprintf(out, n, "%s", buf);
}

/* printable-ASCII copy of a fixed-width on-disc string */
static void copy_field(char *dst, size_t dn, const unsigned char *src, size_t sn)
{
    size_t o = 0;
    while (o + 1 < dn && o < sn) {
        unsigned char c = src[o];
        if (c == 0) break;
        dst[o] = (c >= 0x20 && c < 0x7f) ? (char)c : '.';
        o++;
    }
    while (o > 0 && dst[o - 1] == ' ') o--;
    dst[o] = 0;
}

static unsigned be16u(const unsigned char *p)
{
    return ((unsigned)p[0] << 8) | (unsigned)p[1];
}

/* ---- Master TOC bundle: sector 0 struct + sector 1 SACDText strings ---- */
static int parse_master_toc(const unsigned char *buf, size_t n, disc_t *d)
{
    const unsigned char *text;

    if (n < 10u * SECTOR) { snprintf(d->err, sizeof d->err, "MTOC SHORT (%u B)", (unsigned)n); return 0; }
    if (memcmp(buf, "SACDMTOC", 8) != 0) {
        snprintf(d->err, sizeof d->err, "NOT A SCARLETBOOK DISC");
        return 0;
    }
    d->ver_major = buf[8];
    d->ver_minor = buf[9];
    copy_field(d->album_cat, sizeof d->album_cat, buf + 0x18, 16);
    copy_field(d->disc_cat, sizeof d->disc_cat, buf + 0x58, 16);
    d->disc_type = buf[0x50];
    d->year  = (int)be16u(buf + 0x78);
    d->month = buf[0x7a];
    d->day   = buf[0x7b];
    d->text_area_count = buf[0x80];
    copy_field(d->locale, sizeof d->locale, buf + 0x88, 2);

    /* SACDText = sector 1: 16 big-endian u16 offsets relative to that
       sector; lang 0 = slots 0..3 (title, artist, publisher, copyright —
       the role order is INFERRED in master-toc-structure.md §2.1). */
    text = buf + SECTOR;
    d->have_text = 0;
    if (memcmp(text, "SACDText", 8) == 0) {
        unsigned off0 = be16u(text + 0x10);
        unsigned off1 = be16u(text + 0x12);
        if (off0 && off0 < SECTOR) { copy_field(d->album, sizeof d->album, text + off0, SECTOR - off0); d->have_text = 1; }
        if (off1 && off1 < SECTOR) copy_field(d->artist, sizeof d->artist, text + off1, SECTOR - off1);
        /* slots 2/3 (publisher, copyright) are not shown */
    }
    return 1;
}

/* ---- one area-TOC block (40 sectors) + its SACDTRL1/SACDTRL2 tags ----- */
static int parse_area_toc(const unsigned char *buf, size_t n, unsigned lba,
                          unsigned count, area_t *a)
{
    const unsigned char *trl1 = NULL, *trl2 = NULL;
    unsigned i;

    memset(a, 0, sizeof *a);
    a->toc_lba = lba;
    a->toc_count = count;
    a->bytes = (unsigned)n;
    if (n < SECTOR) return 0;
    if (memcmp(buf, "TWOCHTOC", 8) && memcmp(buf, "MULCHTOC", 8)) return 0;
    memcpy(a->id, buf, 8);
    a->id[8] = 0;
    a->max_byte_rate = be32u(buf + 16);
    a->sample_freq = buf[20];
    a->frame_format = buf[21] & 0x0f;
    a->channels = buf[32];
    a->max_avail = buf[34];
    a->play_m = buf[64]; a->play_s = buf[65]; a->play_f = buf[66];
    a->track_count = buf[69];
    a->trk_start = be32u(buf + 72);
    a->trk_end = be32u(buf + 76);
    if (a->track_count > MAX_TRACKS) a->track_count = MAX_TRACKS;

    for (i = 0; i + SECTOR <= n; i += SECTOR) {
        const unsigned char *p = buf + i;
        if (!memcmp(p, "SACDTRL1", 8)) trl1 = p;
        else if (!memcmp(p, "SACDTRL2", 8)) trl2 = p;
    }
    if (trl1 && trl2) {
        int k;
        a->have_tracklist = 1;
        for (k = 0; k < a->track_count; k++) {
            a->trk[k].lsn = be32u(trl1 + 8 + 4 * k);
            a->trk[k].len = be32u(trl1 + 8 + 1020 + 4 * k);
            a->trk[k].m = trl2[8 + 4 * k + 0];
            a->trk[k].s = trl2[8 + 4 * k + 1];
            a->trk[k].f = trl2[8 + 4 * k + 2];
            a->trk[k].dm = trl2[8 + 1020 + 4 * k + 0];
            a->trk[k].ds = trl2[8 + 1020 + 4 * k + 1];
            a->trk[k].df = trl2[8 + 1020 + 4 * k + 2];
        }
    }
    a->present = 1;
    return 1;
}

/* ================= the wire protocol (adapted from tools/sacdclient.c) =
   Guest-only: the SIM path feeds parse_* from fixture files instead. */
#ifndef SACD_UI_SIM
static int g_sfd = -1;

static void put_varint(uint64_t v, unsigned char **p)
{
    while (v > 0x7f) { *(*p)++ = (unsigned char)(v & 0x7f) | 0x80; v >>= 7; }
    *(*p)++ = (unsigned char)v;
}

static int send_request(int op, uint64_t off, uint64_t cnt)
{
    unsigned char buf[32], *p = buf;
    *p++ = 0x08; put_varint((uint64_t)op, &p);
    *p++ = 0x10; put_varint(off, &p);
    *p++ = 0x18; put_varint(cnt, &p);
    *p++ = 0x00;                                  /* the terminator */
    if (send(g_sfd, buf, (size_t)(p - buf), 0) < 0) return -1;
    return 0;
}

static int read_varint(uint64_t *out)
{
    uint64_t v = 0;
    int shift = 0;
    for (;;) {
        unsigned char b;
        ssize_t n = recv(g_sfd, &b, 1, 0);
        if (n != 1) return -1;
        v |= (uint64_t)(b & 0x7f) << shift;
        if (!(b & 0x80)) { *out = v; return 0; }
        shift += 7;
        if (shift > 63) return -1;
    }
}

static int read_exact(void *buf, size_t n)
{
    unsigned char *p = buf;
    size_t got = 0;
    while (got < n) {
        ssize_t r = recv(g_sfd, p + got, n - got, 0);
        if (r <= 0) return -1;
        got += (size_t)r;
    }
    return 0;
}

static int read_response(int *out_type, long long *out_result,
                         unsigned char **out_data, unsigned *out_len)
{
    unsigned len = 0;
    unsigned char *data = NULL;
    int type = -1;
    long long result = 0;
    for (;;) {
        uint64_t tag;
        if (read_varint(&tag)) { free(data); return -1; }
        if (tag == 0) {
            *out_type = type; *out_result = result;
            *out_data = data; *out_len = len;
            return 0;
        }
        switch (tag & 7) {
        case 0: {
            uint64_t v;
            if (read_varint(&v)) { free(data); return -1; }
            if ((tag >> 3) == 1) type = (int)v;
            else if ((tag >> 3) == 2) result = (long long)v;
            break;
        }
        case 2: {
            uint64_t n;
            if (read_varint(&n)) { free(data); return -1; }
            if (n > (64u << 20)) { free(data); return -1; }
            free(data);
            data = (unsigned char *)malloc(n ? (size_t)n : 1);
            if (!data) return -1;
            if (n && read_exact(data, (size_t)n)) { free(data); return -1; }
            len = (unsigned)n;
            break;
        }
        default:
            free(data);
            return -1;
        }
    }
}

static int wire_connect(const char *host, char *err, size_t en)
{
    struct sockaddr_in addr;
    struct timeval tv;
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) { snprintf(err, en, "SOCKET %s", strerror(errno)); return -1; }
    /* a stalled daemon must not wedge the UI (protocol §0.7: no server-side
       timeout): bound every recv/send so a broken session renders, not hangs.
       60 s, not 8: DISC_OPEN carries sacd_authenticate (CPSA ioctl + the PSP
       detect loop), which measured 8-20 s in the guest (c122g, c123b) — an
       8 s bound turned a slow-but-good open into "OPEN NO REPLY". */
    tv.tv_sec = 60; tv.tv_usec = 0;
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof tv);
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof tv);
    memset(&addr, 0, sizeof addr);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(PORT);
    addr.sin_addr.s_addr = inet_addr(host);
    if (connect(fd, (struct sockaddr *)&addr, sizeof addr) < 0) {
        snprintf(err, en, "CONNECT %s", strerror(errno));
        close(fd);
        return -1;
    }
    g_sfd = fd;
    return 0;
}

static int wire_open(disc_t *d)
{
    int type;
    long long res;
    unsigned char *data = NULL;
    unsigned len = 0;
    double t = now_s();
    if (send_request(1, 0, 0)) { snprintf(d->err, sizeof d->err, "OPEN SEND"); return -1; }
    if (read_response(&type, &res, &data, &len)) {
        snprintf(d->err, sizeof d->err, "OPEN NO REPLY");
        return -1;
    }
    free(data);
    d->ms_open = (now_s() - t) * 1000.0;
    if (type != 1 || res != 0) {
        snprintf(d->err, sizeof d->err, "OPEN type=%d result=%lld", type, res);
        return -1;
    }
    ev_log('>', "DISC_OPEN ok (%4.0f ms)", d->ms_open);
    return 0;
}

static int wire_size(disc_t *d)
{
    int type;
    long long res;
    unsigned char *data = NULL;
    unsigned len = 0;
    double t = now_s();
    if (send_request(4, 0, 0)) { snprintf(d->err, sizeof d->err, "SIZE SEND"); return -1; }
    if (read_response(&type, &res, &data, &len)) {
        snprintf(d->err, sizeof d->err, "SIZE NO REPLY");
        return -1;
    }
    free(data);
    d->ms_size = (now_s() - t) * 1000.0;
    if (type != 4 || res <= 0) {
        snprintf(d->err, sizeof d->err, "SIZE type=%d result=%lld", type, res);
        return -1;
    }
    d->sectors = (unsigned long long)res;
    ev_log('>', "DISC_SIZE %llu sectors (%4.0f ms)", d->sectors, d->ms_size);
    return 0;
}

/* chunked read into out (count*2048 B); honours short results (§3.3) */
static int wire_read(unsigned lba, unsigned count, unsigned char *out,
                     unsigned *got, double *ms_out)
{
    unsigned done = 0;
    double t = now_s();
    unsigned char *data = NULL;
    unsigned len = 0;
    int type;
    long long res;

    while (done < count) {
        unsigned want = count - done;
        if (want > MAX_CHUNK) want = MAX_CHUNK;
        if (send_request(3, lba + done, want)) return -1;
        if (read_response(&type, &res, &data, &len)) return -1;
        if (type != 3 || res <= 0 || !data) {
            free(data);
            *got = done;
            return -1;
        }
        if (len != (unsigned)res * SECTOR) { free(data); *got = done; return -1; }
        memcpy(out + (size_t)done * SECTOR, data, len);
        free(data);
        data = NULL;
        done += (unsigned)res;
    }
    *got = done;
    if (ms_out) *ms_out = (now_s() - t) * 1000.0;
    return 0;
}

static void wire_close(disc_t *d)
{
    int type;
    long long res;
    unsigned char *data = NULL;
    unsigned len = 0;
    double t = now_s();
    if (send_request(2, 0, 0)) return;
    if (read_response(&type, &res, &data, &len) == 0) {
        free(data);
        d->ms_close = (now_s() - t) * 1000.0;
        if (type == 2) ev_log('>', "DISC_CLOSE ok (%4.0f ms)", d->ms_close);
        else ev_log('!', "DISC_CLOSE type=%d", type);
    }
    if (g_sfd >= 0) { close(g_sfd); g_sfd = -1; }
}

/* one complete client session: the whole disc picture comes from here */
static int ui_session(const char *host, disc_t *d)
{
    unsigned char *buf;
    unsigned got = 0;
    unsigned a1_lba, a1_cnt, a2_lba, a2_cnt;
    int i;

    memset(d, 0, sizeof *d);
    d->mtoc_lba = 510;                     /* the daemon's own Master TOC LBA */
    d->mtoc_count = 10;
    if (wire_connect(host, d->err, sizeof d->err)) {
        ev_log('!', "CONNECT %s FAILED", host);
        return -1;
    }
    ev_log('*', "CLIENT CONNECT %s:%d", host, PORT);
    if (wire_open(d)) { ev_log('!', "DISC_OPEN: %s", d->err); wire_close(d); return -1; }
    if (wire_size(d)) { ev_log('!', "DISC_SIZE: %s", d->err); wire_close(d); return -1; }

    buf = (unsigned char *)malloc(d->mtoc_count * SECTOR);
    if (!buf) { snprintf(d->err, sizeof d->err, "MALLOC"); wire_close(d); return -1; }
    if (wire_read(d->mtoc_lba, d->mtoc_count, buf, &got, &d->ms_mtoc)) {
        snprintf(d->err, sizeof d->err, "MTOC READ (%u/%u)", got, d->mtoc_count);
        ev_log('!', "READ lba=%u x%u FAILED", d->mtoc_lba, d->mtoc_count);
        free(buf);
        wire_close(d);
        return -1;
    }
    d->bytes_mtoc = got * SECTOR;
    d->bytes_wire += got * SECTOR;
    ev_log('>', "READ lba=%u x%u %u B (%4.0f ms)", d->mtoc_lba, got,
           got * SECTOR, d->ms_mtoc);
    if (!parse_master_toc(buf, (size_t)got * SECTOR, d)) {
        ev_log('!', "MTOC PARSE: %s", d->err);
        free(buf);
        wire_close(d);
        return -1;
    }
    a1_lba = be32u(buf + 0x40); a1_cnt = be16u(buf + 0x54);
    a2_lba = be32u(buf + 0x48); a2_cnt = be16u(buf + 0x56);
    free(buf);
    ev_log('>', "MTOC SACD %d.%02d cat=%s year=%d areas=%u/%u",
           d->ver_major, d->ver_minor, d->disc_cat[0] ? d->disc_cat : "-",
           d->year, (a1_lba != 0), (a2_lba != 0));

    {
        unsigned lbas[2], cnts[2];
        int n = 0;
        lbas[0] = a1_lba; cnts[0] = a1_cnt;
        lbas[1] = a2_lba; cnts[1] = a2_cnt;
        for (i = 0; i < 2; i++) {
            unsigned char *ab;
            if (!lbas[i] || !cnts[i] || cnts[i] > 256) continue;
            ab = (unsigned char *)malloc((size_t)cnts[i] * SECTOR);
            if (!ab) continue;
            if (wire_read(lbas[i], cnts[i], ab, &got, &d->ms_area[n])) {
                snprintf(d->err, sizeof d->err, "AREA READ lba=%u", lbas[i]);
                ev_log('!', "READ lba=%u x%u FAILED", lbas[i], cnts[i]);
                free(ab);
                continue;
            }
            d->bytes_wire += got * SECTOR;
            ev_log('>', "READ lba=%u x%u %u B (%4.0f ms)", lbas[i], got,
                   got * SECTOR, d->ms_area[n]);
            if (parse_area_toc(ab, (size_t)got * SECTOR, lbas[i], got,
                               &d->area[d->nareas])) {
                area_t *a = &d->area[d->nareas];
                char ms1[16];
                msf(ms1, sizeof ms1, a->play_m, a->play_s, a->play_f);
                ev_log('>', "AREA %s ch=%d trk=%d play=%s", a->id, a->channels,
                       a->track_count, ms1);
                d->nareas++;
            } else {
                ev_log('!', "AREA TOC lba=%u NOT VALID", lbas[i]);
            }
            free(ab);
        }
    }
    wire_close(d);
    d->session_ok = 1;
    return 0;
}
#endif /* !SACD_UI_SIM — the wire client */

/* ================= the event model (THE design contract) =================
 *
 * Polled inputs become a fixed set of typed events; ONE pure function
 * (apply_event) moves state; a frame is painted only when apply_event reports
 * a change. Rendering never happens inside event handling, and event handling
 * never touches the framebuffer — that split is what makes a scene replayable
 * and a frame diffable.
 *
 *   source (pollable, non-blocking)        event        state it moves
 *   -------------------------------        -----        -------------
 *   frame clock              (30 Hz)  ->   EV_TICK      (the glass clock)
 *   /proc/net/tcp             (4 Hz)  ->   EV_TCP       g_tel.listen_2002/clients_2002
 *   /proc/<pid>/cmdline       (4 Hz*) ->   EV_PID       g_tel.daemon_pid   (*until found)
 *   /proc/net/dev  (lo)       (4 Hz)  ->   EV_WIRE      g_tel.wire_bytes/wire_mb
 *   stat(<watch file>)        (4 Hz)  ->   EV_PROGRESS  g_prog.* (SACD_UI_WATCH_FILE)
 *   the startup session        (once) ->   EV_SESSION   g_disc.session_ok/err
 *
 * WHY THERE IS NO /proc/<pid>/io HERE: the BX510 guest kernel (2.6.35) was
 * built without CONFIG_TASK_IO_ACCOUNTING, so /proc/<pid>/io does not exist
 * there at all (fires pio1/pio2: `cat /res/proc/self/io` -> No such file or
 * directory, while /res/proc/net/tcp and /res/proc/net/dev read fine). The
 * sources below are the ones that DO exist, and each measures exactly one
 * thing: the loopback device's byte counter is the WIRE, and the rip file's
 * size is the RIP's progress. The panel's own "IO" label is the old name for
 * the first of those and is kept until the layout lane re-accepts its goldens
 * (renaming it changes the frame).
 *
 * DETERMINISM RULES — the reason the shape above is this shape:
 *
 *  1. ONE cadence per source, both named here: FRAME_PERIOD_S for the tick,
 *     TEL_PERIOD_S for the /proc sources. No source is bursty, so the ring
 *     depth is <= 5 and a drain never has to reorder anything.
 *  2. FIXED source order inside one drain: TICK -> TCP -> PID -> WIRE ->
 *     PROGRESS (the order the loop pushes them in). The ring is FIFO, so the
 *     apply order in a pass is that order in every pass.
 *  3. Every log line carries a monotone sequence number, printed as
 *     `UI-EV <seq> <t> <mark> <text>`, so a transcript's log ORDER is
 *     assertable without parsing timestamps.
 *  4. apply_event() is the ONLY writer of g_tel/g_prog and the only place a
 *     transition is logged. Same event sequence -> same state -> same log.
 *  5. draw_frame() reads state and nothing else (its only clock input is the
 *     `t` it is handed), so a state-identical repaint is byte-identical.
 *
 * Drain-all-per-pass, not one-event-per-pass: a pass pushes at most one event
 * per source and the order is "clock first, samples after", so draining the
 * whole ring in FIFO order is both simpler and the only choice that keeps a
 * burst of samples from starving the tick. The ring is still a real fixed-size
 * ring with a drop counter, so a depth bug shows up as a count, not as
 * corruption.
 *
 * The /proc samplers are PURE in the sense that matters here: (state_in) ->
 * (sample, events[]). They read a file, touch no global, log nothing. The
 * transition (sample -> state change -> log line -> repaint) happens only in
 * apply_event().
 */
typedef enum { EV_TICK, EV_TCP, EV_PID, EV_WIRE, EV_PROGRESS, EV_SESSION } ev_kind_t;

typedef struct {
    ev_kind_t kind;
    union {
        struct { int listen, clients; } tcp;
        struct { int pid; } pid;
        /* both byte samples are CUMULATIVE counters, and that is the only
           thing they have in common: .wire is the loopback device's received
           bytes (the wire), .rip is the rip file's size (one client's progress) */
        struct { unsigned long long bytes; } wire;
        struct { unsigned long long bytes; } rip;
        struct { int ok; char err[96]; } session;
    } u;
} uev_t;

/* ---- state (the only globals the event model writes) ---- */
typedef struct {
    int listen_2002;
    int clients_2002;
    int clients_seen;
    int daemon_pid;
    unsigned long long wire_bytes;   /* /proc/net/dev lo, cumulative */
    double wire_mb;                  /* bytes over one TEL_PERIOD_S window */
    int proc_ok;
} tel_t;

/* The watched second client (opt-in: SACD_UI_WATCH_FILE — the file it rips
   into). The UI opens no session for it: the daemon's single shared accept slot
   (§0.6) is never contended. The file's SIZE is the progress, exactly — it is
   the bytes that client has already written. */
typedef struct {
    int active;                    /* a first sample arrived */
    int stalled;                   /* consecutive samples with no growth */
    int done;                      /* reported finished: stop re-reporting */
    unsigned long long last_bytes; /* the previous file size */
    unsigned long long bytes;      /* the file size == bytes ripped so far */
    unsigned long long sectors;    /* bytes / SECTOR */
    double mb_s;
    double last_log_t;
} prog_t;

static disc_t g_disc;              /* the disc picture (the session's read) */
static tel_t g_tel;
static prog_t g_prog;
static char g_watch_file[128];     /* SACD_UI_WATCH_FILE — the rip target */
static int g_dirty;                /* set by apply_event(), cleared by the painter */

/* ---- the fixed-size, allocation-free event ring ---- */
static uev_t g_evq[EVQ_N];
static int g_evq_head, g_evq_n;
static unsigned g_evq_drops;

static void ev_push(const uev_t *e)
{
    if (g_evq_n >= EVQ_N) { g_evq_drops++; return; }
    g_evq[(g_evq_head + g_evq_n) % EVQ_N] = *e;
    g_evq_n++;
}

static void ev_push_kind(ev_kind_t k)
{
    uev_t e;
    memset(&e, 0, sizeof e);
    e.kind = k;
    ev_push(&e);
}

static void ev_push_tcp(int listen, int clients)
{
    uev_t e;
    memset(&e, 0, sizeof e);
    e.kind = EV_TCP;
    e.u.tcp.listen = listen;
    e.u.tcp.clients = clients;
    ev_push(&e);
}

static void ev_push_pid(int pid)
{
    uev_t e;
    memset(&e, 0, sizeof e);
    e.kind = EV_PID;
    e.u.pid.pid = pid;
    ev_push(&e);
}

/* EV_WIRE (the loopback wire) and EV_PROGRESS (the rip file) are both "this
   counter now reads N", from sources that differ; the kind says which. */
static void ev_push_bytes(ev_kind_t kind, unsigned long long bytes)
{
    uev_t e;
    memset(&e, 0, sizeof e);
    e.kind = kind;
    if (kind == EV_WIRE) e.u.wire.bytes = bytes;
    else e.u.rip.bytes = bytes;
    ev_push(&e);
}

static void ev_push_session(int ok, const char *err)
{
    uev_t e;
    memset(&e, 0, sizeof e);
    e.kind = EV_SESSION;
    e.u.session.ok = ok;
    if (err && err[0]) snprintf(e.u.session.err, sizeof e.u.session.err, "%s", err);
    ev_push(&e);
}

/* bytes accumulated over ONE telemetry window -> MB/s. The window IS
   TEL_PERIOD_S, so the old hard-typed `* 4.0` (a bare 1/0.25 s) is derived
   from the cadence constant now and cannot drift away from it. */
static double window_mb_s(unsigned long long delta)
{
    return (double)delta / (1024.0 * 1024.0) / TEL_PERIOD_S;
}

/* A window with no bytes HALVES the displayed rate instead of snapping to
   zero: a hard zero makes one idle sample look like a stall, and this panel is
   read by eye. Below RATE_FLOOR_MB_S the display settles at 0.0. */
#define RATE_DECAY 0.5
#define RATE_FLOOR_MB_S 0.05
static double rate_next(double prev, unsigned long long delta)
{
    double r = delta ? window_mb_s(delta) : prev * RATE_DECAY;
    return r < RATE_FLOOR_MB_S ? 0.0 : r;
}

/* ---- the ONE state machine: (event, state) -> state, + a log line ----
   Returns 1 when state changed (and sets g_dirty). No rendering here. */
static int apply_event(const uev_t *e)
{
    int changed = 0;

    switch (e->kind) {
    case EV_TICK:
        /* the frame clock has no state of its own: it exists so every drain
           starts with the same event and so the blink + the fps counters have
           one time base (rule 2). */
        break;

    case EV_TCP:
        g_tel.proc_ok = 1;
        if (e->u.tcp.listen != g_tel.listen_2002) {
            ev_log('*', e->u.tcp.listen ? "LISTENER :2002 UP"
                                        : "LISTENER :2002 DOWN");
            g_tel.listen_2002 = e->u.tcp.listen;
            changed = 1;
        }
        if (e->u.tcp.clients != g_tel.clients_2002) {
            ev_log('*', e->u.tcp.clients > g_tel.clients_2002
                        ? "DAEMON CLIENT CONNECT (%d live)"
                        : "DAEMON CLIENT GONE (%d live)", e->u.tcp.clients);
            g_tel.clients_2002 = e->u.tcp.clients;
            if (g_tel.clients_2002 > g_tel.clients_seen)
                g_tel.clients_seen = g_tel.clients_2002;
            changed = 1;
        }
        break;

    case EV_PID:
        if (e->u.pid.pid > 0 && e->u.pid.pid != g_tel.daemon_pid) {
            g_tel.daemon_pid = e->u.pid.pid;
            ev_log('>', "DAEMON pid=%d (%s)", g_tel.daemon_pid, DAEMON_CMD);
            changed = 1;
        }
        break;

    case EV_WIRE: {
        double r;
        if (e->u.wire.bytes < g_tel.wire_bytes) {
            /* a cumulative device counter that went backwards is a new
               counter (the interface was re-created), not negative traffic */
            ev_log('*', "WIRE COUNTER RESET");
            g_tel.wire_bytes = e->u.wire.bytes;
            g_tel.wire_mb = 0.0;
            changed = 1;
            break;
        }
        r = rate_next(g_tel.wire_mb, e->u.wire.bytes - g_tel.wire_bytes);
        g_tel.wire_bytes = e->u.wire.bytes;
        if (r != g_tel.wire_mb) { g_tel.wire_mb = r; changed = 1; }
        break;
    }

    case EV_PROGRESS: {
        unsigned long long delta = 0;

        if (!g_prog.active) {
            /* the watch target appeared: progress starts from its size */
            memset(&g_prog, 0, sizeof g_prog);
            g_prog.active = 1;
            g_prog.last_bytes = e->u.rip.bytes;
            g_prog.bytes = e->u.rip.bytes;
            g_prog.sectors = g_prog.bytes / SECTOR;
            g_prog.last_log_t = ev_clock();
            ev_log('*', "RIP WATCH file=%s", g_watch_file[0] ? g_watch_file : "(none)");
            changed = 1;
        }
        if (g_prog.done) break;        /* a finished rip is not re-reported */

        if (e->u.rip.bytes > g_prog.last_bytes) {
            delta = e->u.rip.bytes - g_prog.last_bytes;
            g_prog.stalled = 0;
        } else if (g_prog.bytes > 0) {
            /* two quiet samples (0.5 s at TEL_PERIOD_S) = the rip finished */
            g_prog.stalled++;
        }
        g_prog.bytes = e->u.rip.bytes;      /* the file size IS the truth */
        g_prog.last_bytes = e->u.rip.bytes;
        g_prog.sectors = g_prog.bytes / SECTOR;
        g_prog.mb_s = rate_next(g_prog.mb_s, delta);

        if (g_prog.stalled >= 2) {
            g_prog.done = 1;
            ev_log('>', "RIP DONE %llu sectors", g_prog.sectors);
            changed = 1;
        } else if (g_prog.bytes > 0 &&
                   ev_clock() - g_prog.last_log_t >= PROGRESS_LOG_S) {
            /* one RIP line per PROGRESS_LOG_S of event time: the rendered log
               is a fixed 7-line window, so an unthrottled line every 250 ms
               would erase the session lines before anyone read them. The
               counters are not on canvas, so a silent sample repaints nothing. */
            g_prog.last_log_t = ev_clock();
            ev_log('>', "RIP %llu sectors %3.1f MB/s", g_prog.sectors, g_prog.mb_s);
            changed = 1;
        }
        break;
    }

    case EV_SESSION:
        g_disc.session_ok = e->u.session.ok;
        if (!g_disc.session_ok) {
            if (e->u.session.err[0])
                snprintf(g_disc.err, sizeof g_disc.err, "%s", e->u.session.err);
            ev_log('!', "SESSION FAILED: %s", g_disc.err);
        } else {
            ev_log('>', "SESSION COMPLETE — disc picture from the wire");
        }
        changed = 1;
        break;
    }
    if (changed) g_dirty = 1;
    return changed;
}

/* ---- the transition table the unit tests read ---------------------------
   Compiled ONLY into the test build (-DSACD_UI_EVENTS_TEST). A guest run's
   stdout is a transcript of what it LOGGED; the tests want what it COMPUTED,
   i.e. the (event, state) pair the determinism rules are about. One line per
   applied event, in apply order, with the state it produced. */
#ifdef SACD_UI_EVENTS_TEST
static const char *ev_kind_name(ev_kind_t k)
{
    switch (k) {
    case EV_TICK: return "tick";
    case EV_TCP: return "tcp";
    case EV_PID: return "pid";
    case EV_WIRE: return "wire";
    case EV_PROGRESS: return "progress";
    case EV_SESSION: return "session";
    }
    return "?";
}

static void evtrace(const uev_t *e, int changed)
{
    printf("UI-EVAPP kind=%s changed=%d listen=%d clients=%d clients_seen=%d "
           "daemon_pid=%d wire_bytes=%llu wire_mb=%.3f proc=%d "
           "rip_bytes=%llu rip_sectors=%llu rip_mb_s=%.3f session_ok=%d "
           "seq=%u drops=%u\n",
           ev_kind_name(e->kind), changed, g_tel.listen_2002,
           g_tel.clients_2002, g_tel.clients_seen, g_tel.daemon_pid,
           g_tel.wire_bytes, g_tel.wire_mb, g_tel.proc_ok, g_prog.bytes,
           g_prog.sectors, g_prog.mb_s, g_disc.session_ok, g_ev_seq,
           g_evq_drops);
}
#else
#define evtrace(e, changed) ((void)0)
#endif

/* apply every queued event, FIFO. -> events applied. */
static int ev_drain(void)
{
    int n = 0;
    while (g_evq_n > 0) {
        uev_t e = g_evq[g_evq_head];
        int changed;
        g_evq_head = (g_evq_head + 1) % EVQ_N;
        g_evq_n--;
        changed = apply_event(&e);
        (void)changed;             /* the trace is compiled out of guest builds */
        evtrace(&e, changed);
        n++;
    }
    return n;
}

/* The 2 Hz blink is the ONE motion that repaints without a state change: its
   phase transition forces a paint, so a static scene repaints twice a second
   instead of thirty times. draw_frame() derives the same phase from the `t` it
   is handed (BLINK_HZ), so the two cannot disagree. */
static int g_blink_phase;
static int blink_flip(double t)
{
    int p = ((int)(t * BLINK_HZ) & 1);
    if (p == g_blink_phase) return 0;
    g_blink_phase = p;
    return 1;
}

/* ================= /proc samplers (pure: file -> sample) ==============
   Guest only: a SIM run gets its samples from a replay script instead. */
#ifndef SACD_UI_SIM
static long read_small(const char *path, char *b, size_t n)
{
    FILE *f = fopen(path, "r");
    size_t got;
    if (!f) return -1;
    got = fread(b, 1, n - 1, f);
    fclose(f);
    b[got] = 0;
    return (long)got;
}

/* /proc/net/tcp -> (listen, clients) on :2002. No state, no logging: the
   transition lives in apply_event(). */
static int tel_sample_tcp(int *listen_out, int *clients_out)
{
    char b[32768], *ln, *save = NULL;
    int clients = 0, listen = 0;
    if (read_small("/proc/net/tcp", b, sizeof b) < 0 &&
        read_small("/res/proc/net/tcp", b, sizeof b) < 0)
        return -1;
    for (ln = strtok_r(b, "\n", &save); ln; ln = strtok_r(NULL, "\n", &save)) {
        char la[16], ra[16], st[8];
        unsigned lport = 0, rport = 0;
        if (sscanf(ln, " %*d: %15[0-9A-Fa-f]:%x %15[0-9A-Fa-f]:%x %7s",
                   la, &lport, ra, &rport, st) != 5) continue;
        if (lport != PORT) continue;
        if (!strcmp(st, "0A")) listen = 1;
        else if (!strcmp(st, "01") || !strcmp(st, "08")) clients++;
    }
    *listen_out = listen;
    *clients_out = clients;
    return 0;
}

/* the daemon's pid by cmdline; -1 while it is not up yet */
static int tel_find_pid(const char *name)
{
    DIR *d;
    struct dirent *e;
    int found = -1;
    d = opendir("/proc");
    if (!d) d = opendir("/res/proc");
    if (!d) return -1;
    while ((e = readdir(d))) {
        char path[64], cmd[256];
        long pid = atol(e->d_name);
        if (pid <= 0) continue;
        snprintf(path, sizeof path, "/proc/%ld/cmdline", pid);
        if (read_small(path, cmd, sizeof cmd) <= 0) {
            snprintf(path, sizeof path, "/res/proc/%ld/cmdline", pid);
            if (read_small(path, cmd, sizeof cmd) <= 0) continue;
        }
        if (strstr(cmd, name)) { found = (int)pid; break; }
    }
    closedir(d);
    return found;
}

/* /proc/net/dev -> the loopback device's cumulative RECEIVED bytes. Loopback
   frames land on the receive side exactly once, which is why this is the
   receive column and not the sum of both (a kernel that also accounts the
   transmit side would double every byte). This is the WIRE, not a process: the
   guest has no /proc/<pid>/io at all (see the event-model header). */
static int tel_sample_wire(unsigned long long *bytes_out)
{
    char b[8192], *ln, *save = NULL;
    if (read_small("/proc/net/dev", b, sizeof b) <= 0 &&
        read_small("/res/proc/net/dev", b, sizeof b) <= 0)
        return -1;
    for (ln = strtok_r(b, "\n", &save); ln; ln = strtok_r(NULL, "\n", &save)) {
        char *colon = strchr(ln, ':');
        unsigned long long rx = 0;
        if (!colon) continue;
        *colon = 0;
        while (*ln == ' ' || *ln == '\t') ln++;
        if (strcmp(ln, "lo")) continue;
        if (sscanf(colon + 1, "%llu", &rx) != 1) return -1;
        *bytes_out = rx;
        return 0;
    }
    return -1;
}

/* the rip's output file, growing: the progress source that EXISTS in this
   guest. A file size cannot lie about how far the client got. */
static int tel_sample_file(const char *path, unsigned long long *bytes_out)
{
    struct stat st;
    if (!path || !path[0] || stat(path, &st) != 0) return -1;
    *bytes_out = (unsigned long long)st.st_size;
    return 0;
}
#endif /* !SACD_UI_SIM — /proc samplers */

/* ================= framebuffer open (proven pool path) ================ */
#ifndef SACD_UI_SIM
static int pool_open(const char *dev)
{
    struct fb_var_screeninfo vi;
    struct fb_fix_screeninfo fi;
    size_t len, hdr = 0;
    int fd = open(dev, O_RDWR);
    void *m;

    if (fd < 0) {
        printf("UI: fb open %s failed: %s\n", dev, strerror(errno));
        return 0;
    }
    if (ioctl(fd, FBIOGET_VSCREENINFO, &vi) == 0 &&
        ioctl(fd, FBIOGET_FSCREENINFO, &fi) == 0 &&
        vi.xres && vi.yres && fi.line_length) {
        size_t fb_bytes = (size_t)fi.line_length * (size_t)vi.yres;
        size_t pool_len = fb_bytes + 0x1000u;      /* MT85 pool0: header page + pixels */
        printf("UI: fbdev %s %ux%u bpp=%u stride=%u smem=%u\n", dev, vi.xres,
               vi.yres, vi.bits_per_pixel, fi.line_length, fi.smem_len);
        SCAL = (int)vi.xres / CW;
        if (SCAL < 1) SCAL = 1;
        g_visible_w = (int)vi.xres;
        g_visible_h = (int)vi.yres;
        if (getenv("SACD_UI_SCALE")) SCAL = atoi(getenv("SACD_UI_SCALE"));
        if (SCAL < 1) SCAL = 1;
        len = pool_len;
        m = mmap(NULL, len, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (m != MAP_FAILED) {
            hdr = 0x1000u;
            printf("UI: vendor pool mapped len=%zu (pixels=%zu +0x1000)\n", len, fb_bytes);
        } else {
            len = fi.smem_len ? fi.smem_len : fb_bytes;
            m = mmap(NULL, len, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        }
        if (m == MAP_FAILED) {
            printf("UI: fbdev mmap %zu failed: %s\n", len, strerror(errno));
            close(fd);
            return 0;
        }
        fb = (unsigned int *)((unsigned char *)m + hdr);
        pitch_px = fi.line_length / (vi.bits_per_pixel / 8);
        close(fd);
        printf("UI: geom %ux%u scale=%d pitch=%d hdr=0x%zx canvas=%dx%d\n",
               g_visible_w, g_visible_h, SCAL, pitch_px, hdr, CW * SCAL, CH * SCAL);
        return 1;
    }
    printf("UI: fbdev geometry read failed\n");
    close(fd);
    return 0;
}
#else
static int sim_open(void)
{
    if (getenv("SACD_UI_SCALE")) SCAL = atoi(getenv("SACD_UI_SCALE"));
    if (SCAL < 1) SCAL = 1;
    g_visible_w = CW * SCAL;
    g_visible_h = CH * SCAL;
    pitch_px = g_visible_w;
    fb = (unsigned int *)calloc((size_t)pitch_px * (size_t)(CH * SCAL), 4);
    if (!fb) return 0;
    printf("UI: SIM canvas %dx%d scale=%d\n", CW * SCAL, CH * SCAL, SCAL);
    return 1;
}

static int sim_write_ppm(const char *path)
{
    FILE *f = fopen(path, "wb");
    int x, y;
    if (!f) return 0;
    fprintf(f, "P6\n%d %d\n255\n", g_visible_w, CH * SCAL);
    for (y = 0; y < CH * SCAL; y++)
        for (x = 0; x < g_visible_w; x++) {
            unsigned v = fb[(size_t)y * pitch_px + x];
            unsigned char rgb[3] = { (unsigned char)((v >> 16) & 0xff),
                                     (unsigned char)((v >> 8) & 0xff),
                                     (unsigned char)(v & 0xff) };
            fwrite(rgb, 1, 3, f);
        }
    fclose(f);
    printf("UI: wrote %s (%dx%d)\n", path, g_visible_w, CH * SCAL);
    return 1;
}
#endif

/* ================= render ============================================= */
static void draw_frame(double t, unsigned frames, double fps)
{
    char l[160], m1[16], m2[16], num[40];
    int y, i;
    int pulse = ((int)(t * BLINK_HZ) & 1);

    clear_canvas(C_BG);
    spec_begin("frame");
    box(0, 0, CW, CH, C_FRAME);

    /* ---- title bar ---- */
    spec_begin("title");
    text_top("SACD RECONSTRUCT", 12, 8, 17, C_PHOS);
    snprintf(l, sizeof l, "BX510 DAEMON CONSOLE");
    text_right(l, CW - 12, 10, 10, C_DIM);
    rect(12, 30, CW - 24, 1, C_RULE);

    /* ---- status block ---- */
    spec_begin("status");
    snprintf(l, sizeof l, "DAEMON  %s:%d %s   CLIENTS %d   PID %d   IO %.1f MB/s",
             "127.0.0.1", PORT,
             g_tel.listen_2002 ? "LISTEN" : "CLOSED",
             g_tel.clients_2002, g_tel.daemon_pid, g_tel.wire_mb);
    text_top(l, 12, 37, 11, g_tel.listen_2002 ? C_BRIGHT : C_RED);
    /* the live link lamp */
    rect(LAMP_X, LAMP_Y, LAMP_W, LAMP_H,
         g_tel.clients_2002 ? (pulse ? C_PHOS : C_DIM)
                                              : (g_tel.listen_2002 ? C_AMBER : C_RED));

    if (g_disc.session_ok || g_disc.sectors) {
        thousands(num, sizeof num, g_disc.sectors);
        snprintf(l, sizeof l, "DISC    %s SECTORS   SACD %d.%02d   CAT %s   %04d-%02d-%02d",
                 num, g_disc.ver_major, g_disc.ver_minor,
                 g_disc.disc_cat[0] ? g_disc.disc_cat : "-",
                 g_disc.year, g_disc.month, g_disc.day);
        text_top(l, 12, 51, 11, C_BODY);
        if (g_disc.have_text)
            snprintf(l, sizeof l, "ALBUM   %s        ARTIST   %s",
                     g_disc.album[0] ? g_disc.album : "-",
                     g_disc.artist[0] ? g_disc.artist : "-");
        else
            snprintf(l, sizeof l, "ALBUM   -        ARTIST   -        (no SACDText)");
        text_top(l, 12, 65, 11, C_BODY);
    } else {
        snprintf(l, sizeof l, "DISC    NO SESSION  %s", g_disc.err);
        text_top(l, 12, 51, 11, C_RED);
        text_top("ALBUM   -        ARTIST   -", 12, 65, 11, C_GREY);
    }
    rect(12, 80, CW - 24, 1, C_RULE);

    /* ---- the two area panels ---- */
    for (i = 0; i < 2; i++) {
        spec_begin(i == 0 ? "panel_2ch" : "panel_multi");
        int px0 = (i == 0) ? 12 : 324;
        int pw = 304;
        unsigned head = (i == 0) ? C_CYAN : C_MAGENTA;
        area_t *a = (i < g_disc.nareas) ? &g_disc.area[i] : NULL;

        rect(px0, 88, pw, 104, C_PANELBG);
        box(px0, 88, pw, 104, C_RULE);
        if (!a) {
            text_top(i == 0 ? "2-CHANNEL AREA" : "MULTI-CHANNEL AREA",
                     px0 + 6, 93, 11, C_GREY);
            text_top("no area TOC", px0 + 6, 108, 10, C_DIM);
            continue;
        }
        msf(m1, sizeof m1, a->play_m, a->play_s, a->play_f);
        snprintf(l, sizeof l, "%s   %d CH   %s",
                 (i == 0) ? "2-CHANNEL" : "MULTI-CHANNEL", a->channels, m1);
        text_top(l, px0 + 6, 92, 11, head);
        snprintf(l, sizeof l, "%d TRACKS   LBA %u..%u", a->track_count,
                 a->trk_start, a->trk_end);
        text_top(l, px0 + 6, 103, 9, C_DIM);

        text_top("#", px0 + 8, 114, 9, C_DIM);
        text_top("START", px0 + 30, 114, 9, C_DIM);
        text_top("LENGTH", px0 + 116, 114, 9, C_DIM);
        text_top("LSN", px0 + 206, 114, 9, C_DIM);
        rect(px0 + 6, 123, pw - 12, 1, C_RULE);

        for (y = 0; y < a->track_count && y < 6; y++) {
            trk_t *k = &a->trk[y];
            int ly = 126 + y * 11;
            msf(m1, sizeof m1, k->m, k->s, k->f);
            msf(m2, sizeof m2, k->dm, k->ds, k->df);
            snprintf(l, sizeof l, "%d", y + 1);
            text_top(l, px0 + 8, ly, 10, C_BRIGHT);
            text_top(m1, px0 + 30, ly, 10, C_BODY);
            text_top(m2, px0 + 116, ly, 10, C_BODY);
            snprintf(l, sizeof l, "%u", k->lsn);
            text_top(l, px0 + 206, ly, 10, C_DIM);
        }
        /* No '+N more' row: the six table rows are 126 + y*11, so the last one
           ends ON the panel's bottom border (y=191) and a seventh row would be
           drawn at y=192 — outside the panel, across the y=196 rule. The count
           line above ("%d TRACKS") already states the full track total, so the
           overflow row is suppressed rather than drawn outside its panel. */
    }
    spec_begin("rule_panels_end");
    rect(12, 196, CW - 24, 1, C_RULE);

    /* ---- event log (newest last) ---- */
    spec_begin("log");
    text_top("EVENT LOG", 12, 200, 10, C_DIM);
    {
        int shown = g_log_n < LOG_SHOWN ? g_log_n : LOG_SHOWN;
        int start = (g_log_head - shown + LOG_RING) % LOG_RING;
        for (i = 0; i < shown; i++) {
            ev_t *e = &g_log[(start + i) % LOG_RING];
            int ly = 212 + i * 12;
            unsigned col = (e->mark == '!') ? C_RED
                         : (e->mark == '*') ? C_AMBER
                         : (i == shown - 1) ? C_BRIGHT : C_BODY;
            snprintf(l, sizeof l, "%6.2f %s", e->t, e->text);
            text_top(l, 12, ly, 10, col);
        }
        if (!shown) text_top("(no events yet)", 12, 212, 10, C_GREY);
    }
    spec_begin("rule_log_end");
    rect(12, 296, CW - 24, 1, C_RULE);

    /* ---- session summary + client watch ---- */
    spec_begin("summary");
    snprintf(l, sizeof l,
             "SESSION  open %.0f ms   size %.0f ms   mtoc %.0f ms   a1 %.0f ms   a2 %.0f ms   close %.0f ms",
             g_disc.ms_open, g_disc.ms_size, g_disc.ms_mtoc,
             g_disc.ms_area[0], g_disc.ms_area[1], g_disc.ms_close);
    text_top(l, 12, 301, 10, C_BODY);
    thousands(num, sizeof num, g_disc.bytes_wire);
    snprintf(l, sizeof l,
             "WIRE     %s B READ BY THIS UI   areas %d   client sessions seen: %d   listener %s",
             num, g_disc.nareas, g_tel.clients_seen,
             g_tel.listen_2002 ? "UP" : "DOWN");
    text_top(l, 12, 314, 10, C_BODY);
    snprintf(l, sizeof l,
             "RENDER   %ux%u panel   font %s   %u frames   %.1f fps   t=%.1f s",
             g_visible_w, g_visible_h,
             g_font_ok ? g_font_path : "(5x7 fallback)", frames, fps, t);
    text_top(l, 12, 327, 10, C_GREY);
    /* blinking cursor + state chip */
    /* blinking cursor left of the state chip */
    {
        int w = text_w(g_disc.session_ok ? "SESSION OK" : "SESSION FAIL", 9 * SCAL) / SCAL;
        if (pulse) rect(CW - 14 - w - 14, CURSOR_Y, CURSOR_W, CURSOR_H, C_PHOS);
    }
    snprintf(l, sizeof l, "%s", g_disc.session_ok ? "SESSION OK" : "SESSION FAIL");
    text_right(l, CW - 14, 340, 9, g_disc.session_ok ? C_PHOS : C_RED);
}

#ifdef SACD_UI_SIM
/* ---- the SIM drivers -------------------------------------------------
 * Two ways to reach the same state machine, deliberately different:
 *
 *   the argv EPISODE (below)  sets state DIRECTLY. It is the seeded GOLDEN:
 *                             its log lines and its frame are what the frame
 *                             goldens were taken from, so routing it through
 *                             apply_event() (which would add transition lines
 *                             a real run would have logged) would change the
 *                             frame. Left exactly as it was.
 *   the EVENT REPLAY          feeds synthetic events through the SAME
 *                             apply_event() the guest loop uses. This is the
 *                             deterministic scenario driver: same script ->
 *                             same state -> same log -> same frames.
 */

/* Load the real TOC fixtures into g_disc: the disc picture without a wire.
   quiet=0 (the argv golden episode) also logs the READ/AREA lines it always
   logged; quiet=1 (an event replay) only parses — a replay's log belongs to
   its events, not to the fixture. Returns -1 if the Master TOC cannot be
   opened. */
static int sim_load_fixtures(const char *mtoc, const char *a1, const char *a2,
                             int quiet)
{
    unsigned char *buf;
    FILE *f;
    size_t n;
    unsigned lba, cnt;

    f = fopen(mtoc, "rb");
    if (!f) { printf("SIM: cannot open %s\n", mtoc); return -1; }
    buf = (unsigned char *)malloc(256 * SECTOR);
    n = fread(buf, 1, 10 * SECTOR, f);
    fclose(f);
    g_disc.sectors = 1064208;
    g_disc.mtoc_lba = 510; g_disc.mtoc_count = 10;
    g_disc.ms_open = 12; g_disc.ms_size = 7; g_disc.ms_mtoc = 1840;
    g_disc.bytes_wire = n;
    if (!parse_master_toc(buf, n, &g_disc)) printf("SIM: mtoc parse: %s\n", g_disc.err);
    lba = be32u(buf + 0x40); cnt = be16u(buf + 0x54);
    if (!quiet) ev_log('>', "READ lba=%u x%u %u B (SIM)", g_disc.mtoc_lba, 10, (unsigned)n);
    free(buf);
    for (int k = 0; k < 2; k++) {
        const char *fn = k == 0 ? a1 : a2;
        unsigned char *ab;
        if (!fn) continue;
        f = fopen(fn, "rb");
        if (!f) continue;
        ab = (unsigned char *)malloc((size_t)(cnt ? cnt : 40) * SECTOR);
        n = fread(ab, 1, (size_t)(cnt ? cnt : 40) * SECTOR, f);
        fclose(f);
        g_disc.bytes_wire += n;
        g_disc.ms_area[k] = 2600 + k * 180;
        if (parse_area_toc(ab, n, lba, (unsigned)(n / SECTOR), &g_disc.area[g_disc.nareas])) {
            if (!quiet) {
                ev_log('>', "READ lba=%u x%u %u B (SIM)", lba, (unsigned)(n / SECTOR), (unsigned)n);
                ev_log('>', "AREA %s ch=%d trk=%d", g_disc.area[g_disc.nareas].id,
                       g_disc.area[g_disc.nareas].channels,
                       g_disc.area[g_disc.nareas].track_count);
            }
            g_disc.nareas++;
        }
        free(ab);
        lba = 353804; cnt = 40;
    }
    return 0;
}

/* every painted replay frame lands in $SACD_UI_SIM_FRAMES as frame-NNN.ppm */
static char g_sim_frames_dir[256];
static unsigned g_sim_frame;

static void sim_paint(void)
{
    char path[320];
    draw_frame(g_clock_v, g_sim_frame + 1, 0.0);
    g_sim_frame++;
    if (g_sim_frames_dir[0]) {
        snprintf(path, sizeof path, "%s/frame-%03u.ppm", g_sim_frames_dir,
                 g_sim_frame);
        sim_write_ppm(path);
    }
    g_dirty = 0;
}

/* ---- SACD_UI_SIM_SCRIPT replay: the deterministic scenario driver -----
 * One event per line, applied through the SAME apply_event() the guest uses.
 * Blank lines and '#' comments are skipped. Grammar:
 *
 *   tick [secs]              advance the event clock (default FRAME_PERIOD_S)
 *   tcp <listen> <clients>   one /proc/net/tcp sample (0/1, live count)
 *   pid <pid>                the daemon's pid (a /proc/<pid>/cmdline scan)
 *   wire <bytes>             one /proc/net/dev lo sample (cumulative)
 *   watch <path>             the rip file's path (what the log names)
 *   rip <bytes>              one stat(<watch file>) sample (the file's size)
 *   session ok|fail [text]   the startup session's outcome
 *
 * A line that changes state paints a frame — the same rule the guest loop
 * uses — plus the scenario's own t=0 frame. Painted frames are written to
 * $SACD_UI_SIM_FRAMES/frame-NNN.ppm, and the final one also to the argv output
 * path. Same script -> same frames byte for byte: the clock is the script's own
 * ticks, and nothing in this path reads the wall clock.
 *
 * Usage: SACD_UI_SIM_SCRIPT=events.txt sacd_ui <out.ppm>
 *        (or, with real disc bytes: sacd_ui <mtoc> <a1> <a2> <out.ppm>)
 */
static int sim_replay(const char *path, const char *out)
{
    FILE *f = fopen(path, "r");
    char line[256];
    unsigned applied = 0;

    if (!f) { printf("SIM: cannot open script %s\n", path); return 0; }
    sim_paint();                     /* the scenario's t=0 frame */
    while (fgets(line, sizeof line, f)) {
        char *p = line, *nl;
        while (*p == ' ' || *p == '\t') p++;
        nl = strchr(p, '\n'); if (nl) *nl = 0;
        if (!*p || *p == '#') continue;
        if (!strncmp(p, "tick", 4)) {
            double dt = p[4] ? atof(p + 4) : FRAME_PERIOD_S;
            g_clock_v += dt;
            ev_push_kind(EV_TICK);
        } else if (!strncmp(p, "tcp ", 4)) {
            int listen = 0, clients = 0;
            if (sscanf(p + 4, "%d %d", &listen, &clients) != 2) goto bad;
            ev_push_tcp(listen, clients);
        } else if (!strncmp(p, "watch ", 6)) {
            snprintf(g_watch_file, sizeof g_watch_file, "%s", p + 6);
            continue;                 /* configuration, not an event */
        } else if (!strncmp(p, "rip ", 4)) {
            unsigned long long bytes = 0;
            if (sscanf(p + 4, "%llu", &bytes) != 1) goto bad;
            ev_push_bytes(EV_PROGRESS, bytes);
        } else if (!strncmp(p, "wire ", 5)) {
            unsigned long long bytes = 0;
            if (sscanf(p + 5, "%llu", &bytes) != 1) goto bad;
            ev_push_bytes(EV_WIRE, bytes);
        } else if (!strncmp(p, "pid ", 4)) {
            int pid = 0;
            if (sscanf(p + 4, "%d", &pid) != 1) goto bad;
            ev_push_pid(pid);
        } else if (!strncmp(p, "session ", 8)) {
            ev_push_session(!strncmp(p + 8, "ok", 2), p + 8);
        } else {
            goto bad;
        }
        ev_drain();
        applied++;
        if (blink_flip(g_clock_v)) g_dirty = 1;
        if (g_dirty) sim_paint();
        continue;
    bad:
        printf("SIM: bad event line: %s\n", p);
        fclose(f);
        return 0;
    }
    fclose(f);
    /* the final frame goes to the argv path even if the last event changed
       nothing: a scenario's artifact is its end state. */
    /* the end state is the scenario's artifact, even if the last event changed
       nothing. Same state, same clock -> byte-identical to the last painted
       frame (rule 5), so it is written, not counted as another frame. */
    draw_frame(g_clock_v, g_sim_frame + 1, 0.0);
    if (out && !sim_write_ppm(out)) return 0;
    printf("SIM: replay %s %u events, %u frames\n", path, applied, g_sim_frame);
    return 1;
}
#endif /* SACD_UI_SIM — the SIM drivers */

/* ================= main ============================================== */
int main(int argc, char **argv)
{
#ifdef SACD_UI_SIM
    unsigned frames = 1;
#else
    const char *host = (argc > 1) ? argv[1] : "127.0.0.1";
    int hold = (argc > 2) ? atoi(argv[2]) : 45;
    const char *fbdev = getenv("SACD_UI_FB");
    unsigned frames = 0;
    double t, fps = 0.0, next_tick = 0.0, next_tel = 0.0, render_t0;

    if (hold < 1) hold = 1;
    if (hold > 600) hold = 600;
#endif

    setvbuf(stdout, NULL, _IOLBF, 0);
    g_t0 = now_s();
#ifdef SACD_UI_SIM
    /* a SIM run never reads the wall clock (rule 5's precondition): the event
       clock starts at 0 and only a replay's own `tick` lines advance it, so the
       same scenario renders the same bytes on any machine. */
    g_clock_sim = 1;
#endif

#ifdef SACD_UI_SIM
    if (!sim_open()) return 4;
#else
    if (!fbdev || !fbdev[0]) fbdev = "/dev/fb0";
    if (!pool_open(fbdev)) {
        if (!pool_open("/res/dev/fb0")) {
            printf("UI: no framebuffer (%s, /res/dev/fb0)\n", fbdev);
            return 4;
        }
    }
#endif
    if (font_load_chain(getenv("SACD_UI_FONT")))
        printf("UI: font %s\n", g_font_path);
    else
        printf("UI: NO FONT — text will be blank (stage sony-font.ttf)\n");
    ev_log('>', "UI UP  canvas %dx%d scale=%d  font=%s",
           CW, CH, SCAL, g_font_ok ? g_font_path : "none");

#ifdef SACD_UI_SIM
    {
        /* SACD_UI_SIM_SCRIPT: the deterministic EVENT replay (see sim_replay).
           Checked first because it is a different driver of the same state
           machine, not a variation of the golden episode below. */
        const char *script = getenv("SACD_UI_SIM_SCRIPT");
        if (script && script[0]) {
            const char *out;
            const char *fdir = getenv("SACD_UI_SIM_FRAMES");
            if (fdir) snprintf(g_sim_frames_dir, sizeof g_sim_frames_dir, "%s", fdir);
            if (argc >= 5) {
                /* with disc bytes: same positions as the argv episode */
                if (sim_load_fixtures(argv[1], argv[2], argv[3], 1) < 0) return 2;
                out = argv[4];
            } else {
                out = (argc > 1) ? argv[1] : "/tmp/sacd_ui_sim.ppm";
            }
            if (!sim_replay(script, out)) return 3;
            return 0;
        }
    }
    {
        /* layout iteration: real TOC bytes from files, synthetic wire/timing */
        const char *mtoc = (argc > 1) ? argv[1] : NULL;
        const char *a1 = (argc > 2) ? argv[2] : NULL;
        const char *a2 = (argc > 3) ? argv[3] : NULL;
        const char *out = (argc > 4) ? argv[4] : "/tmp/sacd_ui.ppm";

        if (!mtoc) { printf("SIM: usage: sacd_ui <mtoc.bin> <area1.bin> <area2.bin> <out.ppm>\n"); return 2; }
        if (sim_load_fixtures(mtoc, a1, a2, 0) < 0) return 2;
        ev_log('>', "MTOC SACD %d.%02d cat=%s year=%d", g_disc.ver_major,
               g_disc.ver_minor, g_disc.disc_cat, g_disc.year);
        ev_log('>', "DISC_SIZE %llu sectors (SIM)", g_disc.sectors);
        ev_log('>', "DISC_OPEN ok (SIM)");
        ev_log('*', "CLIENT CONNECT 127.0.0.1:2002 (SIM)");
        g_disc.session_ok = 1;
        g_tel.listen_2002 = 1;
        g_tel.clients_2002 = 1;
        g_tel.clients_seen = 1;
        g_tel.daemon_pid = 4682;
        g_tel.wire_mb = 3.4;
        /* scene knob (ui-regress s3): the wire path reaches the FAILED-session
           screen through a real failed ui_session(); the SIM path has no wire,
           so the same state is forced explicitly — sectors too, because the
           status block's OK branch keys off (session_ok || sectors). */
        if (getenv("SACD_UI_SIM_FAIL")) {
            g_disc.session_ok = 0;
            g_disc.sectors = 0;
            snprintf(g_disc.err, sizeof g_disc.err, "SIM FAIL (scene knob)");
        }
        draw_frame(1.7, frames, 0.0);
#ifdef SACD_UI_SPEC_DUMP
        spec_dump();
#endif
        if (!sim_write_ppm(out)) return 4;
        return 0;
    }
    {
        /* animation substrate (ui-regress): N frames at a fixed cadence with an
           EXACTLY known t sequence, so the blink/fps analysis has deterministic
           ground truth on the Mac. argv[4] is then a DIRECTORY (must exist).
           The loop prints nothing (a log line between frames would make the
           event-log region change, which the animation diff asserts never
           happens outside lamp+cursor+render-line). */
        const char *seq = getenv("SACD_UI_SIM_SEQ");
        const char *sqout = (argc > 4) ? argv[4] : NULL;
        if (seq && atoi(seq) > 0 && sqout) {
            int k, n = atoi(seq);
            double dt = getenv("SACD_UI_SIM_DT") ? atof(getenv("SACD_UI_SIM_DT")) : 0.125;
            char p[512];
            for (k = 0; k < n; k++) {
                double tk = (double)k * dt;
                char tbuf[32];
                snprintf(tbuf, sizeof tbuf, "%.3f", tk);
                draw_frame(tk, (unsigned)k + 1, k ? ((double)k + 1) / tk : 0.0);
                snprintf(p, sizeof p, "%s/frame-%03d-t%s.ppm", sqout, k, tbuf);
                if (!sim_write_ppm(p)) return 4;
            }
            printf("UI: SIM sequence %d frames dt=%.4f -> %s\n", n, dt, sqout);
            return 0;
        }
    }
#else
    /* The startup session is an ACT (a blocking protocol conversation — the
       only blocking thing in this program). Its OUTCOME is the EV_SESSION
       event, so even that state move flows through the one path (rule 4). */
    if (ui_session(host, &g_disc) != 0) g_disc.session_ok = 0;
    ev_push_session(g_disc.session_ok, g_disc.err);
    ev_drain();

    /* Opt-in RIP progress for a SECOND client (SACD_UI_WATCH_FILE, the file it
       rips into). The UI stats that file and never connects to the daemon for
       it — the accept slot (§0.6) stays free for the real client. */
    {
        const char *w = getenv("SACD_UI_WATCH_FILE");
        if (w && w[0]) {
            snprintf(g_watch_file, sizeof g_watch_file, "%s", w);
            ev_log('>', "WATCHING %s for RIP progress", g_watch_file);
        }
    }

    /* The session is CLOSED at this point (DISC_CLOSE ends the connection).
       The probe's own ring is free again, so a second client (sacdclient) can
       run now without colliding on the daemon's single shared accept slot
       (decode/daemon-socket-protocol.md §0.6). The marker file is how the
       guest sequence knows that moment has passed — never a sleep guess. */
    {
        const char *mark = getenv("SACD_UI_DONE_FILE");
        if (!mark) mark = "/res/ui-session.done";
        if (mark[0]) {
            FILE *mf = fopen(mark, "w");
            if (mf) {
                fprintf(mf, "session_ok=%d\n", g_disc.session_ok);
                fclose(mf);
            } else {
                ev_log('!', "marker %s not writable", mark);
            }
        }
    }
    render_t0 = now_s();

    /* ---- the loop: poll -> queue -> apply_event -> paint if dirty ----
       Source order per pass is FIXED (determinism rule 2): the frame clock,
       then /proc/net/tcp, then the daemon's io, then the watched client's io.
       The sleep is the only thing that is not an event. A painted frame is
       counted, so `fps` is frames PAINTED per second — the number that used to
       be capped by the redraw, not by the work. */
    for (;;) {
        t = now_s() - render_t0;
        if (t >= (double)hold) break;
        if (t >= next_tick) {
            ev_push_kind(EV_TICK);
            next_tick = t + FRAME_PERIOD_S;
        }
        if (t >= next_tel) {
            int listen = 0, clients = 0, dpid = 0;
            unsigned long long bytes = 0;
            next_tel = t + TEL_PERIOD_S;
            if (tel_sample_tcp(&listen, &clients) == 0)
                ev_push_tcp(listen, clients);
            if (g_tel.daemon_pid <= 0) {
                dpid = tel_find_pid(DAEMON_CMD);
                if (dpid > 0) ev_push_pid(dpid);
            }
            if (tel_sample_wire(&bytes) == 0)
                ev_push_bytes(EV_WIRE, bytes);
            if (g_watch_file[0] && tel_sample_file(g_watch_file, &bytes) == 0)
                ev_push_bytes(EV_PROGRESS, bytes);
        }
        ev_drain();
        if (blink_flip(t)) g_dirty = 1;
        if (g_dirty) {
            draw_frame(t, frames, fps);
            frames++;
            g_dirty = 0;
            /* The FIRST-FRAME MARKER (issue #13): the guest sequence gates its
               UI kill on this file, never on a fixed sleep — the session alone
               is a 22 s DISC_OPEN (c123/c132/c133), so a sleep is either too
               short to find a frame (uiloop7) or wasted fire time. One write on
               the first paint; stdout, not ev_log(), because the event log is
               RENDERED and a marker line there would be a different frame. */
            if (frames == 1) {
                const char *fm = getenv("SACD_UI_FRAME_FILE");
                FILE *mf;
                if (!fm || !fm[0]) fm = FRAME_MARKER;
                mf = fopen(fm, "w");
                if (mf) {
                    fputs("frame=1\n", mf);
                    fclose(mf);
                    printf("UI: FRAME MARKER %s at %.2f s\n", fm, t);
                } else {
                    printf("UI: FRAME MARKER %s not writable\n", fm);
                }
            }
        }
        if (t > 0.5) fps = (double)frames / t;
        usleep(FRAME_SLEEP_US);
    }
    t = now_s() - render_t0;
    if (t > 0.5) fps = (double)frames / t;
    /* one last sample + apply, so the final frame carries the leaving client,
       then the final complete frame */
    {
        int listen = 0, clients = 0;
        unsigned long long bytes = 0;
        if (tel_sample_tcp(&listen, &clients) == 0) ev_push_tcp(listen, clients);
        if (tel_sample_wire(&bytes) == 0) ev_push_bytes(EV_WIRE, bytes);
        if (g_watch_file[0] && tel_sample_file(g_watch_file, &bytes) == 0)
            ev_push_bytes(EV_PROGRESS, bytes);
        ev_drain();
    }
    draw_frame(t, frames, fps);              /* final, complete frame */
    frames++;
    printf("UI: frames=%u secs=%.1f fps=%.1f session_ok=%d clients_seen=%d "
           "bytes=%llu areas=%d\n", frames, t, fps, g_disc.session_ok,
           g_tel.clients_seen, g_disc.bytes_wire, g_disc.nareas);
    printf("UI: event model: %u events, %u dropped, daemon_pid=%d "
           "wire_bytes=%llu wire_mb=%.1f rip_bytes=%llu rip_sectors=%llu "
           "rip_mb_s=%.1f\n", g_ev_seq, g_evq_drops, g_tel.daemon_pid,
           g_tel.wire_bytes, g_tel.wire_mb, g_prog.bytes, g_prog.sectors,
           g_prog.mb_s);
    printf("UI: POOL-RENDER DONE\n");
    if (g_disc.session_ok) printf("UI_PASS\n");
    else printf("UI_FAIL %s\n", g_disc.err);
    return g_disc.session_ok ? 0 : 3;
#endif
    return 0;
}
