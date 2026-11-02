00030e38 <__divsf3>:
   30e38: e3a0c0ff     	mov	r12, #255
   30e3c: e01c2ba0     	ands	r2, r12, r0, lsr #23
   30e40: 101c3ba1     	andsne	r3, r12, r1, lsr #23
   30e44: 1132000c     	teqne	r2, r12
   30e48: 1133000c     	teqne	r3, r12
   30e4c: 0a00003a     	beq	0x30f3c <__divsf3+0x104> @ imm = #0xe8
   30e50: e0422003     	sub	r2, r2, r3
   30e54: e020c001     	eor	r12, r0, r1
   30e58: e1b01481     	lsls	r1, r1, #9
   30e5c: e1a00480     	lsl	r0, r0, #9
   30e60: 0a00001c     	beq	0x30ed8 <__divsf3+0xa0> @ imm = #0x70
   30e64: e3a03201     	mov	r3, #268435456
   30e68: e1831221     	orr	r1, r3, r1, lsr #4
   30e6c: e1833220     	orr	r3, r3, r0, lsr #4
   30e70: e20c0102     	and	r0, r12, #-2147483648
   30e74: e1530001     	cmp	r3, r1
   30e78: 31a03083     	lsllo	r3, r3, #1
   30e7c: e2a2207d     	adc	r2, r2, #125
   30e80: e3a0c502     	mov	r12, #8388608
   30e84: e1530001     	cmp	r3, r1
   30e88: 20433001     	subhs	r3, r3, r1
   30e8c: 2180000c     	orrhs	r0, r0, r12
   30e90: e15300a1     	cmp	r3, r1, lsr #1
   30e94: 204330a1     	subhs	r3, r3, r1, lsr #1
   30e98: 218000ac     	orrhs	r0, r0, r12, lsr #1
   30e9c: e1530121     	cmp	r3, r1, lsr #2
   30ea0: 20433121     	subhs	r3, r3, r1, lsr #2
   30ea4: 2180012c     	orrhs	r0, r0, r12, lsr #2
   30ea8: e15301a1     	cmp	r3, r1, lsr #3
   30eac: 204331a1     	subhs	r3, r3, r1, lsr #3
   30eb0: 218001ac     	orrhs	r0, r0, r12, lsr #3
   30eb4: e1b03203     	lsls	r3, r3, #4
   30eb8: 11b0c22c     	lsrsne	r12, r12, #4
   30ebc: 1afffff0     	bne	0x30e84 <__divsf3+0x4c> @ imm = #-0x40
   30ec0: e35200fd     	cmp	r2, #253
   30ec4: 8affff9d     	bhi	0x30d40 <__mulsf3+0xa0> @ imm = #-0x18c
   30ec8: e1530001     	cmp	r3, r1
   30ecc: e0a00b82     	adc	r0, r0, r2, lsl #23
   30ed0: 03c00001     	biceq	r0, r0, #1
   30ed4: e12fff1e     	bx	lr
   30ed8: e20cc102     	and	r12, r12, #-2147483648
   30edc: e18c04a0     	orr	r0, r12, r0, lsr #9
   30ee0: e292207f     	adds	r2, r2, #127
   30ee4: c27230ff     	rsbsgt	r3, r2, #255
   30ee8: c1800b82     	orrgt	r0, r0, r2, lsl #23
   30eec: c12fff1e     	bxgt	lr
   30ef0: e3800502     	orr	r0, r0, #8388608
   30ef4: e3a03000     	mov	r3, #0
   30ef8: e2522001     	subs	r2, r2, #1
   30efc: eaffff8f     	b	0x30d40 <__mulsf3+0xa0> @ imm = #-0x1c4
   30f00: e3320000     	teq	r2, #0
   30f04: e200c102     	and	r12, r0, #-2147483648
   30f08: 01a00080     	lsleq	r0, r0, #1
   30f0c: 03100502     	tsteq	r0, #8388608
   30f10: 02422001     	subeq	r2, r2, #1
   30f14: 0afffffb     	beq	0x30f08 <__divsf3+0xd0> @ imm = #-0x14
   30f18: e180000c     	orr	r0, r0, r12
   30f1c: e3330000     	teq	r3, #0
   30f20: e201c102     	and	r12, r1, #-2147483648
   30f24: 01a01081     	lsleq	r1, r1, #1
   30f28: 03110502     	tsteq	r1, #8388608
   30f2c: 02433001     	subeq	r3, r3, #1
   30f30: 0afffffb     	beq	0x30f24 <__divsf3+0xec> @ imm = #-0x14
   30f34: e181100c     	orr	r1, r1, r12
   30f38: eaffffc4     	b	0x30e50 <__divsf3+0x18> @ imm = #-0xf0
   30f3c: e00c3ba1     	and	r3, r12, r1, lsr #23
   30f40: e132000c     	teq	r2, r12
   30f44: 1a000005     	bne	0x30f60 <__divsf3+0x128> @ imm = #0x14
   30f48: e1b02480     	lsls	r2, r0, #9
   30f4c: 1affffb6     	bne	0x30e2c <__mulsf3+0x18c> @ imm = #-0x128
   30f50: e133000c     	teq	r3, r12
   30f54: 1affffaf     	bne	0x30e18 <__mulsf3+0x178> @ imm = #-0x144
   30f58: e1a00001     	mov	r0, r1
   30f5c: eaffffb2     	b	0x30e2c <__mulsf3+0x18c> @ imm = #-0x138
   30f60: e133000c     	teq	r3, r12
   30f64: 1a000003     	bne	0x30f78 <__divsf3+0x140> @ imm = #0xc
   30f68: e1b03481     	lsls	r3, r1, #9
   30f6c: 0affff97     	beq	0x30dd0 <__mulsf3+0x130> @ imm = #-0x1a4
   30f70: e1a00001     	mov	r0, r1
   30f74: eaffffac     	b	0x30e2c <__mulsf3+0x18c> @ imm = #-0x150
   30f78: e3d0c102     	bics	r12, r0, #-2147483648
   30f7c: 13d1c102     	bicsne	r12, r1, #-2147483648
   30f80: 1affffde     	bne	0x30f00 <__divsf3+0xc8> @ imm = #-0x88
   30f84: e3d02102     	bics	r2, r0, #-2147483648
   30f88: 1affffa2     	bne	0x30e18 <__mulsf3+0x178> @ imm = #-0x178
   30f8c: e3d13102     	bics	r3, r1, #-2147483648
   30f90: 1affff8e     	bne	0x30dd0 <__mulsf3+0x130> @ imm = #-0x1c8
   30f94: eaffffa4     	b	0x30e2c <__mulsf3+0x18c> @ imm = #-0x170

