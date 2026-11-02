00012bf4 <socket_shutdown>:
   12bf4: e92d4800     	push	{r11, lr}
   12bf8: e28db004     	add	r11, sp, #4
   12bfc: e24dd008     	sub	sp, sp, #8
   12c00: e50b0008     	str	r0, [r11, #-0x8]
   12c04: e50b100c     	str	r1, [r11, #-0xc]
   12c08: e51b0008     	ldr	r0, [r11, #-0x8]
   12c0c: eb0001c1     	bl	0x13318 <socket_setblocking> @ imm = #0x704
   12c10: e51b3008     	ldr	r3, [r11, #-0x8]
   12c14: e5933000     	ldr	r3, [r3]
   12c18: e1a00003     	mov	r0, r3
   12c1c: e51b100c     	ldr	r1, [r11, #-0xc]
   12c20: ebffe663     	bl	0xc5b4 <shutdown@plt>   @ imm = #-0x6674
   12c24: e51b0008     	ldr	r0, [r11, #-0x8]
   12c28: eb0001d1     	bl	0x13374 <socket_setnonblocking> @ imm = #0x744
   12c2c: e24bd004     	sub	sp, r11, #4
   12c30: e8bd8800     	pop	{r11, pc}

