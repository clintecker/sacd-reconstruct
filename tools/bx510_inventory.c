/*
 * bx510_inventory.c — read-only runtime inventory collector (Phase 0,
 * production plan section 4; see evidence/bx510/hwmon-payload/
 * INVENTORY-SPEC.md for the field list and unknown-handling contract).
 *
 * Collects the runtime-profile fields hwmon does NOT already carry
 * (RECONCILIATION.md 2026-11-04): ELF interpreter + core-lib hashes,
 * libc version markers, kernel release, CPU flags, memory, random
 * devices, network link state, resource limits, busybox applets,
 * flash/df, DirectFB/Fusion identities.
 *
 * Design rules (plan: "unknown fields must remain explicit"):
 *   - READ-ONLY: nothing outside this process is modified; the only
 *     writes are the report on stdout.
 *   - TOLERANT: every probe is wrapped; a missing file/permission
 *     error is printed as "UNKNOWN (<reason>)", never a crash.
 *   - One portable C99 source: the x86 build is the behavior test
 *     (real /proc on the lab VM), the ARM build is the payload.
 *
 * Build (era gnuarm, static preferred — zero loader dependency, and a
 * static collector keeps its own /proc/self/maps free of the libs it
 * is there to hash):
 *   ~/gnuarm/bin/arm-none-linux-gnueabi-gcc -O2 -Wall -std=gnu99 \
 *       -static -o inventory bx510_inventory.c
 *
 * Run: inventory > report.txt   (hwmon_restore.sh does the redirect)
 */
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

/* ------------------------------------------------------------------ */
/* SHA-256 (self-contained: no crypto dependency on the player)        */

typedef struct {
    uint32_t h[8];
    uint64_t len;
    unsigned char buf[64];
    unsigned buflen;
} sha256_ctx;

static const uint32_t K[64] = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,
    0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,
    0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,
    0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,
    0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,
    0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,
    0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,
    0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,
    0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

#define ROR(x,n) (((x) >> (n)) | ((x) << (32 - (n))))

static void sha256_init(sha256_ctx *c)
{
    static const uint32_t init[8] = {
        0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,
        0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19
    };
    memcpy(c->h, init, sizeof init);
    c->len = 0;
    c->buflen = 0;
}

static void sha256_block(sha256_ctx *c, const unsigned char *p)
{
    uint32_t w[64], a, b, cc, d, e, f, g, h;
    int i;
    for (i = 0; i < 16; i++)
        w[i] = ((uint32_t)p[4*i] << 24) | ((uint32_t)p[4*i+1] << 16) |
                ((uint32_t)p[4*i+2] << 8) | (uint32_t)p[4*i+3];
    for (; i < 64; i++) {
        uint32_t s0 = ROR(w[i-15],7) ^ ROR(w[i-15],18) ^ (w[i-15] >> 3);
        uint32_t s1 = ROR(w[i-2],17) ^ ROR(w[i-2],19) ^ (w[i-2] >> 10);
        w[i] = w[i-16] + s0 + w[i-7] + s1;
    }
    a=c->h[0]; b=c->h[1]; cc=c->h[2]; d=c->h[3];
    e=c->h[4]; f=c->h[5]; g=c->h[6]; h=c->h[7];
    for (i = 0; i < 64; i++) {
        uint32_t S1 = ROR(e,6) ^ ROR(e,11) ^ ROR(e,25);
        uint32_t ch = (e & f) ^ (~e & g);
        uint32_t t1 = h + S1 + ch + K[i] + w[i];
        uint32_t S0 = ROR(a,2) ^ ROR(a,13) ^ ROR(a,22);
        uint32_t mj = (a & b) ^ (a & cc) ^ (b & cc);
        uint32_t t2 = S0 + mj;
        h=g; g=f; f=e; e=d+t1; d=cc; cc=b; b=a; a=t1+t2;
    }
    c->h[0]+=a; c->h[1]+=b; c->h[2]+=cc; c->h[3]+=d;
    c->h[4]+=e; c->h[5]+=f; c->h[6]+=g; c->h[7]+=h;
}

static void sha256_update(sha256_ctx *c, const void *data, size_t n)
{
    const unsigned char *p = data;
    c->len += n;
    while (n) {
        size_t take = 64 - c->buflen;
        if (take > n) take = n;
        memcpy(c->buf + c->buflen, p, take);
        c->buflen += take;
        p += take; n -= take;
        if (c->buflen == 64) {
            sha256_block(c, c->buf);
            c->buflen = 0;
        }
    }
}

static void sha256_final(sha256_ctx *c, unsigned char out[32])
{
    uint64_t bits = c->len * 8;
    unsigned char pad[72];
    size_t padlen;
    unsigned i;
    sha256_update(c, "\x80", 1);
    padlen = (c->buflen < 56) ? (56 - c->buflen) : (120 - c->buflen);
    memset(pad, 0, sizeof pad);
    sha256_update(c, pad, padlen);
    for (i = 0; i < 8; i++)
        pad[i] = (unsigned char)(bits >> (56 - 8*i));
    sha256_update(c, pad, 8);
    for (i = 0; i < 8; i++) {
        out[4*i]   = (unsigned char)(c->h[i] >> 24);
        out[4*i+1] = (unsigned char)(c->h[i] >> 16);
        out[4*i+2] = (unsigned char)(c->h[i] >> 8);
        out[4*i+3] = (unsigned char)(c->h[i]);
    }
}

/* ------------------------------------------------------------------ */
/* report helpers                                                      */

static void section(const char *s) { printf("--- %s ---\n", s); }

static void cat_file(const char *path, int maxbytes)
{
    FILE *in = fopen(path, "r");
    char buf[1024];
    size_t n, total = 0;
    if (!in) {
        printf("UNKNOWN (cannot open %s: %s)\n", path, strerror(errno));
        return;
    }
    while (maxbytes <= 0 || total < (size_t)maxbytes) {
        n = fread(buf, 1, sizeof buf, in);
        if (n == 0) break;
        fwrite(buf, 1, n, stdout);
        total += n;
    }
    if (maxbytes > 0 && total >= (size_t)maxbytes)
        printf("... (truncated at %d bytes)\n", maxbytes);
    fclose(in);
}

/* stat + size + sha256 of one file; 0 on success */
static int hash_file(const char *path)
{
    FILE *in = fopen(path, "rb");
    sha256_ctx c;
    unsigned char buf[16384], dig[32];
    size_t n;
    unsigned long long total = 0;
    int i;
    if (!in) {
        printf("  %s: UNKNOWN (open: %s)\n", path, strerror(errno));
        return -1;
    }
    sha256_init(&c);
    while ((n = fread(buf, 1, sizeof buf, in)) > 0) {
        sha256_update(&c, buf, n);
        total += n;
    }
    fclose(in);
    sha256_final(&c, dig);
    printf("  %s: size=%llu sha256=", path, total);
    for (i = 0; i < 32; i++) printf("%02x", dig[i]);
    printf("\n");
    return 0;
}

static void stat_line(const char *path)
{
    struct stat st;
    if (stat(path, &st) != 0) {
        printf("%s: UNKNOWN (stat: %s)\n", path, strerror(errno));
        return;
    }
    printf("%s: exists type=%s mode=%o uid=%u gid=%u size=%lld\n",
           path, S_ISDIR(st.st_mode) ? "dir" :
                 S_ISCHR(st.st_mode) ? "chardev" :
                 S_ISBLK(st.st_mode) ? "blkdev" :
                 S_ISLNK(st.st_mode) ? "symlink" : "file",
           st.st_mode & 07777, (unsigned)st.st_uid, (unsigned)st.st_gid,
           (long long)st.st_size);
}

/* run an external command, capture stdout+stderr (cap bytes)          */
static void run_capture(const char *path, char *const argv[],
                        int maxbytes, const char *label)
{
    int pfd[2];
    pid_t pid;
    char buf[1024];
    ssize_t n;
    int total = 0;
    if (access(path, X_OK) != 0) {
        printf("%s: UNKNOWN (%s not executable: %s)\n", label, path,
               strerror(errno));
        return;
    }
    if (pipe(pfd) != 0) {
        printf("%s: UNKNOWN (pipe: %s)\n", label, strerror(errno));
        return;
    }
    pid = fork();
    if (pid < 0) {
        printf("%s: UNKNOWN (fork: %s)\n", label, strerror(errno));
        close(pfd[0]); close(pfd[1]);
        return;
    }
    if (pid == 0) {
        close(pfd[0]);
        dup2(pfd[1], 1);
        dup2(pfd[1], 2);
        close(pfd[1]);
        execv(path, argv);
        _exit(127);
    }
    close(pfd[1]);
    while ((n = read(pfd[0], buf, sizeof buf)) > 0) {
        if (total < maxbytes) {
            int room = maxbytes - total;
            if (n > room) n = room;
            fwrite(buf, 1, n, stdout);
            total += (int)n;
        } else break;
    }
    close(pfd[0]);
    waitpid(pid, NULL, 0);
    if (total >= maxbytes) printf("... (truncated at %d bytes)\n", maxbytes);
}

/* ------------------------------------------------------------------ */
/* probes                                                              */

/* PT_INTERP of an ELF image (32- and 64-bit headers, host-endian read
 * of e_phoff is fine: ELF header fields we need are fixed-width and
 * little-endian on every target we care about: ARM + x86)            */
static void elf_interp(const char *elfpath)
{
    FILE *f = fopen(elfpath, "rb");
    unsigned char e[64];
    unsigned char ph[56];
    uint32_t phoff32, phentsize, phnum, ptype, poff32;
    uint64_t phoff64, poff64;
    unsigned i;
    char interp[4096];
    size_t n;
    if (!f) {
        printf("  interp of %s: UNKNOWN (open: %s)\n", elfpath,
               strerror(errno));
        return;
    }
    if (fread(e, 1, sizeof e, f) != sizeof e || memcmp(e, "\x7f""ELF", 4) != 0) {
        printf("  interp of %s: UNKNOWN (not an ELF image)\n", elfpath);
        fclose(f);
        return;
    }
    if (e[4] == 1) { /* ELFCLASS32 */
        phoff32   = e[28] | (e[29]<<8) | ((uint32_t)e[30]<<16) | ((uint32_t)e[31]<<24);
        phentsize = e[42] | (e[43]<<8);
        phnum     = e[44] | (e[45]<<8);
    } else if (e[4] == 2) { /* ELFCLASS64 */
        uint64_t lo = e[32] | (e[33]<<8) | ((uint64_t)e[34]<<16) | ((uint64_t)e[35]<<24);
        uint64_t hi = e[36] | (e[37]<<8) | ((uint64_t)e[38]<<16) | ((uint64_t)e[39]<<24);
        phoff64   = lo | (hi<<32);
        phentsize = e[54] | (e[55]<<8);
        phnum     = e[56] | (e[57]<<8);
    } else {
        printf("  interp of %s: UNKNOWN (EI_CLASS=%d)\n", elfpath, e[4]);
        fclose(f);
        return;
    }
    (void)phoff32; (void)phoff64;
    {
        uint64_t off = (e[4] == 1) ? phoff32 : phoff64;
        for (i = 0; i < phnum && i < 64; i++) {
            if (fseek(f, (long)(off + (uint64_t)i * phentsize), SEEK_SET) != 0)
                break;
            if (fread(ph, 1, phentsize, f) != phentsize)
                break;
            if (e[4] == 1) {
                ptype = ph[0] | (ph[1]<<8) | ((uint32_t)ph[2]<<16) | ((uint32_t)ph[3]<<24);
                poff32 = ph[4] | (ph[5]<<8) | ((uint32_t)ph[6]<<16) | ((uint32_t)ph[7]<<24);
                poff64 = poff32;
            } else {
                ptype = ph[0] | (ph[1]<<8) | ((uint32_t)ph[2]<<16) | ((uint32_t)ph[3]<<24);
                poff64 = ph[8] | (ph[9]<<8) | ((uint64_t)ph[10]<<16) |
                         ((uint64_t)ph[11]<<24) | ((uint64_t)ph[12]<<32) |
                         ((uint64_t)ph[13]<<40) | ((uint64_t)ph[14]<<48) |
                         ((uint64_t)ph[15]<<56);
            }
            if (ptype == 3) { /* PT_INTERP */
                if (fseek(f, (long)poff64, SEEK_SET) != 0) break;
                n = fread(interp, 1, sizeof interp - 1, f);
                interp[n] = 0;
                printf("  %s PT_INTERP: %s\n", elfpath, interp);
                fclose(f);
                return;
            }
        }
    }
    printf("  %s PT_INTERP: none (static image)\n", elfpath);
    fclose(f);
}

/* hash every file in dir/ matching any prefix (self-annealing: the
 * player may keep libc in /lib or /usr/lib)                         */
static void hash_dir_prefixes(const char *dir, const char *const *prefixes)
{
    DIR *d = opendir(dir);
    struct dirent *e;
    const char *const *p;
    if (!d) {
        printf("  %s: UNKNOWN (opendir: %s)\n", dir, strerror(errno));
        return;
    }
    while ((e = readdir(d))) {
        for (p = prefixes; *p; p++) {
            if (strncmp(e->d_name, *p, strlen(*p)) == 0) {
                char full[512];
                snprintf(full, sizeof full, "%s/%s", dir, e->d_name);
                hash_file(full);
                break;
            }
        }
    }
    closedir(d);
}

/* unique mapped file paths from /proc/self/maps (the ACTUAL loaded
 * images — the authoritative "what loader+libc is in use" record).
 * g_libc_path captures the actual libc image for version scanning. */
static char g_libc_path[512];

static void dump_maps_and_hash_libs(void)
{
    FILE *in = fopen("/proc/self/maps", "r");
    char line[1024];
    char *paths[64];
    int npaths = 0, i, j;
    if (!in) {
        printf("UNKNOWN (cannot open /proc/self/maps: %s)\n", strerror(errno));
        return;
    }
    while (fgets(line, sizeof line, in)) {
        char *sp = strchr(line, '/');
        char *nl, *tab;
        if (!sp) continue;
        nl = strchr(sp, '\n'); if (nl) *nl = 0;
        tab = strchr(sp, '\t'); if (tab) *tab = 0;
        /* dedupe */
        for (j = 0; j < npaths; j++)
            if (strcmp(paths[j], sp) == 0) break;
        if (j < npaths) continue;
        printf("  mapped: %s\n", sp);
        if (!g_libc_path[0] && strstr(sp, "libc.so"))
            snprintf(g_libc_path, sizeof g_libc_path, "%s", sp);
        if (npaths < 64) {
            paths[npaths] = malloc(strlen(sp) + 1);
            if (paths[npaths]) { strcpy(paths[npaths], sp); npaths++; }
        }
    }
    fclose(in);
    if (npaths == 0)
        printf("  (no mapped file paths — static image)\n");
    /* hash the shared objects among them (cap 24) */
    for (i = 0, j = 0; i < npaths && j < 24; i++) {
        if (strstr(paths[i], ".so"))
            { hash_file(paths[i]); j++; }
    }
    for (i = 0; i < npaths; i++) free(paths[i]);
}

/* scan a libc image for GLIBC_2.x version markers + the version banner
 * (strings(1) equivalent — the player has no strings(1))             */
static void libc_version(const char *libcpath)
{
    FILE *f = fopen(libcpath, "rb");
    static const unsigned char magic[] = { 'G','L','I','B','C','_','2','.' };
    static const char banner[] = "GNU C Library";
    unsigned char buf[65536];
    size_t n, carry = 0;
    unsigned best[2] = { 0, 0 };   /* minor, tiny: of GLIBC_2.<minor>.<tiny> */
    int best_two = 0;              /* winner had a tiny component */
    int found = 0, found_banner = 0;
    unsigned long long total = 0;
    if (!f) {
        printf("  version markers in %s: UNKNOWN (open: %s)\n", libcpath,
               strerror(errno));
        return;
    }
    while (total < 16ULL*1024*1024 &&
           (n = fread(buf + carry, 1, sizeof buf - carry, f)) > 0) {
        size_t have = carry + n, i;
        for (i = 0; i + sizeof magic <= have; i++) {
            if (memcmp(buf + i, magic, sizeof magic) == 0) {
                /* "GLIBC_2." is fixed by |magic|; parse up to two more
                 * numeric components (minor[.tiny]) */
                unsigned v[2] = { 0, 0 };
                int ci = 0, comps = 0;
                size_t k = i + sizeof magic;
                while (ci < 2) {
                    while (k < have && buf[k] >= '0' && buf[k] <= '9') {
                        v[ci] = v[ci]*10 + (buf[k]-'0');
                        k++; comps++;
                    }
                    if (ci < 1 && k < have && buf[k] == '.') { k++; ci++; }
                    else break;
                }
                if (comps > 0) {
                    if (!found || v[0] > best[0] ||
                        (v[0] == best[0] && v[1] > best[1]))
                        { best[0]=v[0]; best[1]=v[1]; found = 1;
                          best_two = (ci == 1); }
                }
                i = k - 1;
            }
        }
        /* banner search (keep tail for straddling matches) */
        for (i = 0; i + strlen(banner) + 200 <= have; i++) {
            if (!found_banner && memcmp(buf + i, banner, strlen(banner)) == 0) {
                size_t k;
                printf("  banner: ");
                for (k = i; k < i + 200 && k < have; k++) {
                    if (buf[k] == '\n') break;
                    if (buf[k] >= 32 && buf[k] < 127) putchar(buf[k]);
                }
                putchar('\n');
                found_banner = 1;
                break;
            }
        }
        if (have > 256) {
            carry = 256;
            memmove(buf, buf + have - carry, carry);
        } else carry = have;
        total += n;
    }
    fclose(f);
    if (found) {
        printf("  max GLIBC_2.x marker: GLIBC_2.%u", best[0]);
        if (best_two) printf(".%u", best[1]);
        printf("\n");
    } else
        printf("  max GLIBC_2.x marker: UNKNOWN (none found)\n");
    if (!found_banner)
        printf("  banner: UNKNOWN (no \"GNU C Library\" string)\n");
}

static void probe_random_dev(const char *dev, int nonblock)
{
    struct stat st;
    unsigned char b[8];
    ssize_t n;
    int fd, fl = O_RDONLY | (nonblock ? O_NONBLOCK : 0);
    char hex[32];
    int i;
    if (stat(dev, &st) != 0) {
        printf("%s: UNKNOWN (stat: %s)\n", dev, strerror(errno));
        return;
    }
    printf("%s: exists mode=%o type=%s", dev, st.st_mode & 07777,
           S_ISCHR(st.st_mode) ? "chardev" : "OTHER(non-chardev!)");
    fd = open(dev, fl);
    if (fd < 0) {
        printf(" open: UNKNOWN (%s)\n", strerror(errno));
        return;
    }
    n = read(fd, b, sizeof b);
    close(fd);
    if (n <= 0) {
        printf(" read: UNKNOWN (%s)\n", n == 0 ? "EOF" : strerror(errno));
        return;
    }
    for (i = 0; i < n; i++) sprintf(hex + 2*i, "%02x", b[i]);
    hex[2*n] = 0;
    printf(" read%s: %d/%d bytes: %s\n",
           nonblock ? " (O_NONBLOCK)" : "", (int)n, (int)sizeof b, hex);
}

static void probe_net(void)
{
    DIR *d;
    struct dirent *e;
    cat_file("/proc/net/dev", 0);
    d = opendir("/sys/class/net");
    if (!d) {
        printf("  /sys/class/net: UNKNOWN (opendir: %s)\n", strerror(errno));
    } else {
        while ((e = readdir(d))) {
            char p[512];
            FILE *f;
            char v[128];
            if (e->d_name[0] == '.') continue;
            printf("  iface %s:\n", e->d_name);
            snprintf(p, sizeof p, "/sys/class/net/%s/speed", e->d_name);
            f = fopen(p, "r");
            if (f && fgets(v, sizeof v, f)) printf("    speed: %s", v);
            else printf("    speed: UNKNOWN\n");
            if (f) fclose(f);
            snprintf(p, sizeof p, "/sys/class/net/%s/duplex", e->d_name);
            f = fopen(p, "r");
            if (f && fgets(v, sizeof v, f)) printf("    duplex: %s", v);
            else printf("    duplex: UNKNOWN\n");
            if (f) fclose(f);
            snprintf(p, sizeof p, "/sys/class/net/%s/carrier", e->d_name);
            f = fopen(p, "r");
            if (f && fgets(v, sizeof v, f)) printf("    carrier: %s", v);
            else printf("    carrier: UNKNOWN\n");
            if (f) fclose(f);
        }
        closedir(d);
    }
    cat_file("/proc/net/arp", 0);
}

/* Fusion participant identity resolution — THE display-takeover
 * adjudicator (incoming/display-takeover-evidence/ANALYSIS.md):
 * a surviving participant PID + start-time with a live fusionees
 * entry supports a Fusion world (ID 1 = master) the takeover could
 * join; the same PID with no Fusion entry supports the native-route /
 * no-master reading. Resolves Tgid because the recorded PID can be a
 * thread. Layout-agnostic: while dumping /proc/fusion, any small-file
 * content that parses as a live PID is collected, then each such PID's
 * /proc/<pid>/stat (field 22 = start time) and Tgid are printed. */
static int fusion_pids[64];
static int n_fusion_pids = 0;

static int record_live_pid(long v)
{
    char p[512];
    int i;
    if (v < 1 || v > 999999) return 0;
    snprintf(p, sizeof p, "/proc/%ld", v);
    if (access(p, F_OK) != 0) return 0;
    for (i = 0; i < n_fusion_pids; i++)
        if (fusion_pids[i] == (int)v) return 1;
    if (n_fusion_pids < 64)
        fusion_pids[n_fusion_pids++] = (int)v;
    return 1;
}

static void note_fusion_pid(const char *path)
{
    FILE *in = fopen(path, "r");
    char buf[4096];
    size_t n;
    char *s, *end;
    long v;
    int found_pid_word = 0;

    if (!in) return;
    n = fread(buf, 1, sizeof buf - 1, in);
    fclose(in);
    buf[n] = 0;

    /* Strong: integer following the word "pid" (fusion procfs prints a
     * per-fusionee TABLE: "... pid 743 ..." — the takeover analysis's
     * "<world>/fusionees" layout). */
    s = buf;
    while ((s = strstr(s, "pid")) != NULL) {
        v = strtol(s + 3, &end, 10);
        if (end != s + 3 && record_live_pid(v))
            found_pid_word = 1;
        s = (end > s) ? end : s + 3;
    }
    /* Weak fallback: any live-resolving integer token (bare-ID lists).
     * May note incidental IDs whose values collide with live PIDs (e.g.
     * fusionee ID 1 == init) — the raw file content is dumped alongside,
     * so the report reader can tell. */
    if (!found_pid_word) {
        s = buf;
        for (;;) {
            while (*s && (*s < '0' || *s > '9')) s++;
            if (!*s) break;
            v = strtol(s, &end, 10);
            record_live_pid(v);
            s = end;
        }
    }
}

static void dump_fusion_participants(void)
{
    int i;
    char p[512];
    FILE *in;
    char buf[1024];

    printf("  -- participant identity resolution (PID + start time; ID 1 = master) --\n");
    if (n_fusion_pids == 0) {
        printf("  (no live PIDs found in /proc/fusion content — supports the no-master reading)\n");
        return;
    }
    for (i = 0; i < n_fusion_pids; i++) {
        snprintf(p, sizeof p, "/proc/%d/stat", fusion_pids[i]);
        printf("  [fusion pid %d] stat: ", fusion_pids[i]);
        in = fopen(p, "r");
        if (in && fgets(buf, sizeof buf, in)) {
            printf("%s", buf);
        } else {
            printf("UNKNOWN (cannot read %s)\n", p);
        }
        if (in) fclose(in);
        snprintf(p, sizeof p, "/proc/%d/status", fusion_pids[i]);
        in = fopen(p, "r");
        if (in) {
            while (fgets(buf, sizeof buf, in))
                if (strncmp(buf, "Tgid:", 5) == 0 || strncmp(buf, "Name:", 5) == 0)
                    printf("    %s", buf);
            fclose(in);
        }
    }
}

static void probe_fusion(void)
{
    DIR *d = opendir("/dev");
    struct dirent *e;
    int nf = 0;
    if (d) {
        while ((e = readdir(d))) {
            if (strncmp(e->d_name, "fusion", 6) == 0) {
                char p[512];
                snprintf(p, sizeof p, "/dev/%s", e->d_name);
                stat_line(p);
                nf++;
            } else if (strncmp(e->d_name, "fb", 2) == 0 &&
                       e->d_name[2] >= '0' && e->d_name[2] <= '9') {
                char p[512];
                snprintf(p, sizeof p, "/dev/%s", e->d_name);
                stat_line(p);
            }
        }
        closedir(d);
    } else {
        printf("  /dev: UNKNOWN (opendir: %s)\n", strerror(errno));
    }
    if (nf == 0) printf("  (no /dev/fusion* entries)\n");
    /* /proc/fusion: read-only dump of the small per-fusionee files */
    d = opendir("/proc/fusion");
    if (!d) {
        printf("  /proc/fusion: UNKNOWN (opendir: %s)\n", strerror(errno));
    } else {
        while ((e = readdir(d))) {
            char p[512];
            if (e->d_name[0] == '.') continue;
            snprintf(p, sizeof p, "/proc/fusion/%s", e->d_name);
            if (e->d_type == DT_DIR) {
                DIR *sd = opendir(p);
                struct dirent *se;
                if (sd) {
                    while ((se = readdir(sd))) {
                        char q[600];
                        if (se->d_name[0] == '.') continue;
                        snprintf(q, sizeof q, "%s/%s", p, se->d_name);
                        if (se->d_type == DT_DIR) {
                            /* three-level walk: some fusion procfs
                             * versions nest per-fusionee dirs */
                            DIR *td = opendir(q);
                            struct dirent *te;
                            if (td) {
                                while ((te = readdir(td))) {
                                    char r[700];
                                    if (te->d_name[0] == '.') continue;
                                    snprintf(r, sizeof r, "%s/%s", q, te->d_name);
                                    printf("  [%s]\n", r);
                                    cat_file(r, 4096);
                                    note_fusion_pid(r);
                                }
                                closedir(td);
                            }
                        } else {
                            printf("  [%s]\n", q);
                            cat_file(q, 4096);
                            note_fusion_pid(q);
                        }
                    }
                    closedir(sd);
                }
            } else {
                printf("  [%s]\n", p);
                cat_file(p, 4096);
                note_fusion_pid(p);
            }
        }
        closedir(d);
    }
    dump_fusion_participants();
}

/* find the first existing path among candidates (the player's actual
 * libc location is exactly what we do not know yet)                  */
static const char *first_existing(const char *const *cands)
{
    const char *const *p;
    for (p = cands; *p; p++) {
        struct stat st;
        if (stat(*p, &st) == 0) return *p;
    }
    return NULL;
}

int main(void)
{
    static const char *const corelib_prefixes[] = {
        "ld-linux", "ld-2.", "libc.so", "libc-", "libpthread", "libgcc_s",
        "libm.so", "libm-", "libdl", "librt", NULL
    };
    static const char *const dfb_prefixes[] = {
        "libdirectfb", "libdirect-", "libdirect_", "libfusion", NULL
    };
    static const char *const libc_candidates[] = {
        "/lib/libc.so.6", "/lib/libc-2.12.2.so", "/usr/lib/libc.so.6",
        "/lib/libc-2.11.3.so", NULL
    };
    const char *libc;
    char *bb_argv0[] = { (char*)"busybox", NULL };
    char *bb_df[] = { (char*)"busybox", (char*)"df", NULL };
    char *bb_uname[] = { (char*)"busybox", (char*)"uname", (char*)"-a", NULL };

    printf("=== BX510 runtime inventory (bx510_inventory v1) ===\n");
    printf("collector: %s\n", "bx510_inventory v2 (read-only, +fusion adjudicator)");
    printf("note: x86-test values may appear when this binary is run on the"
           " lab VM; player values come only from the player run\n");

    section("uptime");
    cat_file("/proc/uptime", 0);

    section("elf interpreter");
    elf_interp("/proc/self/exe");

    section("core runtime libraries (hashes)");
    hash_dir_prefixes("/lib", corelib_prefixes);
    hash_dir_prefixes("/usr/lib", corelib_prefixes);

    section("loaded images (/proc/self/maps + hashes)");
    dump_maps_and_hash_libs();

    section("libc version markers");
    libc = g_libc_path[0] ? g_libc_path : first_existing(libc_candidates);
    if (!libc) {
        /* static collector + no canonical libc path: the core-lib hash
         * section above still names whatever matched the prefixes    */
        printf("  libc image: UNKNOWN (none of the candidate paths exist)\n");
    } else {
        printf("  libc image: %s%s\n", libc,
               g_libc_path[0] ? " (from /proc/self/maps)" : "");
        libc_version(libc);
    }

    section("kernel release");
    cat_file("/proc/version", 0);
    printf("osrelease: ");
    {
        FILE *f = fopen("/proc/sys/kernel/osrelease", "r");
        char v[256];
        if (f && fgets(v, sizeof v, f)) printf("%s", v);
        else printf("UNKNOWN\n");
        if (f) fclose(f);
    }

    section("cpu (/proc/cpuinfo)");
    cat_file("/proc/cpuinfo", 16384);

    section("memory (/proc/meminfo)");
    cat_file("/proc/meminfo", 8192);

    section("random devices + entropy");
    probe_random_dev("/dev/urandom", 0);
    probe_random_dev("/dev/random", 1); /* NONBLOCK: a blocking read on
                                           /dev/random would wedge the
                                           whole AutoScript trigger */
    printf("/proc/sys/kernel/random/entropy_avail: ");
    {
        FILE *f = fopen("/proc/sys/kernel/random/entropy_avail", "r");
        char v[64];
        if (f && fgets(v, sizeof v, f)) printf("%s", v);
        else printf("UNKNOWN (file absent)\n");
        if (f) fclose(f);
    }

    section("network interfaces + negotiated link");
    probe_net();

    section("resource limits (/proc/self/limits)");
    cat_file("/proc/self/limits", 0);

    section("busybox identity + applet list");
    stat_line("/bin/busybox");
    hash_file("/bin/busybox");
    run_capture("/bin/busybox", bb_argv0, 4096, "busybox applets (no args)");
    run_capture("/bin/busybox", bb_uname, 1024, "busybox uname -a");

    section("flash / storage");
    cat_file("/proc/mtd", 0);
    run_capture("/bin/busybox", bb_df, 4096, "df (busybox)");
    stat_line("/dev/mtd0");

    section("directfb / fusion runtime identities");
    probe_fusion();
    hash_dir_prefixes("/usr/lib", dfb_prefixes);
    hash_dir_prefixes("/lib", dfb_prefixes);

    printf("=== end of inventory ===\n");
    return 0;
}
