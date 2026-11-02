00012570 <socket_waitfd>:
   12570: e92d4810     	push	{r4, r11, lr}
   12574: e28db008     	add	r11, sp, #8
   12578: e24ddf53     	sub	sp, sp, #332
   1257c: e50b0140     	str	r0, [r11, #-0x140]
   12580: e50b1144     	str	r1, [r11, #-0x144]
   12584: e50b2148     	str	r2, [r11, #-0x148]
   12588: e51b3148     	ldr	r3, [r11, #-0x148]
   1258c: e1c320d0     	ldrd	r2, r3, [r3]
   12590: e1a00002     	mov	r0, r2
   12594: e1a01003     	mov	r1, r3
   12598: e3a02000     	mov	r2, #0
   1259c: e3a03000     	mov	r3, #0
   125a0: eb0078d2     	bl	0x308f0 <__aeabi_dcmpeq> @ imm = #0x1e348
   125a4: e1a03000     	mov	r3, r0
   125a8: e3530000     	cmp	r3, #0
   125ac: 0a000001     	beq	0x125b8 <socket_waitfd+0x48> @ imm = #0x4
   125b0: e3e03000     	mvn	r3, #0
   125b4: ea0000c3     	b	0x128c8 <socket_waitfd+0x358> @ imm = #0x30c
   125b8: e3a03000     	mov	r3, #0
   125bc: e50b302c     	str	r3, [r11, #-0x2c]
   125c0: e51b302c     	ldr	r3, [r11, #-0x2c]
   125c4: e50b3030     	str	r3, [r11, #-0x30]
   125c8: e51b3144     	ldr	r3, [r11, #-0x144]
   125cc: e2033001     	and	r3, r3, #1
   125d0: e6ef3073     	uxtb	r3, r3
   125d4: e3530000     	cmp	r3, #0
   125d8: 0a000027     	beq	0x1267c <socket_waitfd+0x10c> @ imm = #0x9c
   125dc: e24b30b4     	sub	r3, r11, #180
   125e0: e50b3018     	str	r3, [r11, #-0x18]
   125e4: e3a03000     	mov	r3, #0
   125e8: e50b301c     	str	r3, [r11, #-0x1c]
   125ec: ea000006     	b	0x1260c <socket_waitfd+0x9c> @ imm = #0x18
   125f0: e51b201c     	ldr	r2, [r11, #-0x1c]
   125f4: e51b3018     	ldr	r3, [r11, #-0x18]
   125f8: e3a01000     	mov	r1, #0
   125fc: e7831102     	str	r1, [r3, r2, lsl #2]
   12600: e51b301c     	ldr	r3, [r11, #-0x1c]
   12604: e2833001     	add	r3, r3, #1
   12608: e50b301c     	str	r3, [r11, #-0x1c]
   1260c: e51b301c     	ldr	r3, [r11, #-0x1c]
   12610: e353001f     	cmp	r3, #31
   12614: 9afffff5     	bls	0x125f0 <socket_waitfd+0x80> @ imm = #-0x2c
   12618: e51b3140     	ldr	r3, [r11, #-0x140]
   1261c: e5933000     	ldr	r3, [r3]
   12620: e1a032a3     	lsr	r3, r3, #5
   12624: e1a01003     	mov	r1, r3
   12628: e1a02003     	mov	r2, r3
   1262c: e3e030a7     	mvn	r3, #167
   12630: e1a02102     	lsl	r2, r2, #2
   12634: e24b000c     	sub	r0, r11, #12
   12638: e0802002     	add	r2, r0, r2
   1263c: e0823003     	add	r3, r2, r3
   12640: e5932000     	ldr	r2, [r3]
   12644: e51b3140     	ldr	r3, [r11, #-0x140]
   12648: e5933000     	ldr	r3, [r3]
   1264c: e203301f     	and	r3, r3, #31
   12650: e3a00001     	mov	r0, #1
   12654: e1a03310     	lsl	r3, r0, r3
   12658: e1822003     	orr	r2, r2, r3
   1265c: e3e030a7     	mvn	r3, #167
   12660: e1a01101     	lsl	r1, r1, #2
   12664: e24b000c     	sub	r0, r11, #12
   12668: e0801001     	add	r1, r0, r1
   1266c: e0813003     	add	r3, r1, r3
   12670: e5832000     	str	r2, [r3]
   12674: e24b30b4     	sub	r3, r11, #180
   12678: e50b3030     	str	r3, [r11, #-0x30]
   1267c: e51b3144     	ldr	r3, [r11, #-0x144]
   12680: e2033002     	and	r3, r3, #2
   12684: e3530000     	cmp	r3, #0
   12688: 0a000027     	beq	0x1272c <socket_waitfd+0x1bc> @ imm = #0x9c
   1268c: e24b3f4d     	sub	r3, r11, #308
   12690: e50b3010     	str	r3, [r11, #-0x10]
   12694: e3a03000     	mov	r3, #0
   12698: e50b3014     	str	r3, [r11, #-0x14]
   1269c: ea000006     	b	0x126bc <socket_waitfd+0x14c> @ imm = #0x18
   126a0: e51b2014     	ldr	r2, [r11, #-0x14]
   126a4: e51b3010     	ldr	r3, [r11, #-0x10]
   126a8: e3a01000     	mov	r1, #0
   126ac: e7831102     	str	r1, [r3, r2, lsl #2]
   126b0: e51b3014     	ldr	r3, [r11, #-0x14]
   126b4: e2833001     	add	r3, r3, #1
   126b8: e50b3014     	str	r3, [r11, #-0x14]
   126bc: e51b3014     	ldr	r3, [r11, #-0x14]
   126c0: e353001f     	cmp	r3, #31
   126c4: 9afffff5     	bls	0x126a0 <socket_waitfd+0x130> @ imm = #-0x2c
   126c8: e51b3140     	ldr	r3, [r11, #-0x140]
   126cc: e5933000     	ldr	r3, [r3]
   126d0: e1a032a3     	lsr	r3, r3, #5
   126d4: e1a01003     	mov	r1, r3
   126d8: e1a02003     	mov	r2, r3
   126dc: e59f31fc     	ldr	r3, [pc, #0x1fc]        @ 0x128e0 <socket_waitfd+0x370>
   126e0: e1a02102     	lsl	r2, r2, #2
   126e4: e24b000c     	sub	r0, r11, #12
   126e8: e0802002     	add	r2, r0, r2
   126ec: e0823003     	add	r3, r2, r3
   126f0: e5932000     	ldr	r2, [r3]
   126f4: e51b3140     	ldr	r3, [r11, #-0x140]
   126f8: e5933000     	ldr	r3, [r3]
   126fc: e203301f     	and	r3, r3, #31
   12700: e3a00001     	mov	r0, #1
   12704: e1a03310     	lsl	r3, r0, r3
   12708: e1822003     	orr	r2, r2, r3
   1270c: e59f31cc     	ldr	r3, [pc, #0x1cc]        @ 0x128e0 <socket_waitfd+0x370>
   12710: e1a01101     	lsl	r1, r1, #2
   12714: e24b000c     	sub	r0, r11, #12
   12718: e0801001     	add	r1, r0, r1
   1271c: e0813003     	add	r3, r1, r3
   12720: e5832000     	str	r2, [r3]
   12724: e24b3f4d     	sub	r3, r11, #308
   12728: e50b302c     	str	r3, [r11, #-0x2c]
   1272c: e51b0148     	ldr	r0, [r11, #-0x148]
   12730: ebfff61f     	bl	0xffb4 <timeout_getretry> @ imm = #-0x2784
   12734: e1a02000     	mov	r2, r0
   12738: e1a03001     	mov	r3, r1
   1273c: e14b22f4     	strd	r2, r3, [r11, #-36]
   12740: e3a03000     	mov	r3, #0
   12744: e50b3028     	str	r3, [r11, #-0x28]
   12748: e3a03000     	mov	r3, #0
   1274c: e1a04003     	mov	r4, r3
   12750: e14b02d4     	ldrd	r0, r1, [r11, #-36]
   12754: e3a02000     	mov	r2, #0
   12758: e3a03000     	mov	r3, #0
   1275c: eb007872     	bl	0x3092c <__aeabi_dcmpge> @ imm = #0x1e1c8
   12760: e1a03000     	mov	r3, r0
   12764: e3530000     	cmp	r3, #0
   12768: 0a000001     	beq	0x12774 <socket_waitfd+0x204> @ imm = #0x4
   1276c: e3a03001     	mov	r3, #1
   12770: e1a04003     	mov	r4, r3
   12774: e6ef3074     	uxtb	r3, r4
   12778: e3530000     	cmp	r3, #0
   1277c: 0a00001a     	beq	0x127ec <socket_waitfd+0x27c> @ imm = #0x68
   12780: e14b02d4     	ldrd	r0, r1, [r11, #-36]
   12784: eb007872     	bl	0x30954 <__fixdfsi>     @ imm = #0x1e1c8
   12788: e1a03000     	mov	r3, r0
   1278c: e50b313c     	str	r3, [r11, #-0x13c]
   12790: e51b313c     	ldr	r3, [r11, #-0x13c]
   12794: e1a00003     	mov	r0, r3
   12798: eb0076d0     	bl	0x302e0 <__floatsidf>   @ imm = #0x1db40
   1279c: e1a02000     	mov	r2, r0
   127a0: e1a03001     	mov	r3, r1
   127a4: e14b02d4     	ldrd	r0, r1, [r11, #-36]
   127a8: eb007617     	bl	0x3000c <__subdf3>      @ imm = #0x1d85c
   127ac: e1a02000     	mov	r2, r0
   127b0: e1a03001     	mov	r3, r1
   127b4: e1a00002     	mov	r0, r2
   127b8: e1a01003     	mov	r1, r3
   127bc: e28f3f45     	add	r3, pc, #276
   127c0: e1c320d0     	ldrd	r2, r3, [r3]
   127c4: eb0076fc     	bl	0x303bc <__muldf3>      @ imm = #0x1dbf0
   127c8: e1a02000     	mov	r2, r0
   127cc: e1a03001     	mov	r3, r1
   127d0: e1a00002     	mov	r0, r2
   127d4: e1a01003     	mov	r1, r3
   127d8: eb00785d     	bl	0x30954 <__fixdfsi>     @ imm = #0x1e174
   127dc: e1a03000     	mov	r3, r0
   127e0: e50b3138     	str	r3, [r11, #-0x138]
   127e4: e24b3f4f     	sub	r3, r11, #316
   127e8: e50b3028     	str	r3, [r11, #-0x28]
   127ec: e51b3140     	ldr	r3, [r11, #-0x140]
   127f0: e5933000     	ldr	r3, [r3]
   127f4: e2833001     	add	r3, r3, #1
   127f8: e51b2028     	ldr	r2, [r11, #-0x28]
   127fc: e58d2000     	str	r2, [sp]
   12800: e1a00003     	mov	r0, r3
   12804: e51b1030     	ldr	r1, [r11, #-0x30]
   12808: e51b202c     	ldr	r2, [r11, #-0x2c]
   1280c: e3a03000     	mov	r3, #0
   12810: ebffe770     	bl	0xc5d8 <select@plt>     @ imm = #-0x6240
   12814: e1a03000     	mov	r3, r0
   12818: e50b3034     	str	r3, [r11, #-0x34]
   1281c: e51b3034     	ldr	r3, [r11, #-0x34]
   12820: e3730001     	cmn	r3, #1
   12824: 1a000004     	bne	0x1283c <socket_waitfd+0x2cc> @ imm = #0x10
   12828: ebffe7eb     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x6054
   1282c: e1a03000     	mov	r3, r0
   12830: e5933000     	ldr	r3, [r3]
   12834: e3530004     	cmp	r3, #4
   12838: 0affff5e     	beq	0x125b8 <socket_waitfd+0x48> @ imm = #-0x288
   1283c: e51b3034     	ldr	r3, [r11, #-0x34]
   12840: e3730001     	cmn	r3, #1
   12844: 1a000003     	bne	0x12858 <socket_waitfd+0x2e8> @ imm = #0xc
   12848: ebffe7e3     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x6074
   1284c: e1a03000     	mov	r3, r0
   12850: e5933000     	ldr	r3, [r3]
   12854: ea00001b     	b	0x128c8 <socket_waitfd+0x358> @ imm = #0x6c
   12858: e51b3034     	ldr	r3, [r11, #-0x34]
   1285c: e3530000     	cmp	r3, #0
   12860: 1a000001     	bne	0x1286c <socket_waitfd+0x2fc> @ imm = #0x4
   12864: e3e03000     	mvn	r3, #0
   12868: ea000016     	b	0x128c8 <socket_waitfd+0x358> @ imm = #0x58
   1286c: e51b3144     	ldr	r3, [r11, #-0x144]
   12870: e3530003     	cmp	r3, #3
   12874: 1a000012     	bne	0x128c4 <socket_waitfd+0x354> @ imm = #0x48
   12878: e51b3140     	ldr	r3, [r11, #-0x140]
   1287c: e5933000     	ldr	r3, [r3]
   12880: e1a022a3     	lsr	r2, r3, #5
   12884: e3e030a7     	mvn	r3, #167
   12888: e1a02102     	lsl	r2, r2, #2
   1288c: e24b100c     	sub	r1, r11, #12
   12890: e0812002     	add	r2, r1, r2
   12894: e0823003     	add	r3, r2, r3
   12898: e5932000     	ldr	r2, [r3]
   1289c: e51b3140     	ldr	r3, [r11, #-0x140]
   128a0: e5933000     	ldr	r3, [r3]
   128a4: e203301f     	and	r3, r3, #31
   128a8: e1a03352     	asr	r3, r2, r3
   128ac: e2033001     	and	r3, r3, #1
   128b0: e6ef3073     	uxtb	r3, r3
   128b4: e3530000     	cmp	r3, #0
   128b8: 0a000001     	beq	0x128c4 <socket_waitfd+0x354> @ imm = #0x4
   128bc: e3e03001     	mvn	r3, #1
   128c0: ea000000     	b	0x128c8 <socket_waitfd+0x358> @ imm = #0x0
   128c4: e3a03000     	mov	r3, #0
   128c8: e1a00003     	mov	r0, r3
   128cc: e24bd008     	sub	sp, r11, #8
   128d0: e8bd8810     	pop	{r4, r11, pc}
   128d4: e1a00000     	mov	r0, r0
   128d8: 00 00 00 00  	.word	0x00000000
   128dc: 80 84 2e 41  	.word	0x412e8480
   128e0: d8 fe ff ff  	.word	0xfffffed8

