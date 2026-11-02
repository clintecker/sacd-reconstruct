000136e8 <inet_trycreate>:
   136e8: e92d4800     	push	{r11, lr}
   136ec: e28db004     	add	r11, sp, #4
   136f0: e24dd008     	sub	sp, sp, #8
   136f4: e50b0008     	str	r0, [r11, #-0x8]
   136f8: e50b100c     	str	r1, [r11, #-0xc]
   136fc: e51b0008     	ldr	r0, [r11, #-0x8]
   13700: e3a01002     	mov	r1, #2
   13704: e51b200c     	ldr	r2, [r11, #-0xc]
   13708: e3a03000     	mov	r3, #0
   1370c: ebfffce3     	bl	0x12aa0 <socket_create> @ imm = #-0xc74
   13710: e1a03000     	mov	r3, r0
   13714: e1a00003     	mov	r0, r3
   13718: ebffff92     	bl	0x13568 <socket_strerror> @ imm = #-0x1b8
   1371c: e1a03000     	mov	r3, r0
   13720: e1a00003     	mov	r0, r3
   13724: e24bd004     	sub	sp, r11, #4
   13728: e8bd8800     	pop	{r11, pc}

