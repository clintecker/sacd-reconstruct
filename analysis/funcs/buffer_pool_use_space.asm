000162b4 <buffer_pool_use_space>:
   162b4: e92d4800     	push	{r11, lr}
   162b8: e28db004     	add	r11, sp, #4
   162bc: e24dd008     	sub	sp, sp, #8
   162c0: e50b0008     	str	r0, [r11, #-0x8]
   162c4: e51b3008     	ldr	r3, [r11, #-0x8]
   162c8: e5933000     	ldr	r3, [r3]
   162cc: e1a00003     	mov	r0, r3
   162d0: ebfffd36     	bl	0x157b0 <possess>       @ imm = #-0xb28
   162d4: e51b3008     	ldr	r3, [r11, #-0x8]
   162d8: e5933000     	ldr	r3, [r3]
   162dc: e1a00003     	mov	r0, r3
   162e0: e3a01001     	mov	r1, #1
   162e4: e3a02001     	mov	r2, #1
   162e8: ebfffd50     	bl	0x15830 <twist>         @ imm = #-0xac0
   162ec: e24bd004     	sub	sp, r11, #4
   162f0: e8bd8800     	pop	{r11, pc}

