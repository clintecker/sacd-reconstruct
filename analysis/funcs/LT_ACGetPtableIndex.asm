000167b8 <LT_ACGetPtableIndex>:
   167b8: e52db004     	str	r11, [sp, #-0x4]!
   167bc: e28db000     	add	r11, sp, #0
   167c0: e24dd014     	sub	sp, sp, #20
   167c4: e1a03000     	mov	r3, r0
   167c8: e50b1014     	str	r1, [r11, #-0x14]
   167cc: e14b30be     	strh	r3, [r11, #-14]
   167d0: e15b30fe     	ldrsh	r3, [r11, #-14]
   167d4: e3530000     	cmp	r3, #0
   167d8: b2633000     	rsblt	r3, r3, #0
   167dc: e1a031c3     	asr	r3, r3, #3
   167e0: e50b3008     	str	r3, [r11, #-0x8]
   167e4: e51b2008     	ldr	r2, [r11, #-0x8]
   167e8: e51b3014     	ldr	r3, [r11, #-0x14]
   167ec: e1520003     	cmp	r2, r3
   167f0: ba000002     	blt	0x16800 <LT_ACGetPtableIndex+0x48> @ imm = #0x8
   167f4: e51b3014     	ldr	r3, [r11, #-0x14]
   167f8: e2433001     	sub	r3, r3, #1
   167fc: e50b3008     	str	r3, [r11, #-0x8]
   16800: e51b3008     	ldr	r3, [r11, #-0x8]
   16804: e1a00003     	mov	r0, r3
   16808: e28bd000     	add	sp, r11, #0
   1680c: e8bd0800     	ldm	sp!, {r11}
   16810: e12fff1e     	bx	lr

