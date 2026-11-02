0001d3b8 <id3_string_size>:
   1d3b8: e92d4800     	push	{r11, lr}
   1d3bc: e28db004     	add	r11, sp, #4
   1d3c0: e24dd010     	sub	sp, sp, #16
   1d3c4: e1a03000     	mov	r3, r0
   1d3c8: e50b1014     	str	r1, [r11, #-0x14]
   1d3cc: e54b300d     	strb	r3, [r11, #-0xd]
   1d3d0: e3a03000     	mov	r3, #0
   1d3d4: e50b3008     	str	r3, [r11, #-0x8]
   1d3d8: e55b300d     	ldrb	r3, [r11, #-0xd]
   1d3dc: e3530003     	cmp	r3, #3
   1d3e0: 979ff103     	ldrls	pc, [pc, r3, lsl #2]
   1d3e4: ea00001d     	b	0x1d460 <id3_string_size+0xa8> @ imm = #0x74
   1d3e8: f8 d3 01 00  	.word	0x0001d3f8
   1d3ec: 2c d4 01 00  	.word	0x0001d42c
   1d3f0: 2c d4 01 00  	.word	0x0001d42c
   1d3f4: f8 d3 01 00  	.word	0x0001d3f8
   1d3f8: e51b0014     	ldr	r0, [r11, #-0x14]
   1d3fc: ebffbc36     	bl	0xc4dc <strlen@plt>     @ imm = #-0x10f28
   1d400: e1a03000     	mov	r3, r0
   1d404: e2833001     	add	r3, r3, #1
   1d408: e50b3008     	str	r3, [r11, #-0x8]
   1d40c: ea000013     	b	0x1d460 <id3_string_size+0xa8> @ imm = #0x4c
   1d410: e51b3014     	ldr	r3, [r11, #-0x14]
   1d414: e2833002     	add	r3, r3, #2
   1d418: e50b3014     	str	r3, [r11, #-0x14]
   1d41c: e51b3008     	ldr	r3, [r11, #-0x8]
   1d420: e2833002     	add	r3, r3, #2
   1d424: e50b3008     	str	r3, [r11, #-0x8]
   1d428: ea000000     	b	0x1d430 <id3_string_size+0x78> @ imm = #0x0
   1d42c: e1a00000     	mov	r0, r0
   1d430: e51b3014     	ldr	r3, [r11, #-0x14]
   1d434: e5d33000     	ldrb	r3, [r3]
   1d438: e3530000     	cmp	r3, #0
   1d43c: 1afffff3     	bne	0x1d410 <id3_string_size+0x58> @ imm = #-0x34
   1d440: e51b3014     	ldr	r3, [r11, #-0x14]
   1d444: e2833001     	add	r3, r3, #1
   1d448: e5d33000     	ldrb	r3, [r3]
   1d44c: e3530000     	cmp	r3, #0
   1d450: 1affffee     	bne	0x1d410 <id3_string_size+0x58> @ imm = #-0x48
   1d454: e51b3008     	ldr	r3, [r11, #-0x8]
   1d458: e2833002     	add	r3, r3, #2
   1d45c: e50b3008     	str	r3, [r11, #-0x8]
   1d460: e51b3008     	ldr	r3, [r11, #-0x8]
   1d464: e1a00003     	mov	r0, r3
   1d468: e24bd004     	sub	sp, r11, #4
   1d46c: e8bd8800     	pop	{r11, pc}

