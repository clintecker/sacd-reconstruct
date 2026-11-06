#!/usr/bin/env python3
"""daemon_map.py — generate docs/DAEMON-MAP.md from the LINKER MAP.

Everything numerical in the generated document comes from `release.map` (the
link of the reconstructed binary): per-object .text sizes, symbol counts, and the
static library members pulled in. The prose is the part a human writes; the
numbers cannot drift from the binary because they are parsed, not remembered.

Usage: daemon_map.py --map release.map [--binary path] [--out docs/DAEMON-MAP.md]
"""
import argparse
import collections
import os
import re
import subprocess
import sys

OBJ_RE = re.compile(r"^\s\.text\s+0x([0-9a-f]+)\s+0x([0-9a-f]+)\s+(\S+\.o)\s*$")
SYM_RE = re.compile(r"^\s+0x([0-9a-f]+)\s+([A-Za-z_][A-Za-z0-9_.$]*)\s*$")

# module grouping: object prefix -> (display name, role)
GROUPS = [
    ("tool_",        "tool/",        "daemon entry: options, server loop, client threads, CPSA wrappers, module install"),
    ("libsacd_",     "libsacd/",     "disc model: scarletbook TOC, sector input, decryption glue, DSF/DSDIFF/ISO writers"),
    ("libdstdec_",   "libdstdec/",   "DST lossless decoder (Philips reference lineage)"),
    ("libcommon_",   "libcommon/",   "logging, filesystem, sockets, protobuf encode/decode, pb stream"),
    ("libid3_",      "libid3/",      "ID3 tags (libid3tag lineage)"),
    ("yarn",         "yarn",         "C threading library used by the decode pool"),
    ("libgcc.a",     "libgcc",       "compiler runtime pulled in per-ABI-helper basis"),
    ("crt",          "crt",          "C runtime start/init"),
]


def group_of(obj):
    base = os.path.basename(obj)
    for pref, name, role in GROUPS:
        if base.startswith(pref):
            return name, role
    return ("other", "other")


def bar(frac, width=44):
    n = int(round(frac * width))
    return "\u2588" * n + "\u00b7" * (width - n)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", required=True)
    ap.add_argument("--binary", default=None)
    ap.add_argument("--out", default=None)
    ap.add_argument("--src", default=None,
                    help="reconstruct/ source tree, to count files per library")
    a = ap.parse_args()

    sizes = collections.Counter()
    obj_size = {}
    syms = collections.Counter()
    objs = collections.Counter()
    cur = None
    total = 0
    for line in open(a.map, encoding="utf-8", errors="ignore"):
        m = OBJ_RE.match(line.rstrip("\n"))
        if m:
            sz, obj = int(m.group(2), 16), m.group(3)
            cur = obj
            g, _ = group_of(obj)
            sizes[g] += sz
            obj_size[obj] = obj_size.get(obj, 0) + sz
            objs[g] += 1
            total += sz
            continue
        s = SYM_RE.match(line.rstrip("\n"))
        if s and cur:
            g, _ = group_of(cur)
            syms[g] += 1

    rows = sorted(sizes.items(), key=lambda kv: -kv[1])
    top_objs = sorted(obj_size.items(), key=lambda kv: -kv[1])
    out = []
    out.append("# What is inside `sacd_extract_160`\n")
    out.append("Generated from the linker map of the reconstructed binary "
               "(`tools/daemon_map.py`), so the numbers match the artefact.\n")
    out.append("## The binary as a picture\n")
    out.append("```")
    out.append("                     ┌──────────────────────────────┐")
    out.append("   TCP :2002  ◄──────►│  tool/  server_loop           │  listener thread")
    out.append("                     │         client_thread ×N      │  detached per connection")
    out.append("                     │         protobuf over socket  │")
    out.append("                     └───────┬──────────────┬────────┘")
    out.append("                             │              │")
    out.append("              ┌──────────────▼───┐   ┌──────▼─────────────┐")
    out.append("              │ libsacd/         │   │ libcommon/         │")
    out.append("              │ scarletbook TOC  │   │ logging, files,    │")
    out.append("              │ sacd_input       │   │ socket, protobuf   │")
    out.append("              │ decrypt glue     │   └────────────────────┘")
    out.append("              └───┬──────────┬───┘")
    out.append("                  │          │")
    out.append("        read raw  │          │ write out")
    out.append("   2064 B/sector  │          │")
    out.append("                  ▼          ▼")
    out.append("        ┌─────────────────┐  ┌──────────────┐")
    out.append("        │ /dev/sacd_read  │  │ libdstdec/   │  DST → DSD")
    out.append("        │ (sacd_read.ko)  │  │ libid3/      │  tags")
    out.append("        │  CPSA decrypt   │  └──────────────┘")
    out.append("        └────────┬────────┘")
    out.append("                 ▼")
    out.append("          SACD disc  (2048 B logical sectors on the wire)")
    out.append("```")
    out.append("")
    out.append("## Byte budget, by module\n")
    out.append("| module | objects | `.text` bytes | share | |")
    out.append("|---|---:|---:|---:|---|")
    for g, sz in rows:
        role = next((r for n, _, r in GROUPS if n == g), "")
        out.append("| `%s` | %d | %d | %.1f%% | `%s` |"
                   % (g, objs[g], sz, 100.0 * sz / total, bar(sz / total)))
    out.append("| **total `.text`** | %d | **%d** | 100%% | |" % (sum(objs.values()), total))
    out.append("")
    out.append("## The biggest single translation units\n")
    out.append("| object | `.text` bytes | module |")
    out.append("|---|---:|---|")
    for obj, sz in top_objs[:14]:
        g, _ = group_of(obj)
        out.append("| `%s` | %d | `%s` |" % (os.path.basename(obj), sz, g))
    out.append("")
    out.append("## Symbols per module (functions + data)\n")
    out.append("| module | symbols |")
    out.append("|---|---:|")
    for g, _ in rows:
        out.append("| `%s` | %d |" % (g, syms[g]))
    out.append("")
    if a.src and os.path.isdir(a.src):
        out.append("## Source tree\n")
        out.append("| directory | files | C/asm | headers |")
        out.append("|---|---:|---:|---:|")
        for d in sorted(os.listdir(a.src)):
            p2 = os.path.join(a.src, d)
            if not os.path.isdir(p2):
                continue
            files = [f for f in os.listdir(p2) if os.path.isfile(os.path.join(p2, f))]
            c = sum(1 for f in files if f.endswith((".c", ".S", ".asm")))
            h = sum(1 for f in files if f.endswith((".h", ".hpp")))
            out.append("| `%s/` | %d | %d | %d |" % (d, len(files), c, h))
        out.append("")

    out.append("## What each part does\n")
    for name, _, role in GROUPS:
        if name in sizes:
            out.append("- **`%s`** — %s" % (name, role))
    out.append("")
    out.append("## The community delta (not in any published upstream revision)\n")
    out.append("These were reconstructed from the shipped binary alone; see `DELTA.md`\n"
               "for the full table and `docs/PROVENANCE.md` for the upstream commit.\n")
    for fn, why in [
        ("`init_sacd` / `auth_sacd` / `read_sacd` / `decrypt_sacd` / `disc_sacd` / `uninit_sacd`",
         "the CPSA wrappers: ioctls on `/dev/sacd_read`"),
        ("`sacd_read_block_raw64` / `sacd_dev_input_read64`",
         "64-bit sector addressing added by the ARM port"),
        ("`install_modules` / `remove_modules`",
         "extract the embedded `sacd_read.ko` to /tmp, mknod, insmod / rmmod"),
        ("`server_loop` / `main_loop` / `client_thread` / `listener_thread` / `validate_stdin`",
         "server mode merged into the ripping tool"),
        ("`sacd_pb_stream`", "socket-backed protobuf input/output stream"),
    ]:
        out.append("- %s — %s" % (fn, why))
    out.append("")
    out.append("## Threads\n")
    out.append("```")
    out.append("  listener            accept() → spawn")
    out.append("    └─ client_thread   one per connection, detached; owns its socket")
    out.append("         └─ (decode pool: decode_thread ×N / write_thread)")
    out.append("              └─ yarn  — thread/lock primitives")
    out.append("```")
    out.append("")
    out.append("The original reuses a single stack slot for the peer address across")
    out.append("connections; the reconstruction reproduces that and the concurrent-session")
    out.append("evidence covers it.\n")
    text = "\n".join(out) + "\n"
    if a.out:
        open(a.out, "w").write(text)
        print("wrote", a.out, len(text), "bytes")
    else:
        sys.stdout.write(text)


if __name__ == "__main__":
    main()
