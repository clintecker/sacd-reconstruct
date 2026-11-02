00013374 <socket_setnonblocking>:
   13374: e92d4800     	push	{r11, lr}
   13378: e28db004     	add	r11, sp, #4
   1337c: e24dd010     	sub	sp, sp, #16
   13380: e50b0010     	str	r0, [r11, #-0x10]
   13384: e51b3010     	ldr	r3, [r11, #-0x10]
   13388: e5933000     	ldr	r3, [r3]
   1338c: e1a00003     	mov	r0, r3
   13390: e3a01003     	mov	r1, #3
   13394: e3a02000     	mov	r2, #0
   13398: ebffe4d6     	bl	0xc6f8 <fcntl@plt>      @ imm = #-0x6ca8
   1339c: e1a03000     	mov	r3, r0
   133a0: e50b3008     	str	r3, [r11, #-0x8]
   133a4: e51b3008     	ldr	r3, [r11, #-0x8]
   133a8: e3833b02     	orr	r3, r3, #2048
   133ac: e50b3008     	str	r3, [r11, #-0x8]
   133b0: e51b3010     	ldr	r3, [r11, #-0x10]
   133b4: e5933000     	ldr	r3, [r3]
   133b8: e1a00003     	mov	r0, r3
   133bc: e3a01004     	mov	r1, #4
   133c0: e51b2008     	ldr	r2, [r11, #-0x8]
   133c4: ebffe4cb     	bl	0xc6f8 <fcntl@plt>      @ imm = #-0x6cd4
   133c8: e24bd004     	sub	sp, r11, #4
   133cc: e8bd8800     	pop	{r11, pc}

