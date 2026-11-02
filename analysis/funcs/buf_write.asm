000115e4 <buf_write>:
   115e4: e92d4800     	push	{r11, lr}
   115e8: e28db004     	add	r11, sp, #4
   115ec: e24dd018     	sub	sp, sp, #24
   115f0: e50b0010     	str	r0, [r11, #-0x10]
   115f4: e50b1014     	str	r1, [r11, #-0x14]
   115f8: e50b2018     	str	r2, [r11, #-0x18]
   115fc: e51b3010     	ldr	r3, [r11, #-0x10]
   11600: e5933004     	ldr	r3, [r3, #0x4]
   11604: e50b3008     	str	r3, [r11, #-0x8]
   11608: e51b0008     	ldr	r0, [r11, #-0x8]
   1160c: e51b1014     	ldr	r1, [r11, #-0x14]
   11610: e51b2018     	ldr	r2, [r11, #-0x18]
   11614: ebffebbc     	bl	0xc50c <memcpy@plt>     @ imm = #-0x5110
   11618: e51b2008     	ldr	r2, [r11, #-0x8]
   1161c: e51b3018     	ldr	r3, [r11, #-0x18]
   11620: e0822003     	add	r2, r2, r3
   11624: e51b3010     	ldr	r3, [r11, #-0x10]
   11628: e5832004     	str	r2, [r3, #0x4]
   1162c: e3a03001     	mov	r3, #1
   11630: e1a00003     	mov	r0, r3
   11634: e24bd004     	sub	sp, r11, #4
   11638: e8bd8800     	pop	{r11, pc}

