00019908 <ReadArithmeticCodedData>:
   19908: e92d4800     	push	{r11, lr}
   1990c: e28db004     	add	r11, sp, #4
   19910: e24dd018     	sub	sp, sp, #24
   19914: e50b0010     	str	r0, [r11, #-0x10]
   19918: e50b1014     	str	r1, [r11, #-0x14]
   1991c: e50b2018     	str	r2, [r11, #-0x18]
   19920: e3a03000     	mov	r3, #0
   19924: e50b3008     	str	r3, [r11, #-0x8]
   19928: ea000055     	b	0x19a84 <ReadArithmeticCodedData+0x17c> @ imm = #0x154
   1992c: e24b300c     	sub	r3, r11, #12
   19930: e51b0010     	ldr	r0, [r11, #-0x10]
   19934: e3a01020     	mov	r1, #32
   19938: e1a02003     	mov	r2, r3
   1993c: eb0007bb     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x1eec
   19940: e51b2018     	ldr	r2, [r11, #-0x18]
   19944: e51b3008     	ldr	r3, [r11, #-0x8]
   19948: e0823003     	add	r3, r2, r3
   1994c: e51b200c     	ldr	r2, [r11, #-0xc]
   19950: e1a02e22     	lsr	r2, r2, #28
   19954: e1a01002     	mov	r1, r2
   19958: e59f217c     	ldr	r2, [pc, #0x17c]        @ 0x19adc <ReadArithmeticCodedData+0x1d4>
   1995c: e7922101     	ldr	r2, [r2, r1, lsl #2]
   19960: e5832000     	str	r2, [r3]
   19964: e51b3008     	ldr	r3, [r11, #-0x8]
   19968: e2833004     	add	r3, r3, #4
   1996c: e51b2018     	ldr	r2, [r11, #-0x18]
   19970: e0823003     	add	r3, r2, r3
   19974: e51b200c     	ldr	r2, [r11, #-0xc]
   19978: e1a02c42     	asr	r2, r2, #24
   1997c: e202100f     	and	r1, r2, #15
   19980: e59f2154     	ldr	r2, [pc, #0x154]        @ 0x19adc <ReadArithmeticCodedData+0x1d4>
   19984: e7922101     	ldr	r2, [r2, r1, lsl #2]
   19988: e5832000     	str	r2, [r3]
   1998c: e51b3008     	ldr	r3, [r11, #-0x8]
   19990: e2833008     	add	r3, r3, #8
   19994: e51b2018     	ldr	r2, [r11, #-0x18]
   19998: e0823003     	add	r3, r2, r3
   1999c: e51b200c     	ldr	r2, [r11, #-0xc]
   199a0: e1a02a42     	asr	r2, r2, #20
   199a4: e202100f     	and	r1, r2, #15
   199a8: e59f212c     	ldr	r2, [pc, #0x12c]        @ 0x19adc <ReadArithmeticCodedData+0x1d4>
   199ac: e7922101     	ldr	r2, [r2, r1, lsl #2]
   199b0: e5832000     	str	r2, [r3]
   199b4: e51b3008     	ldr	r3, [r11, #-0x8]
   199b8: e283300c     	add	r3, r3, #12
   199bc: e51b2018     	ldr	r2, [r11, #-0x18]
   199c0: e0823003     	add	r3, r2, r3
   199c4: e51b200c     	ldr	r2, [r11, #-0xc]
   199c8: e1a02842     	asr	r2, r2, #16
   199cc: e202100f     	and	r1, r2, #15
   199d0: e59f2104     	ldr	r2, [pc, #0x104]        @ 0x19adc <ReadArithmeticCodedData+0x1d4>
   199d4: e7922101     	ldr	r2, [r2, r1, lsl #2]
   199d8: e5832000     	str	r2, [r3]
   199dc: e51b3008     	ldr	r3, [r11, #-0x8]
   199e0: e2833010     	add	r3, r3, #16
   199e4: e51b2018     	ldr	r2, [r11, #-0x18]
   199e8: e0823003     	add	r3, r2, r3
   199ec: e51b200c     	ldr	r2, [r11, #-0xc]
   199f0: e1a02642     	asr	r2, r2, #12
   199f4: e202100f     	and	r1, r2, #15
   199f8: e59f20dc     	ldr	r2, [pc, #0xdc]         @ 0x19adc <ReadArithmeticCodedData+0x1d4>
   199fc: e7922101     	ldr	r2, [r2, r1, lsl #2]
   19a00: e5832000     	str	r2, [r3]
   19a04: e51b3008     	ldr	r3, [r11, #-0x8]
   19a08: e2833014     	add	r3, r3, #20
   19a0c: e51b2018     	ldr	r2, [r11, #-0x18]
   19a10: e0823003     	add	r3, r2, r3
   19a14: e51b200c     	ldr	r2, [r11, #-0xc]
   19a18: e1a02442     	asr	r2, r2, #8
   19a1c: e202100f     	and	r1, r2, #15
   19a20: e59f20b4     	ldr	r2, [pc, #0xb4]         @ 0x19adc <ReadArithmeticCodedData+0x1d4>
   19a24: e7922101     	ldr	r2, [r2, r1, lsl #2]
   19a28: e5832000     	str	r2, [r3]
   19a2c: e51b3008     	ldr	r3, [r11, #-0x8]
   19a30: e2833018     	add	r3, r3, #24
   19a34: e51b2018     	ldr	r2, [r11, #-0x18]
   19a38: e0823003     	add	r3, r2, r3
   19a3c: e51b200c     	ldr	r2, [r11, #-0xc]
   19a40: e1a02242     	asr	r2, r2, #4
   19a44: e202100f     	and	r1, r2, #15
   19a48: e59f208c     	ldr	r2, [pc, #0x8c]         @ 0x19adc <ReadArithmeticCodedData+0x1d4>
   19a4c: e7922101     	ldr	r2, [r2, r1, lsl #2]
   19a50: e5832000     	str	r2, [r3]
   19a54: e51b3008     	ldr	r3, [r11, #-0x8]
   19a58: e283301c     	add	r3, r3, #28
   19a5c: e51b2018     	ldr	r2, [r11, #-0x18]
   19a60: e0823003     	add	r3, r2, r3
   19a64: e51b200c     	ldr	r2, [r11, #-0xc]
   19a68: e202100f     	and	r1, r2, #15
   19a6c: e59f2068     	ldr	r2, [pc, #0x68]         @ 0x19adc <ReadArithmeticCodedData+0x1d4>
   19a70: e7922101     	ldr	r2, [r2, r1, lsl #2]
   19a74: e5832000     	str	r2, [r3]
   19a78: e51b3008     	ldr	r3, [r11, #-0x8]
   19a7c: e2833020     	add	r3, r3, #32
   19a80: e50b3008     	str	r3, [r11, #-0x8]
   19a84: e51b3014     	ldr	r3, [r11, #-0x14]
   19a88: e243201f     	sub	r2, r3, #31
   19a8c: e51b3008     	ldr	r3, [r11, #-0x8]
   19a90: e1520003     	cmp	r2, r3
   19a94: caffffa4     	bgt	0x1992c <ReadArithmeticCodedData+0x24> @ imm = #-0x170
   19a98: ea000009     	b	0x19ac4 <ReadArithmeticCodedData+0x1bc> @ imm = #0x24
   19a9c: e51b3008     	ldr	r3, [r11, #-0x8]
   19aa0: e51b2018     	ldr	r2, [r11, #-0x18]
   19aa4: e0823003     	add	r3, r2, r3
   19aa8: e51b0010     	ldr	r0, [r11, #-0x10]
   19aac: e3a01001     	mov	r1, #1
   19ab0: e1a02003     	mov	r2, r3
   19ab4: eb000730     	bl	0x1b77c <FIO_BitGetChrUnsigned> @ imm = #0x1cc0
   19ab8: e51b3008     	ldr	r3, [r11, #-0x8]
   19abc: e2833001     	add	r3, r3, #1
   19ac0: e50b3008     	str	r3, [r11, #-0x8]
   19ac4: e51b2008     	ldr	r2, [r11, #-0x8]
   19ac8: e51b3014     	ldr	r3, [r11, #-0x14]
   19acc: e1520003     	cmp	r2, r3
   19ad0: bafffff1     	blt	0x19a9c <ReadArithmeticCodedData+0x194> @ imm = #-0x3c
   19ad4: e24bd004     	sub	sp, r11, #4
   19ad8: e8bd8800     	pop	{r11, pc}
   19adc: 44 2e 03 00  	.word	0x00032e44

