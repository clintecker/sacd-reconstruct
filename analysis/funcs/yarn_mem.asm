00015690 <yarn_mem>:
   15690: e52db004     	str	r11, [sp, #-0x4]!
   15694: e28db000     	add	r11, sp, #0
   15698: e24dd00c     	sub	sp, sp, #12
   1569c: e50b0008     	str	r0, [r11, #-0x8]
   156a0: e50b100c     	str	r1, [r11, #-0xc]
   156a4: e59f301c     	ldr	r3, [pc, #0x1c]         @ 0x156c8 <yarn_mem+0x38>
   156a8: e51b2008     	ldr	r2, [r11, #-0x8]
   156ac: e5832000     	str	r2, [r3]
   156b0: e59f3014     	ldr	r3, [pc, #0x14]         @ 0x156cc <yarn_mem+0x3c>
   156b4: e51b200c     	ldr	r2, [r11, #-0xc]
   156b8: e5832000     	str	r2, [r3]
   156bc: e28bd000     	add	sp, r11, #0
   156c0: e8bd0800     	ldm	sp!, {r11}
   156c4: e12fff1e     	bx	lr
   156c8: d4 e7 03 00  	.word	0x0003e7d4
   156cc: d8 e7 03 00  	.word	0x0003e7d8

