# Architecture

Three layers, and it helps to keep them separate when reading the code.

## 1. The device (what we model but do not own)

```
  Blu-ray player  (MT85xx SoC, Linux 2.6.35, armv6l)
  ├── bdpdrv.ko            8.1 MB monolithic driver: display, video, CPSA
  ├── sacd_read.ko         small closed module -> /dev/sacd_read (misc 10:201)
  │                        reads RAW 2064-byte sectors, decrypts them (CPSA)
  └── sacd_extract_160     the daemon we reconstruct
```

`sacd_read.ko` is not open source. Its contract was recovered from the shipped
binary: `SACD_IOC_READ`, `SACD_IOC_DECRYPT`, `SACD_IOC_INIT`, `SACD_IOC_AUTH`,
`SACD_IOC_DISC` on `/dev/sacd_read`, with a `compid` module parameter selecting
one of four CPSA compute ids.

## 2. The daemon (what we reconstruct)

For the binary's actual composition — byte budget per module, the largest
translation units, the source tree and the community delta table, all parsed from
the linker map — see **[DAEMON-MAP.md](DAEMON-MAP.md)**.

```
  TCP :2002  ──►  protocol (nanopb-era protobuf framing)
                   DISC_OPEN   -> result
                   DISC_SIZE   -> total_sectors
                   DISC_READ   -> sector_offset, sector_count  (raw + decrypt)
                   DISC_CLOSE  -> result, then the server closes the socket
```

Threading is a listener plus one detached worker per connection (the original
reuses a single stack slot for the peer address — that quirk is reproduced and
covered by the concurrent-session evidence).

Source layout in `reconstruct/`:

| Path | Role |
|---|---|
| `tool/` | daemon entry, option parsing, server loop, CPSA wrappers, module install |
| `libsacd/` | scarletbook/TOC, sector reading, decryption glue, DSD/DSF writers |
| `libdstdec/` | DST lossless decoder |
| `libcommon/` | logging, filesystem, socket helpers, protobuf encode/decode |
| `libid3/` | ID3 tags (libid3tag-derived) |
| `fsflibgcc/` | the static glibc/gcc support the original carries |

## 3. The verification harness (what proves it)

```
  tools/fn_diff.py        per-function disassembly comparison against the original
  tools/pool_audit.py     literal-string pool content + load-site positional match
  tools/sacd_client.py    wire client: capture, sequences, self-test
  emulator-kit/           QEMU SoC model (NAND, HDHOST block device, UART)
  tools/bx510_*           guest shims: bdpvirt, hdvirt, fbvirt, tmpredir, probe
```

Three verification altitudes, cheapest first:

1. **unit/behavioural** — client self-test against an in-process fake server.
2. **full-system differential** — Sony's own kernel and rootfs in our QEMU
   machine, both binaries, same disc fixture, raw wire captures compared.
3. **hardware** — the real player, the real disc, the real CPSA path.

The rule everywhere: emulator results are predictions; the player is truth.
