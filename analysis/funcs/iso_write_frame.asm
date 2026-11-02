0002e540 <iso_write_frame>:
   2e540: e92d4800     	push	{r11, lr}
   2e544: e28db004     	add	r11, sp, #4
   2e548: e24dd010     	sub	sp, sp, #16
   2e54c: e50b0008     	str	r0, [r11, #-0x8]
   2e550: e50b100c     	str	r1, [r11, #-0xc]
   2e554: e50b2010     	str	r2, [r11, #-0x10]
   2e558: e51b3010     	ldr	r3, [r11, #-0x10]
   2e55c: e1a02583     	lsl	r2, r3, #11
   2e560: e51b3008     	ldr	r3, [r11, #-0x8]
   2e564: e593301c     	ldr	r3, [r3, #0x1c]
   2e568: e51b000c     	ldr	r0, [r11, #-0xc]
   2e56c: e3a01001     	mov	r1, #1
   2e570: ebff781e     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x21f88
   2e574: e1a03000     	mov	r3, r0
   2e578: e1a00003     	mov	r0, r3
   2e57c: e24bd004     	sub	sp, r11, #4
   2e580: e8bd8800     	pop	{r11, pc}

