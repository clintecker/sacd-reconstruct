0001e78c <id3_open_fd>:
   1e78c: e92d4800     	push	{r11, lr}
   1e790: e28db004     	add	r11, sp, #4
   1e794: e24dd010     	sub	sp, sp, #16
   1e798: e50b0010     	str	r0, [r11, #-0x10]
   1e79c: e50b1014     	str	r1, [r11, #-0x14]
   1e7a0: e3a00d05     	mov	r0, #320
   1e7a4: e3a01001     	mov	r1, #1
   1e7a8: ebffb6eb     	bl	0xc35c <calloc@plt>     @ imm = #-0x12454
   1e7ac: e1a03000     	mov	r3, r0
   1e7b0: e50b3008     	str	r3, [r11, #-0x8]
   1e7b4: e51b3008     	ldr	r3, [r11, #-0x8]
   1e7b8: e59f20c4     	ldr	r2, [pc, #0xc4]         @ 0x1e884 <id3_open_fd+0xf8>
   1e7bc: e5832130     	str	r2, [r3, #0x130]
   1e7c0: e51b3008     	ldr	r3, [r11, #-0x8]
   1e7c4: e59f20bc     	ldr	r2, [pc, #0xbc]         @ 0x1e888 <id3_open_fd+0xfc>
   1e7c8: e5832134     	str	r2, [r3, #0x134]
   1e7cc: e51b3008     	ldr	r3, [r11, #-0x8]
   1e7d0: e51b2014     	ldr	r2, [r11, #-0x14]
   1e7d4: e5832004     	str	r2, [r3, #0x4]
   1e7d8: e51b3008     	ldr	r3, [r11, #-0x8]
   1e7dc: e3a02002     	mov	r2, #2
   1e7e0: e5832000     	str	r2, [r3]
   1e7e4: e51b3008     	ldr	r3, [r11, #-0x8]
   1e7e8: e3a02000     	mov	r2, #0
   1e7ec: e5832020     	str	r2, [r3, #0x20]
   1e7f0: e51b3008     	ldr	r3, [r11, #-0x8]
   1e7f4: e51b2010     	ldr	r2, [r11, #-0x10]
   1e7f8: e5832128     	str	r2, [r3, #0x128]
   1e7fc: e3a00a02     	mov	r0, #8192
   1e800: ebffb798     	bl	0xc668 <malloc@plt>     @ imm = #-0x121a0
   1e804: e1a03000     	mov	r3, r0
   1e808: e1a02003     	mov	r2, r3
   1e80c: e51b3008     	ldr	r3, [r11, #-0x8]
   1e810: e583212c     	str	r2, [r3, #0x12c]
   1e814: e51b3008     	ldr	r3, [r11, #-0x8]
   1e818: e2833f4e     	add	r3, r3, #312
   1e81c: e1a00003     	mov	r0, r3
   1e820: ebfffe06     	bl	0x1e040 <INIT_LIST_HEAD> @ imm = #-0x7e8
   1e824: e51b0008     	ldr	r0, [r11, #-0x8]
   1e828: eb0001ca     	bl	0x1ef58 <id3_read_tag>  @ imm = #0x728
   1e82c: e1a03000     	mov	r3, r0
   1e830: e3730001     	cmn	r3, #1
   1e834: 1a000005     	bne	0x1e850 <id3_open_fd+0xc4> @ imm = #0x14
   1e838: e51b3014     	ldr	r3, [r11, #-0x14]
   1e83c: e2033002     	and	r3, r3, #2
   1e840: e3530000     	cmp	r3, #0
   1e844: 0a000003     	beq	0x1e858 <id3_open_fd+0xcc> @ imm = #0xc
   1e848: e51b0008     	ldr	r0, [r11, #-0x8]
   1e84c: eb0001a2     	bl	0x1eedc <id3_init_tag>  @ imm = #0x688
   1e850: e51b3008     	ldr	r3, [r11, #-0x8]
   1e854: ea000007     	b	0x1e878 <id3_open_fd+0xec> @ imm = #0x1c
   1e858: e1a00000     	mov	r0, r0
   1e85c: e51b3008     	ldr	r3, [r11, #-0x8]
   1e860: e593312c     	ldr	r3, [r3, #0x12c]
   1e864: e1a00003     	mov	r0, r3
   1e868: ebffb6eb     	bl	0xc41c <free@plt>       @ imm = #-0x12454
   1e86c: e51b0008     	ldr	r0, [r11, #-0x8]
   1e870: ebffb6e9     	bl	0xc41c <free@plt>       @ imm = #-0x1245c
   1e874: e3a03000     	mov	r3, #0
   1e878: e1a00003     	mov	r0, r3
   1e87c: e24bd004     	sub	sp, r11, #4
   1e880: e8bd8800     	pop	{r11, pc}
   1e884: 00 e2 01 00  	.word	0x0001e200
   1e888: f0 e2 01 00  	.word	0x0001e2f0

