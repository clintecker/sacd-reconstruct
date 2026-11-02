0002f688 <dsf_write_frame>:
   2f688: e92d4870     	push	{r4, r5, r6, r11, lr}
   2f68c: e28db010     	add	r11, sp, #16
   2f690: e24dd034     	sub	sp, sp, #52
   2f694: e50b0038     	str	r0, [r11, #-0x38]
   2f698: e50b103c     	str	r1, [r11, #-0x3c]
   2f69c: e50b2040     	str	r2, [r11, #-0x40]
   2f6a0: e51b3038     	ldr	r3, [r11, #-0x38]
   2f6a4: e593305c     	ldr	r3, [r3, #0x5c]
   2f6a8: e50b3030     	str	r3, [r11, #-0x30]
   2f6ac: e51b203c     	ldr	r2, [r11, #-0x3c]
   2f6b0: e51b3040     	ldr	r3, [r11, #-0x40]
   2f6b4: e0823003     	add	r3, r2, r3
   2f6b8: e50b302c     	str	r3, [r11, #-0x2c]
   2f6bc: e51b303c     	ldr	r3, [r11, #-0x3c]
   2f6c0: e50b3028     	str	r3, [r11, #-0x28]
   2f6c4: e51b3030     	ldr	r3, [r11, #-0x30]
   2f6c8: e1c321d0     	ldrd	r2, r3, [r3, #16]
   2f6cc: e14b22f4     	strd	r2, r3, [r11, #-36]
   2f6d0: ea000092     	b	0x2f920 <dsf_write_frame+0x298> @ imm = #0x248
   2f6d4: e3a03000     	mov	r3, #0
   2f6d8: e50b3018     	str	r3, [r11, #-0x18]
   2f6dc: ea00008a     	b	0x2f90c <dsf_write_frame+0x284> @ imm = #0x228
   2f6e0: e51b3018     	ldr	r3, [r11, #-0x18]
   2f6e4: e51b2030     	ldr	r2, [r11, #-0x30]
   2f6e8: e2833b06     	add	r3, r3, #6144
   2f6ec: e283300a     	add	r3, r3, #10
   2f6f0: e7923103     	ldr	r3, [r2, r3, lsl #2]
   2f6f4: e3530000     	cmp	r3, #0
   2f6f8: 1a00000a     	bne	0x2f728 <dsf_write_frame+0xa0> @ imm = #0x28
   2f6fc: e51b3018     	ldr	r3, [r11, #-0x18]
   2f700: e51b2030     	ldr	r2, [r11, #-0x30]
   2f704: e2822028     	add	r2, r2, #40
   2f708: e1a01002     	mov	r1, r2
   2f70c: e51b2018     	ldr	r2, [r11, #-0x18]
   2f710: e1a02602     	lsl	r2, r2, #12
   2f714: e0811002     	add	r1, r1, r2
   2f718: e51b2030     	ldr	r2, [r11, #-0x30]
   2f71c: e2833b06     	add	r3, r3, #6144
   2f720: e283300a     	add	r3, r3, #10
   2f724: e7821103     	str	r1, [r2, r3, lsl #2]
   2f728: e51b3018     	ldr	r3, [r11, #-0x18]
   2f72c: e51b2030     	ldr	r2, [r11, #-0x30]
   2f730: e2833b06     	add	r3, r3, #6144
   2f734: e283300a     	add	r3, r3, #10
   2f738: e7922103     	ldr	r2, [r2, r3, lsl #2]
   2f73c: e51b3030     	ldr	r3, [r11, #-0x30]
   2f740: e2833028     	add	r3, r3, #40
   2f744: e1a01003     	mov	r1, r3
   2f748: e51b3018     	ldr	r3, [r11, #-0x18]
   2f74c: e2833001     	add	r3, r3, #1
   2f750: e1a03603     	lsl	r3, r3, #12
   2f754: e0813003     	add	r3, r1, r3
   2f758: e1520003     	cmp	r2, r3
   2f75c: 2a00002b     	bhs	0x2f810 <dsf_write_frame+0x188> @ imm = #0xac
   2f760: e51b3018     	ldr	r3, [r11, #-0x18]
   2f764: e51b2030     	ldr	r2, [r11, #-0x30]
   2f768: e2833b06     	add	r3, r3, #6144
   2f76c: e283300a     	add	r3, r3, #10
   2f770: e7924103     	ldr	r4, [r2, r3, lsl #2]
   2f774: e51b3030     	ldr	r3, [r11, #-0x30]
   2f778: e2833028     	add	r3, r3, #40
   2f77c: e1a05003     	mov	r5, r3
   2f780: e51b3018     	ldr	r3, [r11, #-0x18]
   2f784: e1a06603     	lsl	r6, r3, #12
   2f788: e51b3030     	ldr	r3, [r11, #-0x30]
   2f78c: e5933018     	ldr	r3, [r3, #0x18]
   2f790: e51b0040     	ldr	r0, [r11, #-0x40]
   2f794: e1a01003     	mov	r1, r3
   2f798: eb000109     	bl	0x2fbc4 <__udivsi3>     @ imm = #0x424
   2f79c: e1a03000     	mov	r3, r0
   2f7a0: e0863003     	add	r3, r6, r3
   2f7a4: e0853003     	add	r3, r5, r3
   2f7a8: e1540003     	cmp	r4, r3
   2f7ac: 2a000017     	bhs	0x2f810 <dsf_write_frame+0x188> @ imm = #0x5c
   2f7b0: e51b3018     	ldr	r3, [r11, #-0x18]
   2f7b4: e51b2030     	ldr	r2, [r11, #-0x30]
   2f7b8: e2833b06     	add	r3, r3, #6144
   2f7bc: e283300a     	add	r3, r3, #10
   2f7c0: e7923103     	ldr	r3, [r2, r3, lsl #2]
   2f7c4: e51b2028     	ldr	r2, [r11, #-0x28]
   2f7c8: e5d22000     	ldrb	r2, [r2]
   2f7cc: e59f1178     	ldr	r1, [pc, #0x178]        @ 0x2f94c <dsf_write_frame+0x2c4>
   2f7d0: e7d12002     	ldrb	r2, [r1, r2]
   2f7d4: e5c32000     	strb	r2, [r3]
   2f7d8: e51b2018     	ldr	r2, [r11, #-0x18]
   2f7dc: e51b1030     	ldr	r1, [r11, #-0x30]
   2f7e0: e2823b06     	add	r3, r2, #6144
   2f7e4: e283300a     	add	r3, r3, #10
   2f7e8: e7913103     	ldr	r3, [r1, r3, lsl #2]
   2f7ec: e2830001     	add	r0, r3, #1
   2f7f0: e51b1030     	ldr	r1, [r11, #-0x30]
   2f7f4: e2823b06     	add	r3, r2, #6144
   2f7f8: e283300a     	add	r3, r3, #10
   2f7fc: e7810103     	str	r0, [r1, r3, lsl #2]
   2f800: e51b3028     	ldr	r3, [r11, #-0x28]
   2f804: e2833001     	add	r3, r3, #1
   2f808: e50b3028     	str	r3, [r11, #-0x28]
   2f80c: ea00003b     	b	0x2f900 <dsf_write_frame+0x278> @ imm = #0xec
   2f810: e51b3030     	ldr	r3, [r11, #-0x30]
   2f814: e1c302d0     	ldrd	r0, r1, [r3, #32]
   2f818: e51b3018     	ldr	r3, [r11, #-0x18]
   2f81c: e51b2030     	ldr	r2, [r11, #-0x30]
   2f820: e2833b06     	add	r3, r3, #6144
   2f824: e283300a     	add	r3, r3, #10
   2f828: e7923103     	ldr	r3, [r2, r3, lsl #2]
   2f82c: e1a02003     	mov	r2, r3
   2f830: e51b3030     	ldr	r3, [r11, #-0x30]
   2f834: e2833028     	add	r3, r3, #40
   2f838: e1a0c003     	mov	r12, r3
   2f83c: e51b3018     	ldr	r3, [r11, #-0x18]
   2f840: e1a03603     	lsl	r3, r3, #12
   2f844: e08c3003     	add	r3, r12, r3
   2f848: e0633002     	rsb	r3, r3, r2
   2f84c: e1a02003     	mov	r2, r3
   2f850: e1a03fc2     	asr	r3, r2, #31
   2f854: e0922000     	adds	r2, r2, r0
   2f858: e0a33001     	adc	r3, r3, r1
   2f85c: e51b1030     	ldr	r1, [r11, #-0x30]
   2f860: e1c122f0     	strd	r2, r3, [r1, #32]
   2f864: e51b3030     	ldr	r3, [r11, #-0x30]
   2f868: e2832028     	add	r2, r3, #40
   2f86c: e51b3018     	ldr	r3, [r11, #-0x18]
   2f870: e1a03603     	lsl	r3, r3, #12
   2f874: e0822003     	add	r2, r2, r3
   2f878: e51b3038     	ldr	r3, [r11, #-0x38]
   2f87c: e593301c     	ldr	r3, [r3, #0x1c]
   2f880: e1a00002     	mov	r0, r2
   2f884: e3a01001     	mov	r1, #1
   2f888: e3a02a01     	mov	r2, #4096
   2f88c: ebff7357     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x232a4
   2f890: e51b3030     	ldr	r3, [r11, #-0x30]
   2f894: e2832028     	add	r2, r3, #40
   2f898: e51b3018     	ldr	r3, [r11, #-0x18]
   2f89c: e1a03603     	lsl	r3, r3, #12
   2f8a0: e0823003     	add	r3, r2, r3
   2f8a4: e1a00003     	mov	r0, r3
   2f8a8: e3a01000     	mov	r1, #0
   2f8ac: e3a02a01     	mov	r2, #4096
   2f8b0: ebff72bb     	bl	0xc3a4 <memset@plt>     @ imm = #-0x23514
   2f8b4: e51b3018     	ldr	r3, [r11, #-0x18]
   2f8b8: e51b2030     	ldr	r2, [r11, #-0x30]
   2f8bc: e2822028     	add	r2, r2, #40
   2f8c0: e1a01002     	mov	r1, r2
   2f8c4: e51b2018     	ldr	r2, [r11, #-0x18]
   2f8c8: e1a02602     	lsl	r2, r2, #12
   2f8cc: e0811002     	add	r1, r1, r2
   2f8d0: e51b2030     	ldr	r2, [r11, #-0x30]
   2f8d4: e2833b06     	add	r3, r3, #6144
   2f8d8: e283300a     	add	r3, r3, #10
   2f8dc: e7821103     	str	r1, [r2, r3, lsl #2]
   2f8e0: e51b3030     	ldr	r3, [r11, #-0x30]
   2f8e4: e1c301d0     	ldrd	r0, r1, [r3, #16]
   2f8e8: e3a02a01     	mov	r2, #4096
   2f8ec: e3a03000     	mov	r3, #0
   2f8f0: e0922000     	adds	r2, r2, r0
   2f8f4: e0a33001     	adc	r3, r3, r1
   2f8f8: e51b1030     	ldr	r1, [r11, #-0x30]
   2f8fc: e1c121f0     	strd	r2, r3, [r1, #16]
   2f900: e51b3018     	ldr	r3, [r11, #-0x18]
   2f904: e2833001     	add	r3, r3, #1
   2f908: e50b3018     	str	r3, [r11, #-0x18]
   2f90c: e51b3030     	ldr	r3, [r11, #-0x30]
   2f910: e5932018     	ldr	r2, [r3, #0x18]
   2f914: e51b3018     	ldr	r3, [r11, #-0x18]
   2f918: e1520003     	cmp	r2, r3
   2f91c: caffff6f     	bgt	0x2f6e0 <dsf_write_frame+0x58> @ imm = #-0x244
   2f920: e51b2028     	ldr	r2, [r11, #-0x28]
   2f924: e51b302c     	ldr	r3, [r11, #-0x2c]
   2f928: e1520003     	cmp	r2, r3
   2f92c: 3affff68     	blo	0x2f6d4 <dsf_write_frame+0x4c> @ imm = #-0x260
   2f930: e51b3030     	ldr	r3, [r11, #-0x30]
   2f934: e1c321d0     	ldrd	r2, r3, [r3, #16]
   2f938: e51b3024     	ldr	r3, [r11, #-0x24]
   2f93c: e0633002     	rsb	r3, r3, r2
   2f940: e1a00003     	mov	r0, r3
   2f944: e24bd010     	sub	sp, r11, #16
   2f948: e8bd8870     	pop	{r4, r5, r6, r11, pc}
   2f94c: 48 5f 03 00  	.word	0x00035f48

