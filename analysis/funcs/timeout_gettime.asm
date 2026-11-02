00010370 <timeout_gettime>:
   10370: e92d4830     	push	{r4, r5, r11, lr}
   10374: e28db00c     	add	r11, sp, #12
   10378: e24dd008     	sub	sp, sp, #8
   1037c: e24b3014     	sub	r3, r11, #20
   10380: e1a00003     	mov	r0, r3
   10384: e3a01000     	mov	r1, #0
   10388: ebfff032     	bl	0xc458 <gettimeofday@plt> @ imm = #-0x3f38
   1038c: e51b3014     	ldr	r3, [r11, #-0x14]
   10390: e1a00003     	mov	r0, r3
   10394: eb007fd1     	bl	0x302e0 <__floatsidf>   @ imm = #0x1ff44
   10398: e1a04000     	mov	r4, r0
   1039c: e1a05001     	mov	r5, r1
   103a0: e51b3010     	ldr	r3, [r11, #-0x10]
   103a4: e1a00003     	mov	r0, r3
   103a8: eb007fcc     	bl	0x302e0 <__floatsidf>   @ imm = #0x1ff30
   103ac: e1a02000     	mov	r2, r0
   103b0: e1a03001     	mov	r3, r1
   103b4: e1a00002     	mov	r0, r2
   103b8: e1a01003     	mov	r1, r3
   103bc: e28f3034     	add	r3, pc, #52
   103c0: e1c320d0     	ldrd	r2, r3, [r3]
   103c4: eb008097     	bl	0x30628 <__divdf3>      @ imm = #0x2025c
   103c8: e1a02000     	mov	r2, r0
   103cc: e1a03001     	mov	r3, r1
   103d0: e1a00004     	mov	r0, r4
   103d4: e1a01005     	mov	r1, r5
   103d8: eb007f0c     	bl	0x30010 <__aeabi_dadd>  @ imm = #0x1fc30
   103dc: e1a02000     	mov	r2, r0
   103e0: e1a03001     	mov	r3, r1
   103e4: e1a00002     	mov	r0, r2
   103e8: e1a01003     	mov	r1, r3
   103ec: e24bd00c     	sub	sp, r11, #12
   103f0: e8bd8830     	pop	{r4, r5, r11, pc}
   103f4: e1a00000     	mov	r0, r0
   103f8: 00 00 00 00  	.word	0x00000000
   103fc: 80 84 2e 41  	.word	0x412e8480

