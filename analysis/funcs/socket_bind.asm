00012b08 <socket_bind>:
   12b08: e92d4800     	push	{r11, lr}
   12b0c: e28db004     	add	r11, sp, #4
   12b10: e24dd018     	sub	sp, sp, #24
   12b14: e50b0010     	str	r0, [r11, #-0x10]
   12b18: e50b1014     	str	r1, [r11, #-0x14]
   12b1c: e50b2018     	str	r2, [r11, #-0x18]
   12b20: e3a03000     	mov	r3, #0
   12b24: e50b3008     	str	r3, [r11, #-0x8]
   12b28: e51b0010     	ldr	r0, [r11, #-0x10]
   12b2c: eb0001f9     	bl	0x13318 <socket_setblocking> @ imm = #0x7e4
   12b30: e51b3010     	ldr	r3, [r11, #-0x10]
   12b34: e5932000     	ldr	r2, [r3]
   12b38: e51b1014     	ldr	r1, [r11, #-0x14]
   12b3c: e3a03000     	mov	r3, #0
   12b40: e1a03001     	mov	r3, r1
   12b44: e1a00002     	mov	r0, r2
   12b48: e1a01003     	mov	r1, r3
   12b4c: e51b2018     	ldr	r2, [r11, #-0x18]
   12b50: ebffe69a     	bl	0xc5c0 <bind@plt>       @ imm = #-0x6598
   12b54: e1a03000     	mov	r3, r0
   12b58: e3530000     	cmp	r3, #0
   12b5c: aa000003     	bge	0x12b70 <socket_bind+0x68> @ imm = #0xc
   12b60: ebffe71d     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x638c
   12b64: e1a03000     	mov	r3, r0
   12b68: e5933000     	ldr	r3, [r3]
   12b6c: e50b3008     	str	r3, [r11, #-0x8]
   12b70: e51b0010     	ldr	r0, [r11, #-0x10]
   12b74: eb0001fe     	bl	0x13374 <socket_setnonblocking> @ imm = #0x7f8
   12b78: e51b3008     	ldr	r3, [r11, #-0x8]
   12b7c: e1a00003     	mov	r0, r3
   12b80: e24bd004     	sub	sp, r11, #4
   12b84: e8bd8800     	pop	{r11, pc}

