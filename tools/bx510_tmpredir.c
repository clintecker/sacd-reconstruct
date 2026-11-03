/* tmpredir.c — /tmp redirect shim for the RO-root BX510 guest.
 *
 * The minimal init=/bin/sh boot has no /tmp, /dev, /proc or /sys at all:
 * Sony's squashfs root has none of the standard mountpoints — a real
 * player's initramfs provides the whole VFS skeleton. install_modules()
 * writes the embedded sacd_read.ko to tmpnam("/tmp/"), mknods
 * /dev/sacd_read and insmods it from there, and that path gates the entire
 * server startup. This shim rewrites /tmp/<x> to /res/tmp/<x> and /dev/<x>
 * to /res/dev/<x> at the libc boundary. The sacd_read node lands on tmpfs
 * with its real major:minor (misc 10:201), so open() still goes through
 * the kernel's misc core: ENXIO unless the REAL module registered minor
 * 201 — module semantics are not faked. LD_PRELOAD propagates through
 * system() -> /bin/sh -c -> mknod/insmod, so every child sees the same
 * redirect the daemon used. Build with the GNU 4.4.1 toolchain (same
 * provenance as the release ELF; GNU dynamic objects are known to load
 * in Sony's guest).
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

/* redirected /dev/sr0 descriptor, for read-path instrumentation */
static int sr0_fd = -1;

static const char *redirect(const char *path, char *out, size_t n)
{
    /* HDHOST seam knob (large-image rig, docs/large-image-interface.md):
     * TMPREDIR_SR0_TARGET reroutes ONLY /dev/sr0 — the daemon's hardcoded
     * disc path — to an arbitrary node (e.g. /res/dev/hdhost), while
     * every other /dev and /tmp rewrite keeps its existing semantics. */
    if (path && strcmp(path, "/dev/sr0") == 0) {
        const char *t = getenv("TMPREDIR_SR0_TARGET");
        if (t && *t) {
            snprintf(out, n, "%s", t);
            return out;
        }
    }
    if (path && strncmp(path, "/tmp/", 5) == 0) {
        snprintf(out, n, "/res/tmp/%s", path + 5);
        return out;
    }
    if (path && strncmp(path, "/dev/", 5) == 0) {
        snprintf(out, n, "/res/dev/%s", path + 5);
        return out;
    }
    return path;
}

int mknod(const char *path, mode_t mode, dev_t dev)
{
    static int (*real)(const char *, mode_t, dev_t) = 0;
    char buf[512];
    if (!real)
        real = dlsym(RTLD_NEXT, "mknod");
    return real(redirect(path, buf, sizeof(buf)), mode, dev);
}

int mknodat(int dirfd, const char *path, mode_t mode, dev_t dev)
{
    static int (*real)(int, const char *, mode_t, dev_t) = 0;
    char buf[512];
    if (!real)
        real = dlsym(RTLD_NEXT, "mknodat");
    return real(dirfd, redirect(path, buf, sizeof(buf)), mode, dev);
}

int open64(const char *path, int flags, ...)
{
    static int (*real)(const char *, int, ...) = 0;
    char buf[512];
    int fd;
    const char *orig = path;
    if (!real)
        real = dlsym(RTLD_NEXT, "open64");
    path = redirect(path, buf, sizeof(buf));
    if (flags & O_CREAT) {
        va_list ap;
        mode_t mode;
        va_start(ap, flags);
        mode = va_arg(ap, mode_t);
        va_end(ap);
        fd = real(path, flags, mode);
    } else {
        fd = real(path, flags);
    }
    if (fd >= 0 && strcmp(orig, "/dev/sr0") == 0)
        sr0_fd = fd;
    return fd;
}

int open(const char *path, int flags, ...)
{
    static int (*real)(const char *, int, ...) = 0;
    char buf[512];
    int fd;
    const char *orig = path;
    if (!real)
        real = dlsym(RTLD_NEXT, "open");
    path = redirect(path, buf, sizeof(buf));
    if (flags & O_CREAT) {
        va_list ap;
        mode_t mode;
        va_start(ap, flags);
        mode = va_arg(ap, mode_t);
        va_end(ap);
        fd = real(path, flags, mode);
    } else {
        fd = real(path, flags);
    }
    if (fd >= 0 && strcmp(orig, "/dev/sr0") == 0)
        sr0_fd = fd;
    return fd;
}

/* glibc's tmpnam ignores TMPDIR (__path_search called with try_tmpdir=0)
 * and requires P_tmpdir to exist; the guest rootfs has no /tmp, so the real
 * call fails and leaves install_modules' strcpy("/tmp/") as the path, which
 * opens EISDIR. tmpnam IS called through the daemon's PLT, so we can
 * provide the POSIX behavior against the shim's tmpfs-backed /tmp: the
 * generated name is redirected to /res/tmp/<x> at open() like any other
 * /tmp path. Only the location differs from hardware; the daemon's logic
 * (strcpy + tmpnam + open + write + insmod + unlink) runs unmodified.
 */
char *tmpnam(char *s)
{
    static char *(*real)(char *) = 0;
    static char buf[64];
    static unsigned long counter = 0;
    char *out;

    if (!real)
        real = dlsym(RTLD_NEXT, "tmpnam");
    out = real ? real(s) : NULL;
    if (out == NULL) {
        out = s ? s : buf;
        snprintf(out, 64, "/tmp/m%06lu", counter++);
    }
    return out;
}

/* the daemon's sacd input path stats /dev/sr0 before opening it
 * ("libsacdread: Can't stat /dev/sr0" observed live with only open()
 * redirected), so the stat family needs the same mapping. */
#include <sys/stat.h>

static int redir_call_stat(int (*real)(int, const char *, void *),
                           int ver, const char *path, void *st)
{
    char buf[512];
    return real(ver, redirect(path, buf, sizeof(buf)), st);
}

int __xstat64(int ver, const char *path, struct stat64 *st)
{
    static int (*real)(int, const char *, struct stat64 *) = 0;
    if (!real)
        real = dlsym(RTLD_NEXT, "__xstat64");
    return redir_call_stat((int (*)(int, const char *, void *))real, ver, path, st);
}

int __xstat(int ver, const char *path, struct stat *st)
{
    static int (*real)(int, const char *, struct stat *) = 0;
    if (!real)
        real = dlsym(RTLD_NEXT, "__xstat");
    return redir_call_stat((int (*)(int, const char *, void *))real, ver, path, st);
}

int stat64(const char *path, struct stat64 *st)
{
    static int (*real)(const char *, struct stat64 *) = 0;
    if (!real)
        real = dlsym(RTLD_NEXT, "stat64");
    {
        char buf[512];
        return real(redirect(path, buf, sizeof(buf)), st);
    }
}

int stat(const char *path, struct stat *st)
{
    static int (*real)(const char *, struct stat *) = 0;
    if (!real)
        real = dlsym(RTLD_NEXT, "stat");
    {
        char buf[512];
        return real(redirect(path, buf, sizeof(buf)), st);
    }
}

/* read-path instrumentation: the master-TOC zero check fails in the
 * guest against a fixture whose on-disk md5 is verified correct, so log
 * every read on the redirected sr0 fd (offset via SEEK_CUR, requested
 * and actual length) to /res/readlog for offline analysis. */
static int log_fd = -1;

static void readlog(const char *msg, long a, long b)
{
    char line[128];
    int n;
    if (log_fd < 0)
        log_fd = open("/res/readlog", O_WRONLY | O_CREAT | O_APPEND, 0644);
    if (log_fd < 0)
        return;
    n = snprintf(line, sizeof(line), "%s %ld %ld\n", msg, a, b);
    write(log_fd, line, n);
}

ssize_t read(int fd, void *buf, size_t count)
{
    static ssize_t (*real)(int, void *, size_t) = 0;
    ssize_t r;
    if (!real)
        real = dlsym(RTLD_NEXT, "read");
    r = real(fd, buf, count);
    if (fd == sr0_fd && sr0_fd >= 0 && r > 0) {
        /* preserve errno across instrumentation: the seek and logging
         * below must not clobber the real read's error state, and the
         * offset must be recorded 64-bit (lseek64) or it overflows past
         * 2 GiB images. */
        int saved_errno = errno;
        off64_t here = lseek64(fd, 0, SEEK_CUR);
        readlog("R", (long)here - (long)r, (long)r);
        /* hex of first 176 received bytes: reveals any striding/shift */
        {
            unsigned char *p = (unsigned char *)buf;
            char hex[360];
            int i, n = 0;
            int lim = r < 176 ? (int)r : 176;
            for (i = 0; i < lim; i++)
                n += snprintf(hex + n, sizeof(hex) - n, "%02x", p[i]);
            readlog("H", 0, 0);
            if (log_fd >= 0)
                write(log_fd, hex, n), write(log_fd, "\n", 1);
        }
        errno = saved_errno;
    }
    return r;
}

off64_t lseek64(int fd, off64_t off, int whence)
{
    static off64_t (*real)(int, off64_t, int) = 0;
    if (!real)
        real = dlsym(RTLD_NEXT, "lseek64");
    return real(fd, off, whence);
}

/* stdio: fopen's internal open bypasses the PLT shim, so the paths need
 * mapping at the fopen layer too ("Can't open /dev/sr0 for reading"
 * observed live with only open/stat redirected). */
#include <stdio.h>

FILE *fopen64(const char *path, const char *mode)
{
    static FILE *(*real)(const char *, const char *) = 0;
    char buf[512];
    if (!real)
        real = dlsym(RTLD_NEXT, "fopen64");
    return real(redirect(path, buf, sizeof(buf)), mode);
}

FILE *fopen(const char *path, const char *mode)
{
    static FILE *(*real)(const char *, const char *) = 0;
    char buf[512];
    if (!real)
        real = dlsym(RTLD_NEXT, "fopen");
    return real(redirect(path, buf, sizeof(buf)), mode);
}

int unlink(const char *path)
{
    static int (*real)(const char *) = 0;
    char buf[512];
    if (!real)
        real = dlsym(RTLD_NEXT, "unlink");
    return real(redirect(path, buf, sizeof(buf)));
}
