0001d820 <id3_get_text>:
   1d820: e92d4800     	push	{r11, lr}
   1d824: e28db004     	add	r11, sp, #4
   1d828: e24dd010     	sub	sp, sp, #16
   1d82c: e50b0010     	str	r0, [r11, #-0x10]
   1d830: e3a03000     	mov	r3, #0
   1d834: e50b3008     	str	r3, [r11, #-0x8]
   1d838: e51b3010     	ldr	r3, [r11, #-0x10]
   1d83c: e5933004     	ldr	r3, [r3, #0x4]
   1d840: e5d33004     	ldrb	r3, [r3, #0x4]
   1d844: e3530054     	cmp	r3, #84
   1d848: 0a000001     	beq	0x1d854 <id3_get_text+0x34> @ imm = #0x4
   1d84c: e3a03000     	mov	r3, #0
   1d850: ea00002b     	b	0x1d904 <id3_get_text+0xe4> @ imm = #0xac
   1d854: e51b0010     	ldr	r0, [r11, #-0x10]
   1d858: ebfffbc8     	bl	0x1c780 <id3_decompress_frame> @ imm = #-0x10e0
   1d85c: e1a03000     	mov	r3, r0
   1d860: e3730001     	cmn	r3, #1
   1d864: 1a000001     	bne	0x1d870 <id3_get_text+0x50> @ imm = #0x4
   1d868: e3a03000     	mov	r3, #0
   1d86c: ea000024     	b	0x1d904 <id3_get_text+0xe4> @ imm = #0x90
   1d870: e51b3010     	ldr	r3, [r11, #-0x10]
   1d874: e5933004     	ldr	r3, [r3, #0x4]
   1d878: e5932000     	ldr	r2, [r3]
   1d87c: e59f308c     	ldr	r3, [pc, #0x8c]         @ 0x1d910 <id3_get_text+0xf0>
   1d880: e1520003     	cmp	r2, r3
   1d884: 1a000011     	bne	0x1d8d0 <id3_get_text+0xb0> @ imm = #0x44
   1d888: e51b3010     	ldr	r3, [r11, #-0x10]
   1d88c: e5933010     	ldr	r3, [r3, #0x10]
   1d890: e5d32000     	ldrb	r2, [r3]
   1d894: e51b3010     	ldr	r3, [r11, #-0x10]
   1d898: e5933010     	ldr	r3, [r3, #0x10]
   1d89c: e2833001     	add	r3, r3, #1
   1d8a0: e1a00002     	mov	r0, r2
   1d8a4: e1a01003     	mov	r1, r3
   1d8a8: ebfffec2     	bl	0x1d3b8 <id3_string_size> @ imm = #-0x4f8
   1d8ac: e1a03000     	mov	r3, r0
   1d8b0: e50b3008     	str	r3, [r11, #-0x8]
   1d8b4: e51b3010     	ldr	r3, [r11, #-0x10]
   1d8b8: e5932014     	ldr	r2, [r3, #0x14]
   1d8bc: e51b3008     	ldr	r3, [r11, #-0x8]
   1d8c0: e1520003     	cmp	r2, r3
   1d8c4: ca000001     	bgt	0x1d8d0 <id3_get_text+0xb0> @ imm = #0x4
   1d8c8: e3a03000     	mov	r3, #0
   1d8cc: ea00000c     	b	0x1d904 <id3_get_text+0xe4> @ imm = #0x30
   1d8d0: e51b3010     	ldr	r3, [r11, #-0x10]
   1d8d4: e5933010     	ldr	r3, [r3, #0x10]
   1d8d8: e5d32000     	ldrb	r2, [r3]
   1d8dc: e51b3010     	ldr	r3, [r11, #-0x10]
   1d8e0: e5933010     	ldr	r3, [r3, #0x10]
   1d8e4: e1a01003     	mov	r1, r3
   1d8e8: e51b3008     	ldr	r3, [r11, #-0x8]
   1d8ec: e2833001     	add	r3, r3, #1
   1d8f0: e0813003     	add	r3, r1, r3
   1d8f4: e1a00002     	mov	r0, r2
   1d8f8: e1a01003     	mov	r1, r3
   1d8fc: ebfffedb     	bl	0x1d470 <id3_string_decode> @ imm = #-0x494
   1d900: e1a03000     	mov	r3, r0
   1d904: e1a00003     	mov	r0, r3
   1d908: e24bd004     	sub	sp, r11, #4
   1d90c: e8bd8800     	pop	{r11, pc}
   1d910: 58 58 58 54  	.word	0x54585858

