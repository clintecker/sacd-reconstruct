0001b5ec <CreateBuffer>:
   1b5ec: e92d4800     	push	{r11, lr}
   1b5f0: e28db004     	add	r11, sp, #4
   1b5f4: e24dd010     	sub	sp, sp, #16
   1b5f8: e50b0010     	str	r0, [r11, #-0x10]
   1b5fc: e50b1014     	str	r1, [r11, #-0x14]
   1b600: e3a03000     	mov	r3, #0
   1b604: e50b3008     	str	r3, [r11, #-0x8]
   1b608: e51b3010     	ldr	r3, [r11, #-0x10]
   1b60c: e51b2014     	ldr	r2, [r11, #-0x14]
   1b610: e5832004     	str	r2, [r3, #0x4]
   1b614: e51b3010     	ldr	r3, [r11, #-0x10]
   1b618: e5933000     	ldr	r3, [r3]
   1b61c: e3530000     	cmp	r3, #0
   1b620: 0a000006     	beq	0x1b640 <CreateBuffer+0x54> @ imm = #0x18
   1b624: e51b3010     	ldr	r3, [r11, #-0x10]
   1b628: e5933000     	ldr	r3, [r3]
   1b62c: e1a00003     	mov	r0, r3
   1b630: ebffc379     	bl	0xc41c <free@plt>       @ imm = #-0xf21c
   1b634: e51b3010     	ldr	r3, [r11, #-0x10]
   1b638: e3a02000     	mov	r2, #0
   1b63c: e5832000     	str	r2, [r3]
   1b640: e51b3014     	ldr	r3, [r11, #-0x14]
   1b644: e1a00003     	mov	r0, r3
   1b648: ebffc406     	bl	0xc668 <malloc@plt>     @ imm = #-0xefe8
   1b64c: e1a03000     	mov	r3, r0
   1b650: e1a02003     	mov	r2, r3
   1b654: e51b3010     	ldr	r3, [r11, #-0x10]
   1b658: e5832000     	str	r2, [r3]
   1b65c: e51b3010     	ldr	r3, [r11, #-0x10]
   1b660: e5933000     	ldr	r3, [r3]
   1b664: e3530000     	cmp	r3, #0
   1b668: 1a000004     	bne	0x1b680 <CreateBuffer+0x94> @ imm = #0x10
   1b66c: e51b3010     	ldr	r3, [r11, #-0x10]
   1b670: e3a02000     	mov	r2, #0
   1b674: e5832004     	str	r2, [r3, #0x4]
   1b678: e3e03000     	mvn	r3, #0
   1b67c: e50b3008     	str	r3, [r11, #-0x8]
   1b680: e51b0010     	ldr	r0, [r11, #-0x10]
   1b684: ebffffc4     	bl	0x1b59c <ResetReadingIndex> @ imm = #-0xf0
   1b688: e51b3008     	ldr	r3, [r11, #-0x8]
   1b68c: e1a00003     	mov	r0, r3
   1b690: e24bd004     	sub	sp, r11, #4
   1b694: e8bd8800     	pop	{r11, pc}

