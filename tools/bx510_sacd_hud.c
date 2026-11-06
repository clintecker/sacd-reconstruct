/*
 * bx510_sacd_hud.c — SACD HUD: a cyberpunk console showing what the daemon is
 * doing. PHASE H2-lite.
 *
 * H1 measured **2 FPS**: it drew into the 1920x1080 primary with one DirectFB
 * FillRectangle per glyph pixel — hundreds of driver calls per text line.
 * H2-lite flips the architecture:
 *
 *   - render into a 640x360 ARGB SYSTEM surface, Lock()ed: our own software
 *     pixel/glyph routines write raw memory (no driver calls),
 *   - ONE accelerated stretch-Blits to the 1920x1080 primary per frame.
 *
 * Motion that is real, not decorative: a rotating wireframe cube (3D),
 * scrolling perspective grid, CRT sweep line, blinking cursor, a sparkline
 * that moves with measured throughput — and a TICKER fed from the daemon's
 * OWN stdout (the launcher captures it to /tmp/cand.out; the HUD tails it,
 * which is the H2 telemetry path without touching the daemon).
 *
 * Telemetry (unchanged from H1, /proc only): CPSA module, :2002 listener and
 * sessions, daemon pid, read bytes -> MB/s and disc-map progress, memory,
 * /tmp headroom.
 *
 * Build (gnuarm 2009q3, dynamic; DirectFB-1.2.7 headers must be configured):
 *   ~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall \
 *       -I<T>/include -I<T>/lib -I<T>/lib/direct -I<T> -o sacd_hud \
 *       bx510_sacd_hud.c -L/tmp/rootfs/lib -ldirectfb -ldirect -lfusion -lpthread -lrt
 *   ~/gnuarm/bin/arm-none-linux-gnueabi-strip sacd_hud
 *
 * Usage: sacd_hud [seconds] [ticker-file]   (default 120 s, /tmp/cand.out)
 */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <math.h>
#include <dirent.h>
#include <sys/statvfs.h>
#include <sys/mman.h>
#ifndef HUD_SIM
#include <linux/fb.h>
#include <sys/ioctl.h>
#endif
#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>
#ifndef HUD_SIM
#include <directfb.h>
#endif

#define CW 640
#define CH 360

/* ---------------- software canvas ----------------------------------- */
static unsigned int *fb;
static int pitch_px;
static int SCAL = 2;          /* device px per logical px (set from the panel) */
/* device profile offsets (see profile_load): where the visible area starts */
static int g_xoff, g_yoff, g_visible_w, g_visible_h, g_pitch;
static int g_quant_off;   /* set while drawing glyphs so dither spares text */
/* channel order of the pool buffer. The calibration bars decide which is
   right: red must be red, green green. 0=ARGB(xRGB) 1=BGRA 2=RGBA 3=ABGR */
static int g_order;
/* Text size in DEVICE px, derived from the visible panel height so the HUD has
   the same physical size at 720p and 1080p: headline ~1/40 of the height,
   secondary ~1/60 (18/12 px at 720p, 27/18 px at 1080p). A profile may
   override both. */
static int g_head_px = 18, g_body_px = 12;

static void typography_set(int visible_h)
{
    if (visible_h <= 0) visible_h = 720;
    g_head_px = visible_h / 26;      /* ~28 px at 720p, 42 at 1080p */
    g_body_px = visible_h / 38;      /* ~19 px at 720p, 28 at 1080p */
    if (g_head_px < 16) g_head_px = 16;
    if (g_body_px < 12) g_body_px = 12;
}

static void px_blend(int xd, int yd, unsigned int c, unsigned a)
{
    unsigned int *o;
    unsigned int r, g, b, dr, dg, db;
    if (xd < 0 || yd < 0 || xd >= pitch_px || yd >= (CH * SCAL)) return;
    o = fb + (size_t)yd * pitch_px + xd;
    dr = (*o >> 16) & 0xff; dg = (*o >> 8) & 0xff; db = *o & 0xff;
    r = ((c >> 16) & 0xff) * a / 255 + dr * (255 - a) / 255;
    g = ((c >> 8) & 0xff) * a / 255 + dg * (255 - a) / 255;
    b = (c & 0xff) * a / 255 + db * (255 - a) / 255;
    *o = (r << 16) | (g << 8) | b;
}

/* Sony's own screen font (carved from /res/font.bin, see bx510_font_carve.py)
   rendered with stb_truetype: no freetype on this rootfs, and the hand-rolled
   5x7 face was unreadable on a TV at 1080p. Falls back to 5x7 if absent. */
#define STB_TRUETYPE_IMPLEMENTATION
#include "third_party/stb_truetype.h"

static void px_blend(int xd, int yd, unsigned int c, unsigned a);

static stbtt_fontinfo g_font;
static unsigned char *g_ttf;
static int g_font_ok;
static float g_fsc;            /* scale for the current size */

static int font_load(const char *path)
{
    FILE *f = fopen(path, "rb");
    long n;
    if (!f) return 0;
    fseek(f, 0, SEEK_END); n = ftell(f); fseek(f, 0, SEEK_SET);
    if (n <= 0) { fclose(f); return 0; }
    g_ttf = malloc((size_t)n);
    if (!g_ttf) { fclose(f); return 0; }
    if (fread(g_ttf, 1, (size_t)n, f) != (size_t)n) { fclose(f); free(g_ttf); g_ttf = NULL; return 0; }
    fclose(f);
    if (!stbtt_InitFont(&g_font, g_ttf, stbtt_GetFontOffsetForIndex(g_ttf, 0))) {
        free(g_ttf); g_ttf = NULL; return 0;
    }
    g_font_ok = 1;
    return 1;
}
static int ttf_width(const char *str, int px)
{
    float sc;
    int w = 0;
    if (!g_font_ok) return (int)strlen(str) * 6;
    sc = stbtt_ScaleForPixelHeight(&g_font, (float)px);
    for (; *str; str++) {
        int adv, lsb;
        stbtt_GetCodepointHMetrics(&g_font, *str, &adv, &lsb);
        w += (int)(adv * sc);
    }
    return w;
}
/* draw at logical (x,y) with logical pixel height px; blocks scaled by SCAL */
static int ttf_text(const char *str, int x, int y, int px, unsigned int col)
{
    int cx = x;
    if (!g_font_ok) return -1;
    g_quant_off = 1;
    g_fsc = stbtt_ScaleForPixelHeight(&g_font, (float)px);
    for (; *str; str++) {
        int gw = 0, gh = 0, xo = 0, yo = 0, adv, lsb;
        unsigned char *bmp = stbtt_GetCodepointBitmap(&g_font, g_fsc, g_fsc, *str,
                                                     &gw, &gh, &xo, &yo);
        stbtt_GetCodepointHMetrics(&g_font, *str, &adv, &lsb);
        if (bmp) {
            int yy, xx, sy, sx;
            for (yy = 0; yy < gh; yy++)
                for (xx = 0; xx < gw; xx++) {
                    unsigned char a = bmp[yy * gw + xx];
                    if (!a) continue;
                    for (sy = 0; sy < SCAL; sy++)
                        for (sx = 0; sx < SCAL; sx++)
                            px_blend((cx + xo + xx) * SCAL + sx,
                                     (y + yo + yy) * SCAL + sy, col, a);
                }
            stbtt_FreeBitmap(bmp, NULL);
        }
        cx += (int)(adv * g_fsc);
    }
    g_quant_off = 0;
    return cx;
}


#define C_BG      0xff000a06
#define C_GRID    0xff00150f
#define C_PANEL   0xff000f0a
#define C_FRAME   0xff00b34d
#define C_PHOS    0xff22ff66
#define C_PHOSD   0xff0a7a30
#define C_AMBER   0xffffb000
#define C_MAGENTA 0xffff33cc
#define C_CYAN    0xff33e0ff
#define C_RED     0xffff3344
#define C_WHITE   0xffe8ffe8

/* ---------------- embedded 5x7 font (chars we actually print) --------- */
typedef struct { char ch; uint8_t rows[7]; } glyph_t;
static const glyph_t FONT[] = {
    {'A', {0x0E,0x11,0x11,0x1F,0x11,0x11,0x11}},
    {'B', {0x1E,0x11,0x11,0x1E,0x11,0x11,0x1E}},
    {'C', {0x0E,0x11,0x10,0x10,0x10,0x11,0x0E}},
    {'D', {0x1C,0x12,0x11,0x11,0x11,0x12,0x1C}},
    {'E', {0x1F,0x10,0x10,0x1E,0x10,0x10,0x1F}},
    {'F', {0x1F,0x10,0x10,0x1E,0x10,0x10,0x10}},
    {'G', {0x0E,0x11,0x10,0x17,0x11,0x11,0x0F}},
    {'H', {0x11,0x11,0x11,0x1F,0x11,0x11,0x11}},
    {'I', {0x0E,0x04,0x04,0x04,0x04,0x04,0x0E}},
    {'J', {0x07,0x02,0x02,0x02,0x02,0x12,0x0C}},
    {'K', {0x11,0x12,0x14,0x18,0x14,0x12,0x11}},
    {'L', {0x10,0x10,0x10,0x10,0x10,0x10,0x1F}},
    {'M', {0x11,0x1B,0x15,0x15,0x11,0x11,0x11}},
    {'N', {0x11,0x19,0x15,0x13,0x11,0x11,0x11}},
    {'O', {0x0E,0x11,0x11,0x11,0x11,0x11,0x0E}},
    {'P', {0x1E,0x11,0x11,0x1E,0x10,0x10,0x10}},
    {'Q', {0x0E,0x11,0x11,0x11,0x15,0x12,0x0D}},
    {'R', {0x1E,0x11,0x11,0x1E,0x14,0x12,0x11}},
    {'S', {0x0F,0x10,0x10,0x0E,0x01,0x01,0x1E}},
    {'T', {0x1F,0x04,0x04,0x04,0x04,0x04,0x04}},
    {'U', {0x11,0x11,0x11,0x11,0x11,0x11,0x0E}},
    {'V', {0x11,0x11,0x11,0x11,0x11,0x0A,0x04}},
    {'W', {0x11,0x11,0x11,0x15,0x15,0x15,0x0A}},
    {'X', {0x11,0x11,0x0A,0x04,0x0A,0x11,0x11}},
    {'Y', {0x11,0x11,0x0A,0x04,0x04,0x04,0x04}},
    {'Z', {0x1F,0x01,0x02,0x04,0x08,0x10,0x1F}},
    {'0', {0x0E,0x11,0x13,0x15,0x19,0x11,0x0E}},
    {'1', {0x04,0x0C,0x04,0x04,0x04,0x04,0x0E}},
    {'2', {0x0E,0x11,0x01,0x02,0x04,0x08,0x1F}},
    {'3', {0x1F,0x02,0x04,0x02,0x01,0x11,0x0E}},
    {'4', {0x02,0x06,0x0A,0x12,0x1F,0x02,0x02}},
    {'5', {0x1F,0x10,0x1E,0x01,0x01,0x11,0x0E}},
    {'6', {0x06,0x08,0x10,0x1E,0x11,0x11,0x0E}},
    {'7', {0x1F,0x01,0x02,0x04,0x08,0x08,0x08}},
    {'8', {0x0E,0x11,0x11,0x0E,0x11,0x11,0x0E}},
    {'9', {0x0E,0x11,0x11,0x0F,0x01,0x02,0x0C}},
    {' ', {0,0,0,0,0,0,0}},
    {'.', {0,0,0,0,0,0x0C,0x0C}},
    {'/', {0x01,0x01,0x02,0x04,0x08,0x10,0x10}},
    {'-', {0,0,0,0x1F,0,0,0}},
    {'>', {0x08,0x04,0x02,0x01,0x02,0x04,0x08}},
    {':', {0,0x0C,0x0C,0,0x0C,0x0C,0}},
    {'_', {0,0,0,0,0,0,0x1F}},
};

#define NGlyphs (sizeof FONT / sizeof FONT[0])
static const glyph_t *find_glyph(char c)
{
    unsigned i;
    if (c >= 'a' && c <= 'z') c -= 32;
    for (i = 0; i < NGlyphs; i++) if (FONT[i].ch == c) return &FONT[i];
    return &FONT[NGlyphs - 1];
}


static unsigned int reorder(unsigned int c)
{
    unsigned int a = (c >> 24) & 0xff, r = (c >> 16) & 0xff, g = (c >> 8) & 0xff, b = c & 0xff;
    switch (g_order) {
    case 1: return (a << 24) | (r << 16) | (g << 8) | b;      /* BGRA in memory */
    case 2: return (r << 16) | (g << 8) | (b << 0) | (a << 24);
    case 3: return (b << 16) | (g << 8) | (r << 0) | (a << 24);
    default: return c;
    }
}

static void px(int x, int y, unsigned int c)
{
    int dx, dy;
    unsigned int *row;
    if (x < 0 || y < 0 || x >= CW || y >= CH) return;
    row = fb + (size_t)(g_yoff + y * SCAL) * pitch_px + (size_t)(g_xoff + x * SCAL);
    for (dy = 0; dy < SCAL; dy++) {
        unsigned int *o = row + (size_t)dy * pitch_px;
        for (dx = 0; dx < SCAL; dx++) o[dx] = c;
    }
}
static void rect(int x, int y, int w, int h, unsigned int c)
{
    int dy, dx, ddx;
    unsigned int *row;
    if (x < 0) { w += x; x = 0; }
    if (y < 0) { h += y; y = 0; }
    if (x + w > CW) w = CW - x;
    if (y + h > CH) h = CH - y;
    if (w <= 0 || h <= 0) return;
    row = fb + (size_t)(g_yoff + y * SCAL) * pitch_px + (size_t)(g_xoff + x * SCAL);
    for (dy = 0; dy < h * SCAL; dy++) {
        unsigned int *o = row + (size_t)dy * pitch_px;
        for (dx = 0; dx < w; dx++)
            for (ddx = 0; ddx < SCAL; ddx++) o[dx * SCAL + ddx] = c;
    }
}
static void box(int x, int y, int w, int h, unsigned int c)
{
    rect(x, y, w, 1, c); rect(x, y + h - 1, w, 1, c);
    rect(x, y, 1, h, c); rect(x + w - 1, y, 1, h, c);
}
static void line(int x0, int y0, int x1, int y1, unsigned int c)
{
    int dx = abs(x1 - x0), dy = abs(y1 - y0);
    int sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1, err = dx - dy;
    for (;;) {
        px(x0, y0, c);
        if (x0 == x1 && y0 == y1) break;
        {
            int e2 = 2 * err;
            if (e2 > -dy) { err -= dy; x0 += sx; }
            if (e2 < dx)  { err += dx; y0 += sy; }
        }
    }
}
/* one 5x7 glyph, 2x2 blocks + a bold extra column == readable on a TV */
static void glyph2(char c, int x, int y, unsigned int col)
{
    const glyph_t *g = find_glyph(c);
    int r, k;
    for (r = 0; r < 7; r++)
        for (k = 0; k < 5; k++)
            if (g->rows[r] & (1 << (4 - k)))
                rect(x + k * 2, y + r * 2, 3, 2, col);
}
static void glyph1(char c, int x, int y, unsigned int col);

/* logical-px height of a text line at a given DEVICE px size */
static int line_h(int dev_px) { return dev_px * 5 / 4 + 2; }

/* draw text with (x, ytop) in LOGICAL px; returns advance width (logical) */
static int text_top(const char *s, int x, int ytop, int dev_px, unsigned int col)
{
    int lp, adv, asc;
    float sc;
    if (!g_font_ok) {
        int cx = x;
        for (; *s; s++) { glyph1(*s, cx, ytop, col); cx += 6; }
        return cx - x;
    }
    lp = dev_px / SCAL; if (lp < 5) lp = 5;
    sc = stbtt_ScaleForPixelHeight(&g_font, (float)lp);
    stbtt_GetFontVMetrics(&g_font, &asc, NULL, NULL);
    {
        int base = ytop + (int)(asc * sc);
        int r = ttf_text(s, x, base, lp, col);
        return r - x;
    }
}
static int text_top_r(const char *s, int xr, int ytop, int dev_px, unsigned int col)
{
    int w = ttf_width(s, dev_px / SCAL ? dev_px / SCAL : 6);
    return text_top(s, xr - w, ytop, dev_px, col);
}

static int text2(const char *s, int x, int y, unsigned int col)
{
    int r;
    if (g_font_ok) { r = ttf_text(s, x, y - 12, 18, col); return r; }  /* 18 px logical: TV legible */
    {
        int cx = x;
        for (; *s; s++) { glyph2(*s, cx, y, col); cx += 12; }
        return cx;
    }
}
/* 1x face: 6 px per char — status numbers and ticker lines (2x is for the
   headline values only; a 640-px canvas can't fit 2x text and full lines) */
static void glyph1(char c, int x, int y, unsigned int col)
{
    const glyph_t *g = find_glyph(c);
    int r, k;
    for (r = 0; r < 7; r++)
        for (k = 0; k < 5; k++)
            if (g->rows[r] & (1 << (4 - k)))
                rect(x + k, y + r, 1, 1, col);
}
static int text1(const char *s, int x, int y, unsigned int col)
{
    int r;
    if (g_font_ok) {
        int lp = g_body_px / SCAL; if (lp < 6) lp = 6;
        r = ttf_text(s, x, y - lp * 2 / 3, lp, col);
        return r;
    }
    {
        int cx = x;
        for (; *s; s++) { glyph1(*s, cx, y, col); cx += 6; }
        return cx;
    }
}
static int text1r(const char *s, int xr, int y, unsigned int col)
{
    int w = g_font_ok ? ttf_width(s, g_body_px / SCAL ? g_body_px / SCAL : 6)
                      : (int)strlen(s) * 6;
    return text1(s, xr - w, y, col);
}

/* ---------------- telemetry ----------------------------------------- */
#define DISC_SECTORS 1064208ULL
#define SECTOR_BYTES 2048ULL

typedef struct {
    int module_loaded, misc_201, listen_2002, clients_2002, daemon_pid;
    unsigned long long read_bytes, read_bytes_prev;
    double mbps;
    unsigned long uptime_s, memfree_kb, memtotal_kb;
    unsigned int tmp_pct;
    char state[24], note[40];
} hud_t;

static int read_file(const char *p, char *b, size_t n)
{
    FILE *f = fopen(p, "r");
    size_t got;
    if (!f) return -1;
    got = fread(b, 1, n - 1, f);
    fclose(f); b[got] = 0;
    return (int)got;
}
static int contains(const char *p, const char *needle)
{
    char b[65536];
    if (read_file(p, b, sizeof b) < 0) return 0;
    return strstr(b, needle) != NULL;
}
static void sample_tcp(hud_t *h)
{
    /* "  sl: local_addr:port rem_addr:port st ..."  e.g. "3: 00000000:07D2 ... 0A"
       The first cut took the first ':' in the line (the sl field) and read port
       0, so a serving daemon showed CLOSED. Parse the fields. */
    char b[32768], *ln, *save = NULL;
    if (read_file("/proc/net/tcp", b, sizeof b) < 0) return;
    for (ln = strtok_r(b, "\n", &save); ln; ln = strtok_r(NULL, "\n", &save)) {
        char la[16], ra[16], st[8];
        unsigned lport = 0, rport = 0;
        if (sscanf(ln, " %*d: %15[0-9A-Fa-f]:%x %15[0-9A-Fa-f]:%x %7s",
                   la, &lport, ra, &rport, st) != 5) continue;
        (void)ra; (void)rport;
        if (lport != 2002) continue;
        if (!strcmp(st, "0A")) h->listen_2002 = 1;
        else if (!strcmp(st, "01") || !strcmp(st, "08")) h->clients_2002++;
    }
}
static void sample_daemon(hud_t *h)
{
    DIR *d = opendir("/proc");
    struct dirent *e;
    if (!d) return;
    while ((e = readdir(d))) {
        char p[64], cmd[256];
        long pid = atol(e->d_name);
        if (pid <= 0) continue;
        snprintf(p, sizeof p, "/proc/%ld/cmdline", pid);
        if (read_file(p, cmd, sizeof cmd) <= 0) continue;
        if (strstr(cmd, "sacd_extract_160")) { h->daemon_pid = (int)pid; break; }
    }
    closedir(d);
}
static void sample(hud_t *h, int first)
{
    char b[4096], *p;
    unsigned long long rb = 0;
    if (first) memset(h, 0, sizeof *h);
    h->module_loaded = contains("/proc/modules", "sacd_read");
    h->misc_201 = contains("/proc/misc", "201 ");
    h->listen_2002 = 0; h->clients_2002 = 0;
    sample_tcp(h);
    if (first || h->daemon_pid <= 0) sample_daemon(h);
    if (h->daemon_pid > 0) {
        char path[64];
        snprintf(path, sizeof path, "/proc/%d/io", h->daemon_pid);
        if (read_file(path, b, sizeof b) > 0) {
            /* the daemon reads via ioctl on a char device: read_bytes (block
               layer) stays 0, rchar is the counter that moves */
            if ((p = strstr(b, "rchar:"))) rb = strtoull(p + 6, NULL, 10);
            if (!rb && (p = strstr(b, "read_bytes:"))) rb = strtoull(p + 11, NULL, 10);
        }
    }
    h->read_bytes_prev = h->read_bytes;
    h->read_bytes = rb;
    if (!first && rb >= h->read_bytes_prev)
        h->mbps = (double)(rb - h->read_bytes_prev) / (1024.0 * 1024.0);
    if (read_file("/proc/uptime", b, sizeof b) > 0)
        h->uptime_s = (unsigned long)strtod(b, NULL);
    if (read_file("/proc/meminfo", b, sizeof b) > 0) {
        if ((p = strstr(b, "MemTotal:"))) h->memtotal_kb = strtoul(p + 9, NULL, 10);
        if ((p = strstr(b, "MemFree:")))  h->memfree_kb  = strtoul(p + 8, NULL, 10);
    }
    {
        struct statvfs v;
        if (statvfs("/tmp", &v) == 0 && v.f_blocks)
            h->tmp_pct = (unsigned)(100.0 * (double)(v.f_blocks - v.f_bfree) / (double)v.f_blocks);
    }
    if (h->module_loaded && h->listen_2002 && h->clients_2002)      snprintf(h->state, sizeof h->state, "SERVING");
    else if (h->module_loaded && h->listen_2002)                     snprintf(h->state, sizeof h->state, "ARMED");
    else if (h->daemon_pid > 0)                                      snprintf(h->state, sizeof h->state, "STARTING");
    else                                                             snprintf(h->state, sizeof h->state, "IDLE");
    h->note[0] = 0;
    if (!h->module_loaded)          snprintf(h->note, sizeof h->note, "CPSA MODULE DOWN");
    else if (!h->listen_2002)       snprintf(h->note, sizeof h->note, "NO LISTENER 2002");
    else if (h->tmp_pct > 95)       snprintf(h->note, sizeof h->note, "TMP FULL");
}

/* ---------------- ticker: tail the daemon's captured stdout ---------- */
/* observer-derived telemetry: the daemon talks ioctl, so /proc/<pid>/io is
   useless; the armed LD_PRELOAD observer logs "in[lsn=… cnt=…]" per READ and
   that is what we count. */
static unsigned long long ev_requests, ev_sectors, ev_last_lsn, ev_bytes, ev_bytes_win, ev_mbps;
static double ev_win_t;

static void tick_push(const char *ln);   /* below */

static void hud_event(const char *ln)
{
    const char *p = strstr(ln, "in[lsn=");
    unsigned lsn = 0, cnt = 0;
    if (p && sscanf(p, "in[lsn=%u cnt=%u", &lsn, &cnt) == 2) {
        char ev[80];
        ev_requests++;
        ev_sectors += cnt;
        ev_last_lsn = lsn;
        ev_bytes += (unsigned long long)cnt * SECTOR_BYTES;
        /* semantic line: what the client just asked for */
        snprintf(ev, sizeof ev, "READ lsn=%lu n=%u (%uK)", (unsigned long)lsn, cnt, cnt * 2);
        tick_push(ev);
    }
}

#define TICK_MAX 16
static char tick[TICK_MAX][80];
static unsigned tick_rep[TICK_MAX];   /* how many times this line repeated */
static int tick_n;
static long tick_off;

static int tick_events_only;   /* 1 = parse as observer events, no raw lines */

/* ---- host channel (T2): the CLIENT tells us what it requested ---------- */
#define HUD_UDP_PORT 20023
static int udp_fd = -1;

static void udp_open(void)
{
    struct sockaddr_in a;
    int fl;
    udp_fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (udp_fd < 0) return;
    memset(&a, 0, sizeof a);
    a.sin_family = AF_INET;
    a.sin_addr.s_addr = htonl(INADDR_ANY);
    a.sin_port = htons(HUD_UDP_PORT);
    if (bind(udp_fd, (struct sockaddr *)&a, sizeof a) < 0) {
        close(udp_fd); udp_fd = -1; return;
    }
    fl = fcntl(udp_fd, F_GETFL, 0);
    fcntl(udp_fd, F_SETFL, fl | O_NONBLOCK);
}
static void udp_poll(void)
{
    char b[512];
    for (;;) {
        ssize_t n;
        if (udp_fd < 0) return;
        n = recv(udp_fd, b, sizeof b - 1, 0);
        if (n <= 0) return;
        b[n] = 0;
        {   /* "READ lsn=532104 n=128 got=128" / "OPEN ok" / "CLOSE" */
            unsigned lsn = 0, cnt = 0;
            const char *pl = strstr(b, "lsn=");
            const char *pc = strstr(b, "n=");
            if (pl && sscanf(pl, "lsn=%u", &lsn) == 1) {
                if (pc && sscanf(pc, "n=%u", &cnt) == 1 && cnt > 0) {
                    ev_requests++;
                    ev_sectors += cnt;
                    ev_last_lsn = lsn;
                    ev_bytes += (unsigned long long)cnt * SECTOR_BYTES;
                }
            }
            if (b[0]) tick_push(b);
        }
    }
}

static void tick_push(const char *ln)
{
    int ni;
    if (tick_n > 0) {
        int li = (tick_n - 1) % TICK_MAX;
        if (!strncmp(tick[li], ln, 40)) { tick_rep[li]++; return; }
    }
    ni = tick_n % TICK_MAX;
    snprintf(tick[ni], sizeof tick[0], "%s", ln);
    tick_rep[ni] = 1;
    tick_n++;
}

static void ticker_poll(const char *path)
{
    FILE *f = fopen(path, "r");
    char buf[8192];
    size_t got;
    if (!f) return;
    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return; }
    got = (size_t)ftell(f);
    if (got < (size_t)tick_off) tick_off = 0;      /* file recreated */
    if (got == (size_t)tick_off) { fclose(f); return; }
    fseek(f, tick_off, SEEK_SET);
    {
        size_t n = fread(buf, 1, sizeof buf - 1, f);
        char *ln, *save = NULL;
        buf[n] = 0;
        tick_off += (long)n;
        for (ln = strtok_r(buf, "\n", &save); ln; ln = strtok_r(NULL, "\n", &save)) {
            {
                size_t k;
                while (*ln == ' ' || *ln == '\r' || *ln == '\t') ln++;
                if (!*ln) continue;
                /* the daemon's heartbeat repeats with tiny differences, so
                   group on a PREFIX and count, instead of spamming the log */
                if (tick_events_only) { hud_event(ln); continue; }
                tick_push(ln);
                (void)k;
            }
        }
    }
    fclose(f);
}

/* ---------------- scene --------------------------------------------- */
static unsigned spark[40];
static int g_selftest __attribute__((unused));
static int g_render_only;

/* ---- calibration pattern -------------------------------------------------
   Designed so a single photo names the fault:
     - green 1-px grid every 32 logical px      -> stride / scale mismatch
     - white 8-px border at the exact edges     -> visible-area offset / crop
     - crosshair + dot at (0,0) and (CW-1,CH-1) -> origin offset
     - four colour bars in KNOWN order          -> byte order / format
     - one-pixel checker at the centre          -> scale factor (alias patttern)
   Diff it against the same pattern rendered in the rig. */
static void draw_calib(void)
{
    int x, y, i;
    static const unsigned int bars[4] = { C_RED, C_PHOS, C_CYAN, C_AMBER };
    rect(0, 0, CW, CH, 0x000000);
    for (y = 0; y < CH; y += 32) rect(0, y, CW, 1, 0x00ff00);
    for (x = 0; x < CW; x += 32) rect(x, 0, 1, CH, 0x00ff00);
    for (i = 0; i < 8; i++) {
        rect(i, i, CW - 2 * i, 1, 0xffffff);
        rect(i, CH - 1 - i, CW - 2 * i, 1, 0xffffff);
        rect(i, i, 1, CH - 2 * i, 0xffffff);
        rect(CW - 1 - i, i, 1, CH - 2 * i, 0xffffff);
    }
    /* colour bars, left-to-right in a FIXED order */
    for (i = 0; i < 4; i++)
        rect(40 + i * (CW - 80) / 4, 40, (CW - 80) / 4 - 8, 60, bars[i]);
    /* origin crosshair + centre checker */
    rect(0, 0, 24, 2, 0xffffff); rect(0, 0, 2, 24, 0xffffff);
    rect(CW - 24, CH - 2, 24, 2, 0xffffff); rect(CW - 2, CH - 24, 2, 24, 0xffffff);
    for (y = CH / 2 - 16; y < CH / 2 + 16; y++)
        for (x = CW / 2 - 16; x < CW / 2 + 16; x++)
            if (((x ^ y) & 1) == 0) rect(x, y, 1, 1, 0xffffff);
    {   /* legibility ruler: identical string at increasing sizes, labelled.
           A photo tells us which size reads on the actual TV. */
        static const int sizes[] = { 12, 16, 20, 26, 34, 44 };
        int yy = 120, k;
        char lab[32];
        for (k = 0; k < 6; k++) {
            snprintf(lab, sizeof lab, "%dpx", sizes[k]);
            text1(lab, 12, yy, 0x00b34d);
            if (g_font_ok) ttf_text("READ THIS FROM THE SOFA", 90, yy, sizes[k] / SCAL, 0xffffff);
            yy += sizes[k] / SCAL + 10;
        }
    }
    text1("CALIBRATION  CW=640 CH=360", 12, CH - 20, 0xffffff);
}


/* ---- whole-screen effects ------------------------------------------------
   A post pass over the finished frame, operating on DEVICE pixels in the
   locked buffer (in place, except distortion which needs a source copy).
   Every effect is cheap enough for an ARM926 at 720p: no floats in the inner
   loops except distortion's row scale.

   Mask (HUD_FX or profile "fx"):
     1 scanlines      2 chromatic aberration   4 glitch bands
     8 barrel distortion  16 vignette          32 noise
     64 roll/sweep    128 phosphor bloom
   Default when enabled: scanlines|aberration|glitch|vignette (0x17). */
static unsigned g_fx;             /* 0 = off */
static unsigned g_fx_lfsr = 0x1234567u;

static unsigned fx_rand(void)
{
    g_fx_lfsr ^= g_fx_lfsr << 13;
    g_fx_lfsr ^= g_fx_lfsr >> 17;
    g_fx_lfsr ^= g_fx_lfsr << 5;
    return g_fx_lfsr;
}

/* row pointer helper for device coords */
static unsigned int *fxd(int x, int y) { return fb + (size_t)y * pitch_px + x; }

static void fx_scanlines(int w, int h)
{
    int y, x;
    int period = (h >= 1000) ? 3 : 2;   /* 2-px aliases on a 1080p panel */
    for (y = 0; y < h; y += period)
        for (x = 0; x < w; x++) {
            unsigned int v = *fxd(x, y);
            unsigned int r = ((v >> 16) & 0xff) * 3 / 4;
            unsigned int g = ((v >> 8) & 0xff) * 3 / 4;
            unsigned int b = (v & 0xff) * 3 / 4;
            *fxd(x, y) = (r << 16) | (g << 8) | b;
        }
}

static void fx_aberration(int w, int h)
{
    int y, x, d = 2;                        /* channel separation, device px */
    for (y = 0; y < h; y++)
        for (x = 0; x < w; x++) {
            unsigned int *c = fxd(x, y);
            unsigned int l = (x >= d) ? *fxd(x - d, y) : *c;
            unsigned int r = (x + d < w) ? *fxd(x + d, y) : *c;
            unsigned int rr = (r >> 16) & 0xff;   /* red sampled right  */
            unsigned int gg = ((*c) >> 8) & 0xff;
            unsigned int bb = l & 0xff;           /* blue sampled left  */
            *c = (rr << 16) | (gg << 8) | bb;
        }
}

static void fx_glitch(int w, int h, int frame)
{
    int bands = 2 + (int)(fx_rand() % 3), b;
    for (b = 0; b < bands; b++) {
        int y0 = (int)(fx_rand() % (unsigned)h);
        int hh = 2 + (int)(fx_rand() % 10);
        int sh = (int)(fx_rand() % 13) - 6;       /* horizontal shift, clamped */
        int y, x;
        for (y = y0; y < y0 + hh && y < h; y++)
            for (x = 0; x < w; x++) {
                unsigned int *dst = fxd(x, y);
                int sx = x + sh;
                if (sx < 0) sx = 0;
                if (sx >= w) sx = w - 1;
                *dst = *fxd(sx, y);
                if (y == y0 && (x & 7) == 0) *dst = 0x00ff66;  /* tear line */
            }
    }
    (void)frame;
}

static void fx_vignette(int w, int h)
{
    int y, x;
    for (y = 0; y < h; y++)
        for (x = 0; x < w; x++) {
            /* cheap radial falloff, integer only */
            /* normalise the squared radius to 0..255 at the CORNERS */
            long dx = (long)x * 2 - w, dy = (long)y * 2 - h;
            long max2 = (long)w * w + (long)h * h;
            int d2 = (int)(((dx * dx + dy * dy) * 255) / (max2 ? max2 : 1));
            int k = 255 - d2 / 4;                     /* <=25% dip at corners */
            unsigned int v = *fxd(x, y);
            unsigned int r = (((v >> 16) & 0xff) * k) / 255;
            unsigned int g = (((v >> 8) & 0xff) * k) / 255;
            unsigned int b = ((v & 0xff) * k) / 255;
            *fxd(x, y) = (r << 16) | (g << 8) | b;
        }
}

static void fx_noise(int w, int h)
{
    int y, x;
    for (y = 0; y < h; y++)
        for (x = 0; x < w; x += 2) {
            unsigned n = fx_rand() & 0x0f;
            unsigned int v = *fxd(x, y);
            unsigned int r = (((v >> 16) & 0xff) + n > 255) ? 255 : ((v >> 16) & 0xff) + n;
            *fxd(x, y) = (r << 16) | (v & 0xffff);
        }
}

static void fx_bloom(int w, int h)
{
    /* additive 1-px horizontal smear of bright pixels: a cheap phosphor glow */
    int y, x;
    for (y = 0; y < h; y++)
        for (x = 1; x < w - 1; x++) {
            unsigned int a = *fxd(x - 1, y), b = *fxd(x + 1, y);
            unsigned int v = *fxd(x, y);
            unsigned int lum = ((b >> 8) & 0xff);
            if (lum > 96) {
                unsigned int r = (v >> 16) & 0xff, g = (v >> 8) & 0xff, bl = v & 0xff;
                r = (r + ((a >> 16) & 0xff) / 6) > 255 ? 255 : r + ((a >> 16) & 0xff) / 6;
                g = (g + ((b >> 8) & 0xff) / 3) > 255 ? 255 : g + ((b >> 8) & 0xff) / 3;
                bl = (bl + (b & 0xff) / 8) > 255 ? 255 : bl + (b & 0xff) / 8;
                *fxd(x, y) = (r << 16) | (g << 8) | bl;
            }
        }
}

static void fx_barrel(int w, int h)
{
    /* nearest-neighbour barrel: sample along a curved row. Copy first. */
    static unsigned int *src;
    static size_t src_cap;
    int y, x;
    size_t need = (size_t)w * h;
    if (src_cap < need) {
        unsigned int *ns = realloc(src, need * sizeof(unsigned int));
        if (!ns) return;
        src = ns; src_cap = need;
    }
    for (y = 0; y < h; y++)
        for (x = 0; x < w; x++) src[(size_t)y * w + x] = *fxd(x, y);
    for (y = 0; y < h; y++)
        for (x = 0; x < w; x++) {
            int cx = x * 2 - w, cy = y * 2 - h;
            /* r^2 scaled down; the 6/4096 factor is a mild bulge */
            int r2 = (cx * cx + cy * cy) / (w + h);
            int sx = x + (cx * r2) / 12288;   /* mild bulge, not a fish-eye */
            int sy = y + (cy * r2) / 12288;
            if (sx < 0) sx = 0;
            if (sy < 0) sy = 0;
            if (sx >= w) sx = w - 1;
            if (sy >= h) sy = h - 1;
            *fxd(x, y) = src[(size_t)sy * w + sx];
        }
}

static void fx_apply(int frame)
{
    int w = g_visible_w ? g_visible_w : CW * SCAL;
    int h = g_visible_h ? g_visible_h : CH * SCAL;
    if (!g_fx) return;
    if (g_fx & 4) fx_glitch(w, h, frame);
    if (g_fx & 8) fx_barrel(w, h);
    if (g_fx & 2) fx_aberration(w, h);
    if (g_fx & 1) fx_scanlines(w, h);
    if (g_fx & 16) fx_vignette(w, h);
    if (g_fx & 32) fx_noise(w, h);
    if (g_fx & 128) fx_bloom(w, h);
    if (g_fx & 64) {   /* rolling brightness sweep */
        int y0 = (int)((unsigned)frame * 7) % (h ? h : 1);
        int y, x;
        for (y = y0; y < y0 + 24 && y < h; y++)
            for (x = 0; x < w; x++) {
                unsigned int v = *fxd(x, y);
                unsigned int r = (v >> 16) & 0xff, g = (v >> 8) & 0xff, b = v & 0xff;
                *fxd(x, y) = (((r + 24 > 255 ? 255 : r + 24) << 16) |
                              ((g + 40 > 255 ? 255 : g + 40) << 8) |
                              (b + 24 > 255 ? 255 : b + 24));
            }
    }
    return;
}


/* ================= AMIGA / VIDEO-TOASTER LOOK ===========================
   The reference is early digitised TV graphics: Amiga DPaint + genlock,
   Video Toaster DVE, and the composite/VHS path between them. Implemented as
   the vocabulary of that era rather than generic noise:

     AMIGA_QUANT   4 bits/channel quantisation + 4x4 Bayer ordered dither
                   (the 4096-colour Amiga palette look)
     AMIGA_COPPER  moving copper-list gradient bars behind the panels
     AMIGA_BOING   the checkered bouncing ball (Boing), not a wireframe cube
     AMIGA_NTSC    composite artifacts: chroma bleed rightward, dot crawl on
                   edges, mild ringing
     AMIGA_INTER   interlace flicker: alternate scanlines dimmed per field
     AMIGA_VHS     rolling tracking band, head-switching noise at the bottom,
                   dropouts
     AMIGA_DVE     Toaster wipes: mosaic blocks / venetian blinds / strobe
   ======================================================================= */
#define AMIGA_QUANT  0x100u
#define AMIGA_COPPER 0x200u
#define AMIGA_BOING  0x400u
#define AMIGA_NTSC  0x800u
#define AMIGA_INTER 0x1000u
#define AMIGA_VHS   0x2000u
#define AMIGA_DVE   0x4000u
#define AMIGA_PRESET (AMIGA_QUANT|AMIGA_COPPER|AMIGA_BOING|AMIGA_NTSC|AMIGA_INTER|AMIGA_VHS)

static const unsigned char BAYER4[4][4] = {
    {  0,  8,  2, 10 },
    { 12,  4, 14,  6 },
    {  3, 11,  1,  9 },
    { 15,  7, 13,  5 }
};

/* quantise one colour with ordered dither; called from the pixel primitives so
   there is no extra full-frame pass */
static unsigned int amiga_quant(unsigned int c, int x, int y)
{
    unsigned int r = (c >> 16) & 0xff, g = (c >> 8) & 0xff, b = c & 0xff;
    int d = BAYER4[y & 3][x & 3] - 8;          /* -8..+7 */
    r = (unsigned)((int)r + d); g = (unsigned)((int)g + d); b = (unsigned)((int)b + d);
    r = (r > 255 ? 255 : r) & 0xf0;            /* 4 bits per channel */
    g = (g > 255 ? 255 : g) & 0xf0;
    b = (b > 255 ? 255 : b) & 0xf0;
    /* a little of the dither back so it reads as dither, not banding */
    r |= BAYER4[y & 3][x & 3] >> 2;
    g |= BAYER4[y & 3][x & 3] >> 2;
    b |= BAYER4[y & 3][x & 3] >> 2;
    return (c & 0xff000000u) | (r << 16) | (g << 8) | b;
}

/* copper bars: horizontal gradient bands that drift, drawn under the panels */
static void amiga_copper_backdrop(double t)
{
    int y, x;
    for (y = 0; y < CH; y++) {
        double ph = (double)y / 40.0 + t * 0.8;
        int a = (int)(80 + 60 * sin(ph));
        int b = (int)(80 + 60 * sin(ph + 2.1));
        int c = (int)(80 + 60 * sin(ph + 4.2));
        unsigned int col = ((unsigned)(a & 0xff) << 16) | ((unsigned)(b & 0xff) << 8)
                         | (unsigned)(c & 0xff);
        for (x = 0; x < CW; x++) {
            /* dim toward the middle so text stays readable */
            unsigned int k = (unsigned)(150 + 80 * cos((double)x / 70.0 + t));
            rect(x, y, 1, 1, ((((col >> 16) & 0xff) * k / 160) << 16) |
                             ((((col >> 8) & 0xff) * k / 160) << 8) |
                             (((col & 0xff) * k / 160)));
        }
    }
}

/* Boing: checkered ball, gravity + bounce, squashed on impact */
static void amiga_boing(double t)
{
    const double g = 900.0, e = 0.86;
    const int floor_y = CH - 40, r = 26;
    double period = 2.0 * sqrt(2.0 * (floor_y - r) / g);
    double ph = fmod(t, period);
    double h = (floor_y - r) - 0.5 * g * ph * ph;
    int cy, cx = 512 + (int)(18 * sin(t * 0.6)), k;
    int squash;
    if (h < r) { h = r + fabs(h - r) * e; }
    cy = (int)h;
    squash = (cy > floor_y - r - 6) ? 8 : 0;
    for (k = -r; k <= r; k++)
        for (int j = -r; j <= r; j++) {
            double rx = (double)(r + squash), ry = (double)(r - squash);
            double dx = (double)k, dy = (double)j;
            if ((dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) > 1.0) continue;
            {
                int chk = ((k / 6) + (j / 6)) & 1;
                rect(cx + k, cy + j, 1, 1, chk ? 0xd8d8d8 : 0x101010);
            }
        }
}

/* composite/video artifacts, applied over the finished frame */
static void amiga_ntsc(int w, int h, int frame)
{
    int y, x;
    for (y = 0; y < h; y++) {
        unsigned int prev = *fxd(0, y);
        for (x = 1; x < w; x++) {
            unsigned int *c = fxd(x, y);
            unsigned int v = *c;
            unsigned int r = (v >> 16) & 0xff, g = (v >> 8) & 0xff, b = v & 0xff;
            unsigned int pr = (prev >> 16) & 0xff, pg = (prev >> 8) & 0xff, pb = prev & 0xff;
            /* chroma bleed: smear colour to the right, luma stays sharp */
            r = (r * 3 + pr) / 4;
            b = (b * 3 + pb) / 4;
            g = (g * 3 + pg) / 4;
            /* dot crawl on horizontal edges */
            if (((x + y + frame) & 3) == 0) {
                unsigned int up = (y > 0) ? *fxd(x, y - 1) : v;
                int du = (int)(((up >> 8) & 0xff)) - (int)g;
                if (du > 24 || du < -24) g = (g + 18 > 255) ? 255 : g + 18;
            }
            *c = (r << 16) | (g << 8) | b;
            prev = v;
        }
    }
}

static void amiga_interlace(int w, int h, int frame)
{
    int y, x;
    int phase = frame & 1;
    for (y = 0; y < h; y++) {
        if ((y & 1) != phase) continue;          /* the other field */
        for (x = 0; x < w; x++) {
            unsigned int v = *fxd(x, y);
            unsigned int r = ((v >> 16) & 0xff) * 15 / 16;
            unsigned int g = ((v >> 8) & 0xff) * 15 / 16;
            unsigned int b = (v & 0xff) * 15 / 16;
            *fxd(x, y) = (r << 16) | (g << 8) | b;
        }
    }
}

static void amiga_vhs(int w, int h, int frame)
{
    int y, x;
    int band = (int)((unsigned)frame * 11) % (h + 60) - 30;   /* rolling band */
    for (y = band; y < band + 10; y++) {
        if (y < 0 || y >= h) continue;
        int sh = 3 + (int)(fx_rand() % 5);
        for (x = 0; x < w; x++) {
            unsigned int *d = fxd(x, y);
            unsigned n = fx_rand() & 0x3f;                    /* snow */
            unsigned int v = *fxd((x + sh) % w, y);
            unsigned int r = ((v >> 16) & 0xff) / 2 + n;
            unsigned int g = ((v >> 8) & 0xff) / 2 + n;
            unsigned int b = (v & 0xff) / 2 + n;
            *d = ((r > 255 ? 255 : r) << 16) | ((g > 255 ? 255 : g) << 8) |
                 (b > 255 ? 255 : b);
        }
    }
    /* head-switching noise along the bottom edge */
    for (y = h - 6; y < h; y++) {
        if (y < 0) continue;
        int sh = (int)(fx_rand() % 7);
        for (x = 0; x < w; x++) {
            unsigned int v = *fxd((x + sh) % w, y);
            unsigned n = fx_rand() & 0x1f;
            unsigned int r = ((v >> 16) & 0xff) / 3 + n;
            *fxd(x, y) = (r << 16) | (v & 0x00ffff);
        }
    }
    /* occasional dropout: a white speck column */
    if ((frame % 17) == 0) {
        int dx = (int)(fx_rand() % (unsigned)w);
        int dy = (int)(fx_rand() % (unsigned)h);
        int k;
        for (k = 0; k < 3; k++) fxd((dx + k) % w, dy)[0] = 0xffffff;
    }
}

static void amiga_dve(int w, int h, int frame)
{
    /* Toaster-style treatment that cycles: mosaic -> blinds -> strobe */
    int mode = (frame / 40) % 3;
    int y, x;
    if (mode == 0) {                       /* mosaic blocks */
        int bs = 12;
        for (y = 0; y < h; y += bs)
            for (x = 0; x < w; x += bs) {
                unsigned int v = *fxd(x, y);
                int yy, xx;
                for (yy = 0; yy < bs && y + yy < h; yy++)
                    for (xx = 0; xx < bs && x + xx < w; xx++)
                        *fxd(x + xx, y + yy) = v;
            }
    } else if (mode == 1) {                /* venetian blinds */
        for (y = 0; y < h; y++)
            if ((y % 24) < 8)
                for (x = 0; x < w; x++) fxd(x, y)[0] >>= 2;
    } else {                               /* strobe: brief invert */
        if ((frame % 20) < 2)
            for (y = 0; y < h; y++)
                for (x = 0; x < w; x++) {
                    unsigned int v = *fxd(x, y);
                    *fxd(x, y) = (~v) & 0x00ffffff;
                }
    }
}

static void amiga_apply(int frame, double t)
{
    int w = g_visible_w ? g_visible_w : CW * SCAL;
    int h = g_visible_h ? g_visible_h : CH * SCAL;
    if (g_fx & AMIGA_INTER) amiga_interlace(w, h, frame);
    if (g_fx & AMIGA_NTSC) amiga_ntsc(w, h, frame);
    if (g_fx & AMIGA_VHS) amiga_vhs(w, h, frame);
    if (g_fx & AMIGA_DVE) amiga_dve(w, h, frame);
    (void)t;
}

static void scene(const hud_t *h, double t, double fps, int frame)
{
    /* ---- type scale from the panel, in DEVICE px (no logical-px constants) --
       head  = H/26  (~28 at 720p, 42 at 1080p)
       body  = H/38  (~19 / 28)
       small = H/54  (~13 / 20)                                        */
    int head = g_head_px, body = g_body_px, small = g_body_px * 3 / 4;
    int H = g_visible_h ? g_visible_h : CH * SCAL;
    int lh_head = line_h(head) / SCAL + 1;
    int lh_body = line_h(body) / SCAL + 1;
    int lh_small = line_h(small) / SCAL + 1;
    int pad = body / SCAL / 2 + 2;
    char l[128], up[16];
    int i;

    /* ---- backdrop ---- */
    rect(0, 0, CW, CH, C_BG);
    if (g_fx & AMIGA_COPPER) amiga_copper_backdrop(t);
    {
        int gy = 250 + (int)(fmod(t * 8.0, 8.0));
        for (; gy < CH; gy += 8) {
            int half = (gy - 250) * 2 + 20;
            rect(320 - half, gy, half * 2, 1, C_PHOSD);
        }
        for (i = -8; i <= 8; i++) line(320 + i * 18, 250, 320 + i * 80, CH, C_GRID);
        { int sy = (int)(fmod(t * 60.0, CH)); rect(0, sy, CW, 1, 0x0b3a1c); }
    }

    /* ---- status bar: height from the small face, not a constant ---- */
    {
        int barh = lh_small + pad * 2;
        int yb = pad;
        if (!(g_fx & AMIGA_COPPER)) rect(0, 0, CW, barh, C_PANEL);
        text_top("SACD//RIPPER", pad, yb, small, C_PHOS);
        snprintf(up, sizeof up, "%02lu:%02lu:%02lu", h->uptime_s / 3600,
                 (h->uptime_s / 60) % 60, h->uptime_s % 60);
        text_top(up, pad + 20, yb, small, C_PHOSD);
        snprintf(l, sizeof l, "%.0f FPS", fps);
        text_top_r(l, CW - pad - 14, yb, small, C_PHOSD);
        text_top_r(h->clients_2002 ? "LIVE" : (h->listen_2002 ? "ARMED" : "IDLE"),
                   CW - pad, yb, small, h->clients_2002 ? C_PHOS : C_AMBER);

        /* ---- panels below the bar, equal height, footer clearance ---- */
        {
            int top = barh + pad;
            int map_h = lh_small + pad;
            int bot = CH - lh_small - map_h - pad * 3;
            int lw = (CW - pad * 3) * 6 / 10;
            int rx = pad * 2 + lw;
            int rw = CW - rx - pad;
            int lip, rip, riy;
            snprintf(l, sizeof l, "CPSA %s  %s  PID %d",
                     h->module_loaded ? "LOADED" : "DOWN",
                     h->listen_2002 ? ":2002 LISTEN" : ":2002 CLOSED", h->daemon_pid);
            if (!(g_fx & AMIGA_COPPER)) { rect(pad, top, lw, bot - top, C_PANEL); }
            box(pad, top, lw, bot - top, C_FRAME);
            if (!(g_fx & AMIGA_COPPER)) { rect(rx, top, rw, bot - top, C_PANEL); }
            box(rx, top, rw, bot - top, C_FRAME);

            /* left: state (head) then the ticker (body) */
            lip = pad * 2; rip = rx + pad; riy = top + pad;
            text_top("EVENT STREAM", lip, top + pad, small, C_CYAN);
            {
                int y = top + pad + lh_small + 2;
                int avail = lw - pad * 2;
                int n, shown = 0;
                char cut[80];
                snprintf(cut, sizeof cut, "STATE %s", h->state);
                text_top(cut, lip, y, head, C_WHITE); y += lh_head + 2;
                snprintf(cut, sizeof cut, "CLIENTS %d   READ %lluM",
                         h->clients_2002, (unsigned long long)(h->read_bytes >> 20));
                text_top(cut, lip, y, body, h->clients_2002 ? C_PHOS : C_PHOSD);
                y += lh_body + 3;
                n = tick_n < TICK_MAX ? tick_n : TICK_MAX;
                for (i = 0; i < n && y < bot - lh_body; i++) {
                    int idx = (tick_n - n + i) % TICK_MAX;
                    if (idx < 0) continue;
                    snprintf(l, sizeof l, "%s", tick[idx]);
                    {   /* clip to the panel width using the REAL metrics */
                        int wpx = ttf_width(l, body / SCAL ? body / SCAL : 6);
                        while (wpx > avail && strlen(l) > 1) {
                            l[strlen(l) - 1] = 0;
                            wpx = ttf_width(l, body / SCAL ? body / SCAL : 6);
                        }
                    }
                    text_top(l, lip, y, body,
                             (i >= n - 2) ? C_WHITE : (i >= n - 5 ? C_PHOS : C_PHOSD));
                    y += lh_body;
                    shown++;
                }
                if (!shown) text_top("(idle)", lip, y, body, C_PHOSD);
                if (h->note[0]) text_top(h->note, lip, bot - lh_small - 2, small, C_RED);
            }

            /* right: throughput, sparkline, disc map, stats, alerts, ball */
            text_top("TELEMETRY", rip, top + pad, small, C_CYAN);
            riy = top + pad + lh_small + 2;
            snprintf(l, sizeof l, "%.1f MB/s", ev_mbps ? (double)ev_mbps : h->mbps);
            text_top(l, rip, riy, head, C_WHITE); riy += lh_head + 4;
            for (i = 0; i < 39; i++) spark[i] = spark[i + 1];
            { double m = (double)(ev_mbps ? ev_mbps : h->mbps) * 2.0;
              spark[39] = (unsigned)(m > 70 ? 70 : m); }
            {
                int sw2 = (rw - pad * 2) / 38, sh2 = lh_body * 3;
                for (i = 0; i < 38; i++)
                    rect(rip + i * sw2, riy + sh2 - (int)spark[i] / 2, sw2 - 1,
                         (int)spark[i] / 2, (i > 28) ? C_AMBER : C_PHOS);
                riy += sh2 + 4;
            }
            {   /* disc map sized to the panel, head position from the last LSN */
                unsigned long long total = DISC_SECTORS * SECTOR_BYTES;
                int mw = rw - pad * 2, mh = lh_small;
                int cells = 36, lit = total ? (int)((double)ev_last_lsn * SECTOR_BYTES /
                                                    (double)total * cells) : 0;
                int cw = mw / cells;
                if (lit > cells) lit = cells;
                box(rip, riy, mw, mh, C_FRAME);
                for (i = 0; i < cells; i++) {
                    unsigned int c = C_PHOSD;
                    if (i < lit) c = C_PHOS;
                    if (i == lit) c = C_WHITE;
                    rect(rip + 2 + i * cw, riy + 2, cw - 1, mh - 4, c);
                }
                riy += mh + lh_small / 2;
            }
            snprintf(l, sizeof l, "REQ %llu  SEC %llu  LSN %llu",
                     ev_requests, ev_sectors, ev_last_lsn);
            text_top(l, rip, riy, body, C_PHOS); riy += lh_body;
            snprintf(l, sizeof l, "MEM %luM  TMP %u%%",
                     h->memfree_kb / 1024,
                     h->tmp_pct);
            text_top(l, rip, riy, body, h->tmp_pct > 90 ? C_RED : C_PHOSD); riy += lh_body;
            snprintf(l, sizeof l, "CPSA %d  %s", h->misc_201, h->state);
            text_top(l, rip, riy, body, C_WHITE); riy += lh_body + lh_small / 2;
            {
                int ah = lh_small + lh_small / 2 + 4;
                box(rip, riy, rw - pad * 2, ah, C_FRAME);
                text_top("ALERTS", rip + 2, riy + 2, small, C_CYAN);
                text_top(h->note[0] ? h->note : "NONE", rip + 2, riy + 2 + lh_small,
                         small, h->note[0] ? C_RED : C_PHOS);
                riy += ah + lh_small;
            }
            if (g_fx & AMIGA_BOING) amiga_boing(t);
            else {
                int cx = rip + (rw - pad) / 2, cy = riy + (bot - riy) / 2 - lh_small;
                int r = (bot - riy) / 4;
                if (r > lh_body * 2) r = lh_body * 2;
                if (r > 8) {
                    static const double v[8][3] = {
                        {-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1},
                        {-1,-1, 1},{1,-1, 1},{1,1, 1},{-1,1, 1} };
                    static const int e[12][2] = {
                        {0,1},{1,2},{2,3},{3,0},{4,5},{5,6},{6,7},{7,4},{0,4},{1,5},{2,6},{3,7} };
                    int p[8][2], k;
                    double a = t * 0.9, ca = cos(a), sa = sin(a), cb = cos(t * 0.37), sb = sin(t * 0.37);
                    for (k = 0; k < 8; k++) {
                        double x = v[k][0], y = v[k][1], z = v[k][2], x1, z1, y1;
                        x1 = x * ca - z * sa; z1 = x * sa + z * ca;
                        y1 = y * cb - z1 * sb; z1 = y * sb + z1 * cb;
                        { double d = 4.0 / (4.0 + z1);
                          p[k][0] = cx + (int)(x1 * r * d);
                          p[k][1] = cy + (int)(y1 * r * d); }
                    }
                    for (k = 0; k < 12; k++)
                        line(p[e[k][0]][0], p[e[k][0]][1], p[e[k][1]][0], p[e[k][1]][1], C_PHOSD);
                }
            }
        }
        {   /* full-width disc map strip, above the footer */
            unsigned long long total = DISC_SECTORS * SECTOR_BYTES;
            int top2 = CH - lh_small - (lh_small + pad) - pad;
            int mh = lh_small + pad / 2;
            int x0 = pad, wpx = CW - pad * 2, cells = 72, cw = wpx / cells;
            int lit = total ? (int)((double)ev_last_lsn * SECTOR_BYTES / (double)total * cells) : 0;
            char lab[64];
            if (lit > cells) lit = cells;
            box(x0, top2, wpx, mh, C_FRAME);
            for (i = 0; i < cells; i++) {
                unsigned int c = C_PHOSD;
                if (i < lit) c = C_PHOS;
                if (i == lit) c = C_WHITE;
                rect(x0 + 2 + i * cw, top2 + 2, cw - 1, mh - 4, c);
            }
            snprintf(lab, sizeof lab, "DISC %llu/%llu",
                     ev_last_lsn, (unsigned long long)DISC_SECTORS);
            text_top_r(lab, CW - pad, top2 - lh_small - 2, small, C_PHOSD);
        }
        /* footer */
        text_top("SACD HUD", pad, CH - lh_small - 1, small, C_PHOSD);

    }
}

#ifdef HUD_SIM
/* ---- host simulator: same scene(), real font, no DirectFB, no device ----
   cc -DHUD_SIM -I. -o hudsim bx510_sacd_hud.c && ./hudsim out.ppm [frames] */
int main(int argc, char **argv)
{
    hud_t h;
    const char *out = (argc > 1) ? argv[1] : "/tmp/hud_sim.ppm";
    int frames = (argc > 2) ? atoi(argv[2]) : 1;
    int i;
    FILE *f;
    const char *fp = getenv("HUD_FONT");
    if (!fp || !fp[0]) fp = "sony-font.ttf";
    SCAL = 2;
    pitch_px = CW * SCAL;
    fb = calloc((size_t)pitch_px * CH * SCAL, sizeof(unsigned int));
    if (!fb) return 1;
    if (font_load(fp)) printf("SIM: font %s\n", fp);
    else printf("SIM: no font at %s (5x7 fallback)\n", fp);

    memset(&h, 0, sizeof h);
    h.module_loaded = 1; h.misc_201 = 1; h.listen_2002 = 1; h.clients_2002 = 1;
    h.daemon_pid = 4682; h.uptime_s = 872; h.memfree_kb = 155 * 1024; h.tmp_pct = 0;
    snprintf(h.state, sizeof h.state, "SERVING");
    ev_requests = 1024; ev_sectors = 532104; ev_last_lsn = 532104; ev_mbps = 5;
    for (i = 0; i < 39; i++) spark[i] = (unsigned)(6 + (i * 7) % 18);
    tick_push("CLIENT CONNECTED");
    tick_push("READ lsn=532104 n=128 (256K)");
    tick_push("READ lsn=532232 n=128 (256K)");
    tick_push("READ lsn=0 n=128 (256K)");
    tick_push("CLOSE rc=0");

    g_visible_w = CW * SCAL; g_visible_h = CH * SCAL;
    typography_set(g_visible_h);
    printf("SIM: type head=%d body=%d (visible_h=%d)\n", g_head_px, g_body_px, g_visible_h);
    if (getenv("HUD_FX") && !strcmp(getenv("HUD_FX"), "amiga")) g_fx = AMIGA_PRESET;
    else if (getenv("HUD_FX")) g_fx = (unsigned)strtoul(getenv("HUD_FX"), NULL, 0);
    else g_fx = 0x17;
    for (i = 0; i < frames; i++) {
        scene(&h, 1.7 + i * 0.2, 13.0, i * 4);
        fx_apply(i * 4 + 8);
        amiga_apply(i * 4 + 8, 1.7 + i * 0.2);
    }

    f = fopen(out, "wb");
    if (!f) return 1;
    fprintf(f, "P6\n%d %d\n255\n", CW * SCAL, CH * SCAL);
    for (i = 0; i < pitch_px * CH * SCAL; i++) {
        unsigned int v = fb[i];
        unsigned char rgb[3] = { (unsigned char)((v >> 16) & 0xff),
                                 (unsigned char)((v >> 8) & 0xff),
                                 (unsigned char)(v & 0xff) };
        fwrite(rgb, 1, 3, f);
    }
    fclose(f);
    printf("SIM: wrote %s (%dx%d)\n", out, CW * SCAL, CH * SCAL);
    return 0;
}
#else
/* ---- Tier-3 shortcut: draw straight into the vendor POOL slice ----------
   The scan-out on this SoC is a buffer allocated from the MT85 image pool, not
   the fbdev smem (hardware proved fbdev paint is overwritten in <2 s). The
   module dispatches mmap classes BY LENGTH, so mmap(POOL_LEN) hands us the
   same slice the retail provider maps. No DirectFB, no command ring, no Flip.
   Enable with HUD_POOL=1. */
/* device profile: what the panel actually is. Filled from the calibration run
   (or read from /tmp/hud-profile). Fields: scale, xoff, yoff, visible_w,
   visible_h, pitch. Anything absent keeps the default. */

static void profile_load(void)
{
    FILE *f = fopen("/tmp/hud-profile", "r");
    char k[32];
    int v;
    if (!f) return;
    while (fscanf(f, "%31[a-z_] = %d", k, &v) == 2) {
        if (!strcmp(k, "scale")) SCAL = v;
        else if (!strcmp(k, "xoff")) g_xoff = v;
        else if (!strcmp(k, "yoff")) g_yoff = v;
        else if (!strcmp(k, "visible_w")) g_visible_w = v;
        else if (!strcmp(k, "visible_h")) g_visible_h = v;
        else if (!strcmp(k, "pitch")) g_pitch = v;
        else if (!strcmp(k, "fx")) g_fx = (unsigned)v;
        else if (!strcmp(k, "order")) g_order = v;
        else if (!strcmp(k, "head_px")) g_head_px = v;
        else if (!strcmp(k, "body_px")) g_body_px = v;
    }
    fclose(f);
    printf("HUD: profile scale=%d xoff=%d yoff=%d vis=%dx%d pitch=%d\n",
           SCAL, g_xoff, g_yoff, g_visible_w, g_visible_h, g_pitch);
}

static int pool_open(const char *dev)
{
    struct fb_var_screeninfo vi;
    struct fb_fix_screeninfo fi;
    size_t len;
    int fd = open(dev, O_RDWR);
    void *m;
    if (fd < 0) { printf("HUD: pool open %s failed\n", dev); return 0; }
    /* GEOMETRY FROM THE DEVICE, never assumed. Writing 1280-wide rows into a
       1920-wide scanout shears every row (the panel photo showed exactly the
       diagonal banding that produces). */
    if (ioctl(fd, FBIOGET_VSCREENINFO, &vi) == 0 && ioctl(fd, FBIOGET_FSCREENINFO, &fi) == 0
        && vi.xres && vi.yres && fi.line_length) {
        printf("HUD: fbdev %s %ux%u bpp=%u stride=%u smem=%u\n",
               dev, vi.xres, vi.yres, vi.bits_per_pixel, fi.line_length, fi.smem_len);
        SCAL = vi.xres / CW;
        if (SCAL < 1) SCAL = 1;
        g_visible_w = vi.xres;
        g_visible_h = vi.yres;
        len = fi.smem_len ? fi.smem_len : (size_t)fi.line_length * vi.yres;
        m = mmap(NULL, len, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (m == MAP_FAILED) { printf("HUD: fbdev mmap %zu failed\n", len); close(fd); return 0; }
        fb = m;
        pitch_px = fi.line_length / (vi.bits_per_pixel / 8);
        close(fd);
        typography_set(g_visible_h);
        printf("HUD: geom %ux%u scale=%d pitch=%d type head=%d body=%d\n",
               g_visible_w, g_visible_h, SCAL, pitch_px, g_head_px, g_body_px);
        return 1;
    }
    printf("HUD: fbdev geometry read failed, falling back to pool length\n");
    len = (size_t)CW * SCAL * (size_t)CH * SCAL * 4u + 0x1000u;
    m = mmap(NULL, len, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    close(fd);
    if (m == MAP_FAILED) { printf("HUD: pool mmap %zu failed\n", len); return 0; }
    fb = m;
    pitch_px = CW * SCAL;
    if (getenv("HUD_VISIBLE_H")) typography_set(atoi(getenv("HUD_VISIBLE_H")));
    g_visible_w = g_visible_w ? g_visible_w : CW * SCAL;
    g_visible_h = g_visible_h ? g_visible_h : CH * SCAL;
    if (getenv("HUD_FX") && !strcmp(getenv("HUD_FX"), "amiga")) g_fx = AMIGA_PRESET;
    else if (getenv("HUD_FX")) g_fx = (unsigned)strtoul(getenv("HUD_FX"), NULL, 0);
    else g_fx = 0x17;      /* default look: scanlines+aberration+glitch+vignette */
    if (!getenv("HUD_KEEP_TYPE")) typography_set(g_visible_h);
    printf("HUD: pool %s mapped len=%zu (%dx%d) — drawing directly, no Flip\n",
           dev, len, CW * SCAL, CH * SCAL);
    printf("HUD: typography head=%d body=%d device px\n", g_head_px, g_body_px);
    return 1;
}

int main(int argc, char **argv)
{
    IDirectFB *dfb;
    IDirectFBSurface *prim = NULL;
    DFBSurfaceDescription dsc;
    DFBResult ret;
    int hold = (argc > 1) ? atoi(argv[1]) : 120;
    const char *ticker = (argc > 2) ? argv[2] : "/tmp/cand.out";
    hud_t h;
    int pw = 0, ph = 0, first_blit = 1, first_blit2 = 0;
    (void)first_blit2;
    struct timespec t0, now;
    unsigned frames = 0;
    long long next_sample = 0, next_frame = 0;
    double fps = 0;

    if (hold < 1) hold = 1;
    if (hold > 600) hold = 600;

    setvbuf(stdout, NULL, _IOLBF, 0);
    if (getenv("HUD_POOL")) {
        const char *fp2 = getenv("HUD_FONT");
        int i;
        hud_t hp;
        if (!pool_open(getenv("HUD_POOL")[0] == '1' ? "/dev/fb0" : getenv("HUD_POOL")))
            return 1;
        if (!fp2 || !fp2[0]) fp2 = "/tmp/sony-font.ttf";
        if (font_load(fp2)) printf("HUD: font %s\n", fp2);
        memset(&hp, 0, sizeof hp);
        hp.module_loaded = 1; hp.misc_201 = 1; hp.listen_2002 = 1; hp.clients_2002 = 1;
        hp.daemon_pid = 4682; hp.uptime_s = 872; hp.memfree_kb = 155 * 1024;
        snprintf(hp.state, sizeof hp.state, "SERVING");
        ev_requests = 1024; ev_sectors = 532104; ev_last_lsn = 532104; ev_mbps = 5;
        for (i = 0; i < 39; i++) spark[i] = (unsigned)(6 + (i * 7) % 18);
        tick_push("CLIENT CONNECTED");
        tick_push("READ lsn=532104 n=128 (256K)");
        tick_push("CLOSE rc=0");
        profile_load();
        if (getenv("HUD_CALIB")) { g_fx = 0; draw_calib(); }   /* measure RAW */
        else scene(&hp, 1.7, 13.0, 8);
        fx_apply(8);
        amiga_apply(8, 1.7);
        printf("HUD: effects mask 0x%x applied\n", g_fx);
        printf("HUD: POOL-RENDER DONE\n");
        return 0;
    }
    {
        int selftest = (argc > 1 && !strcmp(argv[1], "--selftest"));
        int renderonly = (argc > 1 && !strcmp(argv[1], "--render"));
        if (selftest) { hold = 1; }
        if (renderonly) { hold = 1; g_render_only = 1; }
        g_selftest = selftest;
    }
    ret = DirectFBInit(&argc, &argv);
    printf("HUD: DirectFBInit rc=%d\n", ret);
    if (ret) return 1;
    ret = DirectFBCreate(&dfb);
    printf("HUD: DirectFBCreate rc=%d\n", ret);
    if (ret) return 2;

    /* CAPS ONLY: provider hands back the panel's own mode. Drawing goes
       straight into the LOCKED PRIMARY: the canvas + StretchBlit route went
       through the provider's accelerated command buffer, which segfaults in
       the guest (FBIO_DISPATCHHW storm) and blanked the panel on hardware. */
    memset(&dsc, 0, sizeof dsc);
    dsc.flags = DSDESC_CAPS;
    dsc.caps = DSCAPS_PRIMARY | DSCAPS_FLIPPING;
    ret = dfb->CreateSurface(dfb, &dsc, &prim);
    printf("HUD: CreateSurface(primary, panel mode) rc=%d\n", ret);
    if (ret) { dfb->Release(dfb); return 3; }
    prim->GetSize(prim, &pw, &ph);
    printf("HUD: panel %dx%d\n", pw, ph);
    SCAL = pw / CW;
    if (SCAL < 1) SCAL = 1;
    printf("HUD: logical %dx%d scale=%d\n", CW, CH, SCAL);
    printf("HUD: drawing directly into the primary (no canvas, no blit)\n");

    udp_open();
    printf("HUD: host channel udp/%d %s\n", HUD_UDP_PORT, udp_fd >= 0 ? "OPEN" : "unavailable");
    {
        const char *fp = getenv("HUD_FONT");
        if (!fp || !fp[0]) fp = "/tmp/sony-font.ttf";
        if (font_load(fp)) printf("HUD: font %s loaded (TiresiasScreenfont)\n", fp);
        else printf("HUD: font %s NOT loaded — falling back to the 5x7 face\n", fp);
    }
    sample(&h, 1);
    ticker_poll(ticker);
    tick_events_only = 1;
    ticker_poll("/tmp/hud-events.log");
    clock_gettime(CLOCK_MONOTONIC, &t0);

    for (;;) {
        long long el;
        double secs, t;
        void *lockptr = NULL;
        int lockpitch = 0;
        int locked = 0;

        clock_gettime(CLOCK_MONOTONIC, &now);
        el = (now.tv_sec - t0.tv_sec) * 1000LL + (now.tv_nsec - t0.tv_nsec) / 1000000LL;
        secs = el / 1000.0;
        t = secs;
        if (secs >= (double)hold) break;

        udp_poll();
        if (t - ev_win_t >= 1.0) {
            ev_mbps = (unsigned long long)((ev_bytes - ev_bytes_win) / (1024 * 1024));
            ev_bytes_win = ev_bytes;
            ev_win_t = t;
        }
        if (el >= next_sample) {
            sample(&h, 0);
            udp_poll();
            ticker_poll(ticker);
            tick_events_only = 1;
            ticker_poll("/tmp/hud-events.log");
            next_sample = el + 250;
        }
        {
            static int prev_clients = -1, prev_listen = -1, prev_module = -1;
            if (prev_module != h.module_loaded) {
                tick_push(h.module_loaded ? "CPSA MODULE LOADED" : "CPSA MODULE GONE");
                prev_module = h.module_loaded;
            }
            if (prev_listen != h.listen_2002) {
                tick_push(h.listen_2002 ? "LISTENER :2002 UP" : "LISTENER :2002 DOWN");
                prev_listen = h.listen_2002;
            }
            if (prev_clients != h.clients_2002) {
                if (h.clients_2002 > prev_clients && prev_clients >= 0)
                    tick_push("CLIENT CONNECTED");
                else if (prev_clients > 0)
                    tick_push("CLIENT DISCONNECTED");
                prev_clients = h.clients_2002;
            }
        }
        if (el < next_frame) { usleep(20000); continue; }
        next_frame = el + 66;              /* ~15 fps target */

        {
            DFBResult lr = prim->Lock(prim, DSLF_WRITE, &lockptr, &lockpitch);
            if (lr == DFB_OK) {
                fb = lockptr;
                pitch_px = lockpitch / 4;
                scene(&h, t, fps, (int)frames);
                fx_apply((int)frames);
        amiga_apply((int)frames, t);
                prim->Unlock(prim);
                locked = 1;
            }
            if (first_blit) {
                printf("HUD: primary Lock rc=%d pitch=%d\n", lr, lockpitch);
                first_blit = 0;
            }
        }
        fx_apply((int)frames);
        if (g_render_only) {
            printf("HUD: RENDER-ONLY: one frame drawn into the primary, no Flip\n");
            fflush(stdout);
            prim->Release(prim);
            dfb->Release(dfb);
            return 0;
        }
        prim->Flip(prim, NULL, DSFLIP_NONE);
        frames++;
        if (g_selftest && frames == 2) {
            printf("SELFTEST: PASS frames=%u panel=%dx%d scal=%d\n", frames, pw, ph, SCAL);
            printf("HUD: DONE\n");
            fflush(stdout);
            prim->Release(prim);
            dfb->Release(dfb);
            return 0;
        }
        if (secs > 0.5) fps = frames / secs;
    }

    {
        char l[160];
        snprintf(l, sizeof l,
                 "HUD: frames=%u secs=%.1f fps=%.1f state=%s module=%d listen=%d clients=%d pid=%d read=%lluM tmp=%u%%",
                 frames, (double)((now.tv_sec - t0.tv_sec) + (now.tv_nsec - t0.tv_nsec) / 1e9),
                 frames / ((double)((now.tv_sec - t0.tv_sec) + (now.tv_nsec - t0.tv_nsec) / 1e9)),
                 h.state, h.module_loaded, h.listen_2002, h.clients_2002, h.daemon_pid,
                 (unsigned long long)(h.read_bytes >> 20), h.tmp_pct);
        printf("%s\nHUD: DONE\n", l);
    }
    prim->Release(prim);
    dfb->Release(dfb);
    return 0;
}
#endif /* HUD_SIM */
