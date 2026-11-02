00012b88 <socket_listen>:
   12b88: e92d4800     	push	{r11, lr}
   12b8c: e28db004     	add	r11, sp, #4
   12b90: e24dd010     	sub	sp, sp, #16
   12b94: e50b0010     	str	r0, [r11, #-0x10]
   12b98: e50b1014     	str	r1, [r11, #-0x14]
   12b9c: e3a03000     	mov	r3, #0
   12ba0: e50b3008     	str	r3, [r11, #-0x8]
   12ba4: e51b0010     	ldr	r0, [r11, #-0x10]
   12ba8: eb0001da     	bl	0x13318 <socket_setblocking> @ imm = #0x768
   12bac: e51b3010     	ldr	r3, [r11, #-0x10]
   12bb0: e5933000     	ldr	r3, [r3]
   12bb4: e1a00003     	mov	r0, r3
   12bb8: e51b1014     	ldr	r1, [r11, #-0x14]
   12bbc: ebffe5e3     	bl	0xc350 <listen@plt>     @ imm = #-0x6874
   12bc0: e1a03000     	mov	r3, r0
   12bc4: e3530000     	cmp	r3, #0
   12bc8: 0a000003     	beq	0x12bdc <socket_listen+0x54> @ imm = #0xc
   12bcc: ebffe702     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x63f8
   12bd0: e1a03000     	mov	r3, r0
   12bd4: e5933000     	ldr	r3, [r3]
   12bd8: e50b3008     	str	r3, [r11, #-0x8]
   12bdc: e51b0010     	ldr	r0, [r11, #-0x10]
   12be0: eb0001e3     	bl	0x13374 <socket_setnonblocking> @ imm = #0x78c
   12be4: e51b3008     	ldr	r3, [r11, #-0x8]
   12be8: e1a00003     	mov	r0, r3
   12bec: e24bd004     	sub	sp, r11, #4
   12bf0: e8bd8800     	pop	{r11, pc}

