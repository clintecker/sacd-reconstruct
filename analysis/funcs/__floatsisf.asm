00030bf4 <__floatsisf>:
   30bf4: e2103102     	ands	r3, r0, #-2147483648
   30bf8: 42600000     	rsbmi	r0, r0, #0
   30bfc: e1b0c000     	movs	r12, r0
   30c00: 012fff1e     	bxeq	lr
   30c04: e383344b     	orr	r3, r3, #1258291200
   30c08: e1a01000     	mov	r1, r0
   30c0c: e3a00000     	mov	r0, #0
   30c10: ea00000f     	b	0x30c54 <__floatdisf+0x30> @ imm = #0x3c

