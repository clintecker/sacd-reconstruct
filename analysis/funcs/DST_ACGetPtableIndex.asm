00015588 <DST_ACGetPtableIndex>:
   15588: e52db004     	str	r11, [sp, #-0x4]!
   1558c: e28db000     	add	r11, sp, #0
   15590: e24dd014     	sub	sp, sp, #20
   15594: e50b0010     	str	r0, [r11, #-0x10]
   15598: e50b1014     	str	r1, [r11, #-0x14]
   1559c: e51b3010     	ldr	r3, [r11, #-0x10]
   155a0: e3530000     	cmp	r3, #0
   155a4: b2633000     	rsblt	r3, r3, #0
   155a8: e1a031c3     	asr	r3, r3, #3
   155ac: e50b3008     	str	r3, [r11, #-0x8]
   155b0: e51b2008     	ldr	r2, [r11, #-0x8]
   155b4: e51b3014     	ldr	r3, [r11, #-0x14]
   155b8: e1520003     	cmp	r2, r3
   155bc: ba000002     	blt	0x155cc <DST_ACGetPtableIndex+0x44> @ imm = #0x8
   155c0: e51b3014     	ldr	r3, [r11, #-0x14]
   155c4: e2433001     	sub	r3, r3, #1
   155c8: e50b3008     	str	r3, [r11, #-0x8]
   155cc: e51b3008     	ldr	r3, [r11, #-0x8]
   155d0: e1a00003     	mov	r0, r3
   155d4: e28bd000     	add	sp, r11, #0
   155d8: e8bd0800     	ldm	sp!, {r11}
   155dc: e12fff1e     	bx	lr

