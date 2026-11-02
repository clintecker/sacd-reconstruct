00021278 <disc_sacd>:
   21278: e92d4800     	push	{r11, lr}
   2127c: e28db004     	add	r11, sp, #4
   21280: e24dd018     	sub	sp, sp, #24
   21284: e3e03000     	mvn	r3, #0
   21288: e50b3008     	str	r3, [r11, #-0x8]
   2128c: e24b301c     	sub	r3, r11, #28
   21290: e1a00003     	mov	r0, r3
   21294: e3a01000     	mov	r1, #0
   21298: e3a02010     	mov	r2, #16
   2129c: ebffac40     	bl	0xc3a4 <memset@plt>     @ imm = #-0x14f00
   212a0: e59f0058     	ldr	r0, [pc, #0x58]         @ 0x21300 <disc_sacd+0x88>
   212a4: e3a01000     	mov	r1, #0
   212a8: ebffacb2     	bl	0xc578 <open64@plt>     @ imm = #-0x14d38
   212ac: e1a03000     	mov	r3, r0
   212b0: e50b300c     	str	r3, [r11, #-0xc]
   212b4: e51b300c     	ldr	r3, [r11, #-0xc]
   212b8: e3530000     	cmp	r3, #0
   212bc: ba00000b     	blt	0x212f0 <disc_sacd+0x78> @ imm = #0x2c
   212c0: e24b301c     	sub	r3, r11, #28
   212c4: e51b000c     	ldr	r0, [r11, #-0xc]
   212c8: e59f1034     	ldr	r1, [pc, #0x34]         @ 0x21304 <disc_sacd+0x8c>
   212cc: e1a02003     	mov	r2, r3
   212d0: ebffac75     	bl	0xc4ac <ioctl@plt>      @ imm = #-0x14e2c
   212d4: e1a03000     	mov	r3, r0
   212d8: e3530000     	cmp	r3, #0
   212dc: ba000001     	blt	0x212e8 <disc_sacd+0x70> @ imm = #0x4
   212e0: e51b301c     	ldr	r3, [r11, #-0x1c]
   212e4: e50b3008     	str	r3, [r11, #-0x8]
   212e8: e51b000c     	ldr	r0, [r11, #-0xc]
   212ec: ebffacbc     	bl	0xc5e4 <close@plt>      @ imm = #-0x14d10
   212f0: e51b3008     	ldr	r3, [r11, #-0x8]
   212f4: e1a00003     	mov	r0, r3
   212f8: e24bd004     	sub	sp, r11, #4
   212fc: e8bd8800     	pop	{r11, pc}
   21300: f8 52 03 00  	.word	0x000352f8
   21304: 06 53 10 40  	.word	0x40105306

