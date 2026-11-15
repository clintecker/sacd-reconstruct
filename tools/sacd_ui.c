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
 *     holds one short session and then observes from the outside.
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

#define CW 640                 /* logical canvas */
#define CH 360
#define PORT 2002
#define MAX_CHUNK 128          /* MAX_PROCESSING_BLOCK_SIZE (protocol §3) */
#define SECTOR 2048
#define MAX_TRACKS 16
#define LOG_RING 24
#define LOG_SHOWN 7

/* ================= canvas ============================================== */
static unsigned int *fb;
static int pitch_px;
static int SCAL = 3;           /* device px per logical px (from the panel) */
static int g_visible_w, g_visible_h;

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

/* ================= event log ========================================== */
typedef struct {
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

static void ev_log(char mark, const char *fmt, ...)
{
    va_list ap;
    ev_t *e = &g_log[g_log_head];
    e->t = now_s() - g_t0;
    e->mark = mark;
    va_start(ap, fmt);
    vsnprintf(e->text, sizeof e->text, fmt, ap);
    va_end(ap);
    g_log_head = (g_log_head + 1) % LOG_RING;
    if (g_log_n < LOG_RING) g_log_n++;
    printf("UI-EV %6.2f %c %s\n", e->t, mark, e->text);
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

/* ================= /proc telemetry (proven HUD paths, guest only) === */
typedef struct {
    int listen_2002;
    int clients_2002;
    int clients_seen;
    int daemon_pid;
    unsigned long long rchar;
    double rate_mb;
    int proc_ok;
} tel_t;

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

static void tel_tcp(tel_t *t)
{
    char b[32768], *ln, *save = NULL;
    int clients = 0, listen = 0;
    if (read_small("/proc/net/tcp", b, sizeof b) < 0 &&
        read_small("/res/proc/net/tcp", b, sizeof b) < 0)
        return;
    t->proc_ok = 1;
    for (ln = strtok_r(b, "\n", &save); ln; ln = strtok_r(NULL, "\n", &save)) {
        char la[16], ra[16], st[8];
        unsigned lport = 0, rport = 0;
        if (sscanf(ln, " %*d: %15[0-9A-Fa-f]:%x %15[0-9A-Fa-f]:%x %7s",
                   la, &lport, ra, &rport, st) != 5) continue;
        if (lport != PORT) continue;
        if (!strcmp(st, "0A")) listen = 1;
        else if (!strcmp(st, "01") || !strcmp(st, "08")) clients++;
    }
    if (clients > t->clients_2002) ev_log('*', "DAEMON CLIENT CONNECT (%d live)", clients);
    else if (clients < t->clients_2002) ev_log('*', "DAEMON CLIENT GONE (%d live)", clients);
    if (!t->listen_2002 && listen) ev_log('*', "LISTENER :2002 UP");
    t->listen_2002 = listen;
    t->clients_2002 = clients;
    if (clients > t->clients_seen) t->clients_seen = clients;
}

static void tel_daemon(tel_t *t)
{
    DIR *d;
    struct dirent *e;
    char b[4096], *p;
    unsigned long long rb = 0;

    if (t->daemon_pid <= 0) {
        d = opendir("/proc");
        if (!d) d = opendir("/res/proc");
        if (!d) return;
        while ((e = readdir(d))) {
            char path[64], cmd[256];
            long pid = atol(e->d_name);
            if (pid <= 0) continue;
            snprintf(path, sizeof path, "/proc/%ld/cmdline", pid);
            if (read_small(path, cmd, sizeof cmd) <= 0) {
                snprintf(path, sizeof path, "/res/proc/%ld/cmdline", pid);
                if (read_small(path, cmd, sizeof cmd) <= 0) continue;
            }
            if (strstr(cmd, "sacd_extract_160")) { t->daemon_pid = (int)pid; break; }
        }
        closedir(d);
    }
    if (t->daemon_pid <= 0) return;
    {
        char path[64];
        snprintf(path, sizeof path, "/proc/%d/io", t->daemon_pid);
        if (read_small(path, b, sizeof b) <= 0) {
            snprintf(path, sizeof path, "/res/proc/%d/io", t->daemon_pid);
            read_small(path, b, sizeof b);
        }
        if ((p = strstr(b, "rchar:"))) rb = strtoull(p + 6, NULL, 10);
    }
    if (rb > t->rchar) t->rate_mb = (double)(rb - t->rchar) / (1024.0 * 1024.0) * 4.0;
    else t->rate_mb = 0.0;
    t->rchar = rb;
}
#endif /* !SACD_UI_SIM — /proc telemetry */

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
static disc_t g_disc;
static tel_t g_tel;

static void draw_frame(double t, unsigned frames, double fps)
{
    char l[160], m1[16], m2[16], num[40];
    int y, i;
    int pulse = ((int)(t * 2) & 1);

    clear_canvas(C_BG);
    box(0, 0, CW, CH, C_FRAME);

    /* ---- title bar ---- */
    text_top("SACD RECONSTRUCT", 12, 8, 17, C_PHOS);
    snprintf(l, sizeof l, "BX510 DAEMON CONSOLE");
    text_right(l, CW - 12, 10, 10, C_DIM);
    rect(12, 30, CW - 24, 1, C_RULE);

    /* ---- status block ---- */
    snprintf(l, sizeof l, "DAEMON  %s:%d %s   CLIENTS %d   PID %d   IO %.1f MB/s",
             "127.0.0.1", PORT,
             g_tel.listen_2002 ? "LISTEN" : "CLOSED",
             g_tel.clients_2002, g_tel.daemon_pid, g_tel.rate_mb);
    text_top(l, 12, 37, 11, g_tel.listen_2002 ? C_BRIGHT : C_RED);
    /* the live link lamp */
    rect(CW - 22, 38, 8, 8, g_tel.clients_2002 ? (pulse ? C_PHOS : C_DIM)
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
        if (a->track_count > 6) {
            snprintf(l, sizeof l, "+%d more", a->track_count - 6);
            text_top(l, px0 + 206, 126 + 6 * 11, 9, C_AMBER);
        }
    }
    rect(12, 196, CW - 24, 1, C_RULE);

    /* ---- event log (newest last) ---- */
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
    rect(12, 296, CW - 24, 1, C_RULE);

    /* ---- session summary + client watch ---- */
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
        if (pulse) rect(CW - 14 - w - 14, 341, 5, 7, C_PHOS);
    }
    snprintf(l, sizeof l, "%s", g_disc.session_ok ? "SESSION OK" : "SESSION FAIL");
    text_right(l, CW - 14, 340, 9, g_disc.session_ok ? C_PHOS : C_RED);
}

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
    double t, fps = 0.0, next_tel = 0.0, render_t0;

    if (hold < 1) hold = 1;
    if (hold > 600) hold = 600;
#endif

    setvbuf(stdout, NULL, _IOLBF, 0);
    g_t0 = now_s();

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
        /* layout iteration: real TOC bytes from files, synthetic wire/timing */
        const char *mtoc = (argc > 1) ? argv[1] : NULL;
        const char *a1 = (argc > 2) ? argv[2] : NULL;
        const char *a2 = (argc > 3) ? argv[3] : NULL;
        const char *out = (argc > 4) ? argv[4] : "/tmp/sacd_ui.ppm";
        unsigned char *buf;
        FILE *f;
        size_t n;
        unsigned lba, cnt;

        if (!mtoc) { printf("SIM: usage: sacd_ui <mtoc.bin> <area1.bin> <area2.bin> <out.ppm>\n"); return 2; }
        f = fopen(mtoc, "rb");
        if (!f) { printf("SIM: cannot open %s\n", mtoc); return 2; }
        buf = (unsigned char *)malloc(256 * SECTOR);
        n = fread(buf, 1, 10 * SECTOR, f);
        fclose(f);
        g_disc.sectors = 1064208;
        g_disc.mtoc_lba = 510; g_disc.mtoc_count = 10;
        g_disc.ms_open = 12; g_disc.ms_size = 7; g_disc.ms_mtoc = 1840;
        g_disc.bytes_wire = n;
        if (!parse_master_toc(buf, n, &g_disc)) printf("SIM: mtoc parse: %s\n", g_disc.err);
        lba = be32u(buf + 0x40); cnt = be16u(buf + 0x54);
        ev_log('>', "READ lba=%u x%u %u B (SIM)", g_disc.mtoc_lba, 10, (unsigned)n);
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
                ev_log('>', "READ lba=%u x%u %u B (SIM)", lba, (unsigned)(n / SECTOR), (unsigned)n);
                ev_log('>', "AREA %s ch=%d trk=%d", g_disc.area[g_disc.nareas].id,
                       g_disc.area[g_disc.nareas].channels,
                       g_disc.area[g_disc.nareas].track_count);
                g_disc.nareas++;
            }
            free(ab);
            lba = 353804; cnt = 40;
        }
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
        g_tel.rate_mb = 3.4;
        draw_frame(1.7, frames, 0.0);
        if (!sim_write_ppm(out)) return 4;
        return 0;
    }
#else
    if (ui_session(host, &g_disc) != 0) {
        g_disc.session_ok = 0;
        ev_log('!', "SESSION FAILED: %s", g_disc.err);
    } else {
        ev_log('>', "SESSION COMPLETE — disc picture from the wire");
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

    /* the loop: redraw, watch /proc, keep the last frame complete */
    for (;;) {
        t = now_s() - render_t0;
        if (t >= (double)hold) break;
        if (t >= next_tel) {
            tel_tcp(&g_tel);
            tel_daemon(&g_tel);
            next_tel = t + 0.25;
        }
        draw_frame(t, frames, fps);
        frames++;
        if (t > 0.5) fps = frames / t;
        usleep(30000);
    }
    t = now_s() - render_t0;
    if (t > 0.5) fps = frames / t;
    tel_tcp(&g_tel);
    tel_daemon(&g_tel);
    draw_frame(t, frames, fps);              /* final, complete frame */
    printf("UI: frames=%u secs=%.1f fps=%.1f session_ok=%d clients_seen=%d "
           "bytes=%llu areas=%d\n", frames, t, fps, g_disc.session_ok,
           g_tel.clients_seen, g_disc.bytes_wire, g_disc.nareas);
    printf("UI: POOL-RENDER DONE\n");
    if (g_disc.session_ok) printf("UI_PASS\n");
    else printf("UI_FAIL %s\n", g_disc.err);
    return g_disc.session_ok ? 0 : 3;
#endif
    return 0;
}
