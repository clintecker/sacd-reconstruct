00019dc8 <_mm_malloc>:
   19dc8: e92d4800     	push	{r11, lr}
   19dcc: e28db004     	add	r11, sp, #4
   19dd0: e24dd010     	sub	sp, sp, #16
   19dd4: e50b0010     	str	r0, [r11, #-0x10]
   19dd8: e50b1014     	str	r1, [r11, #-0x14]
   19ddc: e51b3014     	ldr	r3, [r11, #-0x14]
   19de0: e3530001     	cmp	r3, #1
   19de4: 1a000003     	bne	0x19df8 <_mm_malloc+0x30> @ imm = #0xc
   19de8: e51b0010     	ldr	r0, [r11, #-0x10]
   19dec: ebffca1d     	bl	0xc668 <malloc@plt>     @ imm = #-0xd78c
   19df0: e1a03000     	mov	r3, r0
   19df4: ea00000f     	b	0x19e38 <_mm_malloc+0x70> @ imm = #0x3c
   19df8: e51b3014     	ldr	r3, [r11, #-0x14]
   19dfc: e3530002     	cmp	r3, #2
   19e00: 1a000001     	bne	0x19e0c <_mm_malloc+0x44> @ imm = #0x4
   19e04: e3a03004     	mov	r3, #4
   19e08: e50b3014     	str	r3, [r11, #-0x14]
   19e0c: e24b3008     	sub	r3, r11, #8
   19e10: e1a00003     	mov	r0, r3
   19e14: e51b1014     	ldr	r1, [r11, #-0x14]
   19e18: e51b2010     	ldr	r2, [r11, #-0x10]
   19e1c: ebffc9a5     	bl	0xc4b8 <posix_memalign@plt> @ imm = #-0xd96c
   19e20: e1a03000     	mov	r3, r0
   19e24: e3530000     	cmp	r3, #0
   19e28: 1a000001     	bne	0x19e34 <_mm_malloc+0x6c> @ imm = #0x4
   19e2c: e51b3008     	ldr	r3, [r11, #-0x8]
   19e30: ea000000     	b	0x19e38 <_mm_malloc+0x70> @ imm = #0x0
   19e34: e3a03000     	mov	r3, #0
   19e38: e1a00003     	mov	r0, r3
   19e3c: e24bd004     	sub	sp, r11, #4
   19e40: e8bd8800     	pop	{r11, pc}

