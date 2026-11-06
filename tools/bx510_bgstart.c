/* bgstart.c — fork-exec launcher for the RO-root BX510 guest.
 *
 * Sony's /bin/sh aborts any background job at /dev/null open (the squashfs
 * root has no /dev at all), so `daemon -S ... &` can never work in the
 * minimal init=/bin/sh boot. This helper runs as a foreground command,
 * forks, points the child's stdio at /res files, and execs the daemon —
 * the parent returns immediately, so the prompt comes back while the
 * daemon serves on. LD_PRELOAD set in the environment propagates through
 * execv to the daemon (and onward through its system() children).
 *
 * TMPDIR is set to /res/tmp because the guest rootfs has no usable temp
 * dir at all: glibc's tmpnam() validates its candidates, finds none, and
 * fails — leaving the daemon's strcpy("/tmp/") as the path, which opens
 * EISDIR (observed: "install_modules: open filed ffffffeb"). Pointing
 * TMPDIR at existing tmpfs restores the real-player behavior (module
 * staged in a writable temp dir) without touching the daemon. The only
 * divergence: the module file's location, not its content or logic.
 *
 * Build static (-static) so it needs nothing from the guest loader.
 * Usage: bgstart /abs/daemon arg...
 */
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    pid_t pid;
    int fd;

    if (argc < 2) {
        fprintf(stderr, "usage: bgstart daemon [arg...]\n");
        return 2;
    }
    pid = fork();
    if (pid < 0) {
        perror("fork");
        return 1;
    }
    if (pid == 0) {
        setenv("TMPDIR", "/res/tmp", 1);
        /* The release-next daemon's run_loader() execvp("insmod", ...)
         * resolves through the environment's PATH; the minimal
         * init=/bin/sh console exports no PATH (busybox finds commands via
         * its internal default, which is why the frozen original's
         * system()-through-sh install works), so execvp fails ENOENT and
         * install_modules reports "insmod did not load the module"
         * (observed live in the gate4-enhanced battery). A real player's
         * init scripts export PATH; give the daemon busybox's default.
         * setenv overwrite=0: an inherited PATH wins. */
        setenv("PATH", "/sbin:/usr/sbin:/bin:/usr/bin", 0);
        /* Sony's /bin/mknod is statically linked (no LD_PRELOAD), so the
         * daemon's own `mknod /dev/sacd_read` cannot be redirected to
         * tmpfs. Create the misc 10:201 node here; install_modules ignores
         * the mknod result and only checks open("/dev/sacd_read"), which
         * the shim redirects to this node. Open still goes through the
         * kernel misc core: ENXIO unless the real module registered 201. */
        mknod("/res/dev/sacd_read", S_IFCHR | 0666, makedev(10, 201));
        fd = open("/res/daemon.out", O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd >= 0) {
            dup2(fd, 1);
            dup2(fd, 2);
        }
        fd = open("/res/zero", O_RDONLY);
        if (fd >= 0)
            dup2(fd, 0);
        execv(argv[1], &argv[1]);
        _exit(127); /* exec failed */
    }
    printf("BG_PID=%d\n", pid);
    return 0;
}
