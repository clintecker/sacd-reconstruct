0001cf20 <utf16_strlen>:
   1cf20: e52db004     	str	r11, [sp, #-0x4]!
   1cf24: e28db000     	add	r11, sp, #0
   1cf28: e24dd014     	sub	sp, sp, #20
   1cf2c: e50b0010     	str	r0, [r11, #-0x10]
   1cf30: e3a03000     	mov	r3, #0
   1cf34: e50b3008     	str	r3, [r11, #-0x8]
   1cf38: ea000002     	b	0x1cf48 <utf16_strlen+0x28> @ imm = #0x8
   1cf3c: e51b3008     	ldr	r3, [r11, #-0x8]
   1cf40: e2833002     	add	r3, r3, #2
   1cf44: e50b3008     	str	r3, [r11, #-0x8]
   1cf48: e51b2010     	ldr	r2, [r11, #-0x10]
   1cf4c: e51b3008     	ldr	r3, [r11, #-0x8]
   1cf50: e0823003     	add	r3, r2, r3
   1cf54: e5d33000     	ldrb	r3, [r3]
   1cf58: e3530000     	cmp	r3, #0
   1cf5c: 1afffff6     	bne	0x1cf3c <utf16_strlen+0x1c> @ imm = #-0x28
   1cf60: e51b3008     	ldr	r3, [r11, #-0x8]
   1cf64: e2833001     	add	r3, r3, #1
   1cf68: e51b2010     	ldr	r2, [r11, #-0x10]
   1cf6c: e0823003     	add	r3, r2, r3
   1cf70: e5d33000     	ldrb	r3, [r3]
   1cf74: e3530000     	cmp	r3, #0
   1cf78: 1affffef     	bne	0x1cf3c <utf16_strlen+0x1c> @ imm = #-0x44
   1cf7c: e51b3008     	ldr	r3, [r11, #-0x8]
   1cf80: e1a00003     	mov	r0, r3
   1cf84: e28bd000     	add	sp, r11, #0
   1cf88: e8bd0800     	ldm	sp!, {r11}
   1cf8c: e12fff1e     	bx	lr

