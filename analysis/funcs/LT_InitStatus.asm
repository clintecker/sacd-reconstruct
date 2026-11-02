00016c2c <LT_InitStatus>:
   16c2c: e52db004     	str	r11, [sp, #-0x4]!
   16c30: e28db000     	add	r11, sp, #0
   16c34: e24dd014     	sub	sp, sp, #20
   16c38: e50b0010     	str	r0, [r11, #-0x10]
   16c3c: e50b1014     	str	r1, [r11, #-0x14]
   16c40: e3a03000     	mov	r3, #0
   16c44: e50b300c     	str	r3, [r11, #-0xc]
   16c48: ea000012     	b	0x16c98 <LT_InitStatus+0x6c> @ imm = #0x48
   16c4c: e3a03000     	mov	r3, #0
   16c50: e50b3008     	str	r3, [r11, #-0x8]
   16c54: ea000009     	b	0x16c80 <LT_InitStatus+0x54> @ imm = #0x24
   16c58: e51b300c     	ldr	r3, [r11, #-0xc]
   16c5c: e1a03203     	lsl	r3, r3, #4
   16c60: e51b2014     	ldr	r2, [r11, #-0x14]
   16c64: e0822003     	add	r2, r2, r3
   16c68: e51b3008     	ldr	r3, [r11, #-0x8]
   16c6c: e3e01055     	mvn	r1, #85
   16c70: e7c21003     	strb	r1, [r2, r3]
   16c74: e51b3008     	ldr	r3, [r11, #-0x8]
   16c78: e2833001     	add	r3, r3, #1
   16c7c: e50b3008     	str	r3, [r11, #-0x8]
   16c80: e51b3008     	ldr	r3, [r11, #-0x8]
   16c84: e353000f     	cmp	r3, #15
   16c88: dafffff2     	ble	0x16c58 <LT_InitStatus+0x2c> @ imm = #-0x38
   16c8c: e51b300c     	ldr	r3, [r11, #-0xc]
   16c90: e2833001     	add	r3, r3, #1
   16c94: e50b300c     	str	r3, [r11, #-0xc]
   16c98: e51b3010     	ldr	r3, [r11, #-0x10]
   16c9c: e5932004     	ldr	r2, [r3, #0x4]
   16ca0: e51b300c     	ldr	r3, [r11, #-0xc]
   16ca4: e1520003     	cmp	r2, r3
   16ca8: caffffe7     	bgt	0x16c4c <LT_InitStatus+0x20> @ imm = #-0x64
   16cac: e28bd000     	add	sp, r11, #0
   16cb0: e8bd0800     	ldm	sp!, {r11}
   16cb4: e12fff1e     	bx	lr

