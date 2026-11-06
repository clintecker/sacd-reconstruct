#!/bin/sh
# A marker confirms that AutoScript ran even if optical playback or HDMI is idle.
case "$0" in */*) kit=${0%/*} ;; *) kit=. ;; esac
{ echo "AutoScript entered"; /bin/cat /proc/uptime; } >> "$kit/entered.txt" 2>&1
/bin/sleep 6
mode=--bars
[ ! -f "$kit/FULLSCREEN" ] || mode=--fullscreen
/bin/sh "$kit/run-screen.sh" "$mode" && exit 0
/bin/sleep 5
exec /bin/sh "$kit/run-screen.sh" "$mode"
