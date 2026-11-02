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

/* The reference STT_OBJECT for mod_file occupies 26 bytes. */
static char mod_file[26];

int install_modules(void)
{
    int fd;
    int result = 0;
    size_t mod_size = (char *) &_binary_sacd_read_ko_end - (char *) &_binary_sacd_read_ko_start;

    strcpy(mod_file, "/tmp/");
    tmpnam(mod_file);

    fd = open64(mod_file, O_WRONLY | O_CREAT | O_TRUNC);

    if (fd >= 0)
    {
        if (write(fd, &_binary_sacd_read_ko_start, mod_size) == (ssize_t)mod_size)
        {
            close(fd);
            system("mknod -m0666 /dev/sacd_read c 10 201");
            {
                char cmd[512];
                sprintf(cmd, "insmod %s minor=201", mod_file);
                system(cmd);
            }
            unlink(mod_file);
            fd = open64("/dev/sacd_read", 0);
            if (fd >= 0)
            {
                close(fd);
            }
            else
            {
                LOG(lm_main, LOG_ERROR, ("%s: mknod/insmod filed", __func__));
                remove_modules();
                result = -1;
            }
        }
        else
        {
            result = -errno;
            LOG(lm_main, LOG_ERROR, ("%s: write filed %x", __func__, result));
        }
    }
    else
    {
        result = -errno;
        LOG(lm_main, LOG_ERROR, ("%s: open filed %x", __func__, result));
    }
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
        LOG(lm_main, LOG_ERROR, ("%s: rmmod filed", __func__));
    }

    system("rm -rf /dev/sacd_read");
}
