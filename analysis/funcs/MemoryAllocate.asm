00019e64 <MemoryAllocate>:
   19e64: e92d4800     	push	{r11, lr}
   19e68: e28db004     	add	r11, sp, #4
   19e6c: e24dd010     	sub	sp, sp, #16
   19e70: e50b0010     	str	r0, [r11, #-0x10]
   19e74: e50b1014     	str	r1, [r11, #-0x14]
   19e78: e51b3010     	ldr	r3, [r11, #-0x10]
   19e7c: e51b2014     	ldr	r2, [r11, #-0x14]
   19e80: e0030392     	mul	r3, r2, r3
   19e84: e1a00003     	mov	r0, r3
   19e88: e3a01010     	mov	r1, #16
   19e8c: ebffffcd     	bl	0x19dc8 <_mm_malloc>    @ imm = #-0xcc
   19e90: e1a03000     	mov	r3, r0
   19e94: e50b3008     	str	r3, [r11, #-0x8]
   19e98: e51b3008     	ldr	r3, [r11, #-0x8]
   19e9c: e3530000     	cmp	r3, #0
   19ea0: 1a000006     	bne	0x19ec0 <MemoryAllocate+0x5c> @ imm = #0x18
   19ea4: e59f2024     	ldr	r2, [pc, #0x24]         @ 0x19ed0 <MemoryAllocate+0x6c>
   19ea8: e59f3024     	ldr	r3, [pc, #0x24]         @ 0x19ed4 <MemoryAllocate+0x70>
   19eac: e5933000     	ldr	r3, [r3]
   19eb0: e1a00002     	mov	r0, r2
   19eb4: e3a01001     	mov	r1, #1
   19eb8: e3a02025     	mov	r2, #37
   19ebc: ebffc9cb     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0xd8d4
   19ec0: e51b3008     	ldr	r3, [r11, #-0x8]
   19ec4: e1a00003     	mov	r0, r3
   19ec8: e24bd004     	sub	sp, r11, #4
   19ecc: e8bd8800     	pop	{r11, pc}
   19ed0: 84 2e 03 00  	.word	0x00032e84
   19ed4: f8 6d 05 00  	.word	0x00056df8

