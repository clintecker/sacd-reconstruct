000160f0 <buffer_pool_get_space>:
   160f0: e92d4800     	push	{r11, lr}
   160f4: e28db004     	add	r11, sp, #4
   160f8: e24dd010     	sub	sp, sp, #16
   160fc: e50b0010     	str	r0, [r11, #-0x10]
   16100: e51b3010     	ldr	r3, [r11, #-0x10]
   16104: e5933000     	ldr	r3, [r3]
   16108: e1a00003     	mov	r0, r3
   1610c: ebfffda7     	bl	0x157b0 <possess>       @ imm = #-0x964
   16110: e51b3010     	ldr	r3, [r11, #-0x10]
   16114: e593300c     	ldr	r3, [r3, #0xc]
   16118: e3530000     	cmp	r3, #0
   1611c: 1a000005     	bne	0x16138 <buffer_pool_get_space+0x48> @ imm = #0x14
   16120: e51b3010     	ldr	r3, [r11, #-0x10]
   16124: e5933000     	ldr	r3, [r3]
   16128: e1a00003     	mov	r0, r3
   1612c: e3a01001     	mov	r1, #1
   16130: e3a02000     	mov	r2, #0
   16134: ebfffde8     	bl	0x158dc <wait_for>      @ imm = #-0x860
   16138: e51b3010     	ldr	r3, [r11, #-0x10]
   1613c: e5933004     	ldr	r3, [r3, #0x4]
   16140: e3530000     	cmp	r3, #0
   16144: 0a000018     	beq	0x161ac <buffer_pool_get_space+0xbc> @ imm = #0x60
   16148: e51b3010     	ldr	r3, [r11, #-0x10]
   1614c: e5933004     	ldr	r3, [r3, #0x4]
   16150: e50b3008     	str	r3, [r11, #-0x8]
   16154: e51b3008     	ldr	r3, [r11, #-0x8]
   16158: e5933000     	ldr	r3, [r3]
   1615c: e1a00003     	mov	r0, r3
   16160: ebfffd92     	bl	0x157b0 <possess>       @ imm = #-0x9b8
   16164: e51b3008     	ldr	r3, [r11, #-0x8]
   16168: e5932010     	ldr	r2, [r3, #0x10]
   1616c: e51b3010     	ldr	r3, [r11, #-0x10]
   16170: e5832004     	str	r2, [r3, #0x4]
   16174: e51b3010     	ldr	r3, [r11, #-0x10]
   16178: e5933000     	ldr	r3, [r3]
   1617c: e1a00003     	mov	r0, r3
   16180: e3a01001     	mov	r1, #1
   16184: e3e02000     	mvn	r2, #0
   16188: ebfffda8     	bl	0x15830 <twist>         @ imm = #-0x960
   1618c: e51b3008     	ldr	r3, [r11, #-0x8]
   16190: e5933000     	ldr	r3, [r3]
   16194: e1a00003     	mov	r0, r3
   16198: e3a01000     	mov	r1, #0
   1619c: e3a02001     	mov	r2, #1
   161a0: ebfffda2     	bl	0x15830 <twist>         @ imm = #-0x978
   161a4: e51b3008     	ldr	r3, [r11, #-0x8]
   161a8: ea00003b     	b	0x1629c <buffer_pool_get_space+0x1ac> @ imm = #0xec
   161ac: e51b3010     	ldr	r3, [r11, #-0x10]
   161b0: e593300c     	ldr	r3, [r3, #0xc]
   161b4: e3530000     	cmp	r3, #0
   161b8: 1a000004     	bne	0x161d0 <buffer_pool_get_space+0xe0> @ imm = #0x10
   161bc: e59f00e4     	ldr	r0, [pc, #0xe4]         @ 0x162a8 <buffer_pool_get_space+0x1b8>
   161c0: e59f10e4     	ldr	r1, [pc, #0xe4]         @ 0x162ac <buffer_pool_get_space+0x1bc>
   161c4: e3a02041     	mov	r2, #65
   161c8: e59f30e0     	ldr	r3, [pc, #0xe0]         @ 0x162b0 <buffer_pool_get_space+0x1c0>
   161cc: ebffd883     	bl	0xc3e0 <__assert_fail@plt> @ imm = #-0x9df4
   161d0: e51b3010     	ldr	r3, [r11, #-0x10]
   161d4: e593300c     	ldr	r3, [r3, #0xc]
   161d8: e3530000     	cmp	r3, #0
   161dc: da000004     	ble	0x161f4 <buffer_pool_get_space+0x104> @ imm = #0x10
   161e0: e51b3010     	ldr	r3, [r11, #-0x10]
   161e4: e593300c     	ldr	r3, [r3, #0xc]
   161e8: e2432001     	sub	r2, r3, #1
   161ec: e51b3010     	ldr	r3, [r11, #-0x10]
   161f0: e583200c     	str	r2, [r3, #0xc]
   161f4: e51b3010     	ldr	r3, [r11, #-0x10]
   161f8: e5933010     	ldr	r3, [r3, #0x10]
   161fc: e2832001     	add	r2, r3, #1
   16200: e51b3010     	ldr	r3, [r11, #-0x10]
   16204: e5832010     	str	r2, [r3, #0x10]
   16208: e51b3010     	ldr	r3, [r11, #-0x10]
   1620c: e5933000     	ldr	r3, [r3]
   16210: e1a00003     	mov	r0, r3
   16214: ebfffd75     	bl	0x157f0 <release>       @ imm = #-0xa2c
   16218: e3a00014     	mov	r0, #20
   1621c: ebffd911     	bl	0xc668 <malloc@plt>     @ imm = #-0x9bbc
   16220: e1a03000     	mov	r3, r0
   16224: e50b3008     	str	r3, [r11, #-0x8]
   16228: e51b3008     	ldr	r3, [r11, #-0x8]
   1622c: e3530000     	cmp	r3, #0
   16230: 1a000001     	bne	0x1623c <buffer_pool_get_space+0x14c> @ imm = #0x4
   16234: e3a03000     	mov	r3, #0
   16238: ea000017     	b	0x1629c <buffer_pool_get_space+0x1ac> @ imm = #0x5c
   1623c: e3a00001     	mov	r0, #1
   16240: ebfffd36     	bl	0x15720 <new_lock>      @ imm = #-0xb28
   16244: e1a02000     	mov	r2, r0
   16248: e51b3008     	ldr	r3, [r11, #-0x8]
   1624c: e5832000     	str	r2, [r3]
   16250: e51b3010     	ldr	r3, [r11, #-0x10]
   16254: e5933008     	ldr	r3, [r3, #0x8]
   16258: e3a00040     	mov	r0, #64
   1625c: e1a01003     	mov	r1, r3
   16260: ebffd840     	bl	0xc368 <memalign@plt>   @ imm = #-0x9f00
   16264: e1a03000     	mov	r3, r0
   16268: e1a02003     	mov	r2, r3
   1626c: e51b3008     	ldr	r3, [r11, #-0x8]
   16270: e5832004     	str	r2, [r3, #0x4]
   16274: e51b3008     	ldr	r3, [r11, #-0x8]
   16278: e5933004     	ldr	r3, [r3, #0x4]
   1627c: e3530000     	cmp	r3, #0
   16280: 1a000001     	bne	0x1628c <buffer_pool_get_space+0x19c> @ imm = #0x4
   16284: e3a03000     	mov	r3, #0
   16288: ea000003     	b	0x1629c <buffer_pool_get_space+0x1ac> @ imm = #0xc
   1628c: e51b3008     	ldr	r3, [r11, #-0x8]
   16290: e51b2010     	ldr	r2, [r11, #-0x10]
   16294: e583200c     	str	r2, [r3, #0xc]
   16298: e51b3008     	ldr	r3, [r11, #-0x8]
   1629c: e1a00003     	mov	r0, r3
   162a0: e24bd004     	sub	sp, r11, #4
   162a4: e8bd8800     	pop	{r11, pc}
   162a8: a0 2a 03 00  	.word	0x00032aa0
   162ac: b4 2a 03 00  	.word	0x00032ab4
   162b0: 30 2b 03 00  	.word	0x00032b30

