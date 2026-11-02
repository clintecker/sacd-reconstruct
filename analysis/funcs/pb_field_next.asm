0000ee20 <pb_field_next>:
    ee20: e52db004     	str	r11, [sp, #-0x4]!
    ee24: e28db000     	add	r11, sp, #0
    ee28: e24dd014     	sub	sp, sp, #20
    ee2c: e50b0010     	str	r0, [r11, #-0x10]
    ee30: e3a03001     	mov	r3, #1
    ee34: e54b3009     	strb	r3, [r11, #-0x9]
    ee38: e51b3010     	ldr	r3, [r11, #-0x10]
    ee3c: e5933004     	ldr	r3, [r3, #0x4]
    ee40: e5d32004     	ldrb	r2, [r3, #0x4]
    ee44: e5d31005     	ldrb	r1, [r3, #0x5]
    ee48: e1a01401     	lsl	r1, r1, #8
    ee4c: e1812002     	orr	r2, r1, r2
    ee50: e5d31006     	ldrb	r1, [r3, #0x6]
    ee54: e1a01801     	lsl	r1, r1, #16
    ee58: e1812002     	orr	r2, r1, r2
    ee5c: e5d33007     	ldrb	r3, [r3, #0x7]
    ee60: e1a03c03     	lsl	r3, r3, #24
    ee64: e1833002     	orr	r3, r3, r2
    ee68: e50b3008     	str	r3, [r11, #-0x8]
    ee6c: e51b3010     	ldr	r3, [r11, #-0x10]
    ee70: e5933004     	ldr	r3, [r3, #0x4]
    ee74: e5d33001     	ldrb	r3, [r3, #0x1]
    ee78: e20330f0     	and	r3, r3, #240
    ee7c: e3530020     	cmp	r3, #32
    ee80: 1a000006     	bne	0xeea0 <pb_field_next+0x80> @ imm = #0x18
    ee84: e51b3010     	ldr	r3, [r11, #-0x10]
    ee88: e5933004     	ldr	r3, [r3, #0x4]
    ee8c: e5d33008     	ldrb	r3, [r3, #0x8]
    ee90: e1a02003     	mov	r2, r3
    ee94: e51b3008     	ldr	r3, [r11, #-0x8]
    ee98: e0030392     	mul	r3, r2, r3
    ee9c: e50b3008     	str	r3, [r11, #-0x8]
    eea0: e51b3010     	ldr	r3, [r11, #-0x10]
    eea4: e5933004     	ldr	r3, [r3, #0x4]
    eea8: e283200d     	add	r2, r3, #13
    eeac: e51b3010     	ldr	r3, [r11, #-0x10]
    eeb0: e5832004     	str	r2, [r3, #0x4]
    eeb4: e51b3010     	ldr	r3, [r11, #-0x10]
    eeb8: e5933008     	ldr	r3, [r3, #0x8]
    eebc: e2832001     	add	r2, r3, #1
    eec0: e51b3010     	ldr	r3, [r11, #-0x10]
    eec4: e5832008     	str	r2, [r3, #0x8]
    eec8: e51b3010     	ldr	r3, [r11, #-0x10]
    eecc: e5933004     	ldr	r3, [r3, #0x4]
    eed0: e5d33000     	ldrb	r3, [r3]
    eed4: e3530000     	cmp	r3, #0
    eed8: 1a00000e     	bne	0xef18 <pb_field_next+0xf8> @ imm = #0x38
    eedc: e51b3010     	ldr	r3, [r11, #-0x10]
    eee0: e5932000     	ldr	r2, [r3]
    eee4: e51b3010     	ldr	r3, [r11, #-0x10]
    eee8: e5832004     	str	r2, [r3, #0x4]
    eeec: e51b3010     	ldr	r3, [r11, #-0x10]
    eef0: e3a02000     	mov	r2, #0
    eef4: e5832008     	str	r2, [r3, #0x8]
    eef8: e51b3010     	ldr	r3, [r11, #-0x10]
    eefc: e593200c     	ldr	r2, [r3, #0xc]
    ef00: e51b3010     	ldr	r3, [r11, #-0x10]
    ef04: e5832010     	str	r2, [r3, #0x10]
    ef08: e3a03000     	mov	r3, #0
    ef0c: e50b3008     	str	r3, [r11, #-0x8]
    ef10: e3a03000     	mov	r3, #0
    ef14: e54b3009     	strb	r3, [r11, #-0x9]
    ef18: e51b3010     	ldr	r3, [r11, #-0x10]
    ef1c: e5932010     	ldr	r2, [r3, #0x10]
    ef20: e51b3010     	ldr	r3, [r11, #-0x10]
    ef24: e5933004     	ldr	r3, [r3, #0x4]
    ef28: e5d33002     	ldrb	r3, [r3, #0x2]
    ef2c: e1a01003     	mov	r1, r3
    ef30: e51b3008     	ldr	r3, [r11, #-0x8]
    ef34: e0813003     	add	r3, r1, r3
    ef38: e0822003     	add	r2, r2, r3
    ef3c: e51b3010     	ldr	r3, [r11, #-0x10]
    ef40: e5832010     	str	r2, [r3, #0x10]
    ef44: e51b3010     	ldr	r3, [r11, #-0x10]
    ef48: e5932010     	ldr	r2, [r3, #0x10]
    ef4c: e51b3010     	ldr	r3, [r11, #-0x10]
    ef50: e5933004     	ldr	r3, [r3, #0x4]
    ef54: e5d33003     	ldrb	r3, [r3, #0x3]
    ef58: e6af3073     	sxtb	r3, r3
    ef5c: e0822003     	add	r2, r2, r3
    ef60: e51b3010     	ldr	r3, [r11, #-0x10]
    ef64: e5832014     	str	r2, [r3, #0x14]
    ef68: e55b3009     	ldrb	r3, [r11, #-0x9]
    ef6c: e1a00003     	mov	r0, r3
    ef70: e28bd000     	add	sp, r11, #0
    ef74: e8bd0800     	ldm	sp!, {r11}
    ef78: e12fff1e     	bx	lr

