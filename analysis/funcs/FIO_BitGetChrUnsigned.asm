0001b77c <FIO_BitGetChrUnsigned>:
   1b77c: e92d4800     	push	{r11, lr}
   1b780: e28db004     	add	r11, sp, #4
   1b784: e24dd018     	sub	sp, sp, #24
   1b788: e50b0010     	str	r0, [r11, #-0x10]
   1b78c: e50b1014     	str	r1, [r11, #-0x14]
   1b790: e50b2018     	str	r2, [r11, #-0x18]
   1b794: e3e03000     	mvn	r3, #0
   1b798: e50b3008     	str	r3, [r11, #-0x8]
   1b79c: e51b3014     	ldr	r3, [r11, #-0x14]
   1b7a0: e3530000     	cmp	r3, #0
   1b7a4: da00000b     	ble	0x1b7d8 <FIO_BitGetChrUnsigned+0x5c> @ imm = #0x2c
   1b7a8: e24b300c     	sub	r3, r11, #12
   1b7ac: e51b0010     	ldr	r0, [r11, #-0x10]
   1b7b0: e1a01003     	mov	r1, r3
   1b7b4: e51b2014     	ldr	r2, [r11, #-0x14]
   1b7b8: eb0000ca     	bl	0x1bae8 <getbits>       @ imm = #0x328
   1b7bc: e1a03000     	mov	r3, r0
   1b7c0: e50b3008     	str	r3, [r11, #-0x8]
   1b7c4: e51b300c     	ldr	r3, [r11, #-0xc]
   1b7c8: e6ef2073     	uxtb	r2, r3
   1b7cc: e51b3018     	ldr	r3, [r11, #-0x18]
   1b7d0: e5c32000     	strb	r2, [r3]
   1b7d4: ea00000f     	b	0x1b818 <FIO_BitGetChrUnsigned+0x9c> @ imm = #0x3c
   1b7d8: e51b3014     	ldr	r3, [r11, #-0x14]
   1b7dc: e3530000     	cmp	r3, #0
   1b7e0: 1a000005     	bne	0x1b7fc <FIO_BitGetChrUnsigned+0x80> @ imm = #0x14
   1b7e4: e51b3018     	ldr	r3, [r11, #-0x18]
   1b7e8: e3a02000     	mov	r2, #0
   1b7ec: e5c32000     	strb	r2, [r3]
   1b7f0: e3a03000     	mov	r3, #0
   1b7f4: e50b3008     	str	r3, [r11, #-0x8]
   1b7f8: ea000006     	b	0x1b818 <FIO_BitGetChrUnsigned+0x9c> @ imm = #0x18
   1b7fc: e59f2024     	ldr	r2, [pc, #0x24]         @ 0x1b828 <FIO_BitGetChrUnsigned+0xac>
   1b800: e59f3024     	ldr	r3, [pc, #0x24]         @ 0x1b82c <FIO_BitGetChrUnsigned+0xb0>
   1b804: e5933000     	ldr	r3, [r3]
   1b808: e1a00002     	mov	r0, r2
   1b80c: e3a01001     	mov	r1, #1
   1b810: e3a0202c     	mov	r2, #44
   1b814: ebffc375     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0xf22c
   1b818: e51b3008     	ldr	r3, [r11, #-0x8]
   1b81c: e1a00003     	mov	r0, r3
   1b820: e24bd004     	sub	sp, r11, #4
   1b824: e8bd8800     	pop	{r11, pc}
   1b828: a8 30 03 00  	.word	0x000330a8
   1b82c: f8 6d 05 00  	.word	0x00056df8

