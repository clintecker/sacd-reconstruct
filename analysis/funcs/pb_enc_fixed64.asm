00012254 <pb_enc_fixed64>:
   12254: e92d4800     	push	{r11, lr}
   12258: e28db004     	add	r11, sp, #4
   1225c: e24dd010     	sub	sp, sp, #16
   12260: e50b0008     	str	r0, [r11, #-0x8]
   12264: e50b100c     	str	r1, [r11, #-0xc]
   12268: e50b2010     	str	r2, [r11, #-0x10]
   1226c: e51b3010     	ldr	r3, [r11, #-0x10]
   12270: e51b0008     	ldr	r0, [r11, #-0x8]
   12274: e1a01003     	mov	r1, r3
   12278: e3a02008     	mov	r2, #8
   1227c: ebfffd05     	bl	0x11698 <pb_write>      @ imm = #-0xbec
   12280: e1a03000     	mov	r3, r0
   12284: e1a00003     	mov	r0, r3
   12288: e24bd004     	sub	sp, r11, #4
   1228c: e8bd8800     	pop	{r11, pc}

