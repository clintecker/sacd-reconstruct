00011e5c <pb_encode_tag>:
   11e5c: e92d4800     	push	{r11, lr}
   11e60: e28db004     	add	r11, sp, #4
   11e64: e24dd018     	sub	sp, sp, #24
   11e68: e50b0010     	str	r0, [r11, #-0x10]
   11e6c: e50b1014     	str	r1, [r11, #-0x14]
   11e70: e50b2018     	str	r2, [r11, #-0x18]
   11e74: e51b3018     	ldr	r3, [r11, #-0x18]
   11e78: e1a03183     	lsl	r3, r3, #3
   11e7c: e1a02003     	mov	r2, r3
   11e80: e51b3014     	ldr	r3, [r11, #-0x14]
   11e84: e1823003     	orr	r3, r2, r3
   11e88: e50b3008     	str	r3, [r11, #-0x8]
   11e8c: e51b3008     	ldr	r3, [r11, #-0x8]
   11e90: e1a02003     	mov	r2, r3
   11e94: e1a03fc2     	asr	r3, r2, #31
   11e98: e51b0010     	ldr	r0, [r11, #-0x10]
   11e9c: ebffffa7     	bl	0x11d40 <pb_encode_varint> @ imm = #-0x164
   11ea0: e1a03000     	mov	r3, r0
   11ea4: e1a00003     	mov	r0, r3
   11ea8: e24bd004     	sub	sp, r11, #4
   11eac: e8bd8800     	pop	{r11, pc}

