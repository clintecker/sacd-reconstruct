000303bc <__muldf3>:
   303bc: e92d4070     	push	{r4, r5, r6, lr}
   303c0: e3a0c0ff     	mov	r12, #255
   303c4: e38ccc07     	orr	r12, r12, #1792
   303c8: e01c4a21     	ands	r4, r12, r1, lsr #20
   303cc: 101c5a23     	andsne	r5, r12, r3, lsr #20
   303d0: 1134000c     	teqne	r4, r12
   303d4: 1135000c     	teqne	r5, r12
   303d8: 0b00006f     	bleq	0x3059c <__muldf3+0x1e0> @ imm = #0x1bc
   303dc: e0844005     	add	r4, r4, r5
   303e0: e0216003     	eor	r6, r1, r3
   303e4: e1c11a8c     	bic	r1, r1, r12, lsl #21
   303e8: e1c33a8c     	bic	r3, r3, r12, lsl #21
   303ec: e1905601     	orrs	r5, r0, r1, lsl #12
   303f0: 11925603     	orrsne	r5, r2, r3, lsl #12
   303f4: e3811601     	orr	r1, r1, #1048576
   303f8: e3833601     	orr	r3, r3, #1048576
   303fc: 0a00001c     	beq	0x30474 <__muldf3+0xb8> @ imm = #0x70
   30400: e08ec290     	umull	r12, lr, r0, r2
   30404: e3a05000     	mov	r5, #0
   30408: e0a5e291     	umlal	lr, r5, r1, r2
   3040c: e2062102     	and	r2, r6, #-2147483648
   30410: e0a5e390     	umlal	lr, r5, r0, r3
   30414: e3a06000     	mov	r6, #0
   30418: e0a65391     	umlal	r5, r6, r1, r3
   3041c: e33c0000     	teq	r12, #0
   30420: 138ee001     	orrne	lr, lr, #1
   30424: e24440ff     	sub	r4, r4, #255
   30428: e3560c02     	cmp	r6, #512
   3042c: e2c44c03     	sbc	r4, r4, #768
   30430: 2a000002     	bhs	0x30440 <__muldf3+0x84> @ imm = #0x8
   30434: e1b0e08e     	lsls	lr, lr, #1
   30438: e0b55005     	adcs	r5, r5, r5
   3043c: e0a66006     	adc	r6, r6, r6
   30440: e1821586     	orr	r1, r2, r6, lsl #11
   30444: e1811aa5     	orr	r1, r1, r5, lsr #21
   30448: e1a00585     	lsl	r0, r5, #11
   3044c: e1800aae     	orr	r0, r0, lr, lsr #21
   30450: e1a0e58e     	lsl	lr, lr, #11
   30454: e254c0fd     	subs	r12, r4, #253
   30458: 835c0c07     	cmphi	r12, #1792
   3045c: 8a00000f     	bhi	0x304a0 <__muldf3+0xe4> @ imm = #0x3c
   30460: e35e0102     	cmp	lr, #-2147483648
   30464: 01b0e0a0     	lsrseq	lr, r0, #1
   30468: e2b00000     	adcs	r0, r0, #0
   3046c: e0a11a04     	adc	r1, r1, r4, lsl #20
   30470: e8bd8070     	pop	{r4, r5, r6, pc}
   30474: e2066102     	and	r6, r6, #-2147483648
   30478: e1861001     	orr	r1, r6, r1
   3047c: e1800002     	orr	r0, r0, r2
   30480: e0211003     	eor	r1, r1, r3
   30484: e05440ac     	subs	r4, r4, r12, lsr #1
   30488: c074500c     	rsbsgt	r5, r4, r12
   3048c: c1811a04     	orrgt	r1, r1, r4, lsl #20
   30490: c8bd8070     	popgt	{r4, r5, r6, pc}
   30494: e3811601     	orr	r1, r1, #1048576
   30498: e3a0e000     	mov	lr, #0
   3049c: e2544001     	subs	r4, r4, #1
   304a0: ca000058     	bgt	0x30608 <__muldf3+0x24c> @ imm = #0x160
   304a4: e3740036     	cmn	r4, #54
   304a8: d3a00000     	movle	r0, #0
   304ac: d2011102     	andle	r1, r1, #-2147483648
   304b0: d8bd8070     	pople	{r4, r5, r6, pc}
   304b4: e2644000     	rsb	r4, r4, #0
   304b8: e2544020     	subs	r4, r4, #32
   304bc: aa000018     	bge	0x30524 <__muldf3+0x168> @ imm = #0x60
   304c0: e294400c     	adds	r4, r4, #12
   304c4: ca00000b     	bgt	0x304f8 <__muldf3+0x13c> @ imm = #0x2c
   304c8: e2844014     	add	r4, r4, #20
   304cc: e2645020     	rsb	r5, r4, #32
   304d0: e1a03510     	lsl	r3, r0, r5
   304d4: e1a00430     	lsr	r0, r0, r4
   304d8: e1800511     	orr	r0, r0, r1, lsl r5
   304dc: e2012102     	and	r2, r1, #-2147483648
   304e0: e3c11102     	bic	r1, r1, #-2147483648
   304e4: e0900fa3     	adds	r0, r0, r3, lsr #31
   304e8: e0a21431     	adc	r1, r2, r1, lsr r4
   304ec: e19ee083     	orrs	lr, lr, r3, lsl #1
   304f0: 01c00fa3     	biceq	r0, r0, r3, lsr #31
   304f4: e8bd8070     	pop	{r4, r5, r6, pc}
   304f8: e264400c     	rsb	r4, r4, #12
   304fc: e2645020     	rsb	r5, r4, #32
   30500: e1a03410     	lsl	r3, r0, r4
   30504: e1a00530     	lsr	r0, r0, r5
   30508: e1800411     	orr	r0, r0, r1, lsl r4
   3050c: e2011102     	and	r1, r1, #-2147483648
   30510: e0900fa3     	adds	r0, r0, r3, lsr #31
   30514: e2a11000     	adc	r1, r1, #0
   30518: e19ee083     	orrs	lr, lr, r3, lsl #1
   3051c: 01c00fa3     	biceq	r0, r0, r3, lsr #31
   30520: e8bd8070     	pop	{r4, r5, r6, pc}
   30524: e2645020     	rsb	r5, r4, #32
   30528: e18ee510     	orr	lr, lr, r0, lsl r5
   3052c: e1a03430     	lsr	r3, r0, r4
   30530: e1833511     	orr	r3, r3, r1, lsl r5
   30534: e1a00431     	lsr	r0, r1, r4
   30538: e2011102     	and	r1, r1, #-2147483648
   3053c: e1c00431     	bic	r0, r0, r1, lsr r4
   30540: e0800fa3     	add	r0, r0, r3, lsr #31
   30544: e19ee083     	orrs	lr, lr, r3, lsl #1
   30548: 01c00fa3     	biceq	r0, r0, r3, lsr #31
   3054c: e8bd8070     	pop	{r4, r5, r6, pc}
   30550: e3340000     	teq	r4, #0
   30554: 1a000008     	bne	0x3057c <__muldf3+0x1c0> @ imm = #0x20
   30558: e2016102     	and	r6, r1, #-2147483648
   3055c: e1b00080     	lsls	r0, r0, #1
   30560: e0a11001     	adc	r1, r1, r1
   30564: e3110601     	tst	r1, #1048576
   30568: 02444001     	subeq	r4, r4, #1
   3056c: 0afffffa     	beq	0x3055c <__muldf3+0x1a0> @ imm = #-0x18
   30570: e1811006     	orr	r1, r1, r6
   30574: e3350000     	teq	r5, #0
   30578: 112fff1e     	bxne	lr
   3057c: e2036102     	and	r6, r3, #-2147483648
   30580: e1b02082     	lsls	r2, r2, #1
   30584: e0a33003     	adc	r3, r3, r3
   30588: e3130601     	tst	r3, #1048576
   3058c: 02455001     	subeq	r5, r5, #1
   30590: 0afffffa     	beq	0x30580 <__muldf3+0x1c4> @ imm = #-0x18
   30594: e1833006     	orr	r3, r3, r6
   30598: e12fff1e     	bx	lr
   3059c: e134000c     	teq	r4, r12
   305a0: e00c5a23     	and	r5, r12, r3, lsr #20
   305a4: 1135000c     	teqne	r5, r12
   305a8: 0a000006     	beq	0x305c8 <__muldf3+0x20c> @ imm = #0x18
   305ac: e1906081     	orrs	r6, r0, r1, lsl #1
   305b0: 11926083     	orrsne	r6, r2, r3, lsl #1
   305b4: 1affffe5     	bne	0x30550 <__muldf3+0x194> @ imm = #-0x6c
   305b8: e0211003     	eor	r1, r1, r3
   305bc: e2011102     	and	r1, r1, #-2147483648
   305c0: e3a00000     	mov	r0, #0
   305c4: e8bd8070     	pop	{r4, r5, r6, pc}
   305c8: e1906081     	orrs	r6, r0, r1, lsl #1
   305cc: 01a00002     	moveq	r0, r2
   305d0: 01a01003     	moveq	r1, r3
   305d4: 11926083     	orrsne	r6, r2, r3, lsl #1
   305d8: 0a00000f     	beq	0x3061c <__muldf3+0x260> @ imm = #0x3c
   305dc: e134000c     	teq	r4, r12
   305e0: 1a000001     	bne	0x305ec <__muldf3+0x230> @ imm = #0x4
   305e4: e1906601     	orrs	r6, r0, r1, lsl #12
   305e8: 1a00000b     	bne	0x3061c <__muldf3+0x260> @ imm = #0x2c
   305ec: e135000c     	teq	r5, r12
   305f0: 1a000003     	bne	0x30604 <__muldf3+0x248> @ imm = #0xc
   305f4: e1926603     	orrs	r6, r2, r3, lsl #12
   305f8: 11a00002     	movne	r0, r2
   305fc: 11a01003     	movne	r1, r3
   30600: 1a000005     	bne	0x3061c <__muldf3+0x260> @ imm = #0x14
   30604: e0211003     	eor	r1, r1, r3
   30608: e2011102     	and	r1, r1, #-2147483648
   3060c: e381147f     	orr	r1, r1, #2130706432
   30610: e381160f     	orr	r1, r1, #15728640
   30614: e3a00000     	mov	r0, #0
   30618: e8bd8070     	pop	{r4, r5, r6, pc}
   3061c: e381147f     	orr	r1, r1, #2130706432
   30620: e381173e     	orr	r1, r1, #16252928
   30624: e8bd8070     	pop	{r4, r5, r6, pc}

