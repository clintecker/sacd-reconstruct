00030c24 <__floatdisf>:
   30c24: e1902001     	orrs	r2, r0, r1
   30c28: 012fff1e     	bxeq	lr
   30c2c: e2113102     	ands	r3, r1, #-2147483648
   30c30: 5a000001     	bpl	0x30c3c <__floatdisf+0x18> @ imm = #0x4
   30c34: e2700000     	rsbs	r0, r0, #0
   30c38: e2e11000     	rsc	r1, r1, #0
   30c3c: e1b0c001     	movs	r12, r1
   30c40: 01a0c000     	moveq	r12, r0
   30c44: 01a01000     	moveq	r1, r0
   30c48: 03a00000     	moveq	r0, #0
   30c4c: e383345b     	orr	r3, r3, #1526726656
   30c50: 02433201     	subeq	r3, r3, #268435456
   30c54: e2433502     	sub	r3, r3, #8388608
   30c58: e16f2f1c     	clz	r2, r12
   30c5c: e2522008     	subs	r2, r2, #8
   30c60: e0433b82     	sub	r3, r3, r2, lsl #23
   30c64: ba000006     	blt	0x30c84 <__floatdisf+0x60> @ imm = #0x18
   30c68: e0833211     	add	r3, r3, r1, lsl r2
   30c6c: e1a0c210     	lsl	r12, r0, r2
   30c70: e2622020     	rsb	r2, r2, #32
   30c74: e35c0102     	cmp	r12, #-2147483648
   30c78: e0a30230     	adc	r0, r3, r0, lsr r2
   30c7c: 03c00001     	biceq	r0, r0, #1
   30c80: e12fff1e     	bx	lr
   30c84: e2822020     	add	r2, r2, #32
   30c88: e1a0c211     	lsl	r12, r1, r2
   30c8c: e2622020     	rsb	r2, r2, #32
   30c90: e190008c     	orrs	r0, r0, r12, lsl #1
   30c94: e0a30231     	adc	r0, r3, r1, lsr r2
   30c98: 01c00fac     	biceq	r0, r0, r12, lsr #31
   30c9c: e12fff1e     	bx	lr

