/**
 * Module installation for the Mediatek SACD read kernel module.
 *
 * Community port addition ("sacd_extract_160"): extracts the embedded
 * sacd_read.ko (linked in via `ld -b binary`), installs it with insmod
 * and creates the /dev/sacd_read character device node.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#include <logging.h>

#include "install.h"

/* embedded kernel module, produced from sacd_read.ko with `ld -b binary` */
extern char _binary_sacd_read_ko_start;
extern char _binary_sacd_read_ko_end;

static char mod_file[L_tmpnam];

int install_modules(void)
{
    int fd;
    int result = 0;
    int mod_size = (char *) &_binary_sacd_read_ko_end - (char *) &_binary_sacd_read_ko_start;

    memcpy(mod_file, "/tmp/", 6);
    tmpnam(mod_file);

    fd = open64(mod_file, O_WRONLY | O_CREAT | O_TRUNC);
    if (fd < 0)
        goto err_open;

    if (write(fd, &_binary_sacd_read_ko_start, mod_size) != mod_size)
        goto err_write;
    close(fd);

    system("mknod -m0666 /dev/sacd_read c 10 201");

    {
        char cmd[512];
        sprintf(cmd, "insmod %s minor=201", mod_file);
        system(cmd);
    }

    unlink(mod_file);

    fd = open64("/dev/sacd_read", 0);
    if (fd < 0)
        goto err_mknod;

    close(fd);
    return result;

err_mknod:
    LOG(lm_main, LOG_ERROR, ("%s: mknod/insmod filed", "install_modules"));
    remove_modules();
    result = -1;
    return result;

err_write:
    result = -errno;
    LOG(lm_main, LOG_ERROR, ("%s: write filed %x", "install_modules", result));
    return result;

err_open:
    result = -errno;
    LOG(lm_main, LOG_ERROR, ("%s: open filed %x", "install_modules", result));
    return result;
}

void remove_modules(void)
{
    int fd;

    system("rmmod sacd_read");

    fd = open64("/dev/sacd_read", 0);
    if (fd >= 0)
    {
        close(fd);
        LOG(lm_main, LOG_ERROR, ("%s: rmmod filed", "remove_modules"));
    }

    system("rm -rf /dev/sacd_read");
}
