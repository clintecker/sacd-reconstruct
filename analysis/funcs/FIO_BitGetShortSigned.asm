0001b9d8 <FIO_BitGetShortSigned>:
   1b9d8: e92d4800     	push	{r11, lr}
   1b9dc: e28db004     	add	r11, sp, #4
   1b9e0: e24dd018     	sub	sp, sp, #24
   1b9e4: e50b0010     	str	r0, [r11, #-0x10]
   1b9e8: e50b1014     	str	r1, [r11, #-0x14]
   1b9ec: e50b2018     	str	r2, [r11, #-0x18]
   1b9f0: e3e03000     	mvn	r3, #0
   1b9f4: e50b3008     	str	r3, [r11, #-0x8]
   1b9f8: e51b3014     	ldr	r3, [r11, #-0x14]
   1b9fc: e3530000     	cmp	r3, #0
   1ba00: da000020     	ble	0x1ba88 <FIO_BitGetShortSigned+0xb0> @ imm = #0x80
   1ba04: e24b300c     	sub	r3, r11, #12
   1ba08: e51b0010     	ldr	r0, [r11, #-0x10]
   1ba0c: e1a01003     	mov	r1, r3
   1ba10: e51b2014     	ldr	r2, [r11, #-0x14]
   1ba14: eb000033     	bl	0x1bae8 <getbits>       @ imm = #0xcc
   1ba18: e1a03000     	mov	r3, r0
   1ba1c: e50b3008     	str	r3, [r11, #-0x8]
   1ba20: e51b300c     	ldr	r3, [r11, #-0xc]
   1ba24: e6ff2073     	uxth	r2, r3
   1ba28: e51b3018     	ldr	r3, [r11, #-0x18]
   1ba2c: e1c320b0     	strh	r2, [r3]
   1ba30: e51b3018     	ldr	r3, [r11, #-0x18]
   1ba34: e1d330b0     	ldrh	r3, [r3]
   1ba38: e6bf2073     	sxth	r2, r3
   1ba3c: e51b3014     	ldr	r3, [r11, #-0x14]
   1ba40: e2433001     	sub	r3, r3, #1
   1ba44: e3a01001     	mov	r1, #1
   1ba48: e1a03311     	lsl	r3, r1, r3
   1ba4c: e1520003     	cmp	r2, r3
   1ba50: ba00001d     	blt	0x1bacc <FIO_BitGetShortSigned+0xf4> @ imm = #0x74
   1ba54: e51b3018     	ldr	r3, [r11, #-0x18]
   1ba58: e1d330b0     	ldrh	r3, [r3]
   1ba5c: e6ff2073     	uxth	r2, r3
   1ba60: e3a01001     	mov	r1, #1
   1ba64: e51b3014     	ldr	r3, [r11, #-0x14]
   1ba68: e1a03311     	lsl	r3, r1, r3
   1ba6c: e6ff3073     	uxth	r3, r3
   1ba70: e0633002     	rsb	r3, r3, r2
   1ba74: e6ff3073     	uxth	r3, r3
   1ba78: e1a02003     	mov	r2, r3
   1ba7c: e51b3018     	ldr	r3, [r11, #-0x18]
   1ba80: e1c320b0     	strh	r2, [r3]
   1ba84: ea000011     	b	0x1bad0 <FIO_BitGetShortSigned+0xf8> @ imm = #0x44
   1ba88: e51b3014     	ldr	r3, [r11, #-0x14]
   1ba8c: e3530000     	cmp	r3, #0
   1ba90: 1a000005     	bne	0x1baac <FIO_BitGetShortSigned+0xd4> @ imm = #0x14
   1ba94: e51b3018     	ldr	r3, [r11, #-0x18]
   1ba98: e3a02000     	mov	r2, #0
   1ba9c: e1c320b0     	strh	r2, [r3]
   1baa0: e3a03000     	mov	r3, #0
   1baa4: e50b3008     	str	r3, [r11, #-0x8]
   1baa8: ea000008     	b	0x1bad0 <FIO_BitGetShortSigned+0xf8> @ imm = #0x20
   1baac: e59f202c     	ldr	r2, [pc, #0x2c]         @ 0x1bae0 <FIO_BitGetShortSigned+0x108>
   1bab0: e59f302c     	ldr	r3, [pc, #0x2c]         @ 0x1bae4 <FIO_BitGetShortSigned+0x10c>
   1bab4: e5933000     	ldr	r3, [r3]
   1bab8: e1a00002     	mov	r0, r2
   1babc: e3a01001     	mov	r1, #1
   1bac0: e3a0202c     	mov	r2, #44
   1bac4: ebffc2c9     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0xf4dc
   1bac8: ea000000     	b	0x1bad0 <FIO_BitGetShortSigned+0xf8> @ imm = #0x0
   1bacc: e1a00000     	mov	r0, r0
   1bad0: e51b3008     	ldr	r3, [r11, #-0x8]
   1bad4: e1a00003     	mov	r0, r3
   1bad8: e24bd004     	sub	sp, r11, #4
   1badc: e8bd8800     	pop	{r11, pc}
   1bae0: a8 30 03 00  	.word	0x000330a8
   1bae4: f8 6d 05 00  	.word	0x00056df8

