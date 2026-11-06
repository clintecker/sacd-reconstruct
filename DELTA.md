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

## Parity session 2 final state: 377/390 instruction-exact

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

## Parity session 3 (2026-11-02): 385/390 instruction-exact + interface parity

Resolved with the forensics kit (incoming/sacd-installer-and-status/):
- `install_modules`/`remove_modules` source corrected to the witness
  (`strcpy(mod_file, "/tmp/")` — the strcpy builtin's arg expansion produces
  the original `ldr r3`/`mov r1,r3` dance; 26-byte `mod_file`; `size_t`
  mod_size vs signed write result; nested-if error structure; `__func__`
  logging names). Verified: all 464 bytes of install_modules, 132 bytes of
  remove_modules, and 236 bytes of installer .rodata byte-identical at the
  original addresses via a reference-address relink (no masking).
- `server_loop` status strings restored: `L"connected"` / `L"none"`
  (previously misread as `L"c"` / `L"n"`). Six-state QEMU status test
  (headless server_loop + real guest vfwprintf) passes 6/6 on the rebuilt
  candidate, matching the reference exactly.
- `__FILE__` parity: the original was built from /root/sacd-ripper (its
  assert-path strings embed that prefix in buffer_pool.c, dst_decoder.c,
  id3.c, scarletbook_read.c). Our build compiles libs/* through
  BUILDROOT=/root/sacd-ripper (symlink farm on the VM); the kit's
  sudo-free alternative (#line 1 directives + -iquote) is equivalent.
- pthread callback signatures: client_thread/listener_thread return void*
  (type-compatible with pthread_create; no codegen change since both end
  in pthread_exit).
- fn_diff: 385/390 instruction-exact (denominator corrected 2026-11-02:
  earlier revisions said "/388" — fn_diff compares 390 functions, so
  385 exact + 5 remaining = 390; matches issue #2's count).
  Remaining 5 = __libc_csu_init,
  __do_global_dtors_aux, _start, call_gmon_start, frame_dummy — all
  startup/crt objects addressed by the issue-#4 relink recipe (GNU
  crtbegin.o from source + glibc 2.9 elf-init/stat64/fstat64 rebuilt;
  CS 2009q3 libgcc_s.so.1 as pinned dynamic input, --exclude-libs
  libgcc.a, --as-needed).

New tooling: tools/pool_audit.py — audits every PC-relative pool load in
every function by *content* (strings compared exactly, scalars by value,
pointer-bearing structures with address words masked). Catches literal
bugs fn_diff cannot see (it was the L"c"/L"none" class + __FILE__ paths
that motivated it). Current: 369/390 clean; 15 residual flags,
all accounted for (7+4+3+1):
- 7 = .data object ORDER (benign, layout only): original links
  yarn.c -> dst_fram.c -> dst_data.c -> id3_frame.c -> id3.c -> dsdiff.c
  -> scarletbook_output.c -> iso_writer.c -> dsf.c -> scarletbook.c;
  our Makefile orders differently. Runtime-invisible; documented, not
  chased (full byte parity would reorder link lists).
- 4 = GOT/pb-descriptor windows (import-set differences) — resolved by
  the issue-#4 relink. These four get re-checked on the exact relinked
  ELF that ships (release checklist).
- 3 = audit window straddle artifacts (empty-string literal neighbors,
  BOM constants inside code-section ranges, handler tables adjacent to
  the embedded ko blob) — verified equal by hand.
- 1 = __libc_csu_init itself (the known startup-object mismatch, same
  class as the five fn_diff residuals; resolved by the issue-#4 relink).

Rebuilt candidate SHA-256 (session 3, unstripped):
e6daa1128da118f1fb7a7bf3c95d6faba40bc1021c920aec7fca34cae93adaa0

Decision (operator): function-level parity is DONE; effort pivots to the
BX510 drop-in track — TCP client harness for baseline capture (issue #5/#6
critical path). .data order finding documented above instead of fixed.

## Release pipeline (2026-11-02/03): `make verify` — VERIFY: PASS

One release ELF built from tracked sources by tools/release_build.py via
`make verify` (tools/release_verify.sh), reproducing bit-for-bit across
independent full runs:

    RELEASE IMAGE  reconstruct/release/sacd_extract_160_release
    SHA-256       e91720fbbbd592505bde6630843b0495ff82a93e40c0e427aaa70a081ff9ae22

Build command: `cd reconstruct && make verify` on the build host (host
prerequisites documented in tools/release_build.py: FSF gcc-4.4.1 source +
built 4.4.1 tree, glibc-2.9 sources, CodeSourcery 2009q3-67 sysroot whose
libgcc_s.so.1 must hash 5068e1ea...bec6d4, FSF binutils 2.19.1).

Recipe: tracked tool/install.c and tool/main.c compile directly (asserted,
never substituted or repaired); the four __FILE__ TUs via `#line 1
"/root/sacd-ripper/libs/..."` + `-iquote`; ko embedded via .incbin; GNU
crtbegin/crtend from crtstuff.c; glibc 2.9 elf-init/stat64/fstat64 from
source; division helpers + private libgcc.a from lib1funcs.asm
(--exclude-libs); link with CS libgcc_s.so.1 as --as-needed dynamic
provider.

Checks against that exact file — all green:
- fn_diff 388/390 normalized functions. The two accepted residuals for
  the hardware trial are `_start` and `call_gmon_start` (glibc 2.9 csu /
  crtbegin call_gmon: startup code built from the CS sysroot objects,
  not source; behavior-neutral per the eager-binding, status and CLI
  differentials that all pass on this image).
- Link interface: DT_NEEDED order (libpthread.so.0, libgcc_s.so.1,
  libc.so.6), 270 defined exports, 131 undefined imports with binding/
  type/DSO/version, 5 .ARM.exidx function+descriptor pairs — all MATCH
  the original. Only __aeabi_unwind_cpp_pr0@GCC_3.5 imported.
- Six-state status test 6/6; eager binding (LD_BIND_NOW=1) + --help exit 0.
- Integer-division oracle 9,246/9,246.
- tools/pool_audit.py on the release image: 384/384 clean, zero
  mismatches — every PC-relative pool literal reaches the same object
  and value as the original (the four previously flagged GOT/pb windows
  and __libc_csu_init cleared with the relink; the remaining .data
  object-order windows of the _fsf build also cleared in the release
  layout). Release stop rule satisfied.

fn_diff changes enabling the GNU-objdump backend (OBJDUMP env/--objdump):
whitespace collapse, decimal/hex pool offsets, ";"/"@" comment stripping,
"(bad)" wildcards, and function-relative branch-target normalization —
the original's ReadTableSegmentData straddles the ABS symbol
_binary_sacd_read_ko_size, so intra-function branch anchors differ
between disassembler layouts (verified: identical code, different
symbol anchoring).

## QEMU protocol rig (2026-11-03): replay verdict IDENTICAL (issue #5)

tools/qemu_rig.c (ARM LD_PRELOAD shim) substitutes the sacd_read.ko device
layer under qemu-arm-static: system() no-ops for mknod/insmod, /dev/sr0 +
/dev/sacd_read open the fixture image (RIG_DEVFILE), the seven module
ioctls served per the reconstructed sacd_read.c ABI; both device read
paths (plain lseek64+read for TOCs, the READ ioctl for payloads) draw from
the same file. Fixture: a real Scarlet Book ISO (user's own rip,
firebird.iso, SHA-256 1d8f0697...) — genuine SACDMTOC@510, real area TOC,
real encryption ranges. See docs/RIG-ARCHITECTURE.md.

Replay (sacd_client.py capture, identical request sequence):
  original          -> OPEN=0 SIZE=1064208 4 reads + reconnect-repeat
  release candidate -> same sequence
  compare verdict:  IDENTICAL — every result code, payload SHA-256, frame
                    hash and the disc size match (evidence/qemu-rig/<stamp>).

Codified as make targets (root Makefile, docs-sync'd):
  sacd-sync  stage repo + build sources to the VM (never extract a
             directory member through the ~/the verification tree/reconstruct symlink
             — GNU tar replaces the symlink with a real dir and orphans the
             build tree; cost the release ELF once)
  the verification tree  clean release build + all checks
  sacd-rig   orig-vs-candidate replay + evidence pull + compare
  sacd-parity  Mac-side fn_diff/pool_audit/regressions (accepted residuals
             _start + call_gmon_start only)
  sacd-selftest  client self-check against an in-process fake server
  vm-script  stage-and-run a local script on the VM — complex VM
             operations never go through vm-exec one-liners (nested-quote
             breakage cost three debug round-trips)

Behavior note (both binaries, confirmed in the rig): the listener binds
port 2002 hardcoded and sets no SO_REUSEADDR, so a fast daemon restart
after active client sessions fails to bind with EADDRINUSE until the
TIME_WAIT sockets clear (~60s). The rig waits for port-free between legs.

## Module-contract integration from the full-system team (2026-11-03)

The BX510-Handoff emulator work (full-system QEMU 9.2.4 "player.local",
boots Sony's Linux 2.6.35 + real SquashFS; both daemons run inside the
real guest OS against Sony's shipped loader/libc — 1,059 identical
--help bytes) independently disassembled the embedded sacd_read.ko
(SHA-256 b3d7a383e45d3bbe1a987a4a2e15ab7a68dd55e88d0319f7a0fd2e9cf0246dfa)
and pinned the real ioctl contract:
  - SACD_IOC_READ serves RAW 2064-byte frames (12-byte header + 2048
    logical + 4 trailing; .text+0x318/+0x368/_IDECLI_OddRead);
  - SACD_IOC_DECRYPT packs 2048 bytes from offset 12 of each frame
    (CPSA_SACDCmdDecrypt output path, .text+0x4b4/+0x4e4/+0x500);
  - hence 0x40800 raw / 0x40000 logical at 128 sectors.
The qemu-user shim (tools/qemu_rig.c) now models that shape: READ
synthesizes deterministic raw frames around the fixture's logical bytes,
DECRYPT performs the module's offset-12 packing (still NOT CPSA crypto —
the on-player optical/ pair capture covers real raw metadata). The
sequential replay verdict stays IDENTICAL through the real striding.

Also from that handoff: the compare defect they demonstrated (altered
OPEN result + wire hash still compared IDENTICAL) is fixed — compare now
checks every frame (request bytes, response type/result/length, frame
hashes) before the read table. Their optical/media_check.py remains the
independent strict verifier with negative controls.

Overlap (&conn_s race) verdicts: the starved-session tail class
(timeout vs reset/EOF) is scheduler timing — the SAME binary produces
both across runs — so starved exchanges compare as one class; successful
exchanges still compare exactly. Both replays IDENTICAL
(evidence/qemu-rig/20261103-rawframe/, daemon SHAs stamped in manifests:
0fdcefdb… original, e91720fb… release).

Player: BDP-S5100/BX510 family unit at 192.0.2.10 (M15.R.0257),
pinned into evidence/bx510/BASELINE-RUNBOOK.md. Physical baseline still
outstanding: the one on-player attempt received zero reply bytes to
DISC_OPEN.
