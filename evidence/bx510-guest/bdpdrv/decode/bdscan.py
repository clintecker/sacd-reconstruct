import struct, sys
from elftools.elf.elffile import ELFFile
import capstone
from capstone import arm as A
f=ELFFile(open('/tmp/bdpdrv/bdpdrv.ko','rb'))
st=f.get_section_by_name('.symtab')
syms=[]
for s in st.iter_symbols():
    if s.name and isinstance(s['st_shndx'],int):
        syms.append((s['st_value'], s.name, s['st_shndx'], s['st_size'], s['st_info']['type']))
md=capstone.Cs(capstone.CS_ARCH_ARM, capstone.CS_MODE_ARM|capstone.CS_MODE_LITTLE_ENDIAN); md.detail=True
sec=f.get_section_by_name('.text'); data=sec.data()
rel={}
r=f.get_section_by_name('.rel.text')
for rl in r.iter_relocations():
    rel[rl['r_offset']]=st.get_symbol(rl['r_info_sym']).name
funcs=sorted([(v,n,v+max(sz,1)) for (v,n,sh,sz,ty) in syms if sh==2 and ty=='STT_FUNC'])
def owner(o):
    for a,n,b in funcs:
        if a<=o<b: return n
    return None
# literal sites with target base
bases={}
pools=set()
for off in range(0,len(data)-3,4):
    g=list(md.disasm(data[off:off+4],off))
    if not g: continue
    ins=g[0]; ops=ins.operands
    if ins.mnemonic.startswith('ldr') and len(ops)==2 and ops[1].type==A.ARM_OP_MEM and ops[1].mem.base==A.ARM_REG_PC:
        ea=(ins.address+8+ops[1].mem.disp)&0xffffffff
        pools.add(ea)
        v=struct.unpack_from('<I',data,ea)[0]
        bases.setdefault(v,[]).append(ins.address)
want=int(sys.argv[1],16)
sites=bases.get(want,[])
print('literal sites for',hex(want),len(sites))
fns=sorted(set(filter(None,[owner(s) for s in sites])))
print('functions:',len(fns))
targets=sys.argv[2:] 
for fn in fns:
    cand=[(x,z) for x,y,z in funcs if x in [v for v,n,sh,sz,ty in syms if n==fn and sh==2]]
    if not cand: continue
    a,b=cand[0]
    regs={}
    hits=[]
    off=(a//4)*4
    while off<b:
        if off in pools: off+=4; continue
        g=list(md.disasm(data[off:off+4],off))
        off+=4
        if not g: regs={}; continue
        ins=g[0]; ops=ins.operands; mn=ins.mnemonic
        if mn.startswith('ldr') and len(ops)==2 and ops[1].type==A.ARM_OP_MEM and ops[1].mem.base==A.ARM_REG_PC:
            ea=(ins.address+8+ops[1].mem.disp)&0xffffffff
            regs[ops[0].reg]=struct.unpack_from('<I',data,ea)[0]
            continue
        if mn in ('mov','movw') and len(ops)==2 and ops[0].type==A.ARM_OP_REG and ops[1].type==A.ARM_OP_IMM:
            regs[ops[0].reg]=ops[1].imm; continue
        if mn.split('.')[0] in ('add','sub','orr','and','bic') and len(ops)==3 and ops[0].type==A.ARM_OP_REG and ops[1].type==A.ARM_OP_REG and ops[2].type==A.ARM_OP_IMM:
            if ops[1].reg in regs:
                v=regs[ops[1].reg]; i=ops[2].imm; bs=mn.split('.')[0]
                regs[ops[0].reg]={'add':v+i,'sub':v-i,'orr':v|i,'and':v&i,'bic':v&~i}[bs]&0xffffffff
            else: regs.pop(ops[0].reg,None)
            continue
        mem=None
        for o in ops:
            if o.type==A.ARM_OP_MEM: mem=o
        if mem is not None and mem.mem.base in regs:
            ea=(regs[mem.mem.base]+mem.mem.disp)&0xffffffff
            hits.append((ins.address,mn,ea))
        try: _,w=ins.regs_access()
        except Exception: w=[]
        for rr in w: regs.pop(rr,None)
    if hits:
        print('==',fn)
        for h in hits:
            if not targets or any(t in f"{h[2]:x}" for t in targets) or True:
                print(f"   0x{h[0]:06x} {h[1]:8s} ea=0x{h[2]:08x}")
