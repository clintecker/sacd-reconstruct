/* Guest-only test adapter for ARM32 glibc. Run through test_status.py.
 * Start at the daemon's real init and server_loop. Let its formatting, stdio
 * locks, device wrappers and libc execute normally. Four ELF symbol addresses
 * come from the unstripped executable under test. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <locale.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <wchar.h>

typedef int (*entry_fn)(int, char **, char **);
typedef void (*void_fn)(void);
typedef int (*start_fn)(entry_fn, int, char **, void_fn, void_fn, void_fn, void *);

static int disc_kind, probing, last_fd = -1, disc_queries, sacd_queries, sleeps;
static int *quit_flag;

/* This fixture requires a read-only open of just the SACD device. The real
 * close in the daemon releases the harmless descriptor we give it. */
int open64(const char *path, int flags, ...)
{
    if (!probing || strcmp(path, "/dev/sacd_read") || flags != O_RDONLY) {
        errno = ENOENT;
        return -1;
    }
    last_fd = open("/dev/null", O_RDONLY);
    return last_fd;
}

int ioctl(int fd, unsigned long command, ...)
{
    unsigned long *result;
    va_list ap;
    if (!probing || fd != last_fd ||
        (command != 0x40105306UL && command != 0x40105307UL)) {
        errno = ENOTTY;
        return -1;
    }
    /* Both status replies carry their signed result in the first 32-bit word. */
    va_start(ap, command);
    result = va_arg(ap, unsigned long *);
    va_end(ap);
    if (command == 0x40105306UL) {
        ++disc_queries;
        *result = disc_kind ? 0UL : (unsigned long)-1;
    } else {
        ++sacd_queries;
        *result = disc_kind == 2 ? 0UL : (unsigned long)-1;
    }
    return 0;
}

unsigned int sleep(unsigned int seconds)
{
    if (!probing || seconds != 1 || ++sleeps != 1)
        _exit(91);
    *quit_flag = 1;
    return 0;
}

static unsigned long address(const char *arg)
{
    char *end;
    unsigned long n = strtoul(arg, &end, 16);
    if (!n || *end)
        _exit(92);
    return n;
}

static int status_main(int argc, char **argv, char **envp)
{
    void_fn init_daemon, server_loop;
    int *connected;
    (void)envp;
    if (argc != 7) return 93;
    init_daemon = (void_fn)address(argv[1]);
    server_loop = (void_fn)address(argv[2]);
    connected = (int *)address(argv[3]);
    quit_flag = (int *)address(argv[4]);
    disc_kind = atoi(argv[5]);

    /* Follow the original startup calls needed for logging and wide stdout.
     * No listener thread, module-install code or shell command is entered. */
    init_daemon();
    *connected = atoi(argv[6]);
    if (!setlocale(LC_ALL, "C") || fwide(stdout, 1) <= 0) return 94;
    probing = 1;
    server_loop();
    probing = 0;
    if (fflush(stdout) || ferror(stdout)) return 95;
    return sleeps == 1 && disc_queries == 1 && sacd_queries == (disc_kind != 0) ? 0 : 96;
}

/* Preserve normal guest libc initialization, then substitute the test entry. */
int __libc_start_main(entry_fn main_fn, int argc, char **argv, void_fn init,
                      void_fn fini, void_fn rtld_fini, void *stack_end)
{
    start_fn real_start = (start_fn)dlsym(RTLD_NEXT, "__libc_start_main");
    (void)main_fn;
    if (!real_start) _exit(97);
    return real_start(status_main, argc, argv, init, fini, rtld_fini, stack_end);
}
