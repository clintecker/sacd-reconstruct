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
#include <sys/stat.h>
#include <sys/sysmacros.h>
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
static int (*real_fstat64)(int, struct stat64 *);
static int (*real_execvp)(const char *, char *const argv[]);

/* The enhanced installer (sacd-enhanced, B10/B11) VALIDATES its
 * environment instead of trusting it: fstat on the device fd must
 * show the expected character device (major 10 — the module registers
 * as a misc device, minor 201), and the loader call must succeed. In
 * this rig the device fd is the fixture file and no real insmod runs,
 * so the two seams are modeled here: the rig presents the disc fd AS
 * the module's misc device, and loader invocations succeed without
 * executing (the module protocol is answered by the ioctl seam). This
 * is the acceptance environment, not a bypass — the original binary
 * accepted the rig because it ignored shell results (that is B11
 * itself); the enhanced binary demands what real hardware provides. */
static int is_disc_fd(int fd)
{
    return fd >= 0 && fd == disc_fd;
}

int fstat64(int fd, struct stat64 *st)
{
    if (!real_fstat64)
        real_fstat64 = (int (*)(int, struct stat64 *))
            dlsym(RTLD_NEXT, "fstat64");
    int rc = real_fstat64(fd, st);
    if (rc == 0 && is_disc_fd(fd))
    {
        st->st_mode = (st->st_mode & ~S_IFMT) | S_IFCHR;
        st->st_rdev = makedev(10, 201);
    }
    return rc;
}

int fstat(int fd, struct stat *st)
{
    /* glibc maps fstat->fstat64 internally with hidden aliases, so this
     * interposition only affects direct application calls (which is
     * what the installer makes). Keep it for completeness. */
    struct stat64 st64;
    int rc = fstat64(fd, &st64);
    if (rc == 0)
    {
        /* copy back the fields the caller can see */
        st->st_mode = st64.st_mode;
        st->st_rdev = st64.st_rdev;
        st->st_size = st64.st_size;
    }
    return rc;
}

static int (*real_mknod)(const char *, mode_t, dev_t);
static int (*real_unlink)(const char *);

/* glibc's headers compile mknod/fstat64 into inline wrappers that call
 * the __x- internal symbols (verified from the enhanced binary's dynamic
 * symbol table: it imports __xmknod@GLIBC_2.4 and calls __fxstat64 via a
 * LOCAL HIDDEN inline fstat64 — the plain mknod/fstat64 interpositions
 * below are never reached by it). The __x- forms are the real seams. */
int __xmknod(int ver, const char *path, mode_t mode, dev_t *dev)
{
    if (path && strcmp(path, "/dev/sacd_read") == 0)
        return 0;
    {
        static int (*real)(int, const char *, mode_t, dev_t *);
        if (!real)
            real = (int (*)(int, const char *, mode_t, dev_t *))
                dlsym(RTLD_NEXT, "__xmknod");
        return real(ver, path, mode, dev);
    }
}

int __fxstat64(int ver, int fd, struct stat64 *st)
{
    {
        static int (*real)(int, int, struct stat64 *);
        if (!real)
            real = (int (*)(int, int, struct stat64 *))
                dlsym(RTLD_NEXT, "__fxstat64");
        int rc = real(ver, fd, st);
        if (rc == 0 && is_disc_fd(fd))
        {
            st->st_mode = (st->st_mode & ~S_IFMT) | S_IFCHR;
            st->st_rdev = makedev(10, 201);
        }
        return rc;
    }
}

int mknod(const char *path, mode_t mode, dev_t dev)
{
    /* The enhanced installer creates the device node directly (no shell)
     * and CHECKS the result — the original's shell mknod failed silently
     * in this rig (that is finding B11). Model the node's existence. */
    if (path && strcmp(path, "/dev/sacd_read") == 0)
        return 0;
    if (!real_mknod)
        real_mknod = (int (*)(const char *, mode_t, dev_t))
            dlsym(RTLD_NEXT, "mknod");
    return real_mknod(path, mode, dev);
}

int unlink(const char *path)
{
    /* remove_modules tears the node down on exit; model it. */
    if (path && strcmp(path, "/dev/sacd_read") == 0)
        return 0;
    if (!real_unlink)
        real_unlink = (int (*)(const char *))dlsym(RTLD_NEXT, "unlink");
    return real_unlink(path);
}

int execvp(const char *file, char *const argv[])
{
    /* Model the module loader accepting the staged module. Real insmod
     * cannot run under qemu-user here (and the original binary never
     * checked its result — B11). Arguments are inspected only to keep
     * the seam honest: it answers only insmod-shaped invocations. */
    if (file && strstr(file, "insmod"))
    {
        /* execvp semantics: success NEVER returns. run_loader waits for
         * the child, so the model of "loader accepted the module" is the
         * child exiting 0. Returning would fall through to _exit(127)
         * and read as a failed load (found via -d strace: waitpid 127). */
        _exit(0);
    }
    if (!real_execvp)
        real_execvp = (int (*)(const char *, char *const []))
            dlsym(RTLD_NEXT, "execvp");
    return real_execvp(file, argv);
}
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
    case SACD_IOC_INIT:
        /* the enhanced installer's validate_device probe (B11): the
         * module answers init with success */
        ioc->a = 0;
        return 0;
    case SACD_IOC_READ:
    {
        /* Real contract (module disassembly, SHA b3d7a383...): the module
         * fills the caller's buffer with RAW 2064-byte frames -- 12-byte
         * header, 2048 logical bytes, 4 trailing bytes (.text+0x318 loads
         * 2064, +0x368 calls _IDECLI_OddRead, +0x3cc copies to the user
         * pointer). We synthesize header/trailer deterministically and
         * take the logical bytes from the fixture at 2048-byte stride, so
         * the daemon's buffer striding (0x40800 raw / 0x40000 logical)
         * is exercised exactly as on hardware. */
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
            uint8_t *frame = dst + done * 2064;
            ssize_t n = pread(dfd, frame + 12, 2048,
                             (off_t)(lsn + done) * 2048);
            if (n < 0)
            {
                ioc->a = (unsigned long)-1;
                return 0;
            }
            if (n < 2048)
            {
                if (done == 0)
                {
                    /* first sector already past EOF: a read failure,
                     * like the real module at end-of-disc */
                    ioc->a = (unsigned long)-1;
                    return 0;
                }
                /* short mid-block read (sparse tail): deterministic zeros */
                memset(frame + 12 + n, 0, 2048 - n);
            }
            /* deterministic synthetic frame header/trailer */
            frame[0] = (uint8_t)(lsn + done);
            frame[1] = (uint8_t)((lsn + done) >> 8);
            frame[2] = (uint8_t)((lsn + done) >> 16);
            frame[3] = 0x5a;
            memset(frame + 4, 0, 8);          /* header bytes 4..11 */
            memset(frame + 2060, 0, 4);       /* trailing check bytes */
            if (n < 2048)
                break;
            done++;
        }
        ioc->a = 0;             /* success: wrapper reports `blocks` read */
        return 0;
    }
    case SACD_IOC_DECRYPT:
    {
        /* Real contract (module .text+0x4b4/+0x4e4/+0x500,
         * CPSA_SACDCmdDecrypt output path): pack 2048 logical bytes from
         * offset 12 of each 2064-byte frame to the front of the buffer.
         * Raw metadata is synthetic here; the logical payload equals the
         * fixture bytes. NOT a CPSA crypto implementation -- the
         * on-player pair capture (optical/ trace-launch) covers real
         * raw metadata and authentication behavior. */
        uint32_t blocks = (uint32_t)ioc->c;
        uint8_t *buf = (uint8_t *)ioc->d;
        uint32_t i;
        if (!buf || !blocks)
        {
            ioc->a = (unsigned long)-1;
            return 0;
        }
        for (i = 0; i < blocks; i++)
            memcpy(buf + i * 2048, buf + i * 2064 + 12, 2048);
        ioc->a = 0;
        return 0;
    }
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
        {
            int fd = real_open64(devfile, O_RDONLY);
            if (fd >= 0)
            {
                /* every redirected open presents the SAME fixture resource;
                 * record the latest as the device fd so the fstat seam
                 * (validate_device checks S_ISCHR + major on ITS fd) applies */
                disc_fd = fd;
            }
            return fd;
        }
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
