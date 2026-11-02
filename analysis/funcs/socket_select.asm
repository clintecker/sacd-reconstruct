0001296c <socket_select>:
   1296c: e92d4810     	push	{r4, r11, lr}
   12970: e28db008     	add	r11, sp, #8
   12974: e24dd034     	sub	sp, sp, #52
   12978: e50b0028     	str	r0, [r11, #-0x28]
   1297c: e50b102c     	str	r1, [r11, #-0x2c]
   12980: e50b2030     	str	r2, [r11, #-0x30]
   12984: e50b3034     	str	r3, [r11, #-0x34]
   12988: e59b0004     	ldr	r0, [r11, #0x4]
   1298c: ebfff588     	bl	0xffb4 <timeout_getretry> @ imm = #-0x29e0
   12990: e1a02000     	mov	r2, r0
   12994: e1a03001     	mov	r3, r1
   12998: e14b21f4     	strd	r2, r3, [r11, #-20]
   1299c: e14b01d4     	ldrd	r0, r1, [r11, #-20]
   129a0: eb0077eb     	bl	0x30954 <__fixdfsi>     @ imm = #0x1dfac
   129a4: e1a03000     	mov	r3, r0
   129a8: e50b3020     	str	r3, [r11, #-0x20]
   129ac: e51b3020     	ldr	r3, [r11, #-0x20]
   129b0: e1a00003     	mov	r0, r3
   129b4: eb007649     	bl	0x302e0 <__floatsidf>   @ imm = #0x1d924
   129b8: e1a02000     	mov	r2, r0
   129bc: e1a03001     	mov	r3, r1
   129c0: e14b01d4     	ldrd	r0, r1, [r11, #-20]
   129c4: eb007590     	bl	0x3000c <__subdf3>      @ imm = #0x1d640
   129c8: e1a02000     	mov	r2, r0
   129cc: e1a03001     	mov	r3, r1
   129d0: e1a00002     	mov	r0, r2
   129d4: e1a01003     	mov	r1, r3
   129d8: e28f30b8     	add	r3, pc, #184
   129dc: e1c320d0     	ldrd	r2, r3, [r3]
   129e0: eb007675     	bl	0x303bc <__muldf3>      @ imm = #0x1d9d4
   129e4: e1a02000     	mov	r2, r0
   129e8: e1a03001     	mov	r3, r1
   129ec: e1a00002     	mov	r0, r2
   129f0: e1a01003     	mov	r1, r3
   129f4: eb0077d6     	bl	0x30954 <__fixdfsi>     @ imm = #0x1df58
   129f8: e1a03000     	mov	r3, r0
   129fc: e50b301c     	str	r3, [r11, #-0x1c]
   12a00: e3a03000     	mov	r3, #0
   12a04: e1a04003     	mov	r4, r3
   12a08: e14b01d4     	ldrd	r0, r1, [r11, #-20]
   12a0c: e3a02000     	mov	r2, #0
   12a10: e3a03000     	mov	r3, #0
   12a14: eb0077c4     	bl	0x3092c <__aeabi_dcmpge> @ imm = #0x1df10
   12a18: e1a03000     	mov	r3, r0
   12a1c: e3530000     	cmp	r3, #0
   12a20: 0a000001     	beq	0x12a2c <socket_select+0xc0> @ imm = #0x4
   12a24: e3a03001     	mov	r3, #1
   12a28: e1a04003     	mov	r4, r3
   12a2c: e6ef3074     	uxtb	r3, r4
   12a30: e3530000     	cmp	r3, #0
   12a34: 0a000001     	beq	0x12a40 <socket_select+0xd4> @ imm = #0x4
   12a38: e24b3020     	sub	r3, r11, #32
   12a3c: ea000000     	b	0x12a44 <socket_select+0xd8> @ imm = #0x0
   12a40: e3a03000     	mov	r3, #0
   12a44: e58d3000     	str	r3, [sp]
   12a48: e51b0028     	ldr	r0, [r11, #-0x28]
   12a4c: e51b102c     	ldr	r1, [r11, #-0x2c]
   12a50: e51b2030     	ldr	r2, [r11, #-0x30]
   12a54: e51b3034     	ldr	r3, [r11, #-0x34]
   12a58: ebffe6de     	bl	0xc5d8 <select@plt>     @ imm = #-0x6488
   12a5c: e1a03000     	mov	r3, r0
   12a60: e50b3018     	str	r3, [r11, #-0x18]
   12a64: e51b3018     	ldr	r3, [r11, #-0x18]
   12a68: e3530000     	cmp	r3, #0
   12a6c: aa000004     	bge	0x12a84 <socket_select+0x118> @ imm = #0x10
   12a70: ebffe759     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x629c
   12a74: e1a03000     	mov	r3, r0
   12a78: e5933000     	ldr	r3, [r3]
   12a7c: e3530004     	cmp	r3, #4
   12a80: 0affffc0     	beq	0x12988 <socket_select+0x1c> @ imm = #-0x100
   12a84: e51b3018     	ldr	r3, [r11, #-0x18]
   12a88: e1a00003     	mov	r0, r3
   12a8c: e24bd008     	sub	sp, r11, #8
   12a90: e8bd8810     	pop	{r4, r11, pc}
   12a94: e1a00000     	mov	r0, r0
   12a98: 00 00 00 00  	.word	0x00000000
   12a9c: 80 84 2e 41  	.word	0x412e8480

