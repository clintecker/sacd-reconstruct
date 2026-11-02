0001c7dc <id3_delete_frame>:
   1c7dc: e92d4800     	push	{r11, lr}
   1c7e0: e28db004     	add	r11, sp, #4
   1c7e4: e24dd018     	sub	sp, sp, #24
   1c7e8: e50b0018     	str	r0, [r11, #-0x18]
   1c7ec: e3e03000     	mvn	r3, #0
   1c7f0: e50b3008     	str	r3, [r11, #-0x8]
   1c7f4: e51b3018     	ldr	r3, [r11, #-0x18]
   1c7f8: e5933000     	ldr	r3, [r3]
   1c7fc: e5933138     	ldr	r3, [r3, #0x138]
   1c800: e50b3010     	str	r3, [r11, #-0x10]
   1c804: ea000012     	b	0x1c854 <id3_delete_frame+0x78> @ imm = #0x48
   1c808: e51b3010     	ldr	r3, [r11, #-0x10]
   1c80c: e2433028     	sub	r3, r3, #40
   1c810: e50b300c     	str	r3, [r11, #-0xc]
   1c814: e51b200c     	ldr	r2, [r11, #-0xc]
   1c818: e51b3018     	ldr	r3, [r11, #-0x18]
   1c81c: e1520003     	cmp	r2, r3
   1c820: 1a000008     	bne	0x1c848 <id3_delete_frame+0x6c> @ imm = #0x20
   1c824: e51b0010     	ldr	r0, [r11, #-0x10]
   1c828: ebfffe87     	bl	0x1c24c <list_del>      @ imm = #-0x5e4
   1c82c: e51b3018     	ldr	r3, [r11, #-0x18]
   1c830: e5933000     	ldr	r3, [r3]
   1c834: e3a02001     	mov	r2, #1
   1c838: e583200c     	str	r2, [r3, #0xc]
   1c83c: e3a03000     	mov	r3, #0
   1c840: e50b3008     	str	r3, [r11, #-0x8]
   1c844: ea00000c     	b	0x1c87c <id3_delete_frame+0xa0> @ imm = #0x30
   1c848: e51b3010     	ldr	r3, [r11, #-0x10]
   1c84c: e5933000     	ldr	r3, [r3]
   1c850: e50b3010     	str	r3, [r11, #-0x10]
   1c854: e51b3010     	ldr	r3, [r11, #-0x10]
   1c858: e5932000     	ldr	r2, [r3]
   1c85c: e51b3010     	ldr	r3, [r11, #-0x10]
   1c860: e5832000     	str	r2, [r3]
   1c864: e51b3018     	ldr	r3, [r11, #-0x18]
   1c868: e5933000     	ldr	r3, [r3]
   1c86c: e2832f4e     	add	r2, r3, #312
   1c870: e51b3010     	ldr	r3, [r11, #-0x10]
   1c874: e1520003     	cmp	r2, r3
   1c878: 1affffe2     	bne	0x1c808 <id3_delete_frame+0x2c> @ imm = #-0x78
   1c87c: e51b3018     	ldr	r3, [r11, #-0x18]
   1c880: e5933018     	ldr	r3, [r3, #0x18]
   1c884: e3530000     	cmp	r3, #0
   1c888: 0a000003     	beq	0x1c89c <id3_delete_frame+0xc0> @ imm = #0xc
   1c88c: e51b3018     	ldr	r3, [r11, #-0x18]
   1c890: e5933018     	ldr	r3, [r3, #0x18]
   1c894: e1a00003     	mov	r0, r3
   1c898: ebffbedf     	bl	0xc41c <free@plt>       @ imm = #-0x10484
   1c89c: e51b3018     	ldr	r3, [r11, #-0x18]
   1c8a0: e5933020     	ldr	r3, [r3, #0x20]
   1c8a4: e3530000     	cmp	r3, #0
   1c8a8: 0a000003     	beq	0x1c8bc <id3_delete_frame+0xe0> @ imm = #0xc
   1c8ac: e51b3018     	ldr	r3, [r11, #-0x18]
   1c8b0: e5933020     	ldr	r3, [r3, #0x20]
   1c8b4: e1a00003     	mov	r0, r3
   1c8b8: ebffbed7     	bl	0xc41c <free@plt>       @ imm = #-0x104a4
   1c8bc: e51b0018     	ldr	r0, [r11, #-0x18]
   1c8c0: ebffbed5     	bl	0xc41c <free@plt>       @ imm = #-0x104ac
   1c8c4: e51b3008     	ldr	r3, [r11, #-0x8]
   1c8c8: e1a00003     	mov	r0, r3
   1c8cc: e24bd004     	sub	sp, r11, #4
   1c8d0: e8bd8800     	pop	{r11, pc}

