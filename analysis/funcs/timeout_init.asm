0000fc50 <timeout_init>:
    fc50: e52db004     	str	r11, [sp, #-0x4]!
    fc54: e28db000     	add	r11, sp, #0
    fc58: e24dd014     	sub	sp, sp, #20
    fc5c: e50b0008     	str	r0, [r11, #-0x8]
    fc60: e14b21f4     	strd	r2, r3, [r11, #-20]
    fc64: e51b1008     	ldr	r1, [r11, #-0x8]
    fc68: e14b21d4     	ldrd	r2, r3, [r11, #-20]
    fc6c: e1c120f0     	strd	r2, r3, [r1]
    fc70: e51b1008     	ldr	r1, [r11, #-0x8]
    fc74: e1cb20d4     	ldrd	r2, r3, [r11, #4]
    fc78: e1c120f8     	strd	r2, r3, [r1, #8]
    fc7c: e28bd000     	add	sp, r11, #0
    fc80: e8bd0800     	ldm	sp!, {r11}
    fc84: e12fff1e     	bx	lr

