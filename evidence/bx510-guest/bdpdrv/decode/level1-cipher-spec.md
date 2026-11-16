# Level-1 synthetic cipher — Stage-A SPEC (issue #10)

Status: **executable spec, no code landed**. Three implementers + one acceptance
battery. Written 2026-11-16, Mac-side only — no VM contact, no fire, no edits
to any source file.

Read with: `docs/LIFECYCLE.md` (the ladder), `decode/sacdread-cpsa.md` §4.3
(the decrypt chain), `decode/decrypt-hang.md` (why the GCPU completion exists
and how the stub delivers it), `decode/client-leg-oracles.md` (the acceptance
table), `decode/run-c130-c134.md` (Level-0 closed; the `FE_DMA_MAX` lesson),
`decode/daemon-socket-protocol.md` §3.3/§4 (the daemon decrypts every read),
`decode/daemon-ioctl-side.md` §2.4/§3 (the **plain** TOC read path).

**House rules.** **VERIFIED** = read out of an instruction/struct/script line,
cited `file:line`. **INFERRED** = reasoned, with the probe that settles it.
Every interface claim below carries a citation.

---

## 0. Answers to the six briefed decisions (and the three corrections)

| # | decision | this spec |
|---|---|---|
| 1 | the transform | per-sector **keyed 512-word XOR keystream**, one function `F`, self-inverse (`F(F(x))==x`): §1. Applied to the **2048-byte payload only** of each 2064-byte frame; header + 4 trailing bytes pass through untouched (the driver drops them anyway, `sacdread-cpsa.md:342`). **Selectivity by LSN range**, not by a flag: LBA 584..353763 and 353844..1064126 are the encrypted-at-rest areas (`client-leg-oracles.md:9-18`); everything else is identity. |
| 2 | where the LSN comes from | **Not from the ioctl.** The decrypt chain carries only `(src,dst,len)` and the LSN does not exist anywhere in it: userspace fills `+0x08=sectors`, `+0x0c=buf` and leaves `+0x04` (LBA) **zero** (`daemon-ioctl-side.md:108`); `CPSA_SACDCmdDecrypt(compid,src,dst,len)` → `_i4CPSA_Inst_Decrypt` → `i4GCPU_CmdExec(0x806,{src,dst,len})` → `_i4GCPU_SACDDEC` writes `blk[2]=src|NS, blk[3]=dst|NS, blk[4]=len/2064, blk[5]=len` and nothing else (`decrypt-hang.md` §2.3, `0x1715cc–0x1715f8`), which is exactly what the stub reads (`tools/bx510_osal_stub.c:319-322`). The LSN therefore travels **in band, in the 12-byte SACD frame header the model emits** — currently zeroed at `emulator-kit/player.local.c:556`. §1.4. |
| 3 | key management | two compile-time constants in the stub **and** in the fixture tool, one spelling each, agreed by a published KAT (§2). No EKB, no key file, no runtime negotiation — explicitly out of scope. |
| 4 | the fixture side | **not `fixture_gen.py`** — see Correction C1. A derived byte-copy of the real ISO with only the two audio ranges encrypted at rest: `tools/bx510_disc_cipher.py` (§3). Acceptance table unchanged (`client-leg-oracles.md`) + a recorded ciphertext mirror for the negative control (§3.3). |
| 5 | the implementation slice | 3 implementers, 5 files, 1 new disc, 4 fires c135–c138 (§4, §5). |
| 6 | performance | ≈ 4 ARM ops/byte, 2 048 XORs + 514 xorshift steps per sector ⇒ order 0.1 s for the whole 3.2 MB battery; **the TIMEOUT does not move** (§6). |

**Three corrections to the briefed assumptions** (each verified, each changes a
command below):

* **C1 — `tools/fixture_gen.py` is not the rig's disc.** It writes an
  86 200-sector synthetic image (`tools/fixture_gen.py:30` `TOTAL_SECTORS =
  86200`, area TOC at LSN 600, encrypted range 80000..86000,
  `tools/fixture_gen.py:32-33`) — a completely different disc from Firebird, and
  nothing in the current fire path reads it. The live fire hard-codes the real
  ISO: `tools/bx510-fire.sh:59` `export BX510_MACHINE_OPTS='sata-disc=/home/you/the verification tree/firebird.iso'`,
  which `emulator-kit/run.py:14-18` forwards verbatim as `-M player.local,<opts>`.
  Since the acceptance is "post-decrypt wire md5 == the recorded PLAIN md5s"
  and those md5s are of *Firebird's* content (`client-leg-oracles.md:2-6`), the
  Level-1 disc must be a byte-derived copy of Firebird, not a synthesized disc.
  (Supervisor ruling 2026-11-16: confirmed — derived copy, 1064208 sectors, same
  TOC bytes.)
* **C2 — the stub `.ko` is *not* a member of the daemon payload tgz.** The
  nested tgz is repacked with a fixed nine-member list that contains the daemon,
  `sacd_read.ko`, `sacdgate`, `sacdclient`, `sacd_ui`, `fbdump`, the font and
  `bx510_fbvirt.ko` (`tools/bx510_ui_build_vm.sh:102-112`). The stub travels
  separately as the probe's `--stubko` argument
  (`tools/bx510-fire.sh:66`, `tools/bx510_bdpdrv_stub_probe.py:241`), packed
  into `shim/osal_stub.ko` of the **fe_test_data** partition
  (`tools/bx510_bdpdrv_stub_probe.py:50-51`). So a cipher change needs
  `make sacd-stub-build`, **not** `make bx510-ui-build`; the only reason to run
  the UI build/gate is the fe_test_data budget (the stub grows by a few hundred
  bytes) — do it as the cheap `DRYRUN=1` gate in §4.4.
* **C3 — `make sacd-stub-build` is stale in this checkout.** The target stages
  from `experiments/sacd_reconstruct/tools/` (`Makefile:423-425`), and
  `ls experiments` fails here (verified); that is the same defect that put a
  6-hour-old stub into the C109 rig (`decrypt-hang.md` §4.3). Use the explicit
  5-file staging sequence in §4.3, and verify the staged source's sha256.

---

## 1. THE TRANSFORM

### 1.1 What is encrypted, and where it sits in the frame

One SACD sector reaches the stub as a **2064-byte frame**: `[0..11]` header,
`[12..2059]` the 2048-byte payload, `[2060..2063]` four trailing bytes
(`emulator-kit/player.local.c:344-346`, `:556-558`; the driver's own compaction
`memcpy(buf+i*2048, out+12, 2048)` at `sacdread-cpsa.md:342` proves the 12+2048
offsets).

```
Level-0 (today)                       Level-1 (this spec)
+----------------+-------------+----+  +----------------+-------------+----+
| 12B header = 0 | 2048 payload| 4B |  | LSN BE32 | f@4 |2048 payload| 4B |
+----------------+-------------+----+  +----------------+-------------+----+
                                        ^ hdr[0..3] = LSN (BE)   ^ untouched
                                        ^ hdr[4] = 0x01 ciphertext-at-rest
```

* **Encrypted: the 2048-byte payload only.** `[2060..2063]` are copied
  verbatim; `[0..11]` are copied verbatim into `dst` (they never reach the wire,
  `sacdread-cpsa.md:342`, so their content is wire-invisible).
* **Not encrypted: any metadata sector at rest** — i.e. LBA 510..519 (master
  TOC + `SACDText` + `SACD_Man`), 544..553 (TWOCHTOC), 353804..353813
  (MULCHTOC), and the inter-area plaintext zone 353764..353843. This is forced, not stylistic: **the daemon's TOC reads never
  touch the decrypt ioctl** — they are plain `lseek64(fd, lba<<11)` +
  `read(fd, buf, n<<11)` on the `/dev/sr0` fd, 2048 B/sector
  (`daemon-ioctl-side.md:264`, master TOC `read(dev, 0x1FE, 10, buf)` at `:272`,
  area TOC at `:273`, the DISC_OPEN timeline at `:380-382`, "the daemon's first
  disc contact is the PLAIN 10-sector read at LBA 0x1FE" at `:491`). An
  encrypted-at-rest LBA 510 kills DISC_OPEN with `Can't read Master TOC.`
  (`daemon-ioctl-side.md:514`) before a single byte of client traffic.
* Those same metadata LBAs **do** flow through `SACD_IOC_DECRYPT` on the
  port-2002 read path, because the server decrypts unconditionally
  (`daemon-socket-protocol.md:293` and §4.2/§4.3 at `:354-366`). Hence the stub
  must be **selective per sector**, and hence the LSN must be in band.

### 1.2 The cipher (one function, self-inverse) — normative

Naming: one spelling per concept, in both implementations.

```c
/* Level-1 synthetic cipher (issue #10). NOT a cryptographic scheme and not a
 * model of AACS/SACD keying: it demonstrates that the decrypt path carries
 * real per-sector work (keyed, area-selective, invertible), nothing more. */
#define L1_KEY0    0xC0FFEE11u   /* sector key, stage 1 */
#define L1_KEY1    0x1BADB002u   /* sector key, stage 2 */
#define L1_MUL0    0x9E3779B1u   /* LSN mixer (golden-ratio odd) */
#define L1_SALT0   0x00424C31u
#define L1_SALT1   0x5ACD5ACDu   /* the fixture family's salt (fixture_gen.py:174) */
#define L1_WORDS   512u          /* 2048 bytes / 4 */
#define L1_PAYLOAD 2048u
#define L1_HDR     12u
#define L1_FRAME   2064u

static inline uint32_t l1_step(uint32_t x)      /* xorshift32 */
{
    x ^= x << 13; x ^= x >> 17; x ^= x << 5;    /* uint32_t: wrap is defined */
    return x;
}

/* The keystream state for one sector: LSN is mixed through two keyed stages,
 * then stepped once per 32-bit payload word. */
static uint32_t l1_seed(uint32_t lsn)
{
    uint32_t v = (lsn * L1_MUL0) ^ L1_KEY0 ^ L1_SALT0;
    v = l1_step(v);                 /* stage 1 */
    v ^= L1_KEY1 ^ L1_SALT1;
    return l1_step(v);              /* stage 2 */
}

/* F: XOR the 2048-byte payload with the sector's keystream, in place.
 * Words are assembled little-endian from payload bytes (payload[4j] is the
 * low byte) so the ARM stub and the Python fixture tool agree with no
 * alignment or endianness question. F(F(p)) == p. */
static void l1_xform(uint32_t lsn, unsigned char *p)
{
    uint32_t v = l1_seed(lsn), j;
    for (j = 0; j < L1_WORDS; j++) {
        uint32_t w;
        v = l1_step(v);
        w = (uint32_t)p[4*j] | ((uint32_t)p[4*j+1] << 8) |
            ((uint32_t)p[4*j+2] << 16) | ((uint32_t)p[4*j+3] << 24);
        w ^= v;
        p[4*j]   = (unsigned char)w;
        p[4*j+1] = (unsigned char)(w >> 8);
        p[4*j+2] = (unsigned char)(w >> 16);
        p[4*j+3] = (unsigned char)(w >> 24);
    }
}
```

Properties, all deliberate:

* **Self-inverse.** `l1_xform` is a XOR keystream, so the stub and the fixture
  tool call the *same* function; there is no inverse to implement and therefore
  no "the two sides disagree about the inverse" failure class. Verified three
  ways (§2.2): Python, the compiled §1.2 C, and the frame-level round-trip.
* **Per-sector keyed.** Two keyed mixing stages of `(LSN, KEY0, KEY1)` seed a
  xorshift32 generator; word *j* of the keystream is the *(j+1)*-th step.
  Different LSN ⇒ unrelated keystream ⇒ identical plaintext sectors produce
  different ciphertext (the property an identity transform lacks).
* **Era-C, no 64-bit math, no tables, ~4 ops/byte.** ARMv6 `uint32_t` only; no
  division, no floating point, no `__aeabi_*` helper (the guest kernel's
  `-march=armv6` toolchain emits none of these — the stub is already built that
  way, `tools/bx510_stub_build.sh:16`).

### 1.3 Area selectivity — the range table

```c
/* The two encrypted-at-rest areas, from the disc's OWN area TOCs, which are
 * also the daemon's own block_size branch boundaries (`daemon-socket-protocol.md:322-336`, the same
 * four numbers the daemon reads from TWOCHTOC@544 and MULCHTOC@353804). */
#define L1_ENC_START1 584u
#define L1_ENC_END1   353763u
#define L1_ENC_START2 353844u
#define L1_ENC_END2   1064126u

static int l1_in_area(uint32_t lsn)
{
    return (lsn >= L1_ENC_START1 && lsn <= L1_ENC_END1) ||
           (lsn >= L1_ENC_START2 && lsn <= L1_ENC_END2);
}
```

Source of the four numbers: `decode/client-leg-oracles.md:9-18` (the ISO parse
committed with the oracles: `trk_start @72 = 584`, `trk_end @76 = 353763` at `:10`;
MULCHTOC `353844..1064126` at `:17-18`). The daemon derives the *same* four numbers at
runtime from the same TOC fields and splits client reads on them
(`daemon-socket-protocol.md:322-336`, addresses `0xca9c/0xcac0/0xcb08/0xcb4c`, final
clamp `0xcb90–0xcba8`) — which is why the boundary-straddling 353750×40 read
arrives as two blocks (c133: `353750×14 + 353764×26`, `run-c130-c134.md`).
The stub holds a **static copy**; §3.2 makes the fixture tool *prove* the disc's
TOC still matches it, so the pair cannot drift silently.

### 1.4 Where the LSN comes from — the frame header (the one model change)

`hdr[0..3]` = the sector's LSN, **big-endian** (the disc's own byte order —
every multi-byte TOC field is BE on disc and the daemon swaps after reading,
`tools/fixture_gen.py:23`); `hdr[4]` = `0x01` when this frame's payload is
ciphertext at rest, `0x00` otherwise; `hdr[5..11]` remain zero. Written by the
model only when the machine property `sacd-cipher=1` is set — see §4.2. With the
property off the header is byte-identical to today (all zeros), which is the
Level-0 regression invariant.

Why the header is the only possible carrier (all VERIFIED):

* the userspace decrypt ioctl leaves the LBA field zero
  (`daemon-ioctl-side.md:108`: `+0x08=sectors`, `+0x0c=buf`, `+0x04` stays 0);
* the CPSA/GCPU chain drops everything but `(src,dst,len)`
  (`decrypt-hang.md` §2.3);
* the frame is DMA'd and copied as whole `2064 × n` units end to end — the FE
  writes `len = nsec × 2064` bytes (`emulator-kit/player.local.c:341`,
  `:514-560`; c134 census `len=264192 frame=2064`, `run-c130-c134.md:107-108`),
  `sacd_read.ko`'s read arm is `kmalloc(2064*n)` … `copy_to_user(…,2064*n)`
  (`sacdread-cpsa.md:341`), and the decrypt arm is `copy_from_user(…,2064*n)`
  per block `CPSA_SACDCmdDecrypt(compid, in+2064*i, out, 2064)`
  (`sacdread-cpsa.md:342`). So the header bytes physically reach the stub in
  `src`, and whatever the stub leaves in `dst[0..11]` is discarded by the
  driver's `out+12` compaction.

`hdr[4]` is **belt-and-braces, not the selector** (supervisor ruling): the stub
selects on the LSN range and treats the flag as an assertion —
`flag == 0 ⇒ identity` (a Level-0 disc: real ISO, cipher disarmed) and, when
`flag == 1`, `l1_in_area(lsn) == 0 ⇒ identity` (a metadata frame inside an
armed disc). Either way the stub **never silently corrupts**: every block emits
one census line carrying what it did (§1.5).

### 1.5 The stub side — replacing the identity loop

Today (`tools/bx510_osal_stub.c:325-341`):

```c
	if (len && src && dst && count && count * 2064ul == len) {
		... for (j = 0; j < 2064; j++) d[j] = s[j]; ...
		TZ_LOG("svc 0x1e: identity transform done (%lu bytes)\n", len);
```

Level-1 replaces the inner copy with one call per frame plus a per-block census
line. Function signatures (all `static`, all in `tools/bx510_osal_stub.c`):

```c
static inline uint32_t l1_step(uint32_t x);                          /* §1.2 */
static uint32_t       l1_seed(uint32_t lsn);                         /* §1.2 */
static uint32_t       l1_lsn(const unsigned char *frame);            /* BE32  */
static void           l1_xform(uint32_t lsn, unsigned char *payload); /* §1.2 */
static int            l1_in_area(uint32_t lsn);                       /* §1.3 */
static int            l1_frame(unsigned char *src, unsigned char *dst);
```

```c
static uint32_t l1_lsn(const unsigned char *frame)
{
	return ((uint32_t)frame[0] << 24) | ((uint32_t)frame[1] << 16) |
	       ((uint32_t)frame[2] << 8) | (uint32_t)frame[3];
}

/* One 2064-byte frame: header + 4-byte trailer verbatim, payload transformed
 * when the frame is (a) armed (hdr[4]&1) and (b) inside an encrypted-at-rest
 * area. Returns 1 if the payload was transformed, 0 if passed through. */
static int l1_frame(unsigned char *src, unsigned char *dst)
{
	uint32_t lsn = l1_lsn(src);
	unsigned j;
	int xf = 0;

	memcpy(dst, src, L1_HDR);
	for (j = 0; j < L1_PAYLOAD; j++)
		dst[L1_HDR + j] = src[L1_HDR + j];
	if ((src[4] & 1u) && l1_in_area(lsn)) {
		l1_xform(lsn, dst + L1_HDR);
		xf = 1;
	}
	memcpy(dst + L1_HDR + L1_PAYLOAD, src + L1_HDR + L1_PAYLOAD,
	       L1_FRAME - L1_HDR - L1_PAYLOAD);
	return xf;
}
```

and, inside `tz_set_misc`'s transform arm (`tools/bx510_osal_stub.c:325-338`),
per block — `i` is the existing `unsigned long` loop variable, and this log call
replaces today's `identity transform done` line:

```c
		uint32_t lsn0 = l1_lsn(src);
		uint32_t lsn1 = l1_lsn(src + (count - 1) * L1_FRAME);
		unsigned long xf = 0;
		for (i = 0; i < count; i++)
			xf += l1_frame(src + i * L1_FRAME, dst + i * L1_FRAME);
		TZ_LOG("l1 block: count=%lu lsn=%u..%u xform=%lu pass=%lu armed=%u ks0=%08x\n",
		       count, lsn0, lsn1, xf, count - xf, src[4] & 1u,
		       l1_seed(lsn0));
```

`ks0` is the **KAT carrier**: `l1_seed(lsn)` printed per block, comparable
byte-for-byte against the published table in §2.2 with no payload dependency
(the same reason a keystream byte is the cheapest known-answer test).

Keep the existing shape gate (`len && src && dst && count && count*2064 == len`,
`tools/bx510_osal_stub.c:325`): on a shape mismatch the buffer is left untouched
and the existing `NOT transforming` line prints — never partially write a block.
Keep the `*(unsigned long *)(params + 0x34) = 0x67000000UL` result seed
(`tools/bx510_osal_stub.c:340`) and the `gcpu_cmd_complete()` call
(`:406`) exactly as they are: without the completion the ioctl hangs
(`decrypt-hang.md` §4).

---

## 2. KEY MANAGEMENT

### 2.1 Where the key lives and how both sides agree

| party | holds | agreement mechanism |
|---|---|---|
| stub (guest kernel) | `L1_KEY0`, `L1_KEY1`, `L1_MUL0`, `L1_SALT0/1`, the four range bounds — compile-time constants (§1.2/§1.3) | published KAT (§2.2) compared against the fire's own UART `ks0=` field |
| fixture tool (`tools/bx510_disc_cipher.py`) | the same seven constants, one spelling, beside a comment naming this spec | `selftest` asserts its KAT equals the §2.2 table before it is allowed to write a disc |

Explicitly **not** in scope (do not build it now): EKB parsing
(`vEkbInit` / `bEkbParseTagKey` / `fgSacdSetEkbParam`, `sacdread-cpsa.md` §2.2
`_SACDCLI_FindTag`), the TrustZone secure world, AACS/CPRM key ladders, any key
file on the stick. Level 1 has one key pair, embedded, published.

### 2.2 The published KAT (`l1_seed(lsn)`, §1.2 definition)

These are the numbers every implementation must reproduce; the fire's
`l1 block: … ks0=` field for a block starting at that LSN must equal the third
column, and the fixture tool's `kat` subcommand prints the same table.

| LSN | `l1_seed(lsn)` (what the stub logs as `ks0=`) | first 8 keystream words (LE payload order) | `md5(F(2048 zero bytes))` |
|---|---|---|---|
| 845 | `ca7c8729` | `c5c6a809 dda17d3f becc8ee3 82cedb65 9d7b9067 0197fc5c 3d9c6912 a77058ed` | `095ce3226c3b770bbd58c04f46d8ed5e` |
| 745 | `63c3ab72` | `a4e411c3 a677260f af3e88fb a1b0e977 7e4bbbbf 2eb7bb01 e3290aaa 8df95914` | `17bf4fa3b4cc68a699c1dbffca52ee31` |
| 600 | `c27eeaea` | `1b0a57fb 31859858 eea4ee4f b70316f5 997fd9e7 2a221006 6c7e66f7 b4ba0247` | `1ca401e57cb9a85b7d243fff48a6e195` |
| 510 | `d0b6560f` | `b4dd8054 cf3ff9a9 2f81134e b4b8f9f8 3204b723 38f02f33 9fdc66b8 7266889d` | `db18cac5f808df3155b058207f68d99f` |
| 353750 | `52c16efd` | `32dfc09c 8148fd63 17b34c97 8023e424 b21a0a8a 9a2d56cf 2e617815 2d18cc24` | `e0fc7486c1a5c5868f277868f75c6bdd` |
| 353764 | `e74fd37e` | `2ea023b9 1dd1e669 1f3760cb 1e8af57d 5a73a4e5 f30d61d2 b9d6c769 46412974` | `f44c15569374f257d0302cf9a18b3f3c` |

(`F(zeros)` = the keystream itself, so its md5 is a payload-free fingerprint of
the whole 512-word stream — the strongest cheap cross-language check. LSN 353764
is *outside* both ranges on purpose: it is the first frame of the straddle
read's second block, which must pass through untouched.)

> **IMPLEMENTER CORRECTION (implementer 2, 2026-11-16) — the third column above
> is display-only and self-inconsistent; the seed and `md5(F(zeros))` columns are
> correct.** Found while writing `tools/bx510_disc_cipher.py`: the "first 8
> keystream words (LE payload order)" column mixes two conventions — words 0..3
> are each word's payload bytes in payload order (what a hexdump of `F(zeros)`
> shows), words 4..7 are the little-endian word *integer* — and it carries a
> one-character typo at LSN 845 word 2 (`becc8ee3`; the stream has `becb8ee3`).
> Evidence: the §1.2 C compiled verbatim (`cc -O2 -Wall -Wextra`, throwaway file)
> and the Python mirror write byte-identical 2048-byte `F(zeros)` buffers for all
> six LSNs (`cmp` equal, md5 equal), while the seed and `md5(F(zeros))` columns
> of the table above reproduce exactly for all six rows — so the byte stream, and
> therefore the disc, are unaffected. Corrected column (payload-byte order /
> LE-integer order), LSN 845:
> `c5c6a809 dda17d3f becb8ee3 82cedb65 67907b9d 5cfc9701 12699c3d ed5870a7` /
> `09a8c6c5 3f7da1dd e38ecbbe 65dbce82 9d7b9067 0197fc5c 3d9c6912 a77058ed`;
> LSN 745: `a4e411c3 a677260f af3e88fb a1b0e977 bfbb4b7e 01bbb72e aa0a29e3 1459f98d` /
> `c311e4a4 0f2677a6 fb883eaf 77e9b0a1 7e4bbbbf 2eb7bb01 e3290aaa 8df95914`.
> No normative change: `l1_seed` (the `ks0=` the stub logs) and `md5(F(zeros))`
> — the fingerprint of all 512 words — are what `kat`, `selftest` and `encrypt`
> gate on.

Derived with the §1.2 definition on the Mac, 2026-11-16 (re-derive: §8). The
table was then re-derived a **second, independent way**: the §1.2 C was copied
verbatim into a throwaway file, compiled `cc -O2 -Wall -Wextra` (no warnings),
and run — it prints the same `F(zeros)[0:16]` for all six LSNs, its `l1_frame`
round-trips (`l1_frame(l1_frame(x)) == x`) for the in-area LSNs and passes
510/353764 through untouched, and it keeps the header verbatim. So the C in this
spec is *compiled and checked*, not pseudo-code.

---

## 3. THE FIXTURE SIDE — the derived disc

### 3.1 What gets built, where, and by whom

| item | value |
|---|---|
| source (read-only, must stay untouched) | `/home/you/the verification tree/firebird.iso` on the build host |
| derived disc | `/home/you/the verification tree/firebird-cipher.iso` on the build host |
| geometry | **1064208 sectors, byte-identical outside the two ranges** — same TOC, same master TOC, same PVD, same plaintext gaps, so every client template and every `client-leg-oracles.md` row applies unchanged |
| encrypted at rest | LBA 584..353763 and 353844..1064126, payload `f(lba*2048 .. +2048)` = `l1_xform(lba, ·)` |
| untouched at rest | everything else, in particular 0..583, 510..519, 544..553, 353764..353843, 353804..353813, 1064127..end |
| generator | `tools/bx510_disc_cipher.py` (new file, implementer 2) |
| runs where | **on the VM** (the ISO lives there; a Mac-side build would need a 2.18 GB pull for no gain) |
| size cost | ≈ 2.18 GB (1 063 463 of 1 064 208 sectors are audio — the "delta" is the whole disc, so a qcow2 overlay saves nothing: do not bother) |

Generation is deterministic: same ISO + same tool + same constants ⇒
byte-identical output ⇒ the recorded `sha256(firebird-cipher.iso)` is a
regeneration check. Delete the derived disc after the acceptance battery and
regenerate from the recorded recipe if a later lane needs it (it is 2.18 GB of
VM disk, not evidence).

### 3.2 The tool's interface (normative)

```
tools/bx510_disc_cipher.py
  kat      [--lsn N ...]        print the §2.2 table (no disc needed)
  selftest                      involution + KAT + a synthetic round-trip
  encrypt  --src ISO --dst ISO [--ranges "584-353763,353844-1064126"]
           [--jobs N] [--limit N]
  oracle   --src ISO --lba N --cnt M [--json out.json]
```

`encrypt` must, in this order and refusing loudly at each step:

1. refuse if `--dst` exists or equals `--src`; open `--src` **read-only**;
2. read the two area-TOC sectors (LBA 544 and 353804, both recorded in
   `client-leg-oracles.md:9-18`), parse `trk_start` at byte 72 and `trk_end` at
   byte 76 as **big-endian u32** (the daemon's own fields, `client-leg-oracles.md:10`
   for 584/353763 and `:18` for 353844/1064126), and **refuse** unless they equal
   `--ranges`;
3. print and record `sha256(--src)` and its sector count; refuse unless the count
   is 1064208;
4. copy `--src` → `--dst` (`copy_file_range`/`shutil.copyfile`), then rewrite
   each LSN in the ranges in place with `l1_xform(lba, payload)`; progress every
   65 536 sectors;
5. re-verify `sha256(--src)` is unchanged (the untouched-source invariant) and
   print `sha256(--dst)`.

`--jobs` is the performance knob (§6); `--limit` exists only to time a prefix.

### 3.3 Oracles: the unchanged acceptance table + the negative mirror

The plain column is `decode/client-leg-oracles.md` and **does not change** — the
whole point of the design is that the wire bytes after decryption are still the
ISO's plaintext:

| read | template | plain md5 (acceptance, cipher ON) |
|---|---|---|
| 845 × 1 | `client_d_arearead` A1 | `9079e1fce610663d9f0e50bbd3463e0c` |
| 845 × 32 | `client_d_arearead` A32 | `1df16354392e34456e8a11e174140ba5` |
| 745 × 128 | `client_d_arearead` TRK | `5b5c4f4e411155d46885b5848cefd48d` |
| 353750 × 40 | `client_d_arearead` EDGE | `dffda49fa00fffdaac8c5fddf38a959e` |
| 600 × 1600 | `client_d_arearead` RIP | `2609c51af8831e3e3c9f1eaaf2ce5449` |
| 510 × 10 | `client_a_reconnect` S1/S3, UI template | `45ccd7dfbf433a79d28e877d7441677c` |
| 532104 × 1 | `client_a_reconnect` S2 | `9ed18b47f67232ea972515df65cb6ac5` |

(all rows from `client-leg-oracles.md:24-41`; the five `client_d_arearead`
rows are exactly what c134 reproduced, `run-c130-c134.md:116-122`)

The **negative mirror** is new and must be recorded before the battery: the md5
of the *derived* disc's bytes for the same reads — i.e. what the wire carries
when the cipher is off. Two rows are mandatory; compute the rest for free:

| read | ciphertext md5 (negative control, cipher OFF) | status |
|---|---|---|
| 845 × 1 | _to be filled_ | **REQUIRED artifact** — `oracle --src firebird-cipher.iso --lba 845 --cnt 1` |
| 745 × 128 | _to be filled_ | **REQUIRED artifact** — `… --lba 745 --cnt 128` |
| 845 × 32, 353750 × 40, 600 × 1600, 532104 × 1 | _to be filled_ | cheap, same command |

**Why they are not pre-filled here:** they are md5s of Firebird plaintext that
exists only on the VM, and this stage is explicitly VM-free. Computing them is
one `oracle` invocation per row on the VM, and the same run **must** reproduce
the plain column from the real ISO as a hard cross-check (if the plain column
does not reproduce, the tool or the ISO is wrong and nothing else may proceed).
Record both columns plus `sha256(firebird.iso)`, `sha256(firebird-cipher.iso)`
and the generator's sha256 into
`evidence/bx510-guest/bdpdrv/decode/level1-cipher-oracles.json` (new file,
implementer 2) — the checker reads that file (§5.3).

The decisive shape of the pair: **cipher OFF ⇒ wire md5 == the ciphertext
column (≠ plain); cipher ON ⇒ wire md5 == the plain column.** Metadata rows
(510 × 10) equal the plain column in *both* fires — that single row is the
area-selectivity proof: it is plaintext at rest and still plaintext on the wire
even though it passed through the decrypt ioctl.

---

## 4. THE IMPLEMENTATION SLICE

Three implementers, disjoint files, one seam each (the disc + the KAT table +
the oracle JSON). Nobody edits another's file.

| # | owner file(s) | change | gate before handing off |
|---|---|---|---|
| **1** | `tools/bx510_osal_stub.c` | §1.2–§1.5: the cipher + `l1_frame` + the per-block census line, replacing the identity loop at `:325-341` | the build's `strings` carries `l1 block:`; the staged source's sha256 == the repo copy's |
| **2** | `tools/bx510_disc_cipher.py` (new), `tools/bx510_cipher_check.py` (new), `evidence/…/decode/level1-cipher-oracles.json` (new) | §3.2 generator + `selftest`/`kat`, §3.3 oracle JSON, §5.3 checker | `selftest` PASS and `kat` == §2.2 **before** generating; plain column reproduces |
| **3** | `emulator-kit/player.local.c`, `tools/bx510-fire.sh` (+ verify `emulator-kit/run.py`) | §4.2 header LSN + `sacd-cipher` machine property; §4.3 `BX510_DISC` / `BX510_CIPHER` fire knobs | `qemu-system-arm -M player.local,help` lists `sacd-cipher`; a `DRYRUN=1` fire renders the derived disc path |
### 4.1 Rebuild order (do not reorder)

```
1. implementer 3: model edit  ->  make sacd-emu-build        (QEMU, build.sh, ~4 min — c134 precedent)
2. implementer 1: stub edit   ->  stage 5 files + sh /tmp/bx510_stub_build.sh   (§4.4)
3. implementer 2: disc+tools  ->  scp the tool, run selftest/kat, generate the disc, write the oracle JSON
4. fires c135..c138           (§5) — only after 1–3 gate green
```

The QEMU rebuild comes **first** because every later gate reads a header the new
model writes; a fire against a stale QEMU would show `hdr[4]=0` everywhere and
the transform would silently be identity (failing the audio oracles for a reason
that looks like a cipher bug).

### 4.2 Implementer 3 — the model (`emulator-kit/player.local.c`)

(a) State field, beside the other SATA fields (`player.local.c:112-114`):

```c
    bool sata_cipher;           /* frames carry LSN + ciphertext-at-rest flag */
```

(b) Accessors + property, beside `bx510_get_sata_disc`/`bx510_set_sata_disc`
(`player.local.c:1689-1705`) and registered with the other properties in
`bx510_class_init` (`player.local.c:1718-1731`):

```c
static bool bx510_get_sata_cipher(Object *obj, Error **errp)
{
    return BX510_MACHINE(obj)->sata_cipher;
}

static void bx510_set_sata_cipher(Object *obj, bool value, Error **errp)
{
    BX510_MACHINE(obj)->sata_cipher = value;
}
...
    object_class_property_add_bool(klass, "sacd-cipher",
                                   bx510_get_sata_cipher,
                                   bx510_set_sata_cipher);
    object_class_property_set_description(klass, "sacd-cipher",
        "SACD 2064-byte frames carry hdr[0..3]=LSN (BE) and hdr[4]=1 "
        "(payload is ciphertext at rest) — Level 1 synthetic cipher, "
        "evidence/bx510-guest/bdpdrv/decode/level1-cipher-spec.md");
```

(c) The frame build, `player.local.c:542-560` — the `memset(fr, 0, 12)` at `:556`
becomes:

```c
            memset(fr, 0, 12);
            if (s->sata_cipher) {
                /* Level 1 (evidence/bx510-guest/bdpdrv/decode/level1-cipher-spec.md §1.4): the frame's
                 * header names the sector so the guest's CPSA stand-in can key
                 * its per-sector transform; the driver discards out[0..11]
                 * (sacdread-cpsa.md §3.2), so this is wire-invisible. */
                stl_be_p(fr, lba + i);          /* hdr[0..3] = LSN, BE */
                fr[4] = 0x01;                   /* ciphertext at rest */
            }
```

Nothing else in the model changes: `FE_DMA_MAX` stays `0x200000`
(`player.local.c:341`, the c133 fix), the frame stride stays 2064 (`:344`), the
trailer stays zero (`:558`).

`emulator-kit/run.py` needs **no** edit — `BX510_MACHINE_OPTS` is appended
verbatim to `-M player.local,` (`run.py:14-18`). Verify with a `DRYRUN=1` fire
that the rendered `-M` line reads
`-M player.local,sata-disc=/home/you/the verification tree/firebird-cipher.iso,sacd-cipher=1`.

**Regression invariant to assert in the fire evidence:** with `sacd-cipher` off,
the header is all zeros exactly as at Level 0, and the header never reaches the
wire in either state — so **no wire byte of any Level-0 fire can change because
of this edit**. The only wire-visible change in the whole spec is the stub's
transform. (Check: c138 reproduces the c134 md5 table exactly.)

### 4.3 Implementer 3 — the fire knobs (`tools/bx510-fire.sh:59`)

Replace the single hard-coded line with two knobs, default untouched:

```sh
# DISC: the disc image the emulated drive serves. Default is the real Firebird
# ISO — the Level-0 oracle ground truth, which every fire MUST leave untouched
# (read-only: blk_new_open(..., 0, ...), emulator-kit/player.local.c:1667-1670).
# CIPHER=1 arms the model's sacd-cipher property AND therefore the guest
# stub's transform: only ever pair it with an encrypted-at-rest derived disc
# (evidence/bx510-guest/bdpdrv/decode/level1-cipher-spec.md §3).
DISC="${BX510_DISC:-${DISC:-/home/you/the verification tree/firebird.iso}}"
CIPHER_OPT=",sacd-cipher=1"
CIPHER_STATE=on
case "${BX510_CIPHER:-${CIPHER:-0}}" in
1) ;;
*) CIPHER_OPT=""; CIPHER_STATE=off ;;
esac
export BX510_MACHINE_OPTS="sata-disc=$DISC$CIPHER_OPT"
# fire start, so the transcript self-documents what the run ran with
echo "bx510-fire: run $R — disc=$DISC cipher=$CIPHER_STATE machine-opts: $BX510_MACHINE_OPTS"
```

**IMPLEMENTER CORRECTION (§4.3, 2026-11-16 supervisor ruling).** The snippet as
first written above was `${BX510_CIPHER:+,sacd-cipher=1}`, which arms the
property for *any* non-empty value — `CIPHER=0` included, which would have
transformed the derived disc in **c135** (cipher OFF) and read as a cipher bug.
The flag is therefore gated on `= "1"` (`case … in 1)`), and the disc knob
accepts both its long and short spellings (`${BX510_DISC:-${DISC:-…}}`,
mirrored for CIPHER) because §5.1's call sites pass `DISC=`/`CIPHER=` while this
section names `BX510_DISC`/`BX510_CIPHER`; non-empty wins, `DISC` defaults to
the real ISO, `CIPHER` to `0`. Implemented in `tools/bx510-fire.sh`.

Call sites pass `DISC=…`/`CIPHER=1` through bx510-fire.sh's own env names; the
Makefile needs no change (variables that arrive from the environment are
exported to the recipe, so `RUNID=c136 CIPHER=1 DISC=… make bx510-ui-fire`
works). If a later lane prefers it documented in the target's usage line, that
line lives in `Makefile:600` and then needs `make docs-sync` — otherwise
`make docs-check` stays green with no Makefile edit at all.

### 4.4 Implementer 1 — build and stage the stub (exact commands)

`make sacd-stub-build` is stale in this checkout (C3). The working sequence, as
validated for the C106/TZ fix (`decrypt-hang.md` §4.3):

```sh
for f in tools/bx510_osal_stub.c tools/bx510_clidrive.c \
         tools/bx510_stub_build.sh tools/bx510_vermagic_patch.py \
         tools/bx510_cpsa_peer.c; do
  scp -o BatchMode=yes -P 2222 "$f" user@192.0.2.10:/tmp/
done
make vm-exec CMD='sha256sum /tmp/bx510_osal_stub.c'      # MUST equal sha256sum tools/bx510_osal_stub.c
make vm-exec CMD='sh /tmp/bx510_stub_build.sh'           # -> /tmp/osal_{a,b,c,d}
make vm-exec CMD='strings /tmp/osal_b/bx510_osal_stub.ko | grep "l1 block:"'
make vm-exec CMD='strings /tmp/osal_b/bx510_osal_stub.ko | grep "identity transform done"'
```

Both `strings` checks must hit (the second proves the handler is still the same
function; `decrypt-hang.md` §1.2 is the stale-stub incident that makes the
source-sha256 check non-optional). Pre-existing warnings are only the two C90
`x_snprintf`/`x_sscanf` ones at `tools/bx510_osal_stub.c:156`/`:160`.

> **IMPLEMENTER CORRECTION (implementer 1, supervisor ruling 2026-11-16, run
> 8f9c57e0) — the second `strings` check above is UNSATISFIABLE BY
> CONSTRUCTION; the gate is satisfied in intent by evidence (a)+(b)+(c) below.**
> §1.5 says the new per-block `l1 block:` line *replaces* the `identity transform
> done` line, so that string cannot survive in the built object (grep over the
> repo tree: zero occurrences after the change) — §4.4's `grep "identity
> transform done"` and §1.5's "replaces" cannot both hold. **Ruling: option A —
> §1.5 stands, the identity line stays removed, no code change.** The
> same-handler/not-a-stale-stub intent of the second check is instead proven by:
> **(a)** staged-source sha256 == `sha256sum tools/bx510_osal_stub.c` (the
> non-optional anti-stale check); **(b)** `strings /tmp/osal_b/bx510_osal_stub.ko`
> carries `l1 block:` (both format strings — the new code is in the box);
> **(c)** the three surviving handler strings, `svc 0x1e: no request block`,
> `svc 0x1e: opcode=%#lx src=%#lx dst=%#lx count=%lu len=%lu`, `svc 0x1e: NOT
> transforming (src/dst/count/len shape)` — the handler is still `tz_set_misc`
> with the same shape gate. Checker gate 2 in §5.3 (`l1 block:` present in the
> cipher-on UART) remains the runtime form of the same anti-stale gate.
> Implementer 1's build (2026-11-16): staged sha256 `b9d0b6af…`, all four `.ko`
> built, `buildB.log` warnings = only the two pre-existing C90 ones, (b) and (c)
> confirmed.

Then the cheap payload-budget gate (the stub rides in fe_test_data, C2) — no
boot, no fire lock contention beyond its own:

```sh
python3 tools/bx510_ui_render.py --runid ui-budget \
        --out /tmp/g-ui-budget.txt --script /tmp/bx510_ui_guest-ui-budget.sh
DRYRUN=1 RUNID=ui-budget GCMD_FILE=/tmp/g-ui-budget.txt sh tools/bx510-fire.sh
#   gate: "payload: N B of 1048576 B (M B free)" with M > 0
```

---

## 5. THE ACCEPTANCE BATTERY (fires c135–c138)

One fire at a time (`tools/bx510-fire.sh:38-45` takes
`/tmp/bx510-fire.lock`), unique RUNIDs (traces are `/tmp/bdpdrv-run<RUNID>.*`),
`TIMEOUT=720` — the measured cost of the c134 scenario, unchanged by the cipher
(§6).

| run | disc | `CIPHER` | template | what it proves |
|---|---|---|---|---|
| **c135** | `firebird-cipher.iso` | `0` | `client_d_arearead` | the disc really is ciphertext at rest **and** the harness reads it: audio rows == the ciphertext column, **metadata rows == the plain column** |
| **c136** | `firebird-cipher.iso` | `1` | `client_d_arearead` | **THE ACCEPTANCE**: every row == the plain column ⇒ the stub's per-sector transform inverted the disc exactly |
| **c137** | `firebird-cipher.iso` | `1` | `client_a_reconnect` | the second area (353844..1064126, LBA 532104) decrypts too, TOC stays plaintext across three sessions, reconnect unaffected |
| **c138** | `firebird.iso` (real) | `0` | `client_d_arearead` | Level-0 regression: md5 table == c134's (`run-c130-c134.md:116-122`), `hdr` change wire-invisible, real ISO untouched (read-only open, `player.local.c:1667-1670`) |

c135 vs c136 is the decisive pair: same disc, same script, same everything but
the one machine property.

### 5.1 Render + stage + fire (the c133/c134 recipe, per run)

```sh
RUN=c136 TEMPLATE=tools/bx510_client_d_arearead.sh.in
NAME=bx510_client_d_arearead-$RUN.sh
python3 tools/bx510_ui_render.py --runid $RUN --template $TEMPLATE \
        --script /tmp/$NAME --script-name $NAME --out /tmp/g-$RUN.txt
sh tools/bx510_ui_stage.sh /tmp/$NAME
RUNID=$RUN GCMD_FILE=/tmp/g-$RUN.txt TIMEOUT=720 \
  DISC=/home/you/the verification tree/firebird-cipher.iso CIPHER=1 \
  sh tools/bx510-fire.sh
```

`--script-name` is mandatory: the rendered 85-byte command is
`tar -xzf /res/shim/daemon_payload.tgz -C /res; sh /res/shim/<name>`
(`tools/bx510_ui_render.py:28-31`), and the c130 lesson is that the default name
(`bx510_ui_guest-<runid>.sh`) does not match a client-specific script
(`run-c130-c134.md:12-15`). For `client_a_reconnect` substitute
`TEMPLATE=tools/bx510_client_a_reconnect.sh.in` and
`NAME=bx510_client_a_reconnect-<run>.sh`. `client_b_readfail` is **not** in the
battery (past-EOF is a `result=0` arm with `block_size` 0 ⇒ zero frames
transformed; it adds nothing to the cipher claim) — run it only as an optional
hygiene fire if a later lane needs the failure arm re-baselined.

### 5.2 Evidence to pull per fire (the fire script already does it)

`bx510-fire.sh:95-97` pulls `bdpdrv-run<RUNID>.uart.log` + `.meta.json` and tees
the console into `.fire.txt`; the mmio census stays VM-side by policy. Keep all
four fires' uart transcripts — they are the checker's input.

### 5.3 The checker (`tools/bx510_cipher_check.py`, implementer 2)

```
tools/bx510_cipher_check.py --uart evidence/bx510-guest/bdpdrv/bdpdrv-run<c>.uart.log \
                            --oracles evidence/bx510-guest/bdpdrv/decode/level1-cipher-oracles.json \
                            --expect cipher-on|cipher-off --disc <expected disc path>
```

Gates, all fatal (exit 1) and each reporting the row it checked:

1. `bx510: SATA ATAPI drive attached: <expected disc path> (<N> sectors)` present
   with `N == 1064208` (`player.local.c:1677-1679`) — proves *which* disc the run
   really served (guards the c135/c136 pairing, and proves the real ISO was used
   in c138);
2. at least one `l1 block:` line exists in the cipher-on runs (no line ⇒ the
   stub build in the box is the identity one, C3's stale-stub class);
3. for every oracle row the UART's md5 line (`A1_MD5`, `A32_MD5`, `TRK_MD5`,
   `EDGE_MD5`, `RIP_MD5`, or the reconnect template's own markers) equals the
   column selected by `--expect`;
4. `--expect cipher-off` **additionally** asserts every audio row *differs* from
   the plain column (a pass with equal md5s would mean the derived disc was not
   actually encrypted — the anti-no-op gate);
5. the metadata row (510 × 10) equals the **plain** column in both modes (the
   selectivity proof);
6. the `ks0=` of the block whose `lsn=` starts at 845 equals `ca7c8729`, and the
   lsn-745 block's equals `63c3ab72` (§2.2) — the cross-language KAT;
7. for the EDGE read: some `l1 block:` line reports `xform < count` **or** the
   daemon's split shows as two blocks whose `xform` counts are `count` and `0`
   respectively (the straddle: all of 353750..353763 transformed, all of
   353764..353789 passed). This is the only row that can catch an off-by-one in
   the range table.

> **IMPLEMENTER CORRECTION (implementer 2, 2026-11-16) — three applicability
> gaps in the gate list above, found while writing the checker.** (a) `--expect`
> alone cannot express **c138**: the real ISO is plaintext at rest, so a
> cipher-off fire against it carries the *plain* column (§5's "md5 table ==
> c134's"), while a cipher-off fire against the derived disc carries the
> ciphertext one. `tools/bx510_cipher_check.py` therefore derives the column
> from `--disc` against the oracle file's `source`/`derived` paths, and gate 4 is
> N/A for the source disc (its audio rows MUST equal plain — the anti-no-op gate
> is meaningless there). (b) Gates 5 and 7 are not reachable in the same fire as
> gate 6: the 510×10 metadata row and the 845/745/EDGE reads live in different
> client templates (`client_a_reconnect` vs `client_d_arearead`), so c135/c136/
> c138 report gate 5 N/A and c137 reports gates 6/7 N/A — the selectivity proof
> comes from c137, the audio ones from c136. (c) A partially present template is
> a truncated transcript and fails gate 3 instead of passing on the rows it
> happens to contain. The checker proves all of it with `--selftest` (12
> synthetic fixtures: four positive, eight negative — one per failure mode).

---

## 6. PERFORMANCE

Per sector, `l1_xform` costs 512 iterations of {3 shifts/xors + 1 load-word +
1 xor + 1 store-word} ≈ 4–6 ARM instructions per byte of payload, i.e. ~10–12 k
instructions per sector.

| workload | sectors | instructions | estimate (QEMU TCG, ARMv6) |
|---|---|---|---|
| one 128-sector chunk (262 144 B) | 128 | ~1.4 M | < 10 ms |
| the 600×1600 rip (13 chunks, 3.2 MB) | 1600 | ~17 M | ~0.1–0.5 s |
| the whole c136 battery (A1+A32+TRK+EDGE+RIP + UI's TOC session) | ~1700 | ~18 M | ~0.1–0.5 s |

**Against a 720 s fire this is noise** (`run-c130-c134.md` measured the scenario
at 720 s and the c134 rip runs at ~2 MB/s through the daemon, which is
~100× the transform's cost per byte). No timeout change, no new knob. The one
thing to keep an eye on is the census printk: one `TZ_LOG` per block (~20 lines
per fire) — the *existing* handler already prints one line per 0x1e call
(`tools/bx510_osal_stub.c:325-326`), so the added cadence is zero.

The fixture **generation** is the only place performance matters, and it is
one-time: measured 152 µs/sector in CPython on the Mac (2026-11-16) ⇒
1 063 463 sectors ≈ **162 s** single-process, less on the VM. Knob if it
overruns: `--jobs N` (independent LSN blocks, `os.pwrite` to disjoint offsets);
trigger: a `--limit 4096` timing pre-flight projecting > 600 s.

---

## 7. RISKS + the one decisive check per risk

| # | risk | label | the single decisive check |
|---|---|---|---|
| R1 | The header LSN never survives to the stub (some layer scrubs `[0..11]`) | **INFERRED** that it survives (the DMA and both `copy_*_user` are whole-2064; the driver only discards it on the way out). | the fire's own `l1 block: … lsn=845..` line. If every block logs `lsn=0..0`, the channel is dead → the fallback is a stub-side identity + a finding, **not** a silent pass. `xform=0` in every block ⇒ same verdict. |
| R2 | The two implementations of the keystream disagree (C vs Python) | **VERIFIED** equal at the KAT (both derive from §1.2's single definition; Python re-derives the table in §2.2). | checker gate 6 (`ks0` for LSN 845/745). If the KAT matches but the md5s fail, the bug is in *placement* (offset/length), not in the stream. |
| R3 | An off-by-one in the range table ⇒ one sector per area edge is wrong | **VERIFIED** boundaries from the disc's own TOC fields (`client-leg-oracles.md:9-10`, `:17-18`); **INFERRED** that the daemon's runtime parse agrees to the sector. | checker gate 7 (the EDGE straddle) + the 584 boundary: `600×1600` starts inside area 1, so a wrong low bound shows as a RIP md5 failure, while EDGE covers the high bound. |
| R4 | `CIPHER=1` is paired with the **real** (plaintext) ISO ⇒ the stub XORs music that was never encrypted | **VERIFIED** hazard by construction (nothing in the model knows whether the image is encrypted beyond this flag). | checker gate 1 (`--disc` path) + gate 4 (cipher-off rows *must* differ from plain). A CIPHER=1 run against `firebird.iso` fails the audio rows and passes the metadata rows — a signature no other failure produces. |
| R5 | The real ISO gets modified by the fixture step | **VERIFIED** safe: `blk_new_open(..., 0, ...)` read-only (`player.local.c:1667-1670`); the generator opens `--src` read-only and re-verifies its sha256 (§3.2 step 5). | the recorded `sha256(firebird.iso)` in the oracle JSON, re-checked before and after generation; c138's md5 table == c134's. |
| R6 | The stub lumps a straddling block as all-or-nothing (transforming metadata frames) | **INFERRED** safe: selection is per frame (`l1_frame`), so a split or unsplit straddle both come out right. | EDGE row in c136 (oracle `dffda49f…`) — it is the only read whose block spans the boundary. |
| R7 | VM disk cannot hold the 2.18 GB derived disc | **INFERRED** unknown (no df evidence in the repo). | `df -B1 --output=avail /home/you` ≥ 2.4 GB before generating; else generate, fire, delete per run (regeneration is deterministic + sha256-recorded). |
| R8 | A stale stub `.ko` in the box silently serves identity (the C109 class) | **VERIFIED** that this has happened before (`decrypt-hang.md` §1.2). | the staged-source sha256 check (§4.4) **and** checker gate 2 (`l1 block:` present). |
| R9 | QEMU rebuilt but the fire still runs the old binary | **VERIFIED** the fire takes `~/bx510-emu/emulator/work/build/qemu-system-arm` (`bx510-fire.sh:65`). | `-M player.local,help` lists `sacd-cipher` after the rebuild, and the DRYRUN's `-M` line carries `sacd-cipher=1`. |
| R10 | Level-0 (real disc) behaviour drifts | **VERIFIED** impossible for wire bytes: the header never reaches the wire (`sacdread-cpsa.md:342`), and with the property off the header is byte-identical to Level 0. | c138's md5 table vs the c134 table in `run-c130-c134.md:116-122`. |
| R11 | This transform is mistaken for the real SACD crypto | **VERIFIED** it is not: no EKB, no TZ, no AACS. | this document's §0/§2.1 "not in scope" block; the spec's own KAT is labelled synthetic. Do not let a later lane cite Level-1 as evidence about Sony's cipher. |

---

## 8. Provenance / reproduce

* The KAT table (§2.2) — pure arithmetic, no disc:
  `python3 - <<'PY'` with the §1.2 definition (see §2.2's `md5(F(zeros))`, the
  keystream fingerprint). Re-derived 2026-11-16 on the Mac; `selftest` in
  `tools/bx510_disc_cipher.py` must reproduce it before any disc is written.
* The chain facts: `decrypt-hang.md` §2.3 (`blk[]` layout,
  `0x1715cc–0x1715f8`), `daemon-ioctl-side.md:108`: `+0x04` (LBA) stays 0 on the
  decrypt ioctl, `:264/:272/:273/:380-382`: the plain TOC read path,
  `daemon-socket-protocol.md:293/§4`: unconditional decrypt of every read,
  `sacdread-cpsa.md:341-342`: `kmalloc/copy_*_user(2064*n)` + `out+12`
  compaction, `:369-372`: the 12+2048 frame, `client-leg-oracles.md:9-18` and
  `:24-41`: the two area ranges and the oracle table, `run-c130-c134.md:107-108`
  and `:116-122`: the c134 FE census and the Level-0 md5 table.
* Frame/header facts: `emulator-kit/player.local.c:341` `FE_DMA_MAX`, `:344`
  `CD_SACD`, `:542-560` the SACD frame build (header zeros at `:556`),
  `:112-114` the SATA state fields, `:1667-1679` read-only disc open + the
  `SATA ATAPI drive attached` line, `:1689-1731` the property pattern.
* Fire-path facts: `tools/bx510-fire.sh:38-45` (lock), `:66` (`--stubko`),
  `:59` (the machine opts), `:64-84` (probe argv; the QEMU binary at `:65`),
  `:95-97` (evidence pull);
  `tools/bx510_bdpdrv_stub_probe.py:50-51` (stub packed into fe_test_data),
  `:241` (`--stubko`), `:403-407` + `:490` (the "insmod is the only place a
  parameter travels" pattern, if a module param is ever preferred to the machine
  property); `tools/bx510_ui_build_vm.sh:102-112` (the tgz member list, no
  stub); `emulator-kit/run.py:14-18` (`BX510_MACHINE_OPTS` → `-M`).

## 9. What this stage does NOT decide (deliberately)

* No GCPU/TrustZone, no EKB, no `_SACDCLI_FindTag`, no AACS — the stub is still
  the secure world's stand-in (`decrypt-hang.md` §6.3).
* No new `SACD_IOC_*` command, no `sacd_read.ko` change (Sony binary), no daemon
  change.
* No hardware/parity work (#6): the on-player run is the *next* lane, and it
  will show the real drive's real ciphertext — this spec's transform must not
  be read as a claim about it.
* No UI work: the reactive UI just watches the rip file (`sacd_ui` untouched);
  the c136 frame is evidence, not a gate.
