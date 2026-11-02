0001e88c <id3_open_fp>:
   1e88c: e92d4800     	push	{r11, lr}
   1e890: e28db004     	add	r11, sp, #4
   1e894: e24dd010     	sub	sp, sp, #16
   1e898: e50b0010     	str	r0, [r11, #-0x10]
   1e89c: e50b1014     	str	r1, [r11, #-0x14]
   1e8a0: e3a00d05     	mov	r0, #320
   1e8a4: e3a01001     	mov	r1, #1
   1e8a8: ebffb6ab     	bl	0xc35c <calloc@plt>     @ imm = #-0x12554
   1e8ac: e1a03000     	mov	r3, r0
   1e8b0: e50b3008     	str	r3, [r11, #-0x8]
   1e8b4: e51b3008     	ldr	r3, [r11, #-0x8]
   1e8b8: e59f20c4     	ldr	r2, [pc, #0xc4]         @ 0x1e984 <id3_open_fp+0xf8>
   1e8bc: e5832130     	str	r2, [r3, #0x130]
   1e8c0: e51b3008     	ldr	r3, [r11, #-0x8]
   1e8c4: e59f20bc     	ldr	r2, [pc, #0xbc]         @ 0x1e988 <id3_open_fp+0xfc>
   1e8c8: e5832134     	str	r2, [r3, #0x134]
   1e8cc: e51b3008     	ldr	r3, [r11, #-0x8]
   1e8d0: e51b2014     	ldr	r2, [r11, #-0x14]
   1e8d4: e5832004     	str	r2, [r3, #0x4]
   1e8d8: e51b3008     	ldr	r3, [r11, #-0x8]
   1e8dc: e3a02003     	mov	r2, #3
   1e8e0: e5832000     	str	r2, [r3]
   1e8e4: e51b3008     	ldr	r3, [r11, #-0x8]
   1e8e8: e3a02000     	mov	r2, #0
   1e8ec: e5832020     	str	r2, [r3, #0x20]
   1e8f0: e51b3008     	ldr	r3, [r11, #-0x8]
   1e8f4: e51b2010     	ldr	r2, [r11, #-0x10]
   1e8f8: e5832128     	str	r2, [r3, #0x128]
   1e8fc: e3a00a02     	mov	r0, #8192
   1e900: ebffb758     	bl	0xc668 <malloc@plt>     @ imm = #-0x122a0
   1e904: e1a03000     	mov	r3, r0
   1e908: e1a02003     	mov	r2, r3
   1e90c: e51b3008     	ldr	r3, [r11, #-0x8]
   1e910: e583212c     	str	r2, [r3, #0x12c]
   1e914: e51b3008     	ldr	r3, [r11, #-0x8]
   1e918: e2833f4e     	add	r3, r3, #312
   1e91c: e1a00003     	mov	r0, r3
   1e920: ebfffdc6     	bl	0x1e040 <INIT_LIST_HEAD> @ imm = #-0x8e8
   1e924: e51b0008     	ldr	r0, [r11, #-0x8]
   1e928: eb00018a     	bl	0x1ef58 <id3_read_tag>  @ imm = #0x628
   1e92c: e1a03000     	mov	r3, r0
   1e930: e3730001     	cmn	r3, #1
   1e934: 1a000005     	bne	0x1e950 <id3_open_fp+0xc4> @ imm = #0x14
   1e938: e51b3014     	ldr	r3, [r11, #-0x14]
   1e93c: e2033002     	and	r3, r3, #2
   1e940: e3530000     	cmp	r3, #0
   1e944: 0a000003     	beq	0x1e958 <id3_open_fp+0xcc> @ imm = #0xc
   1e948: e51b0008     	ldr	r0, [r11, #-0x8]
   1e94c: eb000162     	bl	0x1eedc <id3_init_tag>  @ imm = #0x588
   1e950: e51b3008     	ldr	r3, [r11, #-0x8]
   1e954: ea000007     	b	0x1e978 <id3_open_fp+0xec> @ imm = #0x1c
   1e958: e1a00000     	mov	r0, r0
   1e95c: e51b3008     	ldr	r3, [r11, #-0x8]
   1e960: e593312c     	ldr	r3, [r3, #0x12c]
   1e964: e1a00003     	mov	r0, r3
   1e968: ebffb6ab     	bl	0xc41c <free@plt>       @ imm = #-0x12554
   1e96c: e51b0008     	ldr	r0, [r11, #-0x8]
   1e970: ebffb6a9     	bl	0xc41c <free@plt>       @ imm = #-0x1255c
   1e974: e3a03000     	mov	r3, #0
   1e978: e1a00003     	mov	r0, r3
   1e97c: e24bd004     	sub	sp, r11, #4
   1e980: e8bd8800     	pop	{r11, pc}
   1e984: 28 e4 01 00  	.word	0x0001e428
   1e988: a8 e5 01 00  	.word	0x0001e5a8

