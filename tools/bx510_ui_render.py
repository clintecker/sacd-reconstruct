#!/usr/bin/env python3
"""bx510_ui_render.py — render the UI fire's guest SCRIPT and its fire command.

Two artifacts, because the guest console cannot carry the scenario:

  the script   tools/bx510_ui_guest.sh.in with its placeholders substituted —
               staged into the payload tgz as shim/<name>, so the guest reads it
               from tmpfs instead of from the serial line. A ~1350-byte one-line
               command gets TRUNCATED mid-word by the guest console (measured,
               run uiloop3: `/bin/sh: slee: not found` at char ~1200, and the
               remainder of the scenario silently never ran — the C43 lesson,
               now with a length).
  the command  `tar -xzf /res/shim/daemon_payload.tgz -C /res; sh /res/shim/<name>`
               — 82 bytes, the shape every fire since c122g has used.

The render is a GATE, not a template expansion. A fire that loses a step still
looks like a data problem: c122f served ZERO FE traffic and died with "Not a
ScarletBook disc!" only because the two `sr_fa_mode` invocations were absent
(decode/daemon-read-despatch.md §3, dd-eio-loop.md §6.2). So the rendered script
must carry, in order:

  * the /tmp tmpfs (the daemon writes its embedded sacd_read.ko there);
  * the payload tgz extraction;
  * the FA-latch clear BEFORE the daemon opens /dev/sr0, and its read-back;
  * the CPSA Connect/Release pre-arm (0x40105301 then 0x40105305);
  * the fbdev node bound to fbvirt's own index (fbvirt is fb1 once the daemon
    stack is resident — run u1 — and /dev/fb0 as `c 29 0` is the MT8530 driver,
    which SIGBUSes the UI and the dump);
  * frame egress in row mode + the UI_SCALE hint + the UI_SHOT_DONE marker.
  * and, in a script that starts the UI at all, a UI kill gated on the UI's own
    first-frame marker (/res/ui-frame.done) with a bounded fallback — never a
    fixed sleep (issue #13: DISC_OPEN alone is 22 s, so a sleep is either too
    short to find a frame or wasted fire time).

Usage:
  bx510_ui_render.py --runid c124 --out /tmp/g-c124.txt --script /tmp/bx510_ui_guest-c124.sh
  bx510_ui_render.py --runid c124 --print-only
Exit: 0 rendered, 1 invariant violation / bad template, 2 usage error.
"""
import argparse
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
DEFAULT_TEMPLATE = HERE / "bx510_ui_guest.sh.in"

# The daemon launch line, as the template writes it: everything the FA clear
# must precede. One spelling, shared with the ordering invariant.
DAEMON_LAUNCH = "./sacd_extract_160 -S"
STAGED_DIR = "/res/shim"

# The UI's own first-frame marker and the shape of the bounded wait that reads
# it. Both spellings live here so the templates, the gate and the tests cannot
# drift apart (the wait is the mechanism issue #13 replaced a fixed sleep with).
UI_LAUNCH = "./sacd_ui"
UI_FRAME_MARKER = "/res/ui-frame.done"


def placeholders(a):
    return {
        "SCALE": str(a.scale),
        "DAEMON_WAIT": str(a.daemon_wait),
        "UI_WAIT_MAX": str(a.ui_wait_max),
        "CLIENT_LSN": str(a.client_lsn),
        "CLIENT_CNT": str(a.client_cnt),
        "UI_ARGS": a.ui_args,
        "POOL_ARGS": f"{a.pool_ofs} {a.pool_w} {a.pool_h}",
        "DAEMON_LAUNCH": getattr(a, "daemon_launch", None) or DAEMON_LAUNCH,
    }


def executable_lines(template_text):
    """The template's code lines: blank and comment lines dropped."""
    out = []
    for raw in template_text.splitlines():
        line = raw.strip()
        if line and not line.startswith("#"):
            out.append(line)
    return out


def render_script(template_text, values):
    """Template text -> the staged guest script. Raises ValueError."""
    if not executable_lines(template_text):
        raise ValueError("template has no executable lines")
    rendered = template_text
    for name, value in values.items():
        rendered = rendered.replace(f"@{name}@", value)
    # Comments may NAME a placeholder (this file's own header does), so the
    # whitelist is enforced on the code the guest will actually run.
    code = "\n".join(executable_lines(rendered))
    if "@" in code:
        leftover = [tok for tok in code.split() if tok.startswith("@") and tok.endswith("@")]
        raise ValueError(f"unrendered placeholder(s) left in the script: {leftover}")
    return rendered


def guest_command(script_name):
    """The 82-byte fire command: extract the tgz, run the staged script."""
    return f"tar -xzf {STAGED_DIR}/daemon_payload.tgz -C /res; sh {STAGED_DIR}/{script_name}"


def check_invariants(code, daemon_launch=DAEMON_LAUNCH):
    """code: the script's executable lines joined by newlines -> [(desc, ok, detail)]."""
    checks = []

    def need(desc, needle, count=None):
        n = code.count(needle)
        ok = n >= (count if count is not None else 1)
        checks.append((desc, ok, f"{needle!r} x{n}"))

    need("/tmp tmpfs (daemon writes its embedded sacd_read.ko there)",
         "mount -t tmpfs tmpfs /tmp")
    need("payload tgz extraction", "tar -xzf /res/shim/daemon_payload.tgz")
    need("CPSA Connect pre-arm (0x40105301)", "/res/shim/sacdgate 0x40105301 /dev/sacd_read")
    need("CPSA slot release (0x40105305, or the daemon's Connect is 0xE8000006 busy)",
         "/res/shim/sacdgate 0x40105305 /dev/sacd_read")
    # The c122f rule: clear, then read back / open again — two invocations.
    need("FA-latch CLEAR (c122f lesson)", "/res/shim/sr_fa_mode /dev/sr0 clear")
    need("FA-latch read-back", "/res/shim/sr_fa_mode /dev/sr0", count=2)
    need("daemon launch", daemon_launch)
    # fbvirt is fb1 once the daemon stack is resident (run u1), so the node is
    # bound to the index fbvirt reported, never to a hard-coded minor 0.
    need("fbdev node bound to fbvirt's own index (not the driver's fb0)",
         "set -- $(grep fbvirt /res/proc/fb); mknod /dev/fb0 c 29 $1")
    need("frame egress (fbdev smem dump, row mode)", "./fbdump --rows /dev/fb0")
    need("frame egress (pool primary dump, row mode)", "./fbdump --rows --pool")
    need("decoder hint (row step)", "echo UI_SCALE=")
    need("shot marker", "echo UI_SHOT_DONE")

    clear_at = code.find("/res/shim/sr_fa_mode /dev/sr0 clear")
    launch_at = code.find(daemon_launch)
    checks.append((
        "FA-latch clear BEFORE the daemon's /dev/sr0 open "
        "(a clear after it is thrown away)",
        0 <= clear_at < launch_at, f"clear@{clear_at} launch@{launch_at}"))

    # Issue #13: the UI is killed when it says a frame exists, not after a fixed
    # sleep. The session before that frame is a 22 s DISC_OPEN (c123/c132/c133),
    # so a short sleep captures nothing (uiloop7's honest black verdict) and a
    # long one just spends fire time. A UI-launching script must therefore wait
    # on /res/ui-frame.done inside a loop with a numeric bound, and must not put
    # a fixed `sleep <n>` between the launch and the kill.
    if UI_LAUNCH in code:
        lines = code.splitlines()
        launch_i = next((i for i, ln in enumerate(lines) if ln.startswith(UI_LAUNCH)
                         or f" {UI_LAUNCH} " in ln), None)
        kill_i = next((i for i, ln in enumerate(lines) if ln.strip().startswith("kill $U")),
                      len(lines))
        wait_lines = [ln for ln in lines[:kill_i]
                      if ln.startswith("i=0; while") and UI_FRAME_MARKER in ln
                      and "[ $i -lt " in ln and "do sleep 1" in ln]
        checks.append((
            "UI kill waits on the first-frame marker with a bounded fallback "
            "(issue #13, never a fixed sleep)",
            bool(wait_lines), f"{UI_FRAME_MARKER} wait lines x{len(wait_lines)}"))
        bare = [ln.strip() for ln in lines[launch_i or 0:kill_i]
                if re.fullmatch(r"sleep \d+", ln.strip())]
        checks.append((
            "no fixed `sleep <n>` between the UI launch and its kill",
            not bare, f"bare sleeps x{len(bare)} {bare}"))

    # An UNBOUNDED marker wait is a wedge waiting to happen: if the marker never
    # lands, the fire sits there until the probe timeout and the transcript says
    # nothing about why. Every wait in this lane carries its own bound and reports
    # expiring (`*_WAIT_TIMEOUT`) instead of going silent.
    unbounded = [ln.strip() for ln in code.splitlines()
                 if re.search(r"while \[ ! -f [^\]]+ \]; do sleep 1; done", ln)]
    checks.append((
        "no unbounded marker wait (every wait carries its own bound)",
        not unbounded, f"unbounded x{len(unbounded)} {unbounded}"))
    return checks


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--runid", required=True, help="run id, e.g. c124 (labelling only)")
    ap.add_argument("--out", default=None,
                    help="write the fire's guest COMMAND here (make bx510-fire GCMD_FILE=)")
    ap.add_argument("--script", default=None,
                    help="write the rendered guest SCRIPT here (staged into the tgz)")
    ap.add_argument("--template", type=Path, default=DEFAULT_TEMPLATE)
    ap.add_argument("--scale", type=int, default=6,
                    help="fbdump decimation; 6 = 320x180 per dump (fast), 2 = 960x540")
    ap.add_argument("--daemon-wait", type=int, default=8)
    ap.add_argument("--daemon-launch", default=None,
                    help="override the daemon launch line (e.g. for the "
                         "in-daemon HUD: './sacd_extract_160 -S --hud=console'); "
                         "the invariants still check the FA-clear ordering "
                         "against whatever line is used")
    ap.add_argument("--ui-wait-max", type=int, default=90,
                    help="upper bound, in seconds, on the UI's first-frame "
                         "marker wait (the marker normally ends it far sooner: "
                         "the UI writes /res/ui-frame.done after its first "
                         "painted frame). This is the fallback that kills a UI "
                         "which never paints, so it must exceed the UI's own "
                         "session (DISC_OPEN alone measured 22 s)")
    ap.add_argument("--client-lsn", type=int, default=510)
    ap.add_argument("--client-cnt", type=int, default=10)
    ap.add_argument("--ui-args", default="", help="argv for ./sacd_ui (guest shell text)")
    ap.add_argument("--pool-ofs", type=int, default=4096,
                    help="byte offset of the primary inside the vendor pool")
    ap.add_argument("--pool-w", type=int, default=1920)
    ap.add_argument("--pool-h", type=int, default=1080)
    ap.add_argument("--script-name", default=None,
                    help="staged script name (default bx510_ui_guest-<runid>.sh)")
    ap.add_argument("--print-only", action="store_true", help="write nothing")
    a = ap.parse_args(argv)

    if not a.print_only and (a.out is None or a.script is None):
        ap.error("--out and --script are required unless --print-only")
    script_name = a.script_name or f"bx510_ui_guest-{a.runid}.sh"
    if "/" in script_name or " " in script_name:
        ap.error("--script-name must be a bare file name (it becomes a tgz member)")

    try:
        text = a.template.read_text()
        script = render_script(text, placeholders(a))
    except (OSError, ValueError) as exc:
        print(f"FAIL template {a.template}: {exc}", file=sys.stderr)
        return 1

    checks = check_invariants("\n".join(executable_lines(script)),
                              getattr(a, "daemon_launch", None) or DAEMON_LAUNCH)
    for desc, ok, detail in checks:
        print(f"{'ok  ' if ok else 'FAIL'} {desc} [{detail}]")
    if not all(ok for _, ok, _ in checks):
        print(f"\nREFUSING to render run {a.runid}: a mandatory invariant is "
              f"missing from {a.template.name}. A UI fire without it reports a "
              "data failure that is really a scenario failure (c122f).",
              file=sys.stderr)
        return 1

    cmd = guest_command(script_name)
    if a.print_only:
        print(f"guest script: {len(script)} B, {len(executable_lines(script))} lines")
        print(script)
        print(f"guest command ({len(cmd)} B, one line):\n{cmd}")
        return 0
    Path(a.script).write_text(script)
    Path(a.out).write_text(cmd + "\n")
    print(f"guest script ({len(script)} B) -> {a.script}  [tgz member shim/{script_name}]")
    print(f"guest command ({len(cmd)} B, one line) -> {a.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
