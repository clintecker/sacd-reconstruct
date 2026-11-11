#!/bin/sh
# bx510_stub_build.sh — build BOTH parts of the split OSAL stub from one
# source on the lab VM, then byte-patch both vermagics (ARMv7 -> ARMv6).
#
# Why split (Run C33+): bdpdrv.ko must link against the REAL Sony CLI
# framework (drvcli.ko), not the stub's no-op cli_* exports. Part A
# (STUB_PART_A) exports ONLY drvcli's non-kernel deps (UTIL_Printf +
# g_u4disable_log + g_u4enable_log_droped). Part B is the full stub minus
# the 7 CLI symbols. Load order: stub_a -> drvcli -> stub_b -> bdpdrv.
#
# Source: /tmp/bx510_osal_stub.c (staged by the caller — see the
# sacd-stub-build Makefile target, which scp's the repo copy first).
# Outputs: /tmp/osal_a/bx510_osal_stub_a.ko, /tmp/osal_b/bx510_osal_stub.ko
set -e
export CROSS_COMPILE=$HOME/gnuarm/bin/arm-none-linux-gnueabi-
FLAGS="-march=armv6 -Wa,-march=armv6"
KDIR=$HOME/sony-kernel/linux-2.6.35

# part A (provider)
rm -rf /tmp/osal_a && mkdir -p /tmp/osal_a
cd /tmp/osal_a
cp /tmp/bx510_osal_stub.c stub_part_a.c
printf 'obj-m := bx510_osal_stub_a.o\nbx510_osal_stub_a-objs := stub_part_a.o\n' > Makefile
make -C "$KDIR" ARCH=arm M="$PWD" modules EXTRA_CFLAGS="$FLAGS -DSTUB_PART_A" >/tmp/buildA.log 2>&1

# part B (full stub minus CLI symbols)
rm -rf /tmp/osal_b && mkdir -p /tmp/osal_b
cd /tmp/osal_b
cp /tmp/bx510_osal_stub.c stub_part_b.c
printf 'obj-m := bx510_osal_stub.o\nbx510_osal_stub-objs := stub_part_b.o\n' > Makefile
make -C "$KDIR" ARCH=arm M="$PWD" modules EXTRA_CFLAGS="$FLAGS" >/tmp/buildB.log 2>&1

# clidrive (kernel-side CLI runtime driver; needs drvcli loaded first)
rm -rf /tmp/osal_c && mkdir -p /tmp/osal_c
cd /tmp/osal_c
cp /tmp/bx510_clidrive.c bx510_clidrive.c
printf 'obj-m := bx510_clidrive.o\n' > Makefile
make -C "$KDIR" ARCH=arm M="$PWD" modules EXTRA_CFLAGS="$FLAGS" >/tmp/buildC.log 2>&1

python3 /tmp/bx510_vermagic_patch.py /tmp/osal_a/bx510_osal_stub_a.ko
python3 /tmp/bx510_vermagic_patch.py /tmp/osal_b/bx510_osal_stub.ko
python3 /tmp/bx510_vermagic_patch.py /tmp/osal_c/bx510_clidrive.ko
ls -l /tmp/osal_a/bx510_osal_stub_a.ko /tmp/osal_b/bx510_osal_stub.ko /tmp/osal_c/bx510_clidrive.ko
