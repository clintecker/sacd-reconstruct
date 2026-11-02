000309b0 <__truncdfsf2>:
   309b0: e1a02081     	lsl	r2, r1, #1
   309b4: e2523207     	subs	r3, r2, #1879048192
   309b8: 2253c602     	subshs	r12, r3, #2097152
   309bc: 227cc57f     	rsbshs	r12, r12, #532676608
   309c0: 9a000006     	bls	0x309e0 <__truncdfsf2+0x30> @ imm = #0x18
   309c4: e201c102     	and	r12, r1, #-2147483648
   309c8: e1a02180     	lsl	r2, r0, #3
   309cc: e18c0ea0     	orr	r0, r12, r0, lsr #29
   309d0: e3520102     	cmp	r2, #-2147483648
   309d4: e0a00103     	adc	r0, r0, r3, lsl #2
   309d8: 03c00001     	biceq	r0, r0, #1
   309dc: e12fff1e     	bx	lr
   309e0: e3110101     	tst	r1, #1073741824
   309e4: 1a00000f     	bne	0x30a28 <__truncdfsf2+0x78> @ imm = #0x3c
   309e8: e293262e     	adds	r2, r3, #48234496
   309ec: b2010102     	andlt	r0, r1, #-2147483648
   309f0: b12fff1e     	bxlt	lr
   309f4: e3811601     	orr	r1, r1, #1048576
   309f8: e1a02aa2     	lsr	r2, r2, #21
   309fc: e2622018     	rsb	r2, r2, #24
   30a00: e262c020     	rsb	r12, r2, #32
   30a04: e1b03c10     	lsls	r3, r0, r12
   30a08: e1a00230     	lsr	r0, r0, r2
   30a0c: 13800001     	orrne	r0, r0, #1
   30a10: e1a03581     	lsl	r3, r1, #11
   30a14: e1a035a3     	lsr	r3, r3, #11
   30a18: e1800c13     	orr	r0, r0, r3, lsl r12
   30a1c: e1a03233     	lsr	r3, r3, r2
   30a20: e1a03083     	lsl	r3, r3, #1
   30a24: eaffffe6     	b	0x309c4 <__truncdfsf2+0x14> @ imm = #-0x68
   30a28: e1f03ac2     	mvns	r3, r2, asr #21
   30a2c: 1a000003     	bne	0x30a40 <__truncdfsf2+0x90> @ imm = #0xc
   30a30: e1903601     	orrs	r3, r0, r1, lsl #12
   30a34: 13a0047f     	movne	r0, #2130706432
   30a38: 13800503     	orrne	r0, r0, #12582912
   30a3c: 112fff1e     	bxne	lr
   30a40: e2010102     	and	r0, r1, #-2147483648
   30a44: e380047f     	orr	r0, r0, #2130706432
   30a48: e3800502     	orr	r0, r0, #8388608
   30a4c: e12fff1e     	bx	lr

