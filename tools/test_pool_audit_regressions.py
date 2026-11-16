#!/usr/bin/env python3
"""Regression + semantics tests for pool_audit's literal comparison
(issues #2 / #12 — policy in evidence/status-test/fn-diff-literal-policy.md).

Five mutants. The first two passed the ORIGINAL audit (multiset compare +
fixed 32-byte window) and are why the load-site/terminator rewrite exists; the
last three passed BOTH the fn_diff+pool_audit pair until the literal policy
gained identity classes:

  A. pointer swap: exchange server_loop's L"connected" and L"none" pool
     words — the multiset is unchanged, only the load sites move.
  B. ninth character: mutate the 9th char of L"connected" ('d' -> 'x') —
     it sat outside the old 32-byte window; the terminator-driven decode
     must now see it.
  C. function-pointer swap: sacd_input_setup's sacd_net_input_open and
     sacd_net_input_read pool words — both address "some .text address", so
     the symbol-blind `code-ptr` class accepted the swap. The identity of a
     taken function address is its symbol.
  D. embedded-module boundary: install_modules' `_binary_sacd_read_ko_end`
     pool word +4 — an unmapped image-range value, which used to compare as
     the opaque class "layout-ptr" whatever its value. It is the size the
     daemon writes to /tmp, so a wrong value must fail.
  E. module blob byte flip at offset 0x100 — the sacd_read.ko blob is data,
     never disassembled, so only blob byte identity can catch it.

Usage: python3 tools/test_pool_audit_regressions.py <original> <candidate>
(pytest mode uses the tracked original + release ELFs.)
Exit code 0 = audit behaves correctly on every case.
"""

import importlib.util
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
ORIG_ELF = os.path.join(REPO, "original", "sacd_extract_160")
RELEASE_ELF = os.path.join(
    REPO, "reconstruct", "release", "sacd_extract_160_release")


def load_audit():
    spec = importlib.util.spec_from_file_location(
        "pool_audit", os.path.join(HERE, "pool_audit.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


class Pair:
    """ELF pair + the one function table both sides are read through."""

    def __init__(self, mod, orig, cand):
        self.mod = mod
        self.orig_path = orig
        self.cand_path = cand
        self.o = mod.ELF(orig)
        self.r = mod.ELF(cand)
        self.o_funcs = dict(self.o.disasm_functions())
        self.r_funcs = dict(self.r.disasm_functions())
        self.data = bytearray(open(cand, "rb").read())

    def pools(self, func):
        return (self.o.pool_loads(func, self.o_funcs[func]),
                self.r.pool_loads(func, self.r_funcs[func]))

    def fails(self, func=None):
        """Audit failures across all functions (or one)."""
        fails = []
        for name in (self.o_funcs if func is None else [func]):
            if name not in self.r_funcs:
                continue
            op, rp = self.pools(name)
            if len(op) != len(rp):
                fails.append((name, "count"))
                continue
            for f in self.mod.site_failures(self.o, self.r, op, rp):
                fails.append((name,) + f)
        return fails

    def site_file_offset(self, func, idx):
        """(file offset, word) of the pool word at a load site."""
        pools = self.r.pool_loads(func, self.r_funcs[func])
        _, pool_va, word = pools[idx]
        off, _ = self.r.va2off(pool_va)
        return off, word

    def mutant(self, mutate, suffix=".elf"):
        data = bytearray(self.data)
        mutate(data)
        tf = tempfile.NamedTemporaryFile(suffix=suffix, delete=False)
        tf.write(data)
        tf.close()
        return tf.name

    def mutant_fails(self, path, func=None):
        other = Pair(self.mod, self.orig_path, path)
        return other.fails(func)


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    mod = load_audit()
    orig, cand = sys.argv[1], sys.argv[2]
    pair = Pair(mod, orig, cand)
    ok = True

    # --- clean candidate: server_loop must be clean -----------------------
    fails = pair.fails("server_loop")
    if fails:
        print("FAIL: clean candidate flags server_loop: %s" % (fails,))
        ok = False
    else:
        print("PASS: clean candidate - server_loop clean")

    # --- A: swap the two wide-string pool words ---------------------------
    conn = _wide_sites(pair, "connected")
    none = _wide_sites(pair, "none")
    if len(conn) != 1 or len(none) != 1:
        print("FAIL: expected one 'connected' and one 'none' pool site in "
              "server_loop, got %d/%d" % (len(conn), len(none)))
        return 1

    def swap_strings(data):
        a, b = conn[0][1], none[0][1]
        wa, wb = bytes(data[a:a + 4]), bytes(data[b:b + 4])
        data[a:a + 4], data[b:b + 4] = wb, wa

    path = pair.mutant(swap_strings)
    ok &= _expect(pair, path, "A pointer swap", ("server_loop",))
    os.unlink(path)

    # --- B: ninth character of L"connected" ------------------------------
    # utf-32le: 9th char = bytes 32..35 of the string object
    def ninth_char(data):
        soff = conn[0][2]
        before = bytes(data[soff + 32:soff + 36])
        assert before == b"d\x00\x00\x00", "unexpected 9th char bytes %r" % before
        data[soff + 32:soff + 36] = b"x\x00\x00\x00"

    path = pair.mutant(ninth_char)
    ok &= _expect(pair, path, "B ninth character", ("server_loop",))
    os.unlink(path)

    # --- C: function-pointer swap in sacd_input_setup --------------------
    def swap_function_pointers(data):
        a, _ = pair.site_file_offset("sacd_input_setup", 1)
        b, _ = pair.site_file_offset("sacd_input_setup", 5)
        wa, wb = bytes(data[a:a + 4]), bytes(data[b:b + 4])
        data[a:a + 4], data[b:b + 4] = wb, wa

    path = pair.mutant(swap_function_pointers)
    ok &= _expect(pair, path, "C function-pointer swap", ("sacd_input_setup",))
    os.unlink(path)

    # --- D: embedded-module boundary literal +4 --------------------------
    def bump_module_end(data):
        off, word = pair.site_file_offset("install_modules", 0)
        data[off:off + 4] = (word + 4).to_bytes(4, "little")

    path = pair.mutant(bump_module_end)
    ok &= _expect(pair, path, "D module-end literal", ("install_modules",))
    os.unlink(path)

    # --- E: embedded module blob byte flip -------------------------------
    blob_off, _ = pair.r.va2off(
        pair.r.sym_by_name["_binary_sacd_read_ko_start"])

    def flip_blob(data):
        data[blob_off + 0x100] ^= 0xff

    path = pair.mutant(flip_blob)
    module_ok, line = mod.check_module_blob(pair.o, mod.ELF(path))
    if module_ok:
        print("FAIL: E module blob mutation NOT flagged")
        ok = False
    else:
        print("PASS: E module blob mutation flagged (%s)" % line)
    os.unlink(path)

    print("REGRESSIONS:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


def _wide_sites(pair, want):
    """(pool_va, file offset, target file offset) of a wide-string site."""
    out = []
    for va, pool_va, word in pair.r.pool_loads(
            "server_loop", pair.r_funcs["server_loop"]):
        if pair.r.describe_word(word) != "wide:%r" % want:
            continue
        out.append((pool_va, pair.r.va2off(pool_va)[0],
                    pair.r.va2off(word)[0]))
    return out


def _expect(pair, path, label, functions):
    fails = pair.mutant_fails(path)
    hit = [f for f in fails if f[0] in functions]
    if hit:
        print("PASS: %s flagged: %s" % (label, hit[0][:3]))
        return True
    print("FAIL: %s NOT flagged" % label)
    return False


# --- pytest mode: the same semantics against the tracked ELFs ------------

def _pytest_pair():
    import pytest
    mod = load_audit()
    objdump = mod.OBJDUMP
    if not os.path.exists(objdump):
        pytest.skip("objdump backend missing: %s" % objdump)
    for p in (ORIG_ELF, RELEASE_ELF):
        if not os.path.exists(p):
            pytest.skip("ELF missing: %s" % p)
    return mod, Pair(mod, ORIG_ELF, RELEASE_ELF)


def test_release_candidate_has_no_literal_or_module_failures():
    mod, pair = _pytest_pair()
    assert pair.fails() == []
    ok, line = mod.check_module_blob(pair.o, pair.r)
    assert ok, line


def test_function_pointer_swap_is_flagged():
    mod, pair = _pytest_pair()

    def swap(data):
        a, _ = pair.site_file_offset("sacd_input_setup", 1)
        b, _ = pair.site_file_offset("sacd_input_setup", 5)
        wa, wb = bytes(data[a:a + 4]), bytes(data[b:b + 4])
        data[a:a + 4], data[b:b + 4] = wb, wa

    path = pair.mutant(swap)
    try:
        assert pair.mutant_fails(path, "sacd_input_setup"), \
            "function-pointer identity is not compared"
    finally:
        os.unlink(path)


def test_module_boundary_literal_and_blob_are_compared():
    mod, pair = _pytest_pair()

    def bump(data):
        off, word = pair.site_file_offset("install_modules", 0)
        data[off:off + 4] = (word + 4).to_bytes(4, "little")

    path = pair.mutant(bump)
    try:
        assert pair.mutant_fails(path, "install_modules"), \
            "the embedded-module end literal is not compared"
    finally:
        os.unlink(path)

    blob_off, _ = pair.r.va2off(
        pair.r.sym_by_name["_binary_sacd_read_ko_start"])

    def flip(data):
        data[blob_off + 0x100] ^= 0xff

    path = pair.mutant(flip)
    try:
        ok, line = mod.check_module_blob(pair.o, mod.ELF(path))
        assert not ok, "module blob bytes are not compared: %s" % line
    finally:
        os.unlink(path)


if __name__ == "__main__":
    sys.exit(main())
