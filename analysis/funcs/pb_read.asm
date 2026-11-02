0000e7dc <pb_read>:
    e7dc: e92d4800     	push	{r11, lr}
    e7e0: e28db004     	add	r11, sp, #4
    e7e4: e24dd010     	sub	sp, sp, #16
    e7e8: e50b0008     	str	r0, [r11, #-0x8]
    e7ec: e50b100c     	str	r1, [r11, #-0xc]
    e7f0: e50b2010     	str	r2, [r11, #-0x10]
    e7f4: e51b3008     	ldr	r3, [r11, #-0x8]
    e7f8: e5932008     	ldr	r2, [r3, #0x8]
    e7fc: e51b3010     	ldr	r3, [r11, #-0x10]
    e800: e1520003     	cmp	r2, r3
    e804: 2a000001     	bhs	0xe810 <pb_read+0x34>   @ imm = #0x4
    e808: e3a03000     	mov	r3, #0
    e80c: ea000013     	b	0xe860 <pb_read+0x84>   @ imm = #0x4c
    e810: e51b3008     	ldr	r3, [r11, #-0x8]
    e814: e5933000     	ldr	r3, [r3]
    e818: e51b0008     	ldr	r0, [r11, #-0x8]
    e81c: e51b100c     	ldr	r1, [r11, #-0xc]
    e820: e51b2010     	ldr	r2, [r11, #-0x10]
    e824: e12fff33     	blx	r3
    e828: e1a03000     	mov	r3, r0
    e82c: e2233001     	eor	r3, r3, #1
    e830: e6ef3073     	uxtb	r3, r3
    e834: e3530000     	cmp	r3, #0
    e838: 0a000001     	beq	0xe844 <pb_read+0x68>   @ imm = #0x4
    e83c: e3a03000     	mov	r3, #0
    e840: ea000006     	b	0xe860 <pb_read+0x84>   @ imm = #0x18
    e844: e51b3008     	ldr	r3, [r11, #-0x8]
    e848: e5932008     	ldr	r2, [r3, #0x8]
    e84c: e51b3010     	ldr	r3, [r11, #-0x10]
    e850: e0632002     	rsb	r2, r3, r2
    e854: e51b3008     	ldr	r3, [r11, #-0x8]
    e858: e5832008     	str	r2, [r3, #0x8]
    e85c: e3a03001     	mov	r3, #1
    e860: e1a00003     	mov	r0, r3
    e864: e24bd004     	sub	sp, r11, #4
    e868: e8bd8800     	pop	{r11, pc}

