00030f98 <__aeabi_uldivmod>:
   30f98: e24dd008     	sub	sp, sp, #8
   30f9c: e92d6000     	push	{sp, lr}
   30fa0: eb000007     	bl	0x30fc4 <__gnu_uldivmod_helper> @ imm = #0x1c
   30fa4: e59de004     	ldr	lr, [sp, #0x4]
   30fa8: e28dd008     	add	sp, sp, #8
   30fac: e8bd000c     	pop	{r2, r3}
   30fb0: e12fff1e     	bx	lr

