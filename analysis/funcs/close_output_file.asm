00028170 <close_output_file>:
   28170: e92d4800     	push	{r11, lr}
   28174: e28db004     	add	r11, sp, #4
   28178: e24dd010     	sub	sp, sp, #16
   2817c: e50b0010     	str	r0, [r11, #-0x10]
   28180: e51b3010     	ldr	r3, [r11, #-0x10]
   28184: e5933050     	ldr	r3, [r3, #0x50]
   28188: e3530000     	cmp	r3, #0
   2818c: 0a000005     	beq	0x281a8 <close_output_file+0x38> @ imm = #0x14
   28190: e51b3010     	ldr	r3, [r11, #-0x10]
   28194: e5933050     	ldr	r3, [r3, #0x50]
   28198: e51b0010     	ldr	r0, [r11, #-0x10]
   2819c: e12fff33     	blx	r3
   281a0: e1a03000     	mov	r3, r0
   281a4: ea000000     	b	0x281ac <close_output_file+0x3c> @ imm = #0x0
   281a8: e3a03000     	mov	r3, #0
   281ac: e50b3008     	str	r3, [r11, #-0x8]
   281b0: e51b3010     	ldr	r3, [r11, #-0x10]
   281b4: e593301c     	ldr	r3, [r3, #0x1c]
   281b8: e3530000     	cmp	r3, #0
   281bc: 0a000003     	beq	0x281d0 <close_output_file+0x60> @ imm = #0xc
   281c0: e51b3010     	ldr	r3, [r11, #-0x10]
   281c4: e593301c     	ldr	r3, [r3, #0x1c]
   281c8: e1a00003     	mov	r0, r3
   281cc: ebff9044     	bl	0xc2e4 <fclose@plt>     @ imm = #-0x1bef0
   281d0: e51b3010     	ldr	r3, [r11, #-0x10]
   281d4: e5933020     	ldr	r3, [r3, #0x20]
   281d8: e1a00003     	mov	r0, r3
   281dc: ebff908e     	bl	0xc41c <free@plt>       @ imm = #-0x1bdc8
   281e0: e51b3010     	ldr	r3, [r11, #-0x10]
   281e4: e5933014     	ldr	r3, [r3, #0x14]
   281e8: e1a00003     	mov	r0, r3
   281ec: ebff908a     	bl	0xc41c <free@plt>       @ imm = #-0x1bdd8
   281f0: e51b3010     	ldr	r3, [r11, #-0x10]
   281f4: e593305c     	ldr	r3, [r3, #0x5c]
   281f8: e1a00003     	mov	r0, r3
   281fc: ebff9086     	bl	0xc41c <free@plt>       @ imm = #-0x1bde8
   28200: e51b0010     	ldr	r0, [r11, #-0x10]
   28204: ebff9084     	bl	0xc41c <free@plt>       @ imm = #-0x1bdf0
   28208: e51b3008     	ldr	r3, [r11, #-0x8]
   2820c: e1a00003     	mov	r0, r3
   28210: e24bd004     	sub	sp, r11, #4
   28214: e8bd8800     	pop	{r11, pc}

