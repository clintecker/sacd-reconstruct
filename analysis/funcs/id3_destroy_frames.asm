0001c9c0 <id3_destroy_frames>:
   1c9c0: e92d4800     	push	{r11, lr}
   1c9c4: e28db004     	add	r11, sp, #4
   1c9c8: e24dd010     	sub	sp, sp, #16
   1c9cc: e50b0010     	str	r0, [r11, #-0x10]
   1c9d0: ea000019     	b	0x1ca3c <id3_destroy_frames+0x7c> @ imm = #0x64
   1c9d4: e51b3010     	ldr	r3, [r11, #-0x10]
   1c9d8: e5933138     	ldr	r3, [r3, #0x138]
   1c9dc: e50b300c     	str	r3, [r11, #-0xc]
   1c9e0: e51b300c     	ldr	r3, [r11, #-0xc]
   1c9e4: e2433028     	sub	r3, r3, #40
   1c9e8: e50b3008     	str	r3, [r11, #-0x8]
   1c9ec: e51b000c     	ldr	r0, [r11, #-0xc]
   1c9f0: ebfffe15     	bl	0x1c24c <list_del>      @ imm = #-0x7ac
   1c9f4: e51b3008     	ldr	r3, [r11, #-0x8]
   1c9f8: e5933018     	ldr	r3, [r3, #0x18]
   1c9fc: e3530000     	cmp	r3, #0
   1ca00: 0a000003     	beq	0x1ca14 <id3_destroy_frames+0x54> @ imm = #0xc
   1ca04: e51b3008     	ldr	r3, [r11, #-0x8]
   1ca08: e5933018     	ldr	r3, [r3, #0x18]
   1ca0c: e1a00003     	mov	r0, r3
   1ca10: ebffbe81     	bl	0xc41c <free@plt>       @ imm = #-0x105fc
   1ca14: e51b3008     	ldr	r3, [r11, #-0x8]
   1ca18: e5933020     	ldr	r3, [r3, #0x20]
   1ca1c: e3530000     	cmp	r3, #0
   1ca20: 0a000003     	beq	0x1ca34 <id3_destroy_frames+0x74> @ imm = #0xc
   1ca24: e51b3008     	ldr	r3, [r11, #-0x8]
   1ca28: e5933020     	ldr	r3, [r3, #0x20]
   1ca2c: e1a00003     	mov	r0, r3
   1ca30: ebffbe79     	bl	0xc41c <free@plt>       @ imm = #-0x1061c
   1ca34: e51b0008     	ldr	r0, [r11, #-0x8]
   1ca38: ebffbe77     	bl	0xc41c <free@plt>       @ imm = #-0x10624
   1ca3c: e51b3010     	ldr	r3, [r11, #-0x10]
   1ca40: e2833f4e     	add	r3, r3, #312
   1ca44: e1a00003     	mov	r0, r3
   1ca48: ebfffe14     	bl	0x1c2a0 <list_empty>    @ imm = #-0x7b0
   1ca4c: e1a03000     	mov	r3, r0
   1ca50: e3530000     	cmp	r3, #0
   1ca54: 0affffde     	beq	0x1c9d4 <id3_destroy_frames+0x14> @ imm = #-0x88
   1ca58: e24bd004     	sub	sp, r11, #4
   1ca5c: e8bd8800     	pop	{r11, pc}

