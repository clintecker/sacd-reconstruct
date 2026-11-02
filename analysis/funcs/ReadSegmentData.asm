00018410 <ReadSegmentData>:
   18410: e92d4800     	push	{r11, lr}
   18414: e28db004     	add	r11, sp, #4
   18418: e24dd020     	sub	sp, sp, #32
   1841c: e50b0010     	str	r0, [r11, #-0x10]
   18420: e50b1014     	str	r1, [r11, #-0x14]
   18424: e51b2014     	ldr	r2, [r11, #-0x14]
   18428: e59f3104     	ldr	r3, [pc, #0x104]        @ 0x18534 <ReadSegmentData+0x124>
   1842c: e0823003     	add	r3, r2, r3
   18430: e51b0010     	ldr	r0, [r11, #-0x10]
   18434: e3a01001     	mov	r1, #1
   18438: e1a02003     	mov	r2, r3
   1843c: eb000cfb     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x33ec
   18440: e1a03000     	mov	r3, r0
   18444: e3530000     	cmp	r3, #0
   18448: 0a000001     	beq	0x18454 <ReadSegmentData+0x44> @ imm = #0x4
   1844c: e3a03001     	mov	r3, #1
   18450: ea000034     	b	0x18528 <ReadSegmentData+0x118> @ imm = #0xd0
   18454: e51b3014     	ldr	r3, [r11, #-0x14]
   18458: e5931004     	ldr	r1, [r3, #0x4]
   1845c: e51b2014     	ldr	r2, [r11, #-0x14]
   18460: e59f30d0     	ldr	r3, [pc, #0xd0]         @ 0x18538 <ReadSegmentData+0x128>
   18464: e7922003     	ldr	r2, [r2, r3]
   18468: e51b3014     	ldr	r3, [r11, #-0x14]
   1846c: e28300b4     	add	r0, r3, #180
   18470: e51bc014     	ldr	r12, [r11, #-0x14]
   18474: e59f30c0     	ldr	r3, [pc, #0xc0]         @ 0x1853c <ReadSegmentData+0x12c>
   18478: e08c3003     	add	r3, r12, r3
   1847c: e3a0cb01     	mov	r12, #1024
   18480: e58dc000     	str	r12, [sp]
   18484: e58d0004     	str	r0, [sp, #0x4]
   18488: e58d3008     	str	r3, [sp, #0x8]
   1848c: e51b0010     	ldr	r0, [r11, #-0x10]
   18490: e3a03004     	mov	r3, #4
   18494: ebfffd69     	bl	0x17a40 <ReadTableSegmentData> @ imm = #-0xa5c
   18498: e1a03000     	mov	r3, r0
   1849c: e50b3008     	str	r3, [r11, #-0x8]
   184a0: e51b3008     	ldr	r3, [r11, #-0x8]
   184a4: e3530000     	cmp	r3, #0
   184a8: 0a000001     	beq	0x184b4 <ReadSegmentData+0xa4> @ imm = #0x4
   184ac: e51b3008     	ldr	r3, [r11, #-0x8]
   184b0: ea00001c     	b	0x18528 <ReadSegmentData+0x118> @ imm = #0x70
   184b4: e51b2014     	ldr	r2, [r11, #-0x14]
   184b8: e59f3074     	ldr	r3, [pc, #0x74]         @ 0x18534 <ReadSegmentData+0x124>
   184bc: e7923003     	ldr	r3, [r2, r3]
   184c0: e3530001     	cmp	r3, #1
   184c4: 1a000003     	bne	0x184d8 <ReadSegmentData+0xc8> @ imm = #0xc
   184c8: e51b0014     	ldr	r0, [r11, #-0x14]
   184cc: ebffff39     	bl	0x181b8 <CopySegmentData> @ imm = #-0x31c
   184d0: e1a03000     	mov	r3, r0
   184d4: ea000013     	b	0x18528 <ReadSegmentData+0x118> @ imm = #0x4c
   184d8: e51b3014     	ldr	r3, [r11, #-0x14]
   184dc: e5931004     	ldr	r1, [r3, #0x4]
   184e0: e51b2014     	ldr	r2, [r11, #-0x14]
   184e4: e59f304c     	ldr	r3, [pc, #0x4c]         @ 0x18538 <ReadSegmentData+0x128>
   184e8: e792c003     	ldr	r12, [r2, r3]
   184ec: e51b3014     	ldr	r3, [r11, #-0x14]
   184f0: e2832bdd     	add	r2, r3, #226304
   184f4: e2822050     	add	r2, r2, #80
   184f8: e51b0014     	ldr	r0, [r11, #-0x14]
   184fc: e59f303c     	ldr	r3, [pc, #0x3c]         @ 0x18540 <ReadSegmentData+0x130>
   18500: e0803003     	add	r3, r0, r3
   18504: e3a00020     	mov	r0, #32
   18508: e58d0000     	str	r0, [sp]
   1850c: e58d2004     	str	r2, [sp, #0x4]
   18510: e58d3008     	str	r3, [sp, #0x8]
   18514: e51b0010     	ldr	r0, [r11, #-0x10]
   18518: e1a0200c     	mov	r2, r12
   1851c: e3a03008     	mov	r3, #8
   18520: ebfffd46     	bl	0x17a40 <ReadTableSegmentData> @ imm = #-0xae8
   18524: e1a03000     	mov	r3, r0
   18528: e1a00003     	mov	r0, r3
   1852c: e24bd004     	sub	sp, r11, #4
   18530: e8bd8800     	pop	{r11, pc}
   18534: ec e7 06 00  	.word	0x0006e7ec
   18538: 10 e8 06 00  	.word	0x0006e810
   1853c: f4 e7 06 00  	.word	0x0006e7f4
   18540: fc e7 06 00  	.word	0x0006e7fc

