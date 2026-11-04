/*
 * bx510_cyberdraw.c — the vibey drawing test for the BX510 display paths.
 *
 * Draws an old-school hacker/cyberpunk console scene, 100% procedural:
 *   - phosphor-green blocky banner (5x7 bitmap font, hand-rolled)
 *   - typed terminal boot log, ACCESS GRANTED with blinking cursor
 *   - rotating wireframe cube (right side)
 *   - scrolling perspective grid floor
 *   - CRT scanlines + moving green sweep (anim mode)
 *
 * Why a recognizable pattern (not plain bars): a TV photo of THIS cannot
 * be confused with any appliance UI screen — the visual is
 * self-authenticating hardware evidence. Static mode is deterministic
 * per resolution (md5 over the final frame) for gate purposes.
 *
 * Modes:
 *   cyberdraw --static        one deterministic frame + ASCII + md5
 *   cyberdraw --anim [secs]    animated scene (default 300s), static frame
 *                             left on screen at the end
 *
 * Resolution-adaptive: reads FBIOGET_VSCREENINFO (xres/yres/bpp/stride);
 * handles 32bpp and 16bpp RGB565. Works against fbvirt in QEMU and the
 * real MTK driver on hardware (fb device default /dev/fb0, override
 * with the CYBER_FBDEV env or second arg).
 *
 * Build: gnuarm toolchain, dynamic, no deps.
 */
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>
#include <linux/fb.h>
#include <math.h>

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
    if (c >= 'a' && c <= 'z')
        c -= 32;
    for (i = 0; i < NGlyphs; i++)
        if (FONT[i].ch == c)
            return &FONT[i];
    return &FONT[NGlyphs - 1]; /* unknown -> '_' (won't happen) */
}

/* ---------------- md5 (compact public-domain style) ----------------- */
typedef struct { uint32_t s[4]; uint64_t len; uint8_t buf[64]; size_t n; } md5_t;
static void md5_init(md5_t *m)
{
    m->s[0] = 0x67452301; m->s[1] = 0xefcdab89; m->s[2] = 0x98badcfe;
    m->s[3] = 0x10325476; m->len = 0; m->n = 0;
}
#define ROL(x, c) (((x) << (c)) | ((x) >> (32 - (c))))
static void md5_block(md5_t *m, const uint8_t p[64])
{
    static const uint32_t K[] = {
        0xd76aa478,0xe8c7b756,0x242070db,0xc1bdceee,0xf57c0faf,0x4787c62a,
        0xa8304613,0xfd469501,0x698098d8,0x8b44f7af,0xffff5bb1,0x895cd7be,
        0x6b901122,0xfd987193,0xa679438e,0x49b40821,0xf61e2562,0xc040b340,
        0x265e5a51,0xe9b6c7aa,0xd62f105d,0x02441453,0xd8a1e681,0xe7d3fbc8,
        0x21e1cde6,0xc33707d6,0xf4d50d87,0x455a14ed,0xa9e3e905,0xfcefa3f8,
        0x676f02d9,0x8d2a4c8a,0xfffa3942,0x8771f681,0x6d9d6122,0xfde5380c,
        0xa4beea44,0x4bdecfa9,0xf6bb4b60,0xbebfbc70,0x289b7ec6,0xeaa127fa,
        0xd4ef3085,0x04881d05,0xd9d4d039,0xe6db99e5,0x1fa27cf8,0xc4ac5665,
        0xf4292244,0x432aff97,0xab9423a7,0xfc93a039,0x655b59c3,0x8f0ccc92,
        0xffeff47d,0x85845dd1,0x6fa87e4f,0xfe2ce6e0,0xa3014314,0x4e0811a1,
        0xf7537e82,0xbd3af235,0x2ad7d2bb,0xeb86d391};
    static const uint8_t S[] = {7,12,17,22,7,12,17,22,7,12,17,22,7,12,17,22,
                                5,9,14,20,5,9,14,20,5,9,14,20,5,9,14,20,
                                4,11,16,23,4,11,16,23,4,11,16,23,4,11,16,23,
                                6,10,15,21,6,10,15,21,6,10,15,21,6,10,15,21};
    uint32_t w[16], a = m->s[0], b = m->s[1], c = m->s[2], d = m->s[3];
    int i;
    for (i = 0; i < 16; i++)
        w[i] = p[i*4] | (p[i*4+1] << 8) | (p[i*4+2] << 16) | ((uint32_t)p[i*4+3] << 24);
    for (i = 0; i < 64; i++) {
        uint32_t f, t;
        int g;
        if (i < 16)      { f = (b & c) | (~b & d);      g = i; }
        else if (i < 32) { f = (d & b) | (~d & c);      g = (5*i + 1) % 16; }
        else if (i < 48) { f = b ^ c ^ d;              g = (3*i + 5) % 16; }
        else             { f = c ^ (b | ~d);           g = (7*i) % 16; }
        t = d; d = c; c = b;
        b = b + ROL(a + f + K[i] + w[g], S[i]);
        a = t;
    }
    m->s[0] += a; m->s[1] += b; m->s[2] += c; m->s[3] += d;
}
static void md5_update(md5_t *m, const void *data, size_t len)
{
    const uint8_t *p = data;
    m->len += len;
    while (len) {
        size_t take = 64 - m->n;
        if (take > len) take = len;
        memcpy(m->buf + m->n, p, take);
        m->n += take; p += take; len -= take;
        if (m->n == 64) { md5_block(m, m->buf); m->n = 0; }
    }
}
static void md5_hex(md5_t *m, char out[33])
{
    static const char hexd[] = "0123456789abcdef";
    uint8_t tail[72];
    uint64_t bits = m->len * 8;
    int i;
    memset(tail, 0, sizeof tail);
    tail[m->n] = 0x80;
    if (m->n >= 56) { md5_block(m, tail); memset(tail, 0, 8); }
    else memcpy(tail, m->buf, m->n);
    for (i = 0; i < 8; i++) tail[56 + i] = (uint8_t)(bits >> (8*i));
    md5_block(m, tail);
    for (i = 0; i < 4; i++) {
        int j;
        uint32_t v = m->s[i];
        for (j = 0; j < 4; j++) {
            out[i*8 + j*2]     = hexd[(v >> (4 + j*8)) & 0xf];
            out[i*8 + j*2 + 1] = hexd[(v >> (j*8)) & 0xf];
        }
    }
    out[32] = 0;
}

/* ---------------- framebuffer abstraction ----------------------------- */
static uint8_t *fbmem;
static struct fb_var_screeninfo vinfo;
static struct fb_fix_screeninfo finfo;
static int fbfd = -1;

static inline void put_pixel(int x, int y, uint8_t r, uint8_t g, uint8_t b)
{
    if (x < 0 || y < 0 || x >= (int)vinfo.xres || y >= (int)vinfo.yres)
        return;
    uint8_t *p = fbmem + (size_t)y * finfo.line_length +
                 (size_t)x * (vinfo.bits_per_pixel / 8);
    if (vinfo.bits_per_pixel == 32) {
        p[0] = b; p[1] = g; p[2] = r; p[3] = 0xff;
    } else { /* 16bpp RGB565 */
        uint16_t v = ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3);
        memcpy(p, &v, 2);
    }
}
static inline uint32_t get_pixel(int x, int y)
{
    uint8_t *p = fbmem + (size_t)y * finfo.line_length +
                 (size_t)x * (vinfo.bits_per_pixel / 8);
    if (vinfo.bits_per_pixel == 32)
        return (p[2] << 16) | (p[1] << 8) | p[0];
    uint16_t v;
    memcpy(&v, p, 2);
    return (((v >> 11) & 0x1f) << 16 | ((v >> 5) & 0x3f) << 8 | (v & 0x1f));
}

static void fill_rect(int x, int y, int w, int h, uint8_t r, uint8_t g, uint8_t b)
{
    int i, j;
    for (j = y; j < y + h; j++)
        for (i = x; i < x + w; i++)
            put_pixel(i, j, r, g, b);
}
static void draw_line(int x0, int y0, int x1, int y1,
                      uint8_t r, uint8_t g, uint8_t b)
{
    int dx = abs(x1 - x0), sx = x0 < x1 ? 1 : -1;
    int dy = -abs(y1 - y0), sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;
    for (;;) {
        put_pixel(x0, y0, r, g, b);
        if (x0 == x1 && y0 == y1) break;
        int e2 = 2 * err;
        if (e2 >= dy) { err += dy; x0 += sx; }
        if (e2 <= dx) { err += dx; y0 += sy; }
    }
}
/* per-channel multiply — a packed-RGB multiply would carry between
 * channels (0x000102 * 7/10 != per-channel 0.7) */
static void scale_mul(uint32_t *rgb, uint32_t num, uint32_t den)
{
    uint32_t r = (*rgb >> 16) & 0xff, g = (*rgb >> 8) & 0xff, b = *rgb & 0xff;
    *rgb = ((r * num / den) << 16) | ((g * num / den) << 8) | (b * num / den);
}

/* draw one 5x7 glyph at scale s; color rgb 0xRRGGBB */
static void draw_char(char c, int x, int y, int s, uint32_t rgb)
{
    const glyph_t *g = find_glyph(c);
    int r, col;
    uint8_t R = rgb >> 16, G = (rgb >> 8) & 0xff, B = rgb & 0xff;
    for (r = 0; r < 7; r++)
        for (col = 0; col < 5; col++)
            if (g->rows[r] & (0x10 >> col)) {
                int i, j;
                for (j = 0; j < s; j++)
                    for (i = 0; i < s; i++)
                        put_pixel(x + col * s + i, y + r * s + j, R, G, B);
            }
}
static void draw_text(const char *s, int x, int y, int sc, uint32_t rgb)
{
    int cx = x;
    while (*s) {
        draw_char(*s, cx, y, sc, rgb);
        cx += 6 * sc;
        s++;
    }
}
static int text_width(int n, int sc) { return n * 6 * sc; }
/* cheap CRT glow: dim copies offset by 1px, then bright core */
static void draw_text_glow(const char *s, int x, int y, int sc, uint32_t rgb)
{
    uint32_t dim = rgb;
    scale_mul(&dim, 1, 4);
    draw_text(s, x - 1, y, sc, dim);
    draw_text(s, x + 1, y, sc, dim);
    draw_text(s, x, y - 1, sc, dim);
    draw_text(s, x, y + 1, sc, dim);
    draw_text(s, x, y, sc, rgb);
}

/* ---------------- the scene ------------------------------------------- */
typedef struct { float x, y, z; } v3;

static void draw_cube(double ang_y, double ang_x, int cx, int cy, int size,
                      uint8_t r, uint8_t g, uint8_t b)
{
    static const v3 V[8] = {{-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1},
                            {-1,-1, 1},{1,-1, 1},{1,1, 1},{-1,1, 1}};
    static const int E[12][2] = {{0,1},{1,2},{2,3},{3,0},{4,5},{5,6},{6,7},
                                 {7,4},{0,4},{1,5},{2,6},{3,7}};
    int i;
    float sy = sin(ang_y), cyv = cos(ang_y), sx = sin(ang_x), cxv = cos(ang_x);
    int px[8], py[8];
    for (i = 0; i < 8; i++) {
        float x = V[i].x, y = V[i].y, z = V[i].z;
        float x1 = x * cyv + z * sy;
        float z1 = -x * sy + z * cyv;
        float y1 = y * cxv - z1 * sx;
        float z2 = y * sx + z1 * cxv;
        float f = 3.0f / (3.0f + z2);
        px[i] = cx + (int)(x1 * f * size);
        py[i] = cy + (int)(y1 * f * size);
    }
    /* magenta glow pass (thick), then bright 2px core */
    for (i = 0; i < 12; i++) {
        int a2 = E[i][0], b2 = E[i][1];
        draw_line(px[a2] - 1, py[a2] - 1, px[b2] - 1, py[b2] - 1,
                  r / 2, g / 2, b + 40 > 255 ? 255 : b + 40);
        draw_line(px[a2] + 1, py[a2] + 1, px[b2] + 1, py[b2] + 1,
                  r / 2, g / 2, b + 40 > 255 ? 255 : b + 40);
    }
    for (i = 0; i < 12; i++) {
        int a2 = E[i][0], b2 = E[i][1];
        draw_line(px[a2], py[a2], px[b2], py[b2], r, g, b);
        draw_line(px[a2], py[a2] + 1, px[b2], py[b2] + 1, r, g, b);
    }
}

static void draw_grid(int W, int H, double scroll, double horizon_frac)
{
    int hy = (int)(H * horizon_frac);
    int cx = W / 2;
    int i;
    /* fan of converging lines (2px for presence) */
    for (i = -12; i <= 12; i++) {
        int bx = cx + i * (W / 12);
        uint32_t rgb = (i & 1) ? 0x00909090 : 0x00506060;
        draw_line(cx, hy, bx, H + 20,
                  (rgb >> 16) & 0xff, (rgb >> 8) & 0xff, rgb & 0xff);
        draw_line(cx + 1, hy, bx + 1, H + 20,
                  (rgb >> 16) & 0xff, (rgb >> 8) & 0xff, rgb & 0xff);
    }
    /* horizontal rings scrolling toward viewer (2px, bright with depth) */
    {
        double k = 1.08;
        double p = 1.0 + scroll;
        int n;
        for (n = 0; n < 14; n++) {
            int y = hy + (int)((H - hy) * (1.0 - 1.0 / p));
            if (y > hy && y < H) {
                uint8_t fade = (uint8_t)(60 + (y - hy) * 195 / (H - hy));
                draw_line(0, y, W, y, 0x00, fade, fade);
                draw_line(0, y + 1, W, y + 1, 0x00, fade, fade);
            }
            p *= k;
        }
    }
    /* horizon line: bright */
    draw_line(0, hy, W, hy, 0x00, 0xd0, 0xd0);
    draw_line(0, hy + 1, W, hy + 1, 0x00, 0x60, 0x60);
}

static void draw_scanlines(int W, int H)
{
    int x, y;
    for (y = 0; y < H; y += 2)
        for (x = 0; x < W; x++) {
            uint32_t c = get_pixel(x, y);
            scale_mul(&c, 7, 10);
            put_pixel(x, y, (c >> 16) & 0xff, (c >> 8) & 0xff, c & 0xff);
        }
}

static void draw_corners(int W, int H)
{
    int m = 12, l = 30, i;
    for (i = 0; i < l; i++) {
        put_pixel(m + i, m, 0x00, 0xff, 0x00);
        put_pixel(m, m + i, 0x00, 0xff, 0x00);
        put_pixel(W - 1 - m - i, H - 1 - m, 0x00, 0xff, 0x00);
        put_pixel(W - 1 - m, H - 1 - m - i, 0x00, 0xff, 0x00);
        put_pixel(W - 1 - m - i, m, 0x00, 0xff, 0x00);
        put_pixel(W - 1 - m, m + i, 0x00, 0xff, 0x00);
        put_pixel(m + i, H - 1 - m, 0x00, 0xff, 0x00);
        put_pixel(m, H - 1 - m - i, 0x00, 0xff, 0x00);
    }
}

static void paint_frame(int W, int H, double t, int typed_lines, int anim)
{
    int y, x, sc_banner, tx, ty, i;
    const char *boot[] = {
        "> MOUNT /DEV/SR0 ......... OK",
        "> AUTH 5307 .............. OK",
        "> TOC 2822400 SPT ......... OK",
        "> SESSION 553077 BYTES .... IDENTICAL",
    };
    char footer[80];

    /* background: deep cyber-navy vertical gradient */
    for (y = 0; y < H; y++) {
        uint8_t r = 6 + (y * 14 / H), g = 0, b = 20 + (y * 40 / H);
        for (x = 0; x < W; x++)
            put_pixel(x, y, r, g, b);
    }
    /* horizon grid over the bottom third */
    draw_grid(W, H, anim ? fmod(t / 4.0, 1.0) * 1.0 : 0.0, 0.70);

    /* banner */
    sc_banner = W / 120;
    if (sc_banner < 2) sc_banner = 2;
    {
        const char *title = "SACD-EXTRACT 160";
        int w = text_width(strlen(title), sc_banner);
        draw_text_glow(title, (W - w) / 2, H * 6 / 100, sc_banner, 0x00ff44);
    }
    {
        const char *sub = "BX510 :: MT85XX CONTRACT TEST";
        int w = text_width(strlen(sub), 2);
        draw_text(sub, (W - w) / 2, H * 6 / 100 + 9 * sc_banner + 6, 2, 0xff00ff);
    }
    /* thin rule under the banner */
    draw_line(W / 10, H * 6 / 100 + 9 * sc_banner + 24,
              W - W / 10, H * 6 / 100 + 9 * sc_banner + 24, 0x00, 0x80, 0x40);

    /* typed boot log, left column */
    tx = W * 6 / 100;
    ty = H * 26 / 100;
    for (i = 0; i < (int)(sizeof boot / sizeof boot[0]); i++) {
        if (i < typed_lines)
            draw_text_glow(boot[i], tx, ty + i * (H * 55 / 1000), 2, 0x00ff66);
        else
            break;
    }
    /* ACCESS GRANTED + blinking cursor */
    if (typed_lines >= 4) {
        const char *gr = "ACCESS GRANTED";
        draw_text_glow(gr, tx, ty + 4 * (H * 55 / 1000) + H * 2 / 100, 3,
                       anim && ((int)(t * 2) & 1) ? 0xccffcc : 0x33ff55);
        if (!anim || ((int)(t * 3) & 1)) {
            int cx0 = tx + text_width(strlen(gr), 3) + 8;
            int cy0 = ty + 4 * (H * 55 / 1000) + H * 2 / 100;
            fill_rect(cx0, cy0, 10, 21, 0x00, 0xff, 0x66);
        }
    }

    /* rotating wireframe cube, right side */
    draw_cube(anim ? t * 0.7 : 0.42, anim ? t * 0.23 : 0.30,
              W * 74 / 100, H * 36 / 100, W * 16 / 100, 0x00, 0xff, 0xff);

    draw_scanlines(W, H);
    draw_corners(W, H);

    /* footer: backing bar then bright text (drawn after scanlines) */
    {
        int fy = H * 94 / 100;
        snprintf(footer, sizeof footer, "PATTERN: CYBERPUNK-V1 MODE:%s RES:%dx%d",
                 anim ? "ANIM" : "STATIC", W, H);
        fill_rect(0, fy, W, 14 + 2, 0x00, 0x10, 0x08);
        draw_text(footer, W * 6 / 100, fy + 3, 2, 0x00ff66);
    }

    /* animated CRT sweep: bright green scan bar */
    if (anim) {
        int sy0 = (int)(fmod(t * H / 90.0, H * 1.2) - H * 0.1);
        for (y = sy0; y < sy0 + 3 && y < H; y++)
            if (y >= 0)
                for (x = 0; x < W; x++) {
                    uint32_t c = get_pixel(x, y);
                    uint32_t g2 = ((c >> 8) & 0xff) * 3 / 2 + 60;
                    put_pixel(x, y, (c >> 16) & 0xff,
                             g2 > 255 ? 255 : g2, c & 0xff);
                }
    }
}

/* ---------------- ascii evidence dump -------------------------------- */
static void ascii_dump(void)
{
    /* downsample 60x18 by MAX luminance — an average over a 12x32 cell
     * erases 1-2px lines (cube edges, grid), which are most of the
     * pattern; max keeps them visible as evidence */
    static const char ramp[] = " .:-=+*#%@";
    int W = vinfo.xres, H = vinfo.yres;
    int cols = 60, rows = 18;
    int cx, cy;
    printf("CYBERDRAW: ASCII downsample %dx%d (max-lum):\n", cols, rows);
    for (cy = 0; cy < rows; cy++) {
        printf("  ");
        for (cx = 0; cx < cols; cx++) {
            unsigned long best = 0;
            int x, y;
            for (y = cy * H / rows; y < (cy + 1) * H / rows; y++)
                for (x = cx * W / cols; x < (cx + 1) * W / cols; x++) {
                    uint32_t p = get_pixel(x, y);
                    unsigned long lum = ((p >> 16) & 0xff) * 30
                                       + ((p >> 8) & 0xff) * 59
                                       + (p & 0xff) * 11;
                    if (lum > best) best = lum;
                }
            best /= 100;
            putchar(ramp[best * 9 / 255]);
        }
        putchar('\n');
    }
}

int main(int argc, char **argv)
{
    const char *fbdev = getenv("CYBER_FBDEV");
    int anim = 0;
    long anim_secs = 300;
    md5_t md5;
    char hex[33];
    size_t y;

    if (argc > 2 && !fbdev) fbdev = argv[2];
    if (!fbdev) fbdev = "/dev/fb0";
    if (argc > 1 && !strcmp(argv[1], "--anim")) {
        anim = 1;
        if (argc > 2) { anim_secs = strtol(argv[2], NULL, 10);
            if (anim_secs > 100) anim_secs = 100; }
        else anim_secs = 300;
    } else if (argc > 1 && strcmp(argv[1], "--static")) {
        fprintf(stderr, "usage: cyberdraw [--static | --anim [secs]] [fbdev]\n");
        return 2;
    }

    fbfd = open(fbdev, O_RDWR);
    if (fbfd < 0) { fprintf(stderr, "cyberdraw: open %s: %s\n", fbdev, strerror(errno)); return 1; }
    if (ioctl(fbfd, FBIOGET_VSCREENINFO, &vinfo) < 0 ||
        ioctl(fbfd, FBIOGET_FSCREENINFO, &finfo) < 0) {
        fprintf(stderr, "cyberdraw: screeninfo: %s\n", strerror(errno));
        return 1;
    }
    if (vinfo.bits_per_pixel != 32 && vinfo.bits_per_pixel != 16) {
        fprintf(stderr, "cyberdraw: unsupported bpp %u\n", vinfo.bits_per_pixel);
        return 1;
    }
    fbmem = mmap(NULL, finfo.smem_len, PROT_READ | PROT_WRITE, MAP_SHARED, fbfd, 0);
    if (fbmem == MAP_FAILED) { fprintf(stderr, "cyberdraw: mmap: %s\n", strerror(errno)); return 1; }
    printf("CYBERDRAW: %s %ux%u bpp=%u stride=%u\n", fbdev,
           vinfo.xres, vinfo.yres, vinfo.bits_per_pixel, finfo.line_length);

    if (anim) {
        struct timespec t0, now;
        long elapsed_ms;
        clock_gettime(CLOCK_MONOTONIC, &t0);
        for (;;) {
            double t;
            clock_gettime(CLOCK_MONOTONIC, &now);
            elapsed_ms = (now.tv_sec - t0.tv_sec) * 1000 +
                         (now.tv_nsec - t0.tv_nsec) / 1000000;
            if (elapsed_ms >= anim_secs * 1000)
                break;
            t = elapsed_ms / 1000.0;
            paint_frame(vinfo.xres, vinfo.yres, t, (int)fmin(2 + t / 1.5, 4), 1);
            usleep(66666); /* 15 fps — kind to a 2013 ARM926 */
        }
    }
    /* final deterministic frame (also the --static output) */
    paint_frame(vinfo.xres, vinfo.yres, 0.0, 4, 0);

    md5_init(&md5);
    for (y = 0; y < vinfo.yres; y++)
        md5_update(&md5, fbmem + (size_t)y * finfo.line_length,
                   (size_t)vinfo.xres * (vinfo.bits_per_pixel / 8));
    md5_hex(&md5, hex);
    ascii_dump();
    printf("CYBERDRAW: full-frame md5: %s\n", hex);
    printf("CYBERDRAW: DONE\n");
    munmap(fbmem, finfo.smem_len);
    close(fbfd);
    return 0;
}
