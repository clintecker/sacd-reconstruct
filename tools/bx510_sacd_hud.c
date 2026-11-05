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
#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <directfb.h>

#define CW 640
#define CH 360

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

/* ---------------- software canvas ----------------------------------- */
static unsigned int *fb;
static int pitch_px;

static void px(int x, int y, unsigned int c)
{
    if (x < 0 || y < 0 || x >= CW || y >= CH) return;
    fb[y * pitch_px + x] = c;
}
static void rect(int x, int y, int w, int h, unsigned int c)
{
    int i, j;
    if (x < 0) { w += x; x = 0; }
    if (y < 0) { h += y; y = 0; }
    if (x + w > CW) w = CW - x;
    if (y + h > CH) h = CH - y;
    for (j = 0; j < h; j++)
        for (i = 0; i < w; i++)
            fb[(y + j) * pitch_px + x + i] = c;
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
static int text2(const char *s, int x, int y, unsigned int col)
{
    int cx = x;
    for (; *s; s++) { glyph2(*s, cx, y, col); cx += 12; }
    return cx;
}
static int text2r(const char *s, int xr, int y, unsigned int col)
{
    return text2(s, xr - (int)strlen(s) * 12, y, col);
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
    int cx = x;
    for (; *s; s++) { glyph1(*s, cx, y, col); cx += 6; }
    return cx;
}
static int text1r(const char *s, int xr, int y, unsigned int col)
{
    return text1(s, xr - (int)strlen(s) * 6, y, col);
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

#define TICK_MAX 8
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

static void scene(const hud_t *h, double t, double fps, int frame)
{
    char l[128], up[16];
    int i;

    rect(0, 0, CW, CH, C_BG);

    {   /* perspective grid, scrolling */
        int gy = 210 + (int)(fmod(t * 8.0, 8.0));
        for (; gy < CH; gy += 8) {
            int half = (gy - 210) * 2 + 30;
            rect(320 - half, gy, half * 2, 1, C_PHOSD);
        }
        for (i = -8; i <= 8; i++)
            line(320 + i * 20, 210, 320 + i * 90, CH, C_GRID);
    }
    {   /* CRT sweep */
        int sy = (int)(fmod(t * 60.0, CH));
        rect(0, sy, CW, 2, 0x0b3a1c);
    }

    /* ---- status bar ---- */
    rect(0, 0, CW, 18, C_PANEL);
    text1("SACD//RIPPER", 4, 2, C_PHOS);
    snprintf(up, sizeof up, "%02lu:%02lu:%02lu", h->uptime_s / 3600, (h->uptime_s / 60) % 60, h->uptime_s % 60);
    text1(up, 84, 2, C_PHOSD);
    snprintf(l, sizeof l, "%.0fFPS", fps);
    text1r(l, CW - 86, 2, C_PHOSD);
    text1r(h->clients_2002 ? "LIVE" : (h->listen_2002 ? "ARMED" : "IDLE"), CW - 4, 2,
           h->clients_2002 ? C_PHOS : C_AMBER);
    text1("HUD H2   CPSA//MT85   MTK CLI AUTOSCRIPT   software 640x360 -> StretchBlit",
          4, 10, C_PHOSD);

    /* ---- panels ---- */
    rect(4, 22, 400, 316, C_PANEL); box(4, 22, 400, 316, C_FRAME);
    rect(408, 22, 228, 316, C_PANEL); box(408, 22, 228, 316, C_FRAME);

    /* ---- left: live state (2x) + ticker (1x) ---- */
    text1("EVENT STREAM", 8, 25, C_CYAN);
    {
        int y = 40;
        snprintf(l, sizeof l, "CPSA %s", h->module_loaded ? "LOADED" : "DOWN");
        text2(l, 8, y, h->module_loaded ? C_PHOS : C_RED); y += 18;
        snprintf(l, sizeof l, "%s  CLIENTS %d", h->listen_2002 ? ":2002 LISTEN" : ":2002 CLOSED", h->clients_2002);
        text2(l, 8, y, h->listen_2002 ? C_PHOS : C_AMBER); y += 18;
        snprintf(l, sizeof l, "%s  PID %d", h->state, h->daemon_pid);
        text2(l, 8, y, C_WHITE); y += 22;
        {
            int n = tick_n < TICK_MAX ? tick_n : TICK_MAX;
            for (i = 0; i < n; i++) {
                int idx = (tick_n - n + i) % TICK_MAX;
                if (idx < 0) continue;
                snprintf(l, sizeof l, "%s", tick[idx]);
                if (strlen(l) > 46) l[46] = 0;
                {
                    char c2[80];
                    if (tick_rep[idx] > 1)
                        snprintf(c2, sizeof c2, "%s x%u", l, tick_rep[idx]);
                    else
                        snprintf(c2, sizeof c2, "%s", l);
                    text1(c2, 8, y, (i == n - 1) ? C_WHITE : C_PHOSD);
                }
                y += 10;
            }
        }
        if (h->note[0]) text1(h->note, 8, 306, C_RED);
        if ((frame / 6) % 2) rect(8, 316, 6, 8, C_PHOS);
    }

    /* ---- right: telemetry ---- */
    text1("TELEMETRY", 412, 25, C_CYAN);
    snprintf(l, sizeof l, "%.1f MB/s", ev_mbps ? (double)ev_mbps : h->mbps);
    text2(l, 412, 38, C_WHITE);
    for (i = 0; i < 39; i++) spark[i] = spark[i + 1];
    { double m = (double)(ev_mbps ? ev_mbps : h->mbps) * 2.0; spark[39] = (unsigned)(m > 80 ? 80 : m); }
    for (i = 0; i < 38; i++)
        rect(412 + i * 5, 92 - (int)spark[i] / 2, 3, (int)spark[i] / 2, (i > 28) ? C_AMBER : C_PHOS);
    {
        unsigned long long total = DISC_SECTORS * SECTOR_BYTES;
        int cells = 36, lit = total ? (int)((double)ev_last_lsn * SECTOR_BYTES / (double)total * cells) : 0;
        int cw = 216 / cells;
        if (lit > cells) lit = cells;
        box(412, 96, 220, 14, C_FRAME);
        for (i = 0; i < cells; i++) {
            unsigned int c = C_PHOSD;
            if (i < lit) c = C_PHOS;
            if (i == lit) c = C_WHITE;
            rect(415 + i * cw, 99, cw - 1, 8, c);
        }
    }
    snprintf(l, sizeof l, "MEM %luM  TMP %u%%", h->memfree_kb / 1024, h->tmp_pct);
    text1(l, 412, 115, h->tmp_pct > 90 ? C_RED : C_PHOSD);
    snprintf(l, sizeof l, "REQ %llu  SEC %llu  LSN %llu", ev_requests, ev_sectors, ev_last_lsn);
    text1(l, 412, 125, C_PHOSD);

    box(412, 140, 220, 30, C_FRAME);
    text1("ALERTS", 416, 144, C_CYAN);
    text1(h->note[0] ? h->note : "NONE", 416, 155, h->note[0] ? C_RED : C_PHOS);

    {   /* rotating cube, true 3D */
        static const double v[8][3] = {
            {-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1},
            {-1,-1, 1},{1,-1, 1},{1,1, 1},{-1,1, 1}
        };
        static const int e[12][2] = {
            {0,1},{1,2},{2,3},{3,0},{4,5},{5,6},{6,7},{7,4},{0,4},{1,5},{2,6},{3,7}
        };
        int p[8][2], k;
        double a = t * 0.9, ca = cos(a), sa = sin(a), cb = cos(t * 0.37), sb = sin(t * 0.37);
        for (k = 0; k < 8; k++) {
            double x = v[k][0], y = v[k][1], z = v[k][2], x1, z1, y1;
            x1 = x * ca - z * sa; z1 = x * sa + z * ca;
            y1 = y * cb - z1 * sb; z1 = y * sb + z1 * cb;
            { double d = 4.0 / (4.0 + z1);
              p[k][0] = 522 + (int)(x1 * 36 * d);
              p[k][1] = 248 + (int)(y1 * 36 * d); }
        }
        for (k = 0; k < 12; k++)
            line(p[e[k][0]][0], p[e[k][0]][1], p[e[k][1]][0], p[e[k][1]][1], C_PHOSD);
    }
    text1("SACD HUD H2", 4, CH - 10, C_PHOSD);
    text1r("CPSA//MT85", CW - 4, CH - 10, C_MAGENTA);
}

int main(int argc, char **argv)
{
    IDirectFB *dfb;
    IDirectFBSurface *prim = NULL, *canvas = NULL;
    DFBSurfaceDescription dsc, cdesc;
    DFBResult ret;
    int hold = (argc > 1) ? atoi(argv[1]) : 120;
    const char *ticker = (argc > 2) ? argv[2] : "/tmp/cand.out";
    hud_t h;
    int pw = 0, ph = 0, first_blit = 1;
    struct timespec t0, now;
    unsigned frames = 0;
    long long next_sample = 0, next_frame = 0;
    double fps = 0;

    if (hold < 1) hold = 1;
    if (hold > 600) hold = 600;

    setvbuf(stdout, NULL, _IOLBF, 0);
    ret = DirectFBInit(&argc, &argv);
    printf("HUD: DirectFBInit rc=%d\n", ret);
    if (ret) return 1;
    ret = DirectFBCreate(&dfb);
    printf("HUD: DirectFBCreate rc=%d\n", ret);
    if (ret) return 2;

    /* CAPS ONLY: the provider then hands back the panel's own mode
       (1280x720 here). Asking for 1920x1080 produced a surface larger than the
       visible area, so the right/bottom of the canvas fell off the screen
       (2026-11-05, video evidence). */
    memset(&dsc, 0, sizeof dsc);
    dsc.flags = DSDESC_CAPS;
    dsc.caps = DSCAPS_PRIMARY | DSCAPS_FLIPPING;
    ret = dfb->CreateSurface(dfb, &dsc, &prim);
    printf("HUD: CreateSurface(primary, panel mode) rc=%d\n", ret);
    if (ret) { dfb->Release(dfb); return 3; }
    prim->GetSize(prim, &pw, &ph);
    printf("HUD: primary %dx%d\n", pw, ph);

    /* The canvas MUST be a normal system surface: a DSCAPS_NONE preallocated
       surface is a poor blit source in this provider, and Blit() with a NULL
       rect does not stretch — the H2 first cut therefore drew nothing.
       Pattern: SYSTEMONLY canvas, Lock/Unlock per frame, explicit
       StretchBlit(src 0,0,CW,CH -> dst 0,0,pw,ph). */
    memset(&cdesc, 0, sizeof cdesc);
    cdesc.flags = DSDESC_CAPS | DSDESC_WIDTH | DSDESC_HEIGHT | DSDESC_PIXELFORMAT;
    cdesc.caps = DSCAPS_SYSTEMONLY;
    cdesc.width = CW; cdesc.height = CH;
    cdesc.pixelformat = DSPF_ARGB;
    ret = dfb->CreateSurface(dfb, &cdesc, &canvas);
    printf("HUD: CreateSurface(canvas %dx%d SYSTEMONLY) rc=%d\n", CW, CH, ret);
    if (ret) { prim->Release(prim); dfb->Release(dfb); return 5; }
    fb = calloc(CW * CH, sizeof(unsigned int));
    if (!fb) { canvas->Release(canvas); prim->Release(prim); dfb->Release(dfb); return 4; }
    pitch_px = CW;

    /* self-test: a bright fill through the same Lock->StretchBlit path. If the
       panel stays black here, the blit is the fault and no drawing code
       matters. Logged, so the stick names it. */
    {
        void *p0 = NULL;
        int pitch0 = 0;
        DFBRectangle src = { 0, 0, CW, CH };
        DFBRectangle dst = { 0, 0, pw, ph };
        DFBResult lr = canvas->Lock(canvas, DSLF_WRITE, &p0, &pitch0);
        printf("HUD: selftest Lock rc=%d pitch=%d\n", lr, pitch0);
        if (lr == DFB_OK) {
            int y, x;
            unsigned int *q = p0;
            for (y = 0; y < CH; y++)
                for (x = 0; x < CW; x++) q[(y * pitch0 / 4) + x] = 0xff00ff00u;
            canvas->Unlock(canvas);
        }
        {
            DFBResult br = prim->StretchBlit(prim, canvas, &src, &dst);
            DFBResult fr = prim->Flip(prim, NULL, DSFLIP_NONE);
            printf("HUD: selftest StretchBlit rc=%d Flip rc=%d\n", br, fr);
        }
        sleep(2);
    }

    udp_open();
    printf("HUD: host channel udp/%d %s\n", HUD_UDP_PORT, udp_fd >= 0 ? "OPEN" : "unavailable");
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

        if (canvas->Lock(canvas, DSLF_WRITE, &lockptr, &lockpitch) == DFB_OK) {
            fb = lockptr;
            pitch_px = lockpitch / 4;
            locked = 1;
        }
        scene(&h, t, fps, (int)frames);
        if (locked) canvas->Unlock(canvas);

        {
            DFBRectangle src = { 0, 0, CW, CH };
            DFBRectangle dst = { 0, 0, pw, ph };
            DFBResult br = prim->StretchBlit(prim, canvas, &src, &dst);
            if (first_blit) {
                printf("HUD: StretchBlit rc=%d (canvas %dx%d -> panel %dx%d)\n",
                       br, CW, CH, pw, ph);
                first_blit = 0;
            }
            if (br) prim->Blit(prim, canvas, NULL, 0, 0);
        }
        prim->Flip(prim, NULL, DSFLIP_NONE);
        frames++;
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
    canvas->Release(canvas);
    prim->Release(prim);
    dfb->Release(dfb);
    return 0;
}
