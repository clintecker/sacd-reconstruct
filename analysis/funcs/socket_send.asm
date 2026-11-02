00012eb0 <socket_send>:
   12eb0: e92d4800     	push	{r11, lr}
   12eb4: e28db004     	add	r11, sp, #4
   12eb8: e24dd018     	sub	sp, sp, #24
   12ebc: e50b0010     	str	r0, [r11, #-0x10]
   12ec0: e50b1014     	str	r1, [r11, #-0x14]
   12ec4: e50b2018     	str	r2, [r11, #-0x18]
   12ec8: e50b301c     	str	r3, [r11, #-0x1c]
   12ecc: e51b301c     	ldr	r3, [r11, #-0x1c]
   12ed0: e3a02000     	mov	r2, #0
   12ed4: e5832000     	str	r2, [r3]
   12ed8: e51b3010     	ldr	r3, [r11, #-0x10]
   12edc: e5933000     	ldr	r3, [r3]
   12ee0: e3730001     	cmn	r3, #1
   12ee4: 1a000002     	bne	0x12ef4 <socket_send+0x44> @ imm = #0x8
   12ee8: e3e03001     	mvn	r3, #1
   12eec: ea000031     	b	0x12fb8 <socket_send+0x108> @ imm = #0xc4
   12ef0: e1a00000     	mov	r0, r0
   12ef4: e51b3010     	ldr	r3, [r11, #-0x10]
   12ef8: e5933000     	ldr	r3, [r3]
   12efc: e1a00003     	mov	r0, r3
   12f00: e51b1014     	ldr	r1, [r11, #-0x14]
   12f04: e51b2018     	ldr	r2, [r11, #-0x18]
   12f08: e59b3004     	ldr	r3, [r11, #0x4]
   12f0c: ebffe5f3     	bl	0xc6e0 <send@plt>       @ imm = #-0x6834
   12f10: e1a03000     	mov	r3, r0
   12f14: e50b3008     	str	r3, [r11, #-0x8]
   12f18: e51b3008     	ldr	r3, [r11, #-0x8]
   12f1c: e3530000     	cmp	r3, #0
   12f20: da000004     	ble	0x12f38 <socket_send+0x88> @ imm = #0x10
   12f24: e51b2008     	ldr	r2, [r11, #-0x8]
   12f28: e51b301c     	ldr	r3, [r11, #-0x1c]
   12f2c: e5832000     	str	r2, [r3]
   12f30: e3a03000     	mov	r3, #0
   12f34: ea00001f     	b	0x12fb8 <socket_send+0x108> @ imm = #0x7c
   12f38: ebffe627     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x6764
   12f3c: e1a03000     	mov	r3, r0
   12f40: e5933000     	ldr	r3, [r3]
   12f44: e50b300c     	str	r3, [r11, #-0xc]
   12f48: e51b3008     	ldr	r3, [r11, #-0x8]
   12f4c: e3530000     	cmp	r3, #0
   12f50: 0a000002     	beq	0x12f60 <socket_send+0xb0> @ imm = #0x8
   12f54: e51b300c     	ldr	r3, [r11, #-0xc]
   12f58: e3530020     	cmp	r3, #32
   12f5c: 1a000001     	bne	0x12f68 <socket_send+0xb8> @ imm = #0x4
   12f60: e3e03001     	mvn	r3, #1
   12f64: ea000013     	b	0x12fb8 <socket_send+0x108> @ imm = #0x4c
   12f68: e51b300c     	ldr	r3, [r11, #-0xc]
   12f6c: e3530004     	cmp	r3, #4
   12f70: 1a000001     	bne	0x12f7c <socket_send+0xcc> @ imm = #0x4
   12f74: e1a00000     	mov	r0, r0
   12f78: eaffffdd     	b	0x12ef4 <socket_send+0x44> @ imm = #-0x8c
   12f7c: e51b300c     	ldr	r3, [r11, #-0xc]
   12f80: e353000b     	cmp	r3, #11
   12f84: 0a000001     	beq	0x12f90 <socket_send+0xe0> @ imm = #0x4
   12f88: e51b300c     	ldr	r3, [r11, #-0xc]
   12f8c: ea000009     	b	0x12fb8 <socket_send+0x108> @ imm = #0x24
   12f90: e51b0010     	ldr	r0, [r11, #-0x10]
   12f94: e3a01002     	mov	r1, #2
   12f98: e59b2008     	ldr	r2, [r11, #0x8]
   12f9c: ebfffd73     	bl	0x12570 <socket_waitfd> @ imm = #-0xa34
   12fa0: e1a03000     	mov	r3, r0
   12fa4: e50b300c     	str	r3, [r11, #-0xc]
   12fa8: e51b300c     	ldr	r3, [r11, #-0xc]
   12fac: e3530000     	cmp	r3, #0
   12fb0: 0affffce     	beq	0x12ef0 <socket_send+0x40> @ imm = #-0xc8
   12fb4: e51b300c     	ldr	r3, [r11, #-0xc]
   12fb8: e1a00003     	mov	r0, r3
   12fbc: e24bd004     	sub	sp, r11, #4
   12fc0: e8bd8800     	pop	{r11, pc}

