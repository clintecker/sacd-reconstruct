0000e1b4 <server_loop>:
    e1b4: e92d4810     	push	{r4, r11, lr}
    e1b8: e28db008     	add	r11, sp, #8
    e1bc: e24dd01c     	sub	sp, sp, #28
    e1c0: ebffffe3     	bl	0xe154 <validate_stdin> @ imm = #-0x74
    e1c4: e1a03000     	mov	r3, r0
    e1c8: e50b3010     	str	r3, [r11, #-0x10]
    e1cc: e51b3010     	ldr	r3, [r11, #-0x10]
    e1d0: e3530000     	cmp	r3, #0
    e1d4: 1a00002f     	bne	0xe298 <server_loop+0xe4> @ imm = #0xbc
    e1d8: e59f00d4     	ldr	r0, [pc, #0xd4]         @ 0xe2b4 <server_loop+0x100>
    e1dc: eb001a5e     	bl	0x14b5c <set_log_file>  @ imm = #0x6978
    e1e0: ea00002d     	b	0xe29c <server_loop+0xe8> @ imm = #0xb4
    e1e4: e51b3010     	ldr	r3, [r11, #-0x10]
    e1e8: e3530000     	cmp	r3, #0
    e1ec: 0a000026     	beq	0xe28c <server_loop+0xd8> @ imm = #0x98
    e1f0: eb004c20     	bl	0x21278 <disc_sacd>     @ imm = #0x13080
    e1f4: e1a03000     	mov	r3, r0
    e1f8: e3530000     	cmp	r3, #0
    e1fc: 13a03000     	movne	r3, #0
    e200: 03a03001     	moveq	r3, #1
    e204: e50b3018     	str	r3, [r11, #-0x18]
    e208: e51b3018     	ldr	r3, [r11, #-0x18]
    e20c: e3530000     	cmp	r3, #0
    e210: 0a000004     	beq	0xe228 <server_loop+0x74> @ imm = #0x10
    e214: eb004c3b     	bl	0x21308 <sacd_sacd>     @ imm = #0x130ec
    e218: e1a03000     	mov	r3, r0
    e21c: e1e03003     	mvn	r3, r3
    e220: e1a03fa3     	lsr	r3, r3, #31
    e224: e50b3014     	str	r3, [r11, #-0x14]
    e228: e59f3088     	ldr	r3, [pc, #0x88]         @ 0xe2b8 <server_loop+0x104>
    e22c: e5934000     	ldr	r4, [r3]
    e230: ebfff9a2     	bl	0xc8c0 <is_client_connected> @ imm = #-0x1978
    e234: e1a03000     	mov	r3, r0
    e238: e3530000     	cmp	r3, #0
    e23c: 0a000001     	beq	0xe248 <server_loop+0x94> @ imm = #0x4
    e240: e59f3074     	ldr	r3, [pc, #0x74]         @ 0xe2bc <server_loop+0x108>
    e244: ea000000     	b	0xe24c <server_loop+0x98> @ imm = #0x0
    e248: e59f3070     	ldr	r3, [pc, #0x70]         @ 0xe2c0 <server_loop+0x10c>
    e24c: e51b2018     	ldr	r2, [r11, #-0x18]
    e250: e3520000     	cmp	r2, #0
    e254: 0a000006     	beq	0xe274 <server_loop+0xc0> @ imm = #0x18
    e258: e51b2014     	ldr	r2, [r11, #-0x14]
    e25c: e3520000     	cmp	r2, #0
    e260: 0a000001     	beq	0xe26c <server_loop+0xb8> @ imm = #0x4
    e264: e59f2058     	ldr	r2, [pc, #0x58]         @ 0xe2c4 <server_loop+0x110>
    e268: ea000000     	b	0xe270 <server_loop+0xbc> @ imm = #0x0
    e26c: e59f2054     	ldr	r2, [pc, #0x54]         @ 0xe2c8 <server_loop+0x114>
    e270: ea000000     	b	0xe278 <server_loop+0xc4> @ imm = #0x0
    e274: e59f2050     	ldr	r2, [pc, #0x50]         @ 0xe2cc <server_loop+0x118>
    e278: e58d2000     	str	r2, [sp]
    e27c: e1a00004     	mov	r0, r4
    e280: e59f1048     	ldr	r1, [pc, #0x48]         @ 0xe2d0 <server_loop+0x11c>
    e284: e59f2048     	ldr	r2, [pc, #0x48]         @ 0xe2d4 <server_loop+0x120>
    e288: ebfffcdb     	bl	0xd5fc <safe_fwprintf>  @ imm = #-0xc94
    e28c: e3a00001     	mov	r0, #1
    e290: ebfff90f     	bl	0xc6d4 <sleep@plt>      @ imm = #-0x1bc4
    e294: ea000000     	b	0xe29c <server_loop+0xe8> @ imm = #0x0
    e298: e1a00000     	mov	r0, r0
    e29c: ebfff990     	bl	0xc8e4 <user_requested_exit> @ imm = #-0x19c0
    e2a0: e1a03000     	mov	r3, r0
    e2a4: e3530000     	cmp	r3, #0
    e2a8: 0affffcd     	beq	0xe1e4 <server_loop+0x30> @ imm = #-0xcc
    e2ac: e24bd008     	sub	sp, r11, #8
    e2b0: e8bd8810     	pop	{r4, r11, pc}
    e2b4: 64 1d 03 00  	.word	0x00031d64
    e2b8: f4 6d 05 00  	.word	0x00056df4
    e2bc: 70 1d 03 00  	.word	0x00031d70
    e2c0: 98 1d 03 00  	.word	0x00031d98
    e2c4: ac 1d 03 00  	.word	0x00031dac
    e2c8: f8 1d 03 00  	.word	0x00031df8
    e2cc: 30 1e 03 00  	.word	0x00031e30
    e2d0: 68 1e 03 00  	.word	0x00031e68
    e2d4: 48 1f 03 00  	.word	0x00031f48

