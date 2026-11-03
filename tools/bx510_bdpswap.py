"""Swap a tail-marker symbol into the LAST symtab entry of a .ko.

Sony's 2.6.35 module loader drops the last symtab entry of every module
from kallsyms (layout_symtab/add_kallsyms off-by-one: 'for (ndst = i = 1;
i < nsrc; ++i, ++src)' starting src at index 0 examines 0..nsrc-2).
Swap two fixed-size Elf32_Sym entries so the victim is a marker we don't
care about. Symtab order is semantically neutral here (no duplicates).
"""
import struct
import sys

path, marker = sys.argv[1], sys.argv[2].encode()
data = bytearray(open(path, 'rb').read())

e_shoff, = struct.unpack_from('<I', data, 0x20)
e_shentsize, e_shnum, e_shstrndx = struct.unpack_from('<HHH', data, 0x2e)
sh = lambda i: data[e_shoff + i * e_shentsize: e_shoff + (i + 1) * e_shentsize]
def field(i, off, n=4):
    return struct.unpack_from('<I', data, e_shoff + i * e_shentsize + off)[0]
strtab_off = field(e_shstrndx, 0x10)
def name(i):
    off, = struct.unpack_from('<I', sh(i), 0)
    end = data.index(b'\0', strtab_off + off)
    return bytes(data[strtab_off + off:end])

symtab = None
for i in range(e_shnum):
    if name(i) == b'.symtab':
        symtab = i
        break
assert symtab is not None, 'no .symtab'
sym_off, sym_size = field(symtab, 0x10), field(symtab, 0x14)
strtab_i, = struct.unpack_from('<I', sh(symtab), 0x18)
str_off = field(strtab_i, 0x10)

def sym_name(idx):
    st_name, = struct.unpack_from('<I', data, sym_off + idx * 16)
    end = data.index(b'\0', str_off + st_name)
    return bytes(data[str_off + st_name:end])

count = sym_size // 16
last = count - 1
if sym_name(last) == marker:
    print('marker already last; nothing to do')
    raise SystemExit(0)
midx = None
for idx in range(count):
    if sym_name(idx) == marker:
        midx = idx
        break
assert midx is not None, f'marker {marker} not found'
a, b = sym_off + midx * 16, sym_off + last * 16
data[a:a + 16], data[b:b + 16] = data[b:b + 16], data[a:a + 16]
open(path, 'wb').write(bytes(data))
print(f'swapped entry {midx} ({marker.decode()}) with last entry {last} ({sym_name(midx).decode()})')
