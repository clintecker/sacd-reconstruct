/**
 * sacd_read.c - userspace wrappers for the sacd_read.ko Mediatek kernel
 * module (CPSA SACD copy-protection driver).
 *
 * Community port addition ("sacd_extract_160"). Every command talks to
 * /dev/sacd_read (misc device minor 201, installed by install_modules)
 * with a 16-byte ioctl argument; the first word of the argument carries
 * the result of the command.
 */

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>

#include "sacd_read.h"

#define SACD_READ_DEVICE "/dev/sacd_read"

#define SACD_IOC_INIT     0x40105301
#define SACD_IOC_AUTH     0x40105302
#define SACD_IOC_READ     0x40105303
#define SACD_IOC_DECRYPT  0x40105304
#define SACD_IOC_UNINIT   0x40105305
#define SACD_IOC_DISC     0x40105306
#define SACD_IOC_SACD     0x40105307

struct sacd_read_ioc
{
    unsigned long a;
    unsigned long b;
    unsigned long c;
    unsigned long d;
};

int init_sacd(void)
{
    int fd;
    int result = -1;
    struct sacd_read_ioc ioc;

    memset(&ioc, 0, sizeof(ioc));

    fd = open64(SACD_READ_DEVICE, 0);
    if (fd >= 0)
    {
        if (ioctl(fd, SACD_IOC_INIT, &ioc) >= 0)
            result = ioc.a;
        close(fd);
    }
    return result;
}

int auth_sacd(void)
{
    int fd;
    int result = -1;
    struct sacd_read_ioc ioc;

    memset(&ioc, 0, sizeof(ioc));

    fd = open64(SACD_READ_DEVICE, 0);
    if (fd >= 0)
    {
        if (ioctl(fd, SACD_IOC_AUTH, &ioc) >= 0)
            result = ioc.a;
        close(fd);
    }
    return result;
}

int read_sacd(int a, int b, void *c)
{
    int fd;
    int result = -1;
    struct sacd_read_ioc ioc;

    memset(&ioc, 0, sizeof(ioc));

    fd = open64(SACD_READ_DEVICE, 0);
    if (fd >= 0)
    {
        ioc.b = a;
        ioc.c = b;
        ioc.d = c;
        if (ioctl(fd, SACD_IOC_READ, &ioc) >= 0)
            result = ioc.a;
        close(fd);
    }
    return result;
}

void uninit_sacd(void)
{
    struct sacd_read_ioc ioc;
    int fd;

    memset(&ioc, 0, sizeof(ioc));

    fd = open64(SACD_READ_DEVICE, 0);
    if (fd >= 0)
    {
        ioctl(fd, SACD_IOC_UNINIT, &ioc);
        close(fd);
    }
}

int decrypt_sacd(int a, void *b)
{
    int fd;
    int result = -1;
    struct sacd_read_ioc ioc;

    memset(&ioc, 0, sizeof(ioc));

    fd = open64(SACD_READ_DEVICE, 0);
    if (fd >= 0)
    {
        ioc.c = a;
        ioc.d = b;
        if (ioctl(fd, SACD_IOC_DECRYPT, &ioc) >= 0)
            result = ioc.a;
        close(fd);
    }
    return result;
}

int disc_sacd(void)
{
    int fd;
    int result = -1;
    struct sacd_read_ioc ioc;

    memset(&ioc, 0, sizeof(ioc));

    fd = open64(SACD_READ_DEVICE, 0);
    if (fd >= 0)
    {
        if (ioctl(fd, SACD_IOC_DISC, &ioc) >= 0)
            result = ioc.a;
        close(fd);
    }
    return result;
}

int sacd_sacd(void)
{
    int fd;
    int result = -1;
    struct sacd_read_ioc ioc;

    memset(&ioc, 0, sizeof(ioc));

    fd = open64(SACD_READ_DEVICE, 0);
    if (fd >= 0)
    {
        if (ioctl(fd, SACD_IOC_SACD, &ioc) >= 0)
            result = ioc.a;
        close(fd);
    }
    return result;
}
