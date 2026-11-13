# sacd_extract_160 ↔ sacd_read.ko: the daemon side of the ioctl stack

Date: 2026-11-13 (stage follow-on to `sacdread-cpsa.md`).
Scope: the **userspace** half. `sacdread-cpsa.md` decoded the kernel side
(`sacd_read.ko`, the seven `0x4010530x` commands, the `0x8530` ODD request built
inside `bdpdrv`). This document answers the four questions the daemon side can
settle: the call sites and struct fills for all seven ioctls, the
`open`/`read`/`decrypt` sequences at startup and per track, what the daemon
contributes to the 44-byte `0x8530` request, the boot sequence with the exact
UART oracle, and the read-failure strings with their triggers.

**House rules.** **VERIFIED** = read out of an instruction (cited as
`vaddr`, the file offset is `vaddr − 0x8000`), a symtab entry, or a literal
pool word, and re-derivable with §7. **INFERRED** = reasoned from a pattern.

---

## 0. Bottom line

1. **The daemon issues exactly eight `ioctl(2)` calls in the whole binary.**
   Seven are the `sacd_read` commands (`0x40105301` … `0x40105307`), the eighth
   is `BLKGETSIZE64` (`0x80041272`) on `/dev/sr0`. There is no other ioctl in
   the program. *VERIFIED (all `bl ioctl@plt` sites enumerated, §7).*
2. **The seven wrappers are one mechanical template.** Each is
   `memset(&cmd,0,16)` → `open("/dev/sacd_read", O_RDONLY)` → `ioctl(fd,cmd,&c)`
   → `ret = cmd.u4Result` (when the ioctl returns ≥ 0) → `close(fd)`. Only
   `read_sacd` and `decrypt_sacd` write anything into the 16-byte
   `_IOCTL_SACD_COMMAND`; the other five pass an **all-zero** payload. Field
   offsets and values are pinned in §1.2 (this supersedes the "names are the
   reconstruction's" caveat for the *values*). *VERIFIED.*
3. **The ioctl path is selected by the input path string, and the default
   input is `/dev/sr0`.** `sacd_input_setup()` installs one of three function
   pointer sets; only the one selected by `strcmp(path,"/dev/sr0")==0` points
   `sacd_input_read64` at `sacd_dev_input_read64` (the ioctl path) and
   `sacd_input_authenticate`/`decrypt` at the device versions. `init()` seeds
   `options.input = "/dev/sr0"`, so **an unconfigured run uses the ioctls**;
   an `ip:port` input selects the TCP client stubs and any other path selects
   plain `lseek`/`read` with no ioctls at all. *VERIFIED (§2).*
4. **`init_sacd()` — `SACD_IOC_INIT` (`0x40105301`) — is the daemon's only
   handshake, and there is no version negotiation on the userspace side.**
   `sacd_dev_input_open()` calls it iff `sacd_input_read64 ==
   sacd_dev_input_read64`; if it returns `< 0` the whole open fails. The
   version query (`eSacdGetVersion`) lives in `bdpdrv` and is only reachable
   from `_SACDCLI_TestPhy`, which `sacd_read.ko` never calls — so a
   C-run/src-level daemon cannot report a SACD version, and must not be
   expected to. *VERIFIED.*
5. **`/dev/sacd_read` is created by the daemon itself, not by the image:**
   `install_modules()` writes the embedded `sacd_read.ko` to a `tmpnam()`
   file, `system("mknod -m0666 /dev/sacd_read c 10 201")`,
   `system("insmod <tmp> minor=201")`, `unlink` the temp, then probes
   `open("/dev/sacd_read",0)`. No `dlopen`, no `dlsym` anywhere in the binary
   (only `system@GLIBC_2.4` is imported for this). *VERIFIED (§3.1).*
6. **TOC reads do not use the ioctls.** `scarletbook_read_master_toc()` reads
   **10 sectors at LBA 0x1FE with a plain `lseek64`+`read` on the `/dev/sr0`
   fd** (2048 B/sector, buffer `malloc(20480)`), and expects the first 8 bytes
   `"SACDMTOC"`. The area TOCs are read the same way. **Only audio sectors go
   through `SACD_IOC_READ`/`SACD_IOC_DECRYPT`.** This closes
   `sacdread-cpsa.md` §7.1: on the ioctl path a sector is **2064 bytes**
   (the daemon allocates `0x40800 = 2064×128` and caps every request at 128
   sectors); on the plain path a sector is **2048 bytes**. Two different
   paths, two different numbers, no contradiction. *VERIFIED (§2.4).*
7. **The daemon never builds the 44-byte `0x8530` request.** It supplies only
   three values that survive into it — LBA, sector count, user buffer — and
   `_IDECLI_SendOddCmd` in `bdpdrv` supplies the rest. §4 pins exactly which
   bytes of the 44 are daemon-determined and which are not, and retires the
   part of `sacdread-cpsa.md` §7.2 that the daemon side can retire.
8. **The UART oracle is a single line, printed once per second, only in
   server mode, only when stdin is *not* a terminal:**
   `\rSACD Daemon 0.37 active. Client <connected|none>. <SACD disc
   inserted|Disc inserted|Tray is empty>.` + 14 spaces. The established launch
   is `/sacd_extract_160 -S &` (no tty) → this line appears. **Nothing else is
   printed on the happy path**, so "no output" is *not* a failure signal; §5.3
   lists every string that can appear and what produces it. *VERIFIED.*

---

## 1. Q1 — the seven ioctls as the daemon issues them

### 1.1 The struct the daemon fills

`sacdread-cpsa.md` §2.1 gives the kernel module's DWARF struct. The daemon has
no DWARF for it (it carries only the constants), but it fills the four words
exactly: each wrapper does `memset(&cmd, 0, 16)` on a 16-byte stack slot, then
stores into it, then passes `&cmd` as the ioctl argument. The stack slot base
and the stores are instruction-cited per wrapper below.

```c
/* 16 bytes, on the wrapper's stack; memset to 0 before every use */
struct _IOCTL_SACD_COMMAND {
    UINT32  u4Result;   /* +0x00  read back as the wrapper's return value    */
    UINT32  u4Offset;   /* +0x04  LBA                       (read only)      */
    UINT32  u4Sectors;  /* +0x08  sector count        (read and decrypt)     */
    UINT8  *pu1Buf;     /* +0x0c  user buffer         (read and decrypt)     */
};
```

### 1.2 Command by command — call site, argument struct, result handling

Every wrapper is at `0x20f90 … 0x21398` and is 0x90-ish bytes. The device path
literal `/dev/sacd_read` is the same word (`0x352f8`) in all seven; the command
constants sit in each function's own literal pool at `vaddr = 0x40105300|nr`.

| cmd | wrapper | `_IOC` | payload the daemon writes | result |
|---|---|---|---|---|
| `0x40105301` | `init_sacd` `0x20f90` | nr=1, size=16 | **all zero** (memset `0x20fa4`, only store) | `ret = cmd.u4Result` (`0x20ff8`) |
| `0x40105302` | `auth_sacd` `0x21020` | nr=2 | **all zero** | `ret = cmd.u4Result` (`0x21088`) |
| `0x40105303` | `read_sacd` `0x210b0` | nr=3 | `+0x04=lba` (`0x21108`), `+0x08=sectors` (`0x21110`), `+0x0c=buf` (`0x21118`) | `ret = cmd.u4Result` (`0x2113c`) |
| `0x40105304` | `decrypt_sacd` `0x21164` | nr=4 | `+0x08=sectors` (`0x211b4`), `+0x0c=buf` (`0x211bc`); `+0x04` stays 0 | `ret = cmd.u4Result` (`0x211e4`) |
| `0x40105305` | `uninit_sacd` `0x2120c` | nr=5 | **all zero**; result **ignored** (no readback) | – |
| `0x40105306` | `disc_sacd` `0x21278` | nr=6 | **all zero** | `ret = cmd.u4Result` (`0x212e0`) |
| `0x40105307` | `sacd_sacd` `0x21308` | nr=7 | **all zero** | `ret = cmd.u4Result` (`0x21370`) |

Notes that matter to a model or a stand-in:

* **`compid`/`minor` are not in the payload at all.** The module takes `compid`
  from its own insmod parameter and `minor` likewise; the daemon passes neither
  (matches `sacdread-cpsa.md` §2.3, now confirmed from the caller side).
* **Failure polarity is "ioctl < 0 → give up quietly, no error string".** All
  seven do `if (ioctl(...) < 0) skip readback` then `return -1` (init/auth/
  read/decrypt/disc/sacd) or `void` (uninit). There is **no `perror`, no
  print** in any wrapper — a failing driver is silent at the ioctl layer.
* **`open("/dev/sacd_read")` uses mode 0** (`O_RDONLY`), and the fd is opened
  and closed **per call** — the daemon does not hold a long-lived `/dev/sacd_read`
  fd. A model/stand-in that assumes one open per session is wrong; there is one
  open per ioctl. *VERIFIED (`0x20fb8`–`0x21004` et al., and the fact that
  `read_sacd`/`decrypt_sacd` each `close()` on the success path too).*
* **`u4Result` is read only when the syscall returned ≥ 0.** A `-ENOTTY` from
  a stand-in driver therefore looks identical to "command failed" (`-1`) rather
  than surfacing the errno. *VERIFIED (`0x20fec`–`0x20ffc`).*
* The eighth ioctl, `disc_sacd`/`sacd_sacd` reasoning: `server_loop` treats
  `disc_sacd() == 0` as "unit ready" and `sacd_sacd() >= 0` as "profile ok";
  see §5.3 and `sacdread-cpsa.md` §3.2 for the driver-side meaning
  (TUR loop 20000 ms, and GET CONFIGURATION profile `0x10`).

### 1.3 Who calls /dev/sr0-adjacent helpers, and the ops table

`sacd_input_setup()` (`0x22954`) installs eight function pointers in the globals
`.bss 0x59dfc … 0x59e18`:

| slot | meaning |
|---|---|
| `0x59e10` | `open(const char *path) -> handle` |
| `0x59e18` | `close(handle) -> int` |
| `0x59e14` | `read(handle, u32 lba, u32 n, void *buf)` — **2048 B/sector** |
| `0x59e04` | `read64(handle, u32 lba, u32 n, void *buf)` — **2064 B/sector** |
| `0x59e08` | `error(int) -> const char *` |
| `0x59e0c` | `authenticate(handle) -> int` |
| `0x59dfc` | `decrypt(handle, void *buf, u32 n) -> int` |
| `0x59e00` | `total_sectors(handle) -> u32` |

Call-chain (all VERIFIED; `→` is a direct `bl`, `⇒` is through a pointer):

```
main / client_thread
  sacd_open(path)                     0x2e674   stat + dispatch
   └ sacd_open_image_file(path)       0x2e5a4
      ├ sacd_input_setup(path)        0x22954   picks the pointer set (§2)
      ├ ⇒ open(path)                  → sacd_dev_input_open  0x21da4
      │    ├ open(path, O_RDONLY)     → fd  (kept for the session)
      │    └ if (read64 == sacd_dev_input_read64) init_sacd()  0x20f90
      └ malloc(8) { 1, handle }       returned as the sacd_t
```

The `sacd_t` is `{ int owner; void *handle; }` (`0x2e63c`/`0x2e648`): every
`sacd_*` entry point checks `t->handle != NULL` (else
`"libsacdread: Fatal error in block read.\n"`) and passes **`t->handle`** — not
`t` — to the ops function. For the device path `handle` is a `calloc(8,1)`
block whose `+0x00` is the `/dev/sr0` fd (`0x21db4`–`0x21e0c`); the ops
functions that need the fd dereference it (`sacd_dev_input_read` `0x21ed4`,
`sacd_dev_input_total_sectors` `0x22108`, `sacd_dev_input_close` `0x22094`),
and the ones that go through `/dev/sacd_read` ignore it entirely
(`sacd_dev_input_read64` `0x22044`, `sacd_dev_input_decrypt` `0x21d44`,
`sacd_dev_input_authenticate`). *VERIFIED.*

**Consequence for the rig:** the `/dev/sr0` fd the daemon holds exists for two
reasons only — plain eating of TOC sectors (§2.4) and `fstat64`/`BLKGETSIZE64`
for the disc size. Everything else re-opens `/dev/sacd_read`.

---

## 2. Q2 — which input selects which mode, and what it implies

### 2.1 The three modes (`sacd_input_setup`, `0x22954`–`0x22b4c`)

The sniff at `0x2297c`–`0x229e8` walks `strchr(p+1,'.')` up to the third dot
and then tests `strchr(p+1,':')`; a hit sets the "server" flag. That is the
`-i 192.168.1.10:2002` form (three dots = IPv4, then `:`), matching the usage
text at `0x322b4`. *VERIFIED for the code shape; INFERRED for "this is the
IPv4:port test" (the only input shape that satisfies it).*

| mode | selected when | open/close/read | `read64` | auth | decrypt | total_sectors |
|---|---|---|---|---|---|---|
| 1 | 3rd `.` followed by `:` | `sacd_net_input_*` | `sacd_net_input_read` | net stub (returns 0) | net stub (returns 0) | net |
| **2** | `!strcmp(path,"/dev/sr0")` | **`sacd_dev_input_*`** | **`sacd_dev_input_read64` → ioctl** | **`sacd_dev_input_authenticate` → ioctl** | **`sacd_dev_input_decrypt` → ioctl** | **`sacd_dev_input_total_sectors`** |
| 3 | every other path | `sacd_dev_input_*` | `sacd_dev_input_read` (**plain `lseek64`+`read`**) | net stub | net stub | `sacd_dev_input_total_sectors` |

Stores cited: mode 1 `0x22a00`–`0x22a54`; mode 2 `0x22a80`–`0x22ad4`;
mode 3 `0x22ae8`–`0x22b3c`. The selector literal for mode 2 is `0x3551c =
"/dev/sr0"` (`strcmp` at `0x22a64`). *VERIFIED.*

Two consequences that are easy to get wrong:

* **Mode 3 has no ioctls at all** — an `.iso`/image input reads a 2048-byte
  sector file and never touches the kernel module (`init_sacd` is not called
  because `read64 != sacd_dev_input_read64`). A rig pointed at an ISO proves
  nothing about the SACD stack.
* **Mode 2 is the default.** `init()` (`0xd978`) zeroes `options` and stores
  `0x31c58 = "/dev/sr0"` into `options.input` (`+0x24`, `0xd9f4`); `-i` only
  replaces it (`parse_options` `0xd4b0`–`0xd4cc`, `strdup(optarg)`).
  `client_thread` does not even use `options.input` — its `DISC_OPEN` handler
  calls `sacd_open(0x319a0 = "/dev/sr0")` unconditionally (`0xcc40`).

### 2.2 `sacd_dev_input_open` — the init gate, exactly

```
0x21db4  h = calloc(8,1)                       ; { fd, unused }
0x21df8  h->fd = open(path, O_RDONLY)
0x21e18  if (h->fd < 0)  -> free(h); return NULL      ; no message
0x21e20  if (sacd_input_read64 == sacd_dev_input_read64) {      ; mode 2 only
0x21e34      r = init_sacd()                                    ; ioctl 0x40105301
0x21e3c      if (r < 0) { close(h->fd); free(h); return NULL }
         }
0x21e58  return h
```

`sacd_dev_input_close` (`0x22080`) mirrors it: `close(h->fd)`, then
`if (read64 == sacd_dev_input_read64) uninit_sacd()` (ioctl `0x40105305`), then
`free(h)`. *VERIFIED.*

So the **acceptance gate for "the daemon got past init"** is
`sacd_dev_input_open != NULL`, i.e. all three of:
1. `/dev/sr0` opens (mode-2 path still opens it, even though it will not read
   from it),
2. `/dev/sacd_read` opens (else `init_sacd` returns `-1`),
3. `ioctl(0x40105301)` returns `>= 0` **and** `cmd.u4Result >= 0`.

A failure of (2) or (3) is reported as
`"libsacdread: Can't open %s for reading\n"` — **with `%s` = `/dev/sr0`**,
because the print lives in `sacd_open_image_file` (`0x2e5f8`, format
`0x35e18`), not in the wrapper. Do not read that string as "sr0 missing".

### 2.3 What `u4Result` must be for the ioctls to count as success

| ioctl | success test in the daemon | notes |
|---|---|---|
| `0x40105301` init | `>= 0` | `-1` ⇒ open fails ⇒ "Can't open /dev/sr0 for reading" |
| `0x40105302` auth | `>= 0` | `main_loop` then logs `authentication failed: %x` at log level >1 (`0xdaf4`–`0xdb28`); `client_thread` returns the value into `DISC_OPEN`'s result |
| `0x40105303` read | `>= 0` | **but see §2.5: the daemon ignores the value and reports success as `n`** |
| `0x40105304` decrypt | `>= 0` | `< 0` ⇒ `log_print("decrypt_sacd: (%#x)\n")` and `-1`, ignored by the caller |
| `0x40105305` uninit | ignored | |
| `0x40105306` unit ready | `== 0` | `disc_sacd() != 0` ⇒ "Tray is empty" |
| `0x40105307` profile | `>= 0` | `sacd_sacd() < 0` ⇒ "Disc inserted" (present but not SACD) |

*VERIFIED* (each test cited in §1.2 / §5.3).

### 2.4 The read paths and the 2048 / 2064 question

`sacd_read_block_raw` (`0x2eb04`, → ops `read`) and `sacd_read_block_raw64`
(`0x2eba4`, → ops `read64`) differ **only** in the pointer slot they call; both
check `t->handle` and return its value as-is. The two implementations:

| | `sacd_dev_input_read` (`0x21eb4`) | `sacd_dev_input_read64` (`0x22028`) |
|---|---|---|
| call | `lseek64(fd, lba<<11, SEEK_SET)` then `read(fd, buf, n<<11)` in a short-read loop | `read_sacd(lba, n, buf)` → ioctl `0x40105303` |
| bytes/sector | **2048** | **2064** (the driver copies `2064*n` to user) |
| return | `n` (sectors), or `0` on lseek/read error | `n` on `u4Result >= 0`, else `0` |

Callers and buffer sizes — this is where §7.1 of `sacdread-cpsa.md` closes:

| caller | function | call | buffer |
|---|---|---|---|
| Master TOC | `scarletbook_read_master_toc` `0x2a25c` | `read(dev, 0x1FE, 10, buf)` | `malloc(20480)` = 10×2048 (`0x2a20c`), signature `"SACDMTOC"` checked at `0x2a298` |
| Area TOC | `scarletbook_open` `0x299d8`, `0x29bac` | `read(dev, lba, cnt, buf)` | `malloc(be16(mtoc[0x54])<<11)` = cnt×2048 (`0x298f8`), stored at `sb + 0x5c*(area+1)` (`0x2991c`; per-area stride `0x5c`) |
| client `DISC_READ` | `client_thread` `0xcbc0` | `read64(dev, lsn, n, buf)`, `n ≤ 128` | `malloc(0x40800)` = **2064×128** (`0xc9d0`) |
| track rip | `processing_thread` `0x28968` | `read64(dev, lsn, n, buf)`, `n ≤ 128` | `malloc(0x40800)` = **2064×128** (`0x28c78`, in `scarletbook_output_create`) |

The 128 cap is explicit at four sites (`cmp r3,#128 ; movhs r3,#128`: `0xcab0`,
`0xcaf8`, `0x28818`, `0x28870`, plus a `mov r3,#128` clamp at `0x28880`).
*VERIFIED.*

⇒ **2064 bytes per sector is the contract on the `SACD_IOC_READ` leg, and the
daemon's own allocation proves it**: it hands the driver a buffer sized
`2064 × n`, so the driver's `copy_to_user(buf, 2064*n)` is exact, and the
daemon-side answer to "does a SACD sector arrive as 2048 or 2064" is **2064 on
the ioctl leg, 2048 on the plain leg**. (The plain leg is *not* an alternative
encoding of the same sectors — it is the TOC/metadata leg, read through the
block device at 2048 B/logical sector.)

### 2.5 The per-request sequence (server mode) — and a real quirk

`client_thread` (`0xc934`) decodes a protobuf request into a stack struct based at
`r11-0x48`, dispatches on its **first word** (`[r11,#-0x48]`, values `1..4` via
the jump table at `0xca44` → `0xcc38`, `0xcda4`, `0xca54`, `0xcdf4`), and always
answers with `{ result: i64, ... }` encoded into a 263,168-byte buffer
(`0xc954`/`0xce4c`, `0x40400`). The remaining request words are at `+0x04`
(LSN) and `+0x08` (sector count). *VERIFIED.*

```
DISC_OPEN  (0xcc38)  sacd_open("/dev/sr0")                        -> i64 result
                     scarletbook_open(dev, 0)     (TOC via plain read())
                     cached: twoch start/end from sb, mulch start/end from sb
                     sacd_authenticate(dev)       -> ioctl 0x40105302
DISC_READ  (0xca54)  clamp lsn into the twoch/mulch area
                     n = min(area_remaining, 128)
                     r = sacd_read_block_raw64(dev, lsn, n, buf)   -> ioctl 0x40105303
                     ok = (r != 0);  payload_len = r << 11         ; 2048 per sector
                     sacd_decrypt(dev, buf, n)                     -> ioctl 0x40105304
DISC_CLOSE (0xcda4)  scarletbook_close(); sacd_close(dev)          -> ioctl 0x40105305
DISC_SIZE  (0xcdf4)  sacd_get_total_sectors(dev)  (fstat64, else BLKGETSIZE64 >> 11)
server_loop          disc_sacd()  -> ioctl 0x40105306, sacd_sacd() -> 0x40105307
```

The quirk, VERIFIED and worth knowing before writing a differential test:
**`sacd_decrypt` is called unconditionally, even when the read failed** — the
`ok` flag only decides the reply's payload length (`0xcc0c`–`0xcc30`). A failed
read therefore still produces a `SACD_IOC_DECRYPT` with `u4Sectors = n` over
stale buffer contents. The same pattern is in `processing_thread`
(`0x28968` read64 → `0x289e4` decrypt, no branch between them).

The per-track rip path (`processing_thread`) is byte-for-byte the same pair,
inside a `while (lsn < end_lsn)` loop that clamps each chunk to 128 sectors,
feeds the result into `scarletbook_process_frames` (`0x28a4c`) and updates
three counters (`0x2898c`–`0x289b8`). *VERIFIED.*

---

## 3. Q3 — the boot sequence

### 3.1 `main` (`0xe2d8`) → `install_modules` (`0x2f970`)

```
main:
  init()                    0xd978   zero options; options.input = "/dev/sr0";
                                    sigaction(SIGINT); init_logging(); new_lock()
  parse_options(argc,argv)  0xd130   on failure: usage to stderr, exit
  install_modules()         0x2f970  <0 => log_print("Can not install modules") and EXIT
  setlocale(LC_ALL,"");     0xe318
  fwide(stdout, +1)         0xe324   switch stdout to wide orientation
  if (options.server_mode /* +0x32c, set by -S */) {
      pthread_create(&tid, NULL, listener_thread, NULL)
      if (ok) server_loop()        else log_print("return code from listener thread creation is %d")
  } else {
      main_loop()
  }
  freopen("/dev/null","w",stdout); fwide(stdout,-1) if it failed
  remove_modules()          0x2fb40
  free_lock / destroy_logging / putchar('\n')
```

`install_modules` in detail (each step instruction-cited):

```
0x2f988  size = _binary_sacd_read_ko_end (0x56de9) - _start (0x3efdc) = 97805   ; matches sacd_read.ko
0x2f9a4  memcpy(buf, "/tmp/", 6)
0x2f9ac  tmpnam(buf)                       ; glibc writes its own /tmp/XXXXXX name here
0x2f9b8  fd = open(buf, O_WRONLY|O_CREAT|O_TRUNC /*0x241*/)
0x2f9dc  write(fd, _binary_sacd_read_ko_start, size)   ; short write => return -errno
0x2f9f4  close(fd)
0x2f9fc  system("mknod -m0666 /dev/sacd_read c 10 201")
0x2fa14  sprintf(buf2, "insmod %s minor=201", tmpfile); system(buf2)
0x2fa28  unlink(tmpfile)
0x2fa34  fd = open("/dev/sacd_read", O_RDONLY)
0x2fa44  if (fd < 0) { log_print("%s: mknod/insmod filed", ...); remove_modules(); return -1 }
0x2fa50  close(fd); return 0
```

`remove_modules` (`0x2fb40`): `system("rmmod sacd_read")`, probe
`open("/dev/sacd_read")` → if it still opens, `log_print("%s: rmmod filed")`,
then `system("rm -rf /dev/sacd_read")`. *VERIFIED.*

**There is no `dlopen` in this binary** (`llvm-nm -D --undefined-only` shows
`system` but no `dl*`). The "module load" is `mknod` + `insmod` through the
shell. On the player this is why `sacd_read.ko` needs `bdpdrv` resident and
CPSA initialised *before* the daemon runs (§2.4 of `sacdread-cpsa.md`).

### 3.2 The order of the seven ioctls over a session

```
startup        -- no ioctl until the first open of the input
1st DISC_OPEN  open("/dev/sr0")            (held for the session)
               ioctl 0x40105301  INIT      <-- the only "handshake"
               plain reads: LBA 0x1FE x10, then area TOC(s)     (no ioctl)
               ioctl 0x40105302  AUTH
per DISC_READ  ioctl 0x40105303  READ   (2064*n, n<=128)
               ioctl 0x40105304  DECRYPT (n sectors)
per second     ioctl 0x40105306  UNIT-READY ; ioctl 0x40105307  PROFILE   (server mode only)
DISC_CLOSE     close(/dev/sr0) + ioctl 0x40105305 UNINIT
```

An `open()`/`close()` of `/dev/sacd_read` accompanies every one of those
ioctls (§1.2). A stand-in driver will therefore see, on the happy path:
`open sr0`, then for init: `open sacd_read / ioctl 0x40105301 / close`, and so
on — 3 file opens per audio sector request plus 2 plain reads.

### 3.3 The first UART-visible bytes, and the exact acceptance oracle

**Happy path, server mode (the shipped launch, `/sacd_extract_160 -S &`):**

The first thing the daemon writes to a *visible* stream is the status line,
produced by `server_loop` once per second (`safe_fwprintf` on `stdout`, wide
oriented — `0xe278`–`0xe288`):

```
format 0x31e68 (wide): "\rSACD Daemon %ls active. Client %ls. %ls." + 14 spaces
arg1   0x31f48        : "0.37"
arg2   0x31d70 / 0x31d98 : "connected" | "none"          (is_client_connected())
arg3   0x31dac / 0x31df8 / 0x31e30 :
          "SACD disc inserted"  disc_sacd()==0 && sacd_sacd()>=0
          "Disc inserted"       disc_sacd()==0 && sacd_sacd()<0
          "Tray is empty"       disc_sacd()!=0        (sacd_sacd() not called)
```

The `\r` + trailing padding means it overwrites in place: a serial capture shows
**one** growing/overwriting line, not one line per second. *VERIFIED
(`0xe1e4`–`0xe288`, wide literals decoded from the 4-byte-char strings).*

`server_loop` also has a surprising guard (`0xe1b0`, `validate_stdin` at
`0xe154`): `validate_stdin()` returns `0` when stdin *is* our controlling
terminal (`tcgetpgrp(0) == getpgrp()`), `-1` otherwise. When it returns `0` the
loop **skips the disc poll entirely** (`beq` → `sleep(1)` → continue, `0xe1ec`)
and additionally redirects logging to `/dev/null` (`set_log_file`, `0xe1d8`).
So: **the status line is emitted only when stdin is not a tty** — which is the
`AutoScript` launch case and the case a C-run harness wants. Launching the
daemon from an interactive shell produces no status line at all. *VERIFIED.*

**Non-server mode:** nothing is printed before the first disc access; the first
visible output is either an error string (§5.3) or, at the very end,
`"\rWe are done.."` + 58 spaces + `"\n"` on stdout (`fwrite(0x31d18, 1, 73, stdout)` at `0xe0cc`; literal `0x31d18`).

**Where the log goes.** `log_print` (`0x14cb4`) appends into a buffer and
`log_flush` (`0x15134`) `fwrite`s to the stream in `.data 0x57354`, which
`log_init` defaults to **`stderr`** (literal pool `0x14830 → 0x56df8` and
`0x147ec`); `set_log_file(path)` replaces it with an `fopen(path,"w")`.
If that global is NULL, `log_print` returns immediately and the message is
**silently dropped** (`0x14cdc`). So log lines (`auth_sacd (%#x)`,
`decrypt_sacd: (%#x)`, `Can not install modules`, `%s: mknod/insmod filed`, …)
appear on **stderr** — visible on a serial console, but *not* on stdout, and
suppressed entirely when `server_loop` redirected the log to `/dev/null`.
*VERIFIED for the stream and the drop; the `LOG_MODULES` env gate is
`getenv("LOG_MODULES")` at `0x14500` with default level 3 from
`create_log_module("all")`.*

**Practical C-run oracle, in order of preference:**
1. server mode → the status line with `SACD Daemon 0.37 active.` (means
   `install_modules` succeeded, `/dev/sacd_read` opened, and *no* ioctl has
   failed fatally yet);
2. the same line's third field flipping `Tray is empty` → `SACD disc inserted`
   (means `0x40105306` and `0x40105307` are answering through the driver);
3. `strace -e trace=open,ioctl,read,lseek` on the first `open("/dev/sacd_read")`
   + `ioctl(0x40105301)` pair (means `init_sacd` was reached *and* returned ≥ 0
   — the status line above appears even if `init_sacd` failed later, since
   `disc_sacd()`/`sacd_sacd()` do not need the session).
4. absence of output is **not** evidence of failure.

---

## 4. Q4 — the 44-byte `0x8530` request: what the daemon actually pins

**The daemon never issues `0x8530`.** The only `ioctl` call sites in the binary
are the seven `0x4010530x` wrappers and `BLKGETSIZE64` (§1.2, §7). The 44-byte
request is constructed entirely inside `bdpdrv`'s `_IDECLI_SendOddCmd`
(`sacdread-cpsa.md` §4.2). What the daemon *does* pin is the **input side** of
that construction — the three values the module copies in, and their ranges:

| 44-byte offset (`_IDECLI_SendOddCmd`) | where it comes from in the daemon | value / range pinned by the daemon |
|---|---|---|
| `+0x00 u8 cdb[12]` | derived: `_IDECLI_OddRead`'s READ(10) template, from `u4Offset` and `u4Sectors` | `cdb[0]=0x28`; `cdb[2..5]=be32(lba)`; `cdb[7..8]=be16(n)`; `cdb[10]=0x98`; **`n ≤ 128`** so the transfer-length field fits comfortably (`0x0080` max) |
| `+0x0c buf` | `_IOCTL_SACD_COMMAND.pu1Buf` (`+0x0c`, written at `0x21118`) | a daemon heap pointer, `malloc(0x40800)`, always ≥ `2064*n` bytes |
| `+0x10 len` | `2064 × n` (module-side `kmalloc`, matches the daemon's buffer exactly) | `2064 … 264192` (`n = 1 … 128`, i.e. `0x810 … 0x40800`) |
| `+0x18 reply44` | module-internal `&reply44` on the sender's stack | **not daemon-visible** |
| `+0x1c u8 type` | module constant (`2` for the READ(10) path, `3` for the TUR/profile leg) | **not daemon-visible** |
| `+0x24 timeout_ms` | module constant `10000` (`0x2710`) | **not daemon-visible** |

So `sacdread-cpsa.md` §7.2 can be tightened as follows:

* **Retired as *daemon-side* open questions:** the buffer pointer, the length,
  and the transfer-length/LBA relationship. The daemon supplies exactly
  `(lba, n, buf)` with `n ≤ 128` and a `2064×128` buffer, so `len = 2064*n` is
  *the* length the model must honour, and `cdb[7..8]` carries the *logical*
  sector count. That is not an inference about the kernel; it is what the
  caller's buffer forces.
* **Not tightened (still INFERRED):** the semantic names of `+0x18`, `+0x1c`,
  `+0x24`, and `type`'s exact meaning. Those bytes are written inside
  `mt85xx_ioctl`'s caller (`bdpdrv`), and *nothing the daemon does* constrains
  them — the daemon cannot even observe them. Any further tightening requires
  the kernel image or `bdpdrv`, not the daemon.
* **Retired entirely:** `sacdread-cpsa.md` §7.1 (2048 vs 2064). Both numbers
  are correct on their own paths (§2.4).

One extra fact the daemon side adds for the disc responder: because the
daemon's *first* disc contact is the **plain** 10-sector read at LBA `0x1FE`,
a model can satisfy "the daemon got past `scarletbook_open`" **without any
`0x8530` support at all** — 20,480 zero-filled bytes with `"SACDMTOC"` at
offset 0 and the TOC fields the parser checks is enough to get to the area-TOC
reads and `SACD_IOC_AUTH`. `0x8530` only becomes load-bearing at the first
`DISC_READ` / track rip.

---

## 5. Q5 — the read-failure strings and the C9x+ acceptance oracle

### 5.1 Every failure string in the ioctl/read layer, with its trigger

| string (stream) | literal | trigger (instruction-cited) |
|---|---|---|
| `libsacdread: Can't stat %s\n` (stderr) | `0x35e40` | `sacd_open` `0x2e744`: `stat64(path)` failed **and** no `:` in the path. Followed by `perror("")` (`0x2e750`, literal `0x35e5c` is an empty string) |
| `libsacdread: Could not open %s\n` (stderr) | `0x35efc` | `sacd_open` `0x2ea58`: path is neither file, block, char nor directory (`stat.S_IFMT` not in {0x8000,0x6000,0x2000,0x4000}) |
| `libsacdread: Attempting to use sacd %s mounted on %s\n` (stderr) | `0x35e74` | `sacd_open` `0x2e958`: path is a **directory**; `/etc/mtab` scan found a mount whose dir matches |
| `libsacdread: Couldn't find sacd name.\n` (stderr) | `0x35eac` | `sacd_open` `0x2e9e8`: directory path with no matching mtab entry |
| `libsacdread: Device %s inaccessible.\n` (stderr) | `0x35ed4` | `sacd_open` `0x2e9fc`: mtab entry found, `sacd_open_image_file(mtab dev)` returned NULL |
| **`libsacdread: Can't open %s for reading\n`** (stderr) | `0x35e18` | **`sacd_open_image_file` `0x2e5f8`: `ops.open(path)` returned NULL** — i.e. `/dev/sr0` unopenable **or** `init_sacd()` < 0 (`/dev/sacd_read` missing, or `0x40105301` returned < 0 / `u4Result < 0`). `%s` is `/dev/sr0`, not the failing node. |
| `libsacdread: Could not allocate memory.\n` (stderr) | `0x35468` | `sacd_dev_input_open` `0x21dd4`: `calloc(8,1)` failed |
| `libsacdread: Fatal error in block read.\n` (stderr) | `0x35f1c` | `sacd_read_block_raw` `0x2eb30` / `…_raw64` `0x2ebd0`: `sacd_t->handle == NULL` (an already-failed open) |
| `libsacdread: Can't read Master TOC.\n` (stderr) | `0x358f8` | `scarletbook_open` `0x29880`: `scarletbook_read_master_toc` returned 0 — the **plain** 10-sector read at LBA `0x1FE` failed |
| `libsacdread: Not a ScarletBook disc!\n` (stderr) | `0x35b18` | `scarletbook_read_master_toc` `0x2a2cc`: `strncmp(buf,"SACDMTOC",8) != 0` |
| `libsacdread: Can't read Area TOC 1.\n` / `…2.` (stderr) | `0x35920` / `0x35948` | `scarletbook_open` `0x29a38` / `0x29c10`: the area-TOC plain read returned 0 |
| `libsacdread: Not a valid Area TOC!\n` | `0x35cbc` | `scarletbook_read_area_toc` `0x2c198`: area-TOC signature mismatch (`TWOCHTOC`/`MULCHTOC`) |
| `libsacdread: Unsupported version: %i.%02i` | `0x359a4` | master-TOC version field out of range |
| `auth_sacd (%#x)\n` (stderr, via log) | `0x3543c` | `sacd_dev_input_authenticate` `0x21d08`: `auth_sacd()` < 0 **and** log level > 1 |
| `authentication failed: %x` (stderr, via log) | `0x31c64` | `main_loop` `0xdb28`: `sacd_authenticate()` != 0 and log level > 1 (note: **not** treated as fatal) |
| `decrypt_sacd: (%#x)\n` (stderr, via log) | `0x35450` | `sacd_dev_input_decrypt` `0x21d80`: `decrypt_sacd()` < 0 and log level > 1 |
| `Failed to connect` / `Failed to encode request` / `Failed to decode response` / `Response result non-zero or disc opened` (stderr) | `0x354a4`/`0x354b8`/`0x354d4`/`0x354f0` | `sacd_net_input_open` only — the **TCP-client** mode (§2 mode 1), not the device path |
| `%s: mknod/insmod filed` / `%s: write filed %x` / `%s: open filed %x` / `%s: rmmod filed` (stderr, via log) | `0x36288`/`0x362a0`/`0x362b4`/`0x362d8` | `install_modules`/`remove_modules` — `%s` is `__func__` |
| `Can not install modules` (stderr, via log) | `0x31fe4` | `main` `0xe44c`: `install_modules() < 0` (the daemon then exits) |

The ioctl wrappers themselves emit **nothing** on failure (§1.2): a driver that
returns `-ENOTTY` produces no output at all, only the downstream symptom.

### 5.2 The C9x+ acceptance oracle for the "real daemon" stage

Staged, cheapest first, each with a **positive** signal (never "no error"):

| # | gate | positive signal | what it proves |
|---|---|---|---|
| D-1 | daemon starts at all | `install_modules()` returns 0 → the process reaches `server_loop`; **no** `%s: mknod/insmod filed` on stderr | `/dev/sacd_read` node created and `insmod` of the embedded `.ko` succeeded ⇒ `bdpdrv` resident, all 13 symbols resolved, CPSA slot free |
| D-2 | `SACD_IOC_INIT` accepted | no `libsacdread: Can't open /dev/sr0 for reading` on the first `DISC_OPEN`/open, and the ioctl returns ≥ 0 with `u4Result ≥ 0` | the driver's `Connect(0x16b,…)` + `CPSMode_Ctrl(…,0x40,TRUE)` path completed |
| D-3 | TOC leg | absence of `Can't read Master TOC.` / `Not a ScarletBook disc!` on `scarletbook_open` | the **plain** `/dev/sr0` read at LBA `0x1FE` returned 20,480 bytes with `"SACDMTOC"` |
| D-4 | auth leg | no `auth_sacd (%#x)` / `authentication failed:` | `SACD_IOC_AUTH` (`0x40105302`) accepted |
| D-5 | read leg | a `DISC_READ` reply whose `result` is 1..128 (not 0) **and** whose payload is `result*2048` bytes | `SACD_IOC_READ` (`0x40105303`) returned an `u4Result ≥ 0` ⇒ `_IDECLI_OddRead` + `mt85xx_ioctl(0x8530)` completed |
| D-6 | status line | `\rSACD Daemon 0.37 active. Client none. SACD disc inserted.` on the console | `0x40105306` == 0 and `0x40105307` ≥ 0 — the profile gate the daemon's own server loop uses |
| D-7 | decrypt leg | no `decrypt_sacd: (%#x)`; **and the ioctl returns** (it blocks on the GCPU worker with no timeout — `sacdread-cpsa.md` §4.3) | `SACD_IOC_DECRYPT` (`0x40105304`) did not hang ⇒ the TrustZone/GCPU completion path exists |

D-5 and D-7 are separable: the raw read works before any GCPU/TrustZone
support, so **"real daemon reads real sectors through `SACD_IOC_READ`"** is the
right endgame gate, with decrypt explicitly out of scope until D-7 is solved.

### 5.3 Two error-path behaviours that will bite a differential harness

1. **A failed read still triggers a decrypt.** `client_thread` `0xcc0c`–`0xcc30`
   and `processing_thread` `0x28968`–`0x289e4`: no branch between the read and
   the decrypt. If a stand-in returns `u4Result < 0` from `SACD_IOC_READ`, the
   daemon immediately issues `SACD_IOC_DECRYPT` over a stale buffer. Do not
   read a decrypt ioctl as "the read succeeded".
2. **`DISC_OPEN` failure is a plain `-1`.** `client_thread` initialises the
   reply result to `{-1,-1}` (`0xca24`) and jumps straight to the encoder when
   `sacd_open` returns NULL (`0xcc58`). No error string is guaranteed — the
   only clue is `libsacdread: Can't open /dev/sr0 for reading` on stderr.

---

## 6. Provenance

| input | identity |
|---|---|
| `original/sacd_extract_160` | sha256 `0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45`, 350,830 B, ELF32 ARM EABI5, dynamically linked (`/lib/ld-linux.so.3`), **unstripped with DWARF**, 818 symtab entries, 432 `T`/`t` |
| tools | Apple `llvm-objdump`/`llvm-nm`/`llvm-readelf` 22 (`/opt/homebrew/opt/llvm/bin`), `strings`, Python 3 for literal-pool resolution |
| method | deterministic decode only: `llvm-objdump -d` for instructions, `.rodata`/`.data` read by `vaddr − 0x8000` for literals and wide strings, `llvm-nm -n` for symbol boundaries. **No hexdump eyeballing.** |

Note on the file: `.rodata` starts at `vaddr 0x3199c` / file `0x2999c`, `.text`
at `vaddr 0xc818` / file `0x4818` — the constant `vaddr − 0x8000 = file offset`
holds for all of `.text`/`.rodata`, which is why `sacdread-cpsa.md`'s file
offsets (`0x1901c`, …) are just `vaddr − 0x8000`.

---

## 7. Reproduce

```sh
OD=/opt/homebrew/opt/llvm/bin/llvm-objdump
NM=/opt/homebrew/opt/llvm/bin/llvm-nm

# the seven wrappers and their payload stores
$OD -d --start-address=0x20f90 --stop-address=0x213a0 original/sacd_extract_160

# the ops-table selection (which mode gets which pointer)
$OD -d --start-address=0x22954 --stop-address=0x22b4c original/sacd_extract_160

# open/close gates, read64 vs read, total_sectors
$OD -d --start-address=0x21da4 --stop-address=0x22200 original/sacd_extract_160

# boot: main / install_modules / server_loop
$OD -d --start-address=0xe1b4 --stop-address=0xe4b0 original/sacd_extract_160
$OD -d --start-address=0x2f970 --stop-address=0x2fbc4 original/sacd_extract_160

# the two read paths and their callers
$OD -d --start-address=0x2eb04 --stop-address=0x2ebf0 original/sacd_extract_160
$OD -d --start-address=0x2a1fc --stop-address=0x2a270 original/sacd_extract_160   # master TOC, LBA 0x1FE x10
$OD -d --start-address=0x28930 --stop-address=0x289f0 original/sacd_extract_160   # rip: read64 + decrypt
$OD -d --start-address=0xcb90 --stop-address=0xcc40 original/sacd_extract_160    # DISC_READ: read64 + decrypt

# every ioctl call site in the binary (should be exactly eight)
$OD -d original/sacd_extract_160 | grep 'ioctl@plt'

# literals / wide strings by vaddr (file offset = vaddr - 0x8000)
python3 - <<'EOF'
import struct
d = open('original/sacd_extract_160','rb').read()
def word(v): return struct.unpack('<I', d[v-0x8000:v-0x8000+4])[0]
def cstr(v):
    o = v-0x8000; return d[o:d.index(b'\0', o)]
def wstr(v):
    o, out = v-0x8000, []
    while True:
        c = struct.unpack('<I', d[o:o+4])[0]
        if not c: return ''.join(out)
        out.append(chr(c)); o += 4
print(word(0xcf98), '= 2064*128 (client_thread raw buffer)')   # 264192
print(word(0xcf90), '(protobuf reply buffer)')                # 263168
print(word(0x2b010), '= master-TOC LBA')                      # 0x1fe
print(cstr(word(0x2b014)))                                    # SACDMTOC
print(wstr(0x31e68)); print(wstr(0x31f48))                    # status line, "0.37"
EOF
```
