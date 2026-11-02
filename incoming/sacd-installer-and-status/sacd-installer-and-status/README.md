# SACD installer reproduction and BX510 status tests

Tested against commit `694f27d69e1eae8a12bb5673d06bb62636ab9f8d` of `clintecker/sacd-reconstruct`. The reference ELF SHA-256 is `0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45`. The checked-in `_fsf` ELF SHA-256 is `27526fc27be5ba28ea282ee1c2ac7c11fefd1f48bf858c46cc9f0300f7b3c970`.

## Run the six headless status cases

The included ARM DSO works with the default ARM multilib of the CodeSourcery 2009q3-67 Linux sysroot. Run these commands on a Linux host with qemu-arm or qemu-arm-static. The Python checks use PEP 723 dependency metadata with uv.

```sh
# Set CSROOT to .../arm-2009q3/arm-none-linux-gnueabi/libc.
uv run test_status.py --qemu qemu-arm --sysroot "$CSROOT" "$ORIGINAL" "$CANDIDATE"
```

Each case launches a fresh process. The guest preload passes control through the real libc startup to a test entry that calls the executable's own `init` and `server_loop`. It sets the client flag, supplies the two status ioctl replies, and ends the loop at its first sleep. The actual guest `safe_fwprintf`, locks, `vfwprintf` and `fflush` execute. The runner compares complete stdout bytes, including the initial carriage return, fourteen trailing spaces and absence of a newline. It requires the expected ioctl counts and one loop iteration. The test bypasses module installation and does not start a network listener. The larger TCP/device replay belongs to issue #5.

| Guest ELF | Result |
|---|---|
| Reference `sacd_extract_160` | 6/6 |
| `reconstruct/sacd_extract_160_fsf` at the commit above | 0/6, all six exit successfully with the incorrect client string |
| Experimental relink using `L"connected"` and `L"none"` | 6/6 |

`status_probe.c` and `build_status_shim.sh` reproduce the included test DSO. Its `LD_PRELOAD` is passed to the guest with QEMU's `-E` option.

## Verify the installer

```sh
# Compare the packaged object at the original symbol, PLT and section addresses.
uv run check_installer.py "$ORIGINAL" --ld "$ARM_LD"

# Reproduce it with a stock GNU GCC 4.4.1 ARM compiler and GNU as 2.19.1.
# For an uninstalled gcc build add -B/path/to/build/gcc/ as a final argument.
sh build_installer.sh "$ARM_CC" "$ARM_AS" "$CSROOT" "$REPO/reconstruct" ./local-installer.o
uv run check_installer.py "$ORIGINAL" --object ./local-installer.o --ld "$ARM_LD"
```

| Linked region | Size | Result |
|---|---:|---|
| `install_modules` at 0x2f970 | 464 | Exact including calls and literal pool |
| `remove_modules` at 0x2fb40 | 132 | Exact including calls and literal pool |
| Installer string data at 0x36234 | 236 | Exact |

`install_module.c` is a complete buildable C witness. `installer.patch` applies the same changes to `reconstruct/tool/install.c` at the pinned commit. Check it against local changes before applying. The witness uses a 26-byte static buffer, a constant `strcpy`, a `size_t` byte count with a signed `write` result comparison, ordinary nested branches with one result return, and `__func__` for the logging names. It preserves the reference file-creation call and error-path behavior.

The choice of string function is underdetermined. With the rest of this file held fixed, all three of these C statements reproduced the entire table above:

```c
strcpy(mod_file, "/tmp/");
strncpy(mod_file, "/tmp/", 6);
sprintf(mod_file, "/tmp/");
```

Changing the original explicit `memcpy` to `strcpy` in the full TU makes the compiler take the string address through r3 for the call to memcpy. The later insmod `sprintf` already takes the format through r3 in C. Stock GCC 4.4.1's C++ frontend with the same flags and target headers instead emits direct argument loads for these two calls. With `extern "C"` function declarations the C++ object retains the unmangled function names but emits `_ZL8mod_file` and mangled function-local `__func__` objects. The original ELF records `install_module.c`, a local `mod_file` and `__func__.3534` / `__func__.3574`. The seven `__PRETTY_FUNCTION__.*` objects belong to `buffer_pool.c` and `dst_decoder.c`. The binary does not contain an installer compilation unit with a DWARF language tag.

## Reproduce the experimental link

`trial_link.py` uses the source list at the pinned repository commit and requires an empty output directory. It builds all 45 application C objects, uses the installer witness and corrects the two client status strings in staged inputs. The four affected source files receive `#line 1 "/root/sacd-ripper/libs/..."` followed by their original bytes. `-iquote` supplies their original physical include directories. No host directory under /root is necessary.

```sh
# SDK is the extracted arm-2009q3 directory, one level above arm-none-linux-gnueabi.
python3 trial_link.py --repo "$REPO" --gcc-src "$GCC441_SOURCE" \
  --gcc-build "$GCC441_BUILD" --glibc-src "$GLIBC29_SOURCE" --sdk "$SDK" \
  --as "$ARM_AS" --ld "$ARM_LD" --out ./trial

uv run check_link_interface.py "$ORIGINAL" ./trial/sacd_extract_160_trial
uv run test_status.py --qemu qemu-arm --sysroot "$CSROOT" "$ORIGINAL" ./trial/sacd_extract_160_trial
uv run "$REPO/incoming/sacd-mtk-forensics/verify_sacd_div.py" ./trial/sacd_extract_160_trial
qemu-arm -cpu arm1176 -L "$CSROOT" -E LD_BIND_NOW=1 ./trial/sacd_extract_160_trial --help
```

The application, GCC startup objects, static arithmetic routines and glibc 2.9 `elf-init.c`, `stat64.c` and `fstat64.c` are compiled from source. The remaining glibc startup objects, headers and shared-library link inputs come from the pinned CodeSourcery sysroot. The recipe uses `--export-dynamic`, hides the private GNU arithmetic archive with `--exclude-libs libgcc.a`, and supplies the pinned shared provider after the static inputs with `--as-needed`. The link emits `trial.map`.

| Comparison with the original | Result for this trial |
|---|---|
| Direct DSOs, with order | libpthread.so.0, libgcc_s.so.1, libc.so.6 |
| Defined externally visible dynamic symbol names | 270 in each, equal sets |
| Undefined dynamic symbols, including binding, type, required DSO and version where present | 131 in each, equal sets |
| ARM unwind index | Five matching function/descriptor pairs |
| Imported ARM personalities | Only __aeabi_unwind_cpp_pr0@GCC_3.5 |
| QEMU eager binding and --help | Exit 0 |
| Six status cases | 6/6 |
| Integer-division oracle | 9,246/9,246 |

The experimental link has no on-player result. One build with the CodeSourcery `crtbegin.o` still imported `pr1` via its `frame_dummy` entry. Source-built GNU `crtbegin.o` removed that import. The CS copies of the three nonshared glibc wrappers above contributed four further unwind entries. Rebuilding those wrappers yielded the original five. Program layout, debug metadata and other parts of an ELF can still differ when all these checks pass.

## Provenance

The default CS shared provider in the tested archive has SONAME `libgcc_s.so.1`, ARM attributes v5TE, and exports `__aeabi_unwind_cpp_pr0@@GCC_3.5`. The included libc identifies its release as GNU libc 2.10.1. The CS DSO serves as a pinned link-time ABI input. The original MTK DSO's byte identity remains unestablished. On the BX510, leave resolution to the player's own loader and libraries and record their build IDs or hashes if available.

| Input | SHA-256 |
|---|---|
| arm-2009q3-67-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2 | b482fa8ad0f8147a4b963f4b24f5733f733e5bfe476826ee504f0fac538e8da0 |
| arm-2009q3/arm-none-linux-gnueabi/libc/lib/libgcc_s.so.1 | 5068e1ea0c56591305d3c605d9fbd3e900ae8d134d13bc32a65e3fe1ddbec6d4 |

- [GNU GCC 4.4.1 releases](https://ftp.gnu.org/gnu/gcc/gcc-4.4.1/)
- [GNU binutils 2.19.1a source](https://ftp.gnu.org/gnu/binutils/binutils-2.19.1a.tar.bz2)
- [Sony GCC 4.4.1 and glibc 2.9 sources](https://oss.sony.net/Products/Linux/Video/BDP-S280.html)
- [CodeSourcery 2009q3-67 archive copy used](https://mirrors.lzu.edu.cn/buildroot/arm-2009q3-67-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2)
- [GCC preprocessor line control](https://gcc.gnu.org/onlinedocs/cpp/Line-Control.html)
