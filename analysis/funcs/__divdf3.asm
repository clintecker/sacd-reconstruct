00030628 <__divdf3>:
   30628: e92d4070     	push	{r4, r5, r6, lr}
   3062c: e3a0c0ff     	mov	r12, #255
   30630: e38ccc07     	orr	r12, r12, #1792
   30634: e01c4a21     	ands	r4, r12, r1, lsr #20
   30638: 101c5a23     	andsne	r5, r12, r3, lsr #20
   3063c: 1134000c     	teqne	r4, r12
   30640: 1135000c     	teqne	r5, r12
   30644: 0b00005c     	bleq	0x307bc <__divdf3+0x194> @ imm = #0x170
   30648: e0444005     	sub	r4, r4, r5
   3064c: e021e003     	eor	lr, r1, r3
   30650: e1925603     	orrs	r5, r2, r3, lsl #12
   30654: e1a01601     	lsl	r1, r1, #12
   30658: 0a00004b     	beq	0x3078c <__divdf3+0x164> @ imm = #0x12c
   3065c: e1a03603     	lsl	r3, r3, #12
   30660: e3a05201     	mov	r5, #268435456
   30664: e1853223     	orr	r3, r5, r3, lsr #4
   30668: e1833c22     	orr	r3, r3, r2, lsr #24
   3066c: e1a02402     	lsl	r2, r2, #8
   30670: e1855221     	orr	r5, r5, r1, lsr #4
   30674: e1855c20     	orr	r5, r5, r0, lsr #24
   30678: e1a06400     	lsl	r6, r0, #8
   3067c: e20e1102     	and	r1, lr, #-2147483648
   30680: e1550003     	cmp	r5, r3
   30684: 01560002     	cmpeq	r6, r2
   30688: e2a440fd     	adc	r4, r4, #253
   3068c: e2844c03     	add	r4, r4, #768
   30690: 2a000001     	bhs	0x3069c <__divdf3+0x74> @ imm = #0x4
   30694: e1b030a3     	lsrs	r3, r3, #1
   30698: e1a02062     	rrx	r2, r2
   3069c: e0566002     	subs	r6, r6, r2
   306a0: e0c55003     	sbc	r5, r5, r3
   306a4: e1b030a3     	lsrs	r3, r3, #1
   306a8: e1a02062     	rrx	r2, r2
   306ac: e3a00601     	mov	r0, #1048576
   306b0: e3a0c702     	mov	r12, #524288
   306b4: e056e002     	subs	lr, r6, r2
   306b8: e0d5e003     	sbcs	lr, r5, r3
   306bc: 20466002     	subhs	r6, r6, r2
   306c0: 21a0500e     	movhs	r5, lr
   306c4: 2180000c     	orrhs	r0, r0, r12
   306c8: e1b030a3     	lsrs	r3, r3, #1
   306cc: e1a02062     	rrx	r2, r2
   306d0: e056e002     	subs	lr, r6, r2
   306d4: e0d5e003     	sbcs	lr, r5, r3
   306d8: 20466002     	subhs	r6, r6, r2
   306dc: 21a0500e     	movhs	r5, lr
   306e0: 218000ac     	orrhs	r0, r0, r12, lsr #1
   306e4: e1b030a3     	lsrs	r3, r3, #1
   306e8: e1a02062     	rrx	r2, r2
   306ec: e056e002     	subs	lr, r6, r2
   306f0: e0d5e003     	sbcs	lr, r5, r3
   306f4: 20466002     	subhs	r6, r6, r2
   306f8: 21a0500e     	movhs	r5, lr
   306fc: 2180012c     	orrhs	r0, r0, r12, lsr #2
   30700: e1b030a3     	lsrs	r3, r3, #1
   30704: e1a02062     	rrx	r2, r2
   30708: e056e002     	subs	lr, r6, r2
   3070c: e0d5e003     	sbcs	lr, r5, r3
   30710: 20466002     	subhs	r6, r6, r2
   30714: 21a0500e     	movhs	r5, lr
   30718: 218001ac     	orrhs	r0, r0, r12, lsr #3
   3071c: e195e006     	orrs	lr, r5, r6
   30720: 0a00000d     	beq	0x3075c <__divdf3+0x134> @ imm = #0x34
   30724: e1a05205     	lsl	r5, r5, #4
   30728: e1855e26     	orr	r5, r5, r6, lsr #28
   3072c: e1a06206     	lsl	r6, r6, #4
   30730: e1a03183     	lsl	r3, r3, #3
   30734: e1833ea2     	orr	r3, r3, r2, lsr #29
   30738: e1a02182     	lsl	r2, r2, #3
   3073c: e1b0c22c     	lsrs	r12, r12, #4
   30740: 1affffdb     	bne	0x306b4 <__divdf3+0x8c> @ imm = #-0x94
   30744: e3110601     	tst	r1, #1048576
   30748: 1a000006     	bne	0x30768 <__divdf3+0x140> @ imm = #0x18
   3074c: e1811000     	orr	r1, r1, r0
   30750: e3a00000     	mov	r0, #0
   30754: e3a0c102     	mov	r12, #-2147483648
   30758: eaffffd5     	b	0x306b4 <__divdf3+0x8c> @ imm = #-0xac
   3075c: e3110601     	tst	r1, #1048576
   30760: 01811000     	orreq	r1, r1, r0
   30764: 03a00000     	moveq	r0, #0
   30768: e254c0fd     	subs	r12, r4, #253
   3076c: 835c0c07     	cmphi	r12, #1792
   30770: 8affff4a     	bhi	0x304a0 <__muldf3+0xe4> @ imm = #-0x2d8
   30774: e055c003     	subs	r12, r5, r3
   30778: 0056c002     	subseq	r12, r6, r2
   3077c: 01b0c0a0     	lsrseq	r12, r0, #1
   30780: e2b00000     	adcs	r0, r0, #0
   30784: e0a11a04     	adc	r1, r1, r4, lsl #20
   30788: e8bd8070     	pop	{r4, r5, r6, pc}
   3078c: e20ee102     	and	lr, lr, #-2147483648
   30790: e18e1621     	orr	r1, lr, r1, lsr #12
   30794: e09440ac     	adds	r4, r4, r12, lsr #1
   30798: c074500c     	rsbsgt	r5, r4, r12
   3079c: c1811a04     	orrgt	r1, r1, r4, lsl #20
   307a0: c8bd8070     	popgt	{r4, r5, r6, pc}
   307a4: e3811601     	orr	r1, r1, #1048576
   307a8: e3a0e000     	mov	lr, #0
   307ac: e2544001     	subs	r4, r4, #1
   307b0: eaffff3a     	b	0x304a0 <__muldf3+0xe4> @ imm = #-0x318
   307b4: e185e006     	orr	lr, r5, r6
   307b8: eaffff38     	b	0x304a0 <__muldf3+0xe4> @ imm = #-0x320
   307bc: e00c5a23     	and	r5, r12, r3, lsr #20
   307c0: e134000c     	teq	r4, r12
   307c4: 0135000c     	teqeq	r5, r12
   307c8: 0affff93     	beq	0x3061c <__muldf3+0x260> @ imm = #-0x1b4
   307cc: e134000c     	teq	r4, r12
   307d0: 1a000006     	bne	0x307f0 <__divdf3+0x1c8> @ imm = #0x18
   307d4: e1904601     	orrs	r4, r0, r1, lsl #12
   307d8: 1affff8f     	bne	0x3061c <__muldf3+0x260> @ imm = #-0x1c4
   307dc: e135000c     	teq	r5, r12
   307e0: 1affff87     	bne	0x30604 <__muldf3+0x248> @ imm = #-0x1e4
   307e4: e1a00002     	mov	r0, r2
   307e8: e1a01003     	mov	r1, r3
   307ec: eaffff8a     	b	0x3061c <__muldf3+0x260> @ imm = #-0x1d8
   307f0: e135000c     	teq	r5, r12
   307f4: 1a000004     	bne	0x3080c <__divdf3+0x1e4> @ imm = #0x10
   307f8: e1925603     	orrs	r5, r2, r3, lsl #12
   307fc: 0affff6d     	beq	0x305b8 <__muldf3+0x1fc> @ imm = #-0x24c
   30800: e1a00002     	mov	r0, r2
   30804: e1a01003     	mov	r1, r3
   30808: eaffff83     	b	0x3061c <__muldf3+0x260> @ imm = #-0x1f4
   3080c: e1906081     	orrs	r6, r0, r1, lsl #1
   30810: 11926083     	orrsne	r6, r2, r3, lsl #1
   30814: 1affff4d     	bne	0x30550 <__muldf3+0x194> @ imm = #-0x2cc
   30818: e1904081     	orrs	r4, r0, r1, lsl #1
   3081c: 1affff78     	bne	0x30604 <__muldf3+0x248> @ imm = #-0x220
   30820: e1925083     	orrs	r5, r2, r3, lsl #1
   30824: 1affff63     	bne	0x305b8 <__muldf3+0x1fc> @ imm = #-0x274
   30828: eaffff7b     	b	0x3061c <__muldf3+0x260> @ imm = #-0x214

