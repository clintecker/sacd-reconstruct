#!/usr/bin/env python3
"""mt85_payload_extract.py -- command-ring payload field-map extractor for the
MT85xx gfxdriver wrappers (retail libdirectfb_mt85.so, BX510).

DECODE LANE tool (no VM): walks each wrapper function's llvm-objdump listing,
symbolically tracks register values and stack stores over the CFG (phi-merge
at joins), and emits per-wrapper payload field maps for the ring-item payloads
of contract section 3.1/3.2 (docs/mt85xx-fbdev-graphics-contract.md).

Determinism rules honored here (no hand-derivation):
  * literal-pool words : read from ELF section bytes via pyelftools
  * GOT slot symbols   : R_ARM_GLOB_DAT / JUMP_SLOT relocation table
  * strings            : GOT-base + signed literal word -> section bytes
  * assert expressions : __assert_fail(expr, file, line, fn) resolved args
  * all field offsets   : from tracked `str*` instruction operands

Values are expression tuples:
  ('imm', n)                 concrete immediate
  ('arg', i)                 wrapper argument i (ARG4 = first stack-passed arg)
  ('spoff', k)               register holds sp+k (payload-base candidate)
  ('gotbase', G)             GOT base address (add rX, pc, rY)
  ('sym', name)              &global   (ldr rX, [gotbase, imm] + reloc)
  ('mem', baseval, off)      *(base + off)
  ('deref', v)               *v
  ('abs', addr)              concrete address (non-string)
  ('str', s, addr)           address of printable string s
  ('alu', op, a, b)          unmodeled ALU result (rendered op(a,b))
  frozenset(...)             phi: any of these values

Usage:
  python3 mt85_payload_extract.py <libdirectfb_mt85.so> <objdump-listing> \
      0x22c0=mt85Blit,0x1f08=mt85StretchBlit,...

Window = [start, next prologue push{...,lr}) or [start, end-of-.text).
"""
import re
import sys
from collections import deque
from elftools.elf.elffile import ELFFile

LINE = re.compile(r'^\s*([0-9a-f]+):\s+([a-z]+)\s+(.*)$')
LABEL = re.compile(r'^([0-9a-f]+) <(.+)>:$')
COND = ('eq', 'ne', 'lt', 'gt', 'le', 'ge', 'hi', 'ls', 'hs', 'lo', 'cc',
        'cs', 'mi', 'pl', 'vc', 'vs')


def base_mnem(m):
    for c in COND:
        if m != c and m.endswith(c):
            return m[:-len(c)], True
    return m, False


class Sections:
    """File-byte access with vaddr->data spans + relocation symbol table."""

    def __init__(self, path):
        elf = ELFFile(open(path, 'rb'))
        self.spans = []
        for s in elf.iter_sections():
            if s.header['sh_type'] != 'SHT_NOBITS' and s.header['sh_addr']:
                self.spans.append((s.header['sh_addr'], s.data(), s.name))
        self.reloc = {}
        for s in elf.iter_sections():
            if s.header['sh_type'] in ('SHT_REL', 'SHT_RELA'):
                symtab = elf.get_section(s.header['sh_link'])
                for r in s.iter_relocations():
                    sym = symtab.get_symbol(r['r_info_sym'])
                    if sym.name:
                        self.reloc[r['r_offset']] = sym.name

    def word(self, addr):
        for base, data, _ in self.spans:
            if base <= addr < base + len(data) - 3:
                return int.from_bytes(data[addr - base:addr - base + 4], 'little')
        return None

    def string(self, addr, maxlen=220):
        for base, data, _ in self.spans:
            if base <= addr < base + len(data):
                off = addr - base
                chunk = data[off:off + maxlen]
                end = chunk.find(b'\0')
                if end == 0:
                    return None
                if end > 0:
                    chunk = chunk[:end]
                try:
                    s = chunk.decode('ascii')
                except UnicodeDecodeError:
                    return None
                if s and all(32 <= ord(c) < 127 or c in '\n\t' for c in s):
                    return s
        return None


def flatten(v):
    """Flatten nested phi sets for readable rendering."""
    if isinstance(v, frozenset):
        out = set()
        for x in v:
            out |= flatten(x) if isinstance(x, frozenset) else {x}
        return out
    return {v}


def render(v):
    if v is None:
        return '?'
    if isinstance(v, frozenset):
        vals = flatten(v)
        if len(vals) == 1:
            return render(next(iter(vals)))
        return '{' + '|'.join(sorted(render(x) for x in vals)) + '}'
    t = v[0]
    if t == 'imm':
        return '#%#x' % v[1] if v[1] > 9 or v[1] < 0 else '#%d' % v[1]
    if t == 'arg':
        return 'ARG%d' % v[1]
    if t == 'spoff':
        return 'sp+%#x' % v[1]
    if t == 'gotbase':
        return 'GOTBASE[%#x]' % v[1]
    if t == 'sym':
        return '&%s' % v[1]
    if t == 'mem':
        return '*(%s%s)' % (render(v[1]), '+%#x' % v[2] if v[2] else '')
    if t == 'deref':
        return '*(%s)' % render(v[1])
    if t == 'abs':
        return '%#x' % v[1]
    if t == 'str':
        return '"%s"@%#x' % (v[1], v[2])
    if t == 'data':
        init = v[2]
        return '*(DATA@%#x)' % v[1] + (', init=%#x' % init if init is not None else '')
    if t == 'alu':
        if v[3] is None:
            return '%s(%s)' % (v[1], render(v[2]))
        return '%s(%s,%s)' % (v[1], render(v[2]), render(v[3]))
    return repr(v)


def merge(a, b):
    if a == b:
        return a
    sa = a if isinstance(a, frozenset) else frozenset([a])
    sb = b if isinstance(b, frozenset) else frozenset([b])
    return sa | sb


def lift2(f, a, b):
    """Distribute a 2-arg concrete computation over phi sets.
    Returns None if any combination is non-concrete."""
    as_ = list(a) if isinstance(a, frozenset) else [a]
    bs_ = list(b) if isinstance(b, frozenset) else [b]
    outs = set()
    for x in as_:
        for y in bs_:
            r = f(x, y)
            if r is None:
                return None
            outs.add(r)
    return frozenset(outs) if len(outs) > 1 else (outs.pop() if outs else None)


def parse_listing(path):
    insns, plt = [], {}
    for line in open(path):
        lm = LABEL.match(line.strip())
        if lm:
            if lm.group(2).endswith('@plt'):
                plt[int(lm.group(1), 16)] = lm.group(2)
            continue
        m = LINE.match(line.rstrip('\n'))
        if m:
            ops = m.group(3).strip()
            # llvm-objdump appends "  @ 0xADDR <...>  @ imm = #..." annotations;
            # the first ' @ ' separates operands from the literal-pool note.
            ann = ''
            pos = ops.find(' @ ')
            if pos >= 0:
                ann = ops[pos:]
                ops = ops[:pos].strip()
            insns.append((int(m.group(1), 16), m.group(2), ops, ann))
    return insns, plt


MEMRE = re.compile(r'\[([a-z0-9]+)(?:,\s*(#-?(?:0x[0-9a-f]+|\d+)))?\]')
POSTRE = re.compile(r'\]\s*,\s*(#-?(?:0x[0-9a-f]+|\d+))\s*$')   # post-indexed [rX], #imm
IMMRE = re.compile(r'^#-?(?:0x[0-9a-f]+|\d+)$')


def immval(s):
    if s is None:
        return None
    s = s.strip().lstrip('#')
    try:
        n = int(s, 0)
        return n if n < 0x80000000 else n - 0x100000000
    except ValueError:
        return None


class Wrapper:
    def __init__(self, secs, insns, plt, start, name):
        self.secs, self.insns, self.plt = secs, insns, plt
        self.index = {a: i for i, (a, _, _, _) in enumerate(insns)}
        self.start, self.name = start, name
        self.end = self.find_end()
        self.push_n = 0
        self.sub_n = 0
        self.stack = {}       # sp offset -> (expr, defaddr, width)
        self.calls = []       # (addr, name, arg exprs list, sp0..sp3)
        self.stores = []      # (addr, spoff, width, expr) in CFG order
        self.payload = None   # (sp_base, length, defaddr)

    def find_end(self):
        i = self.index[self.start]
        for a, m, o, _ in self.insns[i + 1:]:
            if m.startswith('push') and 'lr' in o:
                return a
        return self.insns[-1][0] + 4

    # ---- value constructors -------------------------------------------------
    def mem(self, baseval, off):
        if baseval is None:
            return None
        if baseval[0] == 'gotbase':
            slot = baseval[1] + (off or 0)
            sym = self.secs.reloc.get(slot)
            if sym:
                return ('sym', sym)
            return ('abs', slot)
        if baseval[0] == 'sym':
            return ('mem', baseval, off)
        if baseval[0] == 'arg' or baseval[0] == 'mem' or baseval[0] == 'deref':
            return ('mem', baseval, off)
        if baseval[0] == 'str':
            return ('mem', baseval, off)
        return ('mem', baseval, off)

    # ---- main walk ------------------------------------------------------------
    def run(self):
        regs0 = {'r%d' % i: ('arg', i) for i in range(4)}
        seen = {}
        work = deque([(self.start, dict(regs0))])
        while work:
            pc, in_regs = work.popleft()
            prev = seen.get(pc)
            if prev is not None:
                merged = dict(prev)
                for k in in_regs:
                    if k in merged:
                        if merged[k] != in_regs[k]:
                            merged[k] = merge(merged[k], in_regs[k])
                    else:
                        merged[k] = in_regs[k]
                if merged == prev:
                    continue
                seen[pc] = merged
                regs = dict(merged)
            else:
                seen[pc] = dict(in_regs)
                regs = dict(in_regs)
            if pc not in self.index or not (self.start <= pc < self.end):
                continue
            i = self.index[pc]
            addr, mnem, ops, ann = self.insns[i]
            for npc in self.step(addr, mnem, ops, ann, regs):
                if self.start <= npc < self.end:
                    work.append((npc, regs))
        self.regs_at = seen

    def step(self, addr, mnem, ops, ann, regs):
        m, cond = base_mnem(mnem)
        insns = self.insns
        idx = self.index[addr]
        fall = insns[idx + 1][0] if idx + 1 < len(insns) else None
        parts = [p.strip() for p in ops.split(',')] if ops else []
        dst = parts[0] if parts else ''
        rest = parts[1:]
        succ = [fall] if fall is not None else []

        def g(r):
            return regs.get(r)

        def s(r, v):
            if v is None:
                regs.pop(r, None)
            else:
                regs[r] = v

        def sp_arg(k):
            # stack-passed args start at sp + push_n + sub_n
            base = 4 * self.push_n + self.sub_n
            return ('mem', ('spref',), base + k * 4)

        # prologue bookkeeping
        if m == 'push' and 'lr' in ops:
            self.push_n = len(re.findall(r'r\d+|lr', ops))
            return succ
        if m == 'pop':
            return []
        if m == 'sub' and dst == 'sp' and rest[:1] == ['sp']:
            v = immval(rest[1]) if len(rest) > 1 else 0
            if v:
                self.sub_n = v
            return succ
        if m in ('add', 'sub') and dst == 'sp':
            return succ

        if m in ('b', 'bl', 'blx') and not cond:
            tm = re.match(r'(0x[0-9a-f]+)', parts[0]) if parts else None
            tgt = int(tm.group(1), 16) if tm else None
            if m == 'b' and tgt is not None:
                return [tgt]
            if m in ('bl', 'blx'):
                self.record_call(addr, tgt, regs)
                if self.plt.get(tgt) == '__assert_fail@plt':
                    return []          # noreturn: kill the path (assert blocks)
                # ARM EABI: r0-r3, r12 are caller-saved; r0 holds the return
                # value after the call -- all become unknown.
                for r in ('r0', 'r1', 'r2', 'r3', 'r12'):
                    regs.pop(r, None)
                return succ
        if m == 'b' and cond:
            tm = re.match(r'(0x[0-9a-f]+)', parts[0]) if parts else None
            tgt = int(tm.group(1), 16) if tm else None
            if tgt is not None:
                return [fall, tgt]
            return [fall]
        if m in ('bx',):
            return []

        # loads: ldr/ldrb/ldrh rX, [rB, #off] | [pc, #i] @ A | [rB, rI]
        if m in ('ldr', 'ldrb', 'ldrh', 'ldrsb', 'ldrsh'):
            if '[pc' in ops:
                am = re.search(r'@\s*0x([0-9a-f]+)', ann)
                if am:
                    tgt = int(am.group(1), 16)
                    w = self.secs.word(tgt)
                    if w is not None:
                        # relocate the literal itself if a reloc sits on it
                        rn = self.secs.reloc.get(tgt)
                        if rn:
                            s(dst, ('sym', rn))
                        else:
                            s(dst, ('imm', w - (1 << 32) if w >= 0x80000000 else w))
                return succ
            # register-indexed first: [rB, rI] (no immediate -> MEMRE misses it)
            ridx = re.search(r'\[([a-z0-9]+),\s*(r\d+)\]', ops)
            if ridx:
                bv = g(ridx.group(1))
                iv = g(ridx.group(2))
                if (isinstance(bv, tuple) and bv[0] == 'gotbase'
                        and isinstance(iv, tuple) and iv[0] == 'imm'):
                    slot = bv[1] + iv[1]
                    sym = self.secs.reloc.get(slot)
                    if sym:
                        # relocated GOT slot: content == &symbol
                        s(dst, ('sym', sym))
                    else:
                        # non-relocated module-data word: content unknown at
                        # runtime; record the address (+ initial file content)
                        init = None
                        for sbase, sdata, sname in self.secs.spans:
                            if (sbase <= slot < sbase + len(sdata) - 3
                                    and 'bss' not in sname):
                                init = int.from_bytes(
                                    sdata[slot - sbase:slot - sbase + 4], 'little')
                                break
                        s(dst, ('data', slot, init))
                    return succ
                if (isinstance(bv, tuple) and bv[0] == 'spoff'
                        and isinstance(iv, tuple) and iv[0] == 'imm'):
                    off2 = bv[1] + iv[1]
                    if off2 in self.stack:
                        s(dst, self.stack[off2][0])
                    else:
                        s(dst, ('mem', ('spref',), off2))
                    return succ
                s(dst, ('mem', bv, 0) if bv else None)
                return succ
            mm = MEMRE.search(ops)
            if mm:
                base, off = mm.group(1), immval(mm.group(2)) or 0
                bv = g(base)
                if base == 'sp':
                    # stack load: resolve against stores, else wrapper stack args
                    # (ARG4+ live above the frame: push_n*4 + sub_n)
                    if off in self.stack:
                        s(dst, self.stack[off][0])
                    else:
                        fi = off - (4 * self.push_n + self.sub_n)
                        if fi >= 0 and fi % 4 == 0:
                            s(dst, ('arg', 4 + fi // 4))
                        else:
                            s(dst, ('mem', ('spref',), off))
                    return succ
                s(dst, self.mem(bv, off) if bv is not None else None)
                return succ
            s(dst, None)
            return succ

        # ldm variants: ldm/ldmia (offsets 0,4,...), ldmib (4,8,...)
        if m in ('ldm', 'ldmia', 'ldmib'):
            bv = g(dst)
            regs_list = re.findall(r'r\d+|lr', ','.join(rest))
            start = 4 if m == 'ldmib' else 0
            for k, rr in enumerate(regs_list):
                s(rr, self.mem(bv, start + 4 * k) if bv is not None else None)
            return succ

        # stores: str/strb/strh rX, [rB, #off] / post-indexed [rB], #imm
        if m in ('str', 'strb', 'strh'):
            mm = MEMRE.search(ops)
            if mm:
                base, off = mm.group(1), immval(mm.group(2)) or 0
                srcv = g(dst)
                width = {'str': 4, 'strb': 1, 'strh': 2}[m]
                post = POSTRE.search(ops)
                if base == 'sp':
                    self.record_store(addr, off, width, srcv)
                    return succ
                bv = g(base)
                if isinstance(bv, tuple) and bv[0] == 'spoff':
                    self.record_store(addr, bv[1] + off, width, srcv)
                    if post:
                        s(base, ('spoff', bv[1] + off + (immval(post.group(1)) or 0)))
                    return succ
                if isinstance(bv, tuple) and bv[0] == 'arg':
                    # store through arg pointer (device field updates)
                    return succ
                return succ
            return succ

        # mov rX, rY | mov rX, #imm
        if m in ('mov', 'movw'):
            if len(rest) == 1:
                if IMMRE.match(rest[0]):
                    v = immval(rest[0])
                    s(dst, ('imm', v))
                else:
                    s(dst, g(rest[0]))
            else:
                s(dst, None)
            return succ
        if m == 'movt':
            lo = g(dst)
            hi = immval(rest[0]) if rest else 0
            if isinstance(lo, tuple) and lo[0] == 'imm':
                s(dst, ('imm', (lo[1] & 0xffff) | ((hi & 0xffff) << 16)))
            else:
                s(dst, None)
            return succ
        if m == 'mvn':
            if rest and IMMRE.match(rest[0]):
                v = immval(rest[0])
                s(dst, ('imm', (~v) & 0xffffffff))
            else:
                v = g(rest[0]) if rest else None
                s(dst, ('alu', '~', v, None) if v is not None else None)
            return succ

        # add/sub rX, rY, {rZ | #imm | pc}
        if m in ('add', 'sub'):
            if len(rest) >= 1 and rest[0] == 'pc':
                # add rX, pc, rY  -> GOT base
                v = g(rest[1]) if len(rest) > 1 else None
                if isinstance(v, tuple) and v[0] == 'imm':
                    s(dst, ('gotbase', (addr + 8 + (v[1] if m == 'add' else -v[1])) & 0xffffffff))
                else:
                    s(dst, None)
                return succ
            if len(rest) >= 2:
                a, b = g(rest[0]), g(rest[1])
                # sp base forms: add rX, sp, #imm
                if rest[0] == 'sp':
                    v = immval(rest[1])
                    s(dst, ('spoff', v if v else 0))
                    return succ
                # GOT-relative string/abs: add rX, rB(gotbase), rY(imm)
                if isinstance(a, tuple) and isinstance(b, tuple) and (
                        {a[0], b[0]} & {'gotbase'}):

                    def g_add(x, y):
                        if not (isinstance(x, tuple) and isinstance(y, tuple)):
                            return None
                        g5 = x if x[0] == 'gotbase' else y
                        other = y if x[0] == 'gotbase' else x
                        if other[0] != 'imm':
                            return None
                        a2 = (g5[1] + other[1]) & 0xffffffff if m == 'add' else (g5[1] - other[1]) & 0xffffffff
                        st = self.secs.string(a2)
                        return ('str', st, a2) if st else ('abs', a2)

                    s(dst, lift2(g_add, a, b))
                    return succ
                if isinstance(a, tuple) and a[0] == 'imm' and isinstance(b, tuple) and b[0] == 'imm':
                    s(dst, ('imm', (a[1] + b[1]) if m == 'add' else (a[1] - b[1])))
                    return succ
                if len(rest) == 2 and IMMRE.match(rest[1]) and a is not None:
                    v = immval(rest[1])
                    if (isinstance(a, tuple) and a[0] == 'spoff') if isinstance(a, tuple) else False:
                        s(dst, lift2(lambda x, y: ('spoff', x[1] + (y[1] if m == 'add' else -y[1]))
                                     if isinstance(x, tuple) and x[0] == 'spoff' else None,
                                     a, ('imm', v)))
                        return succ
                    if (isinstance(a, tuple) and a[0] in ('abs', 'str')) if isinstance(a, tuple) else False:

                        def a_add(x, y):
                            if not (isinstance(x, tuple) and x[0] in ('abs', 'str')):
                                return None
                            a2 = (x[2 if x[0] == 'str' else 1] + (y[1] if m == 'add' else -y[1])) & 0xffffffff
                            st = self.secs.string(a2)
                            return ('str', st, a2) if st else ('abs', a2)

                        s(dst, lift2(a_add, a, ('imm', v)))
                        return succ
                    if a[0] == 'imm' if isinstance(a, tuple) else False:
                        s(dst, lift2(lambda x, y: ('imm', x[1] + (y[1] if m == 'add' else -y[1]))
                                     if isinstance(x, tuple) and x[0] == 'imm' else None,
                                     a, ('imm', v)))
                        return succ
                    s(dst, ('alu', m, a, ('imm', v)))
                    return succ
                if len(rest) == 2 and b is not None:
                    s(dst, ('alu', m, a, b))
                    return succ
            s(dst, None)
            return succ

        # orr/lsl/lsr/and/eor etc. -- keep as alu nodes
        if m in ('orr', 'and', 'eor', 'lsl', 'lsr', 'asr', 'mul', 'smlal'):
            a = g(rest[0]) if len(rest) > 0 and not IMMRE.match(rest[0]) else (('imm', immval(rest[0])) if rest else None)
            b = g(rest[1]) if len(rest) > 1 and not IMMRE.match(rest[1]) else (('imm', immval(rest[1])) if len(rest) > 1 else None)
            s(dst, ('alu', m, a, b) if a or b else None)
            return succ

        # cmp/cmn/tst/strd etc: no register dest
        return succ

    # ---- recorders -----------------------------------------------------------
    def record_store(self, addr, spoff, width, expr):
        if not hasattr(self, '_store_seen'):
            self._store_seen = {}
        key = (addr, spoff, width)
        seen = self._store_seen.setdefault(key, set())
        r = render(expr)
        if r == '?' and seen:
            return              # never let an unresolved revisit displace resolved
        if r in seen:
            return
        seen.add(r)
        self.stores.append((addr, spoff, width, expr))
        if r != '?':
            self.stack[spoff] = (expr, addr, width)

    def payload_rows(self, base, length):
        """Group payload stores: offset -> (width, set of exprs, addrs)."""
        rows = {}
        for (a, spoff, width, expr) in sorted(self.stores, key=lambda t: (t[1], t[0])):
            if not (base <= spoff < base + length):
                continue
            po = spoff - base
            r = rows.setdefault((po, width), [set(), []])
            if render(expr) != '?':
                r[0].add(render(expr))
            r[1].append(a)
        return rows

    def record_call(self, addr, tgt, regs):
        if tgt is None:
            return
        name = self.plt.get(tgt, '%#x' % tgt)
        args = [render(regs.get('r%d' % i)) for i in range(4)]
        spargs = [render(self.stack.get(k, (('mem', ('spref',), k), 0, 4))[0])
                  for k in (0, 4, 8, 12)]
        rec = (addr, name, args, spargs)
        for i, (a, n, ar, sp) in enumerate(self.calls):
            if a == addr and n == name:
                # keep the more-resolved record (fewer '?')
                if sum(x.count('?') for x in ar + sp) < sum(x.count('?') for x in args + spargs):
                    self.calls[i] = rec
                return
        self.calls.append(rec)
        if name == 'memset@plt':
            r0 = regs.get('r0')
            r2 = regs.get('r2')
            if (isinstance(r0, tuple) and r0[0] == 'spoff'
                    and isinstance(r2, tuple) and r2[0] == 'imm'):
                self.payload = (r0[1], r2[1], addr)

    # ---- report ---------------------------------------------------------------
    def report(self):
        out = []
        w = out.append
        w('=== %s @ %#x  (window %#x-%#x, frame: push %d regs, sub %#x) ==='
          % (self.name, self.start, self.start, self.end, self.push_n, self.sub_n))
        for (a, name, args, spargs) in sorted(self.calls):
            if name == 'memset@plt':
                w('  memset@%#x: dst=%s fill=%s len=%s' % (a, args[0], args[1], args[2]))
            elif name == '__assert_fail@plt':
                w('  ASSERT@%#x: expr=%s file=%s line=%s fn=%s'
                  % (a, args[0], args[1], args[2], args[3]))
            elif name in ('printf@plt', 'puts@plt'):
                w('  %s@%#x: fmt=%s args=%s stackargs=%s'
                  % (name.split('@')[0], a, args[0], args[1:4], spargs))
            elif tgt_is_emit(name):
                w('  EMIT@%#x: ctx=%s payload=%s cmd=%s flag=%s dev=%s'
                  % (a, args[0], args[1], args[2], args[3], spargs[0]))
            else:
                w('  call %s@%#x(%s) stack(%s)' % (name, a, ', '.join(args), ', '.join(spargs)))
        if self.payload:
            base, length, _ = self.payload
            w('  PAYLOAD base=sp+%#x len=%d  (payload offset = stack offset - %#x)'
              % (base, length, base))
            w('  --- field stores (payload-relative; {a|b} = path-dependent) ---')
            for (po, width), (exprs, addrs) in sorted(self.payload_rows(base, length).items()):
                vals = '|'.join(sorted(exprs)) if exprs else '?'
                if len(exprs) > 1:
                    vals = '{' + vals + '}'
                w('   +%#04x (%d B) <= %s   [@%s]'
                  % (po, width, vals, ','.join('%#x' % a for a in sorted(set(addrs)))))
            w('  --- stores outside payload region (frame fields / outgoing args) ---')
            for (a, spoff, width, expr) in sorted(self.stores, key=lambda t: (t[1], t[0])):
                if base <= spoff < base + length:
                    continue
                w('   sp+%#04x (%d B) <= %s   [@%#x]' % (spoff, width, render(expr), a))
        else:
            w('  (no memset-identified payload base; all stores below are sp-relative)')
            for (a, spoff, width, expr) in sorted(self.stores, key=lambda t: (t[1], t[0])):
                w('   sp+%#04x (%d B) <= %s   [@%#x]' % (spoff, width, render(expr), a))
        return '\n'.join(out)


def tgt_is_emit(name):
    return name == '0xf74'


def main():
    elf, listing, spec = sys.argv[1], sys.argv[2], sys.argv[3]
    secs = Sections(elf)
    insns, plt = parse_listing(listing)
    for item in spec.split(','):
        addr_s, rest = item.split('=')
        name, _, declen = rest.partition(':')
        w = Wrapper(secs, insns, plt, int(addr_s, 16), name)
        w.run()
        if w.payload is None and declen:
            # fallback: the EMIT call's payload-pointer argument as base
            for (a, n, args, sp) in w.calls:
                if tgt_is_emit(n):
                    pm = re.match(r'sp\+(0x[0-9a-f]+|\d+)$', args[1])
                    if pm:
                        w.payload = (int(pm.group(1), 0), int(declen), a)
                    break
        print(w.report())
        print()


if __name__ == '__main__':
    main()
