/* bx510_guest_client.c — in-guest SACD daemon protocol client (loopback).
 * Every data payload is hashed (FNV-1a 64) so a transcript diff between
 * runs IS the strict comparison: same steps, same results, same lengths,
 * same payload hashes.
 *
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

static unsigned long long fnv1a64(const uint8_t *p, long n)
{
    unsigned long long h = 0xcbf29ce484222325ULL;
    long i;
    for (i = 0; i < n; i++) {
        h ^= p[i];
        h *= 0x100000001b3ULL;
    }
    return h;
}

static int wvarint(uint8_t *out, uint64_t v)
{
    int n = 0;
    do {
        out[n++] = (uint8_t)((v & 0x7f) | (v > 0x7f ? 0x80 : 0));
        v >>= 7;
    } while (v);
    return n;
}

static int tx_fd = -1;

static int send_request(int fd, uint64_t type, uint64_t off, uint64_t cnt)
{
    uint8_t req[32];
    int n = 0;
    req[n++] = 0x08; n += wvarint(req + n, type);
    req[n++] = 0x10; n += wvarint(req + n, off);
    req[n++] = 0x18; n += wvarint(req + n, cnt);
    req[n++] = 0x00;
    /* full both-direction raw capture: log transmitted bytes too
     * (received bytes go to gc-raw.bin via raw_fd in read_response) */
    if (tx_fd < 0)
        tx_fd = open("/res/gc-tx.bin", O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (tx_fd >= 0)
        write(tx_fd, req, n);
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
/* offset of the data payload within rbuf for the most recent response —
 * NOT constant: the header length varies with the result/length varint
 * sizes (result=128 encodes as 2 bytes -> 9-byte header). Hashing or
 * dumping from a hardcoded offset corrupts the check, not the data. */
static long g_payload_off = 7;

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
            g_payload_off = r;
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
    printf("GC: READ lsn=0 cnt=1 -> type=%llu result=%lld datalen=%ld fnv1a64=%016llx\n",
           (unsigned long long)type, (long long)result, datalen,
           datalen > 0 ? fnv1a64(rbuf + g_payload_off, datalen) : 0ULL);
    if (datalen > 0) {
        long i;
        printf("GC: data[0..15]:");
        for (i = g_payload_off; i < g_payload_off + 16 && i < 512 * 1024; i++)
            printf(" %02x", rbuf[i]);
        printf(" fnv1a64=%016llx\n", fnv1a64(rbuf + g_payload_off, datalen));
    }
    /* (hash also appears on the READ line for uniform gate parsing) */

    if (send_request(fd, REQ_DISC_READ, 43100, 1) ||
        read_response(fd, &type, &result, &datalen))
        goto fail;
    printf("GC: READ lsn=43100 cnt=1 -> type=%llu result=%lld datalen=%ld fnv1a64=%016llx\n",
           (unsigned long long)type, (long long)result, datalen,
           datalen > 0 ? fnv1a64(rbuf + g_payload_off, datalen) : 0ULL);

    /* 128-sector read at the start of the unencrypted zone: exercises
     * MAX_PROCESSING_BLOCK_SIZE and the module's multi-block frame path
     * (2064*128 raw -> 128 logical on the wire). */
    if (send_request(fd, REQ_DISC_READ, 0, 128) ||
        read_response(fd, &type, &result, &datalen))
        goto fail;
    printf("GC: READ lsn=0 cnt=128 -> type=%llu result=%lld datalen=%ld fnv1a64=%016llx\n",
           (unsigned long long)type, (long long)result, datalen,
           datalen > 0 ? fnv1a64(rbuf + g_payload_off, datalen) : 0ULL);

    /* dump the 128-block payload for offline analysis */
    if (datalen > 0) {
        int df = open("/res/p128.bin", O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (df >= 0) {
            write(df, rbuf + g_payload_off, datalen);
            close(df);
        }
    }

    /* encryption-boundary clamp: the fixture's encrypted range starts at
     * 80000, so a 20-sector read at 79990 must return exactly 10 blocks
     * (unencrypted side) per the daemon's boundary logic. */
    if (send_request(fd, REQ_DISC_READ, 79990, 20) ||
        read_response(fd, &type, &result, &datalen))
        goto fail;
    printf("GC: READ lsn=79990 cnt=20 (boundary) -> type=%llu result=%lld datalen=%ld fnv1a64=%016llx\n",
           (unsigned long long)type, (long long)result, datalen,
           datalen > 0 ? fnv1a64(rbuf + g_payload_off, datalen) : 0ULL);

    /* encrypted-range read: 80000 is inside the fixture's encrypted
     * range; the module's decrypt path fires (mock plaintext copy) and
     * the wire payload must equal the fixture's logical bytes. */
    if (send_request(fd, REQ_DISC_READ, 80000, 2) ||
        read_response(fd, &type, &result, &datalen))
        goto fail;
    printf("GC: READ lsn=80000 cnt=2 (encrypted) -> type=%llu result=%lld datalen=%ld fnv1a64=%016llx\n",
           (unsigned long long)type, (long long)result, datalen,
           datalen > 0 ? fnv1a64(rbuf + g_payload_off, datalen) : 0ULL);

    /* beyond-EOF probe (module-level failure test): 86200 sectors, so
     * LSN 86300 is past the end; expect a non-positive result */
    if (send_request(fd, REQ_DISC_READ, 86300, 1) ||
        read_response(fd, &type, &result, &datalen))
        goto fail;
    printf("GC: READ lsn=86300 (beyond EOF) -> type=%llu result=%lld datalen=%ld\n",
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
    sleep(1);

    /* reconnect: the daemon must accept a fresh session after CLOSE */
    fd = socket(AF_INET, SOCK_STREAM, 0);
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    if (connect(fd, (struct sockaddr *)&a, sizeof(a)) < 0) {
        perror("GC: reconnect connect");
        return 1;
    }
    printf("GC: reconnected\n");
    if (send_request(fd, REQ_DISC_OPEN, 0, 0) ||
        read_response(fd, &type, &result, &datalen))
        goto fail2;
    printf("GC: OPEN#2 -> type=%llu result=%lld\n",
           (unsigned long long)type, (long long)result);
    if (send_request(fd, REQ_DISC_READ, 43100, 1) ||
        read_response(fd, &type, &result, &datalen))
        goto fail2;
    printf("GC: READ#2 lsn=43100 -> type=%llu result=%lld datalen=%ld fnv1a64=%016llx\n",
           (unsigned long long)type, (long long)result, datalen,
           datalen > 0 ? fnv1a64(rbuf + g_payload_off, datalen) : 0ULL);
    if (send_request(fd, REQ_DISC_CLOSE, 0, 0) ||
        read_response(fd, &type, &result, &datalen))
        goto fail2;
    printf("GC: CLOSE#2 -> type=%llu result=%lld\n",
           (unsigned long long)type, (long long)result);
    close(fd);

    /* reconnect sweep (distinct from daemon-restart/TIME_WAIT): fresh
     * connections to the SAME listener, varying the delay after close,
     * recording source ports to characterize session cleanup and the
     * conn_s race without address-reuse effects. */
    {
        int delays_ms[4] = { 0, 100, 300, 1000 };
        int k;
        int att;
        for (att = 0; att < 3; att++) {
        for (k = 0; k < 4; k++) {
            struct sockaddr_in me;
            socklen_t melen = sizeof(me);
            int f2 = socket(AF_INET, SOCK_STREAM, 0);
            uint64_t t;
            int64_t rr;
            long dl;
            setsockopt(f2, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
            usleep(delays_ms[k] * 1000);
            if (connect(f2, (struct sockaddr *)&a, sizeof(a)) < 0) {
                printf("GC: SWEEP delay=%dms att=%d CLASS=connect-err errno=%d (%s)\n",
                       delays_ms[k], att, errno, strerror(errno));
                close(f2);
                continue;
            }
            memset(&me, 0, sizeof(me));
            getsockname(f2, (struct sockaddr *)&me, &melen);
            if (send_request(f2, REQ_DISC_OPEN, 0, 0)) {
                printf("GC: SWEEP delay=%dms att=%d port=%u CLASS=send-err errno=%d (%s)\n",
                       delays_ms[k], att, ntohs(me.sin_port), errno, strerror(errno));
            } else if (read_response(f2, &t, &rr, &dl)) {
                long n = recv(f2, rbuf, 16, MSG_DONTWAIT);
                if (n == 0)
                    printf("GC: SWEEP delay=%dms att=%d port=%u CLASS=eof\n",
                           delays_ms[k], att, ntohs(me.sin_port));
                else if (n < 0)
                    printf("GC: SWEEP delay=%dms att=%d port=%u CLASS=read-err errno=%d (%s)\n",
                           delays_ms[k], att, ntohs(me.sin_port), errno, strerror(errno));
                else
                    printf("GC: SWEEP delay=%dms att=%d port=%u CLASS=parse-fail head=%02x%02x%02x%02x\n",
                           delays_ms[k], att, ntohs(me.sin_port),
                           rbuf[0], rbuf[1], rbuf[2], rbuf[3]);
            } else {
                printf("GC: SWEEP delay=%dms att=%d port=%u CLASS=ok OPEN type=%lld result=%lld\n",
                       delays_ms[k], att, ntohs(me.sin_port), (long long)t, (long long)rr);
            }
            close(f2);
        }
        }
    }
    printf("GC: DONE\n");
    return 0;
fail2:
    printf("GC: FAIL at reconnect step (%s)\n", strerror(errno));
    close(fd);
    return 1;
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
