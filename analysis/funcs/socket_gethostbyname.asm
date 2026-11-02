00013474 <socket_gethostbyname>:
   13474: e92d4800     	push	{r11, lr}
   13478: e28db004     	add	r11, sp, #4
   1347c: e24dd008     	sub	sp, sp, #8
   13480: e50b0008     	str	r0, [r11, #-0x8]
   13484: e50b100c     	str	r1, [r11, #-0xc]
   13488: e51b0008     	ldr	r0, [r11, #-0x8]
   1348c: ebffe4ba     	bl	0xc77c <gethostbyname@plt> @ imm = #-0x6d18
   13490: e1a02000     	mov	r2, r0
   13494: e51b300c     	ldr	r3, [r11, #-0xc]
   13498: e5832000     	str	r2, [r3]
   1349c: e51b300c     	ldr	r3, [r11, #-0xc]
   134a0: e5933000     	ldr	r3, [r3]
   134a4: e3530000     	cmp	r3, #0
   134a8: 0a000001     	beq	0x134b4 <socket_gethostbyname+0x40> @ imm = #0x4
   134ac: e3a03000     	mov	r3, #0
   134b0: ea000012     	b	0x13500 <socket_gethostbyname+0x8c> @ imm = #0x48
   134b4: ebffe41a     	bl	0xc524 <__h_errno_location@plt> @ imm = #-0x6f98
   134b8: e1a03000     	mov	r3, r0
   134bc: e5933000     	ldr	r3, [r3]
   134c0: e3530000     	cmp	r3, #0
   134c4: 0a000003     	beq	0x134d8 <socket_gethostbyname+0x64> @ imm = #0xc
   134c8: ebffe415     	bl	0xc524 <__h_errno_location@plt> @ imm = #-0x6fac
   134cc: e1a03000     	mov	r3, r0
   134d0: e5933000     	ldr	r3, [r3]
   134d4: ea000009     	b	0x13500 <socket_gethostbyname+0x8c> @ imm = #0x24
   134d8: ebffe4bf     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x6d04
   134dc: e1a03000     	mov	r3, r0
   134e0: e5933000     	ldr	r3, [r3]
   134e4: e3530000     	cmp	r3, #0
   134e8: 0a000003     	beq	0x134fc <socket_gethostbyname+0x88> @ imm = #0xc
   134ec: ebffe4ba     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x6d18
   134f0: e1a03000     	mov	r3, r0
   134f4: e5933000     	ldr	r3, [r3]
   134f8: ea000000     	b	0x13500 <socket_gethostbyname+0x8c> @ imm = #0x0
   134fc: e3e03002     	mvn	r3, #2
   13500: e1a00003     	mov	r0, r3
   13504: e24bd004     	sub	sp, r11, #4
   13508: e8bd8800     	pop	{r11, pc}

