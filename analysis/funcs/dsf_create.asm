0002f5b0 <dsf_create>:
   2f5b0: e92d4800     	push	{r11, lr}
   2f5b4: e28db004     	add	r11, sp, #4
   2f5b8: e24dd008     	sub	sp, sp, #8
   2f5bc: e50b0008     	str	r0, [r11, #-0x8]
   2f5c0: e51b0008     	ldr	r0, [r11, #-0x8]
   2f5c4: ebfffde1     	bl	0x2ed50 <dsf_create_header> @ imm = #-0x87c
   2f5c8: e1a03000     	mov	r3, r0
   2f5cc: e1a00003     	mov	r0, r3
   2f5d0: e24bd004     	sub	sp, r11, #4
   2f5d4: e8bd8800     	pop	{r11, pc}

