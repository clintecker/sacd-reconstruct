00029788 <has_multi_channel>:
   29788: e52db004     	str	r11, [sp, #-0x4]!
   2978c: e28db000     	add	r11, sp, #0
   29790: e24dd00c     	sub	sp, sp, #12
   29794: e50b0008     	str	r0, [r11, #-0x8]
   29798: e51b3008     	ldr	r3, [r11, #-0x8]
   2979c: e5933054     	ldr	r3, [r3, #0x54]
   297a0: e3730001     	cmn	r3, #1
   297a4: 03a03000     	moveq	r3, #0
   297a8: 13a03001     	movne	r3, #1
   297ac: e1a00003     	mov	r0, r3
   297b0: e28bd000     	add	sp, r11, #0
   297b4: e8bd0800     	ldm	sp!, {r11}
   297b8: e12fff1e     	bx	lr

