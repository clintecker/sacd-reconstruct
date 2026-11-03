/* qemu_rig.c — LD_PRELOAD test adapter: substitutes the sacd_read.ko
 * device layer for the QEMU protocol rig (issue #5).
 *
 * Interposes in the guest:
 *   system()          -> succeeds without executing anything
 *                        (mknod/insmod/rmmod/rm -rf from the installer)
 *   open64()          -> "/dev/sacd_read" and "/dev/sr0" open the fixture
 *                        disc (RIG_DEVFILE). Its fstat64 size is the
 *                        DISC_SIZE the daemon reports (size/2048), and its
 *                        bytes serve the plain lseek64+read() TOC path.
 *   ioctl()           -> serves the sacd_read.ko protocol
 *                        (0x40105301..0x40105307, 16-byte {a,b,c,d} arg):
 *                        INIT/AUTH/DISC/SACD/UNINIT succeed (a=0);
 *                        READ preads `blocks` x 2048 bytes from the same
 *                        fixture file into the caller's buffer (single
 *                        source of truth for both device paths);
 *                        DECRYPT is a no-op (fixture is plaintext).
 *
 * Compile (ARM): arm-none-linux-gnueabi-gcc -O2 -fPIC -shared
 *   -o sacd_rig.so qemu_rig.c -ldl
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdint.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#define SACD_IOC_INIT    0x40105301UL
#define SACD_IOC_AUTH    0x40105302UL
#define SACD_IOC_READ    0x40105303UL
#define SACD_IOC_DECRYPT 0x40105304UL
#define SACD_IOC_UNINIT  0x40105305UL
#define SACD_IOC_DISC    0x40105306UL
#define SACD_IOC_SACD    0x40105307UL

struct sacd_read_ioc
{
    unsigned long a;
    unsigned long b;
    unsigned long c;
    unsigned long d;
};

static int (*real_open64)(const char *, int, ...);
static int disc_fd = -1;
static pthread_mutex_t disc_lock = PTHREAD_MUTEX_INITIALIZER;

static void init_hooks(void)
{
    if (!real_open64)
        real_open64 = (int (*)(const char *, int, ...))
            dlsym(RTLD_NEXT, "open64");
}

static int open_disc(void)
{
    pthread_mutex_lock(&disc_lock);
    if (disc_fd < 0)
    {
        const char *devfile = getenv("RIG_DEVFILE");
        if (devfile)
            disc_fd = real_open64(devfile, O_RDONLY);
    }
    pthread_mutex_unlock(&disc_lock);
    return disc_fd;
}

int ioctl(int fd, unsigned long request, ...)
{
    struct sacd_read_ioc *ioc;
    va_list ap;

    if (request < SACD_IOC_INIT || request > SACD_IOC_SACD)
    {
        int (*real)(int, unsigned long, ...);
        void *p;
        va_start(ap, request);
        p = va_arg(ap, void *);
        va_end(ap);
        real = (int (*)(int, unsigned long, ...))dlsym(RTLD_NEXT, "ioctl");
        return real(fd, request, p);
    }

    va_start(ap, request);
    ioc = va_arg(ap, struct sacd_read_ioc *);
    va_end(ap);
    if (!ioc)
        return -1;

    switch (request)
    {
    case SACD_IOC_READ:
    {
        uint32_t lsn = (uint32_t)ioc->b;
        uint32_t blocks = (uint32_t)ioc->c;
        uint8_t *dst = (uint8_t *)ioc->d;
        int dfd;
        uint32_t done = 0;
        if (!dst || !blocks)
        {
            ioc->a = (unsigned long)-1;
            return 0;
        }
        dfd = open_disc();
        if (dfd < 0)
        {
            ioc->a = (unsigned long)-1;
            return 0;
        }
        while (done < blocks)
        {
            ssize_t n = pread(dfd, dst + done * 2048, 2048,
                              (off_t)(lsn + done) * 2048);
            if (n < 0)
            {
                ioc->a = (unsigned long)-1;
                return 0;
            }
            if (n < 2048)
            {
                /* short read (past sparse tail): deterministic zeros */
                memset(dst + done * 2048 + n, 0, 2048 - n);
                break;
            }
            done++;
        }
        ioc->a = 0;             /* success: wrapper reports `blocks` read */
        return 0;
    }
    case SACD_IOC_DECRYPT:
        /* plaintext fixture: leave the buffer untouched, report success */
        ioc->a = 0;
        return 0;
    default:
        /* INIT, AUTH, DISC, SACD, UNINIT: present + is-SACD + ok */
        ioc->a = 0;
        return 0;
    }
}

int open64(const char *path, int flags, ...)
{
    init_hooks();
    if (path && (strcmp(path, "/dev/sacd_read") == 0 ||
                 strcmp(path, "/dev/sr0") == 0))
    {
        const char *devfile = getenv("RIG_DEVFILE");
        if (!devfile)
            return -1;
        return real_open64(devfile, O_RDONLY);
    }
    if ((flags & O_CREAT) == 0)
        return real_open64(path, flags);
    {
        va_list ap;
        mode_t mode;
        va_start(ap, flags);
        mode = va_arg(ap, mode_t);
        va_end(ap);
        return real_open64(path, flags, mode);
    }
}

int system(const char *command)
{
    (void)command;
    /* mknod/insmod/rmmod/rm -rf must appear to succeed without touching
     * the host */
    return 0;
}
