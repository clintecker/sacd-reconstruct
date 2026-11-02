0001608c <buffer_pool_create>:
   1608c: e92d4800     	push	{r11, lr}
   16090: e28db004     	add	r11, sp, #4
   16094: e24dd010     	sub	sp, sp, #16
   16098: e50b0008     	str	r0, [r11, #-0x8]
   1609c: e50b100c     	str	r1, [r11, #-0xc]
   160a0: e50b2010     	str	r2, [r11, #-0x10]
   160a4: e3a00000     	mov	r0, #0
   160a8: ebfffd9c     	bl	0x15720 <new_lock>      @ imm = #-0x990
   160ac: e1a02000     	mov	r2, r0
   160b0: e51b3008     	ldr	r3, [r11, #-0x8]
   160b4: e5832000     	str	r2, [r3]
   160b8: e51b3008     	ldr	r3, [r11, #-0x8]
   160bc: e3a02000     	mov	r2, #0
   160c0: e5832004     	str	r2, [r3, #0x4]
   160c4: e51b3008     	ldr	r3, [r11, #-0x8]
   160c8: e51b200c     	ldr	r2, [r11, #-0xc]
   160cc: e5832008     	str	r2, [r3, #0x8]
   160d0: e51b3008     	ldr	r3, [r11, #-0x8]
   160d4: e51b2010     	ldr	r2, [r11, #-0x10]
   160d8: e583200c     	str	r2, [r3, #0xc]
   160dc: e51b3008     	ldr	r3, [r11, #-0x8]
   160e0: e3a02000     	mov	r2, #0
   160e4: e5832010     	str	r2, [r3, #0x10]
   160e8: e24bd004     	sub	sp, r11, #4
   160ec: e8bd8800     	pop	{r11, pc}

