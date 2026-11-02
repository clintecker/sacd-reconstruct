0001b698 <DeleteBuffer>:
   1b698: e92d4800     	push	{r11, lr}
   1b69c: e28db004     	add	r11, sp, #4
   1b6a0: e24dd010     	sub	sp, sp, #16
   1b6a4: e50b0010     	str	r0, [r11, #-0x10]
   1b6a8: e3a03000     	mov	r3, #0
   1b6ac: e50b3008     	str	r3, [r11, #-0x8]
   1b6b0: e51b3010     	ldr	r3, [r11, #-0x10]
   1b6b4: e3a02000     	mov	r2, #0
   1b6b8: e5832004     	str	r2, [r3, #0x4]
   1b6bc: e51b3010     	ldr	r3, [r11, #-0x10]
   1b6c0: e5933000     	ldr	r3, [r3]
   1b6c4: e3530000     	cmp	r3, #0
   1b6c8: 0a000001     	beq	0x1b6d4 <DeleteBuffer+0x3c> @ imm = #0x4
   1b6cc: e3e03000     	mvn	r3, #0
   1b6d0: e50b3008     	str	r3, [r11, #-0x8]
   1b6d4: e51b0010     	ldr	r0, [r11, #-0x10]
   1b6d8: ebffffaf     	bl	0x1b59c <ResetReadingIndex> @ imm = #-0x144
   1b6dc: e51b3008     	ldr	r3, [r11, #-0x8]
   1b6e0: e1a00003     	mov	r0, r3
   1b6e4: e24bd004     	sub	sp, r11, #4
   1b6e8: e8bd8800     	pop	{r11, pc}

