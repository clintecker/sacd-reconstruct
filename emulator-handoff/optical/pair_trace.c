/* Observe one successful ioctl pair in the original 32-bit ARM daemon.
 * SPDX-License-Identifier: GPL-2.0-or-later */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syscall.h>
#include <unistd.h>

#define SACD_READ    0x40105303UL
#define SACD_DECRYPT 0x40105304UL
enum { SECTORS = 2, RAW = 2064 * SECTORS, LOGICAL = 2048 * SECTORS };

struct sacd_arg { int32_t result; uint32_t lsn, count; unsigned char *buf; };
_Static_assert(sizeof(struct sacd_arg) == 16, "requires the player ARM32 ABI");
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

static void configure(void)
{
    int saved = errno;
    ioctl_fn next = (ioctl_fn)dlsym(RTLD_NEXT, "ioctl");
    const char *path = getenv("BX510_PAIR_OUT"), *lsn = getenv("BX510_PAIR_LSN");
    if (next) next_ioctl = next;
    if (next && path && path[0] == '/' && lsn && *lsn >= '0' && *lsn <= '9' &&
        program_invocation_short_name && !strcmp(program_invocation_short_name, "sacd_extract_160")) {
        char *end;
        errno = 0;
        unsigned long n = strtoul(lsn, &end, 10);
        if (!errno && !*end && n < UINT32_MAX && pthread_key_create(&pending_key, free) == 0) {
            requested_lsn = n;
            output = path;
        }
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
    if (fd < 0) return;
    int failed = write_all(fd, &header, sizeof(header)) || write_all(fd, raw, RAW) ||
                 write_all(fd, logical, LOGICAL) || fsync(fd);
    if (close(fd) || failed) unlink(output);
}

__attribute__((visibility("hidden")))
int bx_observe_ioctl(int fd, unsigned long request, struct sacd_arg *arg)
{
    ioctl_fn next = bx_next_ioctl();
    if (!output || !arg) return next(fd, request, arg);
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
    } else if (pending) {
        if (rc >= 0 && arg->result == 0 && input.count == SECTORS &&
            input.buf && pending->buf == input.buf)
            save_pair(pending->raw, input.buf);
        pending->buf = NULL;
    }
    errno = saved;
    return rc;
}
