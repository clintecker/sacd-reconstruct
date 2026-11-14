/* rc-stale-window.sim.c — host-side control + prediction check for
 * decode/rc-stale-window.md. Companion evidence, not part of the emulator.
 *
 * What it does: runs §3's two new FE payload builders verbatim, replays the
 * GUEST's own arithmetic over their output (sr.c:890-968 get_sectorsize +
 * cdrom.c:3764-3900 cdrom_get_last_written, including the driver's 0xbb head
 * poison and the sizeof() clamps), and prints the resulting blkgetsize64 for
 * two cases:
 *
 *   C113  (0x51/0x52 answered bare-success, no payload)  -> 1655709958144
 *   +patch(0x51/0x52 answered with the MMC payloads)     -> 2179497984
 *
 * The first value is the one the guest actually printed
 * (bdpdrv-runC113.uart.log:2125); the second is C114 prediction P1. Both are
 * asserted, so a change in either builder or in the replayed kernel logic fails
 * loudly instead of drifting.
 *
 * Build/run:  cc -Wall -Wextra -o rcsim rc-stale-window.sim.c && ./rcsim
 */
/* Host-side check of the §3 patch: the two new builders run verbatim, then the
 * guest's own arithmetic (sr.c:890-968 + cdrom.c:3764-3900) is replayed over
 * the payloads. Two cases: C113 (model answers 0x51/0x52 bare-success, no
 * payload) and the patched model. Expect 1655709958144 and 2179497984. */
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>

typedef struct { uint64_t img_bytes; } Bx510State;   /* blk_getlength() */static uint32_t be32(const uint8_t *p)
{ return ((uint32_t)p[0]<<24)|((uint32_t)p[1]<<16)|((uint32_t)p[2]<<8)|p[3]; }
static uint16_t be16(const uint8_t *p) { return (uint16_t)((p[0]<<8)|p[1]); }

/* ---- verbatim from the §3 patch ---- */
#define FE_DISC_INFO_LEN  36u
#define FE_TRACK_INFO_LEN 32u

static void bx510_fe_disc_info(uint8_t *buf)
{
    memset(buf, 0, FE_DISC_INFO_LEN);
    buf[0] = 0x00;
    buf[1] = 0x22;
    buf[3] = 0x01;
    buf[4] = 0x01;
    buf[5] = 0x01;
    buf[6] = 0x01;
}

static void bx510_fe_track_info(Bx510State *s, uint8_t *buf)
{
    uint64_t sectors = s->img_bytes ? s->img_bytes / 2048 : 0;
    uint32_t last_lba = sectors ? (uint32_t)(sectors - 1) : 0;

    memset(buf, 0, FE_TRACK_INFO_LEN);
    buf[0]  = 0x00;
    buf[1]  = 0x1e;
    buf[2]  = 0x01;
    buf[3]  = 0x01;
    buf[5]  = 0x04;
    buf[6]  = 0x01;
    buf[7]  = 0x02;
    buf[24] = last_lba >> 24;
    buf[25] = last_lba >> 16;
    buf[26] = last_lba >> 8;
    buf[27] = last_lba;
    buf[28] = last_lba >> 24;
    buf[29] = last_lba >> 16;
    buf[30] = last_lba >> 8;
    buf[31] = last_lba;
}
/* ---- end verbatim ---- */

/* one data-in packet: the driver poisons head min(len,16) with 0xbb
 * (qc_issu_task 0x7468), then the FE copies `fe_len` bytes if it answered. */
static void packet(uint8_t *buf, unsigned bufsz, unsigned buflen,
                   const uint8_t *payload, unsigned fe_len, unsigned stale_off,
                   uint32_t stale)
{
    memset(buf, 0, bufsz);
    if (stale_off) {                /* pre-existing stack content at one spot */
        buf[stale_off+0] = stale >> 24; buf[stale_off+1] = stale >> 16;
        buf[stale_off+2] = stale >> 8;  buf[stale_off+3] = stale;
    }
    memset(buf, 0xbb, buflen < 16 ? buflen : 16);
    if (payload && fe_len) {
        memcpy(buf, payload, fe_len);
    }
}

/* cdrom_get_disc_info + cdrom_get_track_info return buflen (clamped), never an
 * error, on a successful packet: cdrom.c:3826-3844 / 3788-3801. */
static int disc_info(const uint8_t *di_raw, unsigned first_alloc, uint8_t *di,
                     const uint8_t *payload, unsigned fe_len)
{
    packet(di, 36, first_alloc, NULL, 0, 0, 0);       /* the 2-byte probe */
    if (payload) memcpy(di, payload, fe_len < first_alloc ? fe_len : first_alloc);
    unsigned buflen = be16(di) + 2u;
    if (buflen > 36u) buflen = 36u;
    packet(di, 36, buflen, NULL, 0, 0, 0);             /* requeue */
    if (payload) memcpy(di, payload, fe_len < buflen ? fe_len : buflen);
    (void)di_raw;
    return (int)buflen;
}

static int track_info(uint16_t track, uint8_t *ti, const uint8_t *payload,
                      unsigned fe_len, uint32_t stale, int stale_off)
{
    packet(ti, 32, 8, NULL, 0, stale_off, stale);
    if (payload) memcpy(ti, payload, fe_len < 8 ? fe_len : 8);
    unsigned buflen = be16(ti) + 2u;
    if (buflen > 32u) buflen = 32u;
    packet(ti, 32, buflen, NULL, 0, stale_off, stale);
    if (payload) memcpy(ti, payload, fe_len < buflen ? fe_len : buflen);
    (void)track;
    return (int)buflen;
}

static uint64_t guest_size(Bx510State *s, int model_fixed)
{
    uint8_t rc[8], di[36], ti[32];
    uint8_t disc_pl[FE_DISC_INFO_LEN], track_pl[FE_TRACK_INFO_LEN];
    long last_written = 0;

    bx510_fe_disc_info(disc_pl);
    bx510_fe_track_info(s, track_pl);

    /* sr.c:901-908 — the 8-byte READ CAPACITY reply (model row, unchanged) */
    uint64_t sectors = s->img_bytes / 2048;
    uint32_t last_lba = (uint32_t)(sectors - 1);
    rc[0] = last_lba >> 24; rc[1] = last_lba >> 16; rc[2] = last_lba >> 8; rc[3] = last_lba;
    rc[4] = 0x00; rc[5] = 0x00; rc[6] = 0x08; rc[7] = 0x00;

    long capacity = 1 + (long)be32(rc);                     /* sr.c:921 */
    unsigned sector_size = be32(rc + 4);                    /* sr.c:933 */

    /* cdrom.c:3861 generic branch (cd->cdi.mask == 0, sr.c:845) */
    int ret = disc_info(NULL, 2, di, model_fixed ? disc_pl : NULL,
                        model_fixed ? FE_DISC_INFO_LEN : 0);
    if (ret >= 7) {                                         /* cdrom.c:3865 */
        uint32_t track = ((uint32_t)di[11] << 8) | di[6];    /* cdrom.c:3870 */
        int ti_size = track_info((uint16_t)track, ti,
                                 model_fixed ? track_pl : NULL,
                                 model_fixed ? FE_TRACK_INFO_LEN : 0,
                                 0x30300020u, 28);           /* the C113 stale word */
        if (ti_size >= 8 && !(ti[6] & 0x40) && ti_size >= 28) {
            if ((ti[7] & 0x02) && ti_size >= 32)  last_written = (long)be32(ti + 28);
            else {
                last_written = (long)be32(ti + 8) + (long)be32(ti + 24);
                if (be32(ti + 16)) last_written -= (long)be32(ti + 16) + 7;
            }
            printf("   [0x52 CDB track=0x%04x buflen=%d] ", track, ti_size);
            if (capacity < last_written) capacity = last_written;   /* sr.c:931 */
        }
    }
    switch (sector_size) {                                  /* sr.c:935-956 */
    case 0: case 2340: case 2352: sector_size = 2048; /* fallthrough */
    case 2048: capacity *= 4; /* fallthrough */
    case 512: break;
    default: capacity = 0;
    }
    (void)sector_size;
    return (uint64_t)capacity * 512ULL;                      /* set_capacity + i_size */
}

int main(void)
{
    setvbuf(stdout, NULL, _IONBF, 0);
    Bx510State s = { .img_bytes = 2179497984ULL };   /* firebird.iso */
    uint64_t c113 = guest_size(&s, 0), fixed = guest_size(&s, 1);
    fflush(stdout);
    printf("C113  (0x51/0x52 bare success) blkgetsize64 = %llu\n", (unsigned long long)c113);
    printf("+patch(0x51/0x52 answered)     blkgetsize64 = %llu\n", (unsigned long long)fixed);
    printf("driver 'Disc MAX LBA' printk (last_rec_address + 1) = 0x%x\n",
           1064207 + 1);
    fflush(stdout);
    assert(c113  == 1655709958144ULL);      /* the observed C113 value */
    fflush(stdout);
    assert(fixed == 2179497984ULL);         /* the C114 prediction P1 */
    printf("OK: control reproduces C113, patch predicts C114 P1\n");
    return 0;
}
