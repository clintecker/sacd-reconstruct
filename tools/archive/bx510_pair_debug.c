/* bx510_pair_debug.c — instrumented variant of
 * emulator-handoff/optical/pair_trace.c for the guest reproduction of the
 * silent pair-observer miss. The observer logic and every match condition
 * are byte-for-byte the originals; the ONLY additions are an env-gated
 * debug log (BX510_PAIR_LOG=<absolute path>) so a silent miss can be
 * NAMED instead of guessed: it records the arming decision (and the
 * reason it failed), every SACD_IOC_READ / SACD_IOC_DECRYPT the process
 * issues with the fields the matcher uses (lsn/count/buf before and
 * after forwarding, rc, result, worker tid, pending state), and the
 * save outcome. All logging is best-effort: a failure to open or write
 * the log never changes observer behavior.
 *
 * Other ioctl request codes never reach C (the ARM assembly stub
 * forwards them with the original registers), so they are invisible to
 * this log by construction — the two SACD codes are the ones the
 * matcher cares about anyway.
 *
 * Build (no Zig on the lab VM): gnuarm gcc + gnuarm ld with the same
 * recipe as optical/build_trace.sh — see the commands recorded in
 * evidence/bx510-guest/pair-observer/RESULTS.md. Links against the
 * extracted Sony rootfs libs (/tmp/rootfs/lib on the VM).
 * SPDX-License-Identifier: GPL-2.0-or-later */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syscall.h>
#include <unistd.h>

#define SACD_READ    0x40105303UL
#define SACD_DECRYPT 0x40105304UL
enum { SECTORS = 2, RAW = 2064 * SECTORS, LOGICAL = 2048 * SECTORS };

struct sacd_arg { int32_t result; uint32_t lsn, count; unsigned char *buf; };
/* GCC 4.4 (the VM gnuarm toolchain) predates -std=gnu11, so no
 * _Static_assert: the typedef array is the same compile-time check. */
typedef char bx_requires_arm32_abi[(sizeof(struct sacd_arg) == 16) ? 1 : -1];
typedef int (*ioctl_fn)(int, unsigned long, void *);

static int direct_ioctl(int fd, unsigned long request, void *arg)
{
    return syscall(SYS_ioctl, fd, request, arg);
}

static ioctl_fn next_ioctl = direct_ioctl;
static const char *output;
static uint32_t requested_lsn;
struct pending_read {
    void *buf;
    unsigned char raw[RAW];
};
static pthread_once_t init_once = PTHREAD_ONCE_INIT;
static pthread_key_t pending_key;

/* ---- additive debug log (absent in pair_trace.c) ---- */
static int log_fd = -1;

static void blog(const char *fmt, ...)
{
    char buf[320];
    va_list ap;
    int n;

    if (log_fd < 0)
        return;
    n = snprintf(buf, sizeof(buf), "tid=%ld ", (long)syscall(SYS_gettid));
    if (n < 0 || n >= (int)sizeof(buf))
        return;
    va_start(ap, fmt);
    {
        int m = vsnprintf(buf + n, sizeof(buf) - (size_t)n, fmt, ap);
        va_end(ap);
        if (m < 0)
            return;
        n += m;
    }
    if (n >= (int)sizeof(buf))
        n = (int)sizeof(buf) - 1;
    /* one O_APPEND write per line: workers do not interleave mid-line */
    syscall(SYS_write, log_fd, buf, (size_t)n);
}

static void configure(void)
{
    int saved = errno;
    ioctl_fn next = (ioctl_fn)dlsym(RTLD_NEXT, "ioctl");
    const char *path = getenv("BX510_PAIR_OUT"), *lsn = getenv("BX510_PAIR_LSN"),
               *log = getenv("BX510_PAIR_LOG");
    const char *prog = program_invocation_short_name;
    if (next)
        next_ioctl = next;
    if (log && log[0] == '/')
        log_fd = (int)syscall(SYS_open, log,
                              O_WRONLY | O_CREAT | O_APPEND | O_CLOEXEC, 0600);
    if (!next) {
        blog("CFG armed=0 reason=dlsym-next-null prog=%s\n",
             prog ? prog : "(null)");
        errno = saved;
        return;
    }
    if (!(path && path[0] == '/')) {
        blog("CFG armed=0 reason=out-path prog=%s\n", prog ? prog : "(null)");
        errno = saved;
        return;
    }
    if (!(lsn && *lsn >= '0' && *lsn <= '9')) {
        blog("CFG armed=0 reason=lsn-env prog=%s\n", prog ? prog : "(null)");
        errno = saved;
        return;
    }
    if (!(prog && !strcmp(prog, "sacd_extract_160"))) {
        blog("CFG armed=0 reason=prog-name prog=%s\n", prog ? prog : "(null)");
        errno = saved;
        return;
    }
    char *end;
    errno = 0;
    unsigned long n = strtoul(lsn, &end, 10);
    /* no blog between errno=0 and the strtoul errno check */
    if (!errno && !*end && n < UINT32_MAX &&
        pthread_key_create(&pending_key, free) == 0) {
        requested_lsn = n;
        output = path;
        blog("CFG armed=1 lsn=%lu out=%s\n", n, path);
    } else {
        blog("CFG armed=0 reason=lsn-parse-or-key errno=%d\n", errno);
    }
    errno = saved;
}

__attribute__((visibility("hidden"))) ioctl_fn bx_next_ioctl(void)
{
    int saved = errno;
    pthread_once(&init_once, configure);
    errno = saved;
    return next_ioctl;
}

static int write_all(int fd, const void *buf, size_t n)
{
    const unsigned char *p = buf;
    while (n) {
        ssize_t k = write(fd, p, n);
        if (k < 0 && errno == EINTR) continue;
        if (k <= 0) return -1;
        n -= (size_t)k;
        p += k;
    }
    return 0;
}

static void save_pair(const unsigned char *raw, const unsigned char *logical)
{
    /* Little-endian ARM32. A complete file is exactly 8,240 bytes. */
    const struct { char magic[8]; uint32_t lsn, count; } header =
        { "BX5PAIR1", requested_lsn, SECTORS };
    int fd = open(output, O_CREAT | O_EXCL | O_NOFOLLOW | O_WRONLY | O_CLOEXEC, 0600);
    if (fd < 0) {
        blog("SAVE open-fail errno=%d path=%s\n", errno, output);
        return;
    }
    int failed = write_all(fd, &header, sizeof(header)) || write_all(fd, raw, RAW) ||
                 write_all(fd, logical, LOGICAL) || fsync(fd);
    int crc = close(fd);
    if (crc || failed) {
        int uerr = errno;
        unlink(output);
        blog("SAVE failed close=%d writefail=%d errno=%d path=%s\n",
             crc, failed, uerr, output);
    } else {
        blog("SAVE ok lsn=%u bytes=%d\n",
             requested_lsn, (int)(sizeof(header) + RAW + LOGICAL));
    }
}

__attribute__((visibility("hidden")))
int bx_observe_ioctl(int fd, unsigned long request, struct sacd_arg *arg)
{
    ioctl_fn next = bx_next_ioctl();
    if (!output || !arg) {
        if (request == SACD_READ || request == SACD_DECRYPT)
            blog("%s pass-through unarmed=%d arg-null=%d\n",
                 request == SACD_READ ? "RD" : "DC", !output, !arg);
        return next(fd, request, arg);
    }
    /* Both real handlers can replace arg->buf during copy_to_user. */
    struct sacd_arg input = *arg;
    int rc = next(fd, request, arg);
    int saved = errno;
    struct pending_read *pending = pthread_getspecific(pending_key);
    if (request == SACD_READ) {
        if (pending) pending->buf = NULL;
        if (rc >= 0 && arg->result == 0 && input.lsn == requested_lsn &&
            input.count == SECTORS && input.buf) {
            if (!pending) {
                pending = malloc(sizeof(*pending));
                if (pending && pthread_setspecific(pending_key, pending)) {
                    free(pending);
                    pending = NULL;
                }
            }
            if (pending) {
                memcpy(pending->raw, input.buf, RAW);
                pending->buf = input.buf;
            }
        }
        blog("RD fd=%d rc=%d in[lsn=%u cnt=%u buf=%p] post[res=%d lsn=%u cnt=%u buf=%p] "
             "want_lsn=%u match=%d pending=%p pbuf=%p\n",
             fd, rc, input.lsn, input.count, (void *)input.buf,
             arg->result, arg->lsn, arg->count, (void *)arg->buf,
             requested_lsn,
             (int)(rc >= 0 && arg->result == 0 && input.lsn == requested_lsn &&
                   input.count == SECTORS && input.buf != NULL),
             (void *)pending, pending ? pending->buf : NULL);
    } else if (pending) {
        int match = rc >= 0 && arg->result == 0 && input.count == SECTORS &&
                    input.buf && pending->buf == input.buf;
        void *pbuf_before = pending->buf;
        if (match)
            save_pair(pending->raw, input.buf);
        pending->buf = NULL;
        blog("DC fd=%d rc=%d in[cnt=%u buf=%p] post[res=%d cnt=%u buf=%p] "
             "match=%d pbuf=%p\n",
             fd, rc, input.count, (void *)input.buf,
             arg->result, arg->count, (void *)arg->buf,
             match, pbuf_before);
    } else {
        /* original: non-READ with no pending is a no-op — logged so a
         * decrypt-without-pending (e.g. different worker thread) is
         * visible instead of silent */
        blog("DC-no-pending fd=%d rc=%d in[cnt=%u buf=%p] post[res=%d buf=%p]\n",
             fd, rc, input.count, (void *)input.buf,
             arg->result, (void *)arg->buf);
    }
    errno = saved;
    return rc;
}
