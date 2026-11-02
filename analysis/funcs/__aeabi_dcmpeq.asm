000308f0 <__aeabi_dcmpeq>:
   308f0: e52de008     	str	lr, [sp, #-0x8]!
   308f4: ebfffff8     	bl	0x308dc <__aeabi_cdcmple> @ imm = #-0x20
   308f8: 03a00001     	moveq	r0, #1
   308fc: 13a00000     	movne	r0, #0
   30900: e49df008     	ldr	pc, [sp], #8

