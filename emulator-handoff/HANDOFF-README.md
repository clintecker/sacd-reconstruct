# Sony S5100/BX510 hardware emulation — project handoff

State recorded November 2, 2026, Chicago time. The physical unit is a **Sony BDP-S5100, firmware M15.R.0257**, at the operator-reported LAN address 10.20.1.236. QEMU’s machine name remains `sony-bx510`. This report separates observed emulator behavior, physical observations and implementation assumptions.

## Outcome and scope

We implemented a new full-system ARM machine in QEMU 9.2.4. It boots the unmodified Sony Linux 2.6.35 kernel, reads a reconstructed NAND image through the MediaTek controller model, mounts Sony’s real SquashFS and runs Sony’s shell as PID 1. Sony’s dynamic loader and libraries can execute both the original SACD daemon and the reconstructed release.

A second boot path runs the retail U-Boot and reaches the original kernel. Normal appliance startup stops because Linux rejects the packaged initial ramdisk. A controlled replacement ramdisk executes successfully through the same handoff. The actual preloader’s preparation of the initial filesystem remains unresolved.

The optical controller, media authentication, Ethernet packet DMA and HDMI output are still missing from the machine model. No successful emulated SACD session, Sony menu or physical replacement-daemon acceptance is claimed. The recent hardware screen experiment is paused at the user's request. Its findings are retained as hardware evidence.

## Obtain the artifacts

This handoff includes `emulator/`, the complete current source kit with test scripts, ARM diagnostic binaries and evidence. Sony firmware is downloaded separately by its preparer.

- [Previously built Linux x86-64 executable, complete upstream source and kit](https://chatgpt.com/library?file_id=libfile_1d222295545c81918b53385f8530e34e&account_id=personal)
- [Source kit](https://chatgpt.com/library?file_id=libfile_23232656c2408191809ca77b53f5f8df&account_id=personal)
- [Home diagnostics](https://chatgpt.com/library?file_id=libfile_1a2b1314fadc81919e241c08b40a0052&account_id=personal)

These deliverables were saved as archives. The full-system QEMU changes have not been pushed to `clintecker/sacd-reconstruct` or upstream QEMU. The separate reconstruction agent owns that repository’s application reconstruction and qemu-user rig. A future implementer should import `emulator/` into their chosen repository and preserve the provenance hashes.

## Reproduce on Linux

The verified host was Linux x86-64. The provided host executable requires glibc 2.38 or newer, GLib, zlib and libfdt. A native macOS build has not been validated. On a Mac, using an x86-64 Linux VM is the closest reproduction of the verified environment; Apple Silicon would additionally emulate the host architecture. Building the source directly on another supported host is a separate validation task.

From this handoff’s `emulator` directory, install build dependencies and build:

```sh
sudo apt-get install build-essential python3-venv ninja-build pkg-config \
  libglib2.0-dev libpixman-1-dev libfdt-dev zlib1g-dev curl patch xz-utils
JOBS=4 sh build.sh
python3 firmware.py images
```

`build.sh` downloads and verifies QEMU 9.2.4, applies the integration patch, copies the board sources and builds `arm-softmmu`. It uses a dedicated work tree and performs no system installation. Python 3.10 or newer is the documented build prerequisite. For the binary bundle, use `bin/qemu-system-arm` in place of `work/build/qemu-system-arm` below.

Run these individually:

```sh
python3 smoke.py --qemu work/build/qemu-system-arm --images images shell
python3 smoke.py --qemu work/build/qemu-system-arm --images images handoff
python3 smoke.py --qemu work/build/qemu-system-arm --images images fastboot
python3 ramdisk_control.py --qemu work/build/qemu-system-arm --images images
```

Expected results are `PASS shell`, `PASS handoff`, `PASS fastboot` and a control-ramdisk success. The handoff test intentionally ends at the kernel build banner. It does not certify normal userspace startup.

For an interactive diagnostic shell:

```sh
python3 run.py --qemu work/build/qemu-system-arm --images images shell
```

At Sony’s shell prompt:

```sh
echo $$
/bin/uname -r
/usr/bin/md5sum /lib/modules/2.6.35/BDP/bdpdrv.ko
```

Expected PID is 1, kernel is 2.6.35 and module MD5 is `fd3542eeeb6881bcd715fc1b83519ba3`. Terminate QEMU from another terminal with SIGTERM when finished. All launch modes use a transient NAND write overlay.

To see the actual normal-startup blocker:

```sh
python3 run.py --qemu work/build/qemu-system-arm --images images uboot
```

This prints `Initramfs unpacking failed: junk in compressed archive`, then a root-device panic. This is a recorded expected failure at the present implementation stage.

Offline extraction accepts local verified inputs:

```sh
python3 firmware.py images --zip UPDATA_M15R0257.zip --keys keys.ukf
```

Choose a new output directory. For offline QEMU source preparation, place the pinned `qemu-9.2.4.tar.xz` in the build work directory first. The binary bundle includes it under `upstream/` and the build script reuses that copy.

## Firmware provenance and synthetic installation

[Official Sony update](https://www.sony.com/electronics/support/downloads/00015891) applies to both BDP-S5100 and BDP-BX510. [Sony’s model-family source distribution](https://oss.sony.net/Products/Linux/Video/BDP-S1100.html) provides Linux, U-Boot, DirectFB and other components. Their board headers identify the MT8560 family. The framebuffer driver’s `mt8530` name is a legacy software identifier and is not sufficient to identify the physical SoC independently.

The preparer decodes the outer update using the public unixtract substitution table pinned at commit `aadba866ea47ed9506ffe130a8558bb9147ee968`. It applies the Sony PIT/BIT update records to a 256 MiB image, fills unspecified NAND bytes with 0xff and synthesizes a no-bad-block installed/adaptive partition table at 0x200000. The update contains no records for the factory MAC/key partitions. This image is derived from the updater, not a raw dump of the user's flash.

The U-Boot run starts from a reconstructed preloader handoff, not from the mask ROM. QEMU stages a 40-byte `ARGS_TO_UBOOT` at 0x400, U-Boot at 0x04f00000, the uImage header at 0x0d9fffc0 and the packaged initial ramdisk at 0x1c000000. RAM is modeled as two 256 MiB channels, with a channel-A alias at 0xc0000000. These inputs require comparison against the actual boot environment.

The uImage declares load and entry 0x0da00000 and has valid CRCs. Its banner identifies Linux 2.6.35, GCC 4.5.1, built September 20, 2018. U-Boot identifies itself as 2009.08 built October 15, 2012.

| Input or output | SHA-256 |
|---|---|
| QEMU 9.2.4 source tarball | `f3cc1c4eabfdb288218ac3e33763dbe9e276d8bc890b867a2335d58de2ddd39a` |
| Sony update ZIP | `7209013baa51d9d011c928c76f96c7dec883c271b99097b91a376b930add151c` |
| unixtract decode table | `9371ed11ffed8ea82fbb9f612036ba1f09e31c6e851da2ea56721013a34b48af` |
| Original uImage | `10bb0fba4eb26c5b1ebf798f4d4669dc8b5899d520be294d333c318a360be2d7` |
| Original U-Boot stage | `40f19951773da0b180c4719c6d12dd2cea222b29f777f6c69d559fb85d9ac03b` |
| Original Fastlogo stage | `2e84f931415dde0c9e85fc2c9f11c1cde64af8097acbbc117a3d2bff259f66af` |
| Packaged initrd_1 bytes | `737ebf52971947ad5742f2e7356d20546ae35f51ac0d9deecd6393a4a5503dc5` |
| Synthetic installed NAND | `592b2920c2044f90ba91d85f8e58b8d52282355dd25c6ed6c0c88c0c548ceb30` |
| Retail bdpdrv.ko | `6604f6cd6c204c3399ac047f389f47162b06a3f6576159f21b4e8aaf3a72cf54` |

## Implementation map

| File | Purpose |
|---|---|
| `sony-bx510.c` | ARM1176 machine, 512 MiB RAM, alias, MediaTek MMIO, UART, BIM interrupts/timer, semaphore, STAR identification/MDIO and boot setup |
| `mt8560-nfi.c`, `.h` | MediaTek NAND controller, DMA, interrupt and metadata paths connected to QEMU’s NAND die |
| `qemu-integration.patch` | Registers the machine in Kconfig/Meson/default configuration and makes the existing L2 cache ID configurable |
| `firmware.py` | Hash-checked update extraction, synthetic installation, manifest and handoff generation |
| `run.py`, `smoke.py` | Launch and observe the machine through UART |
| `ramdisk_control.py` | Builds a small ARM init executable inside a known gzip/cpio filesystem of the stock handoff length |
| `verify_daemons.py` | Stages the pinned two daemon ELFs into temporary virtual NAND and compares stdout from the real guest |
| `optical/` | Boundary documentation, strict manifest/ISO verifier and ARM ioctl observer |
| `screen/` | Custom DirectFB pixel probe, build sources, USB launcher and restore/refresh tooling |
| `evidence/` | Boot and diagnostic transcripts, partition manifest and first physical screen report |

The modeled NAND uses a Samsung-compatible 2 KiB-page die and a simplified error-free ECC/OOB path. Chip identity is a compatibility choice. BCH errors, factory bad blocks and wear are unmodeled. STAR MAC identification and PHY access let the kernel probe, but no packets are transferred. UART RX and drained-TX events are modeled; a missing TX event discovered during a long transfer was fixed and verified by transferring complete guest stdout.

The Fastlogo replay is a separate single-CPU experiment. It runs the update’s auxiliary ARM program at address zero and prints optical front-end initialization messages. It ends with a zero NAND page size in shared state and a supervisor call. This does not establish the real multicore startup sequence. The update directory labels preloader at boot-partition offset 0x200, AVM at 0x8400, Fastlogo at 0x17400 and U-Boot at 0x2a000.

## Tests already completed

The kernel mounted the stock root on `/dev/mtdblock17` after enumerating 25 MTD partitions. A blank-chip control did not produce the same installed partition setup. The shell exchanged characters in both directions and read the multi-megabyte bdpdrv.ko with the expected digest.

The ramdisk positive control holds U-Boot, kernel, NAND, argument structure, RAM address and initial-ramdisk length fixed. A synthetic gzip/cpio image padded to 532,976 bytes executes `/init` and prints `BX510_RAMDISK_CONTROL_EXECUTED`. This confirms that the modeled handoff can deliver a working initial filesystem. It does not identify the transformation or state that Sony’s preloader supplies for the packaged bytes. The present evidence does not establish a per-device key requirement.

The original daemon and release candidate were executed inside the diagnostic guest with eager binding against Sony’s shipped libraries:

```sh
python3 verify_daemons.py --qemu work/build/qemu-system-arm --images images \
  --reference /path/to/sacd-reconstruct/original/sacd_extract_160 \
  --release /path/to/sacd-reconstruct/reconstruct/release/sacd_extract_160_release
```

The expected ELF SHA-256 values are `0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45` and `e91720fbbbd592505bde6630843b0495ff82a93e40c0e427aaa70a081ff9ae22`. Both `--help` runs exited 0 and produced 1,059 identical stdout bytes with SHA-256 `139e40a3f95c22b1d3d4d6d172739be93d0618c39f4b8c06ef6eae9210664e18`. This exercises loader and libc compatibility for that invocation. The original module was not thereby proven to initialize or read a disc in QEMU.

The distributed Linux executable and preparer were also unpacked into a fresh directory and used to repeat shell, control-ramdisk and daemon tests.

## Coordination with the other agent

The other agent reports qemu-user plus an LD_PRELOAD shim that substitutes system(), device open64() and module ioctls, using genuine Firebird ISO data. Its new shim/architecture files were not yet available on the public main branch when checked. The architecture and run results supplied by the user are retained as that agent’s report. I independently verified the daemon source and original embedded module’s optical boundary.

There are two read paths. TOC reads use seek/read on `/dev/sr0`. Payload requests use `/dev/sacd_read`. The original module’s READ requests 2,064 bytes per sector from `_IDECLI_OddRead`. DECRYPT processes those frames through CPSA and packs 2,048-byte payloads, taking output at offset 12 per frame. Thus 128 raw frames occupy 0x40800 bytes; logical payload occupies 0x40000. A decrypted ISO provides an application oracle, while the original raw metadata and authentication behavior need additional evidence.

The original module SHA-256 is `b3d7a383e45d3bbe1a987a4a2e15ab7a68dd55e88d0319f7a0fd2e9cf0246dfa`. The archive includes offsets and details in `optical/README.md`. The daemon ignores DECRYPT’s return code when deciding its wire reply, so successful payload comparison alone does not prove real crypto succeeded.

A concrete defect was demonstrated in the pinned client's comparison command. Changing an OPEN result and its recorded wire hash could still yield IDENTICAL because it checked reads and size. `optical/media_check.py` validates the complete positive nine-exchange baseline, ordered requests, response results/types/lengths, hashes, reconnect and optional exact ISO bytes. Negative controls for altered requests, missing close, changed response hash, changed ISO bytes and failed OPEN were rejected. `firebird.py` reuses the other team's pinned client, with a wrapper that handles its successful-dict exit-code issue. These are optional diagnostics alongside the full-system project.

## Physical observations through the latest conversation

The actual device matches the firmware family used for emulation. The user has only one working FAT32 ripping USB, with a verified original ELF backup and a second backup on the Mac. The screen wrapper staged the original daemon and launched a separate helper. No reconstructed release ELF was deployed by this work.

The screen probe loaded DirectFB 1.2.7 and queried a framebuffer named mt8530, reporting 1920×1080 visible, 1920×2160 virtual, 32 bpp, stride 7,680 and memory size 16 MiB. These are reported geometries, not a map of the currently scanned-out OSD surface. The driver chooses memory pools using vendor conventions, including mmap length. Direct generic framebuffer writes based only on those numbers were not attempted.

No bars appeared with Home visible or after standby. In the first reported logs, the last graphics message was Fusion SHM initialization. One run timed out with status 142, the probe’s SIGALRM. The older build did not bracket every call, so it cannot prove the exact blocked call. A newer build adds BEGIN/END markers, per-call timeouts, wrapper uptime/PID/parent information, and selected boot/Fusion observations. That newer instrumentation has been guest-tested; a new physical log has not yet been supplied.

The user then tested port 2002 with macOS nc. TCP connected while Home was visible after 30 seconds, and also after OFF stopped blinking, continuing to accept connections for more than ten seconds. This proves TCP reachability in both states. It does not establish which daemon instance accepted, successful disc open, or that the same process survived the transition. The AutoScript requests `-S &` before the tray command; the exact firmware dispatch timing and reason for two logged PIDs remain unproven.

With Firebird confirmed in the tray, the Python baseline connected in standby but received zero reply bytes to its first DISC_OPEN within the timeout. SIZE and sector reads were not reached. The user’s usual client is custom software around sacd_extract and is itself flaky. Lossless Extract was incorrectly assumed earlier and is not being used. A `send-this.zip` was attached after the failure; its contents have not been analyzed in this handoff. The user now wants to focus on hardware emulation, so further physical screen experiments are deferred.

## Recommended continuation of the emulation

1. Reproduce shell, U-Boot handoff and the control ramdisk from the supplied source. Preserve these as the initial regression checks.
2. Investigate the real preloader/initial-root handoff. Most useful physical evidence is `/proc/cmdline`, `/proc/mtd`, `/proc/mounts` and an actual initial-root capture or cold-boot trace. Model/firmware/IP are already known. The screen runner can collect the read-only boot snapshot, but it has not yet been returned. Continue static analysis of update boot metadata and vendor loader code in parallel.
3. Inspect actual bdpdrv.ko optical and framebuffer routines and the GPL SATA/STAR source. Use unimplemented-MMIO logging and bounded single-operation tests. Define raw-frame and logical-sector fixtures from the same disc. Avoid treating a no-op decryption shim as a hardware implementation.
4. Add optical-controller behavior under the real vendor driver and embedded module. First success should be one known TOC read, then one raw audio frame, then the matching logical payload. Keep track of command, DMA, interrupt and buffer semantics.
5. Implement STAR packet DMA or use a guest-local protocol client to test the server before external networking is ready. The current run script specifies `-nic none` because the board has no packet backend.
6. HDMI/OSD emulation and normal Sony UI startup follow their actual driver requirements. The physical framebuffer measurements and shipped DirectFB sources supply useful targets, but the current QEMU machine has no display pipeline.

The user has already authorized this emulation work. Hardware access from this environment is not established. All LAN tests in the conversation were run by the user on their Mac. No firmware update or raw physical flash dump was performed.

## Additional references

The three Scarlet Book PDFs supplied by the user are useful disc-format references. Part 1 describes the 2,064-byte data frame, with 12 leading bytes, 2,048 main bytes and four trailing check bytes. Part 2 documents master/area TOCs and audio-sector structures. Part 3-General gives protection contracts and references separate Disc, Player and LSI specifications. They do not specify the MT8560 register interface. They were inspected but are not redistributed in these archives. [Collection](https://archive.org/details/super-audio-cd-system-description)

SacdImageCreator independently documents raw and logical disc outputs and lists S5100/BX510 support. Existing matching `.raw` and `.iso` files could supply paired sectors without another full rip. [Project](https://github.com/saramibreak/SacdImageCreator)

The emulator implementation and support sources are GPL-2.0-or-later. The binary QEMU bundle includes the exact upstream source archive, modifications and build recipe. Firmware and source downloads retain their respective notices.
