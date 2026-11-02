00030954 <__fixdfsi>:
   30954: e1a02081     	lsl	r2, r1, #1
   30958: e2922602     	adds	r2, r2, #2097152
   3095c: 2a00000c     	bhs	0x30994 <__fixdfsi+0x40> @ imm = #0x30
   30960: 5a000009     	bpl	0x3098c <__fixdfsi+0x38> @ imm = #0x24
   30964: e3e03e3e     	mvn	r3, #992
   30968: e0532ac2     	subs	r2, r3, r2, asr #21
   3096c: 9a00000a     	bls	0x3099c <__fixdfsi+0x48> @ imm = #0x28
   30970: e1a03581     	lsl	r3, r1, #11
   30974: e3833102     	orr	r3, r3, #-2147483648
   30978: e1833aa0     	orr	r3, r3, r0, lsr #21
   3097c: e3110102     	tst	r1, #-2147483648
   30980: e1a00233     	lsr	r0, r3, r2
   30984: 12600000     	rsbne	r0, r0, #0
   30988: e12fff1e     	bx	lr
   3098c: e3a00000     	mov	r0, #0
   30990: e12fff1e     	bx	lr
   30994: e1900601     	orrs	r0, r0, r1, lsl #12
   30998: 1a000002     	bne	0x309a8 <__fixdfsi+0x54> @ imm = #0x8
   3099c: e2110102     	ands	r0, r1, #-2147483648
   309a0: 03e00102     	mvneq	r0, #-2147483648
   309a4: e12fff1e     	bx	lr
   309a8: e3a00000     	mov	r0, #0
   309ac: e12fff1e     	bx	lr

