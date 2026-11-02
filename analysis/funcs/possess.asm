000157b0 <possess>:
   157b0: e92d4800     	push	{r11, lr}
   157b4: e28db004     	add	r11, sp, #4
   157b8: e24dd010     	sub	sp, sp, #16
   157bc: e50b0010     	str	r0, [r11, #-0x10]
   157c0: e51b3010     	ldr	r3, [r11, #-0x10]
   157c4: e1a00003     	mov	r0, r3
   157c8: ebffdb3d     	bl	0xc4c4 <pthread_mutex_lock@plt> @ imm = #-0x930c
   157cc: e1a03000     	mov	r3, r0
   157d0: e50b3008     	str	r3, [r11, #-0x8]
   157d4: e51b3008     	ldr	r3, [r11, #-0x8]
   157d8: e3530000     	cmp	r3, #0
   157dc: 0a000001     	beq	0x157e8 <possess+0x38>  @ imm = #0x4
   157e0: e51b0008     	ldr	r0, [r11, #-0x8]
   157e4: ebffff7d     	bl	0x155e0 <fail>          @ imm = #-0x20c
   157e8: e24bd004     	sub	sp, r11, #4
   157ec: e8bd8800     	pop	{r11, pc}

