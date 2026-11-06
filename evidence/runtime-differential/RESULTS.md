# Runtime differential test: original vs reconstruction (qemu-user)

Date: 2026-11-02. Location: build host (`user@192.0.2.10`), qemu-arm-static 1:7.2
(staged Mac-side from deb.debian.org per network policy; installed via dpkg).
Emulated env: `-L ~/arm-2009q3/arm-none-linux-gnueabi/libc` (CodeSourcery 2009q3
glibc-2.9 ARM sysroot — the same sysroot both binaries were linked against).

## Method

Both binaries executed under `qemu-arm-static` with identical argv, env, and
cwd. The binary filename affects output (usage prints argv[0]), so both were run
under the identical name `sacd_extract_160`. stdout, stderr, and exit code
captured per case (`timeout 20`). Scripts: `run2.sh` (reconstruction),
`run3.sh` (original).

## Result: 10/10 cases byte-identical (stdout, stderr, exit code)

(Corrected 2026-11-02: an earlier revision of this report claimed "12/12"
while listing ten cases — see issue #5. The ten cases below are the ones
with committed captures.)

| Case | Args | rc | stdout | stderr | verdict |
|---|---|---|---|---|---|
| help | `--help` | 0 | 1059 B (help text) | 0 B | IDENTICAL |
| badopt | `-Z` | 0 | 1059 B (help text) | 65 B (getopt msg) | IDENTICAL |
| usage | (none) | 0 | 1 B | 160 B | IDENTICAL |
| notsacd | `-i /etc/hostname` | 0 | 1 B | 160 B | IDENTICAL |
| openfail | `-i /dev/null` | 0 | 1 B | 160 B | IDENTICAL |
| servermode | `-S` | 0 | 1 B | 160 B | IDENTICAL |
| combo | `-2 -m -p /dev/null` | 0 | 1 B | 160 B | IDENTICAL |
| outfile | `-i /dev/null /dev/null` | 0 | 1 B | 160 B | IDENTICAL |
| print | `-P` | 0 | 1 B | 160 B | IDENTICAL |
| iopt | `-i /tmp` | 0 | 1 B | 160 B | IDENTICAL |

(A first pass under differing filenames showed only argv[0] strings differing —
expected, not a behavioral difference.)

## What the exercised paths prove

The 160-byte stderr is the full module-install failure chain:

```
mknod: /dev/sacd_read: Permission denied
sh: 1: insmod: not found
[0]: install_modules: mknod/insmod filed
sh: 1: rmmod: not found
[0]: Can not install modules
```

Both binaries byte-identically executed:
- `install_modules()`: embedded .ko blob extraction, `/tmp/` prefix + `tmpnam`
  filename construction, `open64(mod_file, O_WRONLY|O_CREAT|O_TRUNC)` (the
  decoded flag semantics), `write()`, `system("mknod -m0666 /dev/sacd_read
  c 10 201")`, `system("insmod %s minor=201")`
- the LOG subsystem (`log_print` formatting with module/level tags, the
  `mknod/insmod filed` message decoded from disassembly this session)
- `remove_modules()` (`rmmod` + `/dev/sacd_read` cleanup)
- `main()`'s failure branch and exit path
- option parsing incl. the recovered `2mepsSIcCi:t:P?` getopt string and the
  1059-byte help text (byte-identical)

## What this does NOT prove

- The /dev/sacd_read ioctl data path (needs the kernel module loaded —
  impossible in user-mode emulation; on the target the module blob is
  byte-identical to the original by construction)
- The port-2002 nanopb server conversation (gated behind module install;
  would need a real kernel + client fixture)
- pthread server path (`listener_thread`/`server_loop` main loop — never
  reached because install_modules fails first)

## Verdict

All userspace behavior reachable in emulation is byte-identical. Combined
with 377/388 instruction parity (residuals = toolchain-furnished objects and
compiler-build nops/arg-order, all behavior-neutral by inspection), the
reconstruction is a functional drop-in for the paths testable without the
target hardware.
