00030fc4 <__gnu_uldivmod_helper>:
   30fc4: e92d41f0     	push	{r4, r5, r6, r7, r8, lr}
   30fc8: e1a04002     	mov	r4, r2
   30fcc: e1a05003     	mov	r5, r3
   30fd0: e1a06000     	mov	r6, r0
   30fd4: e1a07001     	mov	r7, r1
   30fd8: eb00013e     	bl	0x314d8 <__udivdi3>     @ imm = #0x4f8
   30fdc: e0050590     	mul	r5, r0, r5
   30fe0: e0832490     	umull	r2, r3, r0, r4
   30fe4: e0245194     	mla	r4, r4, r1, r5
   30fe8: e0843003     	add	r3, r4, r3
   30fec: e0566002     	subs	r6, r6, r2
   30ff0: e0c77003     	sbc	r7, r7, r3
   30ff4: e59d3018     	ldr	r3, [sp, #0x18]
   30ff8: e1c360f0     	strd	r6, r7, [r3]
   30ffc: e8bd81f0     	pop	{r4, r5, r6, r7, r8, pc}

