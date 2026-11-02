0001c1e0 <list_add_tail>:
   1c1e0: e92d4800     	push	{r11, lr}
   1c1e4: e28db004     	add	r11, sp, #4
   1c1e8: e24dd008     	sub	sp, sp, #8
   1c1ec: e50b0008     	str	r0, [r11, #-0x8]
   1c1f0: e50b100c     	str	r1, [r11, #-0xc]
   1c1f4: e51b300c     	ldr	r3, [r11, #-0xc]
   1c1f8: e5933004     	ldr	r3, [r3, #0x4]
   1c1fc: e51b0008     	ldr	r0, [r11, #-0x8]
   1c200: e1a01003     	mov	r1, r3
   1c204: e51b200c     	ldr	r2, [r11, #-0xc]
   1c208: ebffffdf     	bl	0x1c18c <__list_add>    @ imm = #-0x84
   1c20c: e24bd004     	sub	sp, r11, #4
   1c210: e8bd8800     	pop	{r11, pc}

