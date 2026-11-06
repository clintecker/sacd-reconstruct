#!/usr/bin/env python3
"""hud_anim.py — render the HUD as an animated GIF and MP4.

Runs the host simulator (same scene code as the panel) for N frames, one frame
per 0.2 s of HUD time, then assembles:

  <out>.gif   palette-quantised, loops forever (for chat/review)
  <out>.mp4   h264 if ffmpeg is available

The panel itself animates the same way; this is the offline preview path.

Usage: hud_anim.py --sim /tmp/hudsim [--frames 40] [--scale 640] --out /tmp/hud
"""
import argparse
import os
import shutil
import subprocess
import sys
import tempfile

from PIL import Image


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sim", default="/tmp/hudsim")
    ap.add_argument("--frames", type=int, default=40)
    ap.add_argument("--scale", type=int, default=640, help="output width for the GIF")
    ap.add_argument("--out", default="/tmp/hud_anim")
    a = ap.parse_args()

    tmp = tempfile.mkdtemp(prefix="hudanim-")
    env = dict(os.environ, HUD_RETRO="1", HUD_SIM_ANIM=tmp)
    r = subprocess.run([a.sim, os.path.join(tmp, "last.ppm"), str(a.frames)],
                       capture_output=True, text=True, env=env)
    print(r.stdout.strip()[-200:] or r.stderr.strip()[-200:])
    frames = sorted(f for f in os.listdir(tmp) if f.startswith("frame-"))
    if not frames:
        print("no frames rendered", file=sys.stderr)
        return 1
    imgs = []
    for f in frames:
        im = Image.open(os.path.join(tmp, f)).convert("RGB")
        w, h = im.size
        imgs.append(im.resize((a.scale, a.scale * h // w), Image.BILINEAR))

    gif = a.out + ".gif"
    imgs[0].save(gif, save_all=True, append_images=imgs[1:], duration=200, loop=0,
                 optimize=True)
    print("gif:", gif, len(imgs), "frames")

    if shutil.which("ffmpeg"):
        mp4 = a.out + ".mp4"
        p = subprocess.run(["ffmpeg", "-y", "-loglevel", "quiet",
                            "-framerate", "5", "-i", os.path.join(tmp, "frame-%03d.ppm"),
                            "-pix_fmt", "yuv420p", "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2",
                            mp4], capture_output=True)
        if p.returncode == 0:
            print("mp4:", mp4)
        else:
            print("mp4 failed:", p.stderr.decode()[-200:], file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
