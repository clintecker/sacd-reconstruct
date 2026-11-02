0001e6b4 <id3_open_mem>:
   1e6b4: e92d4800     	push	{r11, lr}
   1e6b8: e28db004     	add	r11, sp, #4
   1e6bc: e24dd010     	sub	sp, sp, #16
   1e6c0: e50b0010     	str	r0, [r11, #-0x10]
   1e6c4: e50b1014     	str	r1, [r11, #-0x14]
   1e6c8: e3a00d05     	mov	r0, #320
   1e6cc: e3a01001     	mov	r1, #1
   1e6d0: ebffb721     	bl	0xc35c <calloc@plt>     @ imm = #-0x1237c
   1e6d4: e1a03000     	mov	r3, r0
   1e6d8: e50b3008     	str	r3, [r11, #-0x8]
   1e6dc: e51b3008     	ldr	r3, [r11, #-0x8]
   1e6e0: e59f209c     	ldr	r2, [pc, #0x9c]         @ 0x1e784 <id3_open_mem+0xd0>
   1e6e4: e5832130     	str	r2, [r3, #0x130]
   1e6e8: e51b3008     	ldr	r3, [r11, #-0x8]
   1e6ec: e59f2094     	ldr	r2, [pc, #0x94]         @ 0x1e788 <id3_open_mem+0xd4>
   1e6f0: e5832134     	str	r2, [r3, #0x134]
   1e6f4: e51b3008     	ldr	r3, [r11, #-0x8]
   1e6f8: e51b2014     	ldr	r2, [r11, #-0x14]
   1e6fc: e5832004     	str	r2, [r3, #0x4]
   1e700: e51b3008     	ldr	r3, [r11, #-0x8]
   1e704: e3a02001     	mov	r2, #1
   1e708: e5832000     	str	r2, [r3]
   1e70c: e51b3008     	ldr	r3, [r11, #-0x8]
   1e710: e3a02000     	mov	r2, #0
   1e714: e5832020     	str	r2, [r3, #0x20]
   1e718: e51b3008     	ldr	r3, [r11, #-0x8]
   1e71c: e51b2010     	ldr	r2, [r11, #-0x10]
   1e720: e5832128     	str	r2, [r3, #0x128]
   1e724: e51b3008     	ldr	r3, [r11, #-0x8]
   1e728: e2833f4e     	add	r3, r3, #312
   1e72c: e1a00003     	mov	r0, r3
   1e730: ebfffe42     	bl	0x1e040 <INIT_LIST_HEAD> @ imm = #-0x6f8
   1e734: e51b0008     	ldr	r0, [r11, #-0x8]
   1e738: eb000206     	bl	0x1ef58 <id3_read_tag>  @ imm = #0x818
   1e73c: e1a03000     	mov	r3, r0
   1e740: e3730001     	cmn	r3, #1
   1e744: 1a000005     	bne	0x1e760 <id3_open_mem+0xac> @ imm = #0x14
   1e748: e51b3014     	ldr	r3, [r11, #-0x14]
   1e74c: e2033002     	and	r3, r3, #2
   1e750: e3530000     	cmp	r3, #0
   1e754: 0a000003     	beq	0x1e768 <id3_open_mem+0xb4> @ imm = #0xc
   1e758: e51b0008     	ldr	r0, [r11, #-0x8]
   1e75c: eb0001de     	bl	0x1eedc <id3_init_tag>  @ imm = #0x778
   1e760: e51b3008     	ldr	r3, [r11, #-0x8]
   1e764: ea000003     	b	0x1e778 <id3_open_mem+0xc4> @ imm = #0xc
   1e768: e1a00000     	mov	r0, r0
   1e76c: e51b0008     	ldr	r0, [r11, #-0x8]
   1e770: ebffb729     	bl	0xc41c <free@plt>       @ imm = #-0x1235c
   1e774: e3a03000     	mov	r3, #0
   1e778: e1a00003     	mov	r0, r3
   1e77c: e24bd004     	sub	sp, r11, #4
   1e780: e8bd8800     	pop	{r11, pc}
   1e784: 74 e0 01 00  	.word	0x0001e074
   1e788: 38 e1 01 00  	.word	0x0001e138

