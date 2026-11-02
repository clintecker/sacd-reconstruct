00011438 <trim_dots>:
   11438: e92d4800     	push	{r11, lr}
   1143c: e28db004     	add	r11, sp, #4
   11440: e24dd010     	sub	sp, sp, #16
   11444: e50b0010     	str	r0, [r11, #-0x10]
   11448: e51b3010     	ldr	r3, [r11, #-0x10]
   1144c: e50b300c     	str	r3, [r11, #-0xc]
   11450: e51b000c     	ldr	r0, [r11, #-0xc]
   11454: ebffec20     	bl	0xc4dc <strlen@plt>     @ imm = #-0x4f80
   11458: e1a03000     	mov	r3, r0
   1145c: e50b3008     	str	r3, [r11, #-0x8]
   11460: ea000007     	b	0x11484 <trim_dots+0x4c> @ imm = #0x1c
   11464: e51b3008     	ldr	r3, [r11, #-0x8]
   11468: e2433001     	sub	r3, r3, #1
   1146c: e50b3008     	str	r3, [r11, #-0x8]
   11470: e51b3008     	ldr	r3, [r11, #-0x8]
   11474: e51b200c     	ldr	r2, [r11, #-0xc]
   11478: e0823003     	add	r3, r2, r3
   1147c: e3a02000     	mov	r2, #0
   11480: e5c32000     	strb	r2, [r3]
   11484: e51b3008     	ldr	r3, [r11, #-0x8]
   11488: e2433001     	sub	r3, r3, #1
   1148c: e51b200c     	ldr	r2, [r11, #-0xc]
   11490: e0823003     	add	r3, r2, r3
   11494: e5d33000     	ldrb	r3, [r3]
   11498: e353002e     	cmp	r3, #46
   1149c: 0afffff0     	beq	0x11464 <trim_dots+0x2c> @ imm = #-0x40
   114a0: ea000005     	b	0x114bc <trim_dots+0x84> @ imm = #0x14
   114a4: e51b300c     	ldr	r3, [r11, #-0xc]
   114a8: e2833001     	add	r3, r3, #1
   114ac: e50b300c     	str	r3, [r11, #-0xc]
   114b0: e51b3008     	ldr	r3, [r11, #-0x8]
   114b4: e2433001     	sub	r3, r3, #1
   114b8: e50b3008     	str	r3, [r11, #-0x8]
   114bc: e51b300c     	ldr	r3, [r11, #-0xc]
   114c0: e5d33000     	ldrb	r3, [r3]
   114c4: e3530000     	cmp	r3, #0
   114c8: 0a000003     	beq	0x114dc <trim_dots+0xa4> @ imm = #0xc
   114cc: e51b300c     	ldr	r3, [r11, #-0xc]
   114d0: e5d33000     	ldrb	r3, [r3]
   114d4: e353002e     	cmp	r3, #46
   114d8: 0afffff1     	beq	0x114a4 <trim_dots+0x6c> @ imm = #-0x3c
   114dc: e51b3008     	ldr	r3, [r11, #-0x8]
   114e0: e2833001     	add	r3, r3, #1
   114e4: e51b0010     	ldr	r0, [r11, #-0x10]
   114e8: e51b100c     	ldr	r1, [r11, #-0xc]
   114ec: e1a02003     	mov	r2, r3
   114f0: ebffec7d     	bl	0xc6ec <memmove@plt>    @ imm = #-0x4e0c
   114f4: e24bd004     	sub	sp, r11, #4
   114f8: e8bd8800     	pop	{r11, pc}

