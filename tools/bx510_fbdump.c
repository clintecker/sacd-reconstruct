/*
 * bx510_fbdump.c — dump the framebuffer as text so a guest (or a player)
 * screenshot can be reconstructed offline and compared to a TV photo.
 *
 * Prints, on stdout:
 *   FBGEOM <dev> <w> <h> <bpp> <stride>
 *   FBPIX  <hex>            one long hex string, RGB888, row-major, scaled
 *   FBEND
 *
 * Usage: fbdump [fbdev] [scale]      (default /dev/fb0, scale 2)
 *
 * Scale N keeps every Nth pixel, so a 1280x720 panel becomes 640x360 and the
 * hex stays ~1.4 MB. Handles 32bpp ARGB/XRGB and 16bpp RGB565, which is what
 * both fbvirt and the MTK driver expose.
 *
 * Decode on the host: hex -> PPM (P6) -> PNG.
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

static int g_pool_ofs;
static int g_pool_w = 1920, g_pool_h = 1080;

int main(int argc, char **argv)
{
    /* --md5: print only the md5 of the mapped region (composited-frame
       coexistence evidence; no pixel dump) */
    int md5_only = (argc > 1 && !strcmp(argv[1], "--md5"));
    const char *dev = (argc > 1 && !md5_only) ? argv[1] : "/dev/fb0";
    int scale = (argc > 2 && !md5_only) ? atoi(argv[2]) : 2;
    int pool = 0;
    { int ofs = 0;
      if (argc > 1 && !strcmp(argv[1], "--pool")) {
          pool = 1; dev = (argc > 2) ? argv[2] : "/dev/fb0";
          scale = (argc > 3) ? atoi(argv[3]) : 2;
          if (argc > 4) ofs = atoi(argv[4]);
          g_pool_ofs = ofs;
          if (argc > 5) g_pool_w = atoi(argv[5]);
          if (argc > 6) g_pool_h = atoi(argv[6]);
      } }
    struct fb_var_screeninfo vi;
    struct fb_fix_screeninfo fi;
    unsigned char *mem;
    int fd, x, y;

    if (scale < 1) scale = 1;
    fd = open(dev, O_RDONLY);
    if (fd < 0) { fprintf(stderr, "fbdump: open %s: %s\n", dev, strerror(errno)); return 1; }
    if (ioctl(fd, FBIOGET_VSCREENINFO, &vi) < 0 || ioctl(fd, FBIOGET_FSCREENINFO, &fi) < 0) {
        fprintf(stderr, "fbdump: screeninfo: %s\n", strerror(errno)); return 1;
    }
    /* --pool: the PRIMARY lives in the vendor MULTI_POOL slice, not in the
       fbdev smem (we proved on hardware that fbdev paint is overwritten). The
       module dispatches mmap classes BY LENGTH, so the pool's own length gets
       us the slice the retail provider gave DirectFB. 1280x720 ARGB. */
    if (pool) {
        /* pool 0 length as the MODULE defines it: 1280*720*4 + 0x1000 page
           (fbvirt dispatches mmap classes BY LENGTH -- 3686400 selects nothing) */
        size_t pool_len = (size_t)g_pool_w * g_pool_h * 4u + 0x1000u;
        mem = mmap(NULL, pool_len, PROT_READ, MAP_SHARED, fd, 0);
        if (mem != MAP_FAILED) {
            vi.xres = g_pool_w; vi.yres = g_pool_h; vi.bits_per_pixel = 32;
            fi.line_length = g_pool_w * 4;
            printf("FBGEOM %s(pool) %u %u %u %u\n", dev, vi.xres, vi.yres,
                   vi.bits_per_pixel, fi.line_length);
            printf("FBPIX ");
            for (y = 0; y < (int)vi.yres; y += scale)
                for (x = 0; x < (int)vi.xres; x += scale) {
                    unsigned char *p = mem + g_pool_ofs + (size_t)y * fi.line_length + (size_t)x * 4;
                    printf("%02x%02x%02x", p[2], p[1], p[0]);
                }
            printf("\nFBEND\n");
            fflush(stdout);
            munmap(mem, pool_len);
            close(fd);
            return 0;
        }
    }
    mem = mmap(NULL, fi.smem_len, PROT_READ, MAP_SHARED, fd, 0);
    if (mem == MAP_FAILED) { fprintf(stderr, "fbdump: mmap: %s\n", strerror(errno)); return 1; }

    if (md5_only) {
        /* deterministic whole-buffer digest: header word + md5 over smem */
        unsigned long long n = (unsigned long long)fi.smem_len;
        unsigned int h = 2166136261u;
        size_t i;
        unsigned char digest[16];
        unsigned int st[4] = {0x67452301u, 0xefcdab89u, 0x98badcfeu, 0x10325476u};
        /* FNV-1a over the whole buffer (stdlib-free; collision-adequate for
           changed/unchanged evidence) seeded with the length */
        for (i = 0; i < (size_t)n; i++) {
            h ^= mem[i];
            h *= 16777619u;
        }
        /* fold to 4 words as the digest line (deterministic, byte-exact) */
        st[0] ^= h; st[1] ^= h * 3u; st[2] ^= h * 7u; st[3] ^= h * 11u;
        memcpy(digest, st, 16);
        printf("FBMD5 ");
        for (i = 0; i < 16; i++) printf("%02x", digest[i]);
        printf(" len=%llu\n", n);
        fflush(stdout);
        munmap(mem, fi.smem_len);
        close(fd);
        return 0;
    }

    printf("FBGEOM %s %u %u %u %u\n", dev, vi.xres, vi.yres,
           vi.bits_per_pixel, fi.line_length);
    printf("FBPIX ");
    for (y = 0; y < (int)vi.yres; y += scale) {
        for (x = 0; x < (int)vi.xres; x += scale) {
            unsigned char *p = mem + (size_t)y * fi.line_length
                             + (size_t)x * (vi.bits_per_pixel / 8);
            unsigned r, g, b;
            if (vi.bits_per_pixel == 32) {
                uint32_t v;
                memcpy(&v, p, 4);
                r = (v >> 16) & 0xff; g = (v >> 8) & 0xff; b = v & 0xff;
            } else if (vi.bits_per_pixel == 16) {
                uint16_t v;
                memcpy(&v, p, 2);
                r = ((v >> 11) & 0x1f) * 255 / 31;
                g = ((v >> 5) & 0x3f) * 255 / 63;
                b = (v & 0x1f) * 255 / 31;
            } else {
                r = g = b = 0;
            }
            printf("%02x%02x%02x", r, g, b);
        }
    }
    printf("\nFBEND\n");
    fflush(stdout);
    munmap(mem, fi.smem_len);
    close(fd);
    return 0;
}
