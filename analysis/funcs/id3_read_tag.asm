0001ef58 <id3_read_tag>:
   1ef58: e92d4800     	push	{r11, lr}
   1ef5c: e28db004     	add	r11, sp, #4
   1ef60: e24dd010     	sub	sp, sp, #16
   1ef64: e50b0010     	str	r0, [r11, #-0x10]
   1ef68: e51b3010     	ldr	r3, [r11, #-0x10]
   1ef6c: e3a0200a     	mov	r2, #10
   1ef70: e583201c     	str	r2, [r3, #0x1c]
   1ef74: e51b3010     	ldr	r3, [r11, #-0x10]
   1ef78: e5933004     	ldr	r3, [r3, #0x4]
   1ef7c: e2033001     	and	r3, r3, #1
   1ef80: e3530000     	cmp	r3, #0
   1ef84: 1a000021     	bne	0x1f010 <id3_read_tag+0xb8> @ imm = #0x84
   1ef88: e51b3010     	ldr	r3, [r11, #-0x10]
   1ef8c: e5933134     	ldr	r3, [r3, #0x134]
   1ef90: e51b0010     	ldr	r0, [r11, #-0x10]
   1ef94: e3a01000     	mov	r1, #0
   1ef98: e3a02003     	mov	r2, #3
   1ef9c: e12fff33     	blx	r3
   1efa0: e1a03000     	mov	r3, r0
   1efa4: e50b3008     	str	r3, [r11, #-0x8]
   1efa8: e51b3008     	ldr	r3, [r11, #-0x8]
   1efac: e3530000     	cmp	r3, #0
   1efb0: 1a000001     	bne	0x1efbc <id3_read_tag+0x64> @ imm = #0x4
   1efb4: e3e03000     	mvn	r3, #0
   1efb8: ea00007d     	b	0x1f1b4 <id3_read_tag+0x25c> @ imm = #0x1f4
   1efbc: e51b3008     	ldr	r3, [r11, #-0x8]
   1efc0: e5d33000     	ldrb	r3, [r3]
   1efc4: e3530049     	cmp	r3, #73
   1efc8: 1a000009     	bne	0x1eff4 <id3_read_tag+0x9c> @ imm = #0x24
   1efcc: e51b3008     	ldr	r3, [r11, #-0x8]
   1efd0: e2833001     	add	r3, r3, #1
   1efd4: e5d33000     	ldrb	r3, [r3]
   1efd8: e3530044     	cmp	r3, #68
   1efdc: 1a000004     	bne	0x1eff4 <id3_read_tag+0x9c> @ imm = #0x10
   1efe0: e51b3008     	ldr	r3, [r11, #-0x8]
   1efe4: e2833002     	add	r3, r3, #2
   1efe8: e5d33000     	ldrb	r3, [r3]
   1efec: e3530033     	cmp	r3, #51
   1eff0: 0a000006     	beq	0x1f010 <id3_read_tag+0xb8> @ imm = #0x18
   1eff4: e51b3010     	ldr	r3, [r11, #-0x10]
   1eff8: e5933130     	ldr	r3, [r3, #0x130]
   1effc: e51b0010     	ldr	r0, [r11, #-0x10]
   1f000: e3e01002     	mvn	r1, #2
   1f004: e12fff33     	blx	r3
   1f008: e3e03000     	mvn	r3, #0
   1f00c: ea000068     	b	0x1f1b4 <id3_read_tag+0x25c> @ imm = #0x1a0
   1f010: e51b3010     	ldr	r3, [r11, #-0x10]
   1f014: e5933134     	ldr	r3, [r3, #0x134]
   1f018: e51b0010     	ldr	r0, [r11, #-0x10]
   1f01c: e3a01000     	mov	r1, #0
   1f020: e3a02007     	mov	r2, #7
   1f024: e12fff33     	blx	r3
   1f028: e1a03000     	mov	r3, r0
   1f02c: e50b300c     	str	r3, [r11, #-0xc]
   1f030: e51b300c     	ldr	r3, [r11, #-0xc]
   1f034: e3530000     	cmp	r3, #0
   1f038: 1a000001     	bne	0x1f044 <id3_read_tag+0xec> @ imm = #0x4
   1f03c: e3e03000     	mvn	r3, #0
   1f040: ea00005b     	b	0x1f1b4 <id3_read_tag+0x25c> @ imm = #0x16c
   1f044: e51b300c     	ldr	r3, [r11, #-0xc]
   1f048: e5d33000     	ldrb	r3, [r3]
   1f04c: e1a02003     	mov	r2, r3
   1f050: e51b3010     	ldr	r3, [r11, #-0x10]
   1f054: e5832014     	str	r2, [r3, #0x14]
   1f058: e51b300c     	ldr	r3, [r11, #-0xc]
   1f05c: e2833001     	add	r3, r3, #1
   1f060: e5d33000     	ldrb	r3, [r3]
   1f064: e1a02003     	mov	r2, r3
   1f068: e51b3010     	ldr	r3, [r11, #-0x10]
   1f06c: e5832018     	str	r2, [r3, #0x18]
   1f070: e51b300c     	ldr	r3, [r11, #-0xc]
   1f074: e2833002     	add	r3, r3, #2
   1f078: e5d33000     	ldrb	r3, [r3]
   1f07c: e1a02003     	mov	r2, r3
   1f080: e51b3010     	ldr	r3, [r11, #-0x10]
   1f084: e5832008     	str	r2, [r3, #0x8]
   1f088: e51b300c     	ldr	r3, [r11, #-0xc]
   1f08c: e2833003     	add	r3, r3, #3
   1f090: e5d33000     	ldrb	r3, [r3]
   1f094: e203307f     	and	r3, r3, #127
   1f098: e1a02a83     	lsl	r2, r3, #21
   1f09c: e51b300c     	ldr	r3, [r11, #-0xc]
   1f0a0: e2833004     	add	r3, r3, #4
   1f0a4: e5d33000     	ldrb	r3, [r3]
   1f0a8: e203307f     	and	r3, r3, #127
   1f0ac: e1a03703     	lsl	r3, r3, #14
   1f0b0: e1822003     	orr	r2, r2, r3
   1f0b4: e51b300c     	ldr	r3, [r11, #-0xc]
   1f0b8: e2833005     	add	r3, r3, #5
   1f0bc: e5d33000     	ldrb	r3, [r3]
   1f0c0: e203307f     	and	r3, r3, #127
   1f0c4: e1a03383     	lsl	r3, r3, #7
   1f0c8: e1822003     	orr	r2, r2, r3
   1f0cc: e51b300c     	ldr	r3, [r11, #-0xc]
   1f0d0: e2833006     	add	r3, r3, #6
   1f0d4: e5d33000     	ldrb	r3, [r3]
   1f0d8: e203307f     	and	r3, r3, #127
   1f0dc: e1822003     	orr	r2, r2, r3
   1f0e0: e51b3010     	ldr	r3, [r11, #-0x10]
   1f0e4: e583201c     	str	r2, [r3, #0x1c]
   1f0e8: e51b3010     	ldr	r3, [r11, #-0x10]
   1f0ec: e3a02000     	mov	r2, #0
   1f0f0: e5832010     	str	r2, [r3, #0x10]
   1f0f4: e51b3010     	ldr	r3, [r11, #-0x10]
   1f0f8: e3a02000     	mov	r2, #0
   1f0fc: e5832020     	str	r2, [r3, #0x20]
   1f100: e51b3010     	ldr	r3, [r11, #-0x10]
   1f104: e5933014     	ldr	r3, [r3, #0x14]
   1f108: e3530001     	cmp	r3, #1
   1f10c: da000003     	ble	0x1f120 <id3_read_tag+0x1c8> @ imm = #0xc
   1f110: e51b3010     	ldr	r3, [r11, #-0x10]
   1f114: e5933014     	ldr	r3, [r3, #0x14]
   1f118: e3530004     	cmp	r3, #4
   1f11c: da000001     	ble	0x1f128 <id3_read_tag+0x1d0> @ imm = #0x4
   1f120: e3e03000     	mvn	r3, #0
   1f124: ea000022     	b	0x1f1b4 <id3_read_tag+0x25c> @ imm = #0x88
   1f128: e51b3010     	ldr	r3, [r11, #-0x10]
   1f12c: e5933008     	ldr	r3, [r3, #0x8]
   1f130: e2033040     	and	r3, r3, #64
   1f134: e3530000     	cmp	r3, #0
   1f138: 0a000013     	beq	0x1f18c <id3_read_tag+0x234> @ imm = #0x4c
   1f13c: e51b3010     	ldr	r3, [r11, #-0x10]
   1f140: e5933134     	ldr	r3, [r3, #0x134]
   1f144: e51b0010     	ldr	r0, [r11, #-0x10]
   1f148: e3a01000     	mov	r1, #0
   1f14c: e3a0200a     	mov	r2, #10
   1f150: e12fff33     	blx	r3
   1f154: e1a03000     	mov	r3, r0
   1f158: e50b300c     	str	r3, [r11, #-0xc]
   1f15c: e51b300c     	ldr	r3, [r11, #-0xc]
   1f160: e3530000     	cmp	r3, #0
   1f164: 1a00000a     	bne	0x1f194 <id3_read_tag+0x23c> @ imm = #0x28
   1f168: e3e03000     	mvn	r3, #0
   1f16c: ea000010     	b	0x1f1b4 <id3_read_tag+0x25c> @ imm = #0x40
   1f170: e51b0010     	ldr	r0, [r11, #-0x10]
   1f174: ebfff47e     	bl	0x1c374 <id3_read_frame> @ imm = #-0x2e08
   1f178: e1a03000     	mov	r3, r0
   1f17c: e3730001     	cmn	r3, #1
   1f180: 1a000004     	bne	0x1f198 <id3_read_tag+0x240> @ imm = #0x10
   1f184: e3e03000     	mvn	r3, #0
   1f188: ea000009     	b	0x1f1b4 <id3_read_tag+0x25c> @ imm = #0x24
   1f18c: e1a00000     	mov	r0, r0
   1f190: ea000000     	b	0x1f198 <id3_read_tag+0x240> @ imm = #0x0
   1f194: e1a00000     	mov	r0, r0
   1f198: e51b3010     	ldr	r3, [r11, #-0x10]
   1f19c: e5932020     	ldr	r2, [r3, #0x20]
   1f1a0: e51b3010     	ldr	r3, [r11, #-0x10]
   1f1a4: e593301c     	ldr	r3, [r3, #0x1c]
   1f1a8: e1520003     	cmp	r2, r3
   1f1ac: baffffef     	blt	0x1f170 <id3_read_tag+0x218> @ imm = #-0x44
   1f1b0: e3a03000     	mov	r3, #0
   1f1b4: e1a00003     	mov	r0, r3
   1f1b8: e24bd004     	sub	sp, r11, #4
   1f1bc: e8bd8800     	pop	{r11, pc}

