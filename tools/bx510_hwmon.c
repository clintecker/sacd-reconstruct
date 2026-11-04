/*
 * bx510_hwmon.c — standby/transition watcher for the on-player session.
 *
 * Purpose (docs/ui-graphics-reconstruction.md §standby): the operator
 * observes that pressing power blanks the screen and retracts the tray
 * while the SACD daemon keeps serving. Firmware evidence (bdpprog's
 * ResumeInfo machinery, the .rel apps' sysStandbyHandler/
 * sysResumeHandler message handlers) says standby is PAUSE, not death —
 * but that is inference. This tool converts it to runtime evidence:
 * it snapshots the process table, loaded modules, TCP listeners, and
 * display/fusion state to the USB stick on a continuous timeline, so
 * the before/after of the power press is captured regardless of what
 * the appliance manager does to the watcher itself. (If snapshots
 * STOP at the press and never resume, that is itself a datum about
 * what the standby sequence kills.)
 *
 * Build: gnuarm toolchain, dynamic (player glibc 2.12 runs our 2.9-era
 * binaries). Run: one line from the AutoScript:
 *     /bin/sh /mnt/sda1/hwmon_start.sh
 * (helper script on the stick; see sacd_hardware.sh usb-build)
 *
 * Output: <stick>/hwmon/snap-<seq>-<uptime>.txt
 */
#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <time.h>
#include <unistd.h>

#define SNAP_INTERVAL 5

static int snapshot(const char *outdir, int seq)
{
    char path[512];
    FILE *out, *in;
    char line[1024];
    struct timespec ts;

    clock_gettime(CLOCK_MONOTONIC, &ts);
    snprintf(path, sizeof path, "%s/snap-%04d-%ld.txt", outdir, seq,
             (long)ts.tv_sec);
    out = fopen(path, "w");
    if (!out)
        return -1;

    fprintf(out, "seq %d uptime_mono %ld\n", seq, (long)ts.tv_sec);

    /* process table with cmdlines (also captures whether bdpprog is
     * alive, and what the daemon is doing) */
    fprintf(out, "--- processes ---\n");
    DIR *d = opendir("/proc");
    struct dirent *e;
    while ((e = readdir(d))) {
        char cmd[300];
        if (e->d_name[0] < '0' || e->d_name[0] > '9')
            continue;
        snprintf(cmd, sizeof cmd, "/proc/%s/cmdline", e->d_name);
        in = fopen(cmd, "r");
        if (!in)
            continue;
        size_t n = fread(line, 1, sizeof line - 1, in);
        fclose(in);
        if (n == 0)
            continue;
        line[n] = 0;
        for (size_t i = 0; i < n; i++)
            if (line[i] == 0)
                line[i] = ' ';
        fprintf(out, "%s %s\n", e->d_name, line);
    }
    closedir(d);

    fprintf(out, "--- modules ---\n");
    in = fopen("/proc/modules", "r");
    if (in) {
        while (fgets(line, sizeof line, in))
            fputs(line, out);
        fclose(in);
    }

    fprintf(out, "--- tcp listeners ---\n");
    in = fopen("/proc/net/tcp", "r");
    if (in) {
        while (fgets(line, sizeof line, in))
            fputs(line, out);
        fclose(in);
    }

    /* fusion world state: presence of the shared-memory files says the
     * DirectFB multi-app world survived; holders of /dev/fb* say who
     * owns the display */
    fprintf(out, "--- /dev/shm ---\n");
    d = opendir("/dev/shm");
    if (d) {
        while ((e = readdir(d)))
            fprintf(out, "%s\n", e->d_name);
        closedir(d);
    } else {
        fprintf(out, "(no /dev/shm)\n");
    }

    fprintf(out, "--- display/fusion device holders ---\n");
    d = opendir("/proc");
    while ((e = readdir(d))) {
        char fdpath[300];
        if (e->d_name[0] < '0' || e->d_name[0] > '9')
            continue;
        snprintf(fdpath, sizeof fdpath, "/proc/%s/fd", e->d_name);
        DIR *fd = opendir(fdpath);
        if (!fd)
            continue;
        struct dirent *f;
        while ((f = readdir(fd))) {
            char link[400], target[400];
            snprintf(link, sizeof link, "%s/%s", fdpath, f->d_name);
            ssize_t n = readlink(link, target, sizeof target - 1);
            if (n <= 0)
                continue;
            target[n] = 0;
            if (strstr(target, "/dev/fb") || strstr(target, "/dev/fusion") ||
                strstr(target, "/dev/tty") || strstr(target, "/dev/vc"))
                fprintf(out, "pid %s holds %s\n", e->d_name, target);
        }
        closedir(fd);
    }
    closedir(d);

    fclose(out);
    return 0;
}

int main(int argc, char **argv)
{
    const char *outdir = argc > 1 ? argv[1] : "/mnt/sda1/hwmon";
    /* argv[2]: optional RAM backup dir (/tmp/hwmon). The stick may UNMOUNT
     * at sleep on real players (the scene recipe copies the daemon to /
     * for exactly this reason), so every snapshot is also written to a
     * RAM dir that survives sleep; hwmon_restore.sh copies it back to the
     * stick on the next AutoScript trigger. */
    const char *bakdir = argc > 2 ? argv[2] : NULL;
    int seq = 0;
    char pidfile[512];

    mkdir(outdir, 0755);
    snprintf(pidfile, sizeof pidfile, "%s/hwmon.pid", outdir);
    FILE *pf = fopen(pidfile, "w");
    if (pf) {
        fprintf(pf, "%d\n", getpid());
        fclose(pf);
    }
    fprintf(stderr, "hwmon: watching, snapshots -> %s every %ds\n",
            outdir, SNAP_INTERVAL);
    if (bakdir)
        mkdir(bakdir, 0755);
    for (;;) {
        snapshot(outdir, seq);
        if (bakdir)
            snapshot(bakdir, seq);
        seq++;
        sleep(SNAP_INTERVAL);
    }
    return 0;
}
