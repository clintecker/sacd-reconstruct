000157f0 <release>:
   157f0: e92d4800     	push	{r11, lr}
   157f4: e28db004     	add	r11, sp, #4
   157f8: e24dd010     	sub	sp, sp, #16
   157fc: e50b0010     	str	r0, [r11, #-0x10]
   15800: e51b3010     	ldr	r3, [r11, #-0x10]
   15804: e1a00003     	mov	r0, r3
   15808: ebffdb1b     	bl	0xc47c <pthread_mutex_unlock@plt> @ imm = #-0x9394
   1580c: e1a03000     	mov	r3, r0
   15810: e50b3008     	str	r3, [r11, #-0x8]
   15814: e51b3008     	ldr	r3, [r11, #-0x8]
   15818: e3530000     	cmp	r3, #0
   1581c: 0a000001     	beq	0x15828 <release+0x38>  @ imm = #0x4
   15820: e51b0008     	ldr	r0, [r11, #-0x8]
   15824: ebffff6d     	bl	0x155e0 <fail>          @ imm = #-0x24c
   15828: e24bd004     	sub	sp, r11, #4
   1582c: e8bd8800     	pop	{r11, pc}

