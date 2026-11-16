/* sacdclient.c — guest-side client for the BX510 SACD daemon (port 2002).
 *
 * Wire protocol per decode/daemon-socket-protocol.md (VERIFIED against the
 * original binary's disassembly + the repo's pb_decode.c): nanopb protobuf
 * messages, one 0x00 terminator after EVERY message both directions, no
 * length prefix. Ops: 1=OPEN 2=CLOSE 3=READ 4=SIZE. DISC_READ chunks at
 * 128 sectors (MAX_PROCESSING_BLOCK_SIZE). result is a 64-bit two's
 * complement varint (so -1 encodes as 10 bytes ff ff ... 01).
 *
 * Built with the era toolchain on the build host; stdio-less success path so it
 * runs on the guest's busybox shell which has no tr/od/cut (C117 lesson):
 * all verdicts go through md5sum + shell-exit codes.
 *
 * Usage: sacdclient HOST LBA COUNT [OUTFILE]
 *   reads COUNT sectors at LBA from the daemon at HOST:2002, writes them to
 *   OUTFILE (default /tmp/sacdclient.bin), exits 0 iff every response was
 *   well-formed and every expected byte landed. Prints one line per step.
 */
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#define PORT 2002
#define MAX_CHUNK 128          /* MAX_PROCESSING_BLOCK_SIZE (protocol §3) */
#define SECTOR 2048

static int sock_fd = -1;

static void die(const char *what)
{
    fprintf(stderr, "FAIL %s: %s\n", what, strerror(errno));
    exit(1);
}

/* ── varint helpers (encoding + decoding, both directions) ─────────────── */

static void put_varint(uint64_t v, unsigned char **p)
{
    while (v > 0x7f) {
        *(*p)++ = (unsigned char)(v & 0x7f) | 0x80;
        v >>= 7;
    }
    *(*p)++ = (unsigned char)v;
}

/* Read one varint from the socket; returns the value. Dies on EOF. */
static uint64_t read_varint(void)
{
    uint64_t v = 0;
    int shift = 0;
    for (;;) {
        unsigned char b;
        ssize_t n = recv(sock_fd, &b, 1, 0);
        if (n != 1)
            die("varint read (daemon closed mid-message)");
        v |= (uint64_t)(b & 0x7f) << shift;
        if (!(b & 0x80))
            return v;
        shift += 7;
    }
}

/* Read exactly n bytes into buf (MSG_WAITALL, per the daemon's own receive). */
static void read_exact(void *buf, size_t n)
{
    unsigned char *p = buf;
    size_t got = 0;
    while (got < n) {
        ssize_t r = recv(sock_fd, p + got, n - got, 0);
        if (r <= 0)
            die("data read (short reply)");
        got += (size_t)r;
    }
}

/* ── message layer ─────────────────────────────────────────────────────── */

/* Build a request: field1=type varint, field2=off varint, field3=cnt varint,
 * then the 0x00 terminator (tag 0 encodes as a bare 0x00 byte). */
static void send_request(int op, uint64_t off, uint64_t cnt)
{
    unsigned char buf[32];
    unsigned char *p = buf;
    *p++ = 0x08; put_varint((uint64_t)op, &p);
    *p++ = 0x10; put_varint(off, &p);
    *p++ = 0x18; put_varint(cnt, &p);
    *p++ = 0x00;                                  /* the terminator */
    if (send(sock_fd, buf, (size_t)(p - buf), 0) < 0)
        die("send request");
}

/* Response: fields until the 0x00 terminator.
 *   type   (field 1, varint)      -> *out_type
 *   result (field 2, varint)      -> *out_result (two's complement 64-bit)
 *   data   (field 3, length-delim) -> malloc'd buffer, caller frees; NULL if
 *                                   absent. Returns the byte count via *out_len.
 * Returns 0 on success, -1 on a malformed field (unexpected wire type). */
static int read_response(int *out_type, int64_t *out_result,
                         unsigned char **out_data, uint32_t *out_len)
{
    uint32_t len = 0;
    unsigned char *data = NULL;
    int type = -1;
    int64_t result = 0;

    for (;;) {
        unsigned tag = (unsigned)read_varint();
        if (tag == 0) {                            /* the terminator */
            *out_type = type; *out_result = result;
            *out_data = data; *out_len = len;
            return 0;
        }
        switch (tag & 7) {
        case 0: {                                   /* varint */
            uint64_t v = read_varint();
            if ((tag >> 3) == 1)
                type = (int)v;
            else if ((tag >> 3) == 2)
                result = (int64_t)v;                /* two's complement cast */
            break;
        }
        case 2: {                                   /* length-delimited */
            uint64_t n = read_varint();
            if (n > (64u << 20))
                return -1;                          /* absurd length guard */
            data = malloc(n ? n : 1);
            if (!data)
                die("malloc");
            read_exact(data, n);
            len = (uint32_t)n;
            break;
        }
        default:
            return -1;                              /* malformed */
        }
    }
}

/* ── the session ───────────────────────────────────────────────────────── */

int main(int argc, char **argv)
{
    const char *host;
    uint64_t lba, count;
    const char *outfile = "/tmp/sacdclient.bin";
    struct sockaddr_in addr;
    int out_fd = -1;
    uint64_t done = 0;
    int type, rc;
    int64_t result;
    unsigned char *data;
    uint32_t len;

    if (argc < 4) {
        fprintf(stderr, "usage: %s HOST LBA COUNT [OUTFILE]\n", argv[0]);
        return 2;
    }
    host = argv[1];
    lba = strtoull(argv[2], NULL, 0);
    count = strtoull(argv[3], NULL, 0);
    if (argc > 4)
        outfile = argv[4];

    sock_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (sock_fd < 0)
        die("socket");
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(PORT);
    addr.sin_addr.s_addr = inet_addr(host);
    if (connect(sock_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0)
        die("connect (daemon listening?)");

    /* DISC_OPEN: success is exactly type==1 && result==0 (protocol §3.1). */
    send_request(1, 0, 0);
    rc = read_response(&type, &result, &data, &len);
    if (rc != 0 || type != 1 || result != 0) {
        fprintf(stderr, "FAIL DISC_OPEN type=%d result=%lld rc=%d\n",
                type, (long long)result, rc);
        return 1;
    }
    free(data);
    printf("DISC_OPEN ok\n");

    /* DISC_SIZE: type==4, result>0 = total sectors. */
    send_request(4, 0, 0);
    rc = read_response(&type, &result, &data, &len);
    if (rc != 0 || type != 4 || result <= 0) {
        fprintf(stderr, "FAIL DISC_SIZE type=%d result=%lld rc=%d\n",
                type, (long long)result, rc);
        return 1;
    }
    free(data);
    printf("DISC_SIZE ok sectors=%lld\n", (long long)result);

    /* DISC_READ in <=128-sector chunks; each reply's data is result*2048 B. */
    out_fd = open(outfile, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (out_fd < 0)
        die("open outfile");
    while (done < count) {
        uint64_t want = count - done;
        if (want > MAX_CHUNK)
            want = MAX_CHUNK;
        send_request(3, lba + done, want);
        rc = read_response(&type, &result, &data, &len);
        if (rc != 0 || type != 3 || result <= 0 || data == NULL) {
            fprintf(stderr, "FAIL DISC_READ lba=%llu want=%llu "
                    "type=%d result=%lld rc=%d\n",
                    (unsigned long long)(lba + done),
                    (unsigned long long)want, type, (long long)result, rc);
            return 1;
        }
        if (len != (uint32_t)result * SECTOR) {
            fprintf(stderr, "FAIL reply length %u != result*2048 (%lld)\n",
                    len, (long long)result * SECTOR);
            return 1;
        }
        if (write(out_fd, data, len) != (ssize_t)len)
            die("write outfile");
        free(data);
        done += (uint64_t)result;                   /* honour result<count */
    }
    close(out_fd);
    printf("DISC_READ ok lba=%llu count=%llu -> %s\n",
           (unsigned long long)lba, (unsigned long long)count, outfile);

    /* DISC_CLOSE: the daemon closes the socket after replying (§3.2). */
    send_request(2, 0, 0);
    rc = read_response(&type, &result, &data, &len);
    if (rc != 0 || type != 2) {
        fprintf(stderr, "FAIL DISC_CLOSE type=%d rc=%d\n", type, rc);
        return 1;
    }
    free(data);
    printf("DISC_CLOSE ok\n");
    close(sock_fd);
    printf("CLIENT_PASS\n");
    return 0;
}
