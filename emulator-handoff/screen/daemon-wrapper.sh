#!/bin/sh
# The existing AutoScript may copy and launch this from RAM. Locate the
# marked USB directory, then run the original daemon under its original name.
kit=''
for item in /mnt/sd*/AutoScript/BX510Screen; do
    [ -r "$item/original/sacd_extract_160" ] && [ -r "$item/run-screen.sh" ] || continue
    [ -z "$kit" ] || exit 1
    kit=$item
done
[ -n "$kit" ] || exit 1
{
    echo "--- Wrapper entry pid=$$ parent=${PPID:-unknown} argv0=$0 args=$* ---"
    /bin/cat /proc/uptime
    if [ -r /proc/sys/kernel/random/boot_id ]; then /bin/cat /proc/sys/kernel/random/boot_id; fi
    if [ -r "/proc/${PPID:-0}/comm" ]; then /bin/cat "/proc/${PPID:-0}/comm"; fi
} >> "$kit/bx510-screen.log" 2>&1
umask 077
work=/tmp/bx510-server-$$
/bin/mkdir "$work" && /bin/cp "$kit/original/sacd_extract_160" "$work/sacd_extract_160" &&
    /bin/chmod 700 "$work/sacd_extract_160" || exit 1
daemon_pid=$$
for arg do
    if [ "$arg" = -S ]; then
        (
            /bin/sleep 5
            if kill -0 "$daemon_pid" 2>/dev/null; then
                echo "Daemon PID $daemon_pid present before screen probe" >> "$kit/bx510-screen.log"
                mode=--bars
                [ ! -f "$kit/FULLSCREEN" ] || mode=--fullscreen
                exec /bin/sh "$kit/run-screen.sh" "$mode"
            fi
        ) </dev/null &
        break
    fi
done
exec "$work/sacd_extract_160" "$@"
