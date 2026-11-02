0001a71c <DST_InitDecoder>:
   1a71c: e92d4800     	push	{r11, lr}
   1a720: e28db004     	add	r11, sp, #4
   1a724: e24dd018     	sub	sp, sp, #24
   1a728: e50b0010     	str	r0, [r11, #-0x10]
   1a72c: e50b1014     	str	r1, [r11, #-0x14]
   1a730: e50b2018     	str	r2, [r11, #-0x18]
   1a734: e3a03000     	mov	r3, #0
   1a738: e50b3008     	str	r3, [r11, #-0x8]
   1a73c: e51b0010     	ldr	r0, [r11, #-0x10]
   1a740: e3a01000     	mov	r1, #0
   1a744: e59f2174     	ldr	r2, [pc, #0x174]        @ 0x1a8c0 <DST_InitDecoder+0x1a4>
   1a748: ebffc715     	bl	0xc3a4 <memset@plt>     @ imm = #-0xe3ac
   1a74c: e51b3010     	ldr	r3, [r11, #-0x10]
   1a750: e51b2014     	ldr	r2, [r11, #-0x14]
   1a754: e5832004     	str	r2, [r3, #0x4]
   1a758: e51b3018     	ldr	r3, [r11, #-0x18]
   1a75c: e3a02f93     	mov	r2, #588
   1a760: e0030392     	mul	r3, r2, r3
   1a764: e2832007     	add	r2, r3, #7
   1a768: e3530000     	cmp	r3, #0
   1a76c: b1a03002     	movlt	r3, r2
   1a770: e1a031c3     	asr	r3, r3, #3
   1a774: e1a01003     	mov	r1, r3
   1a778: e51b2010     	ldr	r2, [r11, #-0x10]
   1a77c: e59f3140     	ldr	r3, [pc, #0x140]        @ 0x1a8c4 <DST_InitDecoder+0x1a8>
   1a780: e7821003     	str	r1, [r2, r3]
   1a784: e51b2010     	ldr	r2, [r11, #-0x10]
   1a788: e59f3134     	ldr	r3, [pc, #0x134]        @ 0x1a8c4 <DST_InitDecoder+0x1a8>
   1a78c: e7923003     	ldr	r3, [r2, r3]
   1a790: e51b2010     	ldr	r2, [r11, #-0x10]
   1a794: e5922004     	ldr	r2, [r2, #0x4]
   1a798: e0010392     	mul	r1, r2, r3
   1a79c: e51b2010     	ldr	r2, [r11, #-0x10]
   1a7a0: e59f3120     	ldr	r3, [pc, #0x120]        @ 0x1a8c8 <DST_InitDecoder+0x1ac>
   1a7a4: e7821003     	str	r1, [r2, r3]
   1a7a8: e51b2010     	ldr	r2, [r11, #-0x10]
   1a7ac: e59f3114     	ldr	r3, [pc, #0x114]        @ 0x1a8c8 <DST_InitDecoder+0x1ac>
   1a7b0: e7923003     	ldr	r3, [r2, r3]
   1a7b4: e1a01183     	lsl	r1, r3, #3
   1a7b8: e51b2010     	ldr	r2, [r11, #-0x10]
   1a7bc: e59f3108     	ldr	r3, [pc, #0x108]        @ 0x1a8cc <DST_InitDecoder+0x1b0>
   1a7c0: e7821003     	str	r1, [r2, r3]
   1a7c4: e51b2010     	ldr	r2, [r11, #-0x10]
   1a7c8: e59f30f4     	ldr	r3, [pc, #0xf4]         @ 0x1a8c4 <DST_InitDecoder+0x1a8>
   1a7cc: e7923003     	ldr	r3, [r2, r3]
   1a7d0: e1a01183     	lsl	r1, r3, #3
   1a7d4: e51b2010     	ldr	r2, [r11, #-0x10]
   1a7d8: e59f30f0     	ldr	r3, [pc, #0xf0]         @ 0x1a8d0 <DST_InitDecoder+0x1b4>
   1a7dc: e7821003     	str	r1, [r2, r3]
   1a7e0: e51b3010     	ldr	r3, [r11, #-0x10]
   1a7e4: e5933004     	ldr	r3, [r3, #0x4]
   1a7e8: e1a01083     	lsl	r1, r3, #1
   1a7ec: e51b2010     	ldr	r2, [r11, #-0x10]
   1a7f0: e59f30dc     	ldr	r3, [pc, #0xdc]         @ 0x1a8d4 <DST_InitDecoder+0x1b8>
   1a7f4: e7821003     	str	r1, [r2, r3]
   1a7f8: e51b3010     	ldr	r3, [r11, #-0x10]
   1a7fc: e5933004     	ldr	r3, [r3, #0x4]
   1a800: e1a01083     	lsl	r1, r3, #1
   1a804: e51b2010     	ldr	r2, [r11, #-0x10]
   1a808: e59f30c8     	ldr	r3, [pc, #0xc8]         @ 0x1a8d8 <DST_InitDecoder+0x1bc>
   1a80c: e7821003     	str	r1, [r2, r3]
   1a810: e51b3010     	ldr	r3, [r11, #-0x10]
   1a814: e3a02000     	mov	r2, #0
   1a818: e5832000     	str	r2, [r3]
   1a81c: e51b2010     	ldr	r2, [r11, #-0x10]
   1a820: e59f30b4     	ldr	r3, [pc, #0xb4]         @ 0x1a8dc <DST_InitDecoder+0x1c0>
   1a824: e3a01000     	mov	r1, #0
   1a828: e7821003     	str	r1, [r2, r3]
   1a82c: e51b2010     	ldr	r2, [r11, #-0x10]
   1a830: e59f30a8     	ldr	r3, [pc, #0xa8]         @ 0x1a8e0 <DST_InitDecoder+0x1c4>
   1a834: e3a01001     	mov	r1, #1
   1a838: e7821003     	str	r1, [r2, r3]
   1a83c: e51b3008     	ldr	r3, [r11, #-0x8]
   1a840: e3530000     	cmp	r3, #0
   1a844: 1a000001     	bne	0x1a850 <DST_InitDecoder+0x134> @ imm = #0x4
   1a848: e51b0010     	ldr	r0, [r11, #-0x10]
   1a84c: ebfffedb     	bl	0x1a3c0 <AllocateDecMemory> @ imm = #-0x494
   1a850: e51b3008     	ldr	r3, [r11, #-0x8]
   1a854: e3530000     	cmp	r3, #0
   1a858: 1a000006     	bne	0x1a878 <DST_InitDecoder+0x15c> @ imm = #0x18
   1a85c: e51b3010     	ldr	r3, [r11, #-0x10]
   1a860: e2833a6e     	add	r3, r3, #450560
   1a864: e2833e82     	add	r3, r3, #2080
   1a868: e1a00003     	mov	r0, r3
   1a86c: eb000546     	bl	0x1bd8c <CCP_CalcInit>  @ imm = #0x1518
   1a870: e1a03000     	mov	r3, r0
   1a874: e50b3008     	str	r3, [r11, #-0x8]
   1a878: e51b3008     	ldr	r3, [r11, #-0x8]
   1a87c: e3530000     	cmp	r3, #0
   1a880: 1a000006     	bne	0x1a8a0 <DST_InitDecoder+0x184> @ imm = #0x18
   1a884: e51b2010     	ldr	r2, [r11, #-0x10]
   1a888: e59f3054     	ldr	r3, [pc, #0x54]         @ 0x1a8e4 <DST_InitDecoder+0x1c8>
   1a88c: e0823003     	add	r3, r2, r3
   1a890: e1a00003     	mov	r0, r3
   1a894: eb00053c     	bl	0x1bd8c <CCP_CalcInit>  @ imm = #0x14f0
   1a898: e1a03000     	mov	r3, r0
   1a89c: e50b3008     	str	r3, [r11, #-0x8]
   1a8a0: e51b2010     	ldr	r2, [r11, #-0x10]
   1a8a4: e59f303c     	ldr	r3, [pc, #0x3c]         @ 0x1a8e8 <DST_InitDecoder+0x1cc>
   1a8a8: e3a01000     	mov	r1, #0
   1a8ac: e7821003     	str	r1, [r2, r3]
   1a8b0: e51b3008     	ldr	r3, [r11, #-0x8]
   1a8b4: e1a00003     	mov	r0, r3
   1a8b8: e24bd004     	sub	sp, r11, #4
   1a8bc: e8bd8800     	pop	{r11, pc}
   1a8c0: 8c e8 06 00  	.word	0x0006e88c
   1a8c4: 10 e8 06 00  	.word	0x0006e810
   1a8c8: 14 e8 06 00  	.word	0x0006e814
   1a8cc: 18 e8 06 00  	.word	0x0006e818
   1a8d0: 1c e8 06 00  	.word	0x0006e81c
   1a8d4: 08 e8 06 00  	.word	0x0006e808
   1a8d8: 0c e8 06 00  	.word	0x0006e80c
   1a8dc: 40 e8 06 00  	.word	0x0006e840
   1a8e0: 64 e8 06 00  	.word	0x0006e864
   1a8e4: 44 e8 06 00  	.word	0x0006e844
   1a8e8: 88 e8 06 00  	.word	0x0006e888

