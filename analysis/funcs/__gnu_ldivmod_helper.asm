00031000 <__gnu_ldivmod_helper>:
   31000: e92d41f0     	push	{r4, r5, r6, r7, r8, lr}
   31004: e1a04002     	mov	r4, r2
   31008: e1a05003     	mov	r5, r3
   3100c: e1a06000     	mov	r6, r0
   31010: e1a07001     	mov	r7, r1
   31014: eb000008     	bl	0x3103c <__divdi3>      @ imm = #0x20
   31018: e0050590     	mul	r5, r0, r5
   3101c: e0832490     	umull	r2, r3, r0, r4
   31020: e0245194     	mla	r4, r4, r1, r5
   31024: e0843003     	add	r3, r4, r3
   31028: e0566002     	subs	r6, r6, r2
   3102c: e0c77003     	sbc	r7, r7, r3
   31030: e59d3018     	ldr	r3, [sp, #0x18]
   31034: e1c360f0     	strd	r6, r7, [r3]
   31038: e8bd81f0     	pop	{r4, r5, r6, r7, r8, pc}

