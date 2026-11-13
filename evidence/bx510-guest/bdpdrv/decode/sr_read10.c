/* sr_read10.c — the C103 READ(10) ladder's only non-shell guest tool.
 *
 * Three modes, each printing exactly one machine-readable line so the Mac-side
 * verdict (decode/read10_verdict.sh) can grep it verbatim:
 *
 *   sr_read10 size     <dev>
 *     SRREAD mode=size dev=… rc=… errno=… blkgetsize64=… blkssz=…
 *
 *   sr_read10 read10   <dev> <lba> <nsec> <outfile> [--sacd]
 *     SRREAD mode=read10 lba=… nsec=… len=… rc=… errno=… sense=… file=…
 *
 *   sr_read10 sacdread init <dev>
 *     SACDREAD cmd=0x40105301 ret=… errno=… result=…
 *   sr_read10 sacdread read <dev> <lba> <nsec> <outfile>
 *     SACDREAD cmd=0x40105303 lba=… nsec=… len=… ret=… errno=… result=… file=…
 *
 * `read10` is a plain SG_IO executor: it builds the CDB itself, so the ladder
 * controls LBA, block count and the Sony vendor byte 10 (0x98, the SACD flag
 * _IDECLI_OddRead sets — mt85xx-ioctl.md §3.1) instead of hoping the block
 * layer picks them. With --sacd the transfer buffer is 2064 x nsec — the byte
 * count the kernel's own mt85xx_ioctl path asks for (mt85xx-ioctl.md §3.3) —
 * which makes this mode the framing differential against /dev/sacd_read.
 *
 * `sacdread` drives the daemon's own path: the 16-byte _IOCTL_SACD_COMMAND
 * { u4Result, u4Offset, u4Sectors, pu1Buf } (sacdread-cpsa.md §2.1), INIT
 * first because that is the daemon's order (daemon-gate-experiments.md §1).
 * DECRYPT (0x40105304) is deliberately absent: it blocks on the GCPU/TrustZone
 * worker with no timeout (sacdread-cpsa.md §4.3) — a ladder must not be able to
 * wedge the guest.
 *
 * sense= is the triple bdpdrv itself prints as "SenseKey: %06x":
 * (SCSI status & 0x0f) << 16 | sb[12] << 8 | sb[13] (ASC, ASCQ)
 * — the same mask _IDECLI_OddTestUnitReadyLoop compares (sacdread-cpsa.md §2.2).
 *
 * Exit status: 0 the operation succeeded, 1 it failed (the line still prints),
 * 2 usage error.
 *
 * Build (VM, era toolchain, dynamic against Sony's libc — the shape
 * daemon-gate-experiments.md §2 uses for sacd_gate_ioctl.c):
 *   ~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -Wextra -std=gnu99 \
 *       -o /tmp/srread sr_read10.c
 */

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include <scsi/sg.h>

#ifndef SG_IO
#define SG_IO 0x2285u              /* identical on every Linux since 2.6 */
#endif
#ifndef BLKGETSIZE64
/* _IOR(0x12, 114, size_t) with size_t = 4 on ARM32/EABI => 0x8004_1272.
 * The 64-bit-host spelling 0x8008_1272 is a DIFFERENT command number and the
 * guest answers it with ENOTTY (C103 attempt 2, errno=25) — the width in the
 * _IOC encoding is the argument size, not the value's. */
#define BLKGETSIZE64 0x80041272u
#endif
#ifndef BLKSSZGET
#define BLKSSZGET 0x1268u
#endif

#define SACD_IOC_INIT 0x40105301u
#define SACD_IOC_READ 0x40105303u
#define SG_DXFER_FROM_DEV_ (-3)
#define TIMEOUT_MS 10000           /* _IDECLI_SendOddCmd asks for the same */

static int usage(const char *p)
{
    fprintf(stderr,
            "usage: %s size <dev>\n"
            "       %s read10 <dev> <lba> <nsec> <outfile> [--sacd]\n"
            "       %s sacdread init <dev>\n"
            "       %s sacdread read <dev> <lba> <nsec> <outfile>\n"
            "       %s hex <file> <label>\n",
            p, p, p, p, p);
    return 2;
}

/* mode_hex — the C105 evidence channel: the guest has no host-visible filesystem
 * (/res is tmpfs that dies with the guest, C104's sacd510.bin was lost that
 * way), no od/tr/cut, and a 4128-byte dump is far past md5-only comparison, so
 * the bytes themselves must ride the UART. 64 B/line keeps every line under the
 * console's line-length truncation; the Mac-side decode reassembles from the
 * off= field, so lost/reordered lines are detectable (off runs 0,64,128...). */
static int mode_hex(const char *path, const char *label)
{
    static const size_t ROW = 64;
    unsigned char buf[64];
    FILE *f = fopen(path, "rb");
    size_t off = 0, n;

    if (!f) {
        fprintf(stderr, "open %s: errno=%d\n", path, errno);
        return 1;
    }
    while ((n = fread(buf, 1, ROW, f)) > 0) {
        size_t i;
        printf("DUMPHEX name=%s off=%lu len=%lu ", label,
               (unsigned long)off, (unsigned long)n);
        for (i = 0; i < n; i++) {
            printf("%02x", buf[i]);
        }
        printf("\n");
        off += n;
    }
    fclose(f);
    printf("DUMPHEX name=%s total=%lu\n", label, (unsigned long)off);
    return 0;
}

static int dump(const char *path, const unsigned char *buf, size_t len)
{
    FILE *f = fopen(path, "wb");
    if (!f) {
        fprintf(stderr, "open %s: errno=%d\n", path, errno);
        return -1;
    }
    if (fwrite(buf, 1, len, f) != len) {
        fprintf(stderr, "write %s: errno=%d\n", path, errno);
        fclose(f);
        return -1;
    }
    fclose(f);
    return 0;
}

static int mode_size(const char *dev)
{
    unsigned long long bytes = 0;
    int ssz = 0, fd, rc, saved;

    errno = 0;
    fd = open(dev, O_RDONLY | O_NONBLOCK);
    if (fd < 0) {
        saved = errno;
        printf("SRREAD mode=size dev=%s rc=-1 errno=%d blkgetsize64=0 blkssz=0\n",
               dev, saved);
        return 1;
    }
    errno = 0;
    rc = ioctl(fd, BLKGETSIZE64, &bytes);
    saved = (rc < 0) ? errno : 0;
    if (rc == 0) {
        errno = 0;
        if (ioctl(fd, BLKSSZGET, &ssz) < 0) {
            ssz = 0;
        }
    }
    printf("SRREAD mode=size dev=%s rc=%d errno=%d blkgetsize64=%llu blkssz=%d\n",
           dev, rc, saved, bytes, ssz);
    close(fd);
    return (rc < 0) ? 1 : 0;
}

static int mode_read10(const char *dev, unsigned lba, unsigned nsec,
                       const char *out, int sacd)
{
    struct sg_io_hdr io;
    unsigned char cdb[12], sb[64];
    unsigned char *buf;
    unsigned long len;
    unsigned sense;
    int fd, rc, saved;

    len = (unsigned long)nsec * (sacd ? 2064UL : 2048UL);
    buf = calloc(1, len);
    if (!buf) {
        fprintf(stderr, "calloc %lu: errno=%d\n", len, errno);
        return 1;
    }

    memset(cdb, 0, sizeof(cdb));
    cdb[0] = 0x28;                       /* READ(10)                     */
    cdb[2] = (unsigned char)(lba >> 24); /* LBA, big-endian (c97 §4.1)   */
    cdb[3] = (unsigned char)(lba >> 16);
    cdb[4] = (unsigned char)(lba >> 8);
    cdb[5] = (unsigned char)lba;
    cdb[7] = (unsigned char)(nsec >> 8);
    cdb[8] = (unsigned char)nsec;
    if (sacd) {
        cdb[10] = 0x98;                  /* Sony SACD flag (_IDECLI_OddRead) */
    }

    memset(&io, 0, sizeof(io));
    memset(sb, 0, sizeof(sb));
    io.interface_id    = 'S';
    io.dxfer_direction = SG_DXFER_FROM_DEV_;
    io.cmd_len         = sizeof(cdb);
    /* The CDB pointer is NOT optional: blkdev_ioctl's SG_IO -> sg_io() does
     * copy_from_user(hp, hdr.cmdp, hdr.cmd_len), so a NULL cmdp returns
     * EFAULT before the command is ever built (C103 attempt 2: every plain
     * read failed errno=14 with a zero sense triple). */
    io.cmdp            = cdb;
    io.mx_sb_len       = sizeof(sb);
    io.dxferp          = buf;
    io.dxfer_len       = len;
    io.sbp             = sb;
    io.timeout         = TIMEOUT_MS;

    errno = 0;
    fd = open(dev, O_RDONLY | O_NONBLOCK);
    if (fd < 0) {
        saved = errno;
        printf("SRREAD mode=read10 lba=%u nsec=%u len=%lu rc=-1 errno=%d "
               "sense=000000 host=0000 driver=0000 file=%s\n",
               lba, nsec, len, saved, out);
        free(buf);
        return 1;
    }
    errno = 0;
    rc = ioctl(fd, SG_IO, &io);
    saved = (rc < 0) ? errno : 0;
    close(fd);

    sense = (unsigned)((io.masked_status & 0x0f) << 16)
          | ((unsigned)sb[12] << 8) | (unsigned)sb[13];
    if (rc == 0 && (io.status != 0 || io.host_status != 0 || io.driver_status != 0)) {
        rc = -1;                         /* SCSI-level failure, ioctl returned 0 */
    }
    dump(out, buf, len);
    printf("SRREAD mode=read10 lba=%u nsec=%u len=%lu rc=%d errno=%d "
           "sense=%06x host=%04x driver=%04x file=%s\n",
           lba, nsec, len, rc, saved, sense, io.host_status, io.driver_status, out);
    free(buf);
    return (rc == 0) ? 0 : 1;
}

static int mode_sacdread(const char *sub, const char *dev, unsigned lba,
                         unsigned nsec, const char *out)
{
    unsigned int a[4];
    unsigned char *buf = NULL;
    unsigned long len = 0;
    unsigned cmd;
    int fd, rc, saved, result;

    if (strcmp(sub, "init") != 0 && strcmp(sub, "read") != 0) {
        return usage("sr_read10");
    }
    cmd = (strcmp(sub, "init") == 0) ? SACD_IOC_INIT : SACD_IOC_READ;

    if (cmd == SACD_IOC_READ) {
        len = (unsigned long)nsec * 2064UL;   /* sacd_read.ko's own budget */
        buf = calloc(1, len);
        if (!buf) {
            fprintf(stderr, "calloc %lu: errno=%d\n", len, errno);
            return 1;
        }
    }

    errno = 0;
    fd = open(dev, O_RDONLY);
    if (fd < 0) {
        saved = errno;
        if (cmd == SACD_IOC_INIT) {
            printf("SACDREAD cmd=0x%08x ret=-1 errno=%d result=-1\n", cmd, saved);
        } else {
            printf("SACDREAD cmd=0x%08x lba=%u nsec=%u len=%lu ret=-1 errno=%d "
                   "result=-1 file=%s\n", cmd, lba, nsec, len, saved, out);
        }
        free(buf);
        return 1;
    }
    memset(a, 0, sizeof(a));
    if (cmd == SACD_IOC_READ) {
        a[1] = lba;
        a[2] = nsec;
        a[3] = (unsigned int)(unsigned long)buf;
    }
    errno = 0;
    rc = ioctl(fd, cmd, a);
    saved = (rc < 0) ? errno : 0;
    result = (int)a[0];                        /* u4Result */
    close(fd);

    if (cmd == SACD_IOC_INIT) {
        printf("SACDREAD cmd=0x%08x ret=%d errno=%d result=%d\n",
               cmd, rc, saved, result);
    } else {
        dump(out, buf, len);
        printf("SACDREAD cmd=0x%08x lba=%u nsec=%u len=%lu ret=%d errno=%d "
               "result=%d file=%s\n", cmd, lba, nsec, len, rc, saved, result, out);
    }
    free(buf);
    /* INIT's success value is CPSA-positive (0x68000000), never 0
     * (daemon-gate-experiments.md §0.6), so success is "ioctl did not fail". */
    return (rc < 0) ? 1 : 0;
}

int main(int argc, char **argv)
{
    if (argc >= 3 && strcmp(argv[1], "size") == 0) {
        return mode_size(argv[2]);
    }
    if (argc >= 6 && strcmp(argv[1], "read10") == 0) {
        int sacd = (argc > 6 && strcmp(argv[6], "--sacd") == 0);
        return mode_read10(argv[2], (unsigned)strtoul(argv[3], NULL, 0),
                           (unsigned)strtoul(argv[4], NULL, 0), argv[5], sacd);
    }
    if (argc >= 4 && strcmp(argv[1], "sacdread") == 0 && strcmp(argv[2], "init") == 0) {
        return mode_sacdread("init", argv[3], 0, 0, NULL);
    }
    if (argc >= 7 && strcmp(argv[1], "sacdread") == 0 && strcmp(argv[2], "read") == 0) {
        return mode_sacdread("read", argv[3], (unsigned)strtoul(argv[4], NULL, 0),
                             (unsigned)strtoul(argv[5], NULL, 0), argv[6]);
    }
    if (argc >= 4 && strcmp(argv[1], "hex") == 0) {
        return mode_hex(argv[2], argv[3]);
    }
    return usage(argv[0]);
}
