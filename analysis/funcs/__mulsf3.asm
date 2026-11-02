00030ca0 <__mulsf3>:
   30ca0: e3a0c0ff     	mov	r12, #255
   30ca4: e01c2ba0     	ands	r2, r12, r0, lsr #23
   30ca8: 101c3ba1     	andsne	r3, r12, r1, lsr #23
   30cac: 1132000c     	teqne	r2, r12
   30cb0: 1133000c     	teqne	r3, r12
   30cb4: 0a00003e     	beq	0x30db4 <__mulsf3+0x114> @ imm = #0xf8
   30cb8: e0822003     	add	r2, r2, r3
   30cbc: e020c001     	eor	r12, r0, r1
   30cc0: e1b00480     	lsls	r0, r0, #9
   30cc4: 11b01481     	lslsne	r1, r1, #9
   30cc8: 0a000010     	beq	0x30d10 <__mulsf3+0x70> @ imm = #0x40
   30ccc: e3a03302     	mov	r3, #134217728
   30cd0: e18302a0     	orr	r0, r3, r0, lsr #5
   30cd4: e18312a1     	orr	r1, r3, r1, lsr #5
   30cd8: e0813190     	umull	r3, r1, r0, r1
   30cdc: e20c0102     	and	r0, r12, #-2147483648
   30ce0: e3510502     	cmp	r1, #8388608
   30ce4: 31a01081     	lsllo	r1, r1, #1
   30ce8: 31811fa3     	orrlo	r1, r1, r3, lsr #31
   30cec: 31a03083     	lsllo	r3, r3, #1
   30cf0: e1800001     	orr	r0, r0, r1
   30cf4: e2c2207f     	sbc	r2, r2, #127
   30cf8: e35200fd     	cmp	r2, #253
   30cfc: 8a00000f     	bhi	0x30d40 <__mulsf3+0xa0> @ imm = #0x3c
   30d00: e3530102     	cmp	r3, #-2147483648
   30d04: e0a00b82     	adc	r0, r0, r2, lsl #23
   30d08: 03c00001     	biceq	r0, r0, #1
   30d0c: e12fff1e     	bx	lr
   30d10: e3300000     	teq	r0, #0
   30d14: e20cc102     	and	r12, r12, #-2147483648
   30d18: 01a01481     	lsleq	r1, r1, #9
   30d1c: e18c04a0     	orr	r0, r12, r0, lsr #9
   30d20: e18004a1     	orr	r0, r0, r1, lsr #9
   30d24: e252207f     	subs	r2, r2, #127
   30d28: c27230ff     	rsbsgt	r3, r2, #255
   30d2c: c1800b82     	orrgt	r0, r0, r2, lsl #23
   30d30: c12fff1e     	bxgt	lr
   30d34: e3800502     	orr	r0, r0, #8388608
   30d38: e3a03000     	mov	r3, #0
   30d3c: e2522001     	subs	r2, r2, #1
   30d40: ca000035     	bgt	0x30e1c <__mulsf3+0x17c> @ imm = #0xd4
   30d44: e3720019     	cmn	r2, #25
   30d48: d2000102     	andle	r0, r0, #-2147483648
   30d4c: d12fff1e     	bxle	lr
   30d50: e2622000     	rsb	r2, r2, #0
   30d54: e1b01080     	lsls	r1, r0, #1
   30d58: e1a01231     	lsr	r1, r1, r2
   30d5c: e2622020     	rsb	r2, r2, #32
   30d60: e1a0c210     	lsl	r12, r0, r2
   30d64: e1b00061     	rrxs	r0, r1
   30d68: e2a00000     	adc	r0, r0, #0
   30d6c: e193308c     	orrs	r3, r3, r12, lsl #1
   30d70: 01c00fac     	biceq	r0, r0, r12, lsr #31
   30d74: e12fff1e     	bx	lr
   30d78: e3320000     	teq	r2, #0
   30d7c: e200c102     	and	r12, r0, #-2147483648
   30d80: 01a00080     	lsleq	r0, r0, #1
   30d84: 03100502     	tsteq	r0, #8388608
   30d88: 02422001     	subeq	r2, r2, #1
   30d8c: 0afffffb     	beq	0x30d80 <__mulsf3+0xe0> @ imm = #-0x14
   30d90: e180000c     	orr	r0, r0, r12
   30d94: e3330000     	teq	r3, #0
   30d98: e201c102     	and	r12, r1, #-2147483648
   30d9c: 01a01081     	lsleq	r1, r1, #1
   30da0: 03110502     	tsteq	r1, #8388608
   30da4: 02433001     	subeq	r3, r3, #1
   30da8: 0afffffb     	beq	0x30d9c <__mulsf3+0xfc> @ imm = #-0x14
   30dac: e181100c     	orr	r1, r1, r12
   30db0: eaffffc0     	b	0x30cb8 <__mulsf3+0x18> @ imm = #-0x100
   30db4: e00c3ba1     	and	r3, r12, r1, lsr #23
   30db8: e132000c     	teq	r2, r12
   30dbc: 1133000c     	teqne	r3, r12
   30dc0: 0a000005     	beq	0x30ddc <__mulsf3+0x13c> @ imm = #0x14
   30dc4: e3d0c102     	bics	r12, r0, #-2147483648
   30dc8: 13d1c102     	bicsne	r12, r1, #-2147483648
   30dcc: 1affffe9     	bne	0x30d78 <__mulsf3+0xd8> @ imm = #-0x5c
   30dd0: e0200001     	eor	r0, r0, r1
   30dd4: e2000102     	and	r0, r0, #-2147483648
   30dd8: e12fff1e     	bx	lr
   30ddc: e3300000     	teq	r0, #0
   30de0: 13300102     	teqne	r0, #-2147483648
   30de4: 01a00001     	moveq	r0, r1
   30de8: 13310000     	teqne	r1, #0
   30dec: 13310102     	teqne	r1, #-2147483648
   30df0: 0a00000d     	beq	0x30e2c <__mulsf3+0x18c> @ imm = #0x34
   30df4: e132000c     	teq	r2, r12
   30df8: 1a000001     	bne	0x30e04 <__mulsf3+0x164> @ imm = #0x4
   30dfc: e1b02480     	lsls	r2, r0, #9
   30e00: 1a000009     	bne	0x30e2c <__mulsf3+0x18c> @ imm = #0x24
   30e04: e133000c     	teq	r3, r12
   30e08: 1a000002     	bne	0x30e18 <__mulsf3+0x178> @ imm = #0x8
   30e0c: e1b03481     	lsls	r3, r1, #9
   30e10: 11a00001     	movne	r0, r1
   30e14: 1a000004     	bne	0x30e2c <__mulsf3+0x18c> @ imm = #0x10
   30e18: e0200001     	eor	r0, r0, r1
   30e1c: e2000102     	and	r0, r0, #-2147483648
   30e20: e380047f     	orr	r0, r0, #2130706432
   30e24: e3800502     	orr	r0, r0, #8388608
   30e28: e12fff1e     	bx	lr
   30e2c: e380047f     	orr	r0, r0, #2130706432
   30e30: e3800503     	orr	r0, r0, #12582912
   30e34: e12fff1e     	bx	lr

