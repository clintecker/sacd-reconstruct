# sacd_extract_160 reconstruction — analysis notes

Goal: reconstruct compilable source that reproduces the closed-source community
binary `sacd_extract_160` (Sony/Mediatek BDP AutoScript SACD server, Feb 2018).

## Original binary facts (from ELF itself)

- `original/sacd_extract_160`: ELF32 ARM EABI5 **soft-float** (`ld-linux.so.3`),
  dynamically linked against libc.so.6 / libpthread.so.0 / libgcc_s.so.1 only
  (**no libstdc++** — the program is C, not C++, despite what community lore says).
- Compiler: **GNU C 4.4.1**, MTK toolchain `armv6z-mediatek-linux-gnueabi`
  (comp_dir `/usr/local/mtk-toolchain/gnuarm-4.4.1/...`), glibc **2.9** sysroot,
  linked for Linux 2.6.27+.
- Built **without -g for app code**: the only DWARF compile units are the glibc
  csu (`init.c`, `elf-init.c`, `stat64.c`, `fstat64.c`) and libgcc assembly.
  App-level reconstruction therefore works from the (complete, unstripped) symbol
  table + disassembly. 687 symbols, 349 distinct app functions, 402 disasm chunks
  (duplicate static locals in multiple TUs get `__N` suffixes in analysis/funcs/).
- Banner string: `SACD Ripper release 0.37 Copyright (c) 2010-2012`.
- Embedded kernel module: `sacd_read.ko` (97,805 bytes) objcopy'd in as
  `_binary_sacd_read_ko_start` (VMA 0x3efdc = file off 0x2efdc).
  Extracted to `original/sacd_read.ko`. It is ARM ELF relocatable **with DWARF**,
  single source `/home/sym/sacd_read/sacd_read.c` built against linux-2.6.35,
  exports CPSA_SACDCmd{Enable,Disable,Decrypt,SetCtrl} + sacd_read_{init,exit,open,release,ioctl},
  and does `kallsyms_lookup_name_diag` to find Sony's CPSA driver functions in the
  running kernel.
- `.data` also contains the AutoScript-era strings: `insmod %s minor=201`,
  `mknod -m0666 /dev/sacd_read c 10 201`, `rmmod sacd_read` (install_modules /
  remove_modules), `/dev/sacd_read`.

## Provenance mapping (what source exists vs. what we must decompile)

The binary is a port of the **sacd-ripper** project trunk at the **v0.3.7** commit
(`de008ff`, 2012-12-29, "bumped version to 0.3.7") — reference clone at
`reference/EuFlo_sacd-ripper` (checked out at that commit).

Function-name audit: of 349 app functions, all but the list below exist in the
v0.3.7 tree (src/, libs/libsacd, libs/libcommon, libs/libid3, libs/libdstdec):

### Community delta — must be hand-decompiled (not in any published revision)

| Function | Addr | Size | Role (inferred) |
|---|---|---|---|
| init_sacd | 0x20f90 | 0x90 | CPSA init wrapper (ioctl on /dev/sacd_read) |
| auth_sacd | 0x21020 | 0x90 | CPSA authenticate wrapper |
| read_sacd | 0x210b0 | 0xb4 | CPSA raw-sector read wrapper |
| uninit_sacd | 0x2120c | 0x6c | CPSA teardown wrapper |
| decrypt_sacd | 0x21164 | 0xa8 | CPSA decrypt wrapper |
| disc_sacd | 0x21278 | 0x90 | CPSA disc-state wrapper |
| sacd_sacd | 0x21308 | 0x90 | CPSA ? wrapper |
| sacd_dev_input_read64 | 0x22028 | 0x58 | 64-bit-sector device input read |
| sacd_read_block_raw64 | ? | ? | 64-bit-sector reader (sacd_reader.c delta) |
| install_modules | 0x2f970 | 0x1d0 | writes embedded sacd_read.ko to /tmp, mknod + insmod |
| remove_modules | 0x2fb40 | 0x84 | rmmod sacd_read + rm /dev/sacd_read |
| requested_for_exit | 0xc908 | 0x2c | exit-flag getter (exit handling delta) |
| validate_stdin | 0xe154 | 0x60 | ? (main.c delta) |
| init | 0xd978 | 0xe4 | ? (main.c delta; static) |
| stat64/fstat64 | — | — | glibc 2.9 statically-included wrappers (not app code) |

Also community (exist in PS3 src/ but must be diffed for the ARM port):
main.c merged server mode into the client tool: `server_loop`, `main_loop`,
`client_thread`, `listener_thread`, `is_client_connected`, `-S --server-mode`
option, `validate_stdin`, plus `sacd_pb_stream` socket istream/ostream.
Binary function `main_loop` (0xda5c) replaces PS3 dialog UI of src/main.c.

### Open-source components statically linked (identified by symbol names)

- sacd-ripper v0.3.7: scarletbook.*, sacd_reader/sacd_input (with **new disc
  backend** via CPSA module), dsf, dsdiff, iso_writer, cuesheet, output, print
- libs/libcommon: log.c/logging.c, charset.c, utils.c (trim_*, sanitize_*,
  str_replace...), fileutils.c, list.h (kernel lists), socket.c + timeout.c
  (LuaSocket-derived: socket_create/bind/listen/connect, inet_tryconnect,
  timeout_*), pb_encode.c/pb_decode.c (nanopb-era protobuf), sacd_pb_stream.c
- libs/libid3: libid3tag-derived (id3_* — matches libid3tag API)
- libs/libdstdec: DST decoder (DST_InitDecoder, ReadArithmeticCodedData,
  ReadFilterCoefSets, LT_*, FIO_BitGet*, UnpackDSTframe, ...)
- **yarn** — Mark Adler's C thread/lock library (ignition, reenter, destruct,
  launch, join, join_all, wait_for, possess, release, twist, peek_lock,
  new_lock, free_lock, yarn_mem) — must be fetched (not in v0.3.7 tree!)
- decode_thread/write_thread/setup_decoding_jobs/finish_decoding_jobs etc.:
  dst decoding thread pool — check which TU these live in (dst_decoder delta)

## Verification plan

1. Hand-decompile the community delta from analysis/funcs/*.asm.
2. Fetch yarn (madler/yarn) at a version whose API matches (fail, my_malloc?
   — my_malloc/fail are actually from libcommon utils.c).
3. Assemble reconstruct/ source tree = v0.3.7 files + delta files.
4. Cross-compile with arm-linux-gnueabi GCC (soft-float). Ideal parity target:
   CodeSourcery 2009q3 / MTK gnuarm-4.4.1 (GCC 4.4.1 + glibc 2.9).
5. Per-function disassembly diff vs. original; behavior parity is the bar,
   instruction-level parity is the stretch goal.

## Open questions

- Which exact libid3tag version (file date says EuFlo tree's libs/libid3)?
- Whether the community port also edited scarletbook_read.c etc. beyond the
  64-bit sector reads (sacd_read_block_raw64, sacd_get_total_sectors vs 64?).
- sacd_ripper.proto contents at v0.3.7 vs the ServerRequest/ServerResponse
  messages seen in strings (ServerRequest_fields, ServerResponse_fields,
  sector_count/offset defaults).
