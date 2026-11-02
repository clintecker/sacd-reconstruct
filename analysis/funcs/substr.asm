000139b0 <substr>:
   139b0: e92d4810     	push	{r4, r11, lr}
   139b4: e28db008     	add	r11, sp, #8
   139b8: e24dd024     	sub	sp, sp, #36
   139bc: e50b0020     	str	r0, [r11, #-0x20]
   139c0: e50b1024     	str	r1, [r11, #-0x24]
   139c4: e50b2028     	str	r2, [r11, #-0x28]
   139c8: e59f00b4     	ldr	r0, [pc, #0xb4]         @ 0x13a84 <substr+0xd4>
   139cc: e3a01000     	mov	r1, #0
   139d0: e3a02c02     	mov	r2, #512
   139d4: ebffe272     	bl	0xc3a4 <memset@plt>     @ imm = #-0x7638
   139d8: e51b2028     	ldr	r2, [r11, #-0x28]
   139dc: e59f30a4     	ldr	r3, [pc, #0xa4]         @ 0x13a88 <substr+0xd8>
   139e0: e1520003     	cmp	r2, r3
   139e4: ca000022     	bgt	0x13a74 <substr+0xc4>   @ imm = #0x88
   139e8: e59f309c     	ldr	r3, [pc, #0x9c]         @ 0x13a8c <substr+0xdc>
   139ec: e50b3014     	str	r3, [r11, #-0x14]
   139f0: e51b3024     	ldr	r3, [r11, #-0x24]
   139f4: e51b2020     	ldr	r2, [r11, #-0x20]
   139f8: e0822003     	add	r2, r2, r3
   139fc: e51b3028     	ldr	r3, [r11, #-0x28]
   13a00: e1a00002     	mov	r0, r2
   13a04: e1a01003     	mov	r1, r3
   13a08: e59f2080     	ldr	r2, [pc, #0x80]         @ 0x13a90 <substr+0xe0>
   13a0c: e51b3014     	ldr	r3, [r11, #-0x14]
   13a10: ebffeab7     	bl	0xe4f4 <charset_convert> @ imm = #-0x5524
   13a14: e1a03000     	mov	r3, r0
   13a18: e50b3018     	str	r3, [r11, #-0x18]
   13a1c: e51b4018     	ldr	r4, [r11, #-0x18]
   13a20: e51b0018     	ldr	r0, [r11, #-0x18]
   13a24: ebffe288     	bl	0xc44c <wcslen@plt>     @ imm = #-0x75e0
   13a28: e1a03000     	mov	r3, r0
   13a2c: e1a03103     	lsl	r3, r3, #2
   13a30: e1a00004     	mov	r0, r4
   13a34: e1a01003     	mov	r1, r3
   13a38: e51b2014     	ldr	r2, [r11, #-0x14]
   13a3c: e59f304c     	ldr	r3, [pc, #0x4c]         @ 0x13a90 <substr+0xe0>
   13a40: ebffeaab     	bl	0xe4f4 <charset_convert> @ imm = #-0x5554
   13a44: e1a03000     	mov	r3, r0
   13a48: e50b3010     	str	r3, [r11, #-0x10]
   13a4c: e51b3010     	ldr	r3, [r11, #-0x10]
   13a50: e59f002c     	ldr	r0, [pc, #0x2c]         @ 0x13a84 <substr+0xd4>
   13a54: e1a01003     	mov	r1, r3
   13a58: ebffe2b7     	bl	0xc53c <strcpy@plt>     @ imm = #-0x7524
   13a5c: e51b0018     	ldr	r0, [r11, #-0x18]
   13a60: ebffe26d     	bl	0xc41c <free@plt>       @ imm = #-0x764c
   13a64: e51b0010     	ldr	r0, [r11, #-0x10]
   13a68: ebffe26b     	bl	0xc41c <free@plt>       @ imm = #-0x7654
   13a6c: e59f3010     	ldr	r3, [pc, #0x10]         @ 0x13a84 <substr+0xd4>
   13a70: ea000000     	b	0x13a78 <substr+0xc8>   @ imm = #0x0
   13a74: e59f3008     	ldr	r3, [pc, #0x8]          @ 0x13a84 <substr+0xd4>
   13a78: e1a00003     	mov	r0, r3
   13a7c: e24bd008     	sub	sp, r11, #8
   13a80: e8bd8810     	pop	{r4, r11, pc}
   13a84: 44 71 05 00  	.word	0x00057144
   13a88: ff 01 00 00  	.word	0x000001ff
   13a8c: d4 28 03 00  	.word	0x000328d4
   13a90: dc 28 03 00  	.word	0x000328dc

