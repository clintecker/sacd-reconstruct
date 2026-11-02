0001372c <inet_tryconnect>:
   1372c: e92d4800     	push	{r11, lr}
   13730: e28db004     	add	r11, sp, #4
   13734: e24dd030     	sub	sp, sp, #48
   13738: e50b0028     	str	r0, [r11, #-0x28]
   1373c: e50b102c     	str	r1, [r11, #-0x2c]
   13740: e50b3034     	str	r3, [r11, #-0x34]
   13744: e14b22be     	strh	r2, [r11, #-46]
   13748: e24b301c     	sub	r3, r11, #28
   1374c: e1a00003     	mov	r0, r3
   13750: e3a01000     	mov	r1, #0
   13754: e3a02010     	mov	r2, #16
   13758: ebffe311     	bl	0xc3a4 <memset@plt>     @ imm = #-0x73bc
   1375c: e3a03002     	mov	r3, #2
   13760: e14b31bc     	strh	r3, [r11, #-28]
   13764: e15b32be     	ldrh	r3, [r11, #-46]
   13768: e1a00003     	mov	r0, r3
   1376c: ebffe309     	bl	0xc398 <htons@plt>      @ imm = #-0x73dc
   13770: e1a03000     	mov	r3, r0
   13774: e14b31ba     	strh	r3, [r11, #-26]
   13778: e51b002c     	ldr	r0, [r11, #-0x2c]
   1377c: e59f10e0     	ldr	r1, [pc, #0xe0]         @ 0x13864 <inet_tryconnect+0x138>
   13780: ebffe40c     	bl	0xc7b8 <strcmp@plt>     @ imm = #-0x6fd0
   13784: e1a03000     	mov	r3, r0
   13788: e3530000     	cmp	r3, #0
   1378c: 0a000022     	beq	0x1381c <inet_tryconnect+0xf0> @ imm = #0x88
   13790: e24b301c     	sub	r3, r11, #28
   13794: e2833004     	add	r3, r3, #4
   13798: e51b002c     	ldr	r0, [r11, #-0x2c]
   1379c: e1a01003     	mov	r1, r3
   137a0: ebffe33e     	bl	0xc4a0 <inet_aton@plt>  @ imm = #-0x7308
   137a4: e1a03000     	mov	r3, r0
   137a8: e3530000     	cmp	r3, #0
   137ac: 1a00001d     	bne	0x13828 <inet_tryconnect+0xfc> @ imm = #0x74
   137b0: e3a03000     	mov	r3, #0
   137b4: e50b3020     	str	r3, [r11, #-0x20]
   137b8: e24b3020     	sub	r3, r11, #32
   137bc: e51b002c     	ldr	r0, [r11, #-0x2c]
   137c0: e1a01003     	mov	r1, r3
   137c4: ebffff2a     	bl	0x13474 <socket_gethostbyname> @ imm = #-0x358
   137c8: e1a03000     	mov	r3, r0
   137cc: e50b300c     	str	r3, [r11, #-0xc]
   137d0: e51b300c     	ldr	r3, [r11, #-0xc]
   137d4: e3530000     	cmp	r3, #0
   137d8: 0a000003     	beq	0x137ec <inet_tryconnect+0xc0> @ imm = #0xc
   137dc: e51b000c     	ldr	r0, [r11, #-0xc]
   137e0: ebffff49     	bl	0x1350c <socket_hoststrerror> @ imm = #-0x2dc
   137e4: e1a03000     	mov	r3, r0
   137e8: ea00001a     	b	0x13858 <inet_tryconnect+0x12c> @ imm = #0x68
   137ec: e51b3020     	ldr	r3, [r11, #-0x20]
   137f0: e5933010     	ldr	r3, [r3, #0x10]
   137f4: e50b3008     	str	r3, [r11, #-0x8]
   137f8: e51b3008     	ldr	r3, [r11, #-0x8]
   137fc: e5933000     	ldr	r3, [r3]
   13800: e24b201c     	sub	r2, r11, #28
   13804: e2822004     	add	r2, r2, #4
   13808: e1a00002     	mov	r0, r2
   1380c: e1a01003     	mov	r1, r3
   13810: e3a02004     	mov	r2, #4
   13814: ebffe33c     	bl	0xc50c <memcpy@plt>     @ imm = #-0x7310
   13818: ea000003     	b	0x1382c <inet_tryconnect+0x100> @ imm = #0xc
   1381c: e3a03000     	mov	r3, #0
   13820: e14b31bc     	strh	r3, [r11, #-28]
   13824: ea000000     	b	0x1382c <inet_tryconnect+0x100> @ imm = #0x0
   13828: e1a00000     	mov	r0, r0
   1382c: e24b301c     	sub	r3, r11, #28
   13830: e51b0028     	ldr	r0, [r11, #-0x28]
   13834: e1a01003     	mov	r1, r3
   13838: e3a02010     	mov	r2, #16
   1383c: e51b3034     	ldr	r3, [r11, #-0x34]
   13840: ebfffcfb     	bl	0x12c34 <socket_connect> @ imm = #-0xc14
   13844: e1a03000     	mov	r3, r0
   13848: e50b300c     	str	r3, [r11, #-0xc]
   1384c: e51b000c     	ldr	r0, [r11, #-0xc]
   13850: ebffff44     	bl	0x13568 <socket_strerror> @ imm = #-0x2f0
   13854: e1a03000     	mov	r3, r0
   13858: e1a00003     	mov	r0, r3
   1385c: e24bd004     	sub	sp, r11, #4
   13860: e8bd8800     	pop	{r11, pc}
   13864: d0 28 03 00  	.word	0x000328d0

