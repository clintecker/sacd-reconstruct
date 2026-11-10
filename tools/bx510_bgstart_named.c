/*
 * bx510_bgstart_named.c — fork-exec launcher with per-daemon log path.
 *
 * Problem (VERIFIED, see tools/bx510_bgstart.c): the init=/bin/sh guest has no
 * /dev, so Sony's /bin/sh cannot run background jobs (it tries to open
 * /dev/null). This helper runs as a foreground command, forks, redirects the
 * child's stdio to a caller-supplied /res path, and execs the daemon.
 *
 * This variant is for multi-daemon experiments (SaWMan coexistence): the
 * original bx510_bgstart.c always writes /res/daemon.out, which would clobber
 * logs when two clients are launched concurrently.
 *
 * Usage:
 *   bgstart_named --out /res/app.out /abs/daemon arg...
 *
 * Notes:
 * - Expects /res/tmp to exist (tmpfs), and /res/zero to exist (any file).
 * - Sets TMPDIR=/res/tmp and a default PATH for execvp/system() consumers.
 */
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void usage(void) {
    fprintf(stderr, "usage: bgstart_named --out /res/out.txt daemon [arg...]\n");
}

int main(int argc, char **argv)
{
    const char *out = "/res/daemon.out";
    int i = 1;
    pid_t pid;
    int fd;

    if (argc < 2) {
        usage();
        return 2;
    }

    if (i + 1 < argc && !strcmp(argv[i], "--out")) {
        out = argv[i + 1];
        i += 2;
    }

    if (i >= argc) {
        usage();
        return 2;
    }

    pid = fork();
    if (pid < 0) {
        perror("fork");
        return 1;
    }

    if (pid == 0) {
        setenv("TMPDIR", "/res/tmp", 1);
        setenv("PATH", "/sbin:/usr/sbin:/bin:/usr/bin", 0);

        fd = open(out, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd >= 0) {
            dup2(fd, 1);
            dup2(fd, 2);
        }
        fd = open("/res/zero", O_RDONLY);
        if (fd >= 0)
            dup2(fd, 0);

        execv(argv[i], &argv[i]);
        _exit(127);
    }

    printf("BG_PID=%d\n", pid);
    fflush(stdout);
    return 0;
}
