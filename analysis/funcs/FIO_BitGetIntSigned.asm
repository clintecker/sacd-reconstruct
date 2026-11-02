0001b8e0 <FIO_BitGetIntSigned>:
   1b8e0: e92d4800     	push	{r11, lr}
   1b8e4: e28db004     	add	r11, sp, #4
   1b8e8: e24dd018     	sub	sp, sp, #24
   1b8ec: e50b0010     	str	r0, [r11, #-0x10]
   1b8f0: e50b1014     	str	r1, [r11, #-0x14]
   1b8f4: e50b2018     	str	r2, [r11, #-0x18]
   1b8f8: e3e03000     	mvn	r3, #0
   1b8fc: e50b3008     	str	r3, [r11, #-0x8]
   1b900: e51b3014     	ldr	r3, [r11, #-0x14]
   1b904: e3530000     	cmp	r3, #0
   1b908: da00001a     	ble	0x1b978 <FIO_BitGetIntSigned+0x98> @ imm = #0x68
   1b90c: e24b300c     	sub	r3, r11, #12
   1b910: e51b0010     	ldr	r0, [r11, #-0x10]
   1b914: e1a01003     	mov	r1, r3
   1b918: e51b2014     	ldr	r2, [r11, #-0x14]
   1b91c: eb000071     	bl	0x1bae8 <getbits>       @ imm = #0x1c4
   1b920: e1a03000     	mov	r3, r0
   1b924: e50b3008     	str	r3, [r11, #-0x8]
   1b928: e51b200c     	ldr	r2, [r11, #-0xc]
   1b92c: e51b3018     	ldr	r3, [r11, #-0x18]
   1b930: e5832000     	str	r2, [r3]
   1b934: e51b3018     	ldr	r3, [r11, #-0x18]
   1b938: e5932000     	ldr	r2, [r3]
   1b93c: e51b3014     	ldr	r3, [r11, #-0x14]
   1b940: e2433001     	sub	r3, r3, #1
   1b944: e3a01001     	mov	r1, #1
   1b948: e1a03311     	lsl	r3, r1, r3
   1b94c: e1520003     	cmp	r2, r3
   1b950: ba000019     	blt	0x1b9bc <FIO_BitGetIntSigned+0xdc> @ imm = #0x64
   1b954: e51b3018     	ldr	r3, [r11, #-0x18]
   1b958: e5932000     	ldr	r2, [r3]
   1b95c: e3a01001     	mov	r1, #1
   1b960: e51b3014     	ldr	r3, [r11, #-0x14]
   1b964: e1a03311     	lsl	r3, r1, r3
   1b968: e0632002     	rsb	r2, r3, r2
   1b96c: e51b3018     	ldr	r3, [r11, #-0x18]
   1b970: e5832000     	str	r2, [r3]
   1b974: ea000011     	b	0x1b9c0 <FIO_BitGetIntSigned+0xe0> @ imm = #0x44
   1b978: e51b3014     	ldr	r3, [r11, #-0x14]
   1b97c: e3530000     	cmp	r3, #0
   1b980: 1a000005     	bne	0x1b99c <FIO_BitGetIntSigned+0xbc> @ imm = #0x14
   1b984: e51b3018     	ldr	r3, [r11, #-0x18]
   1b988: e3a02000     	mov	r2, #0
   1b98c: e5832000     	str	r2, [r3]
   1b990: e3a03000     	mov	r3, #0
   1b994: e50b3008     	str	r3, [r11, #-0x8]
   1b998: ea000008     	b	0x1b9c0 <FIO_BitGetIntSigned+0xe0> @ imm = #0x20
   1b99c: e59f202c     	ldr	r2, [pc, #0x2c]         @ 0x1b9d0 <FIO_BitGetIntSigned+0xf0>
   1b9a0: e59f302c     	ldr	r3, [pc, #0x2c]         @ 0x1b9d4 <FIO_BitGetIntSigned+0xf4>
   1b9a4: e5933000     	ldr	r3, [r3]
   1b9a8: e1a00002     	mov	r0, r2
   1b9ac: e3a01001     	mov	r1, #1
   1b9b0: e3a0202c     	mov	r2, #44
   1b9b4: ebffc30d     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0xf3cc
   1b9b8: ea000000     	b	0x1b9c0 <FIO_BitGetIntSigned+0xe0> @ imm = #0x0
   1b9bc: e1a00000     	mov	r0, r0
   1b9c0: e51b3008     	ldr	r3, [r11, #-0x8]
   1b9c4: e1a00003     	mov	r0, r3
   1b9c8: e24bd004     	sub	sp, r11, #4
   1b9cc: e8bd8800     	pop	{r11, pc}
   1b9d0: a8 30 03 00  	.word	0x000330a8
   1b9d4: f8 6d 05 00  	.word	0x00056df8

