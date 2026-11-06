#!/bin/sh
# Stage or restore a duplicate of an already working AutoScript USB stick.
set -eu
test "$#" -eq 2 || { echo "usage: sh usb.sh awake|install|refresh|restore /path/to/test-stick" >&2; exit 2; }
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
volume=$(CDPATH='' cd -- "$2" && pwd)
folder=$volume/AutoScript
target=$folder/sacd_extract_160
kit=$folder/BX510Screen
expected=0fdcefdb84ae818be7385657eaf0960053f6e4452a82f19cbe6777f9c8cddb45
hash() {
    if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d ' ' -f 1
    else sha256sum "$1" | cut -d ' ' -f 1; fi
}
fail() { echo "$*" >&2; exit 1; }
check_wrapped() {
    active=$(hash "$target")
    [ "$active" = "$(hash "$here/daemon-wrapper.sh")" ] ||
        [ "$active" = "79c032d818925af0537f7b085b3dffc7c41bc254b3c2dc7bd0614d178aaedf04" ] ||
        fail "Unrecognized installed launcher. Keep your existing USB backup."
    [ "$(hash "$kit/original/sacd_extract_160")" = "$expected" ] || fail "Unexpected backup hash"
}
case "$1" in
awake)
    [ ! -e "$folder" ] || fail "Use a spare stick with no existing AutoScript directory."
    stage=$(mktemp -d "$volume/BX510stage.XXXXXXXX")
    trap 'if [ -n "$stage" ]; then rm -rf "$stage"; fi' 0
    mkdir "$stage/BX510Screen"
    cp "$here/bx510-screen" "$here/run-screen.sh" "$here/awake-screen.sh" "$stage/BX510Screen/"
    printf '%s\n' '#MTKAT 0.xx script' \
        'CLI(CLI_exec /bin/sh /mnt/sd*/AutoScript/BX510Screen/awake-screen.sh &)' > "$stage/AutoScript"
    mv "$stage" "$folder"
    stage=''
    echo "Ready. Select the Sony HDMI input, power on normally with the spare stick inserted, and leave the player awake at Home for 30 seconds."
    ;;
install)
    [ "$(hash "$target")" = "$expected" ] || fail "Unexpected original daemon hash; check this stick."
    [ ! -e "$kit" ] || fail "BX510Screen already exists. Keep its logs and move it aside before reinstalling."
    stage=$(mktemp -d "$folder/BX510stage.XXXXXXXX")
    trap 'if [ -n "$stage" ]; then rm -rf "$stage"; fi' 0
    mkdir "$stage/original"
    cp "$target" "$stage/original/sacd_extract_160"
    [ "$(hash "$stage/original/sacd_extract_160")" = "$expected" ] || fail "Backup verification failed"
    cp "$here/bx510-screen" "$here/run-screen.sh" "$stage/"
    cp "$here/daemon-wrapper.sh" "$stage/new-launcher"
    chmod +x "$stage/new-launcher"
    mv "$stage" "$kit"
    stage=''
    mv -f "$kit/new-launcher" "$target"
    echo "Ready. Eject the test stick, then start your usual daemon. Log: AutoScript/BX510Screen/bx510-screen.log"
    ;;
refresh)
    check_wrapped
    stage=$(mktemp -d "$folder/BX510refresh.XXXXXXXX")
    trap 'rm -rf "$stage"' 0
    cp "$here/bx510-screen" "$here/run-screen.sh" "$here/daemon-wrapper.sh" "$stage/"
    chmod +x "$stage/daemon-wrapper.sh"
    mv -f "$stage/bx510-screen" "$kit/bx510-screen"
    mv -f "$stage/run-screen.sh" "$kit/run-screen.sh"
    mv -f "$stage/daemon-wrapper.sh" "$target"
    echo "Probe refreshed. The original daemon backup, AutoScript, AutoScript.TSS and previous logs were preserved."
    ;;
restore)
    check_wrapped
    tmp=$(mktemp "$folder/BX510restore.XXXXXXXX")
    trap 'rm -f "$tmp"' 0
    cp "$kit/original/sacd_extract_160" "$tmp"
    [ "$(hash "$tmp")" = "$expected" ] || fail "Restore copy failed verification"
    chmod +x "$tmp"
    mv -f "$tmp" "$target"
    echo "Original daemon restored. Logs and backup remain in AutoScript/BX510Screen."
    ;;
*) fail "Choose awake, install, refresh or restore" ;;
esac
