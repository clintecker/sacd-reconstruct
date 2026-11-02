0000ed88 <pb_field_init>:
    ed88: e52db004     	str	r11, [sp, #-0x4]!
    ed8c: e28db000     	add	r11, sp, #0
    ed90: e24dd014     	sub	sp, sp, #20
    ed94: e50b0008     	str	r0, [r11, #-0x8]
    ed98: e50b100c     	str	r1, [r11, #-0xc]
    ed9c: e50b2010     	str	r2, [r11, #-0x10]
    eda0: e51b3008     	ldr	r3, [r11, #-0x8]
    eda4: e51b200c     	ldr	r2, [r11, #-0xc]
    eda8: e5832004     	str	r2, [r3, #0x4]
    edac: e51b3008     	ldr	r3, [r11, #-0x8]
    edb0: e5932004     	ldr	r2, [r3, #0x4]
    edb4: e51b3008     	ldr	r3, [r11, #-0x8]
    edb8: e5832000     	str	r2, [r3]
    edbc: e51b3008     	ldr	r3, [r11, #-0x8]
    edc0: e3a02000     	mov	r2, #0
    edc4: e5832008     	str	r2, [r3, #0x8]
    edc8: e51b3008     	ldr	r3, [r11, #-0x8]
    edcc: e5933004     	ldr	r3, [r3, #0x4]
    edd0: e5d33002     	ldrb	r3, [r3, #0x2]
    edd4: e51b2010     	ldr	r2, [r11, #-0x10]
    edd8: e0822003     	add	r2, r2, r3
    eddc: e51b3008     	ldr	r3, [r11, #-0x8]
    ede0: e5832010     	str	r2, [r3, #0x10]
    ede4: e51b3008     	ldr	r3, [r11, #-0x8]
    ede8: e5932010     	ldr	r2, [r3, #0x10]
    edec: e51b3008     	ldr	r3, [r11, #-0x8]
    edf0: e5933004     	ldr	r3, [r3, #0x4]
    edf4: e5d33003     	ldrb	r3, [r3, #0x3]
    edf8: e6af3073     	sxtb	r3, r3
    edfc: e0822003     	add	r2, r2, r3
    ee00: e51b3008     	ldr	r3, [r11, #-0x8]
    ee04: e5832014     	str	r2, [r3, #0x14]
    ee08: e51b3008     	ldr	r3, [r11, #-0x8]
    ee0c: e51b2010     	ldr	r2, [r11, #-0x10]
    ee10: e583200c     	str	r2, [r3, #0xc]
    ee14: e28bd000     	add	sp, r11, #0
    ee18: e8bd0800     	ldm	sp!, {r11}
    ee1c: e12fff1e     	bx	lr

