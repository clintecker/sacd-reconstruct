0001caec <id3_frame_get_dataptr>:
   1caec: e92d4800     	push	{r11, lr}
   1caf0: e28db004     	add	r11, sp, #4
   1caf4: e24dd010     	sub	sp, sp, #16
   1caf8: e50b0010     	str	r0, [r11, #-0x10]
   1cafc: e51b3010     	ldr	r3, [r11, #-0x10]
   1cb00: e5933018     	ldr	r3, [r3, #0x18]
   1cb04: e50b3008     	str	r3, [r11, #-0x8]
   1cb08: e51b0010     	ldr	r0, [r11, #-0x10]
   1cb0c: ebffffd3     	bl	0x1ca60 <id3_frame_extra_headers> @ imm = #-0xb4
   1cb10: e1a03000     	mov	r3, r0
   1cb14: e51b2008     	ldr	r2, [r11, #-0x8]
   1cb18: e0823003     	add	r3, r2, r3
   1cb1c: e50b3008     	str	r3, [r11, #-0x8]
   1cb20: e51b3008     	ldr	r3, [r11, #-0x8]
   1cb24: e1a00003     	mov	r0, r3
   1cb28: e24bd004     	sub	sp, r11, #4
   1cb2c: e8bd8800     	pop	{r11, pc}

