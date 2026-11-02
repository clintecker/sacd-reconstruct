# SACD AutoScript ARM build reproduction

The reference is the 350,830-byte `sacd_extract_160` with SHA-256
`0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45`.
The two public AutoScript archives I checked contain that same executable.

## Use the three rebuilt objects

`objects/bpabi.o`, `objects/_divdi3.o` and `objects/_udivdi3.o` contain the four original division routines, rebuilt from public GNU GCC source. Add these three objects as explicit inputs to the ARM link before its runtime archives. Remove any explicit duplicate definitions. Keep the driver's usual libraries for the 32-bit division routines, unwinding and libc. Inspect the resulting link map to confirm which members and shared libraries were selected.

At the original addresses, all 2,372 bytes from `0x30fc4` through `0x31907` compare equal, including the 36 call relocations. This is the SHA-256 of the complete linked interval.

```text
6ac9155b4508e226fea1157d58859ddaace82a9e7ee20064cc2423b34cbb077f
```

| Symbol | Original address | Bytes |
|---|---:|---:|
| `__gnu_uldivmod_helper` | 0x30fc4 | 60 |
| `__gnu_ldivmod_helper` | 0x31000 | 60 |
| `__divdi3` | 0x3103c | 1180 |
| `__udivdi3` | 0x314d8 | 1072 |

The objects are ARM EABI relocatables with hidden function definitions and compact unwind index entries. The binary match covers linked machine code. DWARF paths and other object-file metadata can differ from the vendor build.

## Verify a build

```sh
# Compare a real GNU ld link of the supplied objects to the original functions.
uv run check_link.py ./sacd_extract_160 --ld /path/to/arm-linux-gnueabi-ld

# Exercise each ELF independently against the same mathematical oracle.
uv run verify_sacd_div.py ./sacd_extract_160 ./rebuilt.elf
```

The second command accepts unstripped ARM32 ET_EXEC files whose division routines and callees are present in the image. It resolves each function by symbol name, handles signed division with truncation toward zero, verifies r4–r11 and SP, and checks the remainder write and adjacent guard bytes. It runs 9,246 deterministic calls per image. Division by zero and signed minimum divided by −1 are excluded. The harness uses Unicorn without running the listener, loading a module or accessing a device.

## Rebuild the objects from source

Use a configured GNU GCC **4.4.1** source/build pair, target `armv6z-mediatek-linux-gnueabi`, with the C compiler built via `make all-gcc`. The tested compiler used `--with-arch=armv6z --with-float=soft --with-abi=aapcs-linux --enable-languages=c --disable-multilib --without-headers`. The target assembler and linker used for the shipped objects and address comparisons both report GNU Binutils **2.19.1**. They were built from `binutils-2.19.1a.tar.bz2`. The assembler and linker are ordinary host executables targeting ARM.

```sh
# All paths are local. The compiler build supplies the target-specific headers.
sh build_objects.sh /src/gcc-4.4.1 /build/gcc-4.4.1 /path/to/arm-as ./my-objects
uv run check_link.py ./sacd_extract_160 --objects ./my-objects --ld /path/to/arm-ld
```

The code-generation settings include `-O2 -marm -march=armv6z -mfloat-abi=soft -mabi=aapcs-linux -fPIC -fexceptions -fnon-call-exceptions -fvisibility=hidden`. The application can use its own non-PIC settings. In this test, an explicit `-mtune=arm1136jf-s` changed both division implementations. Default tuning, `arm1176jzf-s` and `mpcore` produced identical function bytes. The comparison does not distinguish those three choices.

The hash of GNU 4.4.1's `gcc/libgcc2.c` is `39326ef9ede351219245d0e1a573f4b0d1a86a3db71fb1d49f1b623d2159e118`. Both 4.4.1 and 4.4.2 declare the division functions on lines 1079 and 1138. The only intermediate commit to this file added two Windows prototypes after line 2049. Sony's BDP-S280-family GCC package contained the same 62,246 regular-file paths and contents as GNU's full 4.4.1 release. These observations establish a sufficient compiler source for the tested code. The original SDK binaries and configure command remain unidentified.

## Verify the startup code

```sh
# Supply extracted source directories, including the separate glibc ports tree.
uv run check_startup.py ./sacd_extract_160 \
  --gcc-src /src/gcc-4.4.1 --gcc-build /build/gcc-4.4.1 \
  --glibc /src/glibc-2.9 --ports /src/glibc-ports-2.9 \
  --as /path/to/arm-as --ld /path/to/arm-ld
```

| Linked interval | Source and condition | Bytes compared |
|---|---|---:|
| 0xc818–0xc84f | glibc-ports `sysdeps/arm/elf/start.S` | 56 |
| 0xc850–0xc873 | ARM `initfini.c` wrapper around glibc `sysdeps/generic/initfini.c`, `call_gmon_start` | 36 |
| 0xc874–0xc8bf | GCC `crtstuff.c`, `__do_global_dtors_aux` and `frame_dummy` | 76 |
| 0x31908–0x31973 | glibc `csu/elf-init.c` compiled with `LIBC_NONSHARED` and PIC, `__libc_csu_fini` and `__libc_csu_init` | 108 |

All 276 bytes match. This test deliberately supplies the reference PLT addresses, GOT base, gmon slot and section addresses to the linker. It explicitly selects the glibc-aware `USE_PT_GNU_EH_FRAME` branch in `crtstuff.c` because the test compiler was built without target headers. The script isolates the startup functions. Obtain complete startup objects from a matching SDK or a full glibc build for an actual link.

Sony's glibc archive contains 14 changed regular files relative to GNU glibc 2.9, patch files for `arm_setjmp_fix`, `cross_hacks`, `libgcc_eh`, `localedef_segfault` and `nptl_lowlevellock`, and rejected hunks. Its `ports` entry is a symlink to `../glibc-ports`. The reference ELF's own glibc CSU compile directory ends in `glibc-2.9/csu`. Sony lists glibc **2.12.2** for the BDP-BX510's shipping firmware. The audit of Sony's older source package does not establish which patches were applied in the daemon author's development sysroot.

## Inspect the application probes

`call_probes.c` contains reduced C functions for the close/cleanup branch and both pthread call shapes. Compile with the tested xgcc and `-O0 -marm -march=armv6z -mfloat-abi=soft -fno-pic -S`. The reference takes the client-thread ID address in r2 at `0xd080`. The r3 ID temporary at `0xe370` belongs to the call that starts the listener with a null fourth argument. In the cleanup probe, the branch immediately follows `bl close`, and a separate incoming edge gets a NOP. These are code-generation witnesses. They do not determine the author's C spelling. The exact source of the `install_modules` formatting-call instruction order remains open.

## Primary sources

- [Sony BDP-S280-family GCC and glibc archives](https://oss.sony.net/Products/Linux/Video/BDP-S280.html)
- [Sony BDP-S5100 and BX510 firmware source package](https://oss.sony.net/Products/Linux/Video/BDP-S1100.html)
- [GNU GCC 4.4.1 full release](https://ftp.gnu.org/gnu/gcc/gcc-4.4.1/gcc-4.4.1.tar.bz2)
- [GNU GCC 4.4.2 release diff](https://ftp.gnu.org/gnu/gcc/gcc-4.4.2/gcc-core-4.4.1-4.4.2.diff.gz)
- [GNU glibc 2.9](https://ftp.gnu.org/gnu/glibc/glibc-2.9.tar.bz2) and [glibc-ports 2.9](https://ftp.gnu.org/gnu/glibc/glibc-ports-2.9.tar.bz2)
- [GNU Binutils 2.19.1a](https://ftp.gnu.org/gnu/binutils/binutils-2.19.1a.tar.bz2)
- [Base PS3 server](https://github.com/sacd-ripper/sacd-ripper/blob/de008ff1a20350acf2f8caed8f6609e3c40addb5/src/server.c) and [wire schema](https://github.com/sacd-ripper/sacd-ripper/blob/de008ff1a20350acf2f8caed8f6609e3c40addb5/libs/libsacd/sacd_ripper.proto)
- [Community distribution of the reference binary](https://www.stereonet.com/forums/topic/109106-sacd-ripping-without-a-ps3/page/2/)
- [Independent player implementation](https://github.com/saramibreak/SacdImageCreator) and [related AutoScript ELF](https://github.com/Lunaqua/lg-bp630/blob/0c52bc24c635e1172a657eae075c7238e545d2a5/autoscript/sacd_extract)
