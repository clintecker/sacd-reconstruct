00015a70 <free_lock>:
   15a70: e92d4800     	push	{r11, lr}
   15a74: e28db004     	add	r11, sp, #4
   15a78: e24dd010     	sub	sp, sp, #16
   15a7c: e50b0010     	str	r0, [r11, #-0x10]
   15a80: e51b3010     	ldr	r3, [r11, #-0x10]
   15a84: e2833018     	add	r3, r3, #24
   15a88: e1a00003     	mov	r0, r3
   15a8c: ebffdaad     	bl	0xc548 <pthread_cond_destroy@plt> @ imm = #-0x954c
   15a90: e1a03000     	mov	r3, r0
   15a94: e50b3008     	str	r3, [r11, #-0x8]
   15a98: e51b3008     	ldr	r3, [r11, #-0x8]
   15a9c: e3530000     	cmp	r3, #0
   15aa0: 1a000007     	bne	0x15ac4 <free_lock+0x54> @ imm = #0x1c
   15aa4: e51b3010     	ldr	r3, [r11, #-0x10]
   15aa8: e1a00003     	mov	r0, r3
   15aac: ebffdaab     	bl	0xc560 <pthread_mutex_destroy@plt> @ imm = #-0x9554
   15ab0: e1a03000     	mov	r3, r0
   15ab4: e50b3008     	str	r3, [r11, #-0x8]
   15ab8: e51b3008     	ldr	r3, [r11, #-0x8]
   15abc: e3530000     	cmp	r3, #0
   15ac0: 0a000001     	beq	0x15acc <free_lock+0x5c> @ imm = #0x4
   15ac4: e51b0008     	ldr	r0, [r11, #-0x8]
   15ac8: ebfffec4     	bl	0x155e0 <fail>          @ imm = #-0x4f0
   15acc: e59f3010     	ldr	r3, [pc, #0x10]         @ 0x15ae4 <free_lock+0x74>
   15ad0: e5933000     	ldr	r3, [r3]
   15ad4: e51b0010     	ldr	r0, [r11, #-0x10]
   15ad8: e12fff33     	blx	r3
   15adc: e24bd004     	sub	sp, r11, #4
   15ae0: e8bd8800     	pop	{r11, pc}
   15ae4: d8 e7 03 00  	.word	0x0003e7d8

