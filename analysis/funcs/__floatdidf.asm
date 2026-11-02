0003035c <__floatdidf>:
   3035c: e1902001     	orrs	r2, r0, r1
   30360: 012fff1e     	bxeq	lr
   30364: e92d4030     	push	{r4, r5, lr}
   30368: e2115102     	ands	r5, r1, #-2147483648
   3036c: 5a000001     	bpl	0x30378 <__floatdidf+0x1c> @ imm = #0x4
   30370: e2700000     	rsbs	r0, r0, #0
   30374: e2e11000     	rsc	r1, r1, #0
   30378: e3a04b01     	mov	r4, #1024
   3037c: e2844032     	add	r4, r4, #50
   30380: e1b0cb21     	lsrs	r12, r1, #22
   30384: 0affff5c     	beq	0x300fc <__aeabi_dadd+0xec> @ imm = #-0x290
   30388: e3a02003     	mov	r2, #3
   3038c: e1b0c1ac     	lsrs	r12, r12, #3
   30390: 12822003     	addne	r2, r2, #3
   30394: e1b0c1ac     	lsrs	r12, r12, #3
   30398: 12822003     	addne	r2, r2, #3
   3039c: e08221ac     	add	r2, r2, r12, lsr #3
   303a0: e2623020     	rsb	r3, r2, #32
   303a4: e1a0c310     	lsl	r12, r0, r3
   303a8: e1a00230     	lsr	r0, r0, r2
   303ac: e1800311     	orr	r0, r0, r1, lsl r3
   303b0: e1a01231     	lsr	r1, r1, r2
   303b4: e0844002     	add	r4, r4, r2
   303b8: eaffff4f     	b	0x300fc <__aeabi_dadd+0xec> @ imm = #-0x2c4

