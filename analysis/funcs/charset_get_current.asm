0000e4ac <charset_get_current>:
    e4ac: e92d4800     	push	{r11, lr}
    e4b0: e28db004     	add	r11, sp, #4
    e4b4: e24dd008     	sub	sp, sp, #8
    e4b8: e59f002c     	ldr	r0, [pc, #0x2c]         @ 0xe4ec <charset_get_current+0x40>
    e4bc: ebfff791     	bl	0xc308 <getenv@plt>     @ imm = #-0x21bc
    e4c0: e1a03000     	mov	r3, r0
    e4c4: e50b3008     	str	r3, [r11, #-0x8]
    e4c8: e51b3008     	ldr	r3, [r11, #-0x8]
    e4cc: e3530000     	cmp	r3, #0
    e4d0: 1a000001     	bne	0xe4dc <charset_get_current+0x30> @ imm = #0x4
    e4d4: e59f3014     	ldr	r3, [pc, #0x14]         @ 0xe4f0 <charset_get_current+0x44>
    e4d8: e50b3008     	str	r3, [r11, #-0x8]
    e4dc: e51b3008     	ldr	r3, [r11, #-0x8]
    e4e0: e1a00003     	mov	r0, r3
    e4e4: e24bd004     	sub	sp, r11, #4
    e4e8: e8bd8800     	pop	{r11, pc}
    e4ec: ac 26 03 00  	.word	0x000326ac
    e4f0: b4 26 03 00  	.word	0x000326b4

