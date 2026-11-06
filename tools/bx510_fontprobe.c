/*
 * bx510_fontprobe.c — OFFLINE legibility check for the HUD's text.
 *
 * Renders sample HUD strings at panel scale into a PPM, using Sony's own
 * TiresiasScreenfont (carved out of /res/font.bin) and the same rasterizer the
 * HUD uses (stb_truetype). No device, no DirectFB: this is the "can you read it
 * from across the room" test we can run in CI.
 *
 * Usage: bx510_fontprobe <font.ttf> <out.ppm> [scale]
 *   scale 2 = HUD 1080p (logical px doubled)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define STB_TRUETYPE_IMPLEMENTATION
#include "third_party/stb_truetype.h"

#define W 1280
#define H 720

static unsigned char img[H][W][3];

static void put(int x, int y, const unsigned char *rgb)
{
    if (x < 0 || y < 0 || x >= W || y >= H) return;
    img[y][x][0] = rgb[0]; img[y][x][1] = rgb[1]; img[y][x][2] = rgb[2];
}

int main(int argc, char **argv)
{
    if (argc < 3) { fprintf(stderr, "usage: %s <font.ttf> <out.ppm> [scale]\n", argv[0]); return 2; }
    int scale = (argc > 3) ? atoi(argv[3]) : 2;
    FILE *f = fopen(argv[1], "rb");
    if (!f) { perror("font"); return 1; }
    fseek(f, 0, SEEK_END); long n = ftell(f); fseek(f, 0, SEEK_SET);
    unsigned char *ttf = malloc((size_t)n);
    if (!ttf || fread(ttf, 1, (size_t)n, f) != (size_t)n) { perror("font read"); return 1; }
    fclose(f);

    stbtt_fontinfo fi;
    if (!stbtt_InitFont(&fi, ttf, stbtt_GetFontOffsetForIndex(ttf, 0))) {
        fprintf(stderr, "stbtt_InitFont failed\n"); return 1;
    }
    /* background: the HUD's panel colour */
    memset(img, 0, sizeof img);
    for (int y = 0; y < H; y++)
        for (int x = 0; x < W; x++) {
            img[y][x][0] = 0x00; img[y][x][1] = 0x0f; img[y][x][2] = 0x0a;
        }

    const char *lines[] = {
        "CPSA LOADED",
        ":2002 LISTEN  CLIENTS 1",
        "SERVING  PID 4682",
        "THROUGHPUT 4.7 MB/s",
        "READ lsn=532104 n=128 got=128",
        "SEC 130  REQ 6  LSN 532104",
        "CLIENT CONNECTED 192.0.2.10",
        "MEM 155M  TMP 0%  CPSA 1",
        NULL
    };
    int px = (argc > 4) ? atoi(argv[4]) : 14;   /* HUD headline size (logical px) */
    float sc = stbtt_ScaleForPixelHeight(&fi, (float)px);
    int ascent, descent, linegap;
    stbtt_GetFontVMetrics(&fi, &ascent, &descent, &linegap);
    int lh = (int)((ascent - descent + linegap) * sc) + 6 * scale / 2;
    int ybase = 40;
    for (int i = 0; lines[i]; i++) {
        int x = 12;
        for (const char *p = lines[i]; *p; p++) {
            int adv, lsb, x0, y0, x1, y1;
            stbtt_GetCodepointHMetrics(&fi, *p, &adv, &lsb);
            stbtt_GetCodepointBitmapBox(&fi, *p, sc, sc, &x0, &y0, &x1, &y1);
            int gw = x1 - x0, gh = y1 - y0;
            unsigned char *bmp = stbtt_GetCodepointBitmap(&fi, sc, sc, *p, &gw, &gh, &x0, &y0);
            /* HUD colours: headline lines phosphor, secondary dim */
            unsigned char rgb[3] = { 0x22, 0xff, 0x66 };
            if (i >= 2) { rgb[0] = 0x0a; rgb[1] = 0x7a; rgb[2] = 0x30; }
            for (int yy = 0; yy < gh; yy++)
                for (int xx = 0; xx < gw; xx++) {
                    unsigned char a = bmp[yy * gw + xx];
                    if (!a) continue;
                    for (int sy = 0; sy < scale; sy++)
                        for (int sx = 0; sx < scale; sx++)
                            put((x + xx) * scale + sx, (ybase + yy) * scale + sy, rgb);
                }
            stbtt_FreeBitmap(bmp, NULL);
            x += (int)(adv * sc);          /* advance scaled to pixels */
        }
        ybase += lh;
    }

    FILE *o = fopen(argv[2], "wb");
    if (!o) { perror("out"); return 1; }
    fprintf(o, "P6\n%d %d\n255\n", W, H);
    fwrite(img, 1, sizeof img, o);
    fclose(o);
    printf("FONTPROBE: %s -> %s  (%dx%d, text %dpx logical, scale %d)\n",
           "TiresiasScreenfont", argv[2], W, H, px, scale);
    return 0;
}
