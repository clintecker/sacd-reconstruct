/* bx510_sacdstat.c — direct SACD-status ioctl check for the BX510 guest.
 *
 * The team review asked for a direct check of the 5307 (SACD_IOC_SACD)
 * contract: sacd_read.ko's handler calls _IDECLI_OddGetProfile(&out) and
 * compares the value with 0x10 (SACD profile). Successful wire payload
 * reads do not cover this path — this binary drives the ioctl directly
 * against the real module node with a zeroed argument and reports the
 * result quad. Expect: ret >= 0 and the profile-dependent result
 * consistent with the GetProfile output (bdpvirt writes 0x10).
 *
 * Build: dynamic. Run: sacdstat  (unpreloaded; opens the real node path).
 */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#define SACD_IOC_SACD 0x40105307

int main(void)
{
    unsigned int arg[4];
    int fd = open("/res/dev/sacd_read", O_RDONLY);
    int ret;

    if (fd < 0) {
        perror("open /res/dev/sacd_read");
        return 1;
    }
    memset(arg, 0, sizeof(arg));
    ret = ioctl(fd, SACD_IOC_SACD, arg);
    printf("STAT: ioctl(5307) ret=%d errno=%d a=%d b=%u c=%u d=%u\n",
           ret, ret < 0 ? errno : 0, (int)arg[0], arg[1], arg[2], arg[3]);
    close(fd);
    return (ret >= 0) ? 0 : 1;
}
