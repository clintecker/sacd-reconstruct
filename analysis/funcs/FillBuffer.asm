0001b6ec <FillBuffer>:
   1b6ec: e92d4800     	push	{r11, lr}
   1b6f0: e28db004     	add	r11, sp, #4
   1b6f4: e24dd018     	sub	sp, sp, #24
   1b6f8: e50b0010     	str	r0, [r11, #-0x10]
   1b6fc: e50b1014     	str	r1, [r11, #-0x14]
   1b700: e50b2018     	str	r2, [r11, #-0x18]
   1b704: e3a03000     	mov	r3, #0
   1b708: e50b300c     	str	r3, [r11, #-0xc]
   1b70c: e51b0010     	ldr	r0, [r11, #-0x10]
   1b710: e51b1018     	ldr	r1, [r11, #-0x18]
   1b714: ebffffb4     	bl	0x1b5ec <CreateBuffer>  @ imm = #-0x130
   1b718: e3a03000     	mov	r3, #0
   1b71c: e50b3008     	str	r3, [r11, #-0x8]
   1b720: ea00000b     	b	0x1b754 <FillBuffer+0x68> @ imm = #0x2c
   1b724: e51b3010     	ldr	r3, [r11, #-0x10]
   1b728: e5932000     	ldr	r2, [r3]
   1b72c: e51b3008     	ldr	r3, [r11, #-0x8]
   1b730: e0823003     	add	r3, r2, r3
   1b734: e51b2008     	ldr	r2, [r11, #-0x8]
   1b738: e51b1014     	ldr	r1, [r11, #-0x14]
   1b73c: e0812002     	add	r2, r1, r2
   1b740: e5d22000     	ldrb	r2, [r2]
   1b744: e5c32000     	strb	r2, [r3]
   1b748: e51b3008     	ldr	r3, [r11, #-0x8]
   1b74c: e2833001     	add	r3, r3, #1
   1b750: e50b3008     	str	r3, [r11, #-0x8]
   1b754: e51b2008     	ldr	r2, [r11, #-0x8]
   1b758: e51b3018     	ldr	r3, [r11, #-0x18]
   1b75c: e1520003     	cmp	r2, r3
   1b760: baffffef     	blt	0x1b724 <FillBuffer+0x38> @ imm = #-0x44
   1b764: e51b0010     	ldr	r0, [r11, #-0x10]
   1b768: ebffff8b     	bl	0x1b59c <ResetReadingIndex> @ imm = #-0x1d4
   1b76c: e51b300c     	ldr	r3, [r11, #-0xc]
   1b770: e1a00003     	mov	r0, r3
   1b774: e24bd004     	sub	sp, r11, #4
   1b778: e8bd8800     	pop	{r11, pc}

