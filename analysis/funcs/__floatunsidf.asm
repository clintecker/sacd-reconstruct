000302bc <__floatunsidf>:
   302bc: e3300000     	teq	r0, #0
   302c0: 03a01000     	moveq	r1, #0
   302c4: 012fff1e     	bxeq	lr
   302c8: e92d4030     	push	{r4, r5, lr}
   302cc: e3a04b01     	mov	r4, #1024
   302d0: e2844032     	add	r4, r4, #50
   302d4: e3a05000     	mov	r5, #0
   302d8: e3a01000     	mov	r1, #0
   302dc: eaffff9d     	b	0x30158 <__aeabi_dadd+0x148> @ imm = #-0x18c

