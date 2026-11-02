0001ea4c <id3_alter_file>:
   1ea4c: e92d4800     	push	{r11, lr}
   1ea50: e28db004     	add	r11, sp, #4
   1ea54: e24dd018     	sub	sp, sp, #24
   1ea58: e50b0018     	str	r0, [r11, #-0x18]
   1ea5c: e3a03000     	mov	r3, #0
   1ea60: e50b3008     	str	r3, [r11, #-0x8]
   1ea64: ea00000c     	b	0x1ea9c <id3_alter_file+0x50> @ imm = #0x30
   1ea68: e51b0010     	ldr	r0, [r11, #-0x10]
   1ea6c: ebfff75a     	bl	0x1c7dc <id3_delete_frame> @ imm = #-0x2298
   1ea70: ea000000     	b	0x1ea78 <id3_alter_file+0x2c> @ imm = #0x0
   1ea74: e1a00000     	mov	r0, r0
   1ea78: e51b0018     	ldr	r0, [r11, #-0x18]
   1ea7c: e51b100c     	ldr	r1, [r11, #-0xc]
   1ea80: e3a02001     	mov	r2, #1
   1ea84: ebfff704     	bl	0x1c69c <id3_get_frame> @ imm = #-0x23f0
   1ea88: e1a03000     	mov	r3, r0
   1ea8c: e50b3010     	str	r3, [r11, #-0x10]
   1ea90: e51b3010     	ldr	r3, [r11, #-0x10]
   1ea94: e3530000     	cmp	r3, #0
   1ea98: 1afffff2     	bne	0x1ea68 <id3_alter_file+0x1c> @ imm = #-0x38
   1ea9c: e51b2008     	ldr	r2, [r11, #-0x8]
   1eaa0: e59f303c     	ldr	r3, [pc, #0x3c]         @ 0x1eae4 <id3_alter_file+0x98>
   1eaa4: e7933102     	ldr	r3, [r3, r2, lsl #2]
   1eaa8: e50b300c     	str	r3, [r11, #-0xc]
   1eaac: e51b300c     	ldr	r3, [r11, #-0xc]
   1eab0: e3530000     	cmp	r3, #0
   1eab4: 03a03000     	moveq	r3, #0
   1eab8: 13a03001     	movne	r3, #1
   1eabc: e6ef3073     	uxtb	r3, r3
   1eac0: e51b2008     	ldr	r2, [r11, #-0x8]
   1eac4: e2822001     	add	r2, r2, #1
   1eac8: e50b2008     	str	r2, [r11, #-0x8]
   1eacc: e3530000     	cmp	r3, #0
   1ead0: 1affffe7     	bne	0x1ea74 <id3_alter_file+0x28> @ imm = #-0x64
   1ead4: e3a03000     	mov	r3, #0
   1ead8: e1a00003     	mov	r0, r3
   1eadc: e24bd004     	sub	sp, r11, #4
   1eae0: e8bd8800     	pop	{r11, pc}
   1eae4: 88 ee 03 00  	.word	0x0003ee88

