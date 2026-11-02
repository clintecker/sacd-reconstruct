0001785c <DST_GetErrorMessage>:
   1785c: e52db004     	str	r11, [sp, #-0x4]!
   17860: e28db000     	add	r11, sp, #0
   17864: e24dd00c     	sub	sp, sp, #12
   17868: e50b0008     	str	r0, [r11, #-0x8]
   1786c: e51b3008     	ldr	r3, [r11, #-0x8]
   17870: e3530000     	cmp	r3, #0
   17874: ba000006     	blt	0x17894 <DST_GetErrorMessage+0x38> @ imm = #0x18
   17878: e51b3008     	ldr	r3, [r11, #-0x8]
   1787c: e353000f     	cmp	r3, #15
   17880: ca000003     	bgt	0x17894 <DST_GetErrorMessage+0x38> @ imm = #0xc
   17884: e51b2008     	ldr	r2, [r11, #-0x8]
   17888: e59f3018     	ldr	r3, [pc, #0x18]         @ 0x178a8 <DST_GetErrorMessage+0x4c>
   1788c: e7933102     	ldr	r3, [r3, r2, lsl #2]
   17890: ea000000     	b	0x17898 <DST_GetErrorMessage+0x3c> @ imm = #0x0
   17894: e59f3010     	ldr	r3, [pc, #0x10]         @ 0x178ac <DST_GetErrorMessage+0x50>
   17898: e1a00003     	mov	r0, r3
   1789c: e28bd000     	add	sp, r11, #0
   178a0: e8bd0800     	ldm	sp!, {r11}
   178a4: e12fff1e     	bx	lr
   178a8: dc e7 03 00  	.word	0x0003e7dc
   178ac: 3c 2e 03 00  	.word	0x00032e3c

