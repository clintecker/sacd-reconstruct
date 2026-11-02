00014938 <set_log_module_level>:
   14938: e92d4800     	push	{r11, lr}
   1493c: e28db004     	add	r11, sp, #4
   14940: e24dd068     	sub	sp, sp, #104
   14944: e50b0060     	str	r0, [r11, #-0x60]
   14948: e59f0174     	ldr	r0, [pc, #0x174]        @ 0x14ac4 <set_log_module_level+0x18c>
   1494c: ebffde6d     	bl	0xc308 <getenv@plt>     @ imm = #-0x864c
   14950: e1a03000     	mov	r3, r0
   14954: e50b3014     	str	r3, [r11, #-0x14]
   14958: e51b3014     	ldr	r3, [r11, #-0x14]
   1495c: e3530000     	cmp	r3, #0
   14960: 0a000055     	beq	0x14abc <set_log_module_level+0x184> @ imm = #0x154
   14964: e51b3014     	ldr	r3, [r11, #-0x14]
   14968: e5d33000     	ldrb	r3, [r3]
   1496c: e3530000     	cmp	r3, #0
   14970: 0a000051     	beq	0x14abc <set_log_module_level+0x184> @ imm = #0x144
   14974: e51b0014     	ldr	r0, [r11, #-0x14]
   14978: ebffded7     	bl	0xc4dc <strlen@plt>     @ imm = #-0x84a4
   1497c: e1a03000     	mov	r3, r0
   14980: e50b3010     	str	r3, [r11, #-0x10]
   14984: e3a03000     	mov	r3, #0
   14988: e50b300c     	str	r3, [r11, #-0xc]
   1498c: ea000042     	b	0x14a9c <set_log_module_level+0x164> @ imm = #0x108
   14990: e3a03001     	mov	r3, #1
   14994: e50b3018     	str	r3, [r11, #-0x18]
   14998: e3a03000     	mov	r3, #0
   1499c: e50b3008     	str	r3, [r11, #-0x8]
   149a0: e3a03000     	mov	r3, #0
   149a4: e50b301c     	str	r3, [r11, #-0x1c]
   149a8: e51b2014     	ldr	r2, [r11, #-0x14]
   149ac: e51b300c     	ldr	r3, [r11, #-0xc]
   149b0: e0820003     	add	r0, r2, r3
   149b4: e59f110c     	ldr	r1, [pc, #0x10c]        @ 0x14ac8 <set_log_module_level+0x190>
   149b8: e24b205c     	sub	r2, r11, #92
   149bc: e24b301c     	sub	r3, r11, #28
   149c0: e24bc018     	sub	r12, r11, #24
   149c4: e58dc000     	str	r12, [sp]
   149c8: e24bc01c     	sub	r12, r11, #28
   149cc: e58dc004     	str	r12, [sp, #0x4]
   149d0: ebffdec4     	bl	0xc4e8 <sscanf@plt>     @ imm = #-0x84f0
   149d4: e1a03000     	mov	r3, r0
   149d8: e50b3008     	str	r3, [r11, #-0x8]
   149dc: e51b301c     	ldr	r3, [r11, #-0x1c]
   149e0: e51b200c     	ldr	r2, [r11, #-0xc]
   149e4: e0823003     	add	r3, r2, r3
   149e8: e50b300c     	str	r3, [r11, #-0xc]
   149ec: e51b3008     	ldr	r3, [r11, #-0x8]
   149f0: e3530000     	cmp	r3, #0
   149f4: 0a00002d     	beq	0x14ab0 <set_log_module_level+0x178> @ imm = #0xb4
   149f8: e51b3060     	ldr	r3, [r11, #-0x60]
   149fc: e3530000     	cmp	r3, #0
   14a00: 0a000013     	beq	0x14a54 <set_log_module_level+0x11c> @ imm = #0x4c
   14a04: e24b305c     	sub	r3, r11, #92
   14a08: e1a00003     	mov	r0, r3
   14a0c: e59f10b8     	ldr	r1, [pc, #0xb8]         @ 0x14acc <set_log_module_level+0x194>
   14a10: ebffde4b     	bl	0xc344 <strcasecmp@plt> @ imm = #-0x86d4
   14a14: e1a03000     	mov	r3, r0
   14a18: e3530000     	cmp	r3, #0
   14a1c: 0a000008     	beq	0x14a44 <set_log_module_level+0x10c> @ imm = #0x20
   14a20: e51b3060     	ldr	r3, [r11, #-0x60]
   14a24: e5933000     	ldr	r3, [r3]
   14a28: e24b205c     	sub	r2, r11, #92
   14a2c: e1a00002     	mov	r0, r2
   14a30: e1a01003     	mov	r1, r3
   14a34: ebffde42     	bl	0xc344 <strcasecmp@plt> @ imm = #-0x86f8
   14a38: e1a03000     	mov	r3, r0
   14a3c: e3530000     	cmp	r3, #0
   14a40: 1a000003     	bne	0x14a54 <set_log_module_level+0x11c> @ imm = #0xc
   14a44: e51b3018     	ldr	r3, [r11, #-0x18]
   14a48: e1a02003     	mov	r2, r3
   14a4c: e51b3060     	ldr	r3, [r11, #-0x60]
   14a50: e5832004     	str	r2, [r3, #0x4]
   14a54: e51b2014     	ldr	r2, [r11, #-0x14]
   14a58: e51b300c     	ldr	r3, [r11, #-0xc]
   14a5c: e0821003     	add	r1, r2, r3
   14a60: e59f2068     	ldr	r2, [pc, #0x68]         @ 0x14ad0 <set_log_module_level+0x198>
   14a64: e24b301c     	sub	r3, r11, #28
   14a68: e1a00001     	mov	r0, r1
   14a6c: e1a01002     	mov	r1, r2
   14a70: e1a02003     	mov	r2, r3
   14a74: ebffde9b     	bl	0xc4e8 <sscanf@plt>     @ imm = #-0x8594
   14a78: e1a03000     	mov	r3, r0
   14a7c: e50b3008     	str	r3, [r11, #-0x8]
   14a80: e51b301c     	ldr	r3, [r11, #-0x1c]
   14a84: e51b200c     	ldr	r2, [r11, #-0xc]
   14a88: e0823003     	add	r3, r2, r3
   14a8c: e50b300c     	str	r3, [r11, #-0xc]
   14a90: e51b3008     	ldr	r3, [r11, #-0x8]
   14a94: e3730001     	cmn	r3, #1
   14a98: 0a000006     	beq	0x14ab8 <set_log_module_level+0x180> @ imm = #0x18
   14a9c: e51b200c     	ldr	r2, [r11, #-0xc]
   14aa0: e51b3010     	ldr	r3, [r11, #-0x10]
   14aa4: e1520003     	cmp	r2, r3
   14aa8: baffffb8     	blt	0x14990 <set_log_module_level+0x58> @ imm = #-0x120
   14aac: ea000002     	b	0x14abc <set_log_module_level+0x184> @ imm = #0x8
   14ab0: e1a00000     	mov	r0, r0
   14ab4: ea000000     	b	0x14abc <set_log_module_level+0x184> @ imm = #0x0
   14ab8: e1a00000     	mov	r0, r0
   14abc: e24bd004     	sub	sp, r11, #4
   14ac0: e8bd8800     	pop	{r11, pc}
   14ac4: 28 29 03 00  	.word	0x00032928
   14ac8: 34 29 03 00  	.word	0x00032934
   14acc: a0 29 03 00  	.word	0x000329a0
   14ad0: a4 29 03 00  	.word	0x000329a4

