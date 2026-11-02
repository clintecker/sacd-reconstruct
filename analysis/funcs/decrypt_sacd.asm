00021164 <decrypt_sacd>:
   21164: e92d4800     	push	{r11, lr}
   21168: e28db004     	add	r11, sp, #4
   2116c: e24dd020     	sub	sp, sp, #32
   21170: e50b0020     	str	r0, [r11, #-0x20]
   21174: e50b1024     	str	r1, [r11, #-0x24]
   21178: e3e03000     	mvn	r3, #0
   2117c: e50b3008     	str	r3, [r11, #-0x8]
   21180: e24b301c     	sub	r3, r11, #28
   21184: e1a00003     	mov	r0, r3
   21188: e3a01000     	mov	r1, #0
   2118c: e3a02010     	mov	r2, #16
   21190: ebffac83     	bl	0xc3a4 <memset@plt>     @ imm = #-0x14df4
   21194: e59f0068     	ldr	r0, [pc, #0x68]         @ 0x21204 <decrypt_sacd+0xa0>
   21198: e3a01000     	mov	r1, #0
   2119c: ebffacf5     	bl	0xc578 <open64@plt>     @ imm = #-0x14c2c
   211a0: e1a03000     	mov	r3, r0
   211a4: e50b300c     	str	r3, [r11, #-0xc]
   211a8: e51b300c     	ldr	r3, [r11, #-0xc]
   211ac: e3530000     	cmp	r3, #0
   211b0: ba00000f     	blt	0x211f4 <decrypt_sacd+0x90> @ imm = #0x3c
   211b4: e51b3020     	ldr	r3, [r11, #-0x20]
   211b8: e50b3014     	str	r3, [r11, #-0x14]
   211bc: e51b3024     	ldr	r3, [r11, #-0x24]
   211c0: e50b3010     	str	r3, [r11, #-0x10]
   211c4: e24b301c     	sub	r3, r11, #28
   211c8: e51b000c     	ldr	r0, [r11, #-0xc]
   211cc: e59f1034     	ldr	r1, [pc, #0x34]         @ 0x21208 <decrypt_sacd+0xa4>
   211d0: e1a02003     	mov	r2, r3
   211d4: ebffacb4     	bl	0xc4ac <ioctl@plt>      @ imm = #-0x14d30
   211d8: e1a03000     	mov	r3, r0
   211dc: e3530000     	cmp	r3, #0
   211e0: ba000001     	blt	0x211ec <decrypt_sacd+0x88> @ imm = #0x4
   211e4: e51b301c     	ldr	r3, [r11, #-0x1c]
   211e8: e50b3008     	str	r3, [r11, #-0x8]
   211ec: e51b000c     	ldr	r0, [r11, #-0xc]
   211f0: ebffacfb     	bl	0xc5e4 <close@plt>      @ imm = #-0x14c14
   211f4: e51b3008     	ldr	r3, [r11, #-0x8]
   211f8: e1a00003     	mov	r0, r3
   211fc: e24bd004     	sub	sp, r11, #4
   21200: e8bd8800     	pop	{r11, pc}
   21204: f8 52 03 00  	.word	0x000352f8
   21208: 04 53 10 40  	.word	0x40105304

