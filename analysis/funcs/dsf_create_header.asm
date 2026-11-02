0002ed50 <dsf_create_header>:
   2ed50: e92d4830     	push	{r4, r5, r11, lr}
   2ed54: e28db00c     	add	r11, sp, #12
   2ed58: e24dd028     	sub	sp, sp, #40
   2ed5c: e50b0030     	str	r0, [r11, #-0x30]
   2ed60: e51b3030     	ldr	r3, [r11, #-0x30]
   2ed64: e5933168     	ldr	r3, [r3, #0x168]
   2ed68: e50b3020     	str	r3, [r11, #-0x20]
   2ed6c: e51b3030     	ldr	r3, [r11, #-0x30]
   2ed70: e593305c     	ldr	r3, [r3, #0x5c]
   2ed74: e50b301c     	str	r3, [r11, #-0x1c]
   2ed78: e51b301c     	ldr	r3, [r11, #-0x1c]
   2ed7c: e5933000     	ldr	r3, [r3]
   2ed80: e3530000     	cmp	r3, #0
   2ed84: 1a000006     	bne	0x2eda4 <dsf_create_header+0x54> @ imm = #0x18
   2ed88: e3a00b02     	mov	r0, #2048
   2ed8c: e3a01001     	mov	r1, #1
   2ed90: ebff7571     	bl	0xc35c <calloc@plt>     @ imm = #-0x22a3c
   2ed94: e1a03000     	mov	r3, r0
   2ed98: e1a02003     	mov	r2, r3
   2ed9c: e51b301c     	ldr	r3, [r11, #-0x1c]
   2eda0: e5832000     	str	r2, [r3]
   2eda4: e51b301c     	ldr	r3, [r11, #-0x1c]
   2eda8: e5933008     	ldr	r3, [r3, #0x8]
   2edac: e3530000     	cmp	r3, #0
   2edb0: 1a000006     	bne	0x2edd0 <dsf_create_header+0x80> @ imm = #0x18
   2edb4: e3a00b02     	mov	r0, #2048
   2edb8: e3a01001     	mov	r1, #1
   2edbc: ebff7566     	bl	0xc35c <calloc@plt>     @ imm = #-0x22a68
   2edc0: e1a03000     	mov	r3, r0
   2edc4: e1a02003     	mov	r2, r3
   2edc8: e51b301c     	ldr	r3, [r11, #-0x1c]
   2edcc: e5832008     	str	r2, [r3, #0x8]
   2edd0: e51b301c     	ldr	r3, [r11, #-0x1c]
   2edd4: e3a02000     	mov	r2, #0
   2edd8: e5832004     	str	r2, [r3, #0x4]
   2eddc: e51b301c     	ldr	r3, [r11, #-0x1c]
   2ede0: e3a02000     	mov	r2, #0
   2ede4: e583200c     	str	r2, [r3, #0xc]
   2ede8: e51b301c     	ldr	r3, [r11, #-0x1c]
   2edec: e5933000     	ldr	r3, [r3]
   2edf0: e50b3024     	str	r3, [r11, #-0x24]
   2edf4: e51b301c     	ldr	r3, [r11, #-0x1c]
   2edf8: e5933000     	ldr	r3, [r3]
   2edfc: e50b3028     	str	r3, [r11, #-0x28]
   2ee00: e51b3028     	ldr	r3, [r11, #-0x28]
   2ee04: e3a02000     	mov	r2, #0
   2ee08: e3822044     	orr	r2, r2, #68
   2ee0c: e5c32000     	strb	r2, [r3]
   2ee10: e3a02000     	mov	r2, #0
   2ee14: e3822053     	orr	r2, r2, #83
   2ee18: e5c32001     	strb	r2, [r3, #0x1]
   2ee1c: e3a02000     	mov	r2, #0
   2ee20: e3822044     	orr	r2, r2, #68
   2ee24: e5c32002     	strb	r2, [r3, #0x2]
   2ee28: e3a02000     	mov	r2, #0
   2ee2c: e3822020     	orr	r2, r2, #32
   2ee30: e5c32003     	strb	r2, [r3, #0x3]
   2ee34: e51b3028     	ldr	r3, [r11, #-0x28]
   2ee38: e3a02000     	mov	r2, #0
   2ee3c: e382201c     	orr	r2, r2, #28
   2ee40: e5c32004     	strb	r2, [r3, #0x4]
   2ee44: e3a02000     	mov	r2, #0
   2ee48: e5c32005     	strb	r2, [r3, #0x5]
   2ee4c: e3a02000     	mov	r2, #0
   2ee50: e5c32006     	strb	r2, [r3, #0x6]
   2ee54: e3a02000     	mov	r2, #0
   2ee58: e5c32007     	strb	r2, [r3, #0x7]
   2ee5c: e3a02000     	mov	r2, #0
   2ee60: e5c32008     	strb	r2, [r3, #0x8]
   2ee64: e3a02000     	mov	r2, #0
   2ee68: e5c32009     	strb	r2, [r3, #0x9]
   2ee6c: e3a02000     	mov	r2, #0
   2ee70: e5c3200a     	strb	r2, [r3, #0xa]
   2ee74: e3a02000     	mov	r2, #0
   2ee78: e5c3200b     	strb	r2, [r3, #0xb]
   2ee7c: e51b301c     	ldr	r3, [r11, #-0x1c]
   2ee80: e5933004     	ldr	r3, [r3, #0x4]
   2ee84: e283201c     	add	r2, r3, #28
   2ee88: e51b301c     	ldr	r3, [r11, #-0x1c]
   2ee8c: e5832004     	str	r2, [r3, #0x4]
   2ee90: e51b301c     	ldr	r3, [r11, #-0x1c]
   2ee94: e5933000     	ldr	r3, [r3]
   2ee98: e283301c     	add	r3, r3, #28
   2ee9c: e50b3024     	str	r3, [r11, #-0x24]
   2eea0: e51b3024     	ldr	r3, [r11, #-0x24]
   2eea4: e50b3018     	str	r3, [r11, #-0x18]
   2eea8: e51b3030     	ldr	r3, [r11, #-0x30]
   2eeac: e5932000     	ldr	r2, [r3]
   2eeb0: e51b1020     	ldr	r1, [r11, #-0x20]
   2eeb4: e3a03060     	mov	r3, #96
   2eeb8: e59f06ec     	ldr	r0, [pc, #0x6ec]        @ 0x2f5ac <dsf_create_header+0x85c>
   2eebc: e0020290     	mul	r2, r0, r2
   2eec0: e0812002     	add	r2, r1, r2
   2eec4: e0823003     	add	r3, r2, r3
   2eec8: e5933000     	ldr	r3, [r3]
   2eecc: e50b3014     	str	r3, [r11, #-0x14]
   2eed0: e51b3018     	ldr	r3, [r11, #-0x18]
   2eed4: e3a02000     	mov	r2, #0
   2eed8: e3822066     	orr	r2, r2, #102
   2eedc: e5c32000     	strb	r2, [r3]
   2eee0: e3a02000     	mov	r2, #0
   2eee4: e382206d     	orr	r2, r2, #109
   2eee8: e5c32001     	strb	r2, [r3, #0x1]
   2eeec: e3a02000     	mov	r2, #0
   2eef0: e3822074     	orr	r2, r2, #116
   2eef4: e5c32002     	strb	r2, [r3, #0x2]
   2eef8: e3a02000     	mov	r2, #0
   2eefc: e3822020     	orr	r2, r2, #32
   2ef00: e5c32003     	strb	r2, [r3, #0x3]
   2ef04: e51b3018     	ldr	r3, [r11, #-0x18]
   2ef08: e3a02000     	mov	r2, #0
   2ef0c: e3822034     	orr	r2, r2, #52
   2ef10: e5c32004     	strb	r2, [r3, #0x4]
   2ef14: e3a02000     	mov	r2, #0
   2ef18: e5c32005     	strb	r2, [r3, #0x5]
   2ef1c: e3a02000     	mov	r2, #0
   2ef20: e5c32006     	strb	r2, [r3, #0x6]
   2ef24: e3a02000     	mov	r2, #0
   2ef28: e5c32007     	strb	r2, [r3, #0x7]
   2ef2c: e3a02000     	mov	r2, #0
   2ef30: e5c32008     	strb	r2, [r3, #0x8]
   2ef34: e3a02000     	mov	r2, #0
   2ef38: e5c32009     	strb	r2, [r3, #0x9]
   2ef3c: e3a02000     	mov	r2, #0
   2ef40: e5c3200a     	strb	r2, [r3, #0xa]
   2ef44: e3a02000     	mov	r2, #0
   2ef48: e5c3200b     	strb	r2, [r3, #0xb]
   2ef4c: e51b3018     	ldr	r3, [r11, #-0x18]
   2ef50: e3a02000     	mov	r2, #0
   2ef54: e3822001     	orr	r2, r2, #1
   2ef58: e5c3200c     	strb	r2, [r3, #0xc]
   2ef5c: e3a02000     	mov	r2, #0
   2ef60: e5c3200d     	strb	r2, [r3, #0xd]
   2ef64: e3a02000     	mov	r2, #0
   2ef68: e5c3200e     	strb	r2, [r3, #0xe]
   2ef6c: e3a02000     	mov	r2, #0
   2ef70: e5c3200f     	strb	r2, [r3, #0xf]
   2ef74: e51b3018     	ldr	r3, [r11, #-0x18]
   2ef78: e3a02000     	mov	r2, #0
   2ef7c: e5c32010     	strb	r2, [r3, #0x10]
   2ef80: e3a02000     	mov	r2, #0
   2ef84: e5c32011     	strb	r2, [r3, #0x11]
   2ef88: e3a02000     	mov	r2, #0
   2ef8c: e5c32012     	strb	r2, [r3, #0x12]
   2ef90: e3a02000     	mov	r2, #0
   2ef94: e5c32013     	strb	r2, [r3, #0x13]
   2ef98: e51b3014     	ldr	r3, [r11, #-0x14]
   2ef9c: e5d33020     	ldrb	r3, [r3, #0x20]
   2efa0: e3530002     	cmp	r3, #2
   2efa4: 1a00000f     	bne	0x2efe8 <dsf_create_header+0x298> @ imm = #0x3c
   2efa8: e51b3014     	ldr	r3, [r11, #-0x14]
   2efac: e5d33021     	ldrb	r3, [r3, #0x21]
   2efb0: e2033007     	and	r3, r3, #7
   2efb4: e3530000     	cmp	r3, #0
   2efb8: 1a00000a     	bne	0x2efe8 <dsf_create_header+0x298> @ imm = #0x28
   2efbc: e51b3018     	ldr	r3, [r11, #-0x18]
   2efc0: e3a02000     	mov	r2, #0
   2efc4: e3822002     	orr	r2, r2, #2
   2efc8: e5c32014     	strb	r2, [r3, #0x14]
   2efcc: e3a02000     	mov	r2, #0
   2efd0: e5c32015     	strb	r2, [r3, #0x15]
   2efd4: e3a02000     	mov	r2, #0
   2efd8: e5c32016     	strb	r2, [r3, #0x16]
   2efdc: e3a02000     	mov	r2, #0
   2efe0: e5c32017     	strb	r2, [r3, #0x17]
   2efe4: ea000031     	b	0x2f0b0 <dsf_create_header+0x360> @ imm = #0xc4
   2efe8: e51b3014     	ldr	r3, [r11, #-0x14]
   2efec: e5d33020     	ldrb	r3, [r3, #0x20]
   2eff0: e3530005     	cmp	r3, #5
   2eff4: 1a00000f     	bne	0x2f038 <dsf_create_header+0x2e8> @ imm = #0x3c
   2eff8: e51b3014     	ldr	r3, [r11, #-0x14]
   2effc: e5d33021     	ldrb	r3, [r3, #0x21]
   2f000: e2033007     	and	r3, r3, #7
   2f004: e3530003     	cmp	r3, #3
   2f008: 1a00000a     	bne	0x2f038 <dsf_create_header+0x2e8> @ imm = #0x28
   2f00c: e51b3018     	ldr	r3, [r11, #-0x18]
   2f010: e3a02000     	mov	r2, #0
   2f014: e3822006     	orr	r2, r2, #6
   2f018: e5c32014     	strb	r2, [r3, #0x14]
   2f01c: e3a02000     	mov	r2, #0
   2f020: e5c32015     	strb	r2, [r3, #0x15]
   2f024: e3a02000     	mov	r2, #0
   2f028: e5c32016     	strb	r2, [r3, #0x16]
   2f02c: e3a02000     	mov	r2, #0
   2f030: e5c32017     	strb	r2, [r3, #0x17]
   2f034: ea00001d     	b	0x2f0b0 <dsf_create_header+0x360> @ imm = #0x74
   2f038: e51b3014     	ldr	r3, [r11, #-0x14]
   2f03c: e5d33020     	ldrb	r3, [r3, #0x20]
   2f040: e3530006     	cmp	r3, #6
   2f044: 1a00000f     	bne	0x2f088 <dsf_create_header+0x338> @ imm = #0x3c
   2f048: e51b3014     	ldr	r3, [r11, #-0x14]
   2f04c: e5d33021     	ldrb	r3, [r3, #0x21]
   2f050: e2033007     	and	r3, r3, #7
   2f054: e3530004     	cmp	r3, #4
   2f058: 1a00000a     	bne	0x2f088 <dsf_create_header+0x338> @ imm = #0x28
   2f05c: e51b3018     	ldr	r3, [r11, #-0x18]
   2f060: e3a02000     	mov	r2, #0
   2f064: e3822007     	orr	r2, r2, #7
   2f068: e5c32014     	strb	r2, [r3, #0x14]
   2f06c: e3a02000     	mov	r2, #0
   2f070: e5c32015     	strb	r2, [r3, #0x15]
   2f074: e3a02000     	mov	r2, #0
   2f078: e5c32016     	strb	r2, [r3, #0x16]
   2f07c: e3a02000     	mov	r2, #0
   2f080: e5c32017     	strb	r2, [r3, #0x17]
   2f084: ea000009     	b	0x2f0b0 <dsf_create_header+0x360> @ imm = #0x24
   2f088: e51b3018     	ldr	r3, [r11, #-0x18]
   2f08c: e3a02000     	mov	r2, #0
   2f090: e3822002     	orr	r2, r2, #2
   2f094: e5c32014     	strb	r2, [r3, #0x14]
   2f098: e3a02000     	mov	r2, #0
   2f09c: e5c32015     	strb	r2, [r3, #0x15]
   2f0a0: e3a02000     	mov	r2, #0
   2f0a4: e5c32016     	strb	r2, [r3, #0x16]
   2f0a8: e3a02000     	mov	r2, #0
   2f0ac: e5c32017     	strb	r2, [r3, #0x17]
   2f0b0: e51b3014     	ldr	r3, [r11, #-0x14]
   2f0b4: e5d33020     	ldrb	r3, [r3, #0x20]
   2f0b8: e1a02003     	mov	r2, r3
   2f0bc: e51b3018     	ldr	r3, [r11, #-0x18]
   2f0c0: e20210ff     	and	r1, r2, #255
   2f0c4: e3a00000     	mov	r0, #0
   2f0c8: e1801001     	orr	r1, r0, r1
   2f0cc: e5c31018     	strb	r1, [r3, #0x18]
   2f0d0: e1a01422     	lsr	r1, r2, #8
   2f0d4: e20110ff     	and	r1, r1, #255
   2f0d8: e3a00000     	mov	r0, #0
   2f0dc: e1801001     	orr	r1, r0, r1
   2f0e0: e5c31019     	strb	r1, [r3, #0x19]
   2f0e4: e1a01822     	lsr	r1, r2, #16
   2f0e8: e20110ff     	and	r1, r1, #255
   2f0ec: e3a00000     	mov	r0, #0
   2f0f0: e1801001     	orr	r1, r0, r1
   2f0f4: e5c3101a     	strb	r1, [r3, #0x1a]
   2f0f8: e1a02c22     	lsr	r2, r2, #24
   2f0fc: e3a01000     	mov	r1, #0
   2f100: e1812002     	orr	r2, r1, r2
   2f104: e5c3201b     	strb	r2, [r3, #0x1b]
   2f108: e51b3018     	ldr	r3, [r11, #-0x18]
   2f10c: e3a02000     	mov	r2, #0
   2f110: e5c3201c     	strb	r2, [r3, #0x1c]
   2f114: e3a02000     	mov	r2, #0
   2f118: e3822011     	orr	r2, r2, #17
   2f11c: e5c3201d     	strb	r2, [r3, #0x1d]
   2f120: e3a02000     	mov	r2, #0
   2f124: e382202b     	orr	r2, r2, #43
   2f128: e5c3201e     	strb	r2, [r3, #0x1e]
   2f12c: e3a02000     	mov	r2, #0
   2f130: e5c3201f     	strb	r2, [r3, #0x1f]
   2f134: e51b3018     	ldr	r3, [r11, #-0x18]
   2f138: e3a02000     	mov	r2, #0
   2f13c: e3822001     	orr	r2, r2, #1
   2f140: e5c32020     	strb	r2, [r3, #0x20]
   2f144: e3a02000     	mov	r2, #0
   2f148: e5c32021     	strb	r2, [r3, #0x21]
   2f14c: e3a02000     	mov	r2, #0
   2f150: e5c32022     	strb	r2, [r3, #0x22]
   2f154: e3a02000     	mov	r2, #0
   2f158: e5c32023     	strb	r2, [r3, #0x23]
   2f15c: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f160: e1c302d0     	ldrd	r0, r1, [r3, #32]
   2f164: e51b3014     	ldr	r3, [r11, #-0x14]
   2f168: e5d33020     	ldrb	r3, [r3, #0x20]
   2f16c: e20320ff     	and	r2, r3, #255
   2f170: e3a03000     	mov	r3, #0
   2f174: eb000787     	bl	0x30f98 <__aeabi_uldivmod> @ imm = #0x1e1c
   2f178: e1a02000     	mov	r2, r0
   2f17c: e1a03001     	mov	r3, r1
   2f180: e1a01ea2     	lsr	r1, r2, #29
   2f184: e1a05183     	lsl	r5, r3, #3
   2f188: e1815005     	orr	r5, r1, r5
   2f18c: e1a04182     	lsl	r4, r2, #3
   2f190: e51b3018     	ldr	r3, [r11, #-0x18]
   2f194: e20420ff     	and	r2, r4, #255
   2f198: e3a01000     	mov	r1, #0
   2f19c: e1812002     	orr	r2, r1, r2
   2f1a0: e5c32024     	strb	r2, [r3, #0x24]
   2f1a4: e1a02424     	lsr	r2, r4, #8
   2f1a8: e20220ff     	and	r2, r2, #255
   2f1ac: e3a01000     	mov	r1, #0
   2f1b0: e1812002     	orr	r2, r1, r2
   2f1b4: e5c32025     	strb	r2, [r3, #0x25]
   2f1b8: e1a02824     	lsr	r2, r4, #16
   2f1bc: e20220ff     	and	r2, r2, #255
   2f1c0: e3a01000     	mov	r1, #0
   2f1c4: e1812002     	orr	r2, r1, r2
   2f1c8: e5c32026     	strb	r2, [r3, #0x26]
   2f1cc: e1a02c24     	lsr	r2, r4, #24
   2f1d0: e3a01000     	mov	r1, #0
   2f1d4: e1812002     	orr	r2, r1, r2
   2f1d8: e5c32027     	strb	r2, [r3, #0x27]
   2f1dc: e20520ff     	and	r2, r5, #255
   2f1e0: e3a01000     	mov	r1, #0
   2f1e4: e1812002     	orr	r2, r1, r2
   2f1e8: e5c32028     	strb	r2, [r3, #0x28]
   2f1ec: e1a02425     	lsr	r2, r5, #8
   2f1f0: e20220ff     	and	r2, r2, #255
   2f1f4: e3a01000     	mov	r1, #0
   2f1f8: e1812002     	orr	r2, r1, r2
   2f1fc: e5c32029     	strb	r2, [r3, #0x29]
   2f200: e1a02825     	lsr	r2, r5, #16
   2f204: e20220ff     	and	r2, r2, #255
   2f208: e3a01000     	mov	r1, #0
   2f20c: e1812002     	orr	r2, r1, r2
   2f210: e5c3202a     	strb	r2, [r3, #0x2a]
   2f214: e1a02c25     	lsr	r2, r5, #24
   2f218: e3a01000     	mov	r1, #0
   2f21c: e1812002     	orr	r2, r1, r2
   2f220: e5c3202b     	strb	r2, [r3, #0x2b]
   2f224: e51b3018     	ldr	r3, [r11, #-0x18]
   2f228: e3a02000     	mov	r2, #0
   2f22c: e5c3202c     	strb	r2, [r3, #0x2c]
   2f230: e3a02000     	mov	r2, #0
   2f234: e3822010     	orr	r2, r2, #16
   2f238: e5c3202d     	strb	r2, [r3, #0x2d]
   2f23c: e3a02000     	mov	r2, #0
   2f240: e5c3202e     	strb	r2, [r3, #0x2e]
   2f244: e3a02000     	mov	r2, #0
   2f248: e5c3202f     	strb	r2, [r3, #0x2f]
   2f24c: e51b3018     	ldr	r3, [r11, #-0x18]
   2f250: e3a02000     	mov	r2, #0
   2f254: e5c32030     	strb	r2, [r3, #0x30]
   2f258: e3a02000     	mov	r2, #0
   2f25c: e5c32031     	strb	r2, [r3, #0x31]
   2f260: e3a02000     	mov	r2, #0
   2f264: e5c32032     	strb	r2, [r3, #0x32]
   2f268: e3a02000     	mov	r2, #0
   2f26c: e5c32033     	strb	r2, [r3, #0x33]
   2f270: e51b3014     	ldr	r3, [r11, #-0x14]
   2f274: e5d33020     	ldrb	r3, [r3, #0x20]
   2f278: e1a02003     	mov	r2, r3
   2f27c: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f280: e5832018     	str	r2, [r3, #0x18]
   2f284: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f288: e5933004     	ldr	r3, [r3, #0x4]
   2f28c: e2832034     	add	r2, r3, #52
   2f290: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f294: e5832004     	str	r2, [r3, #0x4]
   2f298: e51b3024     	ldr	r3, [r11, #-0x24]
   2f29c: e2833034     	add	r3, r3, #52
   2f2a0: e50b3024     	str	r3, [r11, #-0x24]
   2f2a4: e51b3024     	ldr	r3, [r11, #-0x24]
   2f2a8: e50b3010     	str	r3, [r11, #-0x10]
   2f2ac: e51b3010     	ldr	r3, [r11, #-0x10]
   2f2b0: e3a02000     	mov	r2, #0
   2f2b4: e3822064     	orr	r2, r2, #100
   2f2b8: e5c32000     	strb	r2, [r3]
   2f2bc: e3a02000     	mov	r2, #0
   2f2c0: e3822061     	orr	r2, r2, #97
   2f2c4: e5c32001     	strb	r2, [r3, #0x1]
   2f2c8: e3a02000     	mov	r2, #0
   2f2cc: e3822074     	orr	r2, r2, #116
   2f2d0: e5c32002     	strb	r2, [r3, #0x2]
   2f2d4: e3a02000     	mov	r2, #0
   2f2d8: e3822061     	orr	r2, r2, #97
   2f2dc: e5c32003     	strb	r2, [r3, #0x3]
   2f2e0: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f2e4: e1c301d0     	ldrd	r0, r1, [r3, #16]
   2f2e8: e3a0200c     	mov	r2, #12
   2f2ec: e3a03000     	mov	r3, #0
   2f2f0: e0922000     	adds	r2, r2, r0
   2f2f4: e0a33001     	adc	r3, r3, r1
   2f2f8: e51b1010     	ldr	r1, [r11, #-0x10]
   2f2fc: e20200ff     	and	r0, r2, #255
   2f300: e3a0c000     	mov	r12, #0
   2f304: e18c0000     	orr	r0, r12, r0
   2f308: e5c10004     	strb	r0, [r1, #0x4]
   2f30c: e1a00422     	lsr	r0, r2, #8
   2f310: e20000ff     	and	r0, r0, #255
   2f314: e3a0c000     	mov	r12, #0
   2f318: e18c0000     	orr	r0, r12, r0
   2f31c: e5c10005     	strb	r0, [r1, #0x5]
   2f320: e1a00822     	lsr	r0, r2, #16
   2f324: e20000ff     	and	r0, r0, #255
   2f328: e3a0c000     	mov	r12, #0
   2f32c: e18c0000     	orr	r0, r12, r0
   2f330: e5c10006     	strb	r0, [r1, #0x6]
   2f334: e1a00c22     	lsr	r0, r2, #24
   2f338: e3a0c000     	mov	r12, #0
   2f33c: e18c0000     	orr	r0, r12, r0
   2f340: e5c10007     	strb	r0, [r1, #0x7]
   2f344: e20300ff     	and	r0, r3, #255
   2f348: e3a0c000     	mov	r12, #0
   2f34c: e18c0000     	orr	r0, r12, r0
   2f350: e5c10008     	strb	r0, [r1, #0x8]
   2f354: e1a00423     	lsr	r0, r3, #8
   2f358: e20000ff     	and	r0, r0, #255
   2f35c: e3a0c000     	mov	r12, #0
   2f360: e18c0000     	orr	r0, r12, r0
   2f364: e5c10009     	strb	r0, [r1, #0x9]
   2f368: e1a00823     	lsr	r0, r3, #16
   2f36c: e20000ff     	and	r0, r0, #255
   2f370: e3a0c000     	mov	r12, #0
   2f374: e18c0000     	orr	r0, r12, r0
   2f378: e5c1000a     	strb	r0, [r1, #0xa]
   2f37c: e1a03c23     	lsr	r3, r3, #24
   2f380: e3a02000     	mov	r2, #0
   2f384: e1823003     	orr	r3, r2, r3
   2f388: e5c1300b     	strb	r3, [r1, #0xb]
   2f38c: e51b3024     	ldr	r3, [r11, #-0x24]
   2f390: e283300c     	add	r3, r3, #12
   2f394: e50b3024     	str	r3, [r11, #-0x24]
   2f398: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f39c: e5933004     	ldr	r3, [r3, #0x4]
   2f3a0: e283200c     	add	r2, r3, #12
   2f3a4: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f3a8: e5832004     	str	r2, [r3, #0x4]
   2f3ac: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f3b0: e5931008     	ldr	r1, [r3, #0x8]
   2f3b4: e51b3030     	ldr	r3, [r11, #-0x30]
   2f3b8: e5932000     	ldr	r2, [r3]
   2f3bc: e51b3030     	ldr	r3, [r11, #-0x30]
   2f3c0: e5933004     	ldr	r3, [r3, #0x4]
   2f3c4: e51b0020     	ldr	r0, [r11, #-0x20]
   2f3c8: ebffc520     	bl	0x20850 <scarletbook_id3_tag_render> @ imm = #-0xeb80
   2f3cc: e1a03000     	mov	r3, r0
   2f3d0: e1a02003     	mov	r2, r3
   2f3d4: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f3d8: e583200c     	str	r2, [r3, #0xc]
   2f3dc: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f3e0: e5933004     	ldr	r3, [r3, #0x4]
   2f3e4: e1a00003     	mov	r0, r3
   2f3e8: e3a01000     	mov	r1, #0
   2f3ec: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f3f0: e1c321d0     	ldrd	r2, r3, [r3, #16]
   2f3f4: e0900002     	adds	r0, r0, r2
   2f3f8: e0a11003     	adc	r1, r1, r3
   2f3fc: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f400: e593300c     	ldr	r3, [r3, #0xc]
   2f404: e1a02003     	mov	r2, r3
   2f408: e3a03000     	mov	r3, #0
   2f40c: e0922000     	adds	r2, r2, r0
   2f410: e0a33001     	adc	r3, r3, r1
   2f414: e51b1028     	ldr	r1, [r11, #-0x28]
   2f418: e20200ff     	and	r0, r2, #255
   2f41c: e3a0c000     	mov	r12, #0
   2f420: e18c0000     	orr	r0, r12, r0
   2f424: e5c1000c     	strb	r0, [r1, #0xc]
   2f428: e1a00422     	lsr	r0, r2, #8
   2f42c: e20000ff     	and	r0, r0, #255
   2f430: e3a0c000     	mov	r12, #0
   2f434: e18c0000     	orr	r0, r12, r0
   2f438: e5c1000d     	strb	r0, [r1, #0xd]
   2f43c: e1a00822     	lsr	r0, r2, #16
   2f440: e20000ff     	and	r0, r0, #255
   2f444: e3a0c000     	mov	r12, #0
   2f448: e18c0000     	orr	r0, r12, r0
   2f44c: e5c1000e     	strb	r0, [r1, #0xe]
   2f450: e1a00c22     	lsr	r0, r2, #24
   2f454: e3a0c000     	mov	r12, #0
   2f458: e18c0000     	orr	r0, r12, r0
   2f45c: e5c1000f     	strb	r0, [r1, #0xf]
   2f460: e20300ff     	and	r0, r3, #255
   2f464: e3a0c000     	mov	r12, #0
   2f468: e18c0000     	orr	r0, r12, r0
   2f46c: e5c10010     	strb	r0, [r1, #0x10]
   2f470: e1a00423     	lsr	r0, r3, #8
   2f474: e20000ff     	and	r0, r0, #255
   2f478: e3a0c000     	mov	r12, #0
   2f47c: e18c0000     	orr	r0, r12, r0
   2f480: e5c10011     	strb	r0, [r1, #0x11]
   2f484: e1a00823     	lsr	r0, r3, #16
   2f488: e20000ff     	and	r0, r0, #255
   2f48c: e3a0c000     	mov	r12, #0
   2f490: e18c0000     	orr	r0, r12, r0
   2f494: e5c10012     	strb	r0, [r1, #0x12]
   2f498: e1a03c23     	lsr	r3, r3, #24
   2f49c: e3a02000     	mov	r2, #0
   2f4a0: e1823003     	orr	r3, r2, r3
   2f4a4: e5c13013     	strb	r3, [r1, #0x13]
   2f4a8: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f4ac: e593300c     	ldr	r3, [r3, #0xc]
   2f4b0: e3530000     	cmp	r3, #0
   2f4b4: 0a000008     	beq	0x2f4dc <dsf_create_header+0x78c> @ imm = #0x20
   2f4b8: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f4bc: e5933004     	ldr	r3, [r3, #0x4]
   2f4c0: e1a00003     	mov	r0, r3
   2f4c4: e3a01000     	mov	r1, #0
   2f4c8: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f4cc: e1c321d0     	ldrd	r2, r3, [r3, #16]
   2f4d0: e0922000     	adds	r2, r2, r0
   2f4d4: e0a33001     	adc	r3, r3, r1
   2f4d8: ea000001     	b	0x2f4e4 <dsf_create_header+0x794> @ imm = #0x4
   2f4dc: e3a02000     	mov	r2, #0
   2f4e0: e3a03000     	mov	r3, #0
   2f4e4: e51b1028     	ldr	r1, [r11, #-0x28]
   2f4e8: e20200ff     	and	r0, r2, #255
   2f4ec: e3a0c000     	mov	r12, #0
   2f4f0: e18c0000     	orr	r0, r12, r0
   2f4f4: e5c10014     	strb	r0, [r1, #0x14]
   2f4f8: e1a00422     	lsr	r0, r2, #8
   2f4fc: e20000ff     	and	r0, r0, #255
   2f500: e3a0c000     	mov	r12, #0
   2f504: e18c0000     	orr	r0, r12, r0
   2f508: e5c10015     	strb	r0, [r1, #0x15]
   2f50c: e1a00822     	lsr	r0, r2, #16
   2f510: e20000ff     	and	r0, r0, #255
   2f514: e3a0c000     	mov	r12, #0
   2f518: e18c0000     	orr	r0, r12, r0
   2f51c: e5c10016     	strb	r0, [r1, #0x16]
   2f520: e1a00c22     	lsr	r0, r2, #24
   2f524: e3a0c000     	mov	r12, #0
   2f528: e18c0000     	orr	r0, r12, r0
   2f52c: e5c10017     	strb	r0, [r1, #0x17]
   2f530: e20300ff     	and	r0, r3, #255
   2f534: e3a0c000     	mov	r12, #0
   2f538: e18c0000     	orr	r0, r12, r0
   2f53c: e5c10018     	strb	r0, [r1, #0x18]
   2f540: e1a00423     	lsr	r0, r3, #8
   2f544: e20000ff     	and	r0, r0, #255
   2f548: e3a0c000     	mov	r12, #0
   2f54c: e18c0000     	orr	r0, r12, r0
   2f550: e5c10019     	strb	r0, [r1, #0x19]
   2f554: e1a00823     	lsr	r0, r3, #16
   2f558: e20000ff     	and	r0, r0, #255
   2f55c: e3a0c000     	mov	r12, #0
   2f560: e18c0000     	orr	r0, r12, r0
   2f564: e5c1001a     	strb	r0, [r1, #0x1a]
   2f568: e1a03c23     	lsr	r3, r3, #24
   2f56c: e3a02000     	mov	r2, #0
   2f570: e1823003     	orr	r3, r2, r3
   2f574: e5c1301b     	strb	r3, [r1, #0x1b]
   2f578: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f57c: e5931000     	ldr	r1, [r3]
   2f580: e51b301c     	ldr	r3, [r11, #-0x1c]
   2f584: e5932004     	ldr	r2, [r3, #0x4]
   2f588: e51b3030     	ldr	r3, [r11, #-0x30]
   2f58c: e593301c     	ldr	r3, [r3, #0x1c]
   2f590: e1a00001     	mov	r0, r1
   2f594: e3a01001     	mov	r1, #1
   2f598: ebff7414     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x22fb0
   2f59c: e3a03000     	mov	r3, #0
   2f5a0: e1a00003     	mov	r0, r3
   2f5a4: e24bd00c     	sub	sp, r11, #12
   2f5a8: e8bd8830     	pop	{r4, r5, r11, pc}
   2f5ac: f0 37 00 00  	.word	0x000037f0

