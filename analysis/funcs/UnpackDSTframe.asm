00019ae0 <UnpackDSTframe>:
   19ae0: e92d4810     	push	{r4, r11, lr}
   19ae4: e28db008     	add	r11, sp, #8
   19ae8: e24dd01c     	sub	sp, sp, #28
   19aec: e50b0018     	str	r0, [r11, #-0x18]
   19af0: e50b101c     	str	r1, [r11, #-0x1c]
   19af4: e50b2020     	str	r2, [r11, #-0x20]
   19af8: e51b2018     	ldr	r2, [r11, #-0x18]
   19afc: e59f32ac     	ldr	r3, [pc, #0x2ac]        @ 0x19db0 <UnpackDSTframe+0x2d0>
   19b00: e0823003     	add	r3, r2, r3
   19b04: e51b2018     	ldr	r2, [r11, #-0x18]
   19b08: e592207c     	ldr	r2, [r2, #0x7c]
   19b0c: e1a00003     	mov	r0, r3
   19b10: e51b101c     	ldr	r1, [r11, #-0x1c]
   19b14: eb0006f4     	bl	0x1b6ec <FillBuffer>    @ imm = #0x1bd0
   19b18: e51b2018     	ldr	r2, [r11, #-0x18]
   19b1c: e59f328c     	ldr	r3, [pc, #0x28c]        @ 0x19db0 <UnpackDSTframe+0x2d0>
   19b20: e0823003     	add	r3, r2, r3
   19b24: e51b2018     	ldr	r2, [r11, #-0x18]
   19b28: e2822078     	add	r2, r2, #120
   19b2c: e1a00003     	mov	r0, r3
   19b30: e3a01001     	mov	r1, #1
   19b34: eb00073d     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x1cf4
   19b38: e1a03000     	mov	r3, r0
   19b3c: e3530000     	cmp	r3, #0
   19b40: 0a000001     	beq	0x19b4c <UnpackDSTframe+0x6c> @ imm = #0x4
   19b44: e3a03001     	mov	r3, #1
   19b48: ea000095     	b	0x19da4 <UnpackDSTframe+0x2c4> @ imm = #0x254
   19b4c: e51b3018     	ldr	r3, [r11, #-0x18]
   19b50: e5933078     	ldr	r3, [r3, #0x78]
   19b54: e3530000     	cmp	r3, #0
   19b58: 1a000028     	bne	0x19c00 <UnpackDSTframe+0x120> @ imm = #0xa0
   19b5c: e51b2018     	ldr	r2, [r11, #-0x18]
   19b60: e59f3248     	ldr	r3, [pc, #0x248]        @ 0x19db0 <UnpackDSTframe+0x2d0>
   19b64: e0823003     	add	r3, r2, r3
   19b68: e24b2014     	sub	r2, r11, #20
   19b6c: e1a00003     	mov	r0, r3
   19b70: e3a01001     	mov	r1, #1
   19b74: eb00072d     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x1cb4
   19b78: e1a03000     	mov	r3, r0
   19b7c: e3530000     	cmp	r3, #0
   19b80: 0a000001     	beq	0x19b8c <UnpackDSTframe+0xac> @ imm = #0x4
   19b84: e3a03001     	mov	r3, #1
   19b88: ea000085     	b	0x19da4 <UnpackDSTframe+0x2c4> @ imm = #0x214
   19b8c: e51b2018     	ldr	r2, [r11, #-0x18]
   19b90: e59f3218     	ldr	r3, [pc, #0x218]        @ 0x19db0 <UnpackDSTframe+0x2d0>
   19b94: e0823003     	add	r3, r2, r3
   19b98: e24b2014     	sub	r2, r11, #20
   19b9c: e1a00003     	mov	r0, r3
   19ba0: e3a01006     	mov	r1, #6
   19ba4: eb000721     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x1c84
   19ba8: e1a03000     	mov	r3, r0
   19bac: e3530000     	cmp	r3, #0
   19bb0: 0a000001     	beq	0x19bbc <UnpackDSTframe+0xdc> @ imm = #0x4
   19bb4: e3a03001     	mov	r3, #1
   19bb8: ea000079     	b	0x19da4 <UnpackDSTframe+0x2c4> @ imm = #0x1e4
   19bbc: e51b3014     	ldr	r3, [r11, #-0x14]
   19bc0: e3530000     	cmp	r3, #0
   19bc4: 0a000001     	beq	0x19bd0 <UnpackDSTframe+0xf0> @ imm = #0x4
   19bc8: e3a0300d     	mov	r3, #13
   19bcc: ea000074     	b	0x19da4 <UnpackDSTframe+0x2c4> @ imm = #0x1d0
   19bd0: e51b2018     	ldr	r2, [r11, #-0x18]
   19bd4: e59f31d4     	ldr	r3, [pc, #0x1d4]        @ 0x19db0 <UnpackDSTframe+0x2d0>
   19bd8: e0823003     	add	r3, r2, r3
   19bdc: e51b1018     	ldr	r1, [r11, #-0x18]
   19be0: e59f21cc     	ldr	r2, [pc, #0x1cc]        @ 0x19db4 <UnpackDSTframe+0x2d4>
   19be4: e7911002     	ldr	r1, [r1, r2]
   19be8: e51b2018     	ldr	r2, [r11, #-0x18]
   19bec: e5922004     	ldr	r2, [r2, #0x4]
   19bf0: e1a00003     	mov	r0, r3
   19bf4: e51b3020     	ldr	r3, [r11, #-0x20]
   19bf8: ebfff72c     	bl	0x178b0 <ReadDSDframe>  @ imm = #-0x2350
   19bfc: ea000067     	b	0x19da0 <UnpackDSTframe+0x2c0> @ imm = #0x19c
   19c00: e51b2018     	ldr	r2, [r11, #-0x18]
   19c04: e59f31a4     	ldr	r3, [pc, #0x1a4]        @ 0x19db0 <UnpackDSTframe+0x2d0>
   19c08: e0823003     	add	r3, r2, r3
   19c0c: e51b2018     	ldr	r2, [r11, #-0x18]
   19c10: e1a00003     	mov	r0, r3
   19c14: e1a01002     	mov	r1, r2
   19c18: ebfff9fc     	bl	0x18410 <ReadSegmentData> @ imm = #-0x1810
   19c1c: e1a03000     	mov	r3, r0
   19c20: e50b3010     	str	r3, [r11, #-0x10]
   19c24: e51b3010     	ldr	r3, [r11, #-0x10]
   19c28: e3530000     	cmp	r3, #0
   19c2c: 0a000001     	beq	0x19c38 <UnpackDSTframe+0x158> @ imm = #0x4
   19c30: e51b3010     	ldr	r3, [r11, #-0x10]
   19c34: ea00005a     	b	0x19da4 <UnpackDSTframe+0x2c4> @ imm = #0x168
   19c38: e51b2018     	ldr	r2, [r11, #-0x18]
   19c3c: e59f316c     	ldr	r3, [pc, #0x16c]        @ 0x19db0 <UnpackDSTframe+0x2d0>
   19c40: e0823003     	add	r3, r2, r3
   19c44: e51b2018     	ldr	r2, [r11, #-0x18]
   19c48: e1a00003     	mov	r0, r3
   19c4c: e1a01002     	mov	r1, r2
   19c50: ebfffbad     	bl	0x18b0c <ReadMappingData> @ imm = #-0x114c
   19c54: e1a03000     	mov	r3, r0
   19c58: e50b3010     	str	r3, [r11, #-0x10]
   19c5c: e51b3010     	ldr	r3, [r11, #-0x10]
   19c60: e3530000     	cmp	r3, #0
   19c64: 0a000001     	beq	0x19c70 <UnpackDSTframe+0x190> @ imm = #0x4
   19c68: e51b3010     	ldr	r3, [r11, #-0x10]
   19c6c: ea00004c     	b	0x19da4 <UnpackDSTframe+0x2c4> @ imm = #0x130
   19c70: e51b3018     	ldr	r3, [r11, #-0x18]
   19c74: e59f2134     	ldr	r2, [pc, #0x134]        @ 0x19db0 <UnpackDSTframe+0x2d0>
   19c78: e0832002     	add	r2, r3, r2
   19c7c: e51b3018     	ldr	r3, [r11, #-0x18]
   19c80: e5931004     	ldr	r1, [r3, #0x4]
   19c84: e51bc018     	ldr	r12, [r11, #-0x18]
   19c88: e51b3018     	ldr	r3, [r11, #-0x18]
   19c8c: e2833a6e     	add	r3, r3, #450560
   19c90: e2833e82     	add	r3, r3, #2080
   19c94: e1a00002     	mov	r0, r2
   19c98: e1a0200c     	mov	r2, r12
   19c9c: ebfffc0c     	bl	0x18cd4 <ReadFilterCoefSets> @ imm = #-0xfd0
   19ca0: e1a03000     	mov	r3, r0
   19ca4: e50b3010     	str	r3, [r11, #-0x10]
   19ca8: e51b3010     	ldr	r3, [r11, #-0x10]
   19cac: e3530000     	cmp	r3, #0
   19cb0: 0a000001     	beq	0x19cbc <UnpackDSTframe+0x1dc> @ imm = #0x4
   19cb4: e51b3010     	ldr	r3, [r11, #-0x10]
   19cb8: ea000039     	b	0x19da4 <UnpackDSTframe+0x2c4> @ imm = #0xe4
   19cbc: e51b3018     	ldr	r3, [r11, #-0x18]
   19cc0: e59f20e8     	ldr	r2, [pc, #0xe8]         @ 0x19db0 <UnpackDSTframe+0x2d0>
   19cc4: e0832002     	add	r2, r3, r2
   19cc8: e51b1018     	ldr	r1, [r11, #-0x18]
   19ccc: e51b0018     	ldr	r0, [r11, #-0x18]
   19cd0: e59f30e0     	ldr	r3, [pc, #0xe0]         @ 0x19db8 <UnpackDSTframe+0x2d8>
   19cd4: e0803003     	add	r3, r0, r3
   19cd8: e51bc018     	ldr	r12, [r11, #-0x18]
   19cdc: e59f00d8     	ldr	r0, [pc, #0xd8]         @ 0x19dbc <UnpackDSTframe+0x2dc>
   19ce0: e79cc000     	ldr	r12, [r12, r0]
   19ce4: e1a00002     	mov	r0, r2
   19ce8: e1a02003     	mov	r2, r3
   19cec: e1a0300c     	mov	r3, r12
   19cf0: ebfffd7d     	bl	0x192ec <ReadProbabilityTables> @ imm = #-0xa0c
   19cf4: e1a03000     	mov	r3, r0
   19cf8: e50b3010     	str	r3, [r11, #-0x10]
   19cfc: e51b3010     	ldr	r3, [r11, #-0x10]
   19d00: e3530000     	cmp	r3, #0
   19d04: 0a000001     	beq	0x19d10 <UnpackDSTframe+0x230> @ imm = #0x4
   19d08: e51b3010     	ldr	r3, [r11, #-0x10]
   19d0c: ea000024     	b	0x19da4 <UnpackDSTframe+0x2c4> @ imm = #0x90
   19d10: e51b3018     	ldr	r3, [r11, #-0x18]
   19d14: e5934080     	ldr	r4, [r3, #0x80]
   19d18: e51b2018     	ldr	r2, [r11, #-0x18]
   19d1c: e59f308c     	ldr	r3, [pc, #0x8c]         @ 0x19db0 <UnpackDSTframe+0x2d0>
   19d20: e0823003     	add	r3, r2, r3
   19d24: e1a00003     	mov	r0, r3
   19d28: eb000809     	bl	0x1bd54 <get_in_bitcount> @ imm = #0x2024
   19d2c: e1a03000     	mov	r3, r0
   19d30: e0631004     	rsb	r1, r3, r4
   19d34: e51b2018     	ldr	r2, [r11, #-0x18]
   19d38: e59f3080     	ldr	r3, [pc, #0x80]         @ 0x19dc0 <UnpackDSTframe+0x2e0>
   19d3c: e7821003     	str	r1, [r2, r3]
   19d40: e51b2018     	ldr	r2, [r11, #-0x18]
   19d44: e59f3064     	ldr	r3, [pc, #0x64]         @ 0x19db0 <UnpackDSTframe+0x2d0>
   19d48: e0823003     	add	r3, r2, r3
   19d4c: e51b1018     	ldr	r1, [r11, #-0x18]
   19d50: e59f2068     	ldr	r2, [pc, #0x68]         @ 0x19dc0 <UnpackDSTframe+0x2e0>
   19d54: e7911002     	ldr	r1, [r1, r2]
   19d58: e51b0018     	ldr	r0, [r11, #-0x18]
   19d5c: e59f2060     	ldr	r2, [pc, #0x60]         @ 0x19dc4 <UnpackDSTframe+0x2e4>
   19d60: e7902002     	ldr	r2, [r0, r2]
   19d64: e1a00003     	mov	r0, r3
   19d68: ebfffee6     	bl	0x19908 <ReadArithmeticCodedData> @ imm = #-0x468
   19d6c: e51b2018     	ldr	r2, [r11, #-0x18]
   19d70: e59f3048     	ldr	r3, [pc, #0x48]         @ 0x19dc0 <UnpackDSTframe+0x2e0>
   19d74: e7923003     	ldr	r3, [r2, r3]
   19d78: e3530000     	cmp	r3, #0
   19d7c: da000007     	ble	0x19da0 <UnpackDSTframe+0x2c0> @ imm = #0x1c
   19d80: e51b2018     	ldr	r2, [r11, #-0x18]
   19d84: e59f3038     	ldr	r3, [pc, #0x38]         @ 0x19dc4 <UnpackDSTframe+0x2e4>
   19d88: e7923003     	ldr	r3, [r2, r3]
   19d8c: e5d33000     	ldrb	r3, [r3]
   19d90: e3530000     	cmp	r3, #0
   19d94: 0a000001     	beq	0x19da0 <UnpackDSTframe+0x2c0> @ imm = #0x4
   19d98: e3a0300e     	mov	r3, #14
   19d9c: ea000000     	b	0x19da4 <UnpackDSTframe+0x2c4> @ imm = #0x0
   19da0: e3a03000     	mov	r3, #0
   19da4: e1a00003     	mov	r0, r3
   19da8: e24bd008     	sub	sp, r11, #8
   19dac: e8bd8810     	pop	{r4, r11, pc}
   19db0: 74 e8 06 00  	.word	0x0006e874
   19db4: 10 e8 06 00  	.word	0x0006e810
   19db8: 44 e8 06 00  	.word	0x0006e844
   19dbc: 68 e8 06 00  	.word	0x0006e868
   19dc0: 70 e8 06 00  	.word	0x0006e870
   19dc4: 6c e8 06 00  	.word	0x0006e86c

