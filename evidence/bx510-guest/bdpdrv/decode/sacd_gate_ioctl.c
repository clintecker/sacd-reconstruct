/* sacd_gate_ioctl.c — one SACD ioctl against the real /dev/sacd_read node.
 *
 * The ioctl half of daemon_gate.sh. POSIX sh cannot issue ioctl(2), so the four
 * status commands the daemon's own startup issues are driven from here, one
 * process per command — the same open/ioctl/close shape the daemon uses
 * (decode/daemon-ioctl-side.md §1.2: the daemon opens and closes /dev/sacd_read
 * per call; it never holds a session fd).
 *
 * Payload: a zeroed 16-byte _IOCTL_SACD_COMMAND, exactly what init_sacd(),
 * auth_sacd(), disc_sacd() and sacd_sacd() pass (they memset the struct and
 * write nothing). Commands that DO carry a payload — 0x40105303 READ and
 * 0x40105304 DECRYPT — are refused by design; see the refusal text.
 *
 * Output (one line, machine-parsed by daemon_gate.sh):
 *   IOCTL cmd=0x%08x ret=%d errno=%d result=%d raw=%08x %08x %08x %08x dev=%s
 * where result is arg[0] = u4Result (the value the daemon treats as the command
 * result) and the raw quad is u4Result/u4Offset/u4Sectors/pu1Buf.
 *
 * Exit status: 0 the helper ran and printed a line; 1 the device would not
 * open; 2 usage error or a refused command.
 *
 * Build (VM, era toolchain, dynamic against Sony's libc — the same shape the
 * gate suite already runs in-guest for tools/bx510_sacdstat.c):
 *   ~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -std=gnu99 \
 *       -o /tmp/sacdgate sacd_gate_ioctl.c
 */

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#define SACD_IOC_INIT    0x40105301u
#define SACD_IOC_AUTH    0x40105302u
#define SACD_IOC_READ    0x40105303u
#define SACD_IOC_DECRYPT 0x40105304u
#define SACD_IOC_UNINIT  0x40105305u
#define SACD_IOC_DISC    0x40105306u
#define SACD_IOC_SACD    0x40105307u

int main(int argc, char **argv)
{
    unsigned int arg[4];
    unsigned int cmd;
    const char *dev = "/dev/sacd_read";
    char *end;
    int fd, ret, saved;

    if (argc < 2) {
        fprintf(stderr, "usage: %s <0x4010530N> [device]\n", argv[0]);
        return 2;
    }
    errno = 0;
    cmd = (unsigned int)strtoul(argv[1], &end, 0);
    if (end == argv[1] || *end != '\0') {
        fprintf(stderr, "bad command %s; want 0x40105301..0x40105307\n", argv[1]);
        return 2;
    }
    if (argc > 2 && argv[2][0] != '\0')
        dev = argv[2];

    switch (cmd) {
    case SACD_IOC_INIT:
    case SACD_IOC_AUTH:
    case SACD_IOC_UNINIT:
    case SACD_IOC_DISC:
    case SACD_IOC_SACD:
        break;
    case SACD_IOC_READ:
        fprintf(stderr, "refused: 0x40105303 needs lba+sectors+2064*n buffer "
                        "(n<=128) — not a startup gate\n");
        return 2;
    case SACD_IOC_DECRYPT:
        fprintf(stderr, "refused: 0x40105304 blocks on the GCPU/TrustZone "
                        "worker with no timeout (bdpdrv i4GCPU_CmdExec, 0x806)\n");
        return 2;
    default:
        fprintf(stderr, "bad command 0x%08x; sacd_read_ioctl accepts only "
                        "type 0x53, nr 1..7\n", cmd);
        return 2;
    }

    fd = open(dev, O_RDONLY);
    if (fd < 0) {
        saved = errno;
        fprintf(stderr, "open %s: errno=%d\n", dev, saved);
        printf("IOCTL cmd=0x%08x ret=-1 errno=%d result=-1 "
               "raw=00000000 00000000 00000000 00000000 dev=%s\n",
               cmd, saved, dev);
        return 1;
    }
    memset(arg, 0, sizeof(arg));
    errno = 0;
    ret = ioctl(fd, cmd, arg);
    saved = (ret < 0) ? errno : 0;
    printf("IOCTL cmd=0x%08x ret=%d errno=%d result=%d "
           "raw=%08x %08x %08x %08x dev=%s\n",
           cmd, ret, saved, (int)arg[0],
           arg[0], arg[1], arg[2], arg[3], dev);
    close(fd);
    return 0;
}
