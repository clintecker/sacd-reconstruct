00013868 <inet_trybind>:
   13868: e92d4800     	push	{r11, lr}
   1386c: e28db004     	add	r11, sp, #4
   13870: e24dd030     	sub	sp, sp, #48
   13874: e50b0028     	str	r0, [r11, #-0x28]
   13878: e50b102c     	str	r1, [r11, #-0x2c]
   1387c: e1a03002     	mov	r3, r2
   13880: e14b32be     	strh	r3, [r11, #-46]
   13884: e24b301c     	sub	r3, r11, #28
   13888: e1a00003     	mov	r0, r3
   1388c: e3a01000     	mov	r1, #0
   13890: e3a02010     	mov	r2, #16
   13894: ebffe2c2     	bl	0xc3a4 <memset@plt>     @ imm = #-0x74f8
   13898: e3a00000     	mov	r0, #0
   1389c: ebffe39b     	bl	0xc710 <htonl@plt>      @ imm = #-0x7194
   138a0: e1a03000     	mov	r3, r0
   138a4: e50b3018     	str	r3, [r11, #-0x18]
   138a8: e15b32be     	ldrh	r3, [r11, #-46]
   138ac: e1a00003     	mov	r0, r3
   138b0: ebffe2b8     	bl	0xc398 <htons@plt>      @ imm = #-0x7520
   138b4: e1a03000     	mov	r3, r0
   138b8: e14b31ba     	strh	r3, [r11, #-26]
   138bc: e3a03002     	mov	r3, #2
   138c0: e14b31bc     	strh	r3, [r11, #-28]
   138c4: e51b002c     	ldr	r0, [r11, #-0x2c]
   138c8: e59f10dc     	ldr	r1, [pc, #0xdc]         @ 0x139ac <inet_trybind+0x144>
   138cc: ebffe3b9     	bl	0xc7b8 <strcmp@plt>     @ imm = #-0x711c
   138d0: e1a03000     	mov	r3, r0
   138d4: e3530000     	cmp	r3, #0
   138d8: 0a000021     	beq	0x13964 <inet_trybind+0xfc> @ imm = #0x84
   138dc: e24b301c     	sub	r3, r11, #28
   138e0: e2833004     	add	r3, r3, #4
   138e4: e51b002c     	ldr	r0, [r11, #-0x2c]
   138e8: e1a01003     	mov	r1, r3
   138ec: ebffe2eb     	bl	0xc4a0 <inet_aton@plt>  @ imm = #-0x7454
   138f0: e1a03000     	mov	r3, r0
   138f4: e3530000     	cmp	r3, #0
   138f8: 1a000019     	bne	0x13964 <inet_trybind+0xfc> @ imm = #0x64
   138fc: e3a03000     	mov	r3, #0
   13900: e50b3020     	str	r3, [r11, #-0x20]
   13904: e24b3020     	sub	r3, r11, #32
   13908: e51b002c     	ldr	r0, [r11, #-0x2c]
   1390c: e1a01003     	mov	r1, r3
   13910: ebfffed7     	bl	0x13474 <socket_gethostbyname> @ imm = #-0x4a4
   13914: e1a03000     	mov	r3, r0
   13918: e50b300c     	str	r3, [r11, #-0xc]
   1391c: e51b300c     	ldr	r3, [r11, #-0xc]
   13920: e3530000     	cmp	r3, #0
   13924: 0a000003     	beq	0x13938 <inet_trybind+0xd0> @ imm = #0xc
   13928: e51b000c     	ldr	r0, [r11, #-0xc]
   1392c: ebfffef6     	bl	0x1350c <socket_hoststrerror> @ imm = #-0x428
   13930: e1a03000     	mov	r3, r0
   13934: ea000019     	b	0x139a0 <inet_trybind+0x138> @ imm = #0x64
   13938: e51b3020     	ldr	r3, [r11, #-0x20]
   1393c: e5933010     	ldr	r3, [r3, #0x10]
   13940: e50b3008     	str	r3, [r11, #-0x8]
   13944: e51b3008     	ldr	r3, [r11, #-0x8]
   13948: e5933000     	ldr	r3, [r3]
   1394c: e24b201c     	sub	r2, r11, #28
   13950: e2822004     	add	r2, r2, #4
   13954: e1a00002     	mov	r0, r2
   13958: e1a01003     	mov	r1, r3
   1395c: e3a02004     	mov	r2, #4
   13960: ebffe2e9     	bl	0xc50c <memcpy@plt>     @ imm = #-0x745c
   13964: e24b301c     	sub	r3, r11, #28
   13968: e51b0028     	ldr	r0, [r11, #-0x28]
   1396c: e1a01003     	mov	r1, r3
   13970: e3a02010     	mov	r2, #16
   13974: ebfffc63     	bl	0x12b08 <socket_bind>   @ imm = #-0xe74
   13978: e1a03000     	mov	r3, r0
   1397c: e50b300c     	str	r3, [r11, #-0xc]
   13980: e51b300c     	ldr	r3, [r11, #-0xc]
   13984: e3530000     	cmp	r3, #0
   13988: 0a000001     	beq	0x13994 <inet_trybind+0x12c> @ imm = #0x4
   1398c: e51b0028     	ldr	r0, [r11, #-0x28]
   13990: ebfffbe2     	bl	0x12920 <socket_destroy> @ imm = #-0x1078
   13994: e51b000c     	ldr	r0, [r11, #-0xc]
   13998: ebfffef2     	bl	0x13568 <socket_strerror> @ imm = #-0x438
   1399c: e1a03000     	mov	r3, r0
   139a0: e1a00003     	mov	r0, r3
   139a4: e24bd004     	sub	sp, r11, #4
   139a8: e8bd8800     	pop	{r11, pc}
   139ac: d0 28 03 00  	.word	0x000328d0

