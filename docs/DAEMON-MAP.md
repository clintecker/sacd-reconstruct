# What is inside `sacd_extract_160`

Generated from the linker map of the reconstructed binary (`tools/daemon_map.py`), so the numbers match the artefact.

## The binary as a picture

```
                     ┌──────────────────────────────┐
   TCP :2002  ◄──────►│  tool/  server_loop           │  listener thread
                     │         client_thread ×N      │  detached per connection
                     │         protobuf over socket  │
                     └───────┬──────────────┬────────┘
                             │              │
              ┌──────────────▼───┐   ┌──────▼─────────────┐
              │ libsacd/         │   │ libcommon/         │
              │ scarletbook TOC  │   │ logging, files,    │
              │ sacd_input       │   │ socket, protobuf   │
              │ decrypt glue     │   └────────────────────┘
              └───┬──────────┬───┘
                  │          │
        read raw  │          │ write out
   2064 B/sector  │          │
                  ▼          ▼
        ┌─────────────────┐  ┌──────────────┐
        │ /dev/sacd_read  │  │ libdstdec/   │  DST → DSD
        │ (sacd_read.ko)  │  │ libid3/      │  tags
        │  CPSA decrypt   │  └──────────────┘
        └────────┬────────┘
                 ▼
          SACD disc  (2048 B logical sectors on the wire)
```

## Byte budget, by module

| module | objects | `.text` bytes | share | |
|---|---:|---:|---:|---|
| `libsacd/` | 15 | 67504 | 46.0% | `████████████████████························` |
| `libdstdec/` | 9 | 28368 | 19.3% | `█████████···································` |
| `libcommon/` | 10 | 28176 | 19.2% | `████████····································` |
| `libid3/` | 7 | 12340 | 8.4% | `████········································` |
| `tool/` | 4 | 7744 | 5.3% | `██··········································` |
| `other` | 7 | 2512 | 1.7% | `█···········································` |
| `crt` | 5 | 172 | 0.1% | `············································` |
| **total `.text`** | 57 | **146816** | 100% | |

## The biggest single translation units

| object | `.text` bytes | module |
|---|---:|---|
| `libsacd_scarletbook_read.o` | 19948 | `libsacd/` |
| `libsacd_dsdiff.o` | 19416 | `libsacd/` |
| `libdstdec_unpack_dst.o` | 9496 | `libdstdec/` |
| `tool_main.o` | 7148 | `tool/` |
| `libsacd_scarletbook_output.o` | 5856 | `libsacd/` |
| `libcommon_pb_decode.o` | 5236 | `libcommon/` |
| `libcommon_socket.o` | 5184 | `libcommon/` |
| `libsacd_scarletbook_print.o` | 5168 | `libsacd/` |
| `libdstdec_dst_fram.o` | 5104 | `libdstdec/` |
| `libcommon_fileutils.o` | 4580 | `libcommon/` |
| `libcommon_pb_encode.o` | 3980 | `libcommon/` |
| `libsacd_sacd_input.o` | 3816 | `libsacd/` |
| `libid3_id3.o` | 3688 | `libid3/` |
| `libid3_id3_frame.o` | 3476 | `libid3/` |

## Symbols per module (functions + data)

| module | symbols |
|---|---:|
| `libsacd/` | 39 |
| `libdstdec/` | 51 |
| `libcommon/` | 89 |
| `libid3/` | 31 |
| `tool/` | 9 |
| `other` | 71 |
| `crt` | 36 |

## Source tree

| directory | files | C/asm | headers |
|---|---:|---:|---:|
| `fsflibgcc/` | 11 | 6 | 3 |
| `libcommon/` | 25 | 11 | 13 |
| `libdstdec/` | 20 | 9 | 11 |
| `libid3/` | 11 | 7 | 2 |
| `libsacd/` | 40 | 18 | 20 |
| `release/` | 2 | 0 | 0 |
| `tool/` | 10 | 4 | 2 |

## What each part does

- **`crt`** — C runtime start/init

## The community delta (not in any published upstream revision)

These were reconstructed from the shipped binary alone; see `DELTA.md`
for the full table and `docs/PROVENANCE.md` for the upstream commit.

- `init_sacd` / `auth_sacd` / `read_sacd` / `decrypt_sacd` / `disc_sacd` / `uninit_sacd` — the CPSA wrappers: ioctls on `/dev/sacd_read`
- `sacd_read_block_raw64` / `sacd_dev_input_read64` — 64-bit sector addressing added by the ARM port
- `install_modules` / `remove_modules` — extract the embedded `sacd_read.ko` to /tmp, mknod, insmod / rmmod
- `server_loop` / `main_loop` / `client_thread` / `listener_thread` / `validate_stdin` — server mode merged into the ripping tool
- `sacd_pb_stream` — socket-backed protobuf input/output stream

## Threads

```
  listener            accept() → spawn
    └─ client_thread   one per connection, detached; owns its socket
         └─ (decode pool: decode_thread ×N / write_thread)
              └─ yarn  — thread/lock primitives
```

The original reuses a single stack slot for the peer address across
connections; the reconstruction reproduces that and the concurrent-session
evidence covers it.

