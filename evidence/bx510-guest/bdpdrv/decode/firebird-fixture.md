# firebird.iso — end-to-end fixture verification for the C97 read path

Status: verified against the live VM copy the rig uses
Date: 2026-11-12
Scope: the disc fixture only. No driver/model decode is re-derived here; the
claims under test are `decode/c97-read-path.md` §4 (addressing + framing),
`docs/DAEMON-MAP.md` §"2064 and 2048", and `docs/large-image-interface.md`
(fixture geometry). Read-only: nothing in `emulator-kit/`, `tools/` or another
worker's files was modified.

Every number below was produced by a tool (VM-side `python3` + `dd`/`md5sum`, and
host-side arithmetic), never by eyeballing a dump. Probe scripts
`/tmp/firebird_fixture_probe{,2,3,4,5}.py` (wrapped for `make vm-script`) and the
two independent re-derivation scripts `/tmp/firebird_verify_{oracles,frames,batch}.sh`;
their raw output is in the appendix, verbatim.

---

## 0. Bottom line

1. **`firebird.iso` is a plain 2048-byte-sector image.** 2,179,497,984 bytes =
   1,064,208 × 2048 exactly, remainder 0. It is *not* 2064-framed and *not*
   2352-framed — a whole-image scan finds **0** occurrences of the CD raw sync
   pattern (`00 FF×10 00`), so there is no raw frame anywhere in the file.
2. **The model's geometry is right and must not change:**
   `blk_getlength()/2048` = 1,064,208 sectors, which is the number the rig
   printed in the C9x meta and the number the daemon reports on the wire.
3. **It is a real Scarlet Book disc**, not a synthetic fixture: genuine
   `SACDMTOC` @LBA 510 (×3 copies), `SACDText` ×8 + `SACD_Man` per copy,
   `TWOCHTOC` and `MULCHTOC` area TOCs at the LBAs the master TOC points at,
   `SACDTRL1/SACDTRL2/SACD_IGL/SACD_ACC` tag blocks, `SACDTTxt` text areas, and
   an ISO9660+UDF bridge filesystem head (PVD @16, terminator @17, `BEA01` @18).
   There is **no** `SACD_WM` watermark block under that name, and **no `SAR`
   marker**: the 60 `SAR` byte-matches in the image are all unaligned
   coincidences inside ciphertext (none at a sector start, none structural). The
   structure the brief called "the SAR/TOC area" is, on this disc, the
   `SACDMTOC` + `SACDText`/`SACD_Man` copies at 510-539 and the `TWOCHTOC`/
   `MULCHTOC` + tag blocks at 544-562 / 353764-353843 / 1064127-1064165.
4. **Verdict — one ISO, both framings, no offset transform:** the 2048 path is a
   straight `pread(lba*2048, n*2048)`. The 2352 path **cannot** be served by
   re-addressing the file: `lba*2352` fetches wrong bytes from LBA 1 on and runs
   off the end at LBA 926,657 (87.1 % of the disc). The model must **synthesize**
   each frame — payload from `lba*2048`, header byte 15 = mode — exactly as
   `c97-read-path.md` §4.2 says. "Per-frame −152 bytes" is not a usable
   transform; the real per-frame gap is 304 bytes (16 header + 288 EDC/ECC in
   mode 1), and it exists because the file has no framing at all.
5. **C97 acceptance oracles** (§5): md5 of the 2048-byte logical sector at
   LBA 16 / 510 / 532104, plus the 10-sector master-TOC batch and the final
   sector. Model-DMA'd bytes, run through the driver's own strip loop, must
   reproduce these hashes bit-for-bit.

---

## 1. Provenance of the asset

| item | value | how |
|---|---|---|
| path (VM, the copy the rig opens) | `/home/aftermath/sacd-verify/firebird.iso` | `make vm-exec CMD='ls -l ~/sacd-verify/firebird.iso'` |
| bytes | 2,179,497,984 | `os.path.getsize` |
| md5 | `217ea92bdb6915dd229055facba43552` | `md5sum` on the VM |
| sha256 | `1d8f0697389ea2a95cf971a4526ffba421cbcc029d529032ea0a155b6b6f68d3` | single streaming pass (`hashlib`, probe 1) |

The sha256 prefix `1d8f0697…` is the one `DELTA.md` already recorded for this
user-supplied rip, so the VM copy is the same disc image the era work used —
now with the full digest recorded.

---

## 2. What the ISO actually contains

### 2.1 Framing discriminator (the decisive test)

Read the master-TOC magic at the offset each candidate sector size implies, and
the ISO9660 PVD at `16 × sector`:

| assumed sector size | `510 × size` → bytes there | `16 × size` → bytes there |
|---:|---|---|
| **2048** | `b'SACDMTOC'` **MATCH** | `01 'CD001' 01` — **PVD** |
| 2064 | 8 × `00` | `        ` |
| 2352 | `No\xfd/\xe9\xc27\xc1` | 8 × `00` |

Only the 2048 column produces structure. Arithmetic agrees: the file length is
0 mod 2048, 672 mod 2064 and 720 mod 2352, and `2064 × 1064208` / `2352 ×
1064208` both exceed the file by 17,027,328 / 323,519,232 bytes. A 2064- or
2352-framed image is ruled out by three independent measurements.

### 2.2 What the image is *not*

* **No raw CD frames.** Whole-image scan for the classic sync pattern
  (`00 FF FF FF FF FF FF FF FF FF FF 00`): **0 hits** in 2,179,497,984 bytes.
  A 2352- or 2064-framed image would contain one per sector (1.06 M of them).
* **No `SACD_WM` watermark tag.** 0 hits. The Scarlet Book tag blocks that *are*
  present are `SACDTRL1`, `SACDTRL2`, `SACD_IGL`, `SACD_ACC` (4 copies each).
* **Not a mountable ISO9660 filesystem** for geometry purposes: the PVD's
  numeric tail does not decode as ISO9660 (§2.4). The daemon never parses it —
  it seeks straight to LBA 510 (`scarletbook_read_master_toc.asm` 0x2a20c:
  `mov r0, #20480` = 510 × 2048, `mov r2, #10` = 10 sectors) — so nothing
  depends on the PVD.

### 2.3 Structure map (measured, first 8 bytes of each sector)

Head zone ("SACD zone", three redundant copies + tag blocks):

```
510  SACDMTOC      master TOC  (version 1.20)
511..518  SACDText ×8
519  SACD_Man      <- the validator's silent final block
520  SACDMTOC      2nd copy        521..528 SACDText ×8   529 SACD_Man
530  SACDMTOC      3rd copy        531..538 SACDText ×8   539 SACD_Man
544  TWOCHTOC      area-TOC copy   545 SACDTRL1 546 SACDTRL2 547 SACD_IGL
549  SACD_ACC      access list     550..562 access-list entries
581  SACDTTxt      track text      583..    track-text index entries
540..543, 548, 563..580, 582: zeros
```

Body (the LBAs the master TOC actually points at — the pointers and the markers
agree, which is the cross-check that the master TOC is being read correctly):

```
353764  TWOCHTOC   <- master TOC area_1_toc_1_start = 353764  (2-channel area TOC, size 40)
353765  SACDTRL1   353766 SACDTRL2   353767 SACD_IGL   353769 SACD_ACC
353801  SACDTTxt   353804 MULCHTOC   <- area_1_toc_2_start = 353804 (second TOC block of area 1;
                                      its id is MULCHTOC — see §2.6 for the open field map)
353805.. SACDTRL1/SACDTRL2/SACD_IGL/SACD_ACC
353844+ 2-channel payload (first sector after both 40-sector TOC blocks; entropy jumps to 7.77 at 353844, 7.9 through the body, §8.5)
1064127 MULCHTOC   <- area_2_toc_1_start = 1064127 (area-2 TOC block)
1064128.. tag blocks; 1064164 SACDTTxt
1064145.. tail metadata (low entropy; 1064160 is an all-zero sector; 1064166 repeats
           the track-text index-table shape seen at LBA 583; the final sector 1064207
           has only 14 nonzero bytes)
```

Sectors 0..15 are all zero (first nonzero byte in the file is at offset 32768 =
LBA 16 + 0), i.e. the classic ISO9660 system area — the model must serve those
16 sectors as real zeros, and a zero-filled page from the block layer is
*correct* there, not a failure.

### 2.4 Head-of-disc filesystem sectors (informational)

| LBA | first bytes | reading |
|---|---|---|
| 16 | `01 'CD001' 01` | ISO9660 PVD; volume id `TOMITA_FIREBIRD_` @40 |
| 17 | `FF 'CD001' 01` | ISO9660 volume-descriptor-set terminator |
| 18 | `00 'BEA01' 01` | UDF "begin extended area" → ISO9660+UDF bridge |

The PVD's volume-space-size pair (`0f 3d 10 00 | 00 10 3d 0f`) decodes to
1,064,207 = total sectors − 1 **only when byte-reversed**, and its
logical-block-size field is misaligned against ISO9660. So: label the PVD
*INFERRED non-ISO9660-conformant*; use the file length, not the PVD, for
geometry. This does not affect either read path.

### 2.5 Master TOC @510 (big-endian on disc — decoded field by field)

```
id                'SACDMTOC'      version 1.20
area_1_toc_1_start      353764    area_1_toc_2_start 353804   <- both verified present, see §2.6
area_2_toc_1_start     1064127    area_2_toc_2_start      0
disc_type @80           0x80      area_1_toc_size @84    40
album/disc catalog @24 / @88   'CDSML8558       '   (CDSML8558 = this disc's catalog)
disc_date_year @120     2019 (month 3, day 19)
text_area_count @128    1
reserved06 @129..135    7×0x00 (byte @136 is 'e', the first locale byte)
locales[8] @136..168    "en" + zeros
```

`disc_date_year @120 / text_area_count @128 / reserved06 / locales @136` are
exactly the offsets `PHASE0-RESULTS.md` Finding 1 established against this same
disc — an independent confirmation that the copy on the VM is the real one (the
probe's 8-byte `reserved06` slice printed 7 zeros plus the `0x65` of the `"en"`
locale; the field itself is clean, which is what the daemon's validator requires).

### 2.6 Area TOC @353764 (`TWOCHTOC`)

```
id 'TWOCHTOC'  version 1.20   size @10 = 40   max_byte_rate @16 = 327680
sample_frequency @20 = 0x04   frame_format @21 = 0x00
channel_count @32 = 2   loudspeaker = 0   max_available_channels = 2   mute = 0
track_count @69 = 6
BE32 @76 = 353763   (both TWOCHTOC copies)      BE32 @80 = 0x01000000   (both copies)
BE32 @76 = 1064126  (both MULCHTOC copies)      BE32 @80 = 0x01000000
```

Two-channel area confirmed (`channel_count = 2`, 6 tracks). **OPEN:** the value
at @76 is always `area_TOC_LBA − 1` (353,763 for the two TWOCHTOC copies,
1,064,126 for the two MULCHTOC copies), and @80 is `0x01000000`
(16,777,216) for all four copies — larger than the disc, so under a 4-byte BE
reading it cannot be an end LSN, and a 3-byte reading of the same bytes gives
65,536 or 0 depending on the start offset. Either the pair is a different field than
`track_start/track_end` or the player clamps it. It does **not** affect C97 (the
model serves bytes; the clamp/decrypt range is `sacd_read.ko`/CPSA's business),
and the settling experiment is the existing trace: dump the daemon's parsed
area-TOC struct (or the `SACD_IOC_READ` LSNs the payload path actually issues)
and compare with these two values.

---

## 3. Geometry math and LBA translation

### 3.1 Sector-count agreement

| quantity | value | check |
|---|---:|---|
| file bytes | 2,179,497,984 | — |
| /2048 | **1,064,208 rem 0** | equals `DISC_SIZE` on the wire (`docs/DAEMON-MAP.md`) and the C9x meta line |
| /2064 | 1,055,958 rem 672 | not this framing |
| /2352 | 926,657 rem 720 | not this framing |
| `1064208 × 2352` | 2,503,017,216 | **323,519,232 bytes past EOF** |
| `1064208 × 2064` | 2,196,525,312 | 17,027,328 bytes past EOF |

So the model's `sectors = blk_getlength(sata_blk)/2048` (IDENTIFY words 100-103)
is correct for this fixture and the LBA unit is 2048. Both alternate divisors
would advertise a capacity the file cannot back.

### 3.2 What a 2352-addressed read would actually fetch (measured)

| LBA | 2048 offset → bytes | 2352 offset → bytes |
|---:|---|---|
| 0 | 0 → `00 00 00 00 00 00 00 00` | 0 → same (only LBA 0 lines up) |
| 1 | 2048 → zeros (system area) | 2352 → zeros (coincidence of the zero area) |
| 16 | 32768 → `01 CD001` | 37632 → zeros (PVD missed) |
| 510 | 1,044,480 → `SACDMTOC` | 1,199,520 → `No\xfd/\xe9\xc27\xc1` **wrong data** |
| 532104 | 1,089,748,992 → audio | 1,251,508,608 → different audio **wrong sector** |
| 926657 | 1,897,793,536 → audio | 2,179,497,264 → the file's last 720 bytes (zeros) |
| 1064207 | 2,179,495,936 → final sector | 2,503,014,864 → **PAST EOF (+323,516,880 B)** |

`delta = lba*352`, i.e. the two addressings diverge linearly and unboundedly —
there is no constant per-frame correction that maps one onto the other. The
reason is structural: the file stores *no* framing bytes, so a 2352 layout must
be *constructed*: `16-byte header (+8 subheader for mode 2) + 2048 payload +
EDC/ECC tail`. The 304-byte gap (mode 1: 16 + 288; mode 2: 24 + 280) is
synthesis padding, not a shift of existing bytes.

### 3.3 The synthesis the model must perform (byte-exact, verified)

```c
/* frame for logical LBA `lba`, mode 1 (data disc; mode 2 form 1 ⇒ byte15 = 2, payload at 24) */
frame[0]      = 0x00;  frame[1..10] = 0xFF×10;  frame[11] = 0x00;   /* sync  */
frame[12..14] = BCD(MSF of (lba + 150));                            /* unread by driver */
frame[15]     = 1;                                                  /* mode — the ONLY byte the driver reads */
memcpy(frame + 16, image + lba*2048, 2048);                         /* payload */
/* frame[2064..2351] = 0 — EDC/ECC, never verified */
```

Round-trip proof, run per LBA in the appendix: feeding those frames through the
driver's own strip loop (`mode = frame[0xf]; ofs = (mode==2) ? 24 : 16;
memcpy(dst, frame+ofs, 2048)`) returns bytes bit-identical to the 2048-byte
sector for every oracle (8/8 `strip-roundtrip True`, single-sector and batch).

**Implementation constraint found while doing this (byte math, not style):** the
MSF header has only two BCD digits for minutes, so a literal
`BCD((lba+150)/4500)` overflows past **LBA 449,849** — at LBA 1,064,207 the raw
minute value is 236 (`0xEC`), i.e. `bcd(236) = 0x176` does not fit a byte. The
driver never looks at bytes 12-14, so the model must mask
(`BCD(mm % 100)`), which is what the verified frames in §5 use. A model that
writes the unmasked value corrupts the mode byte or wraps and is bit-detectably
wrong the moment byte 12 is written out of range.

### 3.4 The 2064 channel is a *different* framing (do not conflate)

`sacdread-cpsa.md` ioctl `0x40105304`: `CPSA_SACDCmdDecrypt(in + 2064*i, out,
2064)` then `memcpy(buf + i*2048, out + 12, 2048)` — the 2064 frame carries a
**12-byte** header and the payload at **+12**. The SATA/ATAPI raw frame carries
the payload at **+16** (mode 1). Two framings, two offsets, both synthesized
from the same 2048-byte payload; the ISO contains neither. Cross-frame
confusion shows up as a constant 4-byte shift, distinct from the 8-byte shift
that a wrong *mode* byte produces (`c97-read-path.md` §6 check 4).

---

## 4. What that implies for the model's dispatch rows

Everything here is *derived from the fixture*, so it constrains rows 21-23 of
`c97-read-path.md` §5.2 without re-decoding the driver:

* **Row 21 (armed READ).** Decode `lba`/`nsec` from the CDB (BE, §4.1 of the
  doc); bounds-check `lba + nsec <= 1064208`; read `nsec × 2048` bytes at
  `lba × 2048` from `sata_blk`; if the opcode is `0xBE` (driver rewrote to READ
  CD, `0x5c404 = nsec × 2352`) emit `nsec` synthesized 2352-byte frames, else
  emit the plain `nsec × 2048` payload; DMA exactly `fe_dma[1]` (`0x5c404`)
  bytes to `fe_dma[0]`. `0x5c404` is the authority and it is always
  `nsec × 2352` or `nsec × 2048`, so it also *is* the framing discriminator when
  the CDB and the length disagree.
* **Row 23 (past EOF).** The last valid LBA is **1,064,207**; a read there must
  *succeed* (md5 `d1c54ec6c395d7092ce06f04705d33ae`) and a read past it must
  post `byte3 != 0` ⇒ `hw_chg_st(priv,5)` ⇒ status `0x51`. Do not clamp silently
  to a short read: the driver sized its buffer from `nsec`, not from a prefix.
* **Zero sectors are legitimate.** LBAs 0-15 are genuinely zero; a page-cache
  page of zeros at that LBA is a *correct* answer, so the `0xbb` poison check
  (`c97-read-path.md` §3.3) is the only cheap way to tell "served zeros" from
  "never DMA'd" — it must be applied on the TOC/PVD oracles, not there.

---

## 5. C97 acceptance oracles (computed from the ISO on the VM)

Primary three (the brief's set), plus the batches the daemon's own TOC reads
produce. All md5s are of bytes taken directly out of
`/home/aftermath/sacd-verify/firebird.iso`; any trace-side hash is compared to
these.

### 5.1 Plain (2048-byte) path — `0x5c404 = nsec × 2048`, or the stripped payload of a raw read

| LBA | cnt | md5 | what it is |
|---:|---:|---|---|
| **16** | 1 | **`c117ce4cef54ab625e33583156605721`** | ISO9660 PVD (`01 CD001`), first structured sector |
| **510** | 1 | **`e56de1add53c90dd30cf9232b29ddc93`** | `SACDMTOC` master TOC sector |
| **532104** | 1 | **`9ed18b47f67232ea972515df65cb6ac5`** | mid-disc audio sector, inside the 2-channel area |
| 510 | 10 | `45ccd7dfbf433a79d28e877d7441677c` | the daemon's master-TOC read (`seek 20480`, 10 sectors) |
| 519 | 1 | `52566a9e355cc1ad1b61956fe01eed7f` | `SACD_Man` — the validator's last block (a silent-failure site) |
| 353764 | 1 | `629827a332999bfb103e86728ca7854e` | `TWOCHTOC` area TOC |
| 353764 | 40 | `c82835e6ddc7c6c18f66d78870baec1f` | area-TOC read (size field = 40 sectors) |
| 353844 | 1 | `4e7937322d9120fbaed7cb2d1ac4c487` | first payload sector after both 40-sector TOC blocks (entropy 7.77) |
| 353844 | 32 | `c3535a7707f3e6fd4513ebc256cd4891` | 32-sector payload batch (the multi-sector read shape) |
| 1064207 | 1 | `d1c54ec6c395d7092ce06f04705d33ae` | **final sector** — the success-side EOF boundary |
| 0 | 1 | `c99a74c555371a433d121f551d6c6398` | system area — legitimate all-zero sector (md5 identical to `md5(2048 × 0x00)`, verified both ways) |
| 1064160 | 1 | `c99a74c555371a433d121f551d6c6398` | all-zero sector *inside* the tail — same hash as LBA 0, i.e. the resident zero bank is real data, not a failed transfer (pair it with the `0xbb` poison check) |

Note the asymmetry in *how strong* each oracle is: LBA 16/510/532104 differ from a
zero page in most bytes (any wrong data is caught immediately), whereas the final
sector 1064207 has only **14** nonzero bytes — a zero-filled DMA there differs from
the truth by 14 bytes and is invisible to a glance. The md5 is mandatory for that
one; it is not decoration.

### 5.2 Raw (2352-frame) path — CDB `0xBE`, `0x5c404 = nsec × 2352`

Synthesized per §3.3 (mode 1, `frame[15] = 1`). These are the *DMA'd* bytes, i.e.
what must land at `fe_dma[0]` before the driver strips them.

| LBA | cnt | md5 of the 2352-byte frame(s) | strip → |
|---:|---:|---|---|
| 16 | 1 | `b8f578e8806bf4debabc28f765281699` | `c117ce4c…` |
| 510 | 1 | `e03d750071d75dfdb006b074a1897b21` | `e56de1ad…` |
| 532104 | 1 | `149a9ff1432a87fec5e71656be195a95` | `9ed18b47…` |
| 510 | 10 | `14690aec4e5333ebed530137f53d4f4a` | `45ccd7df…` (23520 B raw) |
| 1064207 | 1 | `dfaefb598cdde300952201794e826bd7` | `d1c54ec6…` |

Headers used, for eyeball-free comparison (`frame[12:16]`, BCD MSF + mode):
LBA 16 → `00 02 16 01`, LBA 510 → `00 08 60 01`, LBA 532104 → `18 16 54 01`,
final LBA → `36 31 32 01` (minute wrapped `%100`, §3.3).

**Decision rule for the trace:** compare the *stripped* bytes first (framing
independent); if they match, then compare the raw frame hash (framing exact).
A stripped match with raw mismatch means the sync/header cosmetics drifted and
the driver hid it; a stripped *mismatch* in a constant 8-byte pattern means the
mode byte was wrong (mode 2 ⇒ payload at 24); a constant 2048-byte shift means
the CDB LBA was decoded little-endian.

---

## 6. Verdict

**Yes — one ISO file can serve both framings, and the model needs no
offset transform, only a synthesis step.** Concretely:

* plain (`0x28`/`0xA8`): `pread(lba*2048, nsec*2048)` — the file *is* that
  layout, verified by the PVD/TOC markers landing exactly at `lba*2048`;
* raw (`0xBE`): build `nsec` 2352-byte frames from the same `lba*2048` payload
  with `frame[15] = 1` (mode 1) and payload at +16 — verified bit-exact through
  the driver's own strip loop for every oracle, and *not* achievable by reading
  at `lba*2352` (wrong bytes from LBA 1, past EOF from LBA 926,657).

The "per-frame −152 bytes" idea is refuted: the file has no framing bytes to
subtract, and the two addressings diverge as `lba × 352` without bound (§3.2).

---

## 7. Open items

1. **Area-TOC `track_start/track_end` semantics** (§2.6): @76 = `area_TOC_LBA − 1`
   in all four copies and @80 = `0x01000000` (beyond the disc). Settling
   experiment: dump the daemon's parsed area-TOC struct from an existing trace
   (`bdpdrv-runC9x.mmio.log` has no `0x5c4xx` for payload reads yet — the C97
   trace is needed anyway) or observe the LSNs `SACD_IOC_READ` actually issues.
   No C97 dependency.
2. **PVD non-conformance** (§2.4): volume space size stored LE-first,
   logical-block-size field misaligned. Labelled INFERRED; irrelevant to both
   read paths, but a future `--print` path that tried to parse it as ISO9660
   would read garbage.
3. **Whether the guest ever issues a `0xBE` (raw) READ against *this* disc.**
   §4.4 of `c97-read-path.md` still lists the `priv+0x18 ∈ {8,9,10}` trigger as
   INFERRED. Fixture side is ready for both framings; the trace settles which
   one fires (the `0x5c404` value alone answers it: `nsec × 2352` vs
   `nsec × 2048`).
4. **CPSA/decrypt realism.** The audio sectors here are real ciphertext (high
   entropy, no text); `bdpvirt`'s mock decrypt is a verbatim copy, so the *2048*
   oracles remain valid end-to-end, but any oracle that compares *decrypted*
   audio would be comparing ciphertext to ciphertext — label accordingly.

---

## 8. Appendix — raw probe output (verbatim, VM-side)

### 8.1 File + marker scan + framing discriminator (probe 1)

```
== file ==
path  /home/aftermath/sacd-verify/firebird.iso
bytes 2179497984
  /2048 = 1064208 sectors (+0 bytes)
  /2064 = 1055958 sectors (+672 bytes)
  /2352 = 926657 sectors (+720 bytes)
sha256 1d8f0697389ea2a95cf971a4526ffba421cbcc029d529032ea0a155b6b6f68d3

== marker scan (whole image) ==
  SACDMTOC               : 3 occurrence(s)
      off=1044480      LBA@2048=510     (+0)
      off=1064960      LBA@2048=520     (+0)
      off=1085440      LBA@2048=530     (+0)
  TWOCHTOC               : 2 occurrence(s)
      off=1114112      LBA@2048=544     (+0)
      off=724508672    LBA@2048=353764  (+0)
  MULCHTOC               : 2 occurrence(s)
      off=724590592    LBA@2048=353804  (+0)
      off=2179332096   LBA@2048=1064127 (+0)
  SACDText               : 24 occurrence(s)   (8 per master-TOC copy, 3 copies)
  SACD_Man               : 3 occurrence(s)    LBA 519 / 529 / 539
  SACDTTxt               : 4 occurrence(s)    LBA 581 / 353801 / 353841 / 1064164
  CD001                  : 2 occurrence(s)    LBA 16 (+1) / LBA 17 (+1)
  SACD                   : 50 occurrence(s)   (all at sector starts, 0 mod 2048)
  CD-SYNC(00 FF*10 00)   : 0 occurrences

== framing discriminator (master TOC magic @LBA 510) ==
  assume 2048 B/sector -> off 1044480      : b'SACDMTOC' MATCH
  assume 2064 B/sector -> off 1052640      : b'\x00\x00\x00\x00\x00\x00\x00\x00' -
  assume 2352 B/sector -> off 1199520      : b'No\xfd/\xe9\xc27\xc1' -
  PVD  assume 2048 B/sector -> off 32768   : b'\x01CD001\x01\x00' CD001 at +1
  PVD  assume 2064 B/sector -> off 33024   : b'        ' -
  PVD  assume 2352 B/sector -> off 37632   : b'\x00\x00\x00\x00\x00\x00\x00\x00' -
```

### 8.2 Sector hexdumps (2048 addressing, `dd | od`-equivalent)

```
LBA 0 (off 0), first 64 bytes: all 00
LBA 16 (off 32768):
    0000  01 43 44 30 30 31 01 00 20 20 20 20 20 20 20 20  |.CD001..        |
    0020  20 20 20 20 20 20 20 20 54 4f 4d 49 54 41 5f 46  |        TOMITA_F|
    0030  49 52 45 42 49 52 44 5f 20 20 20 20 20 20 20 20  |IREBIRD_        |
    0050  0f 3d 10 00 00 10 3d 0f 00 00 00 00 00 00 00 00  |.=....=.........|
LBA 510 (off 1044480), 168 bytes:
    0000  53 41 43 44 4d 54 4f 43 01 14 00 00 00 00 00 00  |SACDMTOC........|
    0010  00 01 00 01 00 00 00 00 43 44 53 4d 4c 38 35 35  |........CDSML855|
    0020  38 20 20 20 20 20 20 20 01 00 00 05 00 00 00 00  |8       ........|
    0040  00 00 02 20 00 05 65 e4 00 05 66 0c 00 10 3c bf  |... ..e...f...<.|
    0050  80 00 00 00 00 28 00 28 43 44 53 4d 4c 38 35 35  |.....(.(CDSML855|
    0070  00 00 00 00 00 00 00 00 07 e3 03 13 00 00 00 00  |........(year 2019)|
    0080  01 00 00 00 00 00 00 00 65 6e 01 00 00 00 00 00  |........en......|
LBA 511 (off 1046528): 53 41 43 44 54 65 78 74 00 ...   |SACDText|
LBA 519 (off 1062912): 53 41 43 44 5f 4d 61 6e 00 ...   |SACD_Man|
LBA 16 17/18:  17 -> ff 43 44 30 30 31 01 (terminator) ; 18 -> 00 42 45 41 30 31 01 (BEA01)
```

Master TOC decode as printed by probe 1:

```
  id            b'SACDMTOC'  version 1.20
  area_1_toc_1_start @64+4 = 353764
  area_1_toc_2_start       = 353804
  area_2_toc_1_start       = 1064127
  disc_type @80            = 128
  area_1_toc_size @84      = 40
  disc_catalog_number @88  = b'CDSML8558       '
  disc_date_year @120      = 2019 (month 3 day 19)
  text_area_count @128     = 1
  reserved06 @129..136     = b'\x00\x00\x00\x00\x00\x00\x00e'
  locales[8] @136..168     = b'en\x01\x00...'

== area TOC @ LBA 353764 ==
  id            b'TWOCHTOC'  version 1.20
  size @10      = 40        max_byte_rate = 327680
  sample_freq   = 0x04  frame_format = 0x00
  channel_count = 2  loudspeaker = 0  max_avail = 2  mute = 0
  track_count   = 6
  track_start   = 353763    track_end = 16777216     (see §2.6 — OPEN)
  text_area_count = 0
```

### 8.3 Oracles + framing round-trip (probes 2/3)

```
== C97 oracles: single 2048-byte sectors ==
  LBA 0        sector md5 c99a74c555371a433d121f551d6c6398  head b'\x00...'
               frame2352 md5 c09d3d8a2cc2d5517ab548df53d9120d  strip-roundtrip True
  LBA 16       sector md5 c117ce4cef54ab625e33583156605721  head b'\x01CD001\x01\x00'
               frame2352 md5 b8f578e8806bf4debabc28f765281699  strip-roundtrip True
  LBA 510      sector md5 e56de1add53c90dd30cf9232b29ddc93  head b'SACDMTOC'
               frame2352 md5 e03d750071d75dfdb006b074a1897b21  strip-roundtrip True
  LBA 511      sector md5 68e5b97be9a6db48a3d477d77522d47d  head b'SACDText'
  LBA 519      sector md5 52566a9e355cc1ad1b61956fe01eed7f  head b'SACD_Man'
  LBA 353764   sector md5 629827a332999bfb103e86728ca7854e  head b'TWOCHTOC'
               frame2352 md5 dc9b467eeedb8c0eea2f49cb2c6d97f0  strip-roundtrip True
  LBA 532104   sector md5 9ed18b47f67232ea972515df65cb6ac5
               frame2352 md5 149a9ff1432a87fec5e71656be195a95  strip-roundtrip True
  LBA 1064207  sector md5 d1c54ec6c395d7092ce06f04705d33ae
               frame2352 md5 dfaefb598cdde300952201794e826bd7  strip-roundtrip True

== multi-sector batches ==
  LBA 510  cnt 10 (20480 B)   md5 45ccd7dfbf433a79d28e877d7441677c
  LBA 353764 cnt 40 (81920 B) md5 c82835e6ddc7c6c18f66d78870baec1f
  LBA 510  cnt 10 raw-2352 (23520 B) md5 14690aec4e5333ebed530137f53d4f4a  strip==plain True

== LBA translation vs the file (2179497984 bytes) ==
  2048*1064208 = 2179497984  == size: True
  2352*1064208 = 2503017216  (overflow +323519232)
  2352-addressing EOF LBA = 926657  (87.1% of the disc addressable)
  LBA 510      2048off 1044480    b'SACDMTOC'   2352-off fetch = b'No\xfd/\xe9\xc27\xc1'
  LBA 532104   2048off 1089748992 b'!\x17\xfdn\xfbVG\xbb'  2352-off fetch = b"UR\xa2\xa4TTY'"
  LBA 1064207  2048off 2179495936 b'\x02\x00\x02\x00)\x00\x00\x00'  2352-off PAST EOF (by 323516880 B)

== BCD MSF headroom ==
  mm = (lba+150)//4500 ; two BCD digits => valid while mm <= 99
  last LBA with mm<=99: 449849 ; mm at LBA 1064207 = 236
```

### 8.4 Tag-block inventory (probe 3, first hit per copy)

```
SACDTRL1 : LBA 545 / 353765 / 353805 / 1064128
SACDTRL2 : LBA 546 / 353766 / 353806 / 1064129
SACD_IGL : LBA 547 / 353767 / 353807 / 1064130
SACD_ACC : LBA 549 / 353769 / 353809 / 1064132
SACD_WM  : 0 occurrences
```

### 8.5 Entropy probe (probe 5) — where the payload region starts and ends

```
  LBA 353844   entropy 7.772  nonzero 1975/2048  head b'%\x97\xf9\x00\x00\x00\x16\xfb'
  LBA 353845   entropy 7.751  nonzero 2018/2048  head b'!\x17\xfd\xd9o\xba\xcf\x9e'
  LBA 353900   entropy 6.840  nonzero 1973/2048  head b'!\x17\xfd@\n\x05\xff\xff'
  LBA 355000   entropy 7.922  nonzero 2041/2048  head b'!\x17\xfd!B\x0f\x83\x0f'
  LBA 400000   entropy 7.910  nonzero 2037/2048  head b'E\x12\x84\x95s\x03\x0c\x18'
  LBA 532104   entropy 7.907  nonzero 2044/2048  head b'!\x17\xfdn\xfbVG\xbb'
  LBA 900000   entropy 7.914  nonzero 2040/2048  head b'!\x17\xfd\xa9\x9ea\x87\x9f'
  LBA 1064145  entropy 1.960  nonzero  433/2048  head b'\xf6\xa7\x00\x00\x0f\xf7%\x00'
  LBA 1064160  entropy 0.000  nonzero    0/2048  head b'\x00'×8
  LBA 1064166  entropy 1.874  nonzero  491/2048  head b'\x03\x00\x00\x00\x01 St'
  LBA 1064207  entropy 0.082  nonzero   14/2048  head b'\x02\x00\x02\x00)\x00\x00\x00'
```

Read as: payload/ciphertext from 353844 to at least 1,000,000 (entropy ≈ 7.9, with
structured low-entropy "index record" sectors interleaved — the same `E\x14 …
00 00 NN` shape seen in the head zone at 583-615), then metadata and zeros in the
last ~60 sectors.

### 8.6 Independent re-derivation of every oracle (not the probe script)

The probe scripts produced the hashes above; these two runs re-derive them with
different implementations so the table in §5 is not self-certified.

`dd | md5sum` against the plain sectors (no Python in the path):

```
LBA 16 cnt 1  got c117ce4cef54ab625e33583156605721  want c117ce4cef54ab625e33583156605721  MATCH
LBA 510 cnt 1  got e56de1add53c90dd30cf9232b29ddc93  want e56de1add53c90dd30cf9232b29ddc93  MATCH
LBA 532104 cnt 1  got 9ed18b47f67232ea972515df65cb6ac5  want 9ed18b47f67232ea972515df65cb6ac5  MATCH
LBA 510 cnt 10  got 45ccd7dfbf433a79d28e877d7441677c  want 45ccd7dfbf433a79d28e877d7441677c  MATCH
LBA 519 cnt 1  got 52566a9e355cc1ad1b61956fe01eed7f  want 52566a9e355cc1ad1b61956fe01eed7f  MATCH
LBA 353764 cnt 1  got 629827a332999bfb103e86728ca7854e  want 629827a332999bfb103e86728ca7854e  MATCH
LBA 353764 cnt 40  got c82835e6ddc7c6c18f66d78870baec1f  want c82835e6ddc7c6c18f66d78870baec1f  MATCH
LBA 353844 cnt 1  got 4e7937322d9120fbaed7cb2d1ac4c487  want 4e7937322d9120fbaed7cb2d1ac4c487  MATCH
LBA 353844 cnt 32  got c3535a7707f3e6fd4513ebc256cd4891  want c3535a7707f3e6fd4513ebc256cd4891  MATCH
LBA 1064207 cnt 1  got d1c54ec6c395d7092ce06f04705d33ae  want d1c54ec6c395d7092ce06f04705d33ae  MATCH
```

2352 frames built as *literal header bytes* + `dd` payload + 288 zero bytes
(independent of the `frame2352()` helper):

```
LBA 16      hdr 00ffffffffffffffffffff0000021601  got b8f578e8806bf4debabc28f765281699  MATCH
LBA 510     hdr 00ffffffffffffffffffff0000086001  got e03d750071d75dfdb006b074a1897b21  MATCH
LBA 532104  hdr 00ffffffffffffffffffff0018165401  got 149a9ff1432a87fec5e71656be195a95  MATCH
LBA 1064207 hdr 00ffffffffffffffffffff0036313201  got dfaefb598cdde300952201794e826bd7  MATCH
14690aec4e5333ebed530137f53d4f4a  /tmp/frames10.bin  (10-frame batch LBA 510..519, 23520 = 10 × 2352)  MATCH
```

(the 10-frame batch headers run MSF seconds 0x60..0x69, one per LBA, and the
concatenation hashes to the §5.2 `LBA 510 cnt 10` row.)

The 2048-zero page hash used for the zero-sector control was also confirmed both
ways: `python3 -c 'md5(bytes(2048))'` and `dd if=firebird.iso bs=2048
skip=1064160 count=1 | md5sum` both give
`c99a74c555371a433d121f551d6c6398` (= the LBA 0 hash).

### 8.7 Commands used (reproducible)

```sh
make vm-exec CMD='ls -l ~/sacd-verify/firebird.iso; md5sum ~/sacd-verify/firebird.iso'
make vm-script SCRIPT=/tmp/firebird_probe.sh           # file + marker scan + discriminators + oracles
make vm-script SCRIPT=/tmp/firebird_probe2.sh          # structure map, TOC decode, translation table
make vm-script SCRIPT=/tmp/firebird_probe3.sh          # tag markers, area-TOC alignment, final oracles
make vm-script SCRIPT=/tmp/firebird_probe4.sh          # PVD descriptors 17/18, both-endian field check
make vm-script SCRIPT=/tmp/firebird_probe5.sh          # entropy map of the payload/tail boundary
make vm-script SCRIPT=/tmp/firebird_verify_oracles.sh  # dd | md5sum re-derivation, §8.6
make vm-script SCRIPT=/tmp/firebird_verify_frames.sh   # literal-header frame re-derivation, §8.6
make vm-script SCRIPT=/tmp/firebird_verify_batch.sh    # 10-frame raw batch re-derivation, §8.6
```

Nothing was pulled Mac-side (2.0 GiB); every read happened VM-side and only the
text report crossed the channel. `make sacd-py` was not needed — no repo script
was run against the image, so no repo file was touched.
