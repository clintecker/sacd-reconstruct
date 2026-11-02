0001231c <pb_enc_string>:
   1231c: e92d4810     	push	{r4, r11, lr}
   12320: e28db008     	add	r11, sp, #8
   12324: e24dd014     	sub	sp, sp, #20
   12328: e50b0010     	str	r0, [r11, #-0x10]
   1232c: e50b1014     	str	r1, [r11, #-0x14]
   12330: e50b2018     	str	r2, [r11, #-0x18]
   12334: e51b4018     	ldr	r4, [r11, #-0x18]
   12338: e51b3018     	ldr	r3, [r11, #-0x18]
   1233c: e1a00003     	mov	r0, r3
   12340: ebffe865     	bl	0xc4dc <strlen@plt>     @ imm = #-0x5e6c
   12344: e1a03000     	mov	r3, r0
   12348: e51b0010     	ldr	r0, [r11, #-0x10]
   1234c: e1a01004     	mov	r1, r4
   12350: e1a02003     	mov	r2, r3
   12354: ebfffeff     	bl	0x11f58 <pb_encode_string> @ imm = #-0x404
   12358: e1a03000     	mov	r3, r0
   1235c: e1a00003     	mov	r0, r3
   12360: e24bd008     	sub	sp, r11, #8
   12364: e8bd8810     	pop	{r4, r11, pc}

