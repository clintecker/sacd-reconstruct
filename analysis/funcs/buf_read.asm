0000e86c <buf_read>:
    e86c: e92d4800     	push	{r11, lr}
    e870: e28db004     	add	r11, sp, #4
    e874: e24dd018     	sub	sp, sp, #24
    e878: e50b0010     	str	r0, [r11, #-0x10]
    e87c: e50b1014     	str	r1, [r11, #-0x14]
    e880: e50b2018     	str	r2, [r11, #-0x18]
    e884: e51b3010     	ldr	r3, [r11, #-0x10]
    e888: e5933004     	ldr	r3, [r3, #0x4]
    e88c: e50b3008     	str	r3, [r11, #-0x8]
    e890: e51b3014     	ldr	r3, [r11, #-0x14]
    e894: e3530000     	cmp	r3, #0
    e898: 0a000003     	beq	0xe8ac <buf_read+0x40>  @ imm = #0xc
    e89c: e51b0014     	ldr	r0, [r11, #-0x14]
    e8a0: e51b1008     	ldr	r1, [r11, #-0x8]
    e8a4: e51b2018     	ldr	r2, [r11, #-0x18]
    e8a8: ebfff717     	bl	0xc50c <memcpy@plt>     @ imm = #-0x23a4
    e8ac: e51b2008     	ldr	r2, [r11, #-0x8]
    e8b0: e51b3018     	ldr	r3, [r11, #-0x18]
    e8b4: e0822003     	add	r2, r2, r3
    e8b8: e51b3010     	ldr	r3, [r11, #-0x10]
    e8bc: e5832004     	str	r2, [r3, #0x4]
    e8c0: e3a03001     	mov	r3, #1
    e8c4: e1a00003     	mov	r0, r3
    e8c8: e24bd004     	sub	sp, r11, #4
    e8cc: e8bd8800     	pop	{r11, pc}

