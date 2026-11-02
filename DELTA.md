# DELTA.md — community deltas vs. sacd-ripper v0.3.7 (de008ff)

Everything here is **verified from disassembly** unless marked inferred.
This is the exact change-set the closed-source "sacd_extract_160" applies to
the public v0.3.7 tree.

## Build recipe (recovered)

- Vanilla FSF GCC 4.4.1 (crosstool-style build, `/usr/local/mtk-toolchain/gnuarm-4.4.1`), NOT CodeSourcery (proven by libgcc byte differences)
- glibc 2.9 sysroot, ARM soft-float, binutils 2.19.1
- `-O0`, `-march=armv6z` (default of the MTK triplet; proven by sxtb/uxtb usage)
- `-D_LARGEFILE64_SOURCE` behavior (open64/lseek64/fstat64/reopen64 calls)
- `ld -b binary` embeds sacd_read.ko (`_binary_sacd_read_ko_*`)
- No `-g` for app code (only C runtime kept DWARF)
- MAX_PROCESSING_BLOCK_SIZE changed 512 → 128 in scarletbook.h

## New files

### `tool/install.c` (+ install.h) — module installer
- `install_modules()`: memcpy("/tmp/",6) into static `mod_file[26]`; tmpnam;
  open64(O_WRONLY|O_CREAT|O_EXCL); write embedded .ko; system("mknod -m0666
  /dev/sacd_read c 10 201"); sprintf("insmod %s minor=201"); system; unlink;
  open64("/dev/sr0"...) — final check opens **/dev/sacd_read**; on failure
  LOG("%s: mknod/insmod filed", "install_modules") + remove_modules() + -1.
  - write-failure path leaks fd (no close) — faithful.
- `remove_modules()`: system("rmmod sacd_read"); if /dev/sacd_read still
  opens: LOG("%s: rmmod filed","remove_modules"); system("rm -rf /dev/sacd_read").

### `libsacd/sacd_read.c` (+ sacd_read.h) — CPSA ioctl wrappers
All wrappers open `/dev/sacd_read`, ioctl with 16-byte arg `{a,b,c,d}`,
result in `.a`, close. ioctl cmds `_IOR('S', nr, 16)`:
- init_sacd (0x01), auth_sacd (0x02), uninit_sacd (0x05, void return,
  no result check), disc_sacd (0x06), sacd_sacd (0x07)
- read_sacd (0x03): (x,y,z) → ioc.b/.c/.d
- decrypt_sacd (0x04): (buf, blocks) → ioc.c/.d  (note: +8/+12, not +4/+8)

## Modified files

### `tool/main.c` — server mode merged in
- From src/server.c (PS3): client_thread, listener_thread, is_client_connected
  (pthreads; port 2002; `close(*client)`; client `p_socket` = int*)
  - DISC_OPEN uses "/dev/sr0" (was /dev_bdvd)
  - DISC_READ: `sacd_read_block_raw64`, **unconditional** sacd_decrypt
    (non_encrypted_disc/checked_for_non_encrypted_disc vars remain, dead)
  - request struct: {type, sector_offset(u32), sector_count(u32)}
  - response.result is int64 (proto already had int64)
- exit handling: static `exit_requested` + user_requested_exit/requested_for_exit
- `init()`: defaults input_device="/dev/sr0" (was /dev/cdrom)
- `validate_stdin()`: tcgetpgrp(0); ==-1 → -1; getpgrp()==pgrp → 0 else -1
  (if/else form, not ternary)
- `server_loop()`: validate_stdin; console → set_log_file("/dev/null");
  loop { if headless: disc_sacd()/sacd_sacd() checks + status line
  `L"\rSACD Daemon %ls active. Client %ls. %ls.   "`
  args: L"0.37", L"c"/L"n", disc status}; sleep(1) }
  - has_disc/is_sacd declared at function top, uninit
- `main()`: init → parse_options → install_modules gate → setlocale/fwide →
  server_mode ? (pthread_create(listener) + server_loop) : main_loop →
  freopen(0,"w",stdout)/fwide(-1) → remove_modules → free_lock,
  destroy_logging, putchar('\n'), return 0
- `main_loop()` = reference main() extraction body + `sacd_authenticate`
  after scarletbook_open (LOG "authentication failed: %x") + banner
  `fprintf(stdout, "\rWe are done.. …\n")` at end
- `handle_sigint`: added `if (output) scarletbook_output_interrupt(output);
  requested_for_exit(1);`
- `parse_options`: `-S/--server-mode` → opts.server_mode (new field at
  struct offset 0x32c); help/usage/options_string updated

### `libsacd/sacd_input.c` — three-way backend
- struct unchanged {fd, input_buffer} (8 bytes)
- sacd_dev_input_open: open64; `if (sacd_input_read64 == sacd_dev_input_read64)`
  gates init_sacd() (goto error on failure)
- sacd_dev_input_close: same gate for uninit_sacd()
- sacd_dev_input_read: lseek64 variant of reference read loop
- NEW sacd_dev_input_read64(dev,pos,blocks,buf): read_sacd(pos,blocks,buf);
  <0 → 0 else blocks
- sacd_dev_input_authenticate: auth_sacd(); <0 → LOG("auth_sacd (%#x)") + ret
- sacd_dev_input_decrypt: decrypt_sacd(buffer, blocks); <0 → LOG + -1
- NEW sacd_net_input_authenticate/decrypt: return 0 (no-ops for file images)
- sacd_input_setup: net (a.b.c.d:port) → net backend (read64=net read), ret 1;
  `strcmp(path,"/dev/sr0")==0` → dev backend with read64, ret 2;
  else file images: read64=dev read, authenticate/decrypt = NET no-ops, ret 0
- sacd_dev_input_total_sectors: fstat64; if st_size==0 → ioctl(BLKGETSIZE64
  =0x80041272) into st_size; size/2048

### `libsacd/sacd_reader.c/.h`
- NEW sacd_read_block_raw64 (sacd_input_read64; returns int)

### `libsacd/sacd_input.h`
- NEW extern function pointer sacd_input_read64

## Known cosmetic (non-source) differences

- Original links locally-compiled glibc bits (stat64/fstat64/cs
  `init.c`,`elf-init.c` CUs — its glibc 2.9 kept stat64 out of libc.so);
  our build resolves stat64 via PLT from libc. Function count off by one.
- Original libgcc float compare used post-index store (FSF); we link FSF
  assembly objects for those routines (see reconstruct/fsflibgcc/).

## Slot-layout rule (for -O0 codegen parity)

- Frame: params deepest (arg1 highest of the spill block), then aggregates
  (structs/arrays) in REVERSE declaration order, then scalars in FORWARD
  declaration order (first-declared deepest), block-scoped vars included in
  source order; compiler temps (sret, int64 halves) above them.

## Parity session 2 final state: 377/388 instruction-exact

All source-level differences between the community binary and the
reconstruction are resolved. The 11 remaining mismatches:

1. **Toolchain-furnished objects (9)** — csu (`__libc_csu_init`, `_start`,
   `call_gmon_start`), gcc crtbegin (`__do_global_dtors_aux`, `frame_dummy`),
   and libgcc div helpers (`__divdi3`, `__udivdi3`, `__gnu_{,u}ldivmod_helper`).
   These bytes come from MTK's own glibc/libgcc *builds* (their glibc build
   flags and libgcc patch level); without their exact build recipe these
   cannot be matched. Class: unfixable-at-source.
2. **Compiler-build micro-differences (4)** — the original compiler is a
   post-4.4.1 4.4-branch snapshot (proven by libgcc2.c decl_line +3); our
   closest public proxy is the 4.4.2 release. Three observable differences
   remain between those builds at -O0:
   - a `mov r0, r0` nop after `bl close` in sacd_dev_input_open
   - pthread_create argument-evaluation order (listener_thread, main)
   - memcpy/sprintf constant-arg temp dance (install_modules)

### Source-level discoveries this session (vs the v0.3.7 reference)
- Build flags: `-D_GNU_SOURCE` (transparent-union sockaddr args), 
  `-D_FILE_OFFSET_BITS=64` (fopen->fopen64 rename, stat64)
- scarletbook_output buffer = MAX_PROCESSING_BLOCK_SIZE * 2064 (raw sector)
- processing_thread: raw64 read; non-encrypted-disc check before the read;
  DECRYPT IS UNCONDITIONAL (reference guards it)
- server_loop: is_sacd = !(sacd_sacd() < 0); ternary not negated
- client_thread response buffer = 128*2064
- get_music_filename: 4th param (caller passes opts.output_file), 4-branch
  album fallback, strlen()->*x fold tests, %N - %T first-branch order
- install_modules: O_TRUNC (not O_EXCL); goto-label error structure
- sacd_net_input_open: dev/err zero-inits; fprintf error messages
  ("Failed to connect", "Failed to encode request", "Failed to decode
  response", "Response result non-zero or disc opened"); error path calls
  sacd_input_close(dev) via the global fn-ptr (blx)
- sacd_net_input_close: cleanup guarded by if(dev); dev/input_buffer NULL-out
- scarletbook_print_area_text: the community FIXED the reference's copy-paste
  bug (condition now arranger_phonetic)
- sacd_read/decrypt_sacd protos: (int,int,void*)/(int,void*)

### gcc -O0 codegen forensics codified (for future parity work)
- literal pool vs mov-immediate: non-encodable constants go to the pool
- int<->uint and ptr<->int arg conversions emit temp-dance; same-type = direct
- incompatible fn-ptr assignment flips ldr order (sacd_input_setup signal)
- fprintf(const) folds to fwrite + dead `mov r0,r0` artifact at body level,
  but not inside if-blocks; strlen(x)>0 folds to address-materialized *x!=0
- goto-target label blocks get a leading `mov r0,r0` if empty (incl. `;`)
- `if (x) goto L;` = branch-on-true to distant block; `if (x) {block}` =
  branch-on-false over inline block; ternary/goto choice is readable from
  branch polarity + block placement
