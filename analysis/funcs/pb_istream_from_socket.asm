00020800 <pb_istream_from_socket>:
   20800: e52db004     	str	r11, [sp, #-0x4]!
   20804: e28db000     	add	r11, sp, #0
   20808: e24dd01c     	sub	sp, sp, #28
   2080c: e1a03000     	mov	r3, r0
   20810: e50b1018     	str	r1, [r11, #-0x18]
   20814: e59f2030     	ldr	r2, [pc, #0x30]         @ 0x2084c <pb_istream_from_socket+0x4c>
   20818: e50b2010     	str	r2, [r11, #-0x10]
   2081c: e51b2018     	ldr	r2, [r11, #-0x18]
   20820: e50b200c     	str	r2, [r11, #-0xc]
   20824: e3e02000     	mvn	r2, #0
   20828: e50b2008     	str	r2, [r11, #-0x8]
   2082c: e1a0c003     	mov	r12, r3
   20830: e24b2010     	sub	r2, r11, #16
   20834: e8920007     	ldm	r2, {r0, r1, r2}
   20838: e88c0007     	stm	r12, {r0, r1, r2}
   2083c: e1a00003     	mov	r0, r3
   20840: e28bd000     	add	sp, r11, #0
   20844: e8bd0800     	ldm	sp!, {r11}
   20848: e12fff1e     	bx	lr
   2084c: 74 06 02 00  	.word	0x00020674

