00012aa0 <socket_create>:
   12aa0: e92d4800     	push	{r11, lr}
   12aa4: e28db004     	add	r11, sp, #4
   12aa8: e24dd010     	sub	sp, sp, #16
   12aac: e50b0008     	str	r0, [r11, #-0x8]
   12ab0: e50b100c     	str	r1, [r11, #-0xc]
   12ab4: e50b2010     	str	r2, [r11, #-0x10]
   12ab8: e50b3014     	str	r3, [r11, #-0x14]
   12abc: e51b000c     	ldr	r0, [r11, #-0xc]
   12ac0: e51b1010     	ldr	r1, [r11, #-0x10]
   12ac4: e51b2014     	ldr	r2, [r11, #-0x14]
   12ac8: ebffe66e     	bl	0xc488 <socket@plt>     @ imm = #-0x6648
   12acc: e1a02000     	mov	r2, r0
   12ad0: e51b3008     	ldr	r3, [r11, #-0x8]
   12ad4: e5832000     	str	r2, [r3]
   12ad8: e51b3008     	ldr	r3, [r11, #-0x8]
   12adc: e5933000     	ldr	r3, [r3]
   12ae0: e3730001     	cmn	r3, #1
   12ae4: 0a000001     	beq	0x12af0 <socket_create+0x50> @ imm = #0x4
   12ae8: e3a03000     	mov	r3, #0
   12aec: ea000002     	b	0x12afc <socket_create+0x5c> @ imm = #0x8
   12af0: ebffe739     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x631c
   12af4: e1a03000     	mov	r3, r0
   12af8: e5933000     	ldr	r3, [r3]
   12afc: e1a00003     	mov	r0, r3
   12b00: e24bd004     	sub	sp, r11, #4
   12b04: e8bd8800     	pop	{r11, pc}

