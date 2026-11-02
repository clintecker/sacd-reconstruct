000314d8 <__udivdi3>:
   314d8: e92d4ff0     	push	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
   314dc: e24dd00c     	sub	sp, sp, #12
   314e0: e3530000     	cmp	r3, #0
   314e4: e1a0b001     	mov	r11, r1
   314e8: e1a05000     	mov	r5, r0
   314ec: e1a04002     	mov	r4, r2
   314f0: e1a06001     	mov	r6, r1
   314f4: 1a000034     	bne	0x315cc <__udivdi3+0xf4> @ imm = #0xd0
   314f8: e1520001     	cmp	r2, r1
   314fc: 9a000082     	bls	0x3170c <__udivdi3+0x234> @ imm = #0x208
   31500: e16f3f12     	clz	r3, r2
   31504: e3530000     	cmp	r3, #0
   31508: 12632020     	rsbne	r2, r3, #32
   3150c: 11a02230     	lsrne	r2, r0, r2
   31510: 11a04314     	lslne	r4, r4, r3
   31514: 11826311     	orrne	r6, r2, r1, lsl r3
   31518: e1a07824     	lsr	r7, r4, #16
   3151c: 11a05310     	lslne	r5, r0, r3
   31520: e1a01007     	mov	r1, r7
   31524: e1a00006     	mov	r0, r6
   31528: ebfffa21     	bl	0x2fdb4 <__aeabi_uidivmod> @ imm = #-0x177c
   3152c: e1a00006     	mov	r0, r6
   31530: e1a09001     	mov	r9, r1
   31534: e1a01007     	mov	r1, r7
   31538: ebfff9a1     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x197c
   3153c: e1a06804     	lsl	r6, r4, #16
   31540: e1a06826     	lsr	r6, r6, #16
   31544: e00a0096     	mul	r10, r6, r0
   31548: e1a03825     	lsr	r3, r5, #16
   3154c: e1839809     	orr	r9, r3, r9, lsl #16
   31550: e15a0009     	cmp	r10, r9
   31554: e1a08000     	mov	r8, r0
   31558: 9a000005     	bls	0x31574 <__udivdi3+0x9c> @ imm = #0x14
   3155c: e0999004     	adds	r9, r9, r4
   31560: e2408001     	sub	r8, r0, #1
   31564: 2a000002     	bhs	0x31574 <__udivdi3+0x9c> @ imm = #0x8
   31568: e15a0009     	cmp	r10, r9
   3156c: 82488001     	subhi	r8, r8, #1
   31570: 80899004     	addhi	r9, r9, r4
   31574: e06aa009     	rsb	r10, r10, r9
   31578: e1a0000a     	mov	r0, r10
   3157c: e1a01007     	mov	r1, r7
   31580: ebfffa0b     	bl	0x2fdb4 <__aeabi_uidivmod> @ imm = #-0x17d4
   31584: e1a0000a     	mov	r0, r10
   31588: e1a0b001     	mov	r11, r1
   3158c: e1a01007     	mov	r1, r7
   31590: ebfff98b     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x19d4
   31594: e0060096     	mul	r6, r6, r0
   31598: e1a05805     	lsl	r5, r5, #16
   3159c: e1a05825     	lsr	r5, r5, #16
   315a0: e185580b     	orr	r5, r5, r11, lsl #16
   315a4: e1560005     	cmp	r6, r5
   315a8: 9a000004     	bls	0x315c0 <__udivdi3+0xe8> @ imm = #0x10
   315ac: e0955004     	adds	r5, r5, r4
   315b0: e2400001     	sub	r0, r0, #1
   315b4: 2a000001     	bhs	0x315c0 <__udivdi3+0xe8> @ imm = #0x4
   315b8: e1560005     	cmp	r6, r5
   315bc: 82400001     	subhi	r0, r0, #1
   315c0: e180a808     	orr	r10, r0, r8, lsl #16
   315c4: e3a01000     	mov	r1, #0
   315c8: ea00008d     	b	0x31804 <__udivdi3+0x32c> @ imm = #0x234
   315cc: e1530001     	cmp	r3, r1
   315d0: 8a000089     	bhi	0x317fc <__udivdi3+0x324> @ imm = #0x224
   315d4: e16f6f13     	clz	r6, r3
   315d8: e3560000     	cmp	r6, #0
   315dc: 0a000081     	beq	0x317e8 <__udivdi3+0x310> @ imm = #0x204
   315e0: e2668020     	rsb	r8, r6, #32
   315e4: e1a07832     	lsr	r7, r2, r8
   315e8: e1877613     	orr	r7, r7, r3, lsl r6
   315ec: e1a02830     	lsr	r2, r0, r8
   315f0: e1a08831     	lsr	r8, r1, r8
   315f4: e1a0a827     	lsr	r10, r7, #16
   315f8: e182b611     	orr	r11, r2, r1, lsl r6
   315fc: e1a00008     	mov	r0, r8
   31600: e1a0100a     	mov	r1, r10
   31604: ebfff9ea     	bl	0x2fdb4 <__aeabi_uidivmod> @ imm = #-0x1858
   31608: e1a00008     	mov	r0, r8
   3160c: e1a03001     	mov	r3, r1
   31610: e1a0100a     	mov	r1, r10
   31614: e58d3000     	str	r3, [sp]
   31618: ebfff969     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x1a5c
   3161c: e1a08807     	lsl	r8, r7, #16
   31620: e1a08828     	lsr	r8, r8, #16
   31624: e0010098     	mul	r1, r8, r0
   31628: e59d3000     	ldr	r3, [sp]
   3162c: e1a0282b     	lsr	r2, r11, #16
   31630: e1823803     	orr	r3, r2, r3, lsl #16
   31634: e1510003     	cmp	r1, r3
   31638: e1a09000     	mov	r9, r0
   3163c: e1a02614     	lsl	r2, r4, r6
   31640: 9a000002     	bls	0x31650 <__udivdi3+0x178> @ imm = #0x8
   31644: e0933007     	adds	r3, r3, r7
   31648: e2409001     	sub	r9, r0, #1
   3164c: 3a0000a5     	blo	0x318e8 <__udivdi3+0x410> @ imm = #0x294
   31650: e0614003     	rsb	r4, r1, r3
   31654: e1a00004     	mov	r0, r4
   31658: e1a0100a     	mov	r1, r10
   3165c: e58d2004     	str	r2, [sp, #0x4]
   31660: ebfff9d3     	bl	0x2fdb4 <__aeabi_uidivmod> @ imm = #-0x18b4
   31664: e1a00004     	mov	r0, r4
   31668: e1a03001     	mov	r3, r1
   3166c: e1a0100a     	mov	r1, r10
   31670: e58d3000     	str	r3, [sp]
   31674: ebfff952     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x1ab8
   31678: e0080098     	mul	r8, r8, r0
   3167c: e1a0b80b     	lsl	r11, r11, #16
   31680: e59d3000     	ldr	r3, [sp]
   31684: e1a0b82b     	lsr	r11, r11, #16
   31688: e18b3803     	orr	r3, r11, r3, lsl #16
   3168c: e1580003     	cmp	r8, r3
   31690: e59d2004     	ldr	r2, [sp, #0x4]
   31694: 9a000002     	bls	0x316a4 <__udivdi3+0x1cc> @ imm = #0x8
   31698: e0933007     	adds	r3, r3, r7
   3169c: e2400001     	sub	r0, r0, #1
   316a0: 3a00008c     	blo	0x318d8 <__udivdi3+0x400> @ imm = #0x230
   316a4: e0683003     	rsb	r3, r8, r3
   316a8: e180a809     	orr	r10, r0, r9, lsl #16
   316ac: e1a0c82a     	lsr	r12, r10, #16
   316b0: e1a01822     	lsr	r1, r2, #16
   316b4: e1ca780c     	bic	r7, r10, r12, lsl #16
   316b8: e1c24801     	bic	r4, r2, r1, lsl #16
   316bc: e0000497     	mul	r0, r7, r4
   316c0: e004049c     	mul	r4, r12, r4
   316c4: e0070791     	mul	r7, r1, r7
   316c8: e001019c     	mul	r1, r12, r1
   316cc: e0947007     	adds	r7, r4, r7
   316d0: 22811801     	addhs	r1, r1, #65536
   316d4: e0900807     	adds	r0, r0, r7, lsl #16
   316d8: e0a11827     	adc	r1, r1, r7, lsr #16
   316dc: e1530001     	cmp	r3, r1
   316e0: 3a000006     	blo	0x31700 <__udivdi3+0x228> @ imm = #0x18
   316e4: 13a01000     	movne	r1, #0
   316e8: 03a01001     	moveq	r1, #1
   316ec: e1500615     	cmp	r0, r5, lsl r6
   316f0: 93a01000     	movls	r1, #0
   316f4: 82011001     	andhi	r1, r1, #1
   316f8: e3510000     	cmp	r1, #0
   316fc: 0a000040     	beq	0x31804 <__udivdi3+0x32c> @ imm = #0x100
   31700: e24aa001     	sub	r10, r10, #1
   31704: e3a01000     	mov	r1, #0
   31708: ea00003d     	b	0x31804 <__udivdi3+0x32c> @ imm = #0xf4
   3170c: e3520000     	cmp	r2, #0
   31710: 1a000003     	bne	0x31724 <__udivdi3+0x24c> @ imm = #0xc
   31714: e1a01002     	mov	r1, r2
   31718: e3a00001     	mov	r0, #1
   3171c: ebfff928     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x1b60
   31720: e1a04000     	mov	r4, r0
   31724: e16faf14     	clz	r10, r4
   31728: e35a0000     	cmp	r10, #0
   3172c: 1a000037     	bne	0x31810 <__udivdi3+0x338> @ imm = #0xdc
   31730: e1a08804     	lsl	r8, r4, #16
   31734: e064b00b     	rsb	r11, r4, r11
   31738: e1a08828     	lsr	r8, r8, #16
   3173c: e1a07824     	lsr	r7, r4, #16
   31740: e3a06001     	mov	r6, #1
   31744: e1a0000b     	mov	r0, r11
   31748: e1a01007     	mov	r1, r7
   3174c: ebfff998     	bl	0x2fdb4 <__aeabi_uidivmod> @ imm = #-0x19a0
   31750: e1a0000b     	mov	r0, r11
   31754: e1a09001     	mov	r9, r1
   31758: e1a01007     	mov	r1, r7
   3175c: ebfff918     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x1ba0
   31760: e0030098     	mul	r3, r8, r0
   31764: e1a02825     	lsr	r2, r5, #16
   31768: e1829809     	orr	r9, r2, r9, lsl #16
   3176c: e1530009     	cmp	r3, r9
   31770: e1a0a000     	mov	r10, r0
   31774: 9a000005     	bls	0x31790 <__udivdi3+0x2b8> @ imm = #0x14
   31778: e0999004     	adds	r9, r9, r4
   3177c: e240a001     	sub	r10, r0, #1
   31780: 2a000002     	bhs	0x31790 <__udivdi3+0x2b8> @ imm = #0x8
   31784: e1530009     	cmp	r3, r9
   31788: 824aa001     	subhi	r10, r10, #1
   3178c: 80899004     	addhi	r9, r9, r4
   31790: e0639009     	rsb	r9, r3, r9
   31794: e1a00009     	mov	r0, r9
   31798: e1a01007     	mov	r1, r7
   3179c: ebfff984     	bl	0x2fdb4 <__aeabi_uidivmod> @ imm = #-0x19f0
   317a0: e1a00009     	mov	r0, r9
   317a4: e1a0b001     	mov	r11, r1
   317a8: e1a01007     	mov	r1, r7
   317ac: ebfff904     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x1bf0
   317b0: e0080098     	mul	r8, r8, r0
   317b4: e1a05805     	lsl	r5, r5, #16
   317b8: e1a05825     	lsr	r5, r5, #16
   317bc: e185580b     	orr	r5, r5, r11, lsl #16
   317c0: e1580005     	cmp	r8, r5
   317c4: 9a000004     	bls	0x317dc <__udivdi3+0x304> @ imm = #0x10
   317c8: e0955004     	adds	r5, r5, r4
   317cc: e2400001     	sub	r0, r0, #1
   317d0: 2a000001     	bhs	0x317dc <__udivdi3+0x304> @ imm = #0x4
   317d4: e1580005     	cmp	r8, r5
   317d8: 82400001     	subhi	r0, r0, #1
   317dc: e180a80a     	orr	r10, r0, r10, lsl #16
   317e0: e1a01006     	mov	r1, r6
   317e4: ea000006     	b	0x31804 <__udivdi3+0x32c> @ imm = #0x18
   317e8: e1530001     	cmp	r3, r1
   317ec: 21520000     	cmphs	r2, r0
   317f0: 91a01006     	movls	r1, r6
   317f4: 93a0a001     	movls	r10, #1
   317f8: 9a000001     	bls	0x31804 <__udivdi3+0x32c> @ imm = #0x4
   317fc: e3a01000     	mov	r1, #0
   31800: e1a0a001     	mov	r10, r1
   31804: e1a0000a     	mov	r0, r10
   31808: e28dd00c     	add	sp, sp, #12
   3180c: e8bd8ff0     	pop	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
   31810: e26a6020     	rsb	r6, r10, #32
   31814: e1a04a14     	lsl	r4, r4, r10
   31818: e1a03635     	lsr	r3, r5, r6
   3181c: e1a0663b     	lsr	r6, r11, r6
   31820: e1a07824     	lsr	r7, r4, #16
   31824: e1a00006     	mov	r0, r6
   31828: e1a01007     	mov	r1, r7
   3182c: e183ba1b     	orr	r11, r3, r11, lsl r10
   31830: ebfff95f     	bl	0x2fdb4 <__aeabi_uidivmod> @ imm = #-0x1a84
   31834: e1a00006     	mov	r0, r6
   31838: e1a09001     	mov	r9, r1
   3183c: e1a01007     	mov	r1, r7
   31840: ebfff8df     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x1c84
   31844: e1a08804     	lsl	r8, r4, #16
   31848: e1a08828     	lsr	r8, r8, #16
   3184c: e0030098     	mul	r3, r8, r0
   31850: e1a0282b     	lsr	r2, r11, #16
   31854: e1829809     	orr	r9, r2, r9, lsl #16
   31858: e1530009     	cmp	r3, r9
   3185c: e1a06000     	mov	r6, r0
   31860: 9a000002     	bls	0x31870 <__udivdi3+0x398> @ imm = #0x8
   31864: e0999004     	adds	r9, r9, r4
   31868: e2406001     	sub	r6, r0, #1
   3186c: 3a000021     	blo	0x318f8 <__udivdi3+0x420> @ imm = #0x84
   31870: e0639009     	rsb	r9, r3, r9
   31874: e1a00009     	mov	r0, r9
   31878: e1a01007     	mov	r1, r7
   3187c: ebfff94c     	bl	0x2fdb4 <__aeabi_uidivmod> @ imm = #-0x1ad0
   31880: e1a00009     	mov	r0, r9
   31884: e1a03001     	mov	r3, r1
   31888: e1a01007     	mov	r1, r7
   3188c: e58d3000     	str	r3, [sp]
   31890: ebfff8cb     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x1cd4
   31894: e0020098     	mul	r2, r8, r0
   31898: e1a0b80b     	lsl	r11, r11, #16
   3189c: e59d3000     	ldr	r3, [sp]
   318a0: e1a0b82b     	lsr	r11, r11, #16
   318a4: e18b3803     	orr	r3, r11, r3, lsl #16
   318a8: e1520003     	cmp	r2, r3
   318ac: 9a000005     	bls	0x318c8 <__udivdi3+0x3f0> @ imm = #0x14
   318b0: e0933004     	adds	r3, r3, r4
   318b4: e2400001     	sub	r0, r0, #1
   318b8: 2a000002     	bhs	0x318c8 <__udivdi3+0x3f0> @ imm = #0x8
   318bc: e1520003     	cmp	r2, r3
   318c0: 82400001     	subhi	r0, r0, #1
   318c4: 80833004     	addhi	r3, r3, r4
   318c8: e1a05a15     	lsl	r5, r5, r10
   318cc: e062b003     	rsb	r11, r2, r3
   318d0: e1806806     	orr	r6, r0, r6, lsl #16
   318d4: eaffff9a     	b	0x31744 <__udivdi3+0x26c> @ imm = #-0x198
   318d8: e1580003     	cmp	r8, r3
   318dc: 80833007     	addhi	r3, r3, r7
   318e0: 82400001     	subhi	r0, r0, #1
   318e4: eaffff6e     	b	0x316a4 <__udivdi3+0x1cc> @ imm = #-0x248
   318e8: e1510003     	cmp	r1, r3
   318ec: 82499001     	subhi	r9, r9, #1
   318f0: 80833007     	addhi	r3, r3, r7
   318f4: eaffff55     	b	0x31650 <__udivdi3+0x178> @ imm = #-0x2ac
   318f8: e1530009     	cmp	r3, r9
   318fc: 82466001     	subhi	r6, r6, #1
   31900: 80899004     	addhi	r9, r9, r4
   31904: eaffffd9     	b	0x31870 <__udivdi3+0x398> @ imm = #-0x9c

