0001cb30 <id3_frame_get_size>:
   1cb30: e92d4810     	push	{r4, r11, lr}
   1cb34: e28db008     	add	r11, sp, #8
   1cb38: e24dd00c     	sub	sp, sp, #12
   1cb3c: e50b0010     	str	r0, [r11, #-0x10]
   1cb40: e51b3010     	ldr	r3, [r11, #-0x10]
   1cb44: e593401c     	ldr	r4, [r3, #0x1c]
   1cb48: e51b0010     	ldr	r0, [r11, #-0x10]
   1cb4c: ebffffc3     	bl	0x1ca60 <id3_frame_extra_headers> @ imm = #-0xf4
   1cb50: e1a03000     	mov	r3, r0
   1cb54: e0633004     	rsb	r3, r3, r4
   1cb58: e1a00003     	mov	r0, r3
   1cb5c: e24bd008     	sub	sp, r11, #8
   1cb60: e8bd8810     	pop	{r4, r11, pc}

