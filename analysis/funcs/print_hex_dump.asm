000143d8 <print_hex_dump>:
   143d8: e92d4800     	push	{r11, lr}
   143dc: e28db004     	add	r11, sp, #4
   143e0: e24dd0b8     	sub	sp, sp, #184
   143e4: e50b00a0     	str	r0, [r11, #-0xa0]
   143e8: e50b10a4     	str	r1, [r11, #-0xa4]
   143ec: e50b20a8     	str	r2, [r11, #-0xa8]
   143f0: e50b30ac     	str	r3, [r11, #-0xac]
   143f4: e59b3004     	ldr	r3, [r11, #0x4]
   143f8: e50b3014     	str	r3, [r11, #-0x14]
   143fc: e59b3008     	ldr	r3, [r11, #0x8]
   14400: e50b3008     	str	r3, [r11, #-0x8]
   14404: e51b30a8     	ldr	r3, [r11, #-0xa8]
   14408: e3530010     	cmp	r3, #16
   1440c: 0a000004     	beq	0x14424 <print_hex_dump+0x4c> @ imm = #0x10
   14410: e51b30a8     	ldr	r3, [r11, #-0xa8]
   14414: e3530020     	cmp	r3, #32
   14418: 0a000001     	beq	0x14424 <print_hex_dump+0x4c> @ imm = #0x4
   1441c: e3a03010     	mov	r3, #16
   14420: e50b30a8     	str	r3, [r11, #-0xa8]
   14424: e3a03000     	mov	r3, #0
   14428: e50b3010     	str	r3, [r11, #-0x10]
   1442c: ea000026     	b	0x144cc <print_hex_dump+0xf4> @ imm = #0x98
   14430: e51b20a8     	ldr	r2, [r11, #-0xa8]
   14434: e51b3008     	ldr	r3, [r11, #-0x8]
   14438: e1520003     	cmp	r2, r3
   1443c: b1a03002     	movlt	r3, r2
   14440: a1a03003     	movge	r3, r3
   14444: e50b300c     	str	r3, [r11, #-0xc]
   14448: e51b2008     	ldr	r2, [r11, #-0x8]
   1444c: e51b30a8     	ldr	r3, [r11, #-0xa8]
   14450: e0633002     	rsb	r3, r3, r2
   14454: e50b3008     	str	r3, [r11, #-0x8]
   14458: e51b3010     	ldr	r3, [r11, #-0x10]
   1445c: e51b2014     	ldr	r2, [r11, #-0x14]
   14460: e0823003     	add	r3, r2, r3
   14464: e24b2098     	sub	r2, r11, #152
   14468: e58d2000     	str	r2, [sp]
   1446c: e3a02083     	mov	r2, #131
   14470: e58d2004     	str	r2, [sp, #0x4]
   14474: e59b200c     	ldr	r2, [r11, #0xc]
   14478: e58d2008     	str	r2, [sp, #0x8]
   1447c: e1a00003     	mov	r0, r3
   14480: e51b100c     	ldr	r1, [r11, #-0xc]
   14484: e51b20a8     	ldr	r2, [r11, #-0xa8]
   14488: e51b30ac     	ldr	r3, [r11, #-0xac]
   1448c: ebfffe7a     	bl	0x13e7c <hex_dump_to_buffer> @ imm = #-0x618
   14490: e59f304c     	ldr	r3, [pc, #0x4c]         @ 0x144e4 <print_hex_dump+0x10c>
   14494: e5933000     	ldr	r3, [r3]
   14498: e5932004     	ldr	r2, [r3, #0x4]
   1449c: e51b30a0     	ldr	r3, [r11, #-0xa0]
   144a0: e1520003     	cmp	r2, r3
   144a4: 3a000004     	blo	0x144bc <print_hex_dump+0xe4> @ imm = #0x10
   144a8: e24b3098     	sub	r3, r11, #152
   144ac: e59f0034     	ldr	r0, [pc, #0x34]         @ 0x144e8 <print_hex_dump+0x110>
   144b0: e51b10a4     	ldr	r1, [r11, #-0xa4]
   144b4: e1a02003     	mov	r2, r3
   144b8: eb0001fd     	bl	0x14cb4 <log_print>     @ imm = #0x7f4
   144bc: e51b2010     	ldr	r2, [r11, #-0x10]
   144c0: e51b30a8     	ldr	r3, [r11, #-0xa8]
   144c4: e0823003     	add	r3, r2, r3
   144c8: e50b3010     	str	r3, [r11, #-0x10]
   144cc: e51b2010     	ldr	r2, [r11, #-0x10]
   144d0: e59b3008     	ldr	r3, [r11, #0x8]
   144d4: e1520003     	cmp	r2, r3
   144d8: baffffd4     	blt	0x14430 <print_hex_dump+0x58> @ imm = #-0xb0
   144dc: e24bd004     	sub	sp, r11, #4
   144e0: e8bd8800     	pop	{r11, pc}
   144e4: 5c 73 05 00  	.word	0x0005735c
   144e8: 20 29 03 00  	.word	0x00032920

