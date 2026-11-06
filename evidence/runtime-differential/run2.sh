#!/bin/bash
SYS=$HOME/arm-2009q3/arm-none-linux-gnueabi/libc
run() {
    local tag="$1"; shift
    timeout 20 qemu-arm-static -L "$SYS" ~/difftest/sacd_extract_160 "$@" > ~/difftest/${tag}.new.out 2> ~/difftest/${tag}.new.err
    echo $? > ~/difftest/${tag}.new.rc
}
run help --help
run badopt -Z
run notsacd -i /etc/hostname
run outfile -i /dev/null /dev/null
run print -P
run iopt -i /tmp
