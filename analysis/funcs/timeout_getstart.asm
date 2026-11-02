0000ff88 <timeout_getstart>:
    ff88: e52db004     	str	r11, [sp, #-0x4]!
    ff8c: e28db000     	add	r11, sp, #0
    ff90: e24dd00c     	sub	sp, sp, #12
    ff94: e50b0008     	str	r0, [r11, #-0x8]
    ff98: e51b3008     	ldr	r3, [r11, #-0x8]
    ff9c: e1c321d0     	ldrd	r2, r3, [r3, #16]
    ffa0: e1a00002     	mov	r0, r2
    ffa4: e1a01003     	mov	r1, r3
    ffa8: e28bd000     	add	sp, r11, #0
    ffac: e8bd0800     	ldm	sp!, {r11}
    ffb0: e12fff1e     	bx	lr

