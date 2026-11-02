0003083c <__nedf2>:
   3083c: e3a0c001     	mov	r12, #1
   30840: e50dc004     	str	r12, [sp, #-0x4]
   30844: e1a0c081     	lsl	r12, r1, #1
   30848: e1f0cacc     	mvns	r12, r12, asr #21
   3084c: e1a0c083     	lsl	r12, r3, #1
   30850: 11f0cacc     	mvnsne	r12, r12, asr #21
   30854: 0a00000d     	beq	0x30890 <__nedf2+0x54>  @ imm = #0x34
   30858: e190c081     	orrs	r12, r0, r1, lsl #1
   3085c: 0192c083     	orrseq	r12, r2, r3, lsl #1
   30860: 11310003     	teqne	r1, r3
   30864: 01300002     	teqeq	r0, r2
   30868: 03a00000     	moveq	r0, #0
   3086c: 012fff1e     	bxeq	lr
   30870: e3700000     	cmn	r0, #0
   30874: e1310003     	teq	r1, r3
   30878: 51510003     	cmppl	r1, r3
   3087c: 01500002     	cmpeq	r0, r2
   30880: 21a00fc3     	asrhs	r0, r3, #31
   30884: 31e00fc3     	mvnlo	r0, r3, asr #31
   30888: e3800001     	orr	r0, r0, #1
   3088c: e12fff1e     	bx	lr
   30890: e1a0c081     	lsl	r12, r1, #1
   30894: e1f0cacc     	mvns	r12, r12, asr #21
   30898: 1a000001     	bne	0x308a4 <__nedf2+0x68>  @ imm = #0x4
   3089c: e190c601     	orrs	r12, r0, r1, lsl #12
   308a0: 1a000004     	bne	0x308b8 <__nedf2+0x7c>  @ imm = #0x10
   308a4: e1a0c083     	lsl	r12, r3, #1
   308a8: e1f0cacc     	mvns	r12, r12, asr #21
   308ac: 1affffe9     	bne	0x30858 <__nedf2+0x1c>  @ imm = #-0x5c
   308b0: e192c603     	orrs	r12, r2, r3, lsl #12
   308b4: 0affffe7     	beq	0x30858 <__nedf2+0x1c>  @ imm = #-0x64
   308b8: e51d0004     	ldr	r0, [sp, #-0x4]
   308bc: e12fff1e     	bx	lr

