0002fdcc <__divsi3>:
   2fdcc: e3510000     	cmp	r1, #0
   2fdd0: e020c001     	eor	r12, r0, r1
   2fdd4: 0a000080     	beq	0x2ffdc <__divsi3+0x210> @ imm = #0x200
   2fdd8: 42611000     	rsbmi	r1, r1, #0
   2fddc: e2512001     	subs	r2, r1, #1
   2fde0: 0a000070     	beq	0x2ffa8 <__divsi3+0x1dc> @ imm = #0x1c0
   2fde4: e1b03000     	movs	r3, r0
   2fde8: 42603000     	rsbmi	r3, r0, #0
   2fdec: e1530001     	cmp	r3, r1
   2fdf0: 9a00006f     	bls	0x2ffb4 <__divsi3+0x1e8> @ imm = #0x1bc
   2fdf4: e1110002     	tst	r1, r2
   2fdf8: 0a000071     	beq	0x2ffc4 <__divsi3+0x1f8> @ imm = #0x1c4
   2fdfc: e16f2f13     	clz	r2, r3
   2fe00: e16f0f11     	clz	r0, r1
   2fe04: e0402002     	sub	r2, r0, r2
   2fe08: e272201f     	rsbs	r2, r2, #31
   2fe0c: 10822082     	addne	r2, r2, r2, lsl #1
   2fe10: e3a00000     	mov	r0, #0
   2fe14: 108ff102     	addne	pc, pc, r2, lsl #2
   2fe18: e1a00000     	mov	r0, r0
   2fe1c: e1530f81     	cmp	r3, r1, lsl #31
   2fe20: e0a00000     	adc	r0, r0, r0
   2fe24: 20433f81     	subhs	r3, r3, r1, lsl #31
   2fe28: e1530f01     	cmp	r3, r1, lsl #30
   2fe2c: e0a00000     	adc	r0, r0, r0
   2fe30: 20433f01     	subhs	r3, r3, r1, lsl #30
   2fe34: e1530e81     	cmp	r3, r1, lsl #29
   2fe38: e0a00000     	adc	r0, r0, r0
   2fe3c: 20433e81     	subhs	r3, r3, r1, lsl #29
   2fe40: e1530e01     	cmp	r3, r1, lsl #28
   2fe44: e0a00000     	adc	r0, r0, r0
   2fe48: 20433e01     	subhs	r3, r3, r1, lsl #28
   2fe4c: e1530d81     	cmp	r3, r1, lsl #27
   2fe50: e0a00000     	adc	r0, r0, r0
   2fe54: 20433d81     	subhs	r3, r3, r1, lsl #27
   2fe58: e1530d01     	cmp	r3, r1, lsl #26
   2fe5c: e0a00000     	adc	r0, r0, r0
   2fe60: 20433d01     	subhs	r3, r3, r1, lsl #26
   2fe64: e1530c81     	cmp	r3, r1, lsl #25
   2fe68: e0a00000     	adc	r0, r0, r0
   2fe6c: 20433c81     	subhs	r3, r3, r1, lsl #25
   2fe70: e1530c01     	cmp	r3, r1, lsl #24
   2fe74: e0a00000     	adc	r0, r0, r0
   2fe78: 20433c01     	subhs	r3, r3, r1, lsl #24
   2fe7c: e1530b81     	cmp	r3, r1, lsl #23
   2fe80: e0a00000     	adc	r0, r0, r0
   2fe84: 20433b81     	subhs	r3, r3, r1, lsl #23
   2fe88: e1530b01     	cmp	r3, r1, lsl #22
   2fe8c: e0a00000     	adc	r0, r0, r0
   2fe90: 20433b01     	subhs	r3, r3, r1, lsl #22
   2fe94: e1530a81     	cmp	r3, r1, lsl #21
   2fe98: e0a00000     	adc	r0, r0, r0
   2fe9c: 20433a81     	subhs	r3, r3, r1, lsl #21
   2fea0: e1530a01     	cmp	r3, r1, lsl #20
   2fea4: e0a00000     	adc	r0, r0, r0
   2fea8: 20433a01     	subhs	r3, r3, r1, lsl #20
   2feac: e1530981     	cmp	r3, r1, lsl #19
   2feb0: e0a00000     	adc	r0, r0, r0
   2feb4: 20433981     	subhs	r3, r3, r1, lsl #19
   2feb8: e1530901     	cmp	r3, r1, lsl #18
   2febc: e0a00000     	adc	r0, r0, r0
   2fec0: 20433901     	subhs	r3, r3, r1, lsl #18
   2fec4: e1530881     	cmp	r3, r1, lsl #17
   2fec8: e0a00000     	adc	r0, r0, r0
   2fecc: 20433881     	subhs	r3, r3, r1, lsl #17
   2fed0: e1530801     	cmp	r3, r1, lsl #16
   2fed4: e0a00000     	adc	r0, r0, r0
   2fed8: 20433801     	subhs	r3, r3, r1, lsl #16
   2fedc: e1530781     	cmp	r3, r1, lsl #15
   2fee0: e0a00000     	adc	r0, r0, r0
   2fee4: 20433781     	subhs	r3, r3, r1, lsl #15
   2fee8: e1530701     	cmp	r3, r1, lsl #14
   2feec: e0a00000     	adc	r0, r0, r0
   2fef0: 20433701     	subhs	r3, r3, r1, lsl #14
   2fef4: e1530681     	cmp	r3, r1, lsl #13
   2fef8: e0a00000     	adc	r0, r0, r0
   2fefc: 20433681     	subhs	r3, r3, r1, lsl #13
   2ff00: e1530601     	cmp	r3, r1, lsl #12
   2ff04: e0a00000     	adc	r0, r0, r0
   2ff08: 20433601     	subhs	r3, r3, r1, lsl #12
   2ff0c: e1530581     	cmp	r3, r1, lsl #11
   2ff10: e0a00000     	adc	r0, r0, r0
   2ff14: 20433581     	subhs	r3, r3, r1, lsl #11
   2ff18: e1530501     	cmp	r3, r1, lsl #10
   2ff1c: e0a00000     	adc	r0, r0, r0
   2ff20: 20433501     	subhs	r3, r3, r1, lsl #10
   2ff24: e1530481     	cmp	r3, r1, lsl #9
   2ff28: e0a00000     	adc	r0, r0, r0
   2ff2c: 20433481     	subhs	r3, r3, r1, lsl #9
   2ff30: e1530401     	cmp	r3, r1, lsl #8
   2ff34: e0a00000     	adc	r0, r0, r0
   2ff38: 20433401     	subhs	r3, r3, r1, lsl #8
   2ff3c: e1530381     	cmp	r3, r1, lsl #7
   2ff40: e0a00000     	adc	r0, r0, r0
   2ff44: 20433381     	subhs	r3, r3, r1, lsl #7
   2ff48: e1530301     	cmp	r3, r1, lsl #6
   2ff4c: e0a00000     	adc	r0, r0, r0
   2ff50: 20433301     	subhs	r3, r3, r1, lsl #6
   2ff54: e1530281     	cmp	r3, r1, lsl #5
   2ff58: e0a00000     	adc	r0, r0, r0
   2ff5c: 20433281     	subhs	r3, r3, r1, lsl #5
   2ff60: e1530201     	cmp	r3, r1, lsl #4
   2ff64: e0a00000     	adc	r0, r0, r0
   2ff68: 20433201     	subhs	r3, r3, r1, lsl #4
   2ff6c: e1530181     	cmp	r3, r1, lsl #3
   2ff70: e0a00000     	adc	r0, r0, r0
   2ff74: 20433181     	subhs	r3, r3, r1, lsl #3
   2ff78: e1530101     	cmp	r3, r1, lsl #2
   2ff7c: e0a00000     	adc	r0, r0, r0
   2ff80: 20433101     	subhs	r3, r3, r1, lsl #2
   2ff84: e1530081     	cmp	r3, r1, lsl #1
   2ff88: e0a00000     	adc	r0, r0, r0
   2ff8c: 20433081     	subhs	r3, r3, r1, lsl #1
   2ff90: e1530001     	cmp	r3, r1
   2ff94: e0a00000     	adc	r0, r0, r0
   2ff98: 20433001     	subhs	r3, r3, r1
   2ff9c: e35c0000     	cmp	r12, #0
   2ffa0: 42600000     	rsbmi	r0, r0, #0
   2ffa4: e12fff1e     	bx	lr
   2ffa8: e13c0000     	teq	r12, r0
   2ffac: 42600000     	rsbmi	r0, r0, #0
   2ffb0: e12fff1e     	bx	lr
   2ffb4: 33a00000     	movlo	r0, #0
   2ffb8: 01a00fcc     	asreq	r0, r12, #31
   2ffbc: 03800001     	orreq	r0, r0, #1
   2ffc0: e12fff1e     	bx	lr
   2ffc4: e16f2f11     	clz	r2, r1
   2ffc8: e262201f     	rsb	r2, r2, #31
   2ffcc: e35c0000     	cmp	r12, #0
   2ffd0: e1a00233     	lsr	r0, r3, r2
   2ffd4: 42600000     	rsbmi	r0, r0, #0
   2ffd8: e12fff1e     	bx	lr
   2ffdc: e52de008     	str	lr, [sp, #-0x8]!
   2ffe0: eb0003f3     	bl	0x30fb4 <__div0>        @ imm = #0xfcc
   2ffe4: e3a00000     	mov	r0, #0
   2ffe8: e49df008     	ldr	pc, [sp], #8

