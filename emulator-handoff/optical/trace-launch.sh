#!/bin/sh
# Run from the existing player launcher in place of its normal daemon command
# on a separate, instrumented run. Do not start a second daemon on port 2002.
set -eu
[ "$#" -ge 3 ] || { echo "usage: sh trace-launch.sh ORIGINAL_ELF DECIMAL_LSN ABSOLUTE_OUTPUT.pair [-S]" >&2; exit 2; }
elf=$1; lsn=$2; output=$3; shift 3
case "$lsn" in ''|*[!0-9]*) echo "Expected decimal LSN" >&2; exit 2;; esac
case "$output" in /*) ;; *) echo "Use an absolute output path on USB" >&2; exit 2;; esac
[ ! -e "$output" ] || { echo "Choose a new output path" >&2; exit 2; }
case "$0" in */*) here=${0%/*} ;; *) here=. ;; esac
umask 077
work=/tmp/bx510-trace-$$
/bin/mkdir "$work"
/bin/cp "$elf" "$work/sacd_extract_160"
/bin/cp "$here/bx510_pair.so" "$work/bx510_pair.so"
/bin/chmod 700 "$work/sacd_extract_160"
BX510_PAIR_LSN=$lsn; BX510_PAIR_OUT=$output; LD_PRELOAD=$work/bx510_pair.so
export BX510_PAIR_LSN BX510_PAIR_OUT LD_PRELOAD
if [ "$#" -eq 0 ]; then set -- -S; fi
exec "$work/sacd_extract_160" "$@"
