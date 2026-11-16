#!/usr/bin/env python3
"""bx510_disc_cipher.py — Level-1 synthetic cipher: the fixture-side mirror.

Normative spec: evidence/bx510-guest/bdpdrv/decode/level1-cipher-spec.md
  §1.2  the cipher — this file is a byte-exact mirror of that definition
        (one spelling per concept: l1_step / l1_seed / l1_xform / l1_in_area)
  §1.3  the area-selectivity ranges
  §2.2  the published KAT — `kat` prints it, `selftest` and `encrypt` REFUSE on
        any disagreement
  §3.1  what gets built: a byte-derived copy of the real Firebird ISO with only
        LBA 584..353763 and 353844..1064126 encrypted at rest
  §3.2  this interface (kat / selftest / encrypt / oracle)

NOT a cryptographic scheme and not a model of AACS/SACD keying: it exists so
the guest decrypt path carries real per-sector work (keyed, area-selective,
invertible). The transform is a keystream XOR, so it is self-inverse — the stub
and this tool call the *same* function; there is no inverse to get wrong.

The disc this produces:
  source  /home/you/the verification tree/firebird.iso           (read-only, sha256
                                                              re-verified after)
  output  /home/you/the verification tree/firebird-cipher.iso    (must not exist)
  geometry 1064208 sectors, byte-identical outside the two audio ranges — so
  the master TOC (510..519), the area TOCs (544..553, 353804..353813), the PVD
  and the plaintext gap 353764..353843 are untouched and every
  decode/client-leg-oracles.md row still applies after decryption.

Usage:
  bx510_disc_cipher.py kat      [--lsn N ...]
  bx510_disc_cipher.py selftest
  bx510_disc_cipher.py encrypt  --src ISO --dst ISO [--ranges "584-353763,353844-1064126"]
                                [--jobs N] [--limit N]
  bx510_disc_cipher.py oracle   --src ISO --lba N --cnt M [--json out.json]

Exit codes: 0 pass, 1 refusal / mismatch (every refusal names the step).
"""

import argparse
import hashlib
import json
import os
import shutil
import struct
import sys

# ---------------------------------------------------------------------------
# §1.2 — the cipher. One spelling per concept, mirroring the normative C.
# ---------------------------------------------------------------------------
L1_KEY0 = 0xC0FFEE11      # sector key, stage 1
L1_KEY1 = 0x1BADB002      # sector key, stage 2
L1_MUL0 = 0x9E3779B1      # LSN mixer (golden-ratio odd)
L1_SALT0 = 0x00424C31
L1_SALT1 = 0x5ACD5ACD     # the fixture family's salt (fixture_gen.py:174)
L1_WORDS = 512            # 2048 bytes / 4
L1_PAYLOAD = 2048
L1_HDR = 12
L1_FRAME = 2064

_M32 = 0xFFFFFFFF

# ---------------------------------------------------------------------------
# §1.3 — the two encrypted-at-rest areas, from the disc's OWN area TOCs
# (client-leg-oracles.md:9-18; the same four numbers the daemon reads).
# ---------------------------------------------------------------------------
L1_ENC_START1 = 584
L1_ENC_END1 = 353763
L1_ENC_START2 = 353844
L1_ENC_END2 = 1064126

SECTOR = 2048
TOTAL_SECTORS = 1064208
DEFAULT_RANGES = "584-353763,353844-1064126"

# The two area-TOC sectors, verified by `encrypt` before it writes anything:
# (lba, magic, (trk_start, trk_end)) — §3.2 step 2.
AREA_TOC = (
    (544, b"TWOCHTOC", (L1_ENC_START1, L1_ENC_END1)),
    (353804, b"MULCHTOC", (L1_ENC_START2, L1_ENC_END2)),
)

# ---------------------------------------------------------------------------
# §2.2 — the published KAT: (lsn, l1_seed(lsn), md5(F(2048 zero bytes))).
#
# These two columns are the normative, convention-free ones: the seed is what the
# stub logs as ks0=, and md5(F(zeros)) is the fingerprint of the WHOLE 512-word
# stream (F(zeros) == the keystream), so it subsumes any individual word. Both are
# enforced by `selftest`, by `kat` and by `encrypt` before it writes a disc.
#
# The spec's third column ("first 8 keystream words") is NOT gated: it mixes two
# display conventions — words 0..3 are printed as payload-order bytes, words 4..7
# as the little-endian word integer — and it carries one character typo at LSN 845
# word 2 (`becc8ee3` where the stream has `becb8ee3`). See the IMPLEMENTER
# CORRECTION in the spec §2.2; `kat` prints BOTH conventions so the column can be
# read either way and the discrepancy is visible instead of silent.
# ---------------------------------------------------------------------------
KAT = (
    (845, 0xCA7C8729, "095ce3226c3b770bbd58c04f46d8ed5e"),
    (745, 0x63C3AB72, "17bf4fa3b4cc68a699c1dbffca52ee31"),
    (600, 0xC27EEAEA, "1ca401e57cb9a85b7d243fff48a6e195"),
    (510, 0xD0B6560F, "db18cac5f808df3155b058207f68d99f"),
    (353750, 0x52C16EFD, "e0fc7486c1a5c5868f277868f75c6bdd"),
    (353764, 0xE74FD37E, "f44c15569374f257d0302cf9a18b3f3c"),
)


def l1_step(x):
    """xorshift32 (uint32_t wrap is defined; mask to stay in 32 bits)."""
    x ^= (x << 13) & _M32
    x ^= x >> 17
    x ^= (x << 5) & _M32
    return x & _M32


def l1_seed(lsn):
    """The keystream state for one sector: LSN through two keyed stages."""
    v = ((lsn & _M32) * L1_MUL0) & _M32
    v ^= L1_KEY0 ^ L1_SALT0
    v = l1_step(v)                 # stage 1
    v ^= L1_KEY1 ^ L1_SALT1
    return l1_step(v)              # stage 2


def l1_keystream(lsn):
    """The 512 keystream words for `lsn`: word j is the (j+1)-th step."""
    v = l1_seed(lsn)
    ks = []
    for _ in range(L1_WORDS):
        v = l1_step(v)
        ks.append(v)
    return ks


def l1_xform(lsn, payload):
    """XOR the 2048-byte payload with the sector's keystream, in place.

    Words are assembled little-endian from payload bytes (payload[4j] is the
    low byte) exactly as the §1.2 C does, so the ARM stub and this tool agree
    with no alignment or endianness question. Self-inverse: F(F(p)) == p.
    """
    if len(payload) != L1_PAYLOAD:
        raise ValueError("l1_xform: payload is %d bytes, want %d"
                         % (len(payload), L1_PAYLOAD))
    words = struct.unpack("<%dI" % L1_WORDS, payload)
    ks = l1_keystream(lsn)
    payload[:] = struct.pack("<%dI" % L1_WORDS,
                            *[w ^ k for w, k in zip(words, ks)])
    return payload


def l1_in_area(lsn):
    """§1.3 area selectivity: is this LSN encrypted at rest?"""
    return ((L1_ENC_START1 <= lsn <= L1_ENC_END1) or
            (L1_ENC_START2 <= lsn <= L1_ENC_END2))


# ---------------------------------------------------------------------------
# §1.4/§1.5 frame layer — the same shape the stub sees: 12-byte header
# (hdr[0..3] = LSN big-endian, hdr[4] = 0x01 ciphertext-at-rest), 2048-byte
# payload, 4 trailing bytes. Header and trailer pass through verbatim.
# ---------------------------------------------------------------------------
def l1_lsn(frame):
    """hdr[0..3] as a big-endian u32 (the disc's own byte order)."""
    return struct.unpack(">I", bytes(frame[0:4]))[0]


def l1_frame(src, dst):
    """One 2064-byte frame: transform the payload iff armed AND in area.

    Returns 1 if the payload was transformed, 0 if passed through.
    """
    if len(src) != L1_FRAME or len(dst) != L1_FRAME:
        raise ValueError("l1_frame: frame is not %d bytes" % L1_FRAME)
    lsn = l1_lsn(src)
    dst[0:L1_FRAME] = src[0:L1_FRAME]
    if (src[4] & 1) and l1_in_area(lsn):
        l1_xform(lsn, memoryview(dst)[L1_HDR:L1_HDR + L1_PAYLOAD])
        return 1
    return 0


# ---------------------------------------------------------------------------
# KAT
# ---------------------------------------------------------------------------
def kat_row(lsn):
    """Derive the §2.2 row for `lsn` from the definition above.

    first8_bytes is the keystream's first 32 payload bytes in payload order
    (what a hexdump of F(zeros) shows); first8_words is the same 8 words as the
    little-endian integers the C assembles (`%08x % w`).
    """
    zero = bytearray(L1_PAYLOAD)
    ks = l1_keystream(lsn)
    md5 = hashlib.md5(l1_xform(lsn, zero)).hexdigest()
    return {"lsn": lsn, "seed": l1_seed(lsn),
            "first8_bytes": [struct.pack("<I", w).hex() for w in ks[:8]],
            "first8_words": ks[:8],
            "md5_f_zeros": md5}


def verify_kat(lns=None):
    """Compare derived KAT rows against the published table; refusal list out."""
    rows = KAT if lns is None else [r for r in KAT if r[0] in set(lns)]
    bad = []
    for lsn, seed, md5 in rows:
        got = kat_row(lsn)
        if got["seed"] != seed:
            bad.append("lsn %d seed %08x != published %08x"
                       % (lsn, got["seed"], seed))
        if got["md5_f_zeros"] != md5:
            bad.append("lsn %d md5(F(zeros)) %s != published %s"
                       % (lsn, got["md5_f_zeros"], md5))
    return bad


def cmd_kat(args):
    lns = args.lsn or [r[0] for r in KAT]
    print("Level-1 KAT (spec §2.2) — derived from tools/bx510_disc_cipher.py §1.2")
    print("%-7s %-9s %-33s %-33s %-32s %s"
          % ("LSN", "l1_seed", "ks[0..7] payload bytes", "ks[0..7] LE words",
             "md5(F(zeros))", "published"))
    for lsn in lns:
        got = kat_row(lsn)
        pub = [r for r in KAT if r[0] == lsn]
        note = ("seed+md5 OK" if pub and not verify_kat([lsn])
                else "seed/md5 MISMATCH") if pub else "(unpublished LSN)"
        print("%-7d %08x  %s  %s  %s  %s"
              % (lsn, got["seed"],
                 " ".join(got["first8_bytes"]),
                 " ".join("%08x" % w for w in got["first8_words"]),
                 got["md5_f_zeros"], note))
    bad = verify_kat([r[0] for r in KAT if not lns or r[0] in lns])
    if bad:
        for b in bad:
            print("KAT FAIL: %s" % b)
        return 1
    print("KAT PASS: seed + md5(F(zeros)) equal the published §2.2 table for "
          "every row above (the third column is display-only, see §2.2)")
    return 0


# ---------------------------------------------------------------------------
# selftest
# ---------------------------------------------------------------------------
def cmd_selftest(_args):
    fails = []

    # 1. the published KAT (§2.2) — all six rows, three columns each
    bad = verify_kat()
    print("selftest 1/4 KAT §2.2............ %s" % ("PASS" if not bad else "FAIL"))
    fails.extend(bad)

    # 2. involution F(F(p)) == p, and F(p) != p (the stream is not zero)
    payload = bytearray(os.urandom(L1_PAYLOAD))
    orig = bytes(payload)
    once = bytes(l1_xform(845, bytearray(orig)))
    twice = bytes(l1_xform(845, bytearray(once)))
    inv = (twice == orig) and (once != orig)
    print("selftest 2/4 involution F(F(p))==p %s" % ("PASS" if inv else "FAIL"))
    if not inv:
        fails.append("involution: F(F(p)) != p or F(p) == p for lsn 845")

    # 3. per-sector keying: unrelated LSNs give unrelated streams
    same = l1_keystream(845) == l1_keystream(745)
    print("selftest 3/4 per-sector keying... %s" % ("PASS" if not same else "FAIL"))
    if same:
        fails.append("per-sector keying: keystream(845) == keystream(745)")

    # 4. frame-level round-trip (§1.4/§1.5): header + trailer verbatim, payload
    #    transformed only for an armed in-area LSN, and 510 / 353764 pass through.
    frame_fails = []
    for lsn, want_xf in ((845, 1), (353750, 1), (353844, 1),
                         (510, 0), (353764, 0), (583, 0), (1064127, 0)):
        fr = bytearray(os.urandom(L1_FRAME))
        fr[0:4] = struct.pack(">I", lsn)
        fr[4] = 0x01
        orig_fr = bytes(fr)
        out = bytearray(L1_FRAME)
        xf = l1_frame(fr, out)
        if xf != want_xf:
            frame_fails.append("lsn %d: xform=%d want %d" % (lsn, xf, want_xf))
        if bytes(out)[0:L1_HDR] != orig_fr[0:L1_HDR]:
            frame_fails.append("lsn %d: header not verbatim" % lsn)
        if bytes(out)[L1_HDR + L1_PAYLOAD:] != orig_fr[L1_HDR + L1_PAYLOAD:]:
            frame_fails.append("lsn %d: trailer not verbatim" % lsn)
        if want_xf and bytes(out)[L1_HDR:L1_HDR + L1_PAYLOAD] == \
                orig_fr[L1_HDR:L1_HDR + L1_PAYLOAD]:
            frame_fails.append("lsn %d: in-area payload not transformed" % lsn)
        if not want_xf and bytes(out) != orig_fr:
            frame_fails.append("lsn %d: out-of-area frame modified" % lsn)
        back = bytearray(L1_FRAME)
        l1_frame(out, back)
        if bytes(back) != orig_fr:
            frame_fails.append("lsn %d: frame round-trip != original" % lsn)
    # disarmed frame (Level-0 disc): identity, header untouched
    fr = bytearray(os.urandom(L1_FRAME))
    fr[0:4] = struct.pack(">I", 845)
    fr[4] = 0x00
    out = bytearray(L1_FRAME)
    if l1_frame(bytes(fr), out) != 0 or bytes(out) != bytes(fr):
        frame_fails.append("lsn 845 disarmed: not identity")
    print("selftest 4/4 frame round-trip.... %s" % ("PASS" if not frame_fails else "FAIL"))
    fails.extend(frame_fails)

    if fails:
        for f in fails:
            print("SELFTEST FAIL: %s" % f)
        return 1
    print("SELFTEST PASS")
    return 0


# ---------------------------------------------------------------------------
# encrypt — §3.2
# ---------------------------------------------------------------------------
def parse_ranges(text):
    out = []
    for part in text.split(","):
        part = part.strip()
        if not part:
            continue
        lo, hi = part.split("-")
        out.append((int(lo), int(hi)))
    return out


def sha256_file(path, chunk=1 << 22):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def _encrypt_chunk(job):
    """Transform one contiguous in-area LSN span of `dst` in place."""
    dst, lo, hi, label = job
    fd = os.open(dst, os.O_RDWR)
    transformed = 0
    try:
        base = lo
        while base <= hi:
            n = min(1024, hi - base + 1)
            buf = bytearray(os.pread(fd, n * SECTOR, base * SECTOR))
            if len(buf) != n * SECTOR:
                raise SystemExit("encrypt: short read at lsn %d (%d of %d bytes)"
                                 % (base, len(buf), n * SECTOR))
            mv = memoryview(buf)
            for i in range(n):
                l1_xform(base + i, mv[i * SECTOR:(i + 1) * SECTOR])
            os.pwrite(fd, buf, base * SECTOR)
            transformed += n
            base += n
            if transformed % 65536 < n:
                print("  %s: %d/%d sectors" % (label, transformed, hi - lo + 1))
                sys.stdout.flush()
    finally:
        os.close(fd)
    return transformed


def cmd_encrypt(args):
    ranges = parse_ranges(args.ranges)
    want = parse_ranges(DEFAULT_RANGES)
    if ranges != want:
        print("REFUSED (step 0): --ranges %s != the spec's two areas %s "
              "(§1.3; the stub holds a static copy of these four numbers)"
              % (ranges, want))
        return 1

    # step 0 (spec §2.1): never write a disc the KAT does not agree with
    bad = verify_kat()
    if bad:
        for b in bad:
            print("REFUSED (step 0): KAT mismatch: %s" % b)
        return 1

    src, dst = args.src, args.dst
    if os.path.exists(dst):
        print("REFUSED (step 1): --dst %s already exists" % dst)
        return 1
    if os.path.realpath(dst) == os.path.realpath(src):
        print("REFUSED (step 1): --dst is --src (%s)" % dst)
        return 1
    try:
        fsrc = open(src, "rb")
    except OSError as e:
        print("REFUSED (step 1): cannot open --src read-only: %s" % e)
        return 1

    with fsrc:
        # step 2: the disc's own area TOCs must still name the spec's ranges
        for lba, magic, (start, end) in AREA_TOC:
            fsrc.seek(lba * SECTOR)
            sec = fsrc.read(SECTOR)
            if len(sec) != SECTOR:
                print("REFUSED (step 2): area TOC sector %d unreadable" % lba)
                return 1
            if sec[:8] != magic:
                print("REFUSED (step 2): lba %d magic %r != %r"
                      % (lba, sec[:8], magic))
                return 1
            t_start, t_end = struct.unpack(">I", sec[72:76])[0], struct.unpack(">I", sec[76:80])[0]
            if (t_start, t_end) != (start, end):
                print("REFUSED (step 2): lba %d trk_start/trk_end %d..%d != "
                      "spec %d..%d (client-leg-oracles.md:9-18)"
                      % (lba, t_start, t_end, start, end))
                return 1
            print("step 2: lba %d %s trk_start=%d trk_end=%d == spec"
                  % (lba, magic.decode(), t_start, t_end))

        # step 3: geometry + source fingerprint
        size = os.fstat(fsrc.fileno()).st_size
        if size % SECTOR:
            print("REFUSED (step 3): --src size %d is not a whole sector" % size)
            return 1
        sectors = size // SECTOR
        if sectors != TOTAL_SECTORS:
            print("REFUSED (step 3): --src has %d sectors, want %d" % (sectors, TOTAL_SECTORS))
            return 1
        src_sha = sha256_file(src)
        print("step 3: --src %s %d sectors sha256=%s" % (src, sectors, src_sha))

    # step 4: copy, then rewrite the in-area payloads in place
    jobs = []
    for lo, hi in ranges:
        if args.limit is not None:
            hi = min(hi, lo + args.limit - 1)
        jobs.append((dst, lo, hi, "%d-%d" % (lo, hi)))
    total = sum(hi - lo + 1 for _, lo, hi, _ in jobs)

    shutil.copyfile(src, dst)
    print("step 4: copied %s -> %s (%d bytes)" % (src, dst, size))
    if args.limit is not None:
        print("WARNING: --limit %d — only %d of the %d in-area sectors are "
              "transformed; this output is a TIMING PREFIX, not a usable "
              "fixture disc." % (args.limit, total, sum(hi - lo + 1 for lo, hi in want)))

    if args.jobs and args.jobs > 1:
        from multiprocessing import Pool
        with Pool(args.jobs) as pool:
            counts = pool.map(_encrypt_chunk, jobs)
        transformed = sum(counts)
    else:
        transformed = sum(_encrypt_chunk(j) for j in jobs)
    print("step 4: transformed %d sectors in %d range(s)" % (transformed, len(jobs)))

    # step 5: the untouched-source invariant + the derived-disc fingerprint
    src_sha2 = sha256_file(src)
    if src_sha2 != src_sha:
        print("FAILED (step 5): --src changed during generation! %s -> %s"
              % (src_sha, src_sha2))
        return 1
    dst_sha = sha256_file(dst)
    print("step 5: --src sha256 unchanged: %s" % src_sha2)
    print("step 5: --dst %s %d sectors sha256=%s" % (dst, sectors, dst_sha))
    print("ENCRYPT PASS")
    return 0


# ---------------------------------------------------------------------------
# oracle — §3.2/§3.3: the md5 the wire carries for one contiguous read
# ---------------------------------------------------------------------------
def oracle_md5(path, lba, cnt):
    """md5 of cnt sectors starting at lba — the `dd bs=2048 skip=lba count=cnt`
    oracle form used for client-leg-oracles.md, so the plain column reproduces
    byte-for-byte and the same command against the derived disc yields the
    ciphertext negative-control column."""
    h = hashlib.md5()
    with open(path, "rb") as f:
        f.seek(lba * SECTOR)
        want = cnt * SECTOR
        got = 0
        while got < want:
            b = f.read(want - got)
            if not b:
                break
            h.update(b)
            got += len(b)
    if got != want:
        raise SystemExit("oracle: %s short read at lba %d cnt %d (%d of %d bytes)"
                         % (path, lba, cnt, got, want))
    return h.hexdigest()


def cmd_oracle(args):
    md5 = oracle_md5(args.src, args.lba, args.cnt)
    print("%s  lba=%d cnt=%d bytes=%d" % (md5, args.lba, args.cnt, args.cnt * SECTOR))
    if args.json:
        with open(args.json, "w") as f:
            json.dump({"src": args.src, "lba": args.lba, "cnt": args.cnt,
                       "bytes": args.cnt * SECTOR, "md5": md5}, f, indent=2)
            f.write("\n")
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("kat", help="print the §2.2 KAT and compare it")
    p.add_argument("--lsn", type=int, action="append")
    p.set_defaults(func=cmd_kat)

    p = sub.add_parser("selftest", help="involution + KAT + frame round-trip")
    p.set_defaults(func=cmd_selftest)

    p = sub.add_parser("encrypt", help="derive the encrypted-at-rest disc")
    p.add_argument("--src", required=True)
    p.add_argument("--dst", required=True)
    p.add_argument("--ranges", default=DEFAULT_RANGES)
    p.add_argument("--jobs", type=int, default=1)
    p.add_argument("--limit", type=int, default=None,
                   help="transform only the first N in-area sectors (timing only)")
    p.set_defaults(func=cmd_encrypt)

    p = sub.add_parser("oracle", help="md5 of one contiguous read")
    p.add_argument("--src", required=True)
    p.add_argument("--lba", type=int, required=True)
    p.add_argument("--cnt", type=int, required=True)
    p.add_argument("--json", default=None)
    p.set_defaults(func=cmd_oracle)

    args = ap.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
