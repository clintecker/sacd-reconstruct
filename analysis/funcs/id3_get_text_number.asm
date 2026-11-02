0001d9bc <id3_get_text_number>:
   1d9bc: e92d4800     	push	{r11, lr}
   1d9c0: e28db004     	add	r11, sp, #4
   1d9c4: e24dd010     	sub	sp, sp, #16
   1d9c8: e50b0010     	str	r0, [r11, #-0x10]
   1d9cc: e3a03000     	mov	r3, #0
   1d9d0: e50b300c     	str	r3, [r11, #-0xc]
   1d9d4: e51b0010     	ldr	r0, [r11, #-0x10]
   1d9d8: ebfffb68     	bl	0x1c780 <id3_decompress_frame> @ imm = #-0x1260
   1d9dc: e1a03000     	mov	r3, r0
   1d9e0: e3730001     	cmn	r3, #1
   1d9e4: 1a000001     	bne	0x1d9f0 <id3_get_text_number+0x34> @ imm = #0x4
   1d9e8: e3e03000     	mvn	r3, #0
   1d9ec: ea000017     	b	0x1da50 <id3_get_text_number+0x94> @ imm = #0x5c
   1d9f0: e51b3010     	ldr	r3, [r11, #-0x10]
   1d9f4: e5933010     	ldr	r3, [r3, #0x10]
   1d9f8: e5d32000     	ldrb	r2, [r3]
   1d9fc: e51b3010     	ldr	r3, [r11, #-0x10]
   1da00: e5933010     	ldr	r3, [r3, #0x10]
   1da04: e2833001     	add	r3, r3, #1
   1da08: e1a00002     	mov	r0, r2
   1da0c: e1a01003     	mov	r1, r3
   1da10: ebfffe96     	bl	0x1d470 <id3_string_decode> @ imm = #-0x5a8
   1da14: e1a03000     	mov	r3, r0
   1da18: e50b3008     	str	r3, [r11, #-0x8]
   1da1c: e51b3008     	ldr	r3, [r11, #-0x8]
   1da20: e3530000     	cmp	r3, #0
   1da24: 0a000008     	beq	0x1da4c <id3_get_text_number+0x90> @ imm = #0x20
   1da28: e51b1008     	ldr	r1, [r11, #-0x8]
   1da2c: e59f2028     	ldr	r2, [pc, #0x28]         @ 0x1da5c <id3_get_text_number+0xa0>
   1da30: e24b300c     	sub	r3, r11, #12
   1da34: e1a00001     	mov	r0, r1
   1da38: e1a01002     	mov	r1, r2
   1da3c: e1a02003     	mov	r2, r3
   1da40: ebffbaa8     	bl	0xc4e8 <sscanf@plt>     @ imm = #-0x11560
   1da44: e51b0008     	ldr	r0, [r11, #-0x8]
   1da48: ebffba73     	bl	0xc41c <free@plt>       @ imm = #-0x11634
   1da4c: e51b300c     	ldr	r3, [r11, #-0xc]
   1da50: e1a00003     	mov	r0, r3
   1da54: e24bd004     	sub	sp, r11, #4
   1da58: e8bd8800     	pop	{r11, pc}
   1da5c: 14 39 03 00  	.word	0x00033914

