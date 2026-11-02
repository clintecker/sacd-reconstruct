000162f4 <buffer_pool_drop_space>:
   162f4: e92d4800     	push	{r11, lr}
   162f8: e28db004     	add	r11, sp, #4
   162fc: e24dd010     	sub	sp, sp, #16
   16300: e50b0010     	str	r0, [r11, #-0x10]
   16304: e51b3010     	ldr	r3, [r11, #-0x10]
   16308: e5933000     	ldr	r3, [r3]
   1630c: e1a00003     	mov	r0, r3
   16310: ebfffd26     	bl	0x157b0 <possess>       @ imm = #-0xb68
   16314: e51b3010     	ldr	r3, [r11, #-0x10]
   16318: e5933000     	ldr	r3, [r3]
   1631c: e1a00003     	mov	r0, r3
   16320: ebfffdc8     	bl	0x15a48 <peek_lock>     @ imm = #-0x8e0
   16324: e1a03000     	mov	r3, r0
   16328: e50b300c     	str	r3, [r11, #-0xc]
   1632c: e51b300c     	ldr	r3, [r11, #-0xc]
   16330: e3530000     	cmp	r3, #0
   16334: 1a000004     	bne	0x1634c <buffer_pool_drop_space+0x58> @ imm = #0x10
   16338: e59f0088     	ldr	r0, [pc, #0x88]         @ 0x163c8 <buffer_pool_drop_space+0xd4>
   1633c: e59f1088     	ldr	r1, [pc, #0x88]         @ 0x163cc <buffer_pool_drop_space+0xd8>
   16340: e3a02067     	mov	r2, #103
   16344: e59f3084     	ldr	r3, [pc, #0x84]         @ 0x163d0 <buffer_pool_drop_space+0xdc>
   16348: ebffd824     	bl	0xc3e0 <__assert_fail@plt> @ imm = #-0x9f70
   1634c: e51b300c     	ldr	r3, [r11, #-0xc]
   16350: e3530001     	cmp	r3, #1
   16354: 1a000013     	bne	0x163a8 <buffer_pool_drop_space+0xb4> @ imm = #0x4c
   16358: e51b3010     	ldr	r3, [r11, #-0x10]
   1635c: e593300c     	ldr	r3, [r3, #0xc]
   16360: e50b3008     	str	r3, [r11, #-0x8]
   16364: e51b3008     	ldr	r3, [r11, #-0x8]
   16368: e5933000     	ldr	r3, [r3]
   1636c: e1a00003     	mov	r0, r3
   16370: ebfffd0e     	bl	0x157b0 <possess>       @ imm = #-0xbc8
   16374: e51b3008     	ldr	r3, [r11, #-0x8]
   16378: e5932004     	ldr	r2, [r3, #0x4]
   1637c: e51b3010     	ldr	r3, [r11, #-0x10]
   16380: e5832010     	str	r2, [r3, #0x10]
   16384: e51b3008     	ldr	r3, [r11, #-0x8]
   16388: e51b2010     	ldr	r2, [r11, #-0x10]
   1638c: e5832004     	str	r2, [r3, #0x4]
   16390: e51b3008     	ldr	r3, [r11, #-0x8]
   16394: e5933000     	ldr	r3, [r3]
   16398: e1a00003     	mov	r0, r3
   1639c: e3a01001     	mov	r1, #1
   163a0: e3a02001     	mov	r2, #1
   163a4: ebfffd21     	bl	0x15830 <twist>         @ imm = #-0xb7c
   163a8: e51b3010     	ldr	r3, [r11, #-0x10]
   163ac: e5933000     	ldr	r3, [r3]
   163b0: e1a00003     	mov	r0, r3
   163b4: e3a01001     	mov	r1, #1
   163b8: e3e02000     	mvn	r2, #0
   163bc: ebfffd1b     	bl	0x15830 <twist>         @ imm = #-0xb94
   163c0: e24bd004     	sub	sp, r11, #4
   163c4: e8bd8800     	pop	{r11, pc}
   163c8: e4 2a 03 00  	.word	0x00032ae4
   163cc: b4 2a 03 00  	.word	0x00032ab4
   163d0: 18 2b 03 00  	.word	0x00032b18

