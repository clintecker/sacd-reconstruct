/*
 * bx510_fbmd5.c — read-only framebuffer content hash (no painting).
 *
 * The display-leg discriminator: cyberdraw proves a paint LANDED in the fb
 * buffer; the TV photo proves it was DISPLAYED. This tool answers the third
 * case — did something else write the buffer afterwards?
 *
 *   fbmd5 <fbdev>   ->  FBMD5: <dev> <WxH> bpp=<n> stride=<n> md5=<hex>
 *
 * Sequence in displaylaunch.sh: cyberdraw --static (paint + its own md5),
 * sleep, fbmd5 (same region). Same hash => the buffer kept our pixels (so a
 * black TV means the buffer is not the scan-out surface). Different hash =>
 * the appliance (or another plane writer) repainted us away.
 *
 * Build (gnuarm 2009q3, dynamic — static builds break dlopen in this guest):
 *   ~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -o fbmd5 bx510_fbmd5.c
 *   ~/gnuarm/bin/arm-none-linux-gnueabi-strip fbmd5
 */
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <linux/fb.h>

/* ---------------- md5 (compact public-domain style) ----------------- */
typedef struct { uint32_t s[4]; uint64_t len; uint8_t buf[64]; size_t n; } md5_t;
static void md5_init(md5_t *m)
{
    m->s[0] = 0x67452301; m->s[1] = 0xefcdab89;
    m->s[2] = 0x98badcfe; m->s[3] = 0x10325476;
    m->len = 0; m->n = 0;
}
static uint32_t rotl(uint32_t x, int c) { return (x << c) | (x >> (32 - c)); }
static void md5_block(md5_t *m, const uint8_t p[64])
{
    static const uint32_t K[64] = {
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
        0xf7537e82,0xbd3af235,0x2ad7d2bb,0xeb86d391 };
    static const int R[64] = {
        7,12,17,22,7,12,17,22,7,12,17,22,7,12,17,22,
        5,9,14,20,5,9,14,20,5,9,14,20,5,9,14,20,
        4,11,16,23,4,11,16,23,4,11,16,23,4,11,16,23,
        6,10,15,21,6,10,15,21,6,10,15,21,6,10,15,21 };
    uint32_t w[16], a = m->s[0], b = m->s[1], c = m->s[2], d = m->s[3];
    int i;
    for (i = 0; i < 16; i++)
        w[i] = (uint32_t)p[i*4] | ((uint32_t)p[i*4+1] << 8)
             | ((uint32_t)p[i*4+2] << 16) | ((uint32_t)p[i*4+3] << 24);
    for (i = 0; i < 64; i++) {
        uint32_t f, g, t;
        if (i < 16)      { f = (b & c) | (~b & d);     g = i; }
        else if (i < 32) { f = (d & b) | (~d & c);     g = (5*i + 1) & 15; }
        else if (i < 48) { f = b ^ c ^ d;              g = (3*i + 5) & 15; }
        else             { f = c ^ (b | ~d);           g = (7*i) & 15; }
        t = d; d = c; c = b;
        b = b + rotl(a + f + K[i] + w[g], R[i]);
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
    uint8_t tail[72];
    size_t i;
    memset(tail, 0, sizeof(tail));
    memcpy(tail, m->buf, m->n);
    tail[m->n] = 0x80;
    if (m->n >= 56) { md5_block(m, tail); memset(tail, 0, 64); }
    {
        uint64_t bits = m->len * 8;
        for (i = 0; i < 8; i++) tail[56 + i] = (uint8_t)(bits >> (8 * i));
    }
    md5_block(m, tail);
    for (i = 0; i < 16; i++)
        snprintf(out + i * 2, 3, "%02x", ((uint8_t *)m->s)[i]);
    out[32] = 0;
}

int main(int argc, char **argv)
{
    const char *fbdev = getenv("CYBER_FBDEV");
    struct fb_var_screeninfo vinfo;
    struct fb_fix_screeninfo finfo;
    md5_t md5;
    char hex[33];
    uint8_t *mem;
    size_t y;
    int fd;

    if (argc > 1) fbdev = argv[1];
    if (!fbdev) fbdev = "/dev/fb0";

    fd = open(fbdev, O_RDONLY);
    if (fd < 0) { fprintf(stderr, "fbmd5: open %s: %s\n", fbdev, strerror(errno)); return 1; }
    if (ioctl(fd, FBIOGET_VSCREENINFO, &vinfo) < 0 || ioctl(fd, FBIOGET_FSCREENINFO, &finfo) < 0) {
        fprintf(stderr, "fbmd5: screeninfo: %s\n", strerror(errno)); return 1;
    }
    mem = mmap(NULL, finfo.smem_len, PROT_READ, MAP_SHARED, fd, 0);
    if (mem == MAP_FAILED) { fprintf(stderr, "fbmd5: mmap: %s\n", strerror(errno)); return 1; }

    md5_init(&md5);
    for (y = 0; y < vinfo.yres; y++)
        md5_update(&md5, mem + y * finfo.line_length,
                   (size_t)vinfo.xres * (vinfo.bits_per_pixel / 8));
    md5_hex(&md5, hex);
    printf("FBMD5: %s %ux%u bpp=%u stride=%u md5=%s\n", fbdev,
           vinfo.xres, vinfo.yres, vinfo.bits_per_pixel,
           finfo.line_length, hex);
    munmap(mem, finfo.smem_len);
    close(fd);
    return 0;
}
