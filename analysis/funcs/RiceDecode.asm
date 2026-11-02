00017928 <RiceDecode>:
   17928: e92d4800     	push	{r11, lr}
   1792c: e28db004     	add	r11, sp, #4
   17930: e24dd020     	sub	sp, sp, #32
   17934: e50b0020     	str	r0, [r11, #-0x20]
   17938: e50b1024     	str	r1, [r11, #-0x24]
   1793c: e3a03000     	mov	r3, #0
   17940: e50b3008     	str	r3, [r11, #-0x8]
   17944: e24b3014     	sub	r3, r11, #20
   17948: e51b0020     	ldr	r0, [r11, #-0x20]
   1794c: e3a01001     	mov	r1, #1
   17950: e1a02003     	mov	r2, r3
   17954: eb000fb5     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x3ed4
   17958: e51b3014     	ldr	r3, [r11, #-0x14]
   1795c: e2633001     	rsb	r3, r3, #1
   17960: e51b2008     	ldr	r2, [r11, #-0x8]
   17964: e0823003     	add	r3, r2, r3
   17968: e50b3008     	str	r3, [r11, #-0x8]
   1796c: e51b3014     	ldr	r3, [r11, #-0x14]
   17970: e3530000     	cmp	r3, #0
   17974: 0afffff2     	beq	0x17944 <RiceDecode+0x1c> @ imm = #-0x38
   17978: e24b3010     	sub	r3, r11, #16
   1797c: e51b0020     	ldr	r0, [r11, #-0x20]
   17980: e51b1024     	ldr	r1, [r11, #-0x24]
   17984: e1a02003     	mov	r2, r3
   17988: eb000fa8     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x3ea0
   1798c: e51b2008     	ldr	r2, [r11, #-0x8]
   17990: e51b3024     	ldr	r3, [r11, #-0x24]
   17994: e1a02312     	lsl	r2, r2, r3
   17998: e51b3010     	ldr	r3, [r11, #-0x10]
   1799c: e0823003     	add	r3, r2, r3
   179a0: e50b300c     	str	r3, [r11, #-0xc]
   179a4: e51b300c     	ldr	r3, [r11, #-0xc]
   179a8: e3530000     	cmp	r3, #0
   179ac: 0a00000a     	beq	0x179dc <RiceDecode+0xb4> @ imm = #0x28
   179b0: e24b3018     	sub	r3, r11, #24
   179b4: e51b0020     	ldr	r0, [r11, #-0x20]
   179b8: e3a01001     	mov	r1, #1
   179bc: e1a02003     	mov	r2, r3
   179c0: eb000f9a     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x3e68
   179c4: e51b3018     	ldr	r3, [r11, #-0x18]
   179c8: e3530001     	cmp	r3, #1
   179cc: 1a000002     	bne	0x179dc <RiceDecode+0xb4> @ imm = #0x8
   179d0: e51b300c     	ldr	r3, [r11, #-0xc]
   179d4: e2633000     	rsb	r3, r3, #0
   179d8: e50b300c     	str	r3, [r11, #-0xc]
   179dc: e51b300c     	ldr	r3, [r11, #-0xc]
   179e0: e1a00003     	mov	r0, r3
   179e4: e24bd004     	sub	sp, r11, #4
   179e8: e8bd8800     	pop	{r11, pc}

