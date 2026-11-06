/* bx510_mkfixture.c — in-guest Scarlet Book fixture generator (BX510 guest).
 *
 * Faithful C port of tools/fixture_gen.py (the qemu-user rig's proven
 * fixture): master TOC @510, eight SACDText @511..518, area TOC @600,
 * deterministic synthetic sectors @0..127 and @MID..MID+1, sparse rest,
 * total 86200 sectors (176 MiB logical; tmpfs allocates only written
 * pages). DISC_SIZE comes from the daemon's fstat64(st_size)/2048, so the
 * in-guest daemon reports the same 86200 sectors as the qemu-user rig —
 * the two rigs become cross-comparable.
 *
 * The daemon opens /dev/sr0 for TOC reads; the tmpredir shim maps
 * /dev/<x> to /res/dev/<x>, so the fixture is written to /res/dev/sr0
 * and the preloaded daemon reads it as a plain file (lseek64+read path).
 *
 * Build: static (needs nothing from the guest loader).
 */
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define LSN 2048
#define TOTAL_SECTORS 86200
#define AREA_LSN 600
#define ENCRYPTED_START 80000
#define ENCRYPTED_END 86000
#define MID_LSN (TOTAL_SECTORS / 2)

static uint8_t sec[LSN];

static void put(uint8_t *s, int *off, const void *b, int n)
{
    memcpy(s + *off, b, n);
    *off += n;
}

static void p16(uint8_t *s, int *off, uint16_t v)
{
    uint8_t b[2] = { (uint8_t)(v >> 8), (uint8_t)v };
    put(s, off, b, 2);
}

static void p32(uint8_t *s, int *off, uint32_t v)
{
    uint8_t b[4] = { (uint8_t)(v >> 24), (uint8_t)(v >> 16),
                     (uint8_t)(v >> 8), (uint8_t)v };
    put(s, off, b, 4);
}

static void zeros(uint8_t *s, int *off, int n)
{
    uint8_t z[64] = { 0 };
    while (n > 0) {
        int c = n < (int)sizeof(z) ? n : (int)sizeof(z);
        put(s, off, z, c);
        n -= c;
    }
}

static void master_toc(uint8_t *s)
{
    int o = 0;
    memset(s, 0, LSN);
    put(s, &o, "SACDMTOC", 8);
    { uint8_t v[2] = { 1, 0x14 }; put(s, &o, v, 2); }   /* version 1.20 */
    zeros(s, &o, 6);                                     /* reserved01 */
    p16(s, &o, 1);                                       /* album_set_size */
    p16(s, &o, 1);                                       /* album_sequence_number */
    zeros(s, &o, 4);                                     /* reserved02 */
    zeros(s, &o, 16);                                    /* album_catalog_number */
    zeros(s, &o, 16);                                    /* album_genre[4] (4-byte
                                                          * genre_table_t: category
                                                          * u8 + reserved u16 + genre
                                                          * u8; real-disc ground
                                                          * truth) */
    zeros(s, &o, 8);                                     /* reserved03 */
    p32(s, &o, AREA_LSN);                                /* area_1_toc_1_start */
    p32(s, &o, 0);
    p32(s, &o, 0);
    p32(s, &o, 0);
    { uint8_t v = 0; put(s, &o, &v, 1); }                /* disc_type */
    zeros(s, &o, 3);                                     /* reserved04 */
    p16(s, &o, 10);                                      /* area_1_toc_size */
    p16(s, &o, 0);                                       /* area_2_toc_size */
    zeros(s, &o, 16);                                    /* disc_catalog_number */
    zeros(s, &o, 16);                                    /* disc_genre[4] (4-byte
                                                          * genre_table_t) */
    p16(s, &o, 2025);                                    /* year */
    { uint8_t v[2] = { 11, 2 }; put(s, &o, v, 2); }      /* month, day */
    zeros(s, &o, 4);                                     /* reserved05 */
    { uint8_t v = 1; put(s, &o, &v, 1); }                /* text_area_count */
    zeros(s, &o, 7);                                     /* reserved06 */
    for (int i = 0; i < 8; i++) {
        uint8_t loc[4] = { 'e', 'n', 0, 0 };
        put(s, &o, loc, 4);                              /* locales[8] */
    }
    /* 4-byte genre tables: total 168 (real-disc ground truth; the old
     * 20-byte arrays shifted the tail 8 bytes and failed the original
     * daemon's reserved06 zero-check in the full-system guest). */
    if (o != 168) { fprintf(stderr, "master toc size %d\n", o); return; }
}

static void sacd_man(uint8_t *s)
{
    /* master_man_t: 'SACD_Man' + zeros (real-disc ground truth at LSN
     * 519; required by scarletbook_read_master_toc's final check). */
    memset(s, 0, LSN);
    memcpy(s, "SACD_Man", 8);
}

static void area_toc(uint8_t *s)
{
    int o = 0;
    memset(s, 0, LSN);
    put(s, &o, "TWOCHTOC", 8);
    { uint8_t v[2] = { 1, 0x14 }; put(s, &o, v, 2); }    /* version 1.20 */
    p16(s, &o, 1);                                       /* size -> skips SACDTTxt scan */
    zeros(s, &o, 4);                                     /* reserved01 */
    p32(s, &o, 0);                                       /* max_byte_rate */
    { uint8_t v = 0x04; put(s, &o, &v, 1); }            /* sample_frequency */
    { uint8_t v = 0; put(s, &o, &v, 1); }                /* frame_format */
    zeros(s, &o, 10);                                    /* reserved03 */
    { uint8_t v = 2; put(s, &o, &v, 1); }                /* channel_count */
    { uint8_t v = 0; put(s, &o, &v, 1); }                /* loudspeaker_config */
    { uint8_t v = 2; put(s, &o, &v, 1); }                /* max_available_channels */
    { uint8_t v = 0; put(s, &o, &v, 1); }                /* area_mute_flags */
    zeros(s, &o, 12);                                    /* reserved04 */
    { uint8_t v = 0; put(s, &o, &v, 1); }                /* track_attribute */
    zeros(s, &o, 15);                                    /* reserved06 */
    { uint8_t v[3] = { 0, 0, 0 }; put(s, &o, v, 3); }    /* total_playtime */
    { uint8_t v = 0; put(s, &o, &v, 1); }                /* reserved07 */
    { uint8_t v = 0; put(s, &o, &v, 1); }                /* track_offset */
    { uint8_t v = 1; put(s, &o, &v, 1); }                /* track_count */
    zeros(s, &o, 2);                                     /* reserved08 */
    p32(s, &o, ENCRYPTED_START);                         /* track_start */
    p32(s, &o, ENCRYPTED_END);                           /* track_end */
    { uint8_t v = 0; put(s, &o, &v, 1); }                /* text_area_count */
    zeros(s, &o, 7);                                     /* reserved09 */
    zeros(s, &o, 40);                                    /* languages[10] */
    p16(s, &o, 0);                                       /* track_text_offset */
    p16(s, &o, 0);                                       /* index_list_offset */
    p16(s, &o, 0);                                       /* access_list_offset */
    zeros(s, &o, 10);                                    /* reserved10 */
    p16(s, &o, 0);                                       /* area_description_offset */
    p16(s, &o, 0);                                       /* copyright_offset */
    p16(s, &o, 0);                                       /* area_description_phonetic_offset */
    p16(s, &o, 0);                                       /* copyright_phonetic_offset */
    if (o != 152) { fprintf(stderr, "area toc size %d\n", o); return; }
}

static void sacd_text(uint8_t *s)
{
    memset(s, 0, LSN);
    memcpy(s, "SACDText", 8);
}

static void synthetic(uint8_t *s, uint32_t lsn)
{
    uint32_t x = lsn ^ 0x5ACD5ACDu;
    memset(s, 0, LSN);
    for (int i = 0; i < LSN; i += 4) {
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        memcpy(s + i, &x, 4);        /* little-endian host = ARM LE */
    }
}

static void encsynth(uint8_t *s, uint32_t lsn)
{
    /* distinct nonzero pattern for the encrypted range: same xorshift
     * family as synthetic() with a different salt, so wrong-sector reads
     * and packing failures cannot hide in zero-filled holes (team review
     * finding). Mock decrypt is a verbatim copy, so these are also the
     * expected wire bytes for encrypted-range reads. Byte-identical to
     * fixture_gen.py's enc_sector(). */
    uint32_t x = lsn ^ 0xDEAD5ACDu;
    memset(s, 0, LSN);
    for (int i = 0; i < LSN; i += 4) {
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        memcpy(s + i, &x, 4);
    }
}

static int emit(int fd, long lsn)
{
    if (lseek(fd, lsn * LSN, SEEK_SET) < 0)
        return -1;
    return (int)write(fd, sec, LSN);
}

int main(int argc, char **argv)
{
    const char *path = argc > 1 ? argv[1] : "/res/dev/sr0";
    /* argv[2] == "corrupt": deterministic malformed-TOC negative control —
     * patch reserved06 (sector 510, bytes 129..136) to 0xAA AFTER building
     * the valid TOC, so every open (poll and client) sees the malformed
     * disc. The daemon's poll loop opens within ~1s of file creation, so
     * corrupting after mkfixture returned is racy; corrupting inside the
     * builder closes that window. */
    int corrupt = (argc > 2 && strcmp(argv[2], "corrupt") == 0);
    int fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    long i;

    if (fd < 0) {
        perror(path);
        return 1;
    }
    if (ftruncate(fd, (long)TOTAL_SECTORS * LSN) < 0)
        perror("ftruncate (tmpfs may be small; continuing)");

    master_toc(sec);
    if (emit(fd, 510) < 0) { perror("write"); return 1; }
    sacd_text(sec);
    for (i = 511; i < 519; i++)
        if (emit(fd, i) < 0) { perror("write"); return 1; }
    sacd_man(sec);
    if (emit(fd, 519) < 0) { perror("write"); return 1; }
    area_toc(sec);
    if (emit(fd, AREA_LSN) < 0) { perror("write"); return 1; }
    if (corrupt) {
        /* Deterministic negative control: destroy the SACDMTOC magic
         * itself. Corrupting reserved06 left hidden couplings (the
         * daemon poll's open attempts, in-memory handles, and the
         * OPEN-result default) that could still yield a valid session;
         * with the magic gone, NO validator can ever pass, from the
         * very first read, in any path. */
        if (lseek(fd, 510 * LSN, SEEK_SET) < 0 ||
            write(fd, "\xAA\xAA\xAA\xAA\xAA\xAA\xAA\xAA", 8) != 8) {
            perror("corrupt");
            return 1;
        }
        printf("mkfixture: NEGATIVE control applied (SACDMTOC magic = 0xAA x8)\n");
    }
    for (i = 0; i < 128; i++) {
        synthetic(sec, (uint32_t)i);
        if (emit(fd, i) < 0) { perror("write"); return 1; }
    }
    for (i = MID_LSN; i <= MID_LSN + 1; i++) {
        synthetic(sec, (uint32_t)i);
        if (emit(fd, i) < 0) { perror("write"); return 1; }
    }
    /* boundary sectors 79990..79999: nonzero synthetic data (was sparse
     * zeros); the encrypted-range test sectors 80000..80001 get the
     * distinct enc pattern. Different LSNs than the corrupt patch, so
     * ordering does not interact. */
    for (i = 79990; i < 80000; i++) {
        synthetic(sec, (uint32_t)i);
        if (emit(fd, i) < 0) { perror("write"); return 1; }
    }
    for (i = ENCRYPTED_START; i < ENCRYPTED_START + 2; i++) {
        encsynth(sec, (uint32_t)i);
        if (emit(fd, i) < 0) { perror("write"); return 1; }
    }
    close(fd);
    printf("mkfixture: %s, %d sectors, area LSN %d, mid %d%s\n",
           path, TOTAL_SECTORS, AREA_LSN, MID_LSN,
           corrupt ? " [MALFORMED]" : "");
    return 0;
}
