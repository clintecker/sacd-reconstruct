000133d0 <socket_gethostbyaddr>:
   133d0: e92d4800     	push	{r11, lr}
   133d4: e28db004     	add	r11, sp, #4
   133d8: e24dd010     	sub	sp, sp, #16
   133dc: e50b0008     	str	r0, [r11, #-0x8]
   133e0: e50b100c     	str	r1, [r11, #-0xc]
   133e4: e50b2010     	str	r2, [r11, #-0x10]
   133e8: e51b0008     	ldr	r0, [r11, #-0x8]
   133ec: e51b100c     	ldr	r1, [r11, #-0xc]
   133f0: e3a02002     	mov	r2, #2
   133f4: ebffe468     	bl	0xc59c <gethostbyaddr@plt> @ imm = #-0x6e60
   133f8: e1a02000     	mov	r2, r0
   133fc: e51b3010     	ldr	r3, [r11, #-0x10]
   13400: e5832000     	str	r2, [r3]
   13404: e51b3010     	ldr	r3, [r11, #-0x10]
   13408: e5933000     	ldr	r3, [r3]
   1340c: e3530000     	cmp	r3, #0
   13410: 0a000001     	beq	0x1341c <socket_gethostbyaddr+0x4c> @ imm = #0x4
   13414: e3a03000     	mov	r3, #0
   13418: ea000012     	b	0x13468 <socket_gethostbyaddr+0x98> @ imm = #0x48
   1341c: ebffe440     	bl	0xc524 <__h_errno_location@plt> @ imm = #-0x6f00
   13420: e1a03000     	mov	r3, r0
   13424: e5933000     	ldr	r3, [r3]
   13428: e3530000     	cmp	r3, #0
   1342c: 0a000003     	beq	0x13440 <socket_gethostbyaddr+0x70> @ imm = #0xc
   13430: ebffe43b     	bl	0xc524 <__h_errno_location@plt> @ imm = #-0x6f14
   13434: e1a03000     	mov	r3, r0
   13438: e5933000     	ldr	r3, [r3]
   1343c: ea000009     	b	0x13468 <socket_gethostbyaddr+0x98> @ imm = #0x24
   13440: ebffe4e5     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x6c6c
   13444: e1a03000     	mov	r3, r0
   13448: e5933000     	ldr	r3, [r3]
   1344c: e3530000     	cmp	r3, #0
   13450: 0a000003     	beq	0x13464 <socket_gethostbyaddr+0x94> @ imm = #0xc
   13454: ebffe4e0     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x6c80
   13458: e1a03000     	mov	r3, r0
   1345c: e5933000     	ldr	r3, [r3]
   13460: ea000000     	b	0x13468 <socket_gethostbyaddr+0x98> @ imm = #0x0
   13464: e3e03002     	mvn	r3, #2
   13468: e1a00003     	mov	r0, r3
   1346c: e24bd004     	sub	sp, r11, #4
   13470: e8bd8800     	pop	{r11, pc}

