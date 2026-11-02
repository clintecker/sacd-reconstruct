000163d4 <buffer_pool_free>:
   163d4: e92d4800     	push	{r11, lr}
   163d8: e28db004     	add	r11, sp, #4
   163dc: e24dd010     	sub	sp, sp, #16
   163e0: e50b0010     	str	r0, [r11, #-0x10]
   163e4: e51b3010     	ldr	r3, [r11, #-0x10]
   163e8: e5933000     	ldr	r3, [r3]
   163ec: e1a00003     	mov	r0, r3
   163f0: ebfffcee     	bl	0x157b0 <possess>       @ imm = #-0xc48
   163f4: e3a03000     	mov	r3, #0
   163f8: e50b300c     	str	r3, [r11, #-0xc]
   163fc: ea000010     	b	0x16444 <buffer_pool_free+0x70> @ imm = #0x40
   16400: e51b3008     	ldr	r3, [r11, #-0x8]
   16404: e5932010     	ldr	r2, [r3, #0x10]
   16408: e51b3010     	ldr	r3, [r11, #-0x10]
   1640c: e5832004     	str	r2, [r3, #0x4]
   16410: e51b3008     	ldr	r3, [r11, #-0x8]
   16414: e5933004     	ldr	r3, [r3, #0x4]
   16418: e1a00003     	mov	r0, r3
   1641c: ebffd7fe     	bl	0xc41c <free@plt>       @ imm = #-0xa008
   16420: e51b3008     	ldr	r3, [r11, #-0x8]
   16424: e5933000     	ldr	r3, [r3]
   16428: e1a00003     	mov	r0, r3
   1642c: ebfffd8f     	bl	0x15a70 <free_lock>     @ imm = #-0x9c4
   16430: e51b0008     	ldr	r0, [r11, #-0x8]
   16434: ebffd7f8     	bl	0xc41c <free@plt>       @ imm = #-0xa020
   16438: e51b300c     	ldr	r3, [r11, #-0xc]
   1643c: e2833001     	add	r3, r3, #1
   16440: e50b300c     	str	r3, [r11, #-0xc]
   16444: e51b3010     	ldr	r3, [r11, #-0x10]
   16448: e5933004     	ldr	r3, [r3, #0x4]
   1644c: e50b3008     	str	r3, [r11, #-0x8]
   16450: e51b3008     	ldr	r3, [r11, #-0x8]
   16454: e3530000     	cmp	r3, #0
   16458: 1affffe8     	bne	0x16400 <buffer_pool_free+0x2c> @ imm = #-0x60
   1645c: e51b3010     	ldr	r3, [r11, #-0x10]
   16460: e5933000     	ldr	r3, [r3]
   16464: e1a00003     	mov	r0, r3
   16468: ebfffce0     	bl	0x157f0 <release>       @ imm = #-0xc80
   1646c: e51b3010     	ldr	r3, [r11, #-0x10]
   16470: e5933000     	ldr	r3, [r3]
   16474: e1a00003     	mov	r0, r3
   16478: ebfffd7c     	bl	0x15a70 <free_lock>     @ imm = #-0xa10
   1647c: e51b3010     	ldr	r3, [r11, #-0x10]
   16480: e5932010     	ldr	r2, [r3, #0x10]
   16484: e51b300c     	ldr	r3, [r11, #-0xc]
   16488: e1520003     	cmp	r2, r3
   1648c: 0a000004     	beq	0x164a4 <buffer_pool_free+0xd0> @ imm = #0x10
   16490: e59f001c     	ldr	r0, [pc, #0x1c]         @ 0x164b4 <buffer_pool_free+0xe0>
   16494: e59f101c     	ldr	r1, [pc, #0x1c]         @ 0x164b8 <buffer_pool_free+0xe4>
   16498: e3a0208a     	mov	r2, #138
   1649c: e59f3018     	ldr	r3, [pc, #0x18]         @ 0x164bc <buffer_pool_free+0xe8>
   164a0: ebffd7ce     	bl	0xc3e0 <__assert_fail@plt> @ imm = #-0xa0c8
   164a4: e51b300c     	ldr	r3, [r11, #-0xc]
   164a8: e1a00003     	mov	r0, r3
   164ac: e24bd004     	sub	sp, r11, #4
   164b0: e8bd8800     	pop	{r11, pc}
   164b4: f0 2a 03 00  	.word	0x00032af0
   164b8: b4 2a 03 00  	.word	0x00032ab4
   164bc: 04 2b 03 00  	.word	0x00032b04

