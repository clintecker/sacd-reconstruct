0001d470 <id3_string_decode>:
   1d470: e92d4800     	push	{r11, lr}
   1d474: e28db004     	add	r11, sp, #4
   1d478: e24dd008     	sub	sp, sp, #8
   1d47c: e1a03000     	mov	r3, r0
   1d480: e50b100c     	str	r1, [r11, #-0xc]
   1d484: e54b3005     	strb	r3, [r11, #-0x5]
   1d488: e55b3005     	ldrb	r3, [r11, #-0x5]
   1d48c: e3530003     	cmp	r3, #3
   1d490: 979ff103     	ldrls	pc, [pc, r3, lsl #2]
   1d494: ea000013     	b	0x1d4e8 <id3_string_decode+0x78> @ imm = #0x4c
   1d498: a8 d4 01 00  	.word	0x0001d4a8
   1d49c: c8 d4 01 00  	.word	0x0001d4c8
   1d4a0: d8 d4 01 00  	.word	0x0001d4d8
   1d4a4: b8 d4 01 00  	.word	0x0001d4b8
   1d4a8: e51b000c     	ldr	r0, [r11, #-0xc]
   1d4ac: ebffbc67     	bl	0xc650 <strdup@plt>     @ imm = #-0x10e64
   1d4b0: e1a03000     	mov	r3, r0
   1d4b4: ea00000c     	b	0x1d4ec <id3_string_decode+0x7c> @ imm = #0x30
   1d4b8: e51b000c     	ldr	r0, [r11, #-0xc]
   1d4bc: ebffc49a     	bl	0xe72c <charset_from_utf8> @ imm = #-0xed98
   1d4c0: e1a03000     	mov	r3, r0
   1d4c4: ea000008     	b	0x1d4ec <id3_string_decode+0x7c> @ imm = #0x20
   1d4c8: e51b000c     	ldr	r0, [r11, #-0xc]
   1d4cc: ebffff1e     	bl	0x1d14c <convert_from_utf16> @ imm = #-0x388
   1d4d0: e1a03000     	mov	r3, r0
   1d4d4: ea000004     	b	0x1d4ec <id3_string_decode+0x7c> @ imm = #0x10
   1d4d8: e51b000c     	ldr	r0, [r11, #-0xc]
   1d4dc: ebffff43     	bl	0x1d1f0 <convert_from_utf16be> @ imm = #-0x2f4
   1d4e0: e1a03000     	mov	r3, r0
   1d4e4: ea000000     	b	0x1d4ec <id3_string_decode+0x7c> @ imm = #0x0
   1d4e8: e3a03000     	mov	r3, #0
   1d4ec: e1a00003     	mov	r0, r3
   1d4f0: e24bd004     	sub	sp, r11, #4
   1d4f4: e8bd8800     	pop	{r11, pc}

