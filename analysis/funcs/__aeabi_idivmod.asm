0002ffec <__aeabi_idivmod>:
   2ffec: e92d4003     	push	{r0, r1, lr}
   2fff0: ebffff75     	bl	0x2fdcc <__divsi3>      @ imm = #-0x22c
   2fff4: e8bd4006     	pop	{r1, r2, lr}
   2fff8: e0030092     	mul	r3, r2, r0
   2fffc: e0411003     	sub	r1, r1, r3
   30000: e12fff1e     	bx	lr

