00030a5c <__aeabi_fadd>:
   30a5c: e1b02080     	lsls	r2, r0, #1
   30a60: 11b03081     	lslsne	r3, r1, #1
   30a64: 11320003     	teqne	r2, r3
   30a68: 11f0cc42     	mvnsne	r12, r2, asr #24
   30a6c: 11f0cc43     	mvnsne	r12, r3, asr #24
   30a70: 0a00003c     	beq	0x30b68 <__aeabi_fadd+0x10c> @ imm = #0xf0
   30a74: e1a02c22     	lsr	r2, r2, #24
   30a78: e0723c23     	rsbs	r3, r2, r3, lsr #24
   30a7c: c0822003     	addgt	r2, r2, r3
   30a80: c0201001     	eorgt	r1, r0, r1
   30a84: c0210000     	eorgt	r0, r1, r0
   30a88: c0201001     	eorgt	r1, r0, r1
   30a8c: b2633000     	rsblt	r3, r3, #0
   30a90: e3530019     	cmp	r3, #25
   30a94: 812fff1e     	bxhi	lr
   30a98: e3100102     	tst	r0, #-2147483648
   30a9c: e3800502     	orr	r0, r0, #8388608
   30aa0: e3c004ff     	bic	r0, r0, #-16777216
   30aa4: 12600000     	rsbne	r0, r0, #0
   30aa8: e3110102     	tst	r1, #-2147483648
   30aac: e3811502     	orr	r1, r1, #8388608
   30ab0: e3c114ff     	bic	r1, r1, #-16777216
   30ab4: 12611000     	rsbne	r1, r1, #0
   30ab8: e1320003     	teq	r2, r3
   30abc: 0a000023     	beq	0x30b50 <__aeabi_fadd+0xf4> @ imm = #0x8c
   30ac0: e2422001     	sub	r2, r2, #1
   30ac4: e0900351     	adds	r0, r0, r1, asr r3
   30ac8: e2633020     	rsb	r3, r3, #32
   30acc: e1a01311     	lsl	r1, r1, r3
   30ad0: e2003102     	and	r3, r0, #-2147483648
   30ad4: 5a000001     	bpl	0x30ae0 <__aeabi_fadd+0x84> @ imm = #0x4
   30ad8: e2711000     	rsbs	r1, r1, #0
   30adc: e2e00000     	rsc	r0, r0, #0
   30ae0: e3500502     	cmp	r0, #8388608
   30ae4: 3a00000b     	blo	0x30b18 <__aeabi_fadd+0xbc> @ imm = #0x2c
   30ae8: e3500401     	cmp	r0, #16777216
   30aec: 3a000004     	blo	0x30b04 <__aeabi_fadd+0xa8> @ imm = #0x10
   30af0: e1b000a0     	lsrs	r0, r0, #1
   30af4: e1a01061     	rrx	r1, r1
   30af8: e2822001     	add	r2, r2, #1
   30afc: e35200fe     	cmp	r2, #254
   30b00: 2a00002d     	bhs	0x30bbc <__aeabi_fadd+0x160> @ imm = #0xb4
   30b04: e3510102     	cmp	r1, #-2147483648
   30b08: e0a00b82     	adc	r0, r0, r2, lsl #23
   30b0c: 03c00001     	biceq	r0, r0, #1
   30b10: e1800003     	orr	r0, r0, r3
   30b14: e12fff1e     	bx	lr
   30b18: e1b01081     	lsls	r1, r1, #1
   30b1c: e0a00000     	adc	r0, r0, r0
   30b20: e3100502     	tst	r0, #8388608
   30b24: e2422001     	sub	r2, r2, #1
   30b28: 1afffff5     	bne	0x30b04 <__aeabi_fadd+0xa8> @ imm = #-0x2c
   30b2c: e16fcf10     	clz	r12, r0
   30b30: e24cc008     	sub	r12, r12, #8
   30b34: e052200c     	subs	r2, r2, r12
   30b38: e1a00c10     	lsl	r0, r0, r12
   30b3c: a0800b82     	addge	r0, r0, r2, lsl #23
   30b40: b2622000     	rsblt	r2, r2, #0
   30b44: a1800003     	orrge	r0, r0, r3
   30b48: b1830230     	orrlt	r0, r3, r0, lsr r2
   30b4c: e12fff1e     	bx	lr
   30b50: e3320000     	teq	r2, #0
   30b54: e2211502     	eor	r1, r1, #8388608
   30b58: 02200502     	eoreq	r0, r0, #8388608
   30b5c: 02822001     	addeq	r2, r2, #1
   30b60: 12433001     	subne	r3, r3, #1
   30b64: eaffffd5     	b	0x30ac0 <__aeabi_fadd+0x64> @ imm = #-0xac
   30b68: e1a03081     	lsl	r3, r1, #1
   30b6c: e1f0cc42     	mvns	r12, r2, asr #24
   30b70: 11f0cc43     	mvnsne	r12, r3, asr #24
   30b74: 0a000013     	beq	0x30bc8 <__aeabi_fadd+0x16c> @ imm = #0x4c
   30b78: e1320003     	teq	r2, r3
   30b7c: 0a000002     	beq	0x30b8c <__aeabi_fadd+0x130> @ imm = #0x8
   30b80: e3320000     	teq	r2, #0
   30b84: 01a00001     	moveq	r0, r1
   30b88: e12fff1e     	bx	lr
   30b8c: e1300001     	teq	r0, r1
   30b90: 13a00000     	movne	r0, #0
   30b94: 112fff1e     	bxne	lr
   30b98: e31204ff     	tst	r2, #-16777216
   30b9c: 1a000002     	bne	0x30bac <__aeabi_fadd+0x150> @ imm = #0x8
   30ba0: e1b00080     	lsls	r0, r0, #1
   30ba4: 23800102     	orrhs	r0, r0, #-2147483648
   30ba8: e12fff1e     	bx	lr
   30bac: e2922402     	adds	r2, r2, #33554432
   30bb0: 32800502     	addlo	r0, r0, #8388608
   30bb4: 312fff1e     	bxlo	lr
   30bb8: e2003102     	and	r3, r0, #-2147483648
   30bbc: e383047f     	orr	r0, r3, #2130706432
   30bc0: e3800502     	orr	r0, r0, #8388608
   30bc4: e12fff1e     	bx	lr
   30bc8: e1f02c42     	mvns	r2, r2, asr #24
   30bcc: 11a00001     	movne	r0, r1
   30bd0: 01f03c43     	mvnseq	r3, r3, asr #24
   30bd4: 11a01000     	movne	r1, r0
   30bd8: e1b02480     	lsls	r2, r0, #9
   30bdc: 01b03481     	lslseq	r3, r1, #9
   30be0: 01300001     	teqeq	r0, r1
   30be4: 13800501     	orrne	r0, r0, #4194304
   30be8: e12fff1e     	bx	lr

