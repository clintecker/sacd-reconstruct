00011360 <sanitize_filename>:
   11360: e92d4810     	push	{r4, r11, lr}
   11364: e28db008     	add	r11, sp, #8
   11368: e24dd03c     	sub	sp, sp, #60
   1136c: e50b0040     	str	r0, [r11, #-0x40]
   11370: e59f30bc     	ldr	r3, [pc, #0xbc]         @ 0x11434 <sanitize_filename+0xd4>
   11374: e24bc03c     	sub	r12, r11, #60
   11378: e1a04003     	mov	r4, r3
   1137c: e8b4000f     	ldm	r4!, {r0, r1, r2, r3}
   11380: e8ac000f     	stm	r12!, {r0, r1, r2, r3}
   11384: e8b4000f     	ldm	r4!, {r0, r1, r2, r3}
   11388: e8ac000f     	stm	r12!, {r0, r1, r2, r3}
   1138c: e8940007     	ldm	r4, {r0, r1, r2}
   11390: e8ac0003     	stm	r12!, {r0, r1}
   11394: e1cc20b0     	strh	r2, [r12]
   11398: e51b3040     	ldr	r3, [r11, #-0x40]
   1139c: e50b3010     	str	r3, [r11, #-0x10]
   113a0: e51b3010     	ldr	r3, [r11, #-0x10]
   113a4: e3530000     	cmp	r3, #0
   113a8: 0a00001e     	beq	0x11428 <sanitize_filename+0xc8> @ imm = #0x78
   113ac: e51b3010     	ldr	r3, [r11, #-0x10]
   113b0: e5d33000     	ldrb	r3, [r3]
   113b4: e3530000     	cmp	r3, #0
   113b8: 1a000010     	bne	0x11400 <sanitize_filename+0xa0> @ imm = #0x40
   113bc: ea00001a     	b	0x1142c <sanitize_filename+0xcc> @ imm = #0x68
   113c0: e51b3010     	ldr	r3, [r11, #-0x10]
   113c4: e5d33000     	ldrb	r3, [r3]
   113c8: e24b203c     	sub	r2, r11, #60
   113cc: e1a00002     	mov	r0, r2
   113d0: e1a01003     	mov	r1, r3
   113d4: ebffebd4     	bl	0xc32c <strchr@plt>     @ imm = #-0x50b0
   113d8: e1a03000     	mov	r3, r0
   113dc: e3530000     	cmp	r3, #0
   113e0: 0a000002     	beq	0x113f0 <sanitize_filename+0x90> @ imm = #0x8
   113e4: e51b3010     	ldr	r3, [r11, #-0x10]
   113e8: e3a02020     	mov	r2, #32
   113ec: e5c32000     	strb	r2, [r3]
   113f0: e51b3010     	ldr	r3, [r11, #-0x10]
   113f4: e2833001     	add	r3, r3, #1
   113f8: e50b3010     	str	r3, [r11, #-0x10]
   113fc: ea000000     	b	0x11404 <sanitize_filename+0xa4> @ imm = #0x0
   11400: e1a00000     	mov	r0, r0
   11404: e51b3010     	ldr	r3, [r11, #-0x10]
   11408: e5d33000     	ldrb	r3, [r3]
   1140c: e3530000     	cmp	r3, #0
   11410: 1affffea     	bne	0x113c0 <sanitize_filename+0x60> @ imm = #-0x58
   11414: e51b0040     	ldr	r0, [r11, #-0x40]
   11418: eb000a00     	bl	0x13c20 <replace_double_space_with_single> @ imm = #0x2800
   1141c: e51b0040     	ldr	r0, [r11, #-0x40]
   11420: eb000a56     	bl	0x13d80 <trim_whitespace> @ imm = #0x2958
   11424: ea000000     	b	0x1142c <sanitize_filename+0xcc> @ imm = #0x0
   11428: e1a00000     	mov	r0, r0
   1142c: e24bd008     	sub	sp, r11, #8
   11430: e8bd8810     	pop	{r4, r11, pc}
   11434: 04 28 03 00  	.word	0x00032804

