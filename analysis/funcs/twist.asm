00015830 <twist>:
   15830: e92d4800     	push	{r11, lr}
   15834: e28db004     	add	r11, sp, #4
   15838: e24dd018     	sub	sp, sp, #24
   1583c: e50b0010     	str	r0, [r11, #-0x10]
   15840: e50b1014     	str	r1, [r11, #-0x14]
   15844: e50b2018     	str	r2, [r11, #-0x18]
   15848: e51b3014     	ldr	r3, [r11, #-0x14]
   1584c: e3530000     	cmp	r3, #0
   15850: 1a000003     	bne	0x15864 <twist+0x34>    @ imm = #0xc
   15854: e51b3010     	ldr	r3, [r11, #-0x10]
   15858: e51b2018     	ldr	r2, [r11, #-0x18]
   1585c: e5832048     	str	r2, [r3, #0x48]
   15860: ea000008     	b	0x15888 <twist+0x58>    @ imm = #0x20
   15864: e51b3014     	ldr	r3, [r11, #-0x14]
   15868: e3530001     	cmp	r3, #1
   1586c: 1a000005     	bne	0x15888 <twist+0x58>    @ imm = #0x14
   15870: e51b3010     	ldr	r3, [r11, #-0x10]
   15874: e5932048     	ldr	r2, [r3, #0x48]
   15878: e51b3018     	ldr	r3, [r11, #-0x18]
   1587c: e0822003     	add	r2, r2, r3
   15880: e51b3010     	ldr	r3, [r11, #-0x10]
   15884: e5832048     	str	r2, [r3, #0x48]
   15888: e51b3010     	ldr	r3, [r11, #-0x10]
   1588c: e2833018     	add	r3, r3, #24
   15890: e1a00003     	mov	r0, r3
   15894: ebffdad7     	bl	0xc3f8 <pthread_cond_broadcast@plt> @ imm = #-0x94a4
   15898: e1a03000     	mov	r3, r0
   1589c: e50b3008     	str	r3, [r11, #-0x8]
   158a0: e51b3008     	ldr	r3, [r11, #-0x8]
   158a4: e3530000     	cmp	r3, #0
   158a8: 1a000007     	bne	0x158cc <twist+0x9c>    @ imm = #0x1c
   158ac: e51b3010     	ldr	r3, [r11, #-0x10]
   158b0: e1a00003     	mov	r0, r3
   158b4: ebffdaf0     	bl	0xc47c <pthread_mutex_unlock@plt> @ imm = #-0x9440
   158b8: e1a03000     	mov	r3, r0
   158bc: e50b3008     	str	r3, [r11, #-0x8]
   158c0: e51b3008     	ldr	r3, [r11, #-0x8]
   158c4: e3530000     	cmp	r3, #0
   158c8: 0a000001     	beq	0x158d4 <twist+0xa4>    @ imm = #0x4
   158cc: e51b0008     	ldr	r0, [r11, #-0x8]
   158d0: ebffff42     	bl	0x155e0 <fail>          @ imm = #-0x2f8
   158d4: e24bd004     	sub	sp, r11, #4
   158d8: e8bd8800     	pop	{r11, pc}

