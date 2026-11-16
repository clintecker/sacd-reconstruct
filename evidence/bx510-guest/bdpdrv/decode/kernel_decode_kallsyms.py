#!/usr/bin/env python3
"""Recover symbols from the BX510 guest kernel image (Linux 2.6.35, ARM).

Image chain (each step self-checked by kernel_decode_image.py):
  kernel.uImage --64-byte uImage header (comp=0)--> ARM zImage
  (magic 0x016f2818 at +0x24) --gzip member at +0x43d5--> raw 4,676,960-byte
  ARM image with no ELF headers (objcopy -O binary of vmlinux).

The raw image still carries the kallsyms tables, so symbols are recoverable
without any vendor map file.  2.6.35 layout, in file order:

    kallsyms_addresses[]   absolute u32 VAs, ascending
    kallsyms_num_syms      u32 (0x64d9 here), 12 bytes of pad follow
    kallsyms_names         byte stream: len byte + len token indices
    kallsyms_markers[]     u32 per 256 symbols: offset of names[256*i]
    kallsyms_token_table   256 NUL-terminated token strings (+ zero pad)
    kallsyms_token_index   256 u16 offsets into token_table

Nothing is located by hard-coded offset; every table is found from a
structural invariant and cross-checked against its neighbours:
  * token_index: only 512-byte window with u16[0]==0, strictly ascending,
    u16[255] < 0x4000, and whose token 255 ends the token_table (only zero
    padding may follow it up to token_index);
  * markers: ceil/floor(num_syms/256) ascending u32 immediately before the
    token_table (behind <=16 bytes of alignment pad);
  * addresses: ends where num_syms sits; must start at stext (0xc0008000)
    and stay ascending;
  * names: decoding exactly num_syms entries must land on the markers start
    (modulo alignment padding).

Usage:
  kernel_decode_kallsyms.py <raw-image>          # nm-style "<va> <name>"
  kernel_decode_kallsyms.py <raw-image> --check  # layout report only
"""
import struct
import sys

TEXT_VA = 0xC0008000  # stext == image file offset 0


def find_token_index(d):
    for off in range(0, len(d) - 512, 2):
        if d[off] or d[off + 1]:
            continue
        ti = struct.unpack_from("<256H", d, off)
        if all(ti[i] < ti[i + 1] for i in range(255)) and ti[255] < 0x4000:
            if off < ti[255]:
                continue
            yield off, ti


def token_table_start(d, ti_off, ti):
    """Locate kallsyms_token_table from token_index alone.

    token_index[k] is the byte offset of token k inside token_table, so for the
    real table start every ti[k] must be a string start and every ti[k+1]-1 a
    NUL; the last token ends before ti_off with only zero padding after it.
    Exactly one start satisfies that, so this is a structural fixpoint, not a
    guess.
    """
    for total in range(ti[255] + 2, ti[255] + 0x600):
        tt = ti_off - total
        ok = True
        for k in range(255):
            a, b = tt + ti[k], tt + ti[k + 1]
            if b <= a or d[b - 1] != 0 or 0 in d[a:b - 1]:
                ok = False
                break
        if not ok:
            continue
        e = d.find(b"\x00", tt + ti[255], ti_off)
        if e < 0 or any(d[e + 1:ti_off]):
            continue
        return tt, e
    return None, None


def ascending_u32_run_before(d, end):
    """Longest ascending u32 run ending at `end` (allowing alignment zeros)."""
    p = end
    while p - 4 >= 0 and struct.unpack_from("<I", d, p - 4)[0] == 0:
        p -= 4
    vals = []
    q = p - 4
    while q >= 0:
        v = struct.unpack_from("<I", d, q)[0]
        if vals and v >= vals[-1]:
            break
        if v > 1 << 26:
            break
        vals.append(v)
        q -= 4
    vals.reverse()
    return q + 4, vals


def locate(d):
    for ti_off, ti in find_token_index(d):
        tt, tt_end = token_table_start(d, ti_off, ti)
        if tt is None:
            continue
        mk_start, markers = ascending_u32_run_before(d, tt)
        if len(markers) < 2 or (len(markers) - 1) * 256 >= (1 << 20):
            continue
        names_end = mk_start
        while names_end > 0 and d[names_end - 1] == 0:
            names_end -= 1
        # kallsyms_num_syms is the u32 in the pad-guarded slot after the
        # addresses table; its value must satisfy ceil(ns/256) == n_markers
        # and the ns words before it must be an ascending TEXT_VA-first run.
        for ns_off in range(0, names_end, 4):
            ns = struct.unpack_from("<I", d, ns_off)[0]
            if not (len(markers) - 1) * 256 < ns <= len(markers) * 256:
                continue
            # <=12 bytes of alignment pad may sit between the addresses table
            # and kallsyms_num_syms (link-time ALIGN on the following object)
            end = ns_off
            while end > 4 and end > ns_off - 16 and d[end - 4:end] == b"\0\0\0\0":
                end -= 4
            addrs_off = end - ns * 4
            if addrs_off < 0:
                continue
            if struct.unpack_from("<I", d, addrs_off)[0] != TEXT_VA:
                continue
            addrs = struct.unpack_from("<%dI" % ns, d, addrs_off)
            if any(addrs[i] > addrs[i + 1] for i in range(ns - 1)):
                continue
            # token key = byte value -> token string, reached through
            # token_index[byte] into token_table (2.6.35 expansion)
            tokens = {}
            q = tt
            for _ in range(256):
                z = d.index(b"\x00", q)
                tokens[ti[_]] = d[q:z].decode("latin-1")
                q = z + 1
            names_start = ns_off + 4
            while names_start < names_end and d[names_start] == 0:
                names_start += 1
            # the decoded stream must land exactly on names_end
            p = names_start
            for _ in range(ns):
                if p >= names_end:
                    p = -1
                    break
                p += 1 + d[p]
            if p != names_end:
                continue
            return dict(
                addrs=list(addrs), num_syms=ns, addrs_off=addrs_off,
                num_syms_off=ns_off, names_off=names_start, names_end=names_end,
                markers_start=mk_start, markers=markers, token_table=tt,
                token_table_end=tt_end, token_index_off=ti_off, token_index=ti,
                tokens=tokens)
    raise SystemExit("kallsyms layout not found")


def symbols(img, lay):
    tokens, ti = lay["tokens"], lay["token_index"]
    p, out = lay["names_off"], []
    for addr in lay["addrs"]:
        ln = img[p]
        p += 1
        raw = img[p:p + ln]
        p += ln
        if ln & 0x80:
            raise SystemExit("unexpected long-name form at %#x" % p)
        # 2.6.35 expansion: for each byte, emit token_table[token_index[byte]];
        # the first expanded character is the symbol type letter, not the name.
        expanded = "".join(tokens[ti[b]] for b in raw)
        out.append((addr, (expanded[0], expanded[1:])))
    if p > lay["names_end"] + 4:
        raise SystemExit("names overrun %#x > %#x" % (p, lay["names_end"]))
    return out


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/kdec/vmlinux.bin"
    img = open(path, "rb").read()
    lay = locate(img)
    sys.stderr.write(
        "image %s\n  stext           %#010x  (file 0)\n"
        "  kallsyms_addrs  %#08x..%#08x  (%d entries)\n"
        "  kallsyms_num    %#08x  value %d\n"
        "  kallsyms_names  %#08x..%#08x\n"
        "  kallsyms_mark   %#08x  (%d entries)\n"
        "  token_table     %#08x..%#08x\n"
        "  token_index     %#08x\n"
        % (path, lay["addrs"][0], lay["addrs_off"],
           lay["addrs_off"] + 4 * lay["num_syms"], lay["num_syms"],
           lay["num_syms_off"], lay["num_syms"], lay["names_off"],
           lay["names_end"], lay["markers_start"], len(lay["markers"]),
           lay["token_table"], lay["token_table_end"], lay["token_index_off"]))
    syms = symbols(img, lay)
    sys.stderr.write("  decoded %d symbols; first 3: %s\n"
                     % (len(syms), ["%08x %s" % s for s in syms[:3]]))
    if "--check" in sys.argv:
        raise SystemExit(0)
    print("\n".join("%08x %s" % (a, n) for a, (t, n) in syms))
