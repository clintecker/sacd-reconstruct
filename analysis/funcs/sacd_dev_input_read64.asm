00022028 <sacd_dev_input_read64>:
   22028: e92d4800     	push	{r11, lr}
   2202c: e28db004     	add	r11, sp, #4
   22030: e24dd018     	sub	sp, sp, #24
   22034: e50b0010     	str	r0, [r11, #-0x10]
   22038: e50b1014     	str	r1, [r11, #-0x14]
   2203c: e50b2018     	str	r2, [r11, #-0x18]
   22040: e50b301c     	str	r3, [r11, #-0x1c]
   22044: e51b0014     	ldr	r0, [r11, #-0x14]
   22048: e51b1018     	ldr	r1, [r11, #-0x18]
   2204c: e51b201c     	ldr	r2, [r11, #-0x1c]
   22050: ebfffc16     	bl	0x210b0 <read_sacd>     @ imm = #-0xfa8
   22054: e1a03000     	mov	r3, r0
   22058: e50b3008     	str	r3, [r11, #-0x8]
   2205c: e51b3008     	ldr	r3, [r11, #-0x8]
   22060: e3530000     	cmp	r3, #0
   22064: ba000001     	blt	0x22070 <sacd_dev_input_read64+0x48> @ imm = #0x4
   22068: e51b3018     	ldr	r3, [r11, #-0x18]
   2206c: ea000000     	b	0x22074 <sacd_dev_input_read64+0x4c> @ imm = #0x0
   22070: e3a03000     	mov	r3, #0
   22074: e1a00003     	mov	r0, r3
   22078: e24bd004     	sub	sp, r11, #4
   2207c: e8bd8800     	pop	{r11, pc}

