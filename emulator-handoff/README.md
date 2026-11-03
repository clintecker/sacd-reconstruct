# Sony BDP-BX510 full-system QEMU bring-up

This kit adds a `sony-bx510` machine to QEMU 9.2.4. It executes the retail ARM firmware from Sony’s US BDP-BX510/S5100 M15.R.0257 update. The working path mounts Sony’s SquashFS from an emulated NAND controller and runs the original Sony shell. The automatic U-Boot path currently stops during early userspace boot. The release does not yet reproduce the entire player.

## Build and run

For an actual player, start with [the at-home test card](AT-HOME.md). It includes the original-USB Firebird baseline and a reversible screen test. The [optical tools](optical/README.md) verify rig and hardware manifests, compare ISO payloads, and capture a two-frame sample with the real module on a separately instrumented run. The [screen probe](screen/README.md) draws custom pixels on Sony's DirectFB window surface. These additions are host and guest diagnostics. The QEMU machine still lacks emulated optical-controller and HDMI output.

The Linux x86-64 bundle includes a tested `bin/qemu-system-arm` and the exact QEMU source archive in `upstream/`. On an x86-64 Linux host with glibc 2.38 or newer, GLib, zlib and libfdt (`libfdt1` on Ubuntu), try the included binary first. From the unpacked directory run

```sh
python3 firmware.py images
python3 smoke.py --qemu bin/qemu-system-arm --images images shell
python3 run.py --qemu bin/qemu-system-arm --images images shell
```

The smaller source archive contains the same board implementation and tests. To build it, or to rebuild the Linux bundle, use the following procedure.

The tested host was x86-64 Linux. You need a C/C++ toolchain, make, Python 3.10 or newer with venv, Ninja, pkg-config, GLib and Pixman development headers, libfdt, zlib, curl, tar and patch. On Debian or Ubuntu the main development packages are `build-essential python3-venv ninja-build pkg-config libglib2.0-dev libpixman-1-dev libfdt-dev zlib1g-dev`. The QEMU source includes its pinned Meson wheel. A native macOS build has not been validated.

From this directory, run

```sh
./build.sh
python3 firmware.py images
python3 smoke.py --qemu work/build/qemu-system-arm --images images shell
python3 run.py --qemu work/build/qemu-system-arm --images images shell
```

At the shell, `echo $$` prints `1`. Try `/bin/uname -r` and `/usr/bin/md5sum /lib/modules/2.6.35/BDP/bdpdrv.ko`. The smoke test sends commands over the emulated UART, checks that the guest executes them and compares the module digest to the file independently extracted from Sony’s SquashFS. Stop the emulator from another terminal with SIGTERM if you are in the interactive guest shell.

To observe the retail U-Boot handoff, run

```sh
python3 smoke.py --qemu work/build/qemu-system-arm --images images handoff
python3 run.py --qemu work/build/qemu-system-arm --images images uboot
```

The handoff smoke test ends when U-Boot has loaded the kernel and Linux has printed its build ID. Leave `run.py ... uboot` running to see the later initramfs failure. To replay the update’s auxiliary ARM2 Fastlogo program independently, use `python3 smoke.py --qemu work/build/qemu-system-arm --images images fastboot`. All modes attach the NAND file with a transient write overlay. The firmware preparer refuses to overwrite an existing output directory. For offline extraction pass `--zip UPDATA_M15R0257.zip --keys keys.ukf` to `firmware.py`. For an offline QEMU build place `qemu-9.2.4.tar.xz` in the work directory first.

## What runs

| Component | Verified behavior |
|---|---|
| CPU and memory | ARM1176 under TCG. The machine provides 512 MiB of RAM. Linux recognizes machine ID 2000 as `mt85xx`. The modeled chip ID is the MT8560 revision A value. |
| Bootloader | Retail U-Boot 2009.08, built October 15, 2012. The update’s executable stage is linked at `0x04f00000`. It detects 256 MiB NAND, finds the partition table and launches the retail kernel. |
| Auxiliary processor | In a separate run the retail Fastlogo program executes at address zero and accesses channel A through the `0xc0000000` RAM alias. Its UART prints the front-end work area and the end of `vIdeFastBoot`. |
| Kernel | The unmodified uImage passes its header and data CRCs. Its declared load and entry address are `0x0da00000`. Linux identifies its build as 2.6.35, GCC 4.5.1, September 20, 2018. |
| UART and interrupts | The MediaTek UART transmits and receives guest characters. BIM handles the timer, UART and NAND interrupt paths used in testing. Timer 0 runs on QEMU virtual time. |
| Storage | Sony’s driver probes a 256 MiB large-page Samsung-compatible NAND, finds the installed-format table and registers 25 MTD partitions. The normal root filesystem mounts read-only on `/dev/mtdblock17`. |
| Userspace | In shell mode Linux receives `init=/bin/sh`. Sony’s original shell runs as PID 1 with the firmware’s dynamic loader and libraries. The guest reads the actual vendor driver through NAND. |
| Ethernet | Modeled STAR register identification and basic MDIO/PHY control allow the stock kernel driver to probe. Packet DMA and a network link are outstanding. |

## Where retail startup stops

In `uboot` mode QEMU stages the original U-Boot binary, kernel and packaged `initrd_1` bytes in RAM. A synthesized 40-byte structure at `0x400` follows Sony’s published `ARGS_TO_UBOOT`. U-Boot runs its own boot command and constructs the Linux command line. The model uses two 256 MiB channels and an initrd location of `0x1c000000` so the RAM disk is outside the driver-reserved range. These are reconstruction inputs awaiting comparison with the physical unit.

With these inputs the stock kernel prints `Initramfs unpacking failed: junk in compressed archive` and then cannot mount `/dev/ram0`. The bytes placed there are the verified update record for `initrd_1`. The transformation or additional state supplied before U-Boot on a real player remains unknown. This run starts at U-Boot. The SoC mask-ROM path, normal appliance startup scripts, Sony UI, USB AutoScript, network data transfer and optical/SACD authentication remain outstanding. Cache timing, real NAND BCH and worn-block behavior are also outside the verified model.

There is a positive control for the handoff. The same U-Boot, kernel, NAND, arguments, RAM location and 532,976-byte length successfully boot a small synthetic gzip/cpio ramdisk padded with zeroes to the length of Sony’s record. Its ARM `/init` prints `BX510_RAMDISK_CONTROL_EXECUTED` over the guest UART. This establishes that Linux can receive and execute an initial filesystem through the modeled handoff. The remaining question is which bytes the real player puts there. To reproduce the control run `python3 ramdisk_control.py --qemu work/build/qemu-system-arm --images images`. The synthetic ramdisk exists only for this experiment.

The update itself distinguishes the loader programs. Its `boot_1` directory at offset `0x6400` labels `0x200` as `preloader`, `0x8400` as `AVM`, `0x17400` as `Fastlogo`, and `0x2a000` as `u-boot`. The independent Fastlogo replay ends with a zero NAND page size in its shared input and a supervisor call (`svc #1`). It supplies evidence about the optical front end. The ordering and interactions of these programs on the real SoC remain to be verified.

The normal system partition contains `/usr/local/bin/bdpprog`, `/usr/local/bin/cliprog` and `/lib/modules/2.6.35/BDP/bdpdrv.ko`. The unstripped driver includes `_IDECLI_OddRead`, `_SACDCLI_TestPhy` and `_i4CPSA_Inst_Decrypt`. Some libraries point to the separately mounted `/mnt/rootfs_enc_it`. None of these names alone establishes working hardware decryption.

## Reproduce the daemon comparison

Use the two ELFs from the reconstruction checkout. The test verifies their full SHA-256 digests, puts them in the otherwise update-empty `fe_test_data` partition of a disposable NAND copy, boots the original kernel and runs both with `LD_BIND_NOW=1`. The guest stages both executables under the same basename and redirects stdout to separate files in tmpfs. The test transmits both files through the serial port in hex, decodes them on the host and compares every byte. The normal root and input NAND stay read-only during this test.

```sh
python3 verify_daemons.py --qemu work/build/qemu-system-arm --images images \
  --reference ../sacd-reconstruct/original/sacd_extract_160 \
  --release ../sacd-reconstruct/reconstruct/release/sacd_extract_160_release
```

Use `--qemu bin/qemu-system-arm` with the prebuilt bundle. Both ELFs exited 0 and produced 1,059 identical stdout bytes with SHA-256 `139e40a3f95c22b1d3d4d6d172739be93d0618c39f4b8c06ef6eae9210664e18`. The reference ELF starts with SHA-256 `0fdcefdb` and the tested release starts with `e91720fb`. This exercises the target’s dynamic loader and libraries. The optical driver, port-2002 protocol and physical hardware remain separate tests. The `evidence/` directory holds the serial transcripts and the firmware partition manifest.

## Image provenance

| Artifact | SHA-256 |
|---|---|
| Sony M15.R.0257 ZIP | `7209013baa51d9d011c928c76f96c7dec883c271b99097b91a376b930add151c` |
| Retail uImage | `10bb0fba4eb26c5b1ebf798f4d4669dc8b5899d520be294d333c318a360be2d7` |
| Retail U-Boot executable stage | `40f19951773da0b180c4719c6d12dd2cea222b29f777f6c69d559fb85d9ac03b` |
| Retail ARM2 Fastlogo executable | `2e84f931415dde0c9e85fc2c9f11c1cde64af8097acbbc117a3d2bff259f66af` |
| Packaged initrd_1 record | `737ebf52971947ad5742f2e7356d20546ae35f51ac0d9deecd6393a4a5503dc5` |
| Update-derived 256 MiB NAND | `592b2920c2044f90ba91d85f8e58b8d52282355dd25c6ed6c0c88c0c548ceb30` |
| Retail bdpdrv.ko | `6604f6cd6c204c3399ac047f389f47162b06a3f6576159f21b4e8aaf3a72cf54` |

`firmware.py` verifies the ZIP and decode-table hashes, reads Sony’s host update component and applies its 256 MiB PIT/BIT records at their nominated positions. It fills unspecified bytes with erased NAND data and creates the no-bad-block installed table at the start of `part_info_1`. The updater supplies zero records for both factory key-block and MAC-address partitions. The generated NAND and the modeled memory configuration should be kept distinct from a dump of an individual player. The host update package is public and can be fetched by the preparer. No Sony firmware or Scarlet Book PDF is bundled here. [Sony update](https://www.sony.com/electronics/support/downloads/00015891) · [Board-specific Sony sources](https://oss.sony.net/Products/Linux/Video/BDP-S1100.html) · [unixtract](https://github.com/theubusu/unixtract/tree/aadba866ea47ed9506ffe130a8558bb9147ee968)

## Next evidence

The highest-value comparison is the physical unit’s model/firmware version, `/proc/cmdline`, `/proc/mtd` and `/proc/mounts`. A copy or hash of the initial root as actually handed to Linux, if available, would directly test the current startup blocker. At the optical boundary, a few paired raw-read and post-decrypt sectors from the same addresses would validate the controller path against the unit. Existing full SACD ISOs already establish expected logical sector payloads.

For optical fixtures, Scarlet Book Part 1 §4.2.2 and Figure 4-6 give the 2,064-byte data frame. Its fields are a four-byte ID, two-byte IED, six-byte CPSI, 2,048-byte main payload and four-byte EDC. Part 2 §§2.2.4, 3.1, 3.2 and 5.1 describe the master and area TOCs and audio sectors. Part 3-General v2.1 describes protection-layer contracts and references separate Disc, Player and LSI volumes. These references can be used to validate the disc side while the MediaTek command and register behavior is taken from firmware and traces. [Scarlet Book collection](https://archive.org/details/super-audio-cd-system-description)

The board model and support scripts are provided under GPL-2.0-or-later. QEMU’s upstream source includes its component license notices. The Linux bundle includes the upstream source alongside the modifications and build instructions.
