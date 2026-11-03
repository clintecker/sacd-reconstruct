/* bx510_guest_client.c — in-guest SACD daemon protocol client (loopback).
 *
 * Drives the daemon on 127.0.0.1:2002 with the verified nanopb wire format
 * (byte-identical to real nanopb, cross-checked against sacd_client.py in
 * the qemu-user rig): request = {1:type varint} {2:offset varint}
 * {3:count varint} 0x00; response = {1:type} {2:result, sign-extended
 * int64 varint} {3:data, length-delimited when present} 0x00.
 *
 * The transcript this prints (over stdout, captured to a file and the UART)
 * is the in-guest differential input: same steps against the original and
 * the release daemon must produce identical transcripts.
 *
 * Build: static.
 */
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <netinet/in.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <unistd.h>

#define REQ_DISC_OPEN 1
#define REQ_DISC_CLOSE 2
#define REQ_DISC_READ 3
#define REQ_DISC_SIZE 4

static uint8_t rbuf[512 * 1024];

static int wvarint(uint8_t *out, uint64_t v)
{
    int n = 0;
    do {
        out[n++] = (uint8_t)((v & 0x7f) | (v > 0x7f ? 0x80 : 0));
        v >>= 7;
    } while (v);
    return n;
}

static int send_request(int fd, uint64_t type, uint64_t off, uint64_t cnt)
{
    uint8_t req[32];
    int n = 0;
    req[n++] = 0x08; n += wvarint(req + n, type);
    req[n++] = 0x10; n += wvarint(req + n, off);
    req[n++] = 0x18; n += wvarint(req + n, cnt);
    req[n++] = 0x00;
    return (int)write(fd, req, n) == n ? 0 : -1;
}

/* returns consumed bytes, or -1 */
static long rvarint(const uint8_t *buf, long pos, long len, uint64_t *out)
{
    uint64_t v = 0;
    int shift = 0, count = 0;
    while (pos < len && count < 10) {
        uint8_t b = buf[pos++];
        v |= (uint64_t)(b & 0x7f) << shift;
        count++;
        if (!(b & 0x80)) {
            *out = v;
            return pos;
        }
        shift += 7;
    }
    return -1;
}

static int raw_fd = -1;

static int read_response(int fd, uint64_t *type, int64_t *result,
                         long *datalen)
{
    long len = 0;
    long pos = 0;
    uint64_t tag;

    if (raw_fd < 0)
        raw_fd = open("/res/gc-raw.bin", O_WRONLY | O_CREAT | O_TRUNC, 0644);

    *type = 0;
    *result = 0;
    *datalen = -1;
    for (;;) {
        if (len == pos) {
            long n = read(fd, rbuf + len, sizeof(rbuf) - len);
            if (n <= 0)
                return -1;
            if (raw_fd >= 0)
                write(raw_fd, rbuf + len, n);
            len += n;
        }
        long r = rvarint(rbuf, pos, len, &tag);
        if (r < 0)
            return -1;
        pos = r;
        if (tag == 0) {
            if (pos != len) {
                long i;
                printf("GC: parse: trailing %ld bytes; frame head:", len - pos);
                for (i = 0; i < len && i < 48; i++)
                    printf(" %02x", rbuf[i]);
                printf("\n");
                return -1;          /* trailing bytes: frame corruption */
            }
            return 0;
        }
        uint64_t field = tag >> 3, wire = tag & 7, v;
        r = rvarint(rbuf, pos, len, &v);
        if (r < 0) {
            printf("GC: parse: varint overrun at pos %ld len %ld head:", pos, len);
            { long i; for (i = 0; i < len && i < 48; i++) printf(" %02x", rbuf[i]); }
            printf("\n");
            return -1;
        }
        if (field == 1 && wire == 0) {
            *type = v;
            pos = r;
        } else if (field == 2 && wire == 0) {
            *result = (int64_t)v;  /* two's-complement wrap: bit 63 = negative */
            pos = r;
        } else if (field == 3 && wire == 2) {
            /* v = length; data follows. NB: r is the position AFTER the
             * length varint — assign before using pos (a two-byte slip
             * here made the parser eat the length varint as data and
             * choke on a mid-payload "tag"). */
            pos = r;
            while (len < pos + (long)v) {
                long n = read(fd, rbuf + len, sizeof(rbuf) - len);
                if (n <= 0)
                    return -1;
                if (raw_fd >= 0)
                    write(raw_fd, rbuf + len, n);
                len += n;
            }
            *datalen = (long)v;
            pos += (long)v;
        } else {
            long i;
            printf("GC: parse: unexpected field %llu wire %llu pos %ld len %ld\n",
                   (unsigned long long)field, (unsigned long long)wire, pos, len);
            printf("GC: bytes around pos:");
            for (i = pos - 12; i < len && i < pos + 12; i++)
                printf(" %02x@%ld", rbuf[i], i);
            printf("\n");
            return -1;
        }
    }
}

int main(int argc, char **argv)
{
    const char *host = argc > 1 ? argv[1] : "127.0.0.1";
    int port = argc > 2 ? atoi(argv[1]) : 2002;
    struct sockaddr_in a;
    struct timeval tv = { 20, 0 };
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    uint64_t type;
    int64_t result;
    long datalen;

    if (argc > 2)
        port = atoi(argv[2]);
    if (fd < 0) {
        perror("socket");
        return 1;
    }
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    memset(&a, 0, sizeof(a));
    a.sin_family = AF_INET;
    a.sin_port = htons((uint16_t)port);
    a.sin_addr.s_addr = inet_addr(host);
    if (connect(fd, (struct sockaddr *)&a, sizeof(a)) < 0) {
        perror("connect");
        return 1;
    }
    printf("GC: connected %s:%d\n", host, port);

    if (send_request(fd, REQ_DISC_OPEN, 0, 0) ||
        read_response(fd, &type, &result, &datalen))
        goto fail;
    printf("GC: OPEN  -> type=%llu result=%lld datalen=%ld\n",
           (unsigned long long)type, (long long)result, datalen);

    if (send_request(fd, REQ_DISC_SIZE, 0, 0) ||
        read_response(fd, &type, &result, &datalen))
        goto fail;
    printf("GC: SIZE  -> type=%llu result=%lld (sectors)\n",
           (unsigned long long)type, (long long)result);

    if (send_request(fd, REQ_DISC_READ, 0, 1) ||
        read_response(fd, &type, &result, &datalen))
        goto fail;
    printf("GC: READ lsn=0 cnt=1 -> type=%llu result=%lld datalen=%ld\n",
           (unsigned long long)type, (long long)result, datalen);
    if (datalen > 0) {
        long i;
        printf("GC: data[0..15]:");
        for (i = 7; i < 7 + 16 && i < 512 * 1024; i++)
            printf(" %02x", rbuf[i]);
        printf("\n");
    }

    if (send_request(fd, REQ_DISC_READ, 43100, 1) ||
        read_response(fd, &type, &result, &datalen))
        goto fail;
    printf("GC: READ lsn=43100 cnt=1 -> type=%llu result=%lld datalen=%ld\n",
           (unsigned long long)type, (long long)result, datalen);

    if (send_request(fd, REQ_DISC_CLOSE, 0, 0) ||
        read_response(fd, &type, &result, &datalen))
        goto fail;
    printf("GC: CLOSE -> type=%llu result=%lld\n",
           (unsigned long long)type, (long long)result);

    /* the daemon closes the connection after DISC_CLOSE */
    {
        long n = read(fd, rbuf, 1);
        printf("GC: post-close read -> %ld (%s)\n", n,
               n == 0 ? "EOF" : n < 0 ? strerror(errno) : "data?");
    }
    close(fd);
    printf("GC: DONE\n");
    return 0;
fail:
    printf("GC: FAIL at step (errno=%s)\n", strerror(errno));
    {
        long n, i;
        printf("GC: rawdump:");
        n = recv(fd, rbuf, 256, MSG_DONTWAIT);
        if (n <= 0)
            printf(" (nothing more: %s)", n == 0 ? "EOF" : strerror(errno));
        else
            for (i = 0; i < n && i < 64; i++)
                printf(" %02x", rbuf[i]);
        printf("\n");
    }
    close(fd);
    return 1;
}
