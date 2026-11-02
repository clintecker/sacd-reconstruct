000114fc <sanitize_filepath>:
   114fc: e92d4810     	push	{r4, r11, lr}
   11500: e28db008     	add	r11, sp, #8
   11504: e24dd03c     	sub	sp, sp, #60
   11508: e50b0040     	str	r0, [r11, #-0x40]
   1150c: e59f30cc     	ldr	r3, [pc, #0xcc]         @ 0x115e0 <sanitize_filepath+0xe4>
   11510: e24bc03c     	sub	r12, r11, #60
   11514: e1a04003     	mov	r4, r3
   11518: e8b4000f     	ldm	r4!, {r0, r1, r2, r3}
   1151c: e8ac000f     	stm	r12!, {r0, r1, r2, r3}
   11520: e8b4000f     	ldm	r4!, {r0, r1, r2, r3}
   11524: e8ac000f     	stm	r12!, {r0, r1, r2, r3}
   11528: e8940007     	ldm	r4, {r0, r1, r2}
   1152c: e8ac0003     	stm	r12!, {r0, r1}
   11530: e5cc2000     	strb	r2, [r12]
   11534: e51b3040     	ldr	r3, [r11, #-0x40]
   11538: e50b3010     	str	r3, [r11, #-0x10]
   1153c: e51b3010     	ldr	r3, [r11, #-0x10]
   11540: e3530000     	cmp	r3, #0
   11544: 0a000022     	beq	0x115d4 <sanitize_filepath+0xd8> @ imm = #0x88
   11548: e51b3010     	ldr	r3, [r11, #-0x10]
   1154c: e5d33000     	ldrb	r3, [r3]
   11550: e3530000     	cmp	r3, #0
   11554: 1a000010     	bne	0x1159c <sanitize_filepath+0xa0> @ imm = #0x40
   11558: ea00001e     	b	0x115d8 <sanitize_filepath+0xdc> @ imm = #0x78
   1155c: e51b3010     	ldr	r3, [r11, #-0x10]
   11560: e5d33000     	ldrb	r3, [r3]
   11564: e24b203c     	sub	r2, r11, #60
   11568: e1a00002     	mov	r0, r2
   1156c: e1a01003     	mov	r1, r3
   11570: ebffeb6d     	bl	0xc32c <strchr@plt>     @ imm = #-0x524c
   11574: e1a03000     	mov	r3, r0
   11578: e3530000     	cmp	r3, #0
   1157c: 0a000002     	beq	0x1158c <sanitize_filepath+0x90> @ imm = #0x8
   11580: e51b3010     	ldr	r3, [r11, #-0x10]
   11584: e3a02020     	mov	r2, #32
   11588: e5c32000     	strb	r2, [r3]
   1158c: e51b3010     	ldr	r3, [r11, #-0x10]
   11590: e2833001     	add	r3, r3, #1
   11594: e50b3010     	str	r3, [r11, #-0x10]
   11598: ea000000     	b	0x115a0 <sanitize_filepath+0xa4> @ imm = #0x0
   1159c: e1a00000     	mov	r0, r0
   115a0: e51b3010     	ldr	r3, [r11, #-0x10]
   115a4: e5d33000     	ldrb	r3, [r3]
   115a8: e3530000     	cmp	r3, #0
   115ac: 1affffea     	bne	0x1155c <sanitize_filepath+0x60> @ imm = #-0x58
   115b0: e51b0040     	ldr	r0, [r11, #-0x40]
   115b4: eb000999     	bl	0x13c20 <replace_double_space_with_single> @ imm = #0x2664
   115b8: e51b0040     	ldr	r0, [r11, #-0x40]
   115bc: eb0009ef     	bl	0x13d80 <trim_whitespace> @ imm = #0x27bc
   115c0: e51b0040     	ldr	r0, [r11, #-0x40]
   115c4: ebffff9b     	bl	0x11438 <trim_dots>     @ imm = #-0x194
   115c8: e51b0040     	ldr	r0, [r11, #-0x40]
   115cc: eb0009eb     	bl	0x13d80 <trim_whitespace> @ imm = #0x27ac
   115d0: ea000000     	b	0x115d8 <sanitize_filepath+0xdc> @ imm = #0x0
   115d4: e1a00000     	mov	r0, r0
   115d8: e24bd008     	sub	sp, r11, #8
   115dc: e8bd8810     	pop	{r4, r11, pc}
   115e0: d8 27 03 00  	.word	0x000327d8

