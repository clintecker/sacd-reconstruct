#!/usr/bin/env python3
"""daemon_map.py — generate docs/DAEMON-MAP.md from the LINKER MAP.

Numbers come from `release.map` (per-object .text sizes, symbol counts); prose and
diagrams are fixed text here. Regenerate after any build so the illustration can
never drift from the artefact:

    make sacd-daemon-map   MAP=.../reconstruct/release/release.map
"""
import argparse
import collections
import os
import re
import sys

OBJ_RE = re.compile(r"^\s\.text\s+0x([0-9a-f]+)\s+0x([0-9a-f]+)\s+(\S+\.o)\s*$")
SYM_RE = re.compile(r"^\s+0x([0-9a-f]+)\s+([A-Za-z_][A-Za-z0-9_.$]*)\s*$")

GROUPS = [
    ("tool_", "tool/", "the daemon itself: options, server loop, per-connection threads, CPSA wrappers, module install"),
    ("libsacd_", "libsacd/", "the disc: Scarlet Book structure, sector input, decryption glue, DSF/DSDIFF/ISO writers"),
    ("libdstdec_", "libdstdec/", "DST: the lossless compression SACD uses for multichannel, decoded back to DSD"),
    ("libcommon_", "libcommon/", "plumbing: logging, files, LuaSocket-derived sockets, nanopb-era protobuf"),
    ("libid3_", "libid3/", "ID3 tags for the output files (libid3tag lineage)"),
    ("yarn", "yarn", "C threading library behind the decode pool"),
    ("libgcc.a", "libgcc", "compiler runtime, pulled in helper by helper"),
    ("crt", "crt", "C runtime startup"),
]


def group_of(obj):
    base = os.path.basename(obj)
    for pref, name, _ in GROUPS:
        if base.startswith(pref):
            return name, ""
    return "other", ""


def bar(frac, width=40):
    return "\u2588" * int(round(frac * width)) + "\u00b7" * (width - int(round(frac * width)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", required=True)
    ap.add_argument("--src", default=None)
    ap.add_argument("--out", default=None)
    a = ap.parse_args()

    sizes, objs, syms, obj_size = collections.Counter(), collections.Counter(), collections.Counter(), {}
    cur, total = None, 0
    for line in open(a.map, encoding="utf-8", errors="ignore"):
        m = OBJ_RE.match(line.rstrip("\n"))
        if m:
            sz, obj = int(m.group(2), 16), m.group(3)
            g, _ = group_of(obj)
            sizes[g] += sz; objs[g] += 1; total += sz
            obj_size[obj] = obj_size.get(obj, 0) + sz
            cur = obj
            continue
        s = SYM_RE.match(line.rstrip("\n"))
        if s and cur:
            g, _ = group_of(cur)
            syms[g] += 1

    rows = sorted(sizes.items(), key=lambda kv: -kv[1])
    top = sorted(obj_size.items(), key=lambda kv: -kv[1])[:14]
    T = []
    A = T.append

    # ------------------------------------------------------------------ prose
    A("# What is inside `sacd_extract_160`\n")
    A("A guided tour of the binary that runs on the player: what each part does, "
      "how big it is, and why the shape looks the way it does. The numbers come "
      "from the linker map of the reconstructed build (`make sacd-daemon-map`); "
      "the prose is context a map cannot carry.\n")

    A("## The device, in one paragraph\n")
    A("The BDP-BX510 is a 2013 Sony Blu-ray player built on MediaTek's MT85xx "
      "SoC: an ARMv6 core at a few hundred MHz, 376 MB of RAM, Linux 2.6.35, and a "
      "monolithic 8 MB `bdpdrv.ko` that owns display, video decode and the SACD "
      "hardware path. Firmware `M15.R.0257` ships a single binary that matters to "
      "us, `/usr/local/bin/sacd_extract_160`, plus a small closed kernel module, "
      "`sacd_read.ko`, that it loads at runtime from its own body.\n")
    A("The player can already play SACDs. What it cannot do is hand you the DSD "
      "bitstream — so somebody at Sony wrote a tool that rips the disc, and then "
      "the tool leaked into the world as the community's ripping method. That tool "
      "is what this repository reconstructs.\n")

    A("## Why a SACD needs a daemon at all\n")
    A("A SACD is Scarlet Book: single-layer or dual-layer, up to 4.7 GB, carrying "
      "DSD audio in either raw form or **DST**, a lossless compression used when "
      "there is too much data for the layer. Crucially the audio area is "
      "**encrypted**, and the keys live in the disc's CPSA (Content Protection for "
      "Secure Audio). No PC drive will help you: a computer DVD drive cannot read "
      "the pit geometry correctly, and the player's own CPSA hardware is the only "
      "thing that decrypts it.\n")
    A("So the daemon does not decrypt anything itself. It reads *raw* 64-bit "
      "sectors and asks the player's module to decrypt them through ioctls. That "
      "single design decision explains the binary's shape: most of the code is disc "
      "structure and audio format, very little is protocol.\n")

    A("### 2064 and 2048 — the two numbers that define the wire\n")
    A("A SACD sector on the disc carries **2064** bytes: 2048 bytes of payload plus "
      "a 16-byte header. The decryption path consumes the 2064-byte raw sector and "
      "yields the 2048-byte logical sector, and it is the **2048-byte** form that "
      "travels over TCP — which is why a client asks for `sector_count` and gets "
      "exactly `count * 2048` bytes back, and why the TOC's total-sector count "
      "multiplied by 2048 equals the ISO's byte length exactly (Firebird: 1,064,208 "
      "sectors = 2,179,497,984 bytes).\n")

    A("## Where the code goes\n")
    A("```mermaid")
    A("flowchart LR")
    A("  client([\"client on the LAN\"])")
    A("  subgraph daemon[\"sacd_extract_160 (user space)\"]")
    A("    srv[\"tool/: listener + client_thread\"]")
    A("    disc[\"libsacd/: Scarlet Book + sector input\"]")
    A("    pb[\"libcommon/: protobuf framing\"]")
    A("    dst[\"libdstdec/: DST -> DSD\"]")
    A("    id3[\"libid3/: tags\"]")
    A("  end")
    A("  mod[\"/dev/sacd_read\"]")
    A("  hw[\"SACD disc + CPSA hardware\"]")
    A("  client <-->|\"TCP 2002\"| srv")
    A("  srv --> disc")
    A("  disc --> pb")
    A("  disc --> dst")
    A("  disc --> id3")
    A("  disc -->|\"raw 2064 B\"| mod")
    A("  mod --> hw")
    A("```\n")

    A("## A single read, end to end\n")
    A("```mermaid")
    A("sequenceDiagram")
    A("  participant C as client")
    A("  participant D as daemon (tool/)")
    A("  participant S as libsacd")
    A("  participant M as sacd_read.ko")
    A("  C->>D: DISC_OPEN")
    A("  D-->>C: result 0")
    A("  C->>D: DISC_SIZE")
    A("  D->>S: sacd_get_total_sectors()")
    A("  S-->>D: 1064208")
    A("  D-->>C: total_sectors")
    A("  C->>D: DISC_READ lsn=532104 count=1")
    A("  D->>S: sacd_read_block_raw64(lsn, count)")
    A("  S->>M: ioctl SACD_IOC_READ (2064 B)")
    A("  M-->>S: raw sector")
    A("  S->>M: ioctl SACD_IOC_DECRYPT")
    A("  M-->>S: 2048 B logical")
    A("  S-->>D: payload")
    A("  D-->>C: DISC_READ result=1 + 2048 bytes")
    A("  C->>D: DISC_CLOSE")
    A("  D-->>C: result 0, socket closed")
    A("```\n")

    A("## The byte budget, and what it says\n")
    A("| module | objects | `.text` bytes | share | |")
    A("|---|---:|---:|---:|---|")
    for g, sz in rows:
        A("| `%s` | %d | %d | %.1f%% | `%s` |" % (g, objs[g], sz, 100.0 * sz / total, bar(sz / total)))
    A("| **total `.text`** | %d | **%d** | 100%% | |" % (sum(objs.values()), total))
    A("")
    A("Read it as a statement about the problem, not about our effort: **half the "
      "binary is disc structure** — Scarlet Book areas, TOC parsing, the sector "
      "reader, and three output writers — and a further quarter is DST. The "
      "network protocol is the smallest part. A reimplementation that starts with "
      "the wire format is starting from the easy end.\n")

    A("## The biggest translation units\n")
    A("| object | `.text` bytes | module | what it is |")
    A("|---|---:|---|---|")
    WHAT = {
        "scarletbook_read": "reads and validates the disc's area/TOC structures",
        "dsdiff": "DSDIFF (DFF) writer — header, ID3 chunk, DST frame passthrough",
        "unpack_dst": "DST entropy decoding: the arithmetic-coded frame unpacker",
        "main": "options, install_modules, and the merged server mode",
        "scarletbook_output": "the output_format dispatch layer",
        "pb_decode": "protobuf decode (client requests)",
        "socket": "LuaSocket-derived socket helpers with timeouts",
        "scarletbook_print": "TOC/metadata printing (the -P style output)",
        "dst_fram": "DST frame-channel mapping",
        "fileutils": "file helpers used by the writers",
        "pb_encode": "protobuf encode (server responses)",
        "sacd_input": "sector input layer: raw reads -> logical sectors",
        "id3": "ID3 tag container",
        "id3_frame": "ID3 frame parsing",
    }
    for obj, sz in top:
        base = os.path.basename(obj)[:-2]
        key = next((k for k in WHAT if k in base), "")
        A("| `%s` | %d | `%s` | %s |" % (base, sz, group_of(obj)[0], WHAT.get(key, "")))
    A("")

    if a.src and os.path.isdir(a.src):
        A("## The source tree\n")
        A("| directory | files | C/asm | headers | notes |")
        A("|---|---:|---:|---:|---|")
        NOTE = {
            "tool": "daemon entry point and the CPSA wrappers",
            "libsacd": "the disc model and writers",
            "libdstdec": "DST decoder (Philips reference lineage)",
            "libcommon": "logging, sockets, protobuf, filesystem",
            "libid3": "ID3 tag library",
            "yarn": "threading primitives (not vendored upstream)",
            "fsflibgcc": "static libgcc/glibc support the original carries",
            "release": "linker map + release binary (build output)",
        }
        for d in sorted(os.listdir(a.src)):
            p2 = os.path.join(a.src, d)
            if not os.path.isdir(p2):
                continue
            files = [f for f in os.listdir(p2) if os.path.isfile(os.path.join(p2, f))]
            c = sum(1 for f in files if f.endswith((".c", ".S", ".asm")))
            h = sum(1 for f in files if f.endswith((".h", ".hpp")))
            A("| `%s/` | %d | %d | %d | %s |" % (d, len(files), c, h, NOTE.get(d, "")))
        A("")

    A("## Threads, and one inherited quirk\n")
    A("```mermaid")
    A("flowchart LR")
    A("  L[\"listener thread\"] -->|\"accept()\"| C1[\"client_thread A\"]")
    A("  L -->|\"accept()\"| C2[\"client_thread B\"]")
    A("  C1 --> P[\"decode pool: decode_thread xN\"]")
    A("  C2 --> P")
    A("  P --> W[\"write_thread\"]")
    A("  P -.->|\"locks\"| Y[\"yarn\"]")
    A("```\n")
    A("The original reuses **one stack slot** for the peer address across every "
      "accepted connection, so concurrent clients can interleave into the same "
      "slot. It is not a bug we fixed — it is behaviour the reconstruction keeps, "
      "and the concurrent-session evidence exists to prove both binaries do the "
      "same thing rather than to prove either one is correct.\n")

    A("## The community delta — the part with no upstream source\n")
    A("The binary is a port of **sacd-ripper v0.3.7** (commit `de008ff`, "
      "2012-12-29). Everything below exists only in the shipped ARM build, so it "
      "had to be recovered from the binary:\n")
    A("```mermaid")
    A("flowchart TD")
    A("  up[\"sacd-ripper v0.3.7 (2012, PS3-oriented)\"] --> port[\"ARM port for the BX510\"]")
    A("  port --> cpsa[\"CPSA backend: work through sacd_read.ko instead of a PC drive\"]")
    A("  port --> srv[\"server mode merged into the ripping tool\"]")
    A("  port --> width[\"64-bit sector addressing\"]")
    A("  cpsa --> W1[\"init/auth/read/decrypt/disc/uninit_sacd wrappers\"]")
    A("  cpsa --> W2[\"install_modules: write embedded .ko, mknod, insmod\"]")
    A("  srv --> S1[\"server_loop, main_loop, client_thread, listener_thread\"]")
    A("  srv --> S2[\"sacd_pb_stream: protobuf over a socket\"]")
    A("```\n")
    A("Each arrow is a place where the PS3 assumption broke. The PS3 tool had a "
      "dialog UI and a local drive; the player has neither, so the UI became a "
      "listener loop and the drive became a handful of ioctls.\n")

    A("## Two device facts that shaped everything downstream\n")
    A("1. **`compid` ownership.** `sacd_read.ko` takes a CPSA compute id as a "
      "module parameter. If the appliance already holds it, the module's init "
      "returns `-EBUSY` and prints *\"compid = N is used. Try another.\"* — a "
      "message the stock launch line throws away, which is why a daemon can die in "
      "one second with no visible cause.\n")
    A("2. **The panel is not `/dev/fb0`.** The display scans out an MT85xx image-pool "
      "buffer; a paint into the fbdev smem is overwritten within about two seconds. "
      "Anything drawing on this device has to go through the vendor pool (or the "
      "retail DirectFB stack).\n")

    A("## How to keep this document true\n")
    A("```sh")
    A("make sacd-daemon-map      # regenerate the numbers from release.map")
    A("make -C reconstruct release   # if you changed the source, rebuild first")
    A("```\n")
    A("If a number here disagrees with the binary, this document is wrong — the "
      "map is the source of truth. The same rule governs `docs/EVIDENCE.md`: "
      "claims carry the artefact that produced them.\n")

    text = "\n".join(T)
    if a.out:
        open(a.out, "w").write(text)
        print("wrote", a.out, len(text), "bytes")
    else:
        sys.stdout.write(text)


if __name__ == "__main__":
    main()
