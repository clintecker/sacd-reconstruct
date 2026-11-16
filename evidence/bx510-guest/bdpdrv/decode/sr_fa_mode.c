/* sr_fa_mode — read (and optionally clear) the two vendor flags sr_mod.ko's
 * sr_test_unit_ready() short-circuits on, so the block layer's buffered read of
 * /dev/sr0 stops being refused with -EIO (dd-eio-loop.md §3/§6).
 *
 * Why this is the lever and not a reply: sr_prep_fn (sr_mod.ko .text+0xfdc)
 * returns BLKPREP_KILL while sdev->changed is set, and `changed` is cleared only
 * by sr_media_change's success path (.text+0x1738), which needs
 * sr_test_unit_ready() == 0. That function fabricates 0x08000002 with NO CDB
 * whenever isFaMode|isBeQuiet is set (.text+0x1484/0x1490/0x1554), so the latch
 * never clears and no SCSI command is ever issued for a buffered read. The two
 * flags are plain dwords in the sata_mt85xx channel struct, written ONLY by the
 * 0x8532/0x8534 ioctls (sata_mt85xx_set_FA_mode .text+0x76ec / set_seq_rd_mode
 * .text+0x7670) — so userspace can read them back and zero them.
 *
 *   sr_fa_mode /dev/sr0            print both flags  (diagnostic)
 *   sr_fa_mode /dev/sr0 clear      write 0 to both, then print the read-back
 * Exit 0 on success; the printed line is the observable:
 *   FA_MODE fa=<v> rc=<n> be_quiet=<v> rc=<n>
 */
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <errno.h>

#define MT85XX_IDE_GET_FA_MODE  0x8531
#define MT85XX_IDE_SET_FA_MODE  0x8532
#define MT85XX_IDE_GET_BE_QUIET 0x8533
#define MT85XX_IDE_SET_BE_QUIET 0x8534

int main(int argc, char **argv)
{
    const char *dev = (argc > 1) ? argv[1] : "/dev/sr0";
    int clear = (argc > 2 && strcmp(argv[2], "clear") == 0);
    int fd, fa = -1, bq = -1, r1, r2, z = 0;

    /* O_RDONLY|O_NONBLOCK: the fast open path, so this never depends on media. */
    fd = open(dev, O_RDONLY | O_NONBLOCK);
    if (fd < 0) {
        printf("FA_MODE open failed %s errno=%d\n", dev, errno);
        return 1;
    }
    r1 = ioctl(fd, MT85XX_IDE_GET_FA_MODE, &fa);
    r2 = ioctl(fd, MT85XX_IDE_GET_BE_QUIET, &bq);
    if (clear) {
        (void)ioctl(fd, MT85XX_IDE_SET_FA_MODE, &z);
        (void)ioctl(fd, MT85XX_IDE_SET_BE_QUIET, &z);
        fa = bq = -1;
        r1 = ioctl(fd, MT85XX_IDE_GET_FA_MODE, &fa);
        r2 = ioctl(fd, MT85XX_IDE_GET_BE_QUIET, &bq);
    }
    printf("FA_MODE fa=%d rc=%d be_quiet=%d rc=%d\n", fa, r1, bq, r2);
    close(fd);
    return (fa == 0 && bq == 0) ? 0 : 2;
}
