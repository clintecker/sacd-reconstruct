import struct, sys, json
from elftools.elf.elffile import ELFFile
import capstone
from capstone import arm as A

KO='/tmp/bdpdrv/sata_mt85xx_mod.ko'
f=ELFFile(open(KO,'rb'))
symtab=f.get_section_by_name('.symtab')
allsyms=[]
for s in symtab.iter_symbols():
    if s.name and isinstance(s['st_shndx'],int):
        allsyms.append((s['st_value'], s.name, s['st_shndx'], s['st_size'], s['st_info']['type']))

SECS=['.text','.init.text','.exit.text']
md=capstone.Cs(capstone.CS_ARCH_ARM, capstone.CS_MODE_ARM|capstone.CS_MODE_LITTLE_ENDIAN)
md.detail=True

def secdata(name):
    s=f.get_section_by_name(name)
    rel={}
    r=f.get_section_by_name('.rel'+name)
    if r:
        for rl in r.iter_relocations():
            rel[rl['r_offset']]=symtab.get_symbol(rl['r_info_sym']).name
    return s.data(), rel

def analyze(secname, verbose=False):
    data, rel = secdata(secname)
    idx = [ (n,sh,sz,ty) for (v,n,sh,sz,ty) in allsyms ]
    # function ranges in this section
    secidx = {'shndx': {'.text':1,'.init.text':3,'.exit.text':5}[secname]}['shndx']
    funcs=[]
    for (v,n,sh,sz,ty) in allsyms:
        if sh==secidx and ty=='STT_FUNC':
            funcs.append((v,n,v+max(sz,1)))
    funcs.sort()
    def owner(off):
        for (a,n,b) in funcs:
            if a<=off<b: return n
        return None
    # pool slots: addresses referenced by ldr pc-relative anywhere
    pools=set()
    for off in range(0, len(data)-3, 4):
        g=list(md.disasm(data[off:off+4], off))
        if not g: continue
        ins=g[0]; ops=ins.operands
        if ins.mnemonic.startswith('ldr') and len(ops)==2 and ops[1].type==A.ARM_OP_MEM and ops[1].mem.base==A.ARM_REG_PC:
            pools.add((ins.address+8+ops[1].mem.disp)&0xffffffff)
    regs={}
    out=[]
    for off in range(0, len(data)-3, 4):
        if off in pools:
            regs={}   # pool data, not code
            continue
        g=list(md.disasm(data[off:off+4], off))
        if not g: 
            regs={}
            continue
        ins=g[0]; ops=ins.operands; addr=ins.address; mn=ins.mnemonic
        fn=owner(addr)
        # literal load
        if mn.startswith('ldr') and len(ops)==2 and ops[1].type==A.ARM_OP_MEM and ops[1].mem.base==A.ARM_REG_PC:
            ea=(addr+8+ops[1].mem.disp)&0xffffffff
            if ea+4<=len(data):
                val=struct.unpack_from('<I',data,ea)[0]
                regs[ops[0].reg]=('lit',val,rel.get(ea),ea)
            continue
        if mn in ('mov','movw') and len(ops)==2 and ops[0].type==A.ARM_OP_REG and ops[1].type==A.ARM_OP_IMM:
            regs[ops[0].reg]=('const',ops[1].imm,None,None)
            continue
        if mn=='movt' and len(ops)==2 and ops[0].type==A.ARM_OP_REG and ops[1].type==A.ARM_OP_IMM:
            old=regs.get(ops[0].reg)
            if old and old[0]=='const':
                regs[ops[0].reg]=('const',((ops[1].imm<<16)|(old[1]&0xffff))&0xffffffff,None,None)
            else:
                regs.pop(ops[0].reg,None)
            continue
        if mn in ('add','sub','orr','and','bic','eor','adds','subs') and len(ops)==3 and ops[0].type==A.ARM_OP_REG and ops[1].type==A.ARM_OP_REG and ops[2].type==A.ARM_OP_IMM:
            src=regs.get(ops[1].reg)
            if src and src[0] in ('const','lit'):
                v=src[1]; i=ops[2].imm
                nv = v+i if mn.startswith('add') else v-i if mn.startswith('sub') else v|i if mn=='orr' else v&i if mn=='and' else v&~i if mn=='bic' else v^i
                regs[ops[0].reg]=('const',nv&0xffffffff,None,None)
            else:
                regs.pop(ops[0].reg,None)
            continue
        if mn in ('lsl','lsr','asr') and len(ops)==3 and ops[2].type==A.ARM_OP_IMM and ops[1].type==A.ARM_OP_REG:
            src=regs.get(ops[1].reg)
            if src and src[0]=='const':
                sh=ops[2].imm
                v=src[1]
                nv = (v<<sh)&0xffffffff if mn=='lsl' else v>>sh if mn=='lsr' else v>>sh
                regs[ops[0].reg]=('const',nv,None,None)
            else: regs.pop(ops[0].reg,None)
            continue
        # memory access with base reg
        if len(ops)>=1 and ops[0].type==A.ARM_OP_MEM:
            base=ops[0].mem.base; disp=ops[0].mem.disp
            src=regs.get(base)
            sz=1 if mn.startswith('strb') or mn.startswith('ldrb') else 2 if mn.startswith('strh') or mn.startswith('ldrh') else 4
            if src and src[0] in ('const','lit'):
                ea=((src[1] if src[0]=='const' else 0)+disp)&0xffffffff
                # access with a symbol-relative base (lit with reloc symbol) -> resolve later
                out.append(dict(sec=secname, site=addr, fn=fn, mn=mn, rw='R' if mn.startswith('ldr') else 'W',
                                ea=ea, sz=sz, base=src[1], sym=src[2], poolea=src[3]))
        # invalidate written regs
        try:
            _,w=ins.regs_access()
        except Exception:
            w=[]
        for r in w:
            if not (mn.startswith('ldr') and len(ops)==2 and ops[1].type==A.ARM_OP_MEM and ops[1].mem.base==A.ARM_REG_PC):
                regs.pop(r,None)
    return out

if __name__=='__main__':
    allout=[]
    for s in SECS:
        allout += analyze(s)
    # filter to plausible MMIO (kernel VA device space or symbol-relative)
    keep=[o for o in allout if (0xfd000000<=o['ea']<=0xfe0fffff) or o['sym']]
    print(len(allout),'accesses;',len(keep),'kept')
    for o in sorted(keep,key=lambda o:(o['fn'] or '', o['site'])):
        print(f"{o['fn'] or '?':45s} 0x{o['site']:05x} {o['rw']} {o['mn']:6s} ea=0x{o['ea']:08x} sz{o['sz']} sym={o['sym']}")
