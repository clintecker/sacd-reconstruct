/* bx510_lo_up.c — bring loopback up inside the minimal BX510 guest.
 *
 * The kernel registers 'lo' but leaves it DOWN; nothing in the minimal
 * init=/bin/sh boot brings it up, and ifconfig availability is unknown.
 * This helper does it deterministically with a raw ioctl (SIOCSIFFLAGS),
 * so the in-guest client can reach the daemon on 127.0.0.1:2002.
 *
 * Build: dynamic (guest loader proven); run: lo_up
 */
#include <arpa/inet.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>

int main(void)
{
    struct ifreq ifr;
    struct sockaddr_in *sin = (struct sockaddr_in *)&ifr.ifr_addr;
    int fd = socket(AF_INET, SOCK_DGRAM, 0);

    if (fd < 0) {
        perror("socket");
        return 1;
    }
    memset(&ifr, 0, sizeof(ifr));
    strcpy(ifr.ifr_name, "lo");
    sin->sin_family = AF_INET;
    sin->sin_addr.s_addr = inet_addr("127.0.0.1");
    if (ioctl(fd, SIOCSIFADDR, &ifr) < 0) {
        perror("SIOCSIFADDR");
        return 1;
    }
    ifr.ifr_flags = IFF_UP | IFF_RUNNING | IFF_LOOPBACK;
    if (ioctl(fd, SIOCSIFFLAGS, &ifr) < 0) {
        perror("SIOCSIFFLAGS");
        return 1;
    }
    if (ioctl(fd, SIOCGIFFLAGS, &ifr) < 0) {
        perror("SIOCGIFFLAGS");
        return 1;
    }
    printf("lo_up: flags=0x%x (%s)\n", ifr.ifr_flags,
           (ifr.ifr_flags & IFF_UP) ? "UP" : "down");
    return (ifr.ifr_flags & IFF_UP) ? 0 : 1;
}
