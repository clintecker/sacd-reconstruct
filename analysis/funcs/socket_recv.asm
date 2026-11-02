000130f0 <socket_recv>:
   130f0: e92d4800     	push	{r11, lr}
   130f4: e28db004     	add	r11, sp, #4
   130f8: e24dd018     	sub	sp, sp, #24
   130fc: e50b0010     	str	r0, [r11, #-0x10]
   13100: e50b1014     	str	r1, [r11, #-0x14]
   13104: e50b2018     	str	r2, [r11, #-0x18]
   13108: e50b301c     	str	r3, [r11, #-0x1c]
   1310c: e51b301c     	ldr	r3, [r11, #-0x1c]
   13110: e3a02000     	mov	r2, #0
   13114: e5832000     	str	r2, [r3]
   13118: e51b3010     	ldr	r3, [r11, #-0x10]
   1311c: e5933000     	ldr	r3, [r3]
   13120: e3730001     	cmn	r3, #1
   13124: 1a000002     	bne	0x13134 <socket_recv+0x44> @ imm = #0x8
   13128: e3e03001     	mvn	r3, #1
   1312c: ea00002e     	b	0x131ec <socket_recv+0xfc> @ imm = #0xb8
   13130: e1a00000     	mov	r0, r0
   13134: e51b3010     	ldr	r3, [r11, #-0x10]
   13138: e5933000     	ldr	r3, [r3]
   1313c: e1a00003     	mov	r0, r3
   13140: e51b1014     	ldr	r1, [r11, #-0x14]
   13144: e51b2018     	ldr	r2, [r11, #-0x18]
   13148: e59b3004     	ldr	r3, [r11, #0x4]
   1314c: ebffe46a     	bl	0xc2fc <recv@plt>       @ imm = #-0x6e58
   13150: e1a03000     	mov	r3, r0
   13154: e50b3008     	str	r3, [r11, #-0x8]
   13158: e51b3008     	ldr	r3, [r11, #-0x8]
   1315c: e3530000     	cmp	r3, #0
   13160: da000004     	ble	0x13178 <socket_recv+0x88> @ imm = #0x10
   13164: e51b2008     	ldr	r2, [r11, #-0x8]
   13168: e51b301c     	ldr	r3, [r11, #-0x1c]
   1316c: e5832000     	str	r2, [r3]
   13170: e3a03000     	mov	r3, #0
   13174: ea00001c     	b	0x131ec <socket_recv+0xfc> @ imm = #0x70
   13178: ebffe597     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x69a4
   1317c: e1a03000     	mov	r3, r0
   13180: e5933000     	ldr	r3, [r3]
   13184: e50b300c     	str	r3, [r11, #-0xc]
   13188: e51b3008     	ldr	r3, [r11, #-0x8]
   1318c: e3530000     	cmp	r3, #0
   13190: 1a000001     	bne	0x1319c <socket_recv+0xac> @ imm = #0x4
   13194: e3e03001     	mvn	r3, #1
   13198: ea000013     	b	0x131ec <socket_recv+0xfc> @ imm = #0x4c
   1319c: e51b300c     	ldr	r3, [r11, #-0xc]
   131a0: e3530004     	cmp	r3, #4
   131a4: 1a000001     	bne	0x131b0 <socket_recv+0xc0> @ imm = #0x4
   131a8: e1a00000     	mov	r0, r0
   131ac: eaffffe0     	b	0x13134 <socket_recv+0x44> @ imm = #-0x80
   131b0: e51b300c     	ldr	r3, [r11, #-0xc]
   131b4: e353000b     	cmp	r3, #11
   131b8: 0a000001     	beq	0x131c4 <socket_recv+0xd4> @ imm = #0x4
   131bc: e51b300c     	ldr	r3, [r11, #-0xc]
   131c0: ea000009     	b	0x131ec <socket_recv+0xfc> @ imm = #0x24
   131c4: e51b0010     	ldr	r0, [r11, #-0x10]
   131c8: e3a01001     	mov	r1, #1
   131cc: e59b2008     	ldr	r2, [r11, #0x8]
   131d0: ebfffce6     	bl	0x12570 <socket_waitfd> @ imm = #-0xc68
   131d4: e1a03000     	mov	r3, r0
   131d8: e50b300c     	str	r3, [r11, #-0xc]
   131dc: e51b300c     	ldr	r3, [r11, #-0xc]
   131e0: e3530000     	cmp	r3, #0
   131e4: 0affffd1     	beq	0x13130 <socket_recv+0x40> @ imm = #-0xbc
   131e8: e51b300c     	ldr	r3, [r11, #-0xc]
   131ec: e1a00003     	mov	r0, r3
   131f0: e24bd004     	sub	sp, r11, #4
   131f4: e8bd8800     	pop	{r11, pc}

