#!/usr/bin/env python3
"""Regression tests for pool_audit's literal comparison (issue #2).

Both mutants below passed the OLD audit (multiset compare + fixed 32-byte
window) and must fail the NEW one (positional load-site compare + wide
strings decoded through the UTF-32 terminator):

  A. pointer swap: exchange server_loop's L"connected" and L"none" pool
     words — the multiset is unchanged, only the load sites move.
  B. ninth character: mutate the 9th char of L"connected" ('d' -> 'x') —
     it sat outside the old 32-byte window; the terminator-driven decode
     must now see it.

Usage: python3 tools/test_pool_audit_regressions.py <original> <candidate>
Exit code 0 = audit behaves correctly on all three cases.
"""

import importlib.util
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))


def load_audit():
    spec = importlib.util.spec_from_file_location(
        "pool_audit", os.path.join(HERE, "pool_audit.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def run_audit(mod, orig, cand, only="server_loop"):
    o = mod.ELF(orig)
    r = mod.ELF(cand)
    o_funcs = dict(o.disasm_functions())
    r_funcs = dict(r.disasm_functions())
    o_pools = o.pool_loads(only, o_funcs[only])
    r_pools = r.pool_loads(only, r_funcs[only])
    assert len(o_pools) == len(r_pools), "pool count changed unexpectedly"
    fails = []
    for i, ((ova, _, oword), (rva, _, rword)) in enumerate(zip(o_pools, r_pools)):
        if oword == rword:
            continue
        if o.describe_word(oword) == r.describe_word(rword):
            continue
        fails.append(i)
    return fails


def find_wide_sites(mod, path, want):
    """file-offset + info for pool entries whose target decodes to `want`."""
    elf = mod.ELF(path)
    funcs = dict(elf.disasm_functions())
    pools = elf.pool_loads("server_loop", funcs["server_loop"])
    sites = []
    for va, pool_va, word in pools:
        desc = elf.describe_word(word)
        if desc == "wide:%r" % want:
            off, sec = elf.va2off(pool_va)
            toff, tsec = elf.va2off(word)
            sites.append((pool_va, off, toff))
    return sites


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    orig, cand = sys.argv[1], sys.argv[2]
    mod = load_audit()
    ok = True

    # clean candidate must pass server_loop
    fails = run_audit(mod, orig, cand)
    if fails:
        print("FAIL: clean candidate flags server_loop sites %s" % fails)
        ok = False
    else:
        print("PASS: clean candidate — server_loop clean")

    cand_data = bytearray(open(cand, "rb").read())
    conn = find_wide_sites(mod, cand, "connected")
    none = find_wide_sites(mod, cand, "none")
    if len(conn) != 1 or len(none) != 1:
        print("FAIL: expected exactly one 'connected' and one 'none' pool "
              "site in server_loop, got %d/%d" % (len(conn), len(none)))
        return 1

    # --- mutant A: swap the two pool words -----------------------------
    with tempfile.NamedTemporaryFile(suffix=".elf", delete=False) as tf:
        swap = bytearray(cand_data)
        conn_off, none_off = conn[0][1], none[0][1]
        w_conn = bytes(swap[conn_off:conn_off + 4])
        w_none = bytes(swap[none_off:none_off + 4])
        swap[conn_off:conn_off + 4] = w_none
        swap[none_off:none_off + 4] = w_conn
        tf.write(swap)
        swap_path = tf.name
    fails = run_audit(mod, orig, swap_path)
    if fails:
        print("PASS: pointer swap flagged at sites %s" % fails)
    else:
        print("FAIL: pointer swap NOT flagged (multiset masking)")
        ok = False
    os.unlink(swap_path)

    # --- mutant B: ninth character of "connected" ----------------------
    # utf-32le: 9th char = bytes 32..35 of the string object
    with tempfile.NamedTemporaryFile(suffix=".elf", delete=False) as tf:
        ninth = bytearray(cand_data)
        soff = conn[0][2]
        before = bytes(ninth[soff + 32:soff + 36])
        assert before == b"d\x00\x00\x00", "unexpected 9th char bytes %r" % before
        ninth[soff + 32:soff + 36] = b"x\x00\x00\x00"
        tf.write(ninth)
        ninth_path = tf.name
    fails = run_audit(mod, orig, ninth_path)
    if fails:
        print("PASS: ninth-character mutation flagged at sites %s" % fails)
    else:
        print("FAIL: ninth-character mutation NOT flagged (window truncation)")
        ok = False
    os.unlink(ninth_path)

    print("REGRESSIONS:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
