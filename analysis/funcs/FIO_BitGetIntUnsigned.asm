0001b830 <FIO_BitGetIntUnsigned>:
   1b830: e92d4800     	push	{r11, lr}
   1b834: e28db004     	add	r11, sp, #4
   1b838: e24dd018     	sub	sp, sp, #24
   1b83c: e50b0010     	str	r0, [r11, #-0x10]
   1b840: e50b1014     	str	r1, [r11, #-0x14]
   1b844: e50b2018     	str	r2, [r11, #-0x18]
   1b848: e3e03000     	mvn	r3, #0
   1b84c: e50b3008     	str	r3, [r11, #-0x8]
   1b850: e51b3014     	ldr	r3, [r11, #-0x14]
   1b854: e3530000     	cmp	r3, #0
   1b858: da00000a     	ble	0x1b888 <FIO_BitGetIntUnsigned+0x58> @ imm = #0x28
   1b85c: e24b300c     	sub	r3, r11, #12
   1b860: e51b0010     	ldr	r0, [r11, #-0x10]
   1b864: e1a01003     	mov	r1, r3
   1b868: e51b2014     	ldr	r2, [r11, #-0x14]
   1b86c: eb00009d     	bl	0x1bae8 <getbits>       @ imm = #0x274
   1b870: e1a03000     	mov	r3, r0
   1b874: e50b3008     	str	r3, [r11, #-0x8]
   1b878: e51b200c     	ldr	r2, [r11, #-0xc]
   1b87c: e51b3018     	ldr	r3, [r11, #-0x18]
   1b880: e5832000     	str	r2, [r3]
   1b884: ea00000f     	b	0x1b8c8 <FIO_BitGetIntUnsigned+0x98> @ imm = #0x3c
   1b888: e51b3014     	ldr	r3, [r11, #-0x14]
   1b88c: e3530000     	cmp	r3, #0
   1b890: 1a000005     	bne	0x1b8ac <FIO_BitGetIntUnsigned+0x7c> @ imm = #0x14
   1b894: e51b3018     	ldr	r3, [r11, #-0x18]
   1b898: e3a02000     	mov	r2, #0
   1b89c: e5832000     	str	r2, [r3]
   1b8a0: e3a03000     	mov	r3, #0
   1b8a4: e50b3008     	str	r3, [r11, #-0x8]
   1b8a8: ea000006     	b	0x1b8c8 <FIO_BitGetIntUnsigned+0x98> @ imm = #0x18
   1b8ac: e59f2024     	ldr	r2, [pc, #0x24]         @ 0x1b8d8 <FIO_BitGetIntUnsigned+0xa8>
   1b8b0: e59f3024     	ldr	r3, [pc, #0x24]         @ 0x1b8dc <FIO_BitGetIntUnsigned+0xac>
   1b8b4: e5933000     	ldr	r3, [r3]
   1b8b8: e1a00002     	mov	r0, r2
   1b8bc: e3a01001     	mov	r1, #1
   1b8c0: e3a0202c     	mov	r2, #44
   1b8c4: ebffc349     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0xf2dc
   1b8c8: e51b3008     	ldr	r3, [r11, #-0x8]
   1b8cc: e1a00003     	mov	r0, r3
   1b8d0: e24bd004     	sub	sp, r11, #4
   1b8d4: e8bd8800     	pop	{r11, pc}
   1b8d8: a8 30 03 00  	.word	0x000330a8
   1b8dc: f8 6d 05 00  	.word	0x00056df8

