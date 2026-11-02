00011f58 <pb_encode_string>:
   11f58: e92d4800     	push	{r11, lr}
   11f5c: e28db004     	add	r11, sp, #4
   11f60: e24dd010     	sub	sp, sp, #16
   11f64: e50b0008     	str	r0, [r11, #-0x8]
   11f68: e50b100c     	str	r1, [r11, #-0xc]
   11f6c: e50b2010     	str	r2, [r11, #-0x10]
   11f70: e51b3010     	ldr	r3, [r11, #-0x10]
   11f74: e1a02003     	mov	r2, r3
   11f78: e3a03000     	mov	r3, #0
   11f7c: e51b0008     	ldr	r0, [r11, #-0x8]
   11f80: ebffff6e     	bl	0x11d40 <pb_encode_varint> @ imm = #-0x248
   11f84: e1a03000     	mov	r3, r0
   11f88: e2233001     	eor	r3, r3, #1
   11f8c: e6ef3073     	uxtb	r3, r3
   11f90: e3530000     	cmp	r3, #0
   11f94: 0a000001     	beq	0x11fa0 <pb_encode_string+0x48> @ imm = #0x4
   11f98: e3a03000     	mov	r3, #0
   11f9c: ea000004     	b	0x11fb4 <pb_encode_string+0x5c> @ imm = #0x10
   11fa0: e51b0008     	ldr	r0, [r11, #-0x8]
   11fa4: e51b100c     	ldr	r1, [r11, #-0xc]
   11fa8: e51b2010     	ldr	r2, [r11, #-0x10]
   11fac: ebfffdb9     	bl	0x11698 <pb_write>      @ imm = #-0x91c
   11fb0: e1a03000     	mov	r3, r0
   11fb4: e1a00003     	mov	r0, r3
   11fb8: e24bd004     	sub	sp, r11, #4
   11fbc: e8bd8800     	pop	{r11, pc}

