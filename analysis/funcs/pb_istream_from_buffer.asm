0000e8d0 <pb_istream_from_buffer>:
    e8d0: e52db004     	str	r11, [sp, #-0x4]!
    e8d4: e28db000     	add	r11, sp, #0
    e8d8: e24dd01c     	sub	sp, sp, #28
    e8dc: e1a03000     	mov	r3, r0
    e8e0: e50b1018     	str	r1, [r11, #-0x18]
    e8e4: e50b201c     	str	r2, [r11, #-0x1c]
    e8e8: e59f2030     	ldr	r2, [pc, #0x30]         @ 0xe920 <pb_istream_from_buffer+0x50>
    e8ec: e50b2010     	str	r2, [r11, #-0x10]
    e8f0: e51b2018     	ldr	r2, [r11, #-0x18]
    e8f4: e50b200c     	str	r2, [r11, #-0xc]
    e8f8: e51b201c     	ldr	r2, [r11, #-0x1c]
    e8fc: e50b2008     	str	r2, [r11, #-0x8]
    e900: e1a0c003     	mov	r12, r3
    e904: e24b2010     	sub	r2, r11, #16
    e908: e8920007     	ldm	r2, {r0, r1, r2}
    e90c: e88c0007     	stm	r12, {r0, r1, r2}
    e910: e1a00003     	mov	r0, r3
    e914: e28bd000     	add	sp, r11, #0
    e918: e8bd0800     	ldm	sp!, {r11}
    e91c: e12fff1e     	bx	lr
    e920: 6c e8 00 00  	.word	0x0000e86c

