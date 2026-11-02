00030010 <__aeabi_dadd>:
   30010: e92d4030     	push	{r4, r5, lr}
   30014: e1a04081     	lsl	r4, r1, #1
   30018: e1a05083     	lsl	r5, r3, #1
   3001c: e1340005     	teq	r4, r5
   30020: 01300002     	teqeq	r0, r2
   30024: 1194c000     	orrsne	r12, r4, r0
   30028: 1195c002     	orrsne	r12, r5, r2
   3002c: 11f0cac4     	mvnsne	r12, r4, asr #21
   30030: 11f0cac5     	mvnsne	r12, r5, asr #21
   30034: 0a000079     	beq	0x30220 <__aeabi_dadd+0x210> @ imm = #0x1e4
   30038: e1a04aa4     	lsr	r4, r4, #21
   3003c: e0745aa5     	rsbs	r5, r4, r5, lsr #21
   30040: b2655000     	rsblt	r5, r5, #0
   30044: da000006     	ble	0x30064 <__aeabi_dadd+0x54> @ imm = #0x18
   30048: e0844005     	add	r4, r4, r5
   3004c: e0202002     	eor	r2, r0, r2
   30050: e0213003     	eor	r3, r1, r3
   30054: e0220000     	eor	r0, r2, r0
   30058: e0231001     	eor	r1, r3, r1
   3005c: e0202002     	eor	r2, r0, r2
   30060: e0213003     	eor	r3, r1, r3
   30064: e3550036     	cmp	r5, #54
   30068: 88bd8030     	pophi	{r4, r5, pc}
   3006c: e3110102     	tst	r1, #-2147483648
   30070: e1a01601     	lsl	r1, r1, #12
   30074: e3a0c601     	mov	r12, #1048576
   30078: e18c1621     	orr	r1, r12, r1, lsr #12
   3007c: 0a000001     	beq	0x30088 <__aeabi_dadd+0x78> @ imm = #0x4
   30080: e2700000     	rsbs	r0, r0, #0
   30084: e2e11000     	rsc	r1, r1, #0
   30088: e3130102     	tst	r3, #-2147483648
   3008c: e1a03603     	lsl	r3, r3, #12
   30090: e18c3623     	orr	r3, r12, r3, lsr #12
   30094: 0a000001     	beq	0x300a0 <__aeabi_dadd+0x90> @ imm = #0x4
   30098: e2722000     	rsbs	r2, r2, #0
   3009c: e2e33000     	rsc	r3, r3, #0
   300a0: e1340005     	teq	r4, r5
   300a4: 0a000057     	beq	0x30208 <__aeabi_dadd+0x1f8> @ imm = #0x15c
   300a8: e2444001     	sub	r4, r4, #1
   300ac: e275e020     	rsbs	lr, r5, #32
   300b0: ba000005     	blt	0x300cc <__aeabi_dadd+0xbc> @ imm = #0x14
   300b4: e1a0ce12     	lsl	r12, r2, lr
   300b8: e0900532     	adds	r0, r0, r2, lsr r5
   300bc: e2a11000     	adc	r1, r1, #0
   300c0: e0900e13     	adds	r0, r0, r3, lsl lr
   300c4: e0b11553     	adcs	r1, r1, r3, asr r5
   300c8: ea000006     	b	0x300e8 <__aeabi_dadd+0xd8> @ imm = #0x18
   300cc: e2455020     	sub	r5, r5, #32
   300d0: e28ee020     	add	lr, lr, #32
   300d4: e3520001     	cmp	r2, #1
   300d8: e1a0ce13     	lsl	r12, r3, lr
   300dc: 238cc002     	orrhs	r12, r12, #2
   300e0: e0900553     	adds	r0, r0, r3, asr r5
   300e4: e0b11fc3     	adcs	r1, r1, r3, asr #31
   300e8: e2015102     	and	r5, r1, #-2147483648
   300ec: 5a000002     	bpl	0x300fc <__aeabi_dadd+0xec> @ imm = #0x8
   300f0: e27cc000     	rsbs	r12, r12, #0
   300f4: e2f00000     	rscs	r0, r0, #0
   300f8: e2e11000     	rsc	r1, r1, #0
   300fc: e3510601     	cmp	r1, #1048576
   30100: 3a00000e     	blo	0x30140 <__aeabi_dadd+0x130> @ imm = #0x38
   30104: e3510602     	cmp	r1, #2097152
   30108: 3a000006     	blo	0x30128 <__aeabi_dadd+0x118> @ imm = #0x18
   3010c: e1b010a1     	lsrs	r1, r1, #1
   30110: e1b00060     	rrxs	r0, r0
   30114: e1a0c06c     	rrx	r12, r12
   30118: e2844001     	add	r4, r4, #1
   3011c: e1a02a84     	lsl	r2, r4, #21
   30120: e3720501     	cmn	r2, #4194304
   30124: 2a000055     	bhs	0x30280 <__aeabi_dadd+0x270> @ imm = #0x154
   30128: e35c0102     	cmp	r12, #-2147483648
   3012c: 01b0c0a0     	lsrseq	r12, r0, #1
   30130: e2b00000     	adcs	r0, r0, #0
   30134: e0a11a04     	adc	r1, r1, r4, lsl #20
   30138: e1811005     	orr	r1, r1, r5
   3013c: e8bd8030     	pop	{r4, r5, pc}
   30140: e1b0c08c     	lsls	r12, r12, #1
   30144: e0b00000     	adcs	r0, r0, r0
   30148: e0a11001     	adc	r1, r1, r1
   3014c: e3110601     	tst	r1, #1048576
   30150: e2444001     	sub	r4, r4, #1
   30154: 1afffff3     	bne	0x30128 <__aeabi_dadd+0x118> @ imm = #-0x34
   30158: e3310000     	teq	r1, #0
   3015c: 01a01000     	moveq	r1, r0
   30160: 03a00000     	moveq	r0, #0
   30164: e16f3f11     	clz	r3, r1
   30168: 02833020     	addeq	r3, r3, #32
   3016c: e243300b     	sub	r3, r3, #11
   30170: e2532020     	subs	r2, r3, #32
   30174: aa000007     	bge	0x30198 <__aeabi_dadd+0x188> @ imm = #0x1c
   30178: e292200c     	adds	r2, r2, #12
   3017c: da000004     	ble	0x30194 <__aeabi_dadd+0x184> @ imm = #0x10
   30180: e282c014     	add	r12, r2, #20
   30184: e262200c     	rsb	r2, r2, #12
   30188: e1a00c11     	lsl	r0, r1, r12
   3018c: e1a01231     	lsr	r1, r1, r2
   30190: ea000004     	b	0x301a8 <__aeabi_dadd+0x198> @ imm = #0x10
   30194: e2822014     	add	r2, r2, #20
   30198: d262c020     	rsble	r12, r2, #32
   3019c: e1a01211     	lsl	r1, r1, r2
   301a0: d1811c30     	orrle	r1, r1, r0, lsr r12
   301a4: d1a00210     	lslle	r0, r0, r2
   301a8: e0544003     	subs	r4, r4, r3
   301ac: a0811a04     	addge	r1, r1, r4, lsl #20
   301b0: a1811005     	orrge	r1, r1, r5
   301b4: a8bd8030     	popge	{r4, r5, pc}
   301b8: e1e04004     	mvn	r4, r4
   301bc: e254401f     	subs	r4, r4, #31
   301c0: aa00000d     	bge	0x301fc <__aeabi_dadd+0x1ec> @ imm = #0x34
   301c4: e294400c     	adds	r4, r4, #12
   301c8: ca000005     	bgt	0x301e4 <__aeabi_dadd+0x1d4> @ imm = #0x14
   301cc: e2844014     	add	r4, r4, #20
   301d0: e2642020     	rsb	r2, r4, #32
   301d4: e1a00430     	lsr	r0, r0, r4
   301d8: e1800211     	orr	r0, r0, r1, lsl r2
   301dc: e1851431     	orr	r1, r5, r1, lsr r4
   301e0: e8bd8030     	pop	{r4, r5, pc}
   301e4: e264400c     	rsb	r4, r4, #12
   301e8: e2642020     	rsb	r2, r4, #32
   301ec: e1a00230     	lsr	r0, r0, r2
   301f0: e1800411     	orr	r0, r0, r1, lsl r4
   301f4: e1a01005     	mov	r1, r5
   301f8: e8bd8030     	pop	{r4, r5, pc}
   301fc: e1a00431     	lsr	r0, r1, r4
   30200: e1a01005     	mov	r1, r5
   30204: e8bd8030     	pop	{r4, r5, pc}
   30208: e3340000     	teq	r4, #0
   3020c: e2233601     	eor	r3, r3, #1048576
   30210: 02211601     	eoreq	r1, r1, #1048576
   30214: 02844001     	addeq	r4, r4, #1
   30218: 12455001     	subne	r5, r5, #1
   3021c: eaffffa1     	b	0x300a8 <__aeabi_dadd+0x98> @ imm = #-0x17c
   30220: e1f0cac4     	mvns	r12, r4, asr #21
   30224: 11f0cac5     	mvnsne	r12, r5, asr #21
   30228: 0a000018     	beq	0x30290 <__aeabi_dadd+0x280> @ imm = #0x60
   3022c: e1340005     	teq	r4, r5
   30230: 01300002     	teqeq	r0, r2
   30234: 0a000003     	beq	0x30248 <__aeabi_dadd+0x238> @ imm = #0xc
   30238: e194c000     	orrs	r12, r4, r0
   3023c: 01a01003     	moveq	r1, r3
   30240: 01a00002     	moveq	r0, r2
   30244: e8bd8030     	pop	{r4, r5, pc}
   30248: e1310003     	teq	r1, r3
   3024c: 13a01000     	movne	r1, #0
   30250: 13a00000     	movne	r0, #0
   30254: 18bd8030     	popne	{r4, r5, pc}
   30258: e1b0caa4     	lsrs	r12, r4, #21
   3025c: 1a000003     	bne	0x30270 <__aeabi_dadd+0x260> @ imm = #0xc
   30260: e1b00080     	lsls	r0, r0, #1
   30264: e0b11001     	adcs	r1, r1, r1
   30268: 23811102     	orrhs	r1, r1, #-2147483648
   3026c: e8bd8030     	pop	{r4, r5, pc}
   30270: e2944501     	adds	r4, r4, #4194304
   30274: 32811601     	addlo	r1, r1, #1048576
   30278: 38bd8030     	poplo	{r4, r5, pc}
   3027c: e2015102     	and	r5, r1, #-2147483648
   30280: e385147f     	orr	r1, r5, #2130706432
   30284: e381160f     	orr	r1, r1, #15728640
   30288: e3a00000     	mov	r0, #0
   3028c: e8bd8030     	pop	{r4, r5, pc}
   30290: e1f0cac4     	mvns	r12, r4, asr #21
   30294: 11a01003     	movne	r1, r3
   30298: 11a00002     	movne	r0, r2
   3029c: 01f0cac5     	mvnseq	r12, r5, asr #21
   302a0: 11a03001     	movne	r3, r1
   302a4: 11a02000     	movne	r2, r0
   302a8: e1904601     	orrs	r4, r0, r1, lsl #12
   302ac: 01925603     	orrseq	r5, r2, r3, lsl #12
   302b0: 01310003     	teqeq	r1, r3
   302b4: 13811702     	orrne	r1, r1, #524288
   302b8: e8bd8030     	pop	{r4, r5, pc}

