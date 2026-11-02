000302e0 <__floatsidf>:
   302e0: e3300000     	teq	r0, #0
   302e4: 03a01000     	moveq	r1, #0
   302e8: 012fff1e     	bxeq	lr
   302ec: e92d4030     	push	{r4, r5, lr}
   302f0: e3a04b01     	mov	r4, #1024
   302f4: e2844032     	add	r4, r4, #50
   302f8: e2105102     	ands	r5, r0, #-2147483648
   302fc: 42600000     	rsbmi	r0, r0, #0
   30300: e3a01000     	mov	r1, #0
   30304: eaffff93     	b	0x30158 <__aeabi_dadd+0x148> @ imm = #-0x1b4

