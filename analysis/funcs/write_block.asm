000282f4 <write_block>:
   282f4: e92d4800     	push	{r11, lr}
   282f8: e28db004     	add	r11, sp, #4
   282fc: e24dd018     	sub	sp, sp, #24
   28300: e50b0010     	str	r0, [r11, #-0x10]
   28304: e50b1014     	str	r1, [r11, #-0x14]
   28308: e50b2018     	str	r2, [r11, #-0x18]
   2830c: e51b3010     	ldr	r3, [r11, #-0x10]
   28310: e593304c     	ldr	r3, [r3, #0x4c]
   28314: e3530000     	cmp	r3, #0
   28318: 0a000007     	beq	0x2833c <write_block+0x48> @ imm = #0x1c
   2831c: e51b3010     	ldr	r3, [r11, #-0x10]
   28320: e593304c     	ldr	r3, [r3, #0x4c]
   28324: e51b0010     	ldr	r0, [r11, #-0x10]
   28328: e51b1014     	ldr	r1, [r11, #-0x14]
   2832c: e51b2018     	ldr	r2, [r11, #-0x18]
   28330: e12fff33     	blx	r3
   28334: e1a03000     	mov	r3, r0
   28338: ea000000     	b	0x28340 <write_block+0x4c> @ imm = #0x0
   2833c: e3a03000     	mov	r3, #0
   28340: e50b3008     	str	r3, [r11, #-0x8]
   28344: e51b3010     	ldr	r3, [r11, #-0x10]
   28348: e1c302d8     	ldrd	r0, r1, [r3, #40]
   2834c: e51b3008     	ldr	r3, [r11, #-0x8]
   28350: e1a02003     	mov	r2, r3
   28354: e3a03000     	mov	r3, #0
   28358: e0922000     	adds	r2, r2, r0
   2835c: e0a33001     	adc	r3, r3, r1
   28360: e51b1010     	ldr	r1, [r11, #-0x10]
   28364: e1c122f8     	strd	r2, r3, [r1, #40]
   28368: e51b3008     	ldr	r3, [r11, #-0x8]
   2836c: e1a00003     	mov	r0, r3
   28370: e24bd004     	sub	sp, r11, #4
   28374: e8bd8800     	pop	{r11, pc}

