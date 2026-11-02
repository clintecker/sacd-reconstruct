00016a24 <Reverse7LSBs>:
   16a24: e52db004     	str	r11, [sp, #-0x4]!
   16a28: e28db000     	add	r11, sp, #0
   16a2c: e24dd00c     	sub	sp, sp, #12
   16a30: e1a03000     	mov	r3, r0
   16a34: e14b30b6     	strh	r3, [r11, #-6]
   16a38: e15b30f6     	ldrsh	r3, [r11, #-6]
   16a3c: e2833c02     	add	r3, r3, #512
   16a40: e203307f     	and	r3, r3, #127
   16a44: e59f201c     	ldr	r2, [pc, #0x1c]         @ 0x16a68 <Reverse7LSBs+0x44>
   16a48: e1a03083     	lsl	r3, r3, #1
   16a4c: e0823003     	add	r3, r2, r3
   16a50: e1d330b0     	ldrh	r3, [r3]
   16a54: e6bf3073     	sxth	r3, r3
   16a58: e1a00003     	mov	r0, r3
   16a5c: e28bd000     	add	sp, r11, #0
   16a60: e8bd0800     	ldm	sp!, {r11}
   16a64: e12fff1e     	bx	lr
   16a68: 48 2b 03 00  	.word	0x00032b48

