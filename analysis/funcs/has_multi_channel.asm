0000d0fc <has_multi_channel>:
    d0fc: e52db004     	str	r11, [sp, #-0x4]!
    d100: e28db000     	add	r11, sp, #0
    d104: e24dd00c     	sub	sp, sp, #12
    d108: e50b0008     	str	r0, [r11, #-0x8]
    d10c: e51b3008     	ldr	r3, [r11, #-0x8]
    d110: e5933054     	ldr	r3, [r3, #0x54]
    d114: e3730001     	cmn	r3, #1
    d118: 03a03000     	moveq	r3, #0
    d11c: 13a03001     	movne	r3, #1
    d120: e1a00003     	mov	r0, r3
    d124: e28bd000     	add	sp, r11, #0
    d128: e8bd0800     	ldm	sp!, {r11}
    d12c: e12fff1e     	bx	lr

