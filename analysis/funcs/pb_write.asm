00011698 <pb_write>:
   11698: e92d4800     	push	{r11, lr}
   1169c: e28db004     	add	r11, sp, #4
   116a0: e24dd010     	sub	sp, sp, #16
   116a4: e50b0008     	str	r0, [r11, #-0x8]
   116a8: e50b100c     	str	r1, [r11, #-0xc]
   116ac: e50b2010     	str	r2, [r11, #-0x10]
   116b0: e51b3008     	ldr	r3, [r11, #-0x8]
   116b4: e5933000     	ldr	r3, [r3]
   116b8: e3530000     	cmp	r3, #0
   116bc: 0a000016     	beq	0x1171c <pb_write+0x84> @ imm = #0x58
   116c0: e51b3008     	ldr	r3, [r11, #-0x8]
   116c4: e593200c     	ldr	r2, [r3, #0xc]
   116c8: e51b3010     	ldr	r3, [r11, #-0x10]
   116cc: e0822003     	add	r2, r2, r3
   116d0: e51b3008     	ldr	r3, [r11, #-0x8]
   116d4: e5933008     	ldr	r3, [r3, #0x8]
   116d8: e1520003     	cmp	r2, r3
   116dc: 9a000001     	bls	0x116e8 <pb_write+0x50> @ imm = #0x4
   116e0: e3a03000     	mov	r3, #0
   116e4: ea000013     	b	0x11738 <pb_write+0xa0> @ imm = #0x4c
   116e8: e51b3008     	ldr	r3, [r11, #-0x8]
   116ec: e5933000     	ldr	r3, [r3]
   116f0: e51b0008     	ldr	r0, [r11, #-0x8]
   116f4: e51b100c     	ldr	r1, [r11, #-0xc]
   116f8: e51b2010     	ldr	r2, [r11, #-0x10]
   116fc: e12fff33     	blx	r3
   11700: e1a03000     	mov	r3, r0
   11704: e2233001     	eor	r3, r3, #1
   11708: e6ef3073     	uxtb	r3, r3
   1170c: e3530000     	cmp	r3, #0
   11710: 0a000001     	beq	0x1171c <pb_write+0x84> @ imm = #0x4
   11714: e3a03000     	mov	r3, #0
   11718: ea000006     	b	0x11738 <pb_write+0xa0> @ imm = #0x18
   1171c: e51b3008     	ldr	r3, [r11, #-0x8]
   11720: e593200c     	ldr	r2, [r3, #0xc]
   11724: e51b3010     	ldr	r3, [r11, #-0x10]
   11728: e0822003     	add	r2, r2, r3
   1172c: e51b3008     	ldr	r3, [r11, #-0x8]
   11730: e583200c     	str	r2, [r3, #0xc]
   11734: e3a03001     	mov	r3, #1
   11738: e1a00003     	mov	r0, r3
   1173c: e24bd004     	sub	sp, r11, #4
   11740: e8bd8800     	pop	{r11, pc}

