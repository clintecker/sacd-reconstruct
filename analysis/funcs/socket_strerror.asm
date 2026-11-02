00013568 <socket_strerror>:
   13568: e92d4800     	push	{r11, lr}
   1356c: e28db004     	add	r11, sp, #4
   13570: e24dd008     	sub	sp, sp, #8
   13574: e50b0008     	str	r0, [r11, #-0x8]
   13578: e51b3008     	ldr	r3, [r11, #-0x8]
   1357c: e3530000     	cmp	r3, #0
   13580: ca000003     	bgt	0x13594 <socket_strerror+0x2c> @ imm = #0xc
   13584: e51b0008     	ldr	r0, [r11, #-0x8]
   13588: eb00003c     	bl	0x13680 <io_strerror>   @ imm = #0xf0
   1358c: e1a03000     	mov	r3, r0
   13590: ea000026     	b	0x13630 <socket_strerror+0xc8> @ imm = #0x98
   13594: e51b3008     	ldr	r3, [r11, #-0x8]
   13598: e3530068     	cmp	r3, #104
   1359c: 0a000019     	beq	0x13608 <socket_strerror+0xa0> @ imm = #0x64
   135a0: e3530068     	cmp	r3, #104
   135a4: ca000006     	bgt	0x135c4 <socket_strerror+0x5c> @ imm = #0x18
   135a8: e3530062     	cmp	r3, #98
   135ac: 0a00000b     	beq	0x135e0 <socket_strerror+0x78> @ imm = #0x2c
   135b0: e3530067     	cmp	r3, #103
   135b4: 0a000011     	beq	0x13600 <socket_strerror+0x98> @ imm = #0x44
   135b8: e353000d     	cmp	r3, #13
   135bc: 0a00000b     	beq	0x135f0 <socket_strerror+0x88> @ imm = #0x2c
   135c0: ea000014     	b	0x13618 <socket_strerror+0xb0> @ imm = #0x50
   135c4: e353006e     	cmp	r3, #110
   135c8: 0a000010     	beq	0x13610 <socket_strerror+0xa8> @ imm = #0x40
   135cc: e353006f     	cmp	r3, #111
   135d0: 0a000008     	beq	0x135f8 <socket_strerror+0x90> @ imm = #0x20
   135d4: e353006a     	cmp	r3, #106
   135d8: 0a000002     	beq	0x135e8 <socket_strerror+0x80> @ imm = #0x8
   135dc: ea00000d     	b	0x13618 <socket_strerror+0xb0> @ imm = #0x34
   135e0: e59f3054     	ldr	r3, [pc, #0x54]         @ 0x1363c <socket_strerror+0xd4>
   135e4: ea000011     	b	0x13630 <socket_strerror+0xc8> @ imm = #0x44
   135e8: e59f3050     	ldr	r3, [pc, #0x50]         @ 0x13640 <socket_strerror+0xd8>
   135ec: ea00000f     	b	0x13630 <socket_strerror+0xc8> @ imm = #0x3c
   135f0: e59f304c     	ldr	r3, [pc, #0x4c]         @ 0x13644 <socket_strerror+0xdc>
   135f4: ea00000d     	b	0x13630 <socket_strerror+0xc8> @ imm = #0x34
   135f8: e59f3048     	ldr	r3, [pc, #0x48]         @ 0x13648 <socket_strerror+0xe0>
   135fc: ea00000b     	b	0x13630 <socket_strerror+0xc8> @ imm = #0x2c
   13600: e59f3044     	ldr	r3, [pc, #0x44]         @ 0x1364c <socket_strerror+0xe4>
   13604: ea000009     	b	0x13630 <socket_strerror+0xc8> @ imm = #0x24
   13608: e59f303c     	ldr	r3, [pc, #0x3c]         @ 0x1364c <socket_strerror+0xe4>
   1360c: ea000007     	b	0x13630 <socket_strerror+0xc8> @ imm = #0x1c
   13610: e59f3038     	ldr	r3, [pc, #0x38]         @ 0x13650 <socket_strerror+0xe8>
   13614: ea000005     	b	0x13630 <socket_strerror+0xc8> @ imm = #0x14
   13618: ebffe46f     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x6e44
   1361c: e1a03000     	mov	r3, r0
   13620: e5933000     	ldr	r3, [r3]
   13624: e1a00003     	mov	r0, r3
   13628: ebffe2fa     	bl	0xc218 <strerror@plt>   @ imm = #-0x7418
   1362c: e1a03000     	mov	r3, r0
   13630: e1a00003     	mov	r0, r3
   13634: e24bd004     	sub	sp, r11, #4
   13638: e8bd8800     	pop	{r11, pc}
   1363c: 5c 28 03 00  	.word	0x0003285c
   13640: 74 28 03 00  	.word	0x00032874
   13644: 88 28 03 00  	.word	0x00032888
   13648: 9c 28 03 00  	.word	0x0003289c
   1364c: b0 28 03 00  	.word	0x000328b0
   13650: b8 28 03 00  	.word	0x000328b8

