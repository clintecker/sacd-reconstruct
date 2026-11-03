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
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

static const char *redirect(const char *path, char *out, size_t n)
{
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
    if (!real)
        real = dlsym(RTLD_NEXT, "open64");
    path = redirect(path, buf, sizeof(buf));
    if (flags & O_CREAT) {
        va_list ap;
        mode_t mode;
        va_start(ap, flags);
        mode = va_arg(ap, mode_t);
        va_end(ap);
        return real(path, flags, mode);
    }
    return real(path, flags);
}

int open(const char *path, int flags, ...)
{
    static int (*real)(const char *, int, ...) = 0;
    char buf[512];
    if (!real)
        real = dlsym(RTLD_NEXT, "open");
    path = redirect(path, buf, sizeof(buf));
    if (flags & O_CREAT) {
        va_list ap;
        mode_t mode;
        va_start(ap, flags);
        mode = va_arg(ap, mode_t);
        va_end(ap);
        return real(path, flags, mode);
    }
    return real(path, flags);
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

int unlink(const char *path)
{
    static int (*real)(const char *) = 0;
    char buf[512];
    if (!real)
        real = dlsym(RTLD_NEXT, "unlink");
    return real(redirect(path, buf, sizeof(buf)));
}
