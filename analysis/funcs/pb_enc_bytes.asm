000122cc <pb_enc_bytes>:
   122cc: e92d4800     	push	{r11, lr}
   122d0: e28db004     	add	r11, sp, #4
   122d4: e24dd018     	sub	sp, sp, #24
   122d8: e50b0010     	str	r0, [r11, #-0x10]
   122dc: e50b1014     	str	r1, [r11, #-0x14]
   122e0: e50b2018     	str	r2, [r11, #-0x18]
   122e4: e51b3018     	ldr	r3, [r11, #-0x18]
   122e8: e50b3008     	str	r3, [r11, #-0x8]
   122ec: e51b3008     	ldr	r3, [r11, #-0x8]
   122f0: e5932004     	ldr	r2, [r3, #0x4]
   122f4: e51b3008     	ldr	r3, [r11, #-0x8]
   122f8: e5933000     	ldr	r3, [r3]
   122fc: e51b0010     	ldr	r0, [r11, #-0x10]
   12300: e1a01002     	mov	r1, r2
   12304: e1a02003     	mov	r2, r3
   12308: ebffff12     	bl	0x11f58 <pb_encode_string> @ imm = #-0x3b8
   1230c: e1a03000     	mov	r3, r0
   12310: e1a00003     	mov	r0, r3
   12314: e24bd004     	sub	sp, r11, #4
   12318: e8bd8800     	pop	{r11, pc}

