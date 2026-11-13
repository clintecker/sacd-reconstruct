# FE tag-partition fixtures — build + VM apply record

Turns `decode/fe-tags.md` §4 into runnable artifacts: three page-0 records generated
Mac-side, written into the rig image's partitions on the Lab VM, verified by readback.
**No emulator run was fired** — that stays with the parent. The gate to look for in
the next run is §4.3 of `fe-tags.md`, listed at the bottom.

Status at end of this build: **APPLIED** to `/tmp/images-fe/nand.img`
(md5 `1ddc0b62fb04ac57e69a0e875046cdef`, was `88da7e1635e122fb00483a6a20bf8401`).
Restore is one command (§6).

---

## 1. Artifacts

| path | what it is |
|---|---|
| `decode/build_fe_tag_fixtures.py` | fixture generator — stdlib only, deterministic, self-verifying, `--strict` provenance gate |
| `decode/apply_tag_fixtures.sh` | VM-side writer/verifier — resolves offsets from the image's own `manifest.json`, backs up, dd-writes, readback-verifies |
| `fixtures/fe_power_curve.bin` | 0x420 B |
| `fixtures/fe_test_data.bin` | 0x2020 B |
| `fixtures/fe_parameters.bin` | 0x2000 B |

Each blob is **exactly the byte count the driver asks for at partition offset 0**, so
dd-ing it at the partition offset leaves the remaining 1 MiB of each partition erased
(`0xFF`) — §4.2's "everything else stays 0xFF" without needing to rewrite the partition.

| fixture | tag | total_len | payload | slack | checksum | md5 | sha256 |
|---|---|---|---|---|---|---|---|
| `fe_power_curve.bin` | `PWRC` | 0x410 | 0x400 | 0x10 | 0x000107fb | `b1e05b13dc2a7880b4a947ed3cd151b4` | `efb22f530c77e651135bc98c76eee61fe2e78e71bc9ca77eb9f88e546ec6de9d` |
| `fe_test_data.bin` | `FATB` | 0x2010 | 0x2000 | 0x10 | 0x0008101f | `086a3f6031f4ad40f70faea70fa4f69e` | `e2812ac4bac334c1e303f1f8420e927b7301c9a3fecee048c1e70cb00b54dcf6` |
| `fe_parameters.bin` | `PARM` | 0x2000 | 0x1FF0 | 0x00 | 0x00083fbc | `9866500e5a09b1cac02d676bcea37203` | `8a9916d88b28cf23c5258069ea3ec1c780d62df037158b4ba1cb8d588c9dac25` |

Header bytes as written (od, first 16 of each — this is the layout §2 of `fe-tags.md`
VERIFIES, reproduced by tool, not by eye):

```
PWRC  50 57 52 43 | 00 00 00 00 | 10 04 00 00 | fb 07 01 00   tag | +0x04 unused | total_len | checksum
FATB  46 41 54 42 | 00 00 00 00 | 10 20 00 00 | 1f 10 08 00
PARM  50 41 52 4d | 00 00 00 00 | 00 20 00 00 | bc 3f 08 00
```

Checksum re-derived independently of the generator (payload summed with `od -tu1`,
compared against the stored `+0x0c` LE word): match for all three. The generator's own
`verify_record()` re-checks tag, `total_len`, checksum, `+0x04` round-trip, blob length
and payload label on every build; a corrupt recipe fails the build, it does not ship.

## 2. Field provenance (what the doc settles, what it does not)

`FIELD_PROVENANCE` in the generator carries this table; `--strict` refuses to build
while an INFERRED field is still at its default.

| field | label | basis |
|---|---|---|
| `tag` (`PWRC`/`FATB`/`PARM` at +0x00) | VERIFIED | strings read from `.data+0x10/+0x24/+0x38` at the three `strncmp` sites (`fe-tags.md` §1.1–1.3). `PWRC`, **not** the fw-header spelling `POWC` (§3, §7.4). |
| `hdr_unused` (+0x04) | **INFERRED** | no instruction in the three checksum/tag blocks reads it (§2 "UNKNOWN/unused"); written as 0 so a genuine factory sequence/version word is not imitated. §7.3 is unsettled. **This is the one field `--strict` gates** (`--hdr-unused 0`). |
| `total_len` (+0x08 LE) | VERIFIED | 16 + payload; read lengths are the callers' `r10`/`PARM.f2` (§1.1–1.3). |
| `checksum` (+0x0c LE) | VERIFIED | byte-wise running sum, 32-bit wrapping, over `[0x10, total_len)` (§2, `.text+0x1bbc..0x1be8`). Not the `fe_bin_1` BE-dword sum. |
| `payload_contents` | **SYNTHETIC** | the driver never interprets the payload — it only `memcpy`s `POWC.f2`/`FATB.f2`/`PARM.f2` bytes into FE DRAM; FE-side acceptance is INFERRED (§5). Payloads are therefore self-identifying ASCII labels, cycled to the exact length (`BX510 FE POWER CURVE FIXTURE (SYNTHETIC - NOT FACTORY DATA) v1\n` etc.), so no hexdump of this region can be mistaken for factory data. |

## 3. Build (Mac)

```sh
python3 evidence/bx510-guest/bdpdrv/decode/build_fe_tag_fixtures.py     # -> fixtures/*.bin, rc=0
python3 evidence/bx510-guest/bdpdrv/decode/build_fe_tag_fixtures.py --strict   # -> rc=2, names hdr_unused
python3 evidence/bx510-guest/bdpdrv/decode/build_fe_tag_fixtures.py --strict --hdr-unused 0   # -> rc=0
```

Deterministic: re-running reproduces the md5s in §1 byte-for-byte (no timestamps, no
randomness; payload fill is a cycled constant label).

## 4. Apply (Lab VM)

```sh
make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/fixtures/fe_power_curve.bin
make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/fixtures/fe_test_data.bin
make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/fixtures/fe_parameters.bin
make vm-script SCRIPT=evidence/bx510-guest/bdpdrv/decode/apply_tag_fixtures.sh
```

`make vm-script` runs `sh <script>` — correct for this shell script, and *not* usable
for the Python probes (they need `make vm-exec CMD='python3 /tmp/x.py'`).

Offsets used were read from `/tmp/images-fe/manifest.json` **inside the script** by
partition name; the §4.2 constants are printed only as a cross-check:

```
fe_power_curve: manifest offset 0x01000000 (fe-tags.md §4.2: 0x01000000 — SAME), partition 0x100000 B, fixture 0x420 B
fe_test_data: manifest offset 0x00e00000 (fe-tags.md §4.2: 0x00e00000 — SAME), partition 0x100000 B, fixture 0x2020 B
fe_parameters: manifest offset 0x00f00000 (fe-tags.md §4.2: 0x00f00000 — SAME), partition 0x100000 B, fixture 0x2000 B
```

### 4.1 Applied state

```
== image state before ==
image:       /tmp/images-fe/nand.img (268435456 B)
image md5:   88da7e1635e122fb00483a6a20bf8401          <- matches fe-tags.md §3
backup:      wrote /tmp/nand.img.bak-TAGFIX (268435456 B, md5 88da7e1635e122fb00483a6a20bf8401)
state:       image still identical to backup (fixtures not applied before)

== verify (dd readback vs fixture) ==
fe_power_curve @ 0x01000000 len 0x420
  fixture md5 b1e05b13dc2a7880b4a947ed3cd151b4
  image   md5 b1e05b13dc2a7880b4a947ed3cd151b4  OK
  header:  50 57 52 43 00 00 00 00 10 04 00 00 fb 07 01 00
fe_test_data @ 0x00e00000 len 0x2020
  fixture md5 086a3f6031f4ad40f70faea70fa4f69e
  image   md5 086a3f6031f4ad40f70faea70fa4f69e  OK
  header:  46 41 54 42 00 00 00 00 10 20 00 00 1f 10 08 00
fe_parameters @ 0x00f00000 len 0x2000
  fixture md5 9866500e5a09b1cac02d676bcea37203
  image   md5 9866500e5a09b1cac02d676bcea37203  OK
  header:  50 41 52 4d 00 00 00 00 00 20 00 00 bc 3f 08 00

== region md5s in /tmp/images-fe/nand.img ==
fe_power_curve 0x01000000+0x420 b1e05b13dc2a7880b4a947ed3cd151b4
fe_test_data 0x00e00000+0x2020 086a3f6031f4ad40f70faea70fa4f69e
fe_parameters 0x00f00000+0x2000 9866500e5a09b1cac02d676bcea37203

image md5 after: 1ddc0b62fb04ac57e69a0e875046cdef
APPLIED — three fixtures verified in place; backup at /tmp/nand.img.bak-TAGFIX
```

Backup `/tmp/nand.img.bak-TAGFIX` = pre-fixture image. The script skips the backup if
it already exists, so re-running never overwrites the original bytes.

### 4.2 Independent confirmations (not from the writer script)

Byte provenance with the pre-existing probe (`decode/fe_tags_probe.py`, unchanged,
`make vm-exec CMD='python3 /tmp/fe_tags_probe.py'`):

```
fe_test_data  @ 0x00e00000: head=4641544200000000102000001f1008004258353130204645204641205441424c distinct-bytes-in-1MiB=31
fe_parameters @ 0x00f00000: head=5041524d0000000000200000bc3f0800425835313020464520504152414d4554 distinct-bytes-in-1MiB=32
fe_power_curve @ 0x01000000: head=505752430000000010040000fb070100425835313020464520504f5745522043 distinct-bytes-in-1MiB=35
```

Before: `head=ffff…`, `distinct-bytes-in-1MiB=1` for all three. Now the head decodes as
the expected tag and the partition is no longer a uniform fill. (`fe_bin_1`/`fe_bin_2`
still read `head=cddfd0ad…`, 256 distinct — untouched real firmware.)

Blast radius, image vs backup over the whole 256 MiB (a byte-diff, staged from `/tmp`,
not added to the repo):

```
image size 0x10000000; differing byte ranges: 3
  0x00e00000..0x00e0201f  len=0x2020
  0x00f00000..0x00f01fff  len=0x2000
  0x01000000..0x0100041f  len=0x420
```

Exactly the three fixture extents and nothing else — the injection is scoped to the
three partitions `fe-tags.md` names.

## 5. What the next emulator run should show (parent's gate, `fe-tags.md` §4.3)

In order, from the UART log:

1. `[IDE]<xfer_int_ldr_fw> read pwr_curve len: %d OK.` replaces `read power curve failed !!`
2. `Read FA table len: %d OK.` **without** the preceding `read FA table from FW offset = 0x%x`
3. `[IDE]<xfer_int_ldr_fw> Read parameter len: %d OK.` replaces `Read parameter failed !!`
4. no `TAG mismatch:%c%c%c%c` and no `MTDAdvRead> TAG mismatched` anywhere
5. controls unchanged: `FE firmware CheckSum OK !!`, `verify boot code -- OK`,
   `release frontend reset done !!`

**The printed 4 tag bytes are not the observable** (`fe-tags.md` §3.1: they are stale
heap on the no-record path). Only gates 1–3/4 above count as "loaded".

## 6. Restore

```sh
make vm-exec CMD='cp /tmp/nand.img.bak-TAGFIX /tmp/images-fe/nand.img'
```

Not run — the parent owns image state. Expected restore md5 back to
`88da7e1635e122fb00483a6a20bf8401`.

## 7. Open risks

1. **`fe_test_data` payload is synthetic, so FE DRAM `0x11000` changes.** Today the FATB
   mismatch falls back to the copy embedded in `fe_bin_1` at `+0xFE000`
   (`fe-tags.md` §1.2) — a *real* FA table. Injecting the fixture removes the fallback
   (gate 2) but puts the labelled label-pattern there instead. The embedded copy in this
   image is md5 `84d04c9d6cc8ef35bf825d51a5277699` (0x2000 B at `fe_bin_1+0xfe000`, printed
   by the apply script). If a later FE-fidelity comparison needs DRAM `0x11000` to stay
   identical to today's behaviour, the FATB payload should be sourced from that embedded
   table instead of the label — `fe-tags.md` §4.2 asks for the labelled default, so that
   is what was built. Cheap to switch; flagging rather than deciding.
2. **`+0x04` of the header is INFERRED** (§2, §7.3). Written as 0. The driver provably
   never reads it, so no host-side observable can distinguish this from a factory value —
   but the FE could, in principle, once it sees the header (PARM path copies it to DRAM
   `0x15000`, `fe-tags.md` §1.3).
3. **Payload semantics are unknown by design.** A real FE reading a label pattern is not
   a real power curve / parameter set. The fixtures make the UART honest; they do not
   make the FE's inputs faithful. `fe-tags.md` §5 already says this is the honest claim.
4. **The image md5 changed**, so any other lane holding `88da7e16…` as an expectation
   (or comparing regions against a cached image) must be told. Nothing else in the image
   was written (see §4.2 blast radius).
5. Fixtures are untracked working-tree files; committing them is the parent's call.

## 8. Reproduce, from scratch

```sh
# Mac
python3 evidence/bx510-guest/bdpdrv/decode/build_fe_tag_fixtures.py
# VM
make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/fixtures/fe_power_curve.bin
make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/fixtures/fe_test_data.bin
make vm-stage-file FILE=evidence/bx510-guest/bdpdrv/fixtures/fe_parameters.bin
make vm-script SCRIPT=evidence/bx510-guest/bdpdrv/decode/apply_tag_fixtures.sh
make vm-exec CMD='python3 /tmp/fe_tags_probe.py'
```
