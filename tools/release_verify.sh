#!/bin/sh
# release_verify.sh — `make verify` pipeline (issues #3/#4).
#
# Builds the release candidate from tracked sources via tools/release_build.py,
# then runs every check against that exact file. Any check failing exits
# nonzero. Prints the build command, candidate SHA-256 and each check verdict.
#
# Expected state on the producing host (the build host):
#   ~/gcc-4.4.1            FSF gcc 4.4.1 release source
#   ~/g441obj              configured+built gcc 4.4.1 (gcc/xgcc, default armv6z)
#   ~/glibc-2.9-build/glibc-2.9   glibc 2.9 + glibc-ports 2.9 sources
#   ~/arm-2009q3           CodeSourcery 2009q3-67 (libgcc_s.so.1 must hash to
#                          5068e1ea0c56591305d3c605d9fbd3e900ae8d134d13bc32a65e3fe1ddbec6d4)
#   ~/gnuarm/bin           FSF binutils 2.19.1 (as/ld, built with --with-sysroot)
#   qemu-arm-static        for the runtime checks
#   a python3 with pyelftools (venv) in $VERIFY_PY, default: uv-free venv
set -eu

REPO=$(cd "$(dirname "$0")/.." && pwd)
RECON="$REPO/reconstruct"
ORIG="$REPO/original/sacd_extract_160"
KIT="$REPO/incoming/sacd-installer-and-status/sacd-installer-and-status"
MTK="$REPO/incoming/sacd-mtk-forensics"
VERIFY_PY=${VERIFY_PY:-$HOME/sacdtest-venv/bin/python}
QEMU=${QEMU:-qemu-arm-static}
CSROOT=${CSROOT:-$HOME/arm-2009q3/arm-none-linux-gnueabi/libc}
EXPECT_FNMATCH=${EXPECT_FNMATCH:-388}
# fn_diff objdump backend: prefer $OBJDUMP, else the FSF arm objdump when
# present (build host), else the script default (llvm-objdump).
if [ "${OBJDUMP:-}" = "" ] && [ -x "$HOME/gnuarm/bin/arm-none-linux-gnueabi-objdump" ]; then
  OBJDUMP="$HOME/gnuarm/bin/arm-none-linux-gnueabi-objdump"
  export OBJDUMP
fi

echo "=== build (command: make verify -> tools/release_build.py) ==="
"$VERIFY_PY" "$REPO/tools/release_build.py"

IMG="$RECON/release/sacd_extract_160_release"
SHA=$(shasum -a 256 "$IMG" | cut -d' ' -f1) || SHA=$(sha256sum "$IMG" | cut -d' ' -f1)
echo
echo "=== verifying $IMG"
echo "=== SHA-256 $SHA"
echo

fail=0

echo "--- [1/5] fn_diff (expect $EXPECT_FNMATCH/390 normalized functions) ---"
"$VERIFY_PY" "$REPO/tools/fn_diff.py" "$ORIG" "$IMG" | tee /tmp/verify_fn_diff.txt
got=$(sed -n 's/^match: \([0-9]*\).*/\1/p' /tmp/verify_fn_diff.txt)
echo "fn_diff: $got functions match"
[ "$got" -ge "$EXPECT_FNMATCH" ] || { echo "FAIL: fn_diff below $EXPECT_FNMATCH"; fail=1; }

echo
echo "--- [2/5] link interface (DT_NEEDED order, 270 exports, 131 imports, 5 unwind) ---"
"$VERIFY_PY" "$KIT/check_link_interface.py" "$ORIG" "$IMG" || fail=1

echo
echo "--- [3/5] six-state status test (expect 6/6 on both) ---"
"$VERIFY_PY" "$KIT/test_status.py" --qemu "$QEMU" --sysroot "$CSROOT" "$ORIG" "$IMG" || fail=1

echo
echo "--- [4/5] integer-division oracle (expect 9,246/9,246) ---"
"$VERIFY_PY" "$MTK/verify_sacd_div.py" "$ORIG" "$IMG" || fail=1

echo
echo "--- [5/5] eager binding + --help under QEMU ---"
"$QEMU" -cpu arm1176 -L "$CSROOT" -E LD_BIND_NOW=1 "$IMG" --help >/dev/null 2>&1 || fail=1
echo "eager binding + --help: OK"

echo
if [ "$fail" = 0 ]; then
  echo "VERIFY: PASS — $IMG"
  echo "VERIFY: SHA-256 $SHA"
else
  echo "VERIFY: FAIL"
  exit 1
fi
