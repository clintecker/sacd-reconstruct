0002fdb4 <__aeabi_uidivmod>:
   2fdb4: e92d4003     	push	{r0, r1, lr}
   2fdb8: ebffff81     	bl	0x2fbc4 <__udivsi3>     @ imm = #-0x1fc
   2fdbc: e8bd4006     	pop	{r1, r2, lr}
   2fdc0: e0030092     	mul	r3, r2, r0
   2fdc4: e0411003     	sub	r1, r1, r3
   2fdc8: e12fff1e     	bx	lr

