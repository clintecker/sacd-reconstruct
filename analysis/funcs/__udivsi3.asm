0002fbc4 <__udivsi3>:
   2fbc4: e2512001     	subs	r2, r1, #1
   2fbc8: 012fff1e     	bxeq	lr
   2fbcc: 3a000074     	blo	0x2fda4 <__udivsi3+0x1e0> @ imm = #0x1d0
   2fbd0: e1500001     	cmp	r0, r1
   2fbd4: 9a00006b     	bls	0x2fd88 <__udivsi3+0x1c4> @ imm = #0x1ac
   2fbd8: e1110002     	tst	r1, r2
   2fbdc: 0a00006c     	beq	0x2fd94 <__udivsi3+0x1d0> @ imm = #0x1b0
   2fbe0: e16f3f10     	clz	r3, r0
   2fbe4: e16f2f11     	clz	r2, r1
   2fbe8: e0423003     	sub	r3, r2, r3
   2fbec: e273301f     	rsbs	r3, r3, #31
   2fbf0: 10833083     	addne	r3, r3, r3, lsl #1
   2fbf4: e3a02000     	mov	r2, #0
   2fbf8: 108ff103     	addne	pc, pc, r3, lsl #2
   2fbfc: e1a00000     	mov	r0, r0
   2fc00: e1500f81     	cmp	r0, r1, lsl #31
   2fc04: e0a22002     	adc	r2, r2, r2
   2fc08: 20400f81     	subhs	r0, r0, r1, lsl #31
   2fc0c: e1500f01     	cmp	r0, r1, lsl #30
   2fc10: e0a22002     	adc	r2, r2, r2
   2fc14: 20400f01     	subhs	r0, r0, r1, lsl #30
   2fc18: e1500e81     	cmp	r0, r1, lsl #29
   2fc1c: e0a22002     	adc	r2, r2, r2
   2fc20: 20400e81     	subhs	r0, r0, r1, lsl #29
   2fc24: e1500e01     	cmp	r0, r1, lsl #28
   2fc28: e0a22002     	adc	r2, r2, r2
   2fc2c: 20400e01     	subhs	r0, r0, r1, lsl #28
   2fc30: e1500d81     	cmp	r0, r1, lsl #27
   2fc34: e0a22002     	adc	r2, r2, r2
   2fc38: 20400d81     	subhs	r0, r0, r1, lsl #27
   2fc3c: e1500d01     	cmp	r0, r1, lsl #26
   2fc40: e0a22002     	adc	r2, r2, r2
   2fc44: 20400d01     	subhs	r0, r0, r1, lsl #26
   2fc48: e1500c81     	cmp	r0, r1, lsl #25
   2fc4c: e0a22002     	adc	r2, r2, r2
   2fc50: 20400c81     	subhs	r0, r0, r1, lsl #25
   2fc54: e1500c01     	cmp	r0, r1, lsl #24
   2fc58: e0a22002     	adc	r2, r2, r2
   2fc5c: 20400c01     	subhs	r0, r0, r1, lsl #24
   2fc60: e1500b81     	cmp	r0, r1, lsl #23
   2fc64: e0a22002     	adc	r2, r2, r2
   2fc68: 20400b81     	subhs	r0, r0, r1, lsl #23
   2fc6c: e1500b01     	cmp	r0, r1, lsl #22
   2fc70: e0a22002     	adc	r2, r2, r2
   2fc74: 20400b01     	subhs	r0, r0, r1, lsl #22
   2fc78: e1500a81     	cmp	r0, r1, lsl #21
   2fc7c: e0a22002     	adc	r2, r2, r2
   2fc80: 20400a81     	subhs	r0, r0, r1, lsl #21
   2fc84: e1500a01     	cmp	r0, r1, lsl #20
   2fc88: e0a22002     	adc	r2, r2, r2
   2fc8c: 20400a01     	subhs	r0, r0, r1, lsl #20
   2fc90: e1500981     	cmp	r0, r1, lsl #19
   2fc94: e0a22002     	adc	r2, r2, r2
   2fc98: 20400981     	subhs	r0, r0, r1, lsl #19
   2fc9c: e1500901     	cmp	r0, r1, lsl #18
   2fca0: e0a22002     	adc	r2, r2, r2
   2fca4: 20400901     	subhs	r0, r0, r1, lsl #18
   2fca8: e1500881     	cmp	r0, r1, lsl #17
   2fcac: e0a22002     	adc	r2, r2, r2
   2fcb0: 20400881     	subhs	r0, r0, r1, lsl #17
   2fcb4: e1500801     	cmp	r0, r1, lsl #16
   2fcb8: e0a22002     	adc	r2, r2, r2
   2fcbc: 20400801     	subhs	r0, r0, r1, lsl #16
   2fcc0: e1500781     	cmp	r0, r1, lsl #15
   2fcc4: e0a22002     	adc	r2, r2, r2
   2fcc8: 20400781     	subhs	r0, r0, r1, lsl #15
   2fccc: e1500701     	cmp	r0, r1, lsl #14
   2fcd0: e0a22002     	adc	r2, r2, r2
   2fcd4: 20400701     	subhs	r0, r0, r1, lsl #14
   2fcd8: e1500681     	cmp	r0, r1, lsl #13
   2fcdc: e0a22002     	adc	r2, r2, r2
   2fce0: 20400681     	subhs	r0, r0, r1, lsl #13
   2fce4: e1500601     	cmp	r0, r1, lsl #12
   2fce8: e0a22002     	adc	r2, r2, r2
   2fcec: 20400601     	subhs	r0, r0, r1, lsl #12
   2fcf0: e1500581     	cmp	r0, r1, lsl #11
   2fcf4: e0a22002     	adc	r2, r2, r2
   2fcf8: 20400581     	subhs	r0, r0, r1, lsl #11
   2fcfc: e1500501     	cmp	r0, r1, lsl #10
   2fd00: e0a22002     	adc	r2, r2, r2
   2fd04: 20400501     	subhs	r0, r0, r1, lsl #10
   2fd08: e1500481     	cmp	r0, r1, lsl #9
   2fd0c: e0a22002     	adc	r2, r2, r2
   2fd10: 20400481     	subhs	r0, r0, r1, lsl #9
   2fd14: e1500401     	cmp	r0, r1, lsl #8
   2fd18: e0a22002     	adc	r2, r2, r2
   2fd1c: 20400401     	subhs	r0, r0, r1, lsl #8
   2fd20: e1500381     	cmp	r0, r1, lsl #7
   2fd24: e0a22002     	adc	r2, r2, r2
   2fd28: 20400381     	subhs	r0, r0, r1, lsl #7
   2fd2c: e1500301     	cmp	r0, r1, lsl #6
   2fd30: e0a22002     	adc	r2, r2, r2
   2fd34: 20400301     	subhs	r0, r0, r1, lsl #6
   2fd38: e1500281     	cmp	r0, r1, lsl #5
   2fd3c: e0a22002     	adc	r2, r2, r2
   2fd40: 20400281     	subhs	r0, r0, r1, lsl #5
   2fd44: e1500201     	cmp	r0, r1, lsl #4
   2fd48: e0a22002     	adc	r2, r2, r2
   2fd4c: 20400201     	subhs	r0, r0, r1, lsl #4
   2fd50: e1500181     	cmp	r0, r1, lsl #3
   2fd54: e0a22002     	adc	r2, r2, r2
   2fd58: 20400181     	subhs	r0, r0, r1, lsl #3
   2fd5c: e1500101     	cmp	r0, r1, lsl #2
   2fd60: e0a22002     	adc	r2, r2, r2
   2fd64: 20400101     	subhs	r0, r0, r1, lsl #2
   2fd68: e1500081     	cmp	r0, r1, lsl #1
   2fd6c: e0a22002     	adc	r2, r2, r2
   2fd70: 20400081     	subhs	r0, r0, r1, lsl #1
   2fd74: e1500001     	cmp	r0, r1
   2fd78: e0a22002     	adc	r2, r2, r2
   2fd7c: 20400001     	subhs	r0, r0, r1
   2fd80: e1a00002     	mov	r0, r2
   2fd84: e12fff1e     	bx	lr
   2fd88: 03a00001     	moveq	r0, #1
   2fd8c: 13a00000     	movne	r0, #0
   2fd90: e12fff1e     	bx	lr
   2fd94: e16f2f11     	clz	r2, r1
   2fd98: e262201f     	rsb	r2, r2, #31
   2fd9c: e1a00230     	lsr	r0, r0, r2
   2fda0: e12fff1e     	bx	lr
   2fda4: e52de008     	str	lr, [sp, #-0x8]!
   2fda8: eb000481     	bl	0x30fb4 <__div0>        @ imm = #0x1204
   2fdac: e3a00000     	mov	r0, #0
   2fdb0: e49df008     	ldr	pc, [sp], #8

