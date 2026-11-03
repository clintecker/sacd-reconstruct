# QEMU protocol rig architecture (issue #5)

How the port-2002 daemon is exercised end-to-end under emulation, for
teams reproducing this pathway.

## Model: qemu-user + LD_PRELOAD, not full-system emulation

    qemu-arm-static -L <CS-2009q3-sysroot> \
        -E LD_PRELOAD=sacd_rig.so -E RIG_DEVFILE=<disc.iso> \
        -E LANG=C -E LC_ALL=C  <daemon.elf> -S

The daemon runs as real ARMv6 code translated by qemu-user; syscalls go
to the host kernel. Networking is native: bind/listen/accept are host
syscalls, so the daemon's port 2002 is a real port — a plain TCP client
connects with no forwarding. Threads (pthread) work. Everything above the
interposed functions runs for real: nanopb parsing, locks, wide output,
LOG subsystem, the tmpnam/ko-extract/unlink install dance on the real FS.

## Interposition shim (tools/qemu_rig.c)

Three libc doors cover every player touchpoint:

1. system() -> 0. install_modules()'s mknod/insmod (and rmmod/rm on
   teardown) must appear to succeed without executing.
2. open64() -> the disc image for BOTH "/dev/sr0" (device fd: fstat64 +
   the plain read path) and "/dev/sacd_read" (opened per module call).
3. ioctl() -> the sacd_read.ko protocol, 0x40105103.. wait: numbers are
   0x40105301..0x40105307, each with a 16-byte {a,b,c,d} arg, result in a:
     INIT 0x40105301 -> a=0      AUTH 0x40105302 -> a=0
     READ 0x40105303 -> {b=lsn, c=blocks, d=buf}: pread blocks*2048 from
                          the disc image into buf; a=0 (a>=0 maps to
                          "blocks read" in sacd_dev_input_read64)
     DECRYPT 0x40105304 -> a=0, buffer untouched (fixture is user data)
     UNINIT 0x40105305 -> a=0    DISC 0x40105306 -> a=0 (disc present)
     SACD 0x40105307 -> a=0 (is SACD)

## TWO read paths (the critical detail)

- TOC reads: scarletbook_read_* -> sacd_read_block_raw -> sacd_input_read
  (32-bit) -> plain lseek64(fd, pos*2048) + read() on the /dev/sr0 fd.
  NO ioctl. Serve only the ioctl path and you get "Can't read Master TOC".
- Payload reads: client DISC_READ -> sacd_read_block_raw64 -> read_sacd()
  -> the READ ioctl with a userspace buffer.

Fix: both device paths open the same file, and the ioctl READ preads from
that same file — one source of truth for both paths.

DISC_SIZE = fstat64(dev->fd).st_size / 2048 — the image's file size
controls the reported sector count.

## Fixture

Real Scarlet Book ISO (preferred: genuine SACDMTOC@510, real area TOCs,
real encryption ranges) or tools/fixture_gen.py's synthetic sparse image
(documented field layouts passing scarletbook_read.c's validators).

## Determinism

The shim is stateless (one shared fd behind a mutex; pread is
position-independent and thread-safe). Both daemons receive byte-identical
device responses, so transcript divergence is attributable to the daemons.
DECRYPT is a no-op because the fixture is already user data; on hardware
both daemons issue the identical ioctl, so the player leg covers crypto.

## Client (tools/sacd_client.py)

Wire format (verified byte-identical against real nanopb compiled for ARM
and run under qemu): varint fields, frame = protobuf + one 0x00 tag byte,
result is int64 (negatives = 10-byte two's-complement varints), data =
result * 2048 bytes. Sequence: OPEN, SIZE, READ(1@0), READ(128@0,
the server block cap), READ(1@mid), CLOSE, reconnect, repeat mid read.
Records LSN, requested vs returned counts (the daemon clamps at
encryption ranges), payload SHA-256, raw frame hashes. compare diffs
two manifests.

## Pitfalls (all hit in practice)

1. -ldl on the shim: old guest glibc keeps dlsym in libdl.so.2.
2. -E LANG=C -E LC_ALL=C or the 2009-era guest glibc asserts in
   loadlocale.c when the daemon calls setlocale(LC_ALL, "").
3. BOTH /dev/sr0 and /dev/sacd_read need hooking (different purposes).
4. TOC reads bypass the ioctl entirely (lseek64+read).
5. DISC_SIZE = st_size/2048.
6. qemu -E passes guest env — that's how LD_PRELOAD reaches the daemon.
7. The status line prints even redirected; the sleep loop runs forever —
   the runner kills the daemon after capture.
8. system() interposition must cover mknod/insmod/rmmod/"rm -rf" (return
   0 unconditionally is safe in the rig).

## Scope

The rig proves protocol-behavior equivalence above the ioctl boundary.
It does not prove kernel-module crypto, the player's loader/libc, or real
module installation — that is the on-player baseline/replay (issue #6).
