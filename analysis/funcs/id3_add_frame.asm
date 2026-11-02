0001c8d4 <id3_add_frame>:
   1c8d4: e92d4800     	push	{r11, lr}
   1c8d8: e28db004     	add	r11, sp, #4
   1c8dc: e24dd010     	sub	sp, sp, #16
   1c8e0: e50b0010     	str	r0, [r11, #-0x10]
   1c8e4: e50b1014     	str	r1, [r11, #-0x14]
   1c8e8: e3a00030     	mov	r0, #48
   1c8ec: e3a01001     	mov	r1, #1
   1c8f0: ebffbe99     	bl	0xc35c <calloc@plt>     @ imm = #-0x1059c
   1c8f4: e1a03000     	mov	r3, r0
   1c8f8: e50b300c     	str	r3, [r11, #-0xc]
   1c8fc: e51b300c     	ldr	r3, [r11, #-0xc]
   1c900: e51b2010     	ldr	r2, [r11, #-0x10]
   1c904: e5832000     	str	r2, [r3]
   1c908: e3a03000     	mov	r3, #0
   1c90c: e50b3008     	str	r3, [r11, #-0x8]
   1c910: ea000018     	b	0x1c978 <id3_add_frame+0xa4> @ imm = #0x60
   1c914: e51b2008     	ldr	r2, [r11, #-0x8]
   1c918: e59f109c     	ldr	r1, [pc, #0x9c]         @ 0x1c9bc <id3_add_frame+0xe8>
   1c91c: e1a03002     	mov	r3, r2
   1c920: e1a03083     	lsl	r3, r3, #1
   1c924: e0833002     	add	r3, r3, r2
   1c928: e1a03103     	lsl	r3, r3, #2
   1c92c: e0813003     	add	r3, r1, r3
   1c930: e5932000     	ldr	r2, [r3]
   1c934: e51b3014     	ldr	r3, [r11, #-0x14]
   1c938: e1520003     	cmp	r2, r3
   1c93c: 1a00000a     	bne	0x1c96c <id3_add_frame+0x98> @ imm = #0x28
   1c940: e51b2008     	ldr	r2, [r11, #-0x8]
   1c944: e1a03002     	mov	r3, r2
   1c948: e1a03083     	lsl	r3, r3, #1
   1c94c: e0833002     	add	r3, r3, r2
   1c950: e1a03103     	lsl	r3, r3, #2
   1c954: e1a02003     	mov	r2, r3
   1c958: e59f305c     	ldr	r3, [pc, #0x5c]         @ 0x1c9bc <id3_add_frame+0xe8>
   1c95c: e0822003     	add	r2, r2, r3
   1c960: e51b300c     	ldr	r3, [r11, #-0xc]
   1c964: e5832004     	str	r2, [r3, #0x4]
   1c968: ea000005     	b	0x1c984 <id3_add_frame+0xb0> @ imm = #0x14
   1c96c: e51b3008     	ldr	r3, [r11, #-0x8]
   1c970: e2833001     	add	r3, r3, #1
   1c974: e50b3008     	str	r3, [r11, #-0x8]
   1c978: e51b3008     	ldr	r3, [r11, #-0x8]
   1c97c: e353005b     	cmp	r3, #91
   1c980: daffffe3     	ble	0x1c914 <id3_add_frame+0x40> @ imm = #-0x74
   1c984: e51b300c     	ldr	r3, [r11, #-0xc]
   1c988: e2832028     	add	r2, r3, #40
   1c98c: e51b3010     	ldr	r3, [r11, #-0x10]
   1c990: e2833f4e     	add	r3, r3, #312
   1c994: e1a00002     	mov	r0, r2
   1c998: e1a01003     	mov	r1, r3
   1c99c: ebfffe0f     	bl	0x1c1e0 <list_add_tail> @ imm = #-0x7c4
   1c9a0: e51b3010     	ldr	r3, [r11, #-0x10]
   1c9a4: e3a02001     	mov	r2, #1
   1c9a8: e583200c     	str	r2, [r3, #0xc]
   1c9ac: e51b300c     	ldr	r3, [r11, #-0xc]
   1c9b0: e1a00003     	mov	r0, r3
   1c9b4: e24bd004     	sub	sp, r11, #4
   1c9b8: e8bd8800     	pop	{r11, pc}
   1c9bc: 40 e8 03 00  	.word	0x0003e840

