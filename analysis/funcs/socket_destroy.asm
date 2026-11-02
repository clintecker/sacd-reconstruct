00012920 <socket_destroy>:
   12920: e92d4800     	push	{r11, lr}
   12924: e28db004     	add	r11, sp, #4
   12928: e24dd008     	sub	sp, sp, #8
   1292c: e50b0008     	str	r0, [r11, #-0x8]
   12930: e51b3008     	ldr	r3, [r11, #-0x8]
   12934: e5933000     	ldr	r3, [r3]
   12938: e3730001     	cmn	r3, #1
   1293c: 0a000008     	beq	0x12964 <socket_destroy+0x44> @ imm = #0x20
   12940: e51b0008     	ldr	r0, [r11, #-0x8]
   12944: eb000273     	bl	0x13318 <socket_setblocking> @ imm = #0x9cc
   12948: e51b3008     	ldr	r3, [r11, #-0x8]
   1294c: e5933000     	ldr	r3, [r3]
   12950: e1a00003     	mov	r0, r3
   12954: ebffe722     	bl	0xc5e4 <close@plt>      @ imm = #-0x6378
   12958: e51b3008     	ldr	r3, [r11, #-0x8]
   1295c: e3e02000     	mvn	r2, #0
   12960: e5832000     	str	r2, [r3]
   12964: e24bd004     	sub	sp, r11, #4
   12968: e8bd8800     	pop	{r11, pc}

