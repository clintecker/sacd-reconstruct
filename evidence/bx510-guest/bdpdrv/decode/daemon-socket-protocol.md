# The daemon's port-2002 server protocol, end to end

Date: 2026-11-14. Scope: the **wire protocol** of `sacd_extract_160 -S`
(server mode) — framing, op codes, per-op semantics, the listener's
accept/slot behaviour, per-client FD handling, malformed-input behaviour, and
a client spec small enough to implement against. Companion to
`daemon-ioctl-side.md` (device side of the same daemon) — that document answers
*what the daemon does to the drive*; this one answers *what it says on the
socket*.

| | |
|---|---|
| target | `original/sacd_extract_160` (family: the daemon ARM ELF on the VM at `~/the verification tree/original/sacd_extract_160`) |
| binary id | md5 `49107e9625e8cd27232e395787c46fe2`, ELF32 ARM EABI5, **not stripped, with debug_info** |
| tools | Apple `llvm-objdump` 22 / `llvm-nm` / `llvm-readelf` (`/opt/homebrew/opt/llvm/bin`), Python 3 for literal-pool and `.rodata` resolution — no hexdump eyeballing |
| address convention | `vaddr`; the file offset is `vaddr − 0x8000` for both `.text` (vaddr `0xc818` = file `0x4818`) and `.rodata` (vaddr `0x3199c` = file `0x2999c`), so one rule covers everything cited here (§11) |
| re-derive | §11 lists every command |

**House rules.** **VERIFIED** = read out of an instruction, a symtab entry, or
a literal-pool/`.rodata` word, cited as `vaddr`, and re-derivable with §11.
**INFERRED** = reasoned from a code path. Every claim about a *byte* on the
wire is VERIFIED against either the disassembly or the daemon's own nanopb
library compiled from the repo tree (§9).

---

## 0. Bottom line

1. **The protocol is nanopb-encoded protobuf, not a hand-rolled frame.**
   `sacd_ripper.proto` is the schema. Every request is one `ServerRequest`,
   every response one `ServerResponse`, and **each message is followed by a
   single `0x00` byte** — on *both* directions. The `0x00` is not decoration:
   nanopb's `pb_decode` has `if (temp == 0) break; /* Special feature: allow
   0-terminated messages */`, and the socket istream's `bytes_left` is
   `(size_t)-1` (never hits 0), so **without the trailing zero the daemon waits
   forever for the next field**. *VERIFIED — istream `bytes_left = -1` at
   `0x20824`/`0x20828`; terminator appended at `0xce9c`–`0xcea4`; decode loop's
   `bytes_left` test at `0xf714` and tag-zero break at `0xf654`/`0xf730`.*
2. **Four ops, numbered 1–4 in one shared enum.** DISC_OPEN=1, DISC_CLOSE=2,
   DISC_READ=3, DISC_SIZE=4; the response type enum is the same 1–4. The server
   dispatches on `request.type − 1` through a jump table: `0xcc38` (OPEN),
   `0xcda4` (CLOSE), `0xca54` (READ), `0xcdf4` (SIZE), everything else →
   `0xce40`. *VERIFIED (jump table at `0xca44`).*
3. **The fail sentinel is `result = -1` and it is reset every iteration**
   (`mvn r2,#0 / mvn r3,#0 / strd → [r11,#-100]` at `0xca24`–`0xca2c`). A
   successful DISC_OPEN is `type == 1 && result == 0` — **exactly zero**, which
   the daemon's own client enforces with `result_lo | result_hi == 0`
   (`0x224b0`) and the error string *"Response result non-zero or disc
   opened"* (`0x354f0`). *VERIFIED.*
4. **A DISC_READ returns at most 128 sectors** (`MAX_PROCESSING_BLOCK_SIZE`)
   and `data.size = result × 2048`, hard-coded as `lsl #11` at `0xcc14`.
   A client that wants N > 128 sectors must loop. *VERIFIED.*
5. **The server's response buffer is 263 168 bytes** (`0x40400`, literal at
   `0xcf90`) and a 128-sector read response is 262 153 bytes — 1 015 bytes of
   headroom. Exceeding it does not truncate: `pb_encode` fails, the thread
   breaks, **no response at all**. *VERIFIED (`0xcf90`, `0xce50`; §9 measures
   the real encoded sizes).*
6. **The listener accepts into a single stack slot and hands the *address* of
   that slot to every client thread** — `str r3,[r11,#-0x20]` at `0xd070`,
   `sub r3,r11,#32` at `0xd084` → `pthread_create(..., 0xc934, &conn_s)` at
   `0xd094`. The original has the same defect as `reconstruct/tool/main.c:309`.
   Any second connection makes a still-running first client thread talk to (and
   `close`) the **second** connection's FD. *VERIFIED (§5).*
7. **Nothing timeouts out and nothing is joined.** `socket_recv` is called with
   `flags = 256` (`MSG_WAITALL`) and `tm = NULL` (`0x206e0`/`0x206e8`), on a
   blocking socket, so a client that sends a partial message and stalls holds
   its thread (and the shared slot) indefinitely. *VERIFIED — arg order is
   `(ps, data, count, got, flags, tm)` per `socket.h:104`, confirmed by
   `socket_recv`'s own prologue at `0x13148` reading the 5th arg and passing it
   to `recv` as `flags`.*
8. **The rebuild is protocol-identical to the original.** The two field
   descriptor arrays in `.rodata` are byte-identical apart from relocation
   addresses, all four op handlers match instruction-for-instruction in shape,
   and the terminator is present on both paths. **No divergence found in the
   protocol path** (§8). *VERIFIED.*

---

## 1. Transport

| property | value | evidence |
|---|---|---|
| listen address | `INADDR_ANY` (`htonl(0)`), `AF_INET` | `0xcfe8`–`0xcff4` |
| port | **2002** (`htons(0x07d2)`, literal `0x7d2` at `0xd0c0`) | `0xcfd8`–`0xcfe4` |
| socket | `socket(PF_INET=2, SOCK_STREAM=1, IPPROTO_TCP=6)` | `0xcff8`–`0xd004` |
| backlog | **1** — `listen(list_s, 1)` | `0xd038`–`0xd048` |
| `SO_REUSEADDR` | **absent** — no `setsockopt` anywhere in `listener_thread` (`0xcfac`–`0xd0c8`) | negative: full function read |
| accept condition | `accept(...) > 0`; a connection that lands on **FD 0** is silently dropped | `0xd074`–`0xd07c` |
| bind/listen failure | `pthread_exit(0)` — **no message, no log, no listener**; `main` continues into `server_loop()` and the UART says "Client none" forever | `0xd030`–`0xd054` |
| framing | protobuf + one `0x00` terminator per message, **no length prefix** | §2 |
| messages per connection | unbounded; **DISC_CLOSE ends the connection** (send it, read the reply, expect EOF) | `0xcf0c`–`0xcf18` |
| read pattern (server side) | `recv(MSG_WAITALL)` per protobuf primitive — and since a request contains only varints, that is **one `recv` syscall per byte**, plus one per byte for a skipped field | `0x206d8`–`0x206f8`; skip path `0x206d0`–`0x20710` |
| write pattern | one `socket_send(..., flags=0, tm=NULL)` for the whole encoded response + terminator | `0xcec8`, `0x20614`–`0x20634` |
| idle timeout | **none** (blocking socket, `tm = NULL`) | §7 |

Consequences a client must respect:

* No `SO_REUSEADDR` on the daemon side ⇒ after the daemon exits, re-binding
  2002 can hit `TIME_WAIT`. (This is the same fact `make sacd-hw-baseline-retry`
  documents: *"wait ~90 s first (no-SO_REUSEADDR TIME_WAIT)"*.)
* Because the server reads **one byte at a time**, request bytes may be split
  across TCP segments freely — no `TCP_NODELAY` games needed. The *response*
  arrives as one `send` but a client must still loop on `recv` (it is up to
  262 KB).
* A client that stops mid-message parks a daemon thread forever (§7) *and*,
  thanks to point 6 of §0, parks the accept slot.

---

## 2. Framing and schema

### 2.1 The two descriptor arrays, byte for byte

`sacd_ripper.proto` compiles to two `pb_field_t` arrays in `.rodata`.
`pb_field_t` here is `pb_packed` (`reconstruct/libcommon/pb.h:92`) and 13 bytes:
`tag(1) type(1) data_offset(1) size_offset(1) data_size(4) array_size(1) ptr(4)`.

`ServerRequest_fields` @ **`0x35290`** (4 records × 13 B = 52 B; the next
object in `.rodata` is `ServerResponse_fields` at `0x352c4`, and `/dev/sr0`
sits at `0x352f8` = `0x352c4 + 52`):

| # | tag | type | data_off | size_off | data_size | ptr |
|---|---|---|---|---|---|---|
| 0 | 1 | `0x00` = REQUIRED \| VARINT | 0 | 0 | 4 | 0 |
| 1 | 2 | `0x00` = REQUIRED \| VARINT | 0 | 0 | 4 | `0x35288` |
| 2 | 3 | `0x00` = REQUIRED \| VARINT | 0 | 0 | 4 | `0x3528c` |
| 3 | 0 | `PB_LAST_FIELD` | | | | |

`ServerResponse_fields` @ **`0x352c4`** (4 × 13 B, then `/dev/sr0`):

| # | tag | type | data_off | size_off | data_size | ptr |
|---|---|---|---|---|---|---|
| 0 | 1 | `0x00` = REQUIRED \| VARINT | 0 | 0 | 4 | 0 |
| 1 | 2 | `0x00` = REQUIRED \| VARINT | 4 | 0 | **8** | 0 |
| 2 | 3 | `0x14` = OPTIONAL \| BYTES | 4 | **−4** | **1 048 576** | 0 |
| 3 | 0 | `PB_LAST_FIELD` | | | | |

`0x35288`/`0x3528c` are `ServerRequest_sector_offset_default` /
`..._sector_count_default`, both **0** (4-byte zero words immediately before the
request array). *VERIFIED (bytes dumped from `.rodata`, §11.)*

Read off those tables:

* **Field order on the wire is 1, 2, 3** (nanopb walks the array in order and
  encodes each field in turn). Field 1 = `type`, 2 = `sector_offset`,
  3 = `sector_count`; in the response 1 = `type`, 2 = `result`, 3 = `data`.
* **All three request fields are REQUIRED and are always encoded**, including
  when the value is 0 (`pb_encode.c:164` — `case PB_HTYPE_REQUIRED:` encodes
  unconditionally; the `default_value` pointer does *not* suppress a zero).
  `data_offset = 0` with `prev_size = 4` puts `sector_offset` at struct +4 and
  `sector_count` at +8, matching `ServerRequest {type; sector_offset;
  sector_count}`.
* **`result` is 8 bytes wide** (`data_size = 8`) ⇒ a 64-bit varint. Negative
  values are two's-complement, so **`result = -1` is 10 bytes:
  `ff ff ff ff ff ff ff ff ff 01`**. *VERIFIED (encoder output, §9.)*
* **`data` is OPTIONAL with `size_offset = −4`**: the `has_data` bool sits 4
  bytes before the `data` struct (offset 16 with `data` at 20). It is encoded
  **only when `has_data` is true** (`pb_encode.c:171`). Maximum `data_size` is
  1 048 576 = 512 × 2048, so the *client* may hand the decoder a buffer up to
  that size; the *server* never sends more than 128 × 2048.
* Wire tags therefore are: field 1 varint → `0x08`, field 2 varint → `0x10`,
  field 3 varint → `0x18`, field 3 bytes → **`0x1a`**.

### 2.2 The terminator

`client_thread` holds `uint8_t zero = 0` in a stack byte (`strb r3,[r11,#-0x6d]`
at `0xc950`), and after `pb_encode` always does
`pb_write(&output, &zero, 1)` (`0xce90`–`0xcea4`). The response on the wire is
`<ServerResponse> 00`. The daemon's own client does the same for requests
(`pb_write(&out,&zero,1)` at `0x22458` for DISC_OPEN, `0x22864` for DISC_READ,
`0x22738` for DISC_SIZE). *VERIFIED.*

Both decoders treat tag 0 as end-of-message and stop *before* consuming
anything else (`pb_decode.c:399`, and the original's own `pb_decode` at
`0xf654`/`0xf730`). So `0x00` is an unambiguous message separator.

### 2.3 Unknown / malformed fields (decoder rules, identical in both binaries)

`pb_decode` (`0xf5d4`) walks tags; for each tag it searches the field table
(`pb_field_find`, `0xef7c`). Outcomes:

| tag | action | evidence |
|---|---|---|
| a known tag, right wire type | decode into the struct; set `fields_seen` bit | `0xf6c4`–`0xf6f0` |
| a known tag, **wrong** wire type | the decoder branches on `PB_LTYPE`, not on the wire type, so a varint field read as wire type 2 desynchronises the stream — it will usually fail on the next parse, not here | `decode_field` (`0xefec`), `PB_DECODERS` table |
| an **unknown** tag, wire type 0/1/2/5 | value skipped (`skip`, `0xeb18`), message continues | `0xf69c`–`0xf6b8` |
| an unknown tag, wire type **3/4/6/7** | `skip()` returns false → whole decode fails | `skip` default arm |
| tag `0x00` | end of message | `0xf654` |
| varint longer than 10 bytes / EOF mid-value | decode fails | `pb_decode_varint32` (`0xe924`) |
| a required field never seen | decode fails **after** the terminator | `0xf740`–`0xf798` |

`fields_seen` is a bitmask mod 32; the request has 3 fields so the mask is
exact. *VERIFIED.*

---

## 3. The four ops

State that the thread carries between requests (all function locals of
`client_thread`, `0xc934`–`0xcfac`, zeroed once at thread start at
`0xc974`–`0xc9c0` and **not** re-zeroed per iteration):

| local | stack | meaning |
|---|---|---|
| `client` | `r11−0x3c` | `p_socket` = **the address of the listener's `conn_s` slot** |
| `output_buf` | `r11−0x38` | `malloc(0x40400)` (`0xcf90`) |
| `sacd_reader` | `r11−0x34` | `sacd_reader_t *`, 0 = closed |
| `handle` | `r11−0x30` | `scarletbook_handle_t *`, 0 = closed |
| `checked_for_non_encrypted_disc` | `r11−0x28` | set 0 on OPEN, **never read** |
| `non_encrypted_disc` | `r11−0x2c` | set 0 on OPEN, **never read** |
| `encrypted_start_1` | `r11−0x24` | area[0] TOC `track_start` |
| `encrypted_end_1` | `r11−0x1c` | area[0] TOC `track_end` |
| `encrypted_start_2` | `r11−0x20` | area[1] TOC `track_start` |
| `encrypted_end_2` | `r11−0x18` | area[1] TOC `track_end` |
| `block_size` | `r11−0x14` | sectors per device read, ≤ 128 |
| `end_lsn` | `r11−0x10` | `sector_offset + sector_count` (32-bit) |
| `encrypted` | `r11−0xc` | **dead** — computed in all four branches, never read |
| `request` | `r11−72` … `−61` | 12 B |
| `response` | `r11−108` … `−81` | `type`@0, pad, `result`@8 (8 B), `has_data`@16, `data.size`@20, `data.bytes`@24 |
| `zero` | `r11−0x6d` | the terminator byte |

Per-iteration reset (before the switch): `has_data = false` (`0xca14`),
`data.size = 0` (`0xca1c`), `result = -1` (`0xca24`). **`response.type` is
NOT reset** — see §7.

### 3.1 DISC_OPEN (1 → DISC_OPENED 1)

Request: `08 01 10 00 18 00 00` (fields 2/3 are ignored). Handler `0xcc38`:

1. `response.type = 1` (`0xcc38`).
2. `sacd_reader = sacd_open("/dev/sr0")` — literal `0x319a0`, call `0xcc44`.
   On this path `sacd_open` installs the ioctl backend and runs
   `SACD_IOC_INIT` (`init_sacd`); see `daemon-ioctl-side.md` §3.1/§4.
   NULL ⇒ jump `0xce34` → encode; **`result` stays `-1`**.
3. `handle = scarletbook_open(reader, 0)` (`0xcc64`) — this is where the
   **master TOC is read: LBA 0x1FE × 10 sectors, `"SACDMTOC"` magic required**
   (magic string at `0x35970`; method in `daemon-ioctl-side.md` §6, structure
   in `master-toc-structure.md`). Nothing is read before a client asks: the
   `-S` daemon's startup path is `main` → `listener_thread` + `server_loop`, no
   block I/O (`0xe384`/`0xe3c0`). NULL ⇒ jump `0xce3c` → encode; **`result`
   stays `-1`**.
4. Reads the two area TOC encryption ranges out of the in-memory TOC (no I/O):
   `area[0].area_toc = [handle+0x60]` (`0xcc90`), `area[1].area_toc =
   [handle+0x3850]` (literal `0x3850` at `0xcfa4`, used at `0xcd08`/`0xcd1c`).
   From each: `track_start = u32le@+0x48` (byte-assembled
   `0xcca4`–`0xccc8` / `0xcd24`–`0xcd4c`) and `track_end = u32le@+0x4c`
   (`0xccd0`–`0xccfc` / `0xcd50`–`0xcd84`).
5. `result = sacd_authenticate(reader)` (`0xcd8c`–`0xcd9c`) → `auth_sacd()` →
   `SACD_IOC_AUTH`, returning the ioctl's `u4Result` word.
6. Encode + send.

Response bytes on success: `08 01 10 00 00` (5 B). On failure:
`08 01 10 ff ff ff ff ff ff ff ff ff 01 00` (14 B).

**Client acceptance rule: `type == 1 && result == 0`.** Nothing else is
success. Note that a *disc that is not a SACD* — or an absent disc — fails at
step 2 or 3 and produces `-1`.

### 3.2 DISC_SIZE (4 → DISC_SIZE 4)

Request: `08 04 10 00 18 00 00`. Handler `0xcdf4`:
`response.type = 4`; if `sacd_reader != NULL` →
`result = sacd_get_total_sectors(reader)` (`0xce0c`), **zero-extended to 64
bits** (`mov r3,#0` at `0xce18`). Reader NULL ⇒ `result = -1`.

`sacd_get_total_sectors` for `/dev/sr0` = `fstat64(fd).st_size`, or
`ioctl(fd, BLKGETSIZE64=0x80041272, &u64)` when `st_size == 0`, then
`>> 11` — i.e. **total 2048-byte sectors** (`0x220e0`–`0x221b8`). For the
Firebird fixture that is **1 064 208** (final LBA 1 064 207, per
`firebird-fixture.md` §5.1).

Response: `08 04 10 <varint sectors> 00`.

### 3.3 DISC_READ (3 → DISC_READ 3)

Request: `08 03 10 <varint lba> 18 <varint count> 00`. Handler `0xca54`:

1. `response.type = 3` (`0xca54`).
2. If `handle == NULL` **or** `sacd_reader == NULL` → encode with `result = -1`
   and **no data** (`0xca5c`→`0xce24`, `0xca68`→`0xce2c`).
3. `end_lsn = sector_offset + sector_count` — plain **32-bit** add
   (`0xca7c`–`0xca88`), so it wraps.
4. Compute `block_size` from the four encryption-range branches (§4).
5. `block_size = min(end_lsn − sector_offset, block_size)` (`0xcb90`–`0xcba8`).
6. `result = sacd_read_block_raw64(reader, sector_offset, block_size,
   data.bytes)` (`0xcbc0`) — on the `/dev/sr0` backend this is
   `read_sacd()` = `SACD_IOC_READ`, which returns `block_size` on success and
   **0** on failure (`0x22028`–`0x22074`), so a failed read is a *zero-length
   success*, not a `-1`.
7. `has_data = result > 0` (signed 64-bit compare `0xcbd4`–`0xcc08`).
8. `data.size = result × 2048` — `lsl r3,r3,#11` at `0xcc14`. (Note: `<<11` of
   the **low 32 bits**, stored to the 32-bit `data.size`.)
9. `sacd_decrypt(reader, data.bytes, block_size)` (`0xcc30`) —
   **unconditional**, even when `result <= 0`, and with the *requested*
   `block_size`, not the *returned* `result`. See §4.3.

Response on a full read, `result = n`: `08 03 10 <varint n> 1a <varint
n×2048> <n×2048 bytes> 00`. For `n = 10`: 20 489 bytes, head
`08 03 10 0a 1a 80 a0 01`, tail `<2 bytes> 00`. *VERIFIED (§9.)* For `n = 128`:
262 153 bytes, head `08 03 10 80 01 1a 80 80 10` — fits the 263 168-byte
output buffer with 1 015 bytes to spare. *VERIFIED (§9.)*

Response when nothing was read: `08 03 10 00 00` (result 0, **no `data`
field** — `has_data` false). This is the normal answer for `count = 0` or for
an LBA past the end of the requested range.

### 3.4 DISC_CLOSE (2 → DISC_CLOSED 2)

Request: `08 02 10 00 18 00 00`. Handler `0xcda4`: `response.type = 2`;
`scarletbook_close(handle)` if set (`0xcdbc`); `sacd_close(reader)` if set
(`0xcdd8`, which also runs `SACD_IOC_UNINIT` when the reader is on the ioctl
backend — `0x220bc`); `result = 0`. Respond `08 02 10 00`. Then, after the
send, `if (request.type == 2) break;` (`0xcf0c`–`0xcf18`) → cleanup → **the
daemon closes the socket**. A client must not expect DISC_CLOSE to leave the
connection usable.

`sacd_close` failing / a `DISC_CLOSE` without an open reader is not an error:
`result = 0` regardless.

---

## 4. The block-size computation (the only non-obvious arithmetic)

Four branches, identical shape to the ripping client
(`reconstruct/libsacd/scarletbook_output.c:382`–`406`):

| condition | `block_size` | `encrypted` |
|---|---|---|
| `off < start1` | `min(start1 − off, 128)` | 0 |
| `start1 ≤ off ≤ end1` | `min(end1 + 1 − off, 128)` | 1 |
| `end1 < off < start2` | `min(start2 − off, 128)` | 0 |
| `start2 ≤ off ≤ end2` | `min(end2 + 1 − off, 128)` | 1 |

then `block_size = min(end_lsn − off, block_size)`. Evidence: `0xca9c`,
`0xcac0`, `0xcb08`, `0xcb4c`, final clamp `0xcb90`–`0xcba8`.

### 4.1 There is no `else` branch — `block_size` goes stale

If `off > end2` (past the last area), **none** of the four conditions holds, so
`block_size` keeps whatever the previous iteration left in `r11−0x14` — zero on
the first read of a connection (thread-start zeroing `0xc9b8`) and the previous
request's value thereafter. The final clamp still applies, so the observable
effect is "you may get fewer sectors than you asked for" (or, on the very first
read past `end2`, **zero sectors**). *VERIFIED (no `b` into a fifth arm; the
jump table's default target `0xce40` is the encode, and the four arms all `b`
to `0xcb90`).*

**Client rule: treat `result < requested` as legal and continue from
`off + result`.** Do not assume `result == count`.

### 4.2 `encrypted` is dead code

The flag is written in every branch and read nowhere in `client_thread`. The
same is true of the ripping client, which calls `sacd_decrypt` unconditionally
too (`scarletbook_output.c:433`) — the flag there only feeds the
DSD-3-in-14/16 non-encrypted-disc hack. So the daemon sends **the same bytes
the local rip path writes into the ISO**. *VERIFIED for the dead flag; the
"wire bytes == ISO bytes" claim is INFERRED from that symmetry and is settled
empirically by the LBA-510 oracle in §9.3.*

### 4.3 Decrypt uses the requested count, not the returned count

`sacd_decrypt(reader, buf, block_size)` at `0xcc30` passes the *requested*
`block_size`, whereas `scarletbook_output.c:427` first reassigns
`block_size = (result of the read)` and then decrypts. When a read comes back
short, the daemon therefore runs `SACD_IOC_DECRYPT` over sectors it never read
(stale buffer tail). The **first `result × 2048` bytes of the response are
unaffected** — the kernel compacts sector *i* to `buf + i×2048`
(`sacdread-cpsa.md` §6) — so this is a hygiene note, not a wire defect.
*VERIFIED (addresses above).*

---

## 5. The listener: accept, and the `conn_s` stack-slot reuse

`listener_thread` (`0xcfac`, 0x11c bytes) — the analogue of
`reconstruct/tool/main.c:309`:

```
d058  conn_s = accept(list_s, NULL, NULL);        /* accept@plt 0xd068 */
d070  str conn_s -> [r11,#-0x20]                  /* ONE stack slot       */
d074  if (conn_s <= 0) goto d0a0                  /* <=0, not <0          */
d080  r2 = &id   (r11-12)                         /* pthread_t id, local  */
d084  r3 = &conn_s (r11-32)
d094  pthread_create(&id, NULL, 0xc934 /*client_thread*/, &conn_s)
d0a0  if (!user_requested_exit()) goto d058       /* straight back to accept */
```

Properties, all VERIFIED:

1. **The FD is never copied.** `&conn_s` — a pointer into the listener's own
   stack frame — is the thread argument. Every later use inside
   `client_thread` dereferences that pointer:
   `pb_istream_from_socket(&input, client)` at `0xc970` stores the *pointer* as
   the stream state; `socket_send(*client, …)` at `0xcec0`;
   `close(*client)` at `0xcf6c`–`0xcf78`.
2. **A second accept overwrites the slot while client #1 is still running.**
   The listener does not wait for the previous thread, does not join it
   (`id` is a local that is overwritten and discarded), and there is no mutual
   exclusion. So with two simultaneous clients:
   * client #1's thread, on its **next** send/recv, operates on **client #2's
     FD** (the pointer was already resolved for any call in progress, but every
     subsequent `socket_send`/`socket_recv` re-reads `*ps`);
   * whichever thread finishes first calls `close(*client)` → **closes client
     #2's connection** while client #2's own thread is using it;
   * both threads write the single `client_connected` word (`0x56e04`):
     set to 1 at `0xc9c4`–`0xc9cc`, cleared at `0xcf7c`–`0xcf84`, so the UART
     status line can read "none" while a client is live.
3. **`client_connected` gates nothing.** No handler consults it; the listener
   accepts unconditionally. The rebuild's source comment *"only 1 socket
   connection is allowed at once"* (`main.c:296`) refers to `listen(_, 1)` —
   the backlog, not a limit on concurrency.
4. `accept()` returning **0** (possible if the daemon was started with stdin
   closed) is discarded by `cmp r3,#0 / ble` — the connection is dropped and
   its FD leaked (never closed, since only `client_thread` closes).
5. On `accept()` error the loop just retries (`ble d0a0` → exit check → back to
   `accept`), i.e. a persistent `EMFILE` spins a hot loop with a 1 Hz escape
   hatch only.

**Practical client rule:** assume **one client at a time**, close your
connection (or send DISC_CLOSE) before anything else connects. A second
connection while the first is live corrupts both. There is no way to detect
this from the socket — the symptom is a truncated/garbled response or an
unexplained `ECONNRESET`.

---

## 6. Per-client FD handling

| fd | lifetime | evidence |
|---|---|---|
| listening socket | `pthread_create` of the listener → daemon exit; never closed on the accept path, `close(list_s)` only after `user_requested_exit()` | `0xd0b0`–`0xd0b4` |
| accepted connection | owned by `client_thread`, "owned" via the shared listener stack slot; closed exactly once at thread exit (`close(*client)`, `0xcf6c`–`0xcf78`), *not* on the DISC_CLOSE path (that path only breaks the loop and falls into the same cleanup) | `0xcf30`–`0xcf88` |
| `/dev/sr0` | opened by `sacd_open` at DISC_OPEN, held until DISC_CLOSE **or** connection teardown (`sacd_close` at `0xcf50`); all TOC and sector reads use this one fd | `0xcc44`, `0xcf50`, `0xcdd8` |
| `/dev/sacd_read` | **opened and closed around every single ioctl** — `init/auth/read/decrypt/uninit/disc/sacd` each do `open` → `ioctl` → `close` (`daemon-ioctl-side.md` §1.2). No long-lived ioctl fd exists. | `daemon-ioctl-side.md` §1.2 |

So: the daemon multiplexes no FDs between clients on purpose — the only sharing
is the accidental aliasing of §5. `SACD_IOC_UNINIT` runs on `sacd_close`, i.e.
per client connection, not per daemon.

Concurrency note: two client threads can each hold their own `/dev/sr0` fd and
their own reader/handle if the aliasing did not exist — but since the aliasing
*does* exist, the second open collides with the first on the same slot.

---

## 7. What the daemon does on malformed input

All rows VERIFIED by the code paths cited; §9's harness reproduces the decoder
verdicts.

| client behaviour | daemon behaviour |
|---|---|
| sends the 3 required fields, `0x00`, then keeps the socket open | one request processed, one response sent, loop continues |
| sends the 3 required fields **then `FIN` with no `0x00`** | `read_callback` sets `bytes_left = 0` on the socket error (`0x2075c`–`0x2076c`), `pb_decode` treats that as EOF (`0xf63c`–`0xf648`), and the required-field check **passes** — so **the operation executes**. The response send may still succeed (a peer `FIN` only half-closes its direction); either way the loop ends at the next `pb_decode`, whose empty message fails the required check. Fire-and-forget DISC_OPEN/DISC_READ therefore works: **the work happens even though the client never reads a reply**. *VERIFIED (the required-check-on-EOF path); the send outcome is INFERRED (kernel-dependent).* |
| sends a partial message and stalls (no EOF) | thread blocks in `recv(MSG_WAITALL)` with no timeout — **forever**. The connection, the thread, and the shared accept slot are consumed. |
| `FIN` in the middle of a field | `pb_decode` fails → break → close, no response |
| `0x00` terminator but a missing required field | `pb_decode` fails after the terminator → close, **no response** (§9 reproduces) |
| unknown tag with wire type 0/1/2/5 | value skipped, request continues |
| unknown tag with wire type 3/4/6/7 | `skip()` fails → close, no response |
| `request.type` ∉ {1,2,3,4} | switch default → encode a response whose **`type` is whatever the previous response left in `r11−0x6c`** (uninitialised stack on the first request of a connection — it is never reset per iteration) and `result = -1`. So the client sees a stale/garbage type with `result = -1`. *VERIFIED (`0xca30`–`0xca3c`, `0xce40`, no `response.type` store in the default path).* |
| DISC_READ before DISC_OPEN, or after a failed OPEN | `result = -1`, no `data` |
| DISC_READ `count = 0` | `end_lsn − off = 0` → `block_size = 0` → read returns 0 → `result = 0`, **no `data`** (`08 03 10 00 00`) |
| DISC_READ `count > 128` | clamped to 128 by all four branches; send ≤ 262 153 bytes |
| DISC_READ with `off + count` wrapping 2³² | `end_lsn` wraps; `end_lsn − off` is an unsigned 32-bit difference, so the clamp uses the wrapped value. Block size is still ≤ 128. |
| DISC_READ past `end2` | stale `block_size` (§4.1): 0 on the first read of a connection, the previous value afterwards |
| request big enough to make the response exceed 263 168 B | `pb_encode`/`pb_write` fail → break → **close with no response**. Not reachable with `count ≤ 128`; reachable only if the device returned > 128 sectors for one request (it cannot — the read is capped at `block_size`). |

---

## 8. Rebuild vs original — cross-check

Method: extract the same `.rodata` byte ranges from
`reconstruct/sacd_extract_160` (built from `reconstruct/tool/main.c` +
`libsacd`), diff them, and walk the rebuilt `client_thread`
(`0xaf30`) / `listener_thread` (`0xb5a4`) against the original's.

### 8.1 Field descriptors — identical

```
ORIG  ServerRequest_fields  @0x35290: rec0 tag=1 type=0x00 doff=0 dsize=4 ptr=0
                                      rec1 tag=2 type=0x00 doff=0 dsize=4 ptr=0x35288
                                      rec2 tag=3 type=0x00 doff=0 dsize=4 ptr=0x3528c
REBLD ServerRequest_fields @0x32cb8: ... identical, ptrs 0x32cb0 / 0x32cb4
ORIG  ServerResponse_fields @0x352c4: rec0 tag=1 type=0x00 dsize=4
                                      rec1 tag=2 type=0x00 doff=4 dsize=8
                                      rec2 tag=3 type=0x14 doff=4 soff=-4 dsize=1048576
REBLD ServerResponse_fields@0x32cec: ... byte-identical
```

`ServerResponse_fields` compares equal byte for byte; `ServerRequest_fields`
compares equal except for the two default-value pointers (relocations into each
image's own `.rodata`). Both images place `/dev/sr0` at the same relative
offset — response array +0x34 — and both arrays end with the same
`PB_LAST_FIELD` terminator. **⇒ same op codes, same field order, same
endianness, same `data` size limit.** *VERIFIED.*

### 8.2 Server control flow — identical

| element | original | rebuild | verdict |
|---|---|---|---|
| `malloc` output buffer | `0x40400` @ `0xcf90` | same literal | identical |
| `malloc` data buffer | `0x40800` @ `0xcf98` | same | identical |
| `pb_istream_from_socket` per connection | once, at `0xc964` | once | identical (terminator required) |
| `pb_decode` / break on failure | `0xc9fc` / `0xca10` | same | identical |
| per-iteration reset of `has_data`, `data.size`, `result=-1` | `0xca14`–`0xca2c` | same (three statements) | identical, **and `response.type` is left alone in both** |
| switch on `type−1`, 4 arms + default | `0xca30`–`0xca3c`, table `0xca44` | same | identical |
| DISC_READ range logic + clamp + `<<11` + unconditional decrypt | `0xca54`–`0xcc34` | same | identical, including the *dead* `encrypted` flag and the missing `else` (§4.1) |
| DISC_OPEN null-gating + authenticate inside `if (handle)` | `0xcc38`–`0xcda0` | same | identical |
| area TOC offsets `+0x60` / `+0x3850`, `track_start`@+0x48, `track_end`@+0x4c | `0xcc90`, `0xcd08` | same field names in `scarletbook.h` | identical |
| DISC_SIZE zero-extension of the result | `0xce18` | same | identical |
| DISC_CLOSE closing both handles, `result = 0`, then break | `0xcda4`–`0xcdf0`, `0xcf0c` | same | identical |
| terminator `pb_write(&zero,1)` before the send | `0xce90`–`0xcea4` | same | identical |
| `socket_send(...) == IO_DONE && written == bytes_written` | `0xced0`–`0xcef4` | same | identical |
| `close(*client)` + `client_connected = 0` + `pthread_exit` | `0xcf6c`–`0xcf8c` | same | identical |
| listener: `listen(1)`, `accept>0`, `pthread_create(&id,0,client_thread,&conn_s)` | `0xd040`, `0xd074`, `0xd084` | same, incl. `&conn_s` | **identical defect** |
| `validate_stdin` / `server_loop` / the 1 Hz wide-string status line | `0xe154` / `0xe1b4` | same | identical |

### 8.3 Findings

**No protocol divergence.** Everything the wire can observe — schema, op
numbers, field order, terminator, clamping, result codes, `result` sign
handling — is the same in the rebuild and the original. The rebuild is therefore
a valid stand-in for a client-side pre-check, and a client written against §9
works against both.

Non-divergent oddities worth recording (present in **both**, so not
rebuild-introduced):

* **F-1 (daemon-side latent bug):** no `else` arm in the block-size ladder ⇒
  stale `block_size` for `off > end2` (§4.1). Effect: short/zero reads, not
  corruption.
* **F-2 (daemon-side latent bug):** the accept slot is shared by reference
  (§5) ⇒ a second concurrent client can hijack or kill the first. This is the
  acceptance-criteria item "overlapping-client FD behavior".
* **F-3 (dead code):** `encrypted` is computed and never used; and
  `non_encrypted_disc` / `checked_for_non_encrypted_disc` are set to 0 on
  DISC_OPEN and never read, so the DSD-3-in-14/16 non-encrypted-disc path
  exists in the ripping client (`scarletbook_output.c:413`) but **not** in the
  server thread.
* **F-4 (response type not reset):** an unknown `request.type` returns the
  previous message's `response.type` (or stack garbage on the first request).
* **F-5 (verify-only, no fix in this task):** the client-side DISC_OPEN /
  DISC_SIZE requests in the original leave `sector_offset`/`sector_count`
  **uninitialised** on the stack (`sacd_net_input_open` writes only `type` at
  `0x223f0`; `sacd_net_input_total_sectors` likewise at `0x226e8`) — so a real
  capture of those two requests will show arbitrary varint values in fields 2
  and 3. They are required on the wire and ignored by the server. A client
  should send `0`.

---

## 9. Minimal client spec

### 9.1 The state machine

```
connect(host, 2002)                     # one client at a time (§5)
send DISC_OPEN  ; expect type=1 result=0        else abort
send DISC_SIZE  ; expect type=4 result=N>0      (optional; N = total sectors)
   for each wanted range (lba, count):
       chunk ≤ 128 sectors per request
       send DISC_READ(lba, chunk)
       expect type=3
         result > 0 → result sectors of data, exactly result*2048 bytes
         result == 0 → nothing read (past end2 / count 0); stop this range
         result < 0  → no disc open / device error; abort
       lba += result ; count -= result
send DISC_CLOSE ; expect type=2 ; then the daemon closes the socket
```

Byte-level request bodies (all `< ... >` = protobuf varints):

| op | bytes |
|---|---|
| DISC_OPEN | `08 01 10 00 18 00` + `00` |
| DISC_CLOSE | `08 02 10 00 18 00` + `00` |
| DISC_READ(lba, cnt) | `08 03 10 <lba> 18 <cnt>` + `00` |
| DISC_SIZE | `08 04 10 00 18 00` + `00` |

Response parse: read varints/tags until tag `0x00`; field 1 varint = type,
field 2 varint = result (8-byte two's complement → subtract 2⁶⁴ if ≥ 2⁶³),
field 3 (tag `0x1a`) = length-delimited data. Nothing else appears.

### 9.2 The first test vector: LBA 510, count 10 (the Master TOC)

```
request  08 03 10 fe 03 18 0a 00            (510 = 0x1FE → varint fe 03;  10 → 0a)
reply    08 03 10 0a 1a 80 a0 01 <20480 bytes> 00     total 20489 bytes
         └ type=3   └ result=10  └ len=20480 (varint 80 a0 01)
```

Expected payload md5 vs the fixture oracle: **`45ccd7dfbf433a79d28e877d7441677c`**
(`firebird-fixture.md` §5.1 — "the daemon's master-TOC read, `seek 20480`,
10 sectors"; `fe_read_dma_selftest.py` carries the same value).

Why this vector: LBA 510 is **outside both encryption ranges** (it is below
`area[0].track_start`), so it exercises branch 1 of §4 (the `off < start1`
arm), and it is the sector `scarletbook_open` itself parses — so a client that
gets this right has already proven connect, framing, varint encoding, the
terminator, and the data path. Two additional vectors to pin the branchy
middle: `532104 × 1` (`9ed18b47f67232ea972515df65cb6ac5`, mid 2-channel area,
branch 2) and `1064207 × 1` (`d1c54ec6c395d7092ce06f04705d33ae`, the final
sector, `off > end2` ⇒ **exercises §4.1**, expect a short or zero read).

*Whether these md5s match byte-for-byte depends on the CPSA transform being a
no-op on already-plain sectors (§4.2) — INFERRED, and this is the live check
that settles it. A mismatch at 510 with a match at 532104 would mean the
daemon's out-of-range reads need the raw/encrypted form instead.*

### 9.3 Reference implementation (~60 lines, structure-validated)

This exact code was executed against a fake server replaying the predicted
response bytes (§10):

```python
import hashlib, socket

def varint(v):
    if v < 0: v += 1 << 64
    out = bytearray()
    while True:
        b = v & 0x7F; v >>= 7
        out.append(b | 0x80 if v else b)
        if not v: return bytes(out)

def request(op, off=0, cnt=0):
    # field1 type, field2 sector_offset, field3 sector_count, then the 0x00 terminator
    return b"\x08" + varint(op) + b"\x10" + varint(off) + b"\x18" + varint(cnt) + b"\x00"

class Reader:
    def __init__(self, sock): self.s = sock; self.buf = b""
    def _need(self):
        d = self.s.recv(65536)
        if not d: raise EOFError("daemon closed")
        self.buf += d
    def varint(self):
        v = 0; shift = 0
        while True:
            if not self.buf: self._need()
            b = self.buf[0]; self.buf = self.buf[1:]
            v |= (b & 0x7F) << shift; shift += 7
            if not b & 0x80: return v
    def take(self, n):
        while len(self.buf) < n: self._need()
        out, self.buf = self.buf[:n], self.buf[n:]
        return out

def response(r):                       # -> (type, result, data|None)
    rtype = result = None; data = None
    while True:
        tag = r.varint()
        if tag == 0: return rtype, result, data        # the 0x00 terminator
        field, wire = tag >> 3, tag & 7
        if wire == 0:
            val = r.varint()
            if field == 1: rtype = val
            elif field == 2: result = val - (1 << 64) if val >= (1 << 63) else val
        elif wire == 2:
            n = r.varint(); payload = r.take(n)
            if field == 3: data = payload
        else:
            raise ValueError("unexpected wire type %d" % wire)

def disc_open(r, w):
    w.sendall(request(1)); t, res, _ = response(r)
    if t != 1 or res != 0: raise RuntimeError("DISC_OPEN type=%r result=%r" % (t, res))

def disc_size(r, w):
    w.sendall(request(4)); t, res, _ = response(r)
    if t != 4 or res < 0: raise RuntimeError("DISC_SIZE type=%r result=%r" % (t, res))
    return res

def disc_read(r, w, lba, count):
    out = bytearray()
    while count:
        n = min(count, 128)                       # MAX_PROCESSING_BLOCK_SIZE
        w.sendall(request(3, lba, n))
        t, res, data = response(r)
        if t != 3 or res <= 0 or data is None:
            raise RuntimeError("DISC_READ type=%r result=%r" % (t, res))
        assert len(data) == res * 2048, (len(data), res)
        out += data; lba += res; count -= res
    return bytes(out)

def disc_close(r, w):
    w.sendall(request(2)); response(r)

sock = socket.create_connection(("192.0.2.10", 2002))
r, w = Reader(sock), sock
disc_open(r, w)
print("total sectors:", disc_size(r, w))
blob = disc_read(r, w, 510, 10)
print(len(blob), hashlib.md5(blob).hexdigest())     # want 20480 45ccd7df...
disc_close(r, w)
```

Two things a host implementation gets wrong if it skips §1/§3.3: (a) it must
loop `recv` — the reply is up to 262 KB and arrives from a single `send`;
(b) it must chunk reads at 128 sectors and honour `result < count`.

---

## 10. Pre-check evidence

Two harnesses were run on the Mac against the **daemon's own library sources**
(`reconstruct/libcommon/pb_decode.c`, `pb_encode.c`,
`reconstruct/libsacd/sacd_ripper.pb.c`), compiled host-native with
`pb_packed` emptied (arm64 refuses the packed pointer). Working copies live in
`/tmp/sockdecode/`; nothing in the repo was touched.

**C harness (`/tmp/sockdecode/precheck.c`) — decode/encode verdicts:**

```
DISC_OPEN                  pb_decode=true  type=1 off=0 cnt=0
DISC_CLOSE                 pb_decode=true  type=2 off=0 cnt=0
DISC_SIZE                  pb_decode=true  type=4 off=0 cnt=0
READ 510x10                pb_decode=true  type=3 off=510 cnt=10
READ 510x10 no-zero        pb_decode=true  type=3 off=510 cnt=10   (buffer stream only)
missing field 3            pb_decode=FALSE type=3 off=510 cnt=0
unknown tag wire=3         pb_decode=FALSE
type=5 (unknown)           pb_decode=true  type=5               -> server default arm
response encode=FALSE total=9        (1024 B buffer, 20480 B payload -> pb_write refuses)
OPEN failed (-1) + zero    len=  14 : 08 01 10 ff ff ff ff ff ff ff ff ff 01 00
128-sector response encode=true bytes=262153 cap=0x40400 (263168) headroom=1015
```

**Encoded sizes measured with the real encoder:**

| response | body | total incl. `00` |
|---|---|---|
| DISC_OPENED ok | `08 01 10 00` | 5 |
| DISC_OPENED fail | `08 01 10 ff ff ff ff ff ff ff ff ff 01` | 14 |
| DISC_CLOSED | `08 02 10 00` | 5 |
| DISC_SIZE = 2097151 | `08 04 10 ff ff 7f` | 7 |
| DISC_READ r=10 | `08 03 10 0a 1a 80 a0 01` + 20480 B | 20489 |
| DISC_READ r=0 | `08 03 10 00` | 5 |
| DISC_READ r=-1 | `08 03 10 <10-byte -1>` | 14 |
| DISC_READ r=128 | `08 03 10 80 01 1a 80 80 10` + 262144 B | 262153 |

**Python client (`/tmp/sockdecode/client_preview.py`)** — the §9.3 code plus a
fake server emitting the predicted bytes — ran to completion:

```
DISC_SIZE   -> 1064208 sectors
DISC_READ   -> 20480 bytes  md5 ebcbf9b3a29550898de71befd6309314   (synthetic payload)
precheck OK
```

That validates the client's framing/varint/terminator/loop logic. It does **not**
validate the payload against the disc — that needs a live daemon.

---

## 11. How to re-derive

```sh
OD=/opt/homebrew/opt/llvm/bin/llvm-objdump
NM=/opt/homebrew/opt/llvm/bin/llvm-nm
RE=/opt/homebrew/opt/llvm/bin/llvm-readelf

# sections / symbol boundaries (.text @0x8000 file 0x4818 → offset = vaddr - 0x8000)
$RE -S original/sacd_extract_160
$NM -n -S original/sacd_extract_160 | awk '$1>="0000c800" && $1<="0000e500"'

# the four threads/functions of interest
$OD -d --no-show-raw-insn --triple=armv6-linux-gnueabi \
    --start-address=0xc934 --stop-address=0xcfac original/sacd_extract_160   # client_thread
$OD -d --no-show-raw-insn --triple=armv6-linux-gnueabi \
    --start-address=0xcfac --stop-address=0xd0c8 original/sacd_extract_160   # listener_thread
$OD -d --no-show-raw-insn --triple=armv6-linux-gnueabi \
    --start-address=0xe154 --stop-address=0xe2d8 original/sacd_extract_160   # validate_stdin + server_loop

# the protobuf field descriptors + the property test that they are 13-byte records
$OD -d --no-show-raw-insn --triple=armv6-linux-gnueabi \
    --start-address=0xf5d4 --stop-address=0xf7e4 original/sacd_extract_160   # pb_decode (tag-0 break, required check)
$OD -d --no-show-raw-insn --triple=armv6-linux-gnueabi \
    --start-address=0x205f0 --stop-address=0x20850 original/sacd_extract_160 # socket stream callbacks + pb_*_from_socket
$OD -d --no-show-raw-insn --triple=armv6-linux-gnueabi \
    --start-address=0x22218 --stop-address=0x22954 original/sacd_extract_160 # the daemon's own client

# .rodata words: offset = vaddr - 0x8000
python3 - <<'EOF'
d=open('original/sacd_extract_160','rb').read()
def rd(v,n): return d[v-0x8000:v-0x8000+n]
for base,name in [(0x35290,'ServerRequest_fields'),(0x352c4,'ServerResponse_fields')]:
    b=rd(base,52); print(name, hex(base), b.hex(' '))
    for i in range(4):
        r=b[i*13:(i+1)*13]
        print('  rec%d tag=%d type=0x%02x doff=%d soff=%d dsize=%d arr=%d ptr=0x%08x'%(
            i,r[0],r[1],r[2],r[3]-256 if r[3]>127 else r[3],
            int.from_bytes(r[4:8],'little'),r[8],int.from_bytes(r[9:13],'little')))
EOF

# the same arrays in the rebuild, for the §8 diff (rebuild .rodata: vaddr-0x8000 too)
#   rebuild ServerRequest_fields @0x32cb8, ServerResponse_fields @0x32cec
```

Wide strings in `.rodata` are 4-byte `wchar_t` (UTF-32LE); narrow strings are
plain NUL-terminated bytes at the same `vaddr − 0x8000`. The status-line format
string is `L"\rSACD Daemon %ls active. Client %ls. %ls.              "` at
`0x31e68`, with `L"0.37"` `0x31f48`, `L"connected"` `0x31d70`, `L"none"`
`0x31d98`, `L"SACD disc inserted"` `0x31dac`, `L"Disc inserted"` `0x31df8`,
`L"Tray is empty"` `0x31e30`, and `"/dev/null"` `0x31d64` for the no-console
case. *VERIFIED.*

---

## 12. Open questions (need a live daemon to close)

1. **Does the wire payload equal the ISO bytes** for out-of-range sectors?
   §4.2 argues yes (same unconditional-decrypt shape as the rip path); the
   LBA-510 md5 in §9.2 is the decisive test.
2. **`result` short reads in practice.** §4.1 predicts short/zero reads past
   `end2`; nobody has yet observed the daemon's answer for LBA 1 064 207.
3. **`SACD_IOC_AUTH` return value on a real disc** — i.e. whether DISC_OPEN
   returns 0 on the Firebird fixture. The client spec keys success on `== 0`.
4. **Two-client behaviour** (§5 F-2) is decoded but not demonstrated on the
   wire; a two-connection experiment would convert F-2 from VERIFIED-by-reading
   to demonstrated.
