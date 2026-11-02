0003103c <__divdi3>:
   3103c: e92d4ff0     	push	{r4, r5, r6, r7, r8, r9, r10, r11, lr}
   31040: e24dd014     	sub	sp, sp, #20
   31044: e3510000     	cmp	r1, #0
   31048: a3a06000     	movge	r6, #0
   3104c: ba0000d6     	blt	0x313ac <__divdi3+0x370> @ imm = #0x358
   31050: e3530000     	cmp	r3, #0
   31054: ba0000d0     	blt	0x3139c <__divdi3+0x360> @ imm = #0x340
   31058: e253c000     	subs	r12, r3, #0
   3105c: e1a07001     	mov	r7, r1
   31060: e1a04002     	mov	r4, r2
   31064: e1a05000     	mov	r5, r0
   31068: 1a000034     	bne	0x31140 <__divdi3+0x104> @ imm = #0xd0
   3106c: e1520001     	cmp	r2, r1
   31070: 9a000040     	bls	0x31178 <__divdi3+0x13c> @ imm = #0x100
   31074: e16f3f12     	clz	r3, r2
   31078: e3530000     	cmp	r3, #0
   3107c: 12632020     	rsbne	r2, r3, #32
   31080: 11a02230     	lsrne	r2, r0, r2
   31084: 11a04314     	lslne	r4, r4, r3
   31088: 11827311     	orrne	r7, r2, r1, lsl r3
   3108c: e1a08824     	lsr	r8, r4, #16
   31090: 11a05310     	lslne	r5, r0, r3
   31094: e1a01008     	mov	r1, r8
   31098: e1a00007     	mov	r0, r7
   3109c: ebfffb44     	bl	0x2fdb4 <__aeabi_uidivmod> @ imm = #-0x12f0
   310a0: e1a00007     	mov	r0, r7
   310a4: e1a0b001     	mov	r11, r1
   310a8: e1a01008     	mov	r1, r8
   310ac: ebfffac4     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x14f0
   310b0: e1a07804     	lsl	r7, r4, #16
   310b4: e1a07827     	lsr	r7, r7, #16
   310b8: e0090097     	mul	r9, r7, r0
   310bc: e1a03825     	lsr	r3, r5, #16
   310c0: e183b80b     	orr	r11, r3, r11, lsl #16
   310c4: e159000b     	cmp	r9, r11
   310c8: e1a0a000     	mov	r10, r0
   310cc: 9a000005     	bls	0x310e8 <__divdi3+0xac> @ imm = #0x14
   310d0: e09bb004     	adds	r11, r11, r4
   310d4: e240a001     	sub	r10, r0, #1
   310d8: 2a000002     	bhs	0x310e8 <__divdi3+0xac> @ imm = #0x8
   310dc: e159000b     	cmp	r9, r11
   310e0: 824aa001     	subhi	r10, r10, #1
   310e4: 808bb004     	addhi	r11, r11, r4
   310e8: e069900b     	rsb	r9, r9, r11
   310ec: e1a00009     	mov	r0, r9
   310f0: e1a01008     	mov	r1, r8
   310f4: ebfffb2e     	bl	0x2fdb4 <__aeabi_uidivmod> @ imm = #-0x1348
   310f8: e1a00009     	mov	r0, r9
   310fc: e1a0b001     	mov	r11, r1
   31100: e1a01008     	mov	r1, r8
   31104: ebfffaae     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x1548
   31108: e0070097     	mul	r7, r7, r0
   3110c: e1a05805     	lsl	r5, r5, #16
   31110: e1a05825     	lsr	r5, r5, #16
   31114: e185580b     	orr	r5, r5, r11, lsl #16
   31118: e1570005     	cmp	r7, r5
   3111c: 9a000004     	bls	0x31134 <__divdi3+0xf8> @ imm = #0x10
   31120: e0955004     	adds	r5, r5, r4
   31124: e2400001     	sub	r0, r0, #1
   31128: 2a000001     	bhs	0x31134 <__divdi3+0xf8> @ imm = #0x4
   3112c: e1570005     	cmp	r7, r5
   31130: 82400001     	subhi	r0, r0, #1
   31134: e180a80a     	orr	r10, r0, r10, lsl #16
   31138: e3a08000     	mov	r8, #0
   3113c: ea000003     	b	0x31150 <__divdi3+0x114> @ imm = #0xc
   31140: e15c0001     	cmp	r12, r1
   31144: 9a000043     	bls	0x31258 <__divdi3+0x21c> @ imm = #0x10c
   31148: e3a08000     	mov	r8, #0
   3114c: e1a0a008     	mov	r10, r8
   31150: e3560000     	cmp	r6, #0
   31154: e1a0200a     	mov	r2, r10
   31158: e1a03008     	mov	r3, r8
   3115c: 0a000001     	beq	0x31168 <__divdi3+0x12c> @ imm = #0x4
   31160: e2722000     	rsbs	r2, r2, #0
   31164: e2e33000     	rsc	r3, r3, #0
   31168: e1a01003     	mov	r1, r3
   3116c: e1a00002     	mov	r0, r2
   31170: e28dd014     	add	sp, sp, #20
   31174: e8bd8ff0     	pop	{r4, r5, r6, r7, r8, r9, r10, r11, pc}
   31178: e3520000     	cmp	r2, #0
   3117c: 1a000003     	bne	0x31190 <__divdi3+0x154> @ imm = #0xc
   31180: e1a01002     	mov	r1, r2
   31184: e3a00001     	mov	r0, #1
   31188: ebfffa8d     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x15cc
   3118c: e1a04000     	mov	r4, r0
   31190: e16faf14     	clz	r10, r4
   31194: e35a0000     	cmp	r10, #0
   31198: 1a000087     	bne	0x313bc <__divdi3+0x380> @ imm = #0x21c
   3119c: e1a08804     	lsl	r8, r4, #16
   311a0: e3a00001     	mov	r0, #1
   311a4: e064a007     	rsb	r10, r4, r7
   311a8: e1a08828     	lsr	r8, r8, #16
   311ac: e1a07824     	lsr	r7, r4, #16
   311b0: e58d000c     	str	r0, [sp, #0xc]
   311b4: e1a0000a     	mov	r0, r10
   311b8: e1a01007     	mov	r1, r7
   311bc: ebfffafc     	bl	0x2fdb4 <__aeabi_uidivmod> @ imm = #-0x1410
   311c0: e1a0000a     	mov	r0, r10
   311c4: e1a0b001     	mov	r11, r1
   311c8: e1a01007     	mov	r1, r7
   311cc: ebfffa7c     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x1610
   311d0: e0090098     	mul	r9, r8, r0
   311d4: e1a03825     	lsr	r3, r5, #16
   311d8: e183b80b     	orr	r11, r3, r11, lsl #16
   311dc: e159000b     	cmp	r9, r11
   311e0: e1a0a000     	mov	r10, r0
   311e4: 9a000005     	bls	0x31200 <__divdi3+0x1c4> @ imm = #0x14
   311e8: e09bb004     	adds	r11, r11, r4
   311ec: e240a001     	sub	r10, r0, #1
   311f0: 2a000002     	bhs	0x31200 <__divdi3+0x1c4> @ imm = #0x8
   311f4: e159000b     	cmp	r9, r11
   311f8: 824aa001     	subhi	r10, r10, #1
   311fc: 808bb004     	addhi	r11, r11, r4
   31200: e069900b     	rsb	r9, r9, r11
   31204: e1a00009     	mov	r0, r9
   31208: e1a01007     	mov	r1, r7
   3120c: ebfffae8     	bl	0x2fdb4 <__aeabi_uidivmod> @ imm = #-0x1460
   31210: e1a00009     	mov	r0, r9
   31214: e1a0b001     	mov	r11, r1
   31218: e1a01007     	mov	r1, r7
   3121c: ebfffa68     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x1660
   31220: e0080098     	mul	r8, r8, r0
   31224: e1a05805     	lsl	r5, r5, #16
   31228: e1a05825     	lsr	r5, r5, #16
   3122c: e185580b     	orr	r5, r5, r11, lsl #16
   31230: e1580005     	cmp	r8, r5
   31234: 9a000004     	bls	0x3124c <__divdi3+0x210> @ imm = #0x10
   31238: e0955004     	adds	r5, r5, r4
   3123c: e2400001     	sub	r0, r0, #1
   31240: 2a000001     	bhs	0x3124c <__divdi3+0x210> @ imm = #0x4
   31244: e1580005     	cmp	r8, r5
   31248: 82400001     	subhi	r0, r0, #1
   3124c: e180a80a     	orr	r10, r0, r10, lsl #16
   31250: e59d800c     	ldr	r8, [sp, #0xc]
   31254: eaffffbd     	b	0x31150 <__divdi3+0x114> @ imm = #-0x10c
   31258: e16f8f1c     	clz	r8, r12
   3125c: e3580000     	cmp	r8, #0
   31260: 0a00008b     	beq	0x31494 <__divdi3+0x458> @ imm = #0x22c
   31264: e268a020     	rsb	r10, r8, #32
   31268: e1a09a32     	lsr	r9, r2, r10
   3126c: e1a03a30     	lsr	r3, r0, r10
   31270: e189981c     	orr	r9, r9, r12, lsl r8
   31274: e1a0aa31     	lsr	r10, r1, r10
   31278: e1833811     	orr	r3, r3, r1, lsl r8
   3127c: e1a0b829     	lsr	r11, r9, #16
   31280: e1a0000a     	mov	r0, r10
   31284: e1a0100b     	mov	r1, r11
   31288: e58d300c     	str	r3, [sp, #0xc]
   3128c: ebfffac8     	bl	0x2fdb4 <__aeabi_uidivmod> @ imm = #-0x14e0
   31290: e1a0000a     	mov	r0, r10
   31294: e1a03001     	mov	r3, r1
   31298: e1a0100b     	mov	r1, r11
   3129c: e58d3004     	str	r3, [sp, #0x4]
   312a0: ebfffa47     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x16e4
   312a4: e1a07809     	lsl	r7, r9, #16
   312a8: e1a07827     	lsr	r7, r7, #16
   312ac: e0010097     	mul	r1, r7, r0
   312b0: e1a0a000     	mov	r10, r0
   312b4: e59d000c     	ldr	r0, [sp, #0xc]
   312b8: e59d3004     	ldr	r3, [sp, #0x4]
   312bc: e1a02820     	lsr	r2, r0, #16
   312c0: e1823803     	orr	r3, r2, r3, lsl #16
   312c4: e1510003     	cmp	r1, r3
   312c8: e1a02814     	lsl	r2, r4, r8
   312cc: 9a000002     	bls	0x312dc <__divdi3+0x2a0> @ imm = #0x8
   312d0: e0933009     	adds	r3, r3, r9
   312d4: e24aa001     	sub	r10, r10, #1
   312d8: 3a000076     	blo	0x314b8 <__divdi3+0x47c> @ imm = #0x1d8
   312dc: e0614003     	rsb	r4, r1, r3
   312e0: e1a00004     	mov	r0, r4
   312e4: e1a0100b     	mov	r1, r11
   312e8: e58d2008     	str	r2, [sp, #0x8]
   312ec: ebfffab0     	bl	0x2fdb4 <__aeabi_uidivmod> @ imm = #-0x1540
   312f0: e1a00004     	mov	r0, r4
   312f4: e1a03001     	mov	r3, r1
   312f8: e1a0100b     	mov	r1, r11
   312fc: e58d3004     	str	r3, [sp, #0x4]
   31300: ebfffa2f     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x1744
   31304: e59dc00c     	ldr	r12, [sp, #0xc]
   31308: e0070097     	mul	r7, r7, r0
   3130c: e1a0180c     	lsl	r1, r12, #16
   31310: e59d3004     	ldr	r3, [sp, #0x4]
   31314: e1a01821     	lsr	r1, r1, #16
   31318: e1813803     	orr	r3, r1, r3, lsl #16
   3131c: e1570003     	cmp	r7, r3
   31320: e59d2008     	ldr	r2, [sp, #0x8]
   31324: 9a000002     	bls	0x31334 <__divdi3+0x2f8> @ imm = #0x8
   31328: e0933009     	adds	r3, r3, r9
   3132c: e2400001     	sub	r0, r0, #1
   31330: 3a00005c     	blo	0x314a8 <__divdi3+0x46c> @ imm = #0x170
   31334: e0673003     	rsb	r3, r7, r3
   31338: e180a80a     	orr	r10, r0, r10, lsl #16
   3133c: e1a0c82a     	lsr	r12, r10, #16
   31340: e1a01822     	lsr	r1, r2, #16
   31344: e1ca780c     	bic	r7, r10, r12, lsl #16
   31348: e1c24801     	bic	r4, r2, r1, lsl #16
   3134c: e0000497     	mul	r0, r7, r4
   31350: e004049c     	mul	r4, r12, r4
   31354: e0070791     	mul	r7, r1, r7
   31358: e001019c     	mul	r1, r12, r1
   3135c: e0947007     	adds	r7, r4, r7
   31360: 22811801     	addhs	r1, r1, #65536
   31364: e0900807     	adds	r0, r0, r7, lsl #16
   31368: e0a11827     	adc	r1, r1, r7, lsr #16
   3136c: e1530001     	cmp	r3, r1
   31370: 3a000006     	blo	0x31390 <__divdi3+0x354> @ imm = #0x18
   31374: 13a03000     	movne	r3, #0
   31378: 03a03001     	moveq	r3, #1
   3137c: e1500815     	cmp	r0, r5, lsl r8
   31380: 93a08000     	movls	r8, #0
   31384: 82038001     	andhi	r8, r3, #1
   31388: e3580000     	cmp	r8, #0
   3138c: 0affff6f     	beq	0x31150 <__divdi3+0x114> @ imm = #-0x244
   31390: e24aa001     	sub	r10, r10, #1
   31394: e3a08000     	mov	r8, #0
   31398: eaffff6c     	b	0x31150 <__divdi3+0x114> @ imm = #-0x250
   3139c: e2722000     	rsbs	r2, r2, #0
   313a0: e2e33000     	rsc	r3, r3, #0
   313a4: e1e06006     	mvn	r6, r6
   313a8: eaffff2a     	b	0x31058 <__divdi3+0x1c> @ imm = #-0x358
   313ac: e2700000     	rsbs	r0, r0, #0
   313b0: e2e11000     	rsc	r1, r1, #0
   313b4: e3e06000     	mvn	r6, #0
   313b8: eaffff24     	b	0x31050 <__divdi3+0x14> @ imm = #-0x370
   313bc: e26a8020     	rsb	r8, r10, #32
   313c0: e1a03835     	lsr	r3, r5, r8
   313c4: e1a04a14     	lsl	r4, r4, r10
   313c8: e1a08837     	lsr	r8, r7, r8
   313cc: e1833a17     	orr	r3, r3, r7, lsl r10
   313d0: e1a07824     	lsr	r7, r4, #16
   313d4: e1a00008     	mov	r0, r8
   313d8: e1a01007     	mov	r1, r7
   313dc: e58d300c     	str	r3, [sp, #0xc]
   313e0: ebfffa73     	bl	0x2fdb4 <__aeabi_uidivmod> @ imm = #-0x1634
   313e4: e1a00008     	mov	r0, r8
   313e8: e1a0b001     	mov	r11, r1
   313ec: e1a01007     	mov	r1, r7
   313f0: ebfff9f3     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x1834
   313f4: e1a08804     	lsl	r8, r4, #16
   313f8: e1a08828     	lsr	r8, r8, #16
   313fc: e0030098     	mul	r3, r8, r0
   31400: e59d100c     	ldr	r1, [sp, #0xc]
   31404: e1a09000     	mov	r9, r0
   31408: e1a02821     	lsr	r2, r1, #16
   3140c: e182b80b     	orr	r11, r2, r11, lsl #16
   31410: e153000b     	cmp	r3, r11
   31414: 9a000002     	bls	0x31424 <__divdi3+0x3e8> @ imm = #0x8
   31418: e09bb004     	adds	r11, r11, r4
   3141c: e2409001     	sub	r9, r0, #1
   31420: 3a000028     	blo	0x314c8 <__divdi3+0x48c> @ imm = #0xa0
   31424: e063b00b     	rsb	r11, r3, r11
   31428: e1a0000b     	mov	r0, r11
   3142c: e1a01007     	mov	r1, r7
   31430: ebfffa5f     	bl	0x2fdb4 <__aeabi_uidivmod> @ imm = #-0x1684
   31434: e1a0000b     	mov	r0, r11
   31438: e1a03001     	mov	r3, r1
   3143c: e1a01007     	mov	r1, r7
   31440: e58d3004     	str	r3, [sp, #0x4]
   31444: ebfff9de     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x1888
   31448: e59dc00c     	ldr	r12, [sp, #0xc]
   3144c: e0010098     	mul	r1, r8, r0
   31450: e1a0280c     	lsl	r2, r12, #16
   31454: e59d3004     	ldr	r3, [sp, #0x4]
   31458: e1a02822     	lsr	r2, r2, #16
   3145c: e1823803     	orr	r3, r2, r3, lsl #16
   31460: e1510003     	cmp	r1, r3
   31464: 9a000005     	bls	0x31480 <__divdi3+0x444> @ imm = #0x14
   31468: e0933004     	adds	r3, r3, r4
   3146c: e2400001     	sub	r0, r0, #1
   31470: 2a000002     	bhs	0x31480 <__divdi3+0x444> @ imm = #0x8
   31474: e1510003     	cmp	r1, r3
   31478: 82400001     	subhi	r0, r0, #1
   3147c: 80833004     	addhi	r3, r3, r4
   31480: e1800809     	orr	r0, r0, r9, lsl #16
   31484: e1a05a15     	lsl	r5, r5, r10
   31488: e58d000c     	str	r0, [sp, #0xc]
   3148c: e061a003     	rsb	r10, r1, r3
   31490: eaffff47     	b	0x311b4 <__divdi3+0x178> @ imm = #-0x2e4
   31494: e15c0001     	cmp	r12, r1
   31498: 21520000     	cmphs	r2, r0
   3149c: 93a0a001     	movls	r10, #1
   314a0: 9affff2a     	bls	0x31150 <__divdi3+0x114> @ imm = #-0x358
   314a4: eaffff27     	b	0x31148 <__divdi3+0x10c> @ imm = #-0x364
   314a8: e1570003     	cmp	r7, r3
   314ac: 80833009     	addhi	r3, r3, r9
   314b0: 82400001     	subhi	r0, r0, #1
   314b4: eaffff9e     	b	0x31334 <__divdi3+0x2f8> @ imm = #-0x188
   314b8: e1510003     	cmp	r1, r3
   314bc: 824aa001     	subhi	r10, r10, #1
   314c0: 80833009     	addhi	r3, r3, r9
   314c4: eaffff84     	b	0x312dc <__divdi3+0x2a0> @ imm = #-0x1f0
   314c8: e153000b     	cmp	r3, r11
   314cc: 82499001     	subhi	r9, r9, #1
   314d0: 808bb004     	addhi	r11, r11, r4
   314d4: eaffffd2     	b	0x31424 <__divdi3+0x3e8> @ imm = #-0xb8

