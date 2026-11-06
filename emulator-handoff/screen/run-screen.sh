#!/bin/sh
# shell entry point on the Sony. Supply an absolute script path to /bin/sh.
set -u
case "$0" in */*) kit=${0%/*} ;; *) kit=. ;; esac
case "${1:---bars}" in --bars|--fullscreen|--info) mode="${1:---bars}" ;; *) exit 2 ;; esac
exec >>"$kit/bx510-screen.log" 2>&1
echo "Starting BX510 screen probe $mode pid=$$ parent=${PPID:-unknown} argv0=$0"
/bin/cat /proc/uptime
{
    echo "--- BX510 running system ---"
    for file in /proc/uptime /proc/sys/kernel/random/boot_id /proc/version /proc/cmdline /proc/mtd /proc/mounts \
                /proc/fb /sys/class/graphics/fb0/name /sys/class/graphics/fb0/blank \
                /proc/driver/fusion/0/fusionees /proc/fusion/0/fusionees; do
        if [ -r "$file" ]; then
            echo "[$file]"
            /bin/cat "$file"
        fi
    done
    echo "[display devices]"
    /bin/ls -ld /dev/fusion* /dev/fusion/* /dev/fb0 /dev/fb/0 2>/dev/null
    echo "[display and daemon processes]"
    for proc in /proc/[0-9]*; do
        [ -r "$proc/comm" ] || continue
        read -r name < "$proc/comm" || continue
        case "$name" in bdpprog|cliprog|sacd_extract*|sawman*|dfb*|fusion*)
            echo "$proc $name"
            while IFS= read -r line; do
                case "$line" in State:*|PPid:*) echo "$line";; esac
            done < "$proc/status"
            /bin/ls -l "$proc/fd" 2>/dev/null | while IFS= read -r line; do
                case "$line" in *'/dev/fusion'*|*'/dev/fb'*) echo "$line";; esac
            done ;;
        esac
    done
} >> "$kit/boot-info.txt"
umask 077
work=/tmp/bx510-screen-$$
/bin/mkdir "$work" || exit 1
trap '/bin/rm -f "$work/bx510-screen"; /bin/rmdir "$work"' 0
/bin/cp "$kit/bx510-screen" "$work/bx510-screen" && /bin/chmod 700 "$work/bx510-screen" || exit 1
"$work/bx510-screen" --info
info_rc=$?
echo "INFO_EXIT=$info_rc"
if [ "$mode" = --info ]; then exit "$info_rc"; fi
"$work/bx510-screen" "$mode"
rc=$?
echo "DRAW_EXIT=$rc"
exit "$rc"
