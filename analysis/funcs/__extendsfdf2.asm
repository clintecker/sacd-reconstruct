00030308 <__extendsfdf2>:
   30308: e1b02080     	lsls	r2, r0, #1
   3030c: e1a011c2     	asr	r1, r2, #3
   30310: e1a01061     	rrx	r1, r1
   30314: e1a00e02     	lsl	r0, r2, #28
   30318: 121234ff     	andsne	r3, r2, #-16777216
   3031c: 133304ff     	teqne	r3, #-16777216
   30320: 1221130e     	eorne	r1, r1, #939524096
   30324: 112fff1e     	bxne	lr
   30328: e3320000     	teq	r2, #0
   3032c: 133304ff     	teqne	r3, #-16777216
   30330: 012fff1e     	bxeq	lr
   30334: e92d4030     	push	{r4, r5, lr}
   30338: e3a04d0e     	mov	r4, #896
   3033c: e2015102     	and	r5, r1, #-2147483648
   30340: e3c11102     	bic	r1, r1, #-2147483648
   30344: eaffff83     	b	0x30158 <__aeabi_dadd+0x148> @ imm = #-0x1f4

