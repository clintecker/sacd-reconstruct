0000c818 <_start>:
    c818: e59fc024     	ldr	r12, [pc, #0x24]        @ 0xc844 <_start+0x2c>
    c81c: e3a0b000     	mov	r11, #0
    c820: e49d1004     	ldr	r1, [sp], #4
    c824: e1a0200d     	mov	r2, sp
    c828: e52d2004     	str	r2, [sp, #-0x4]!
    c82c: e52d0004     	str	r0, [sp, #-0x4]!
    c830: e59f0010     	ldr	r0, [pc, #0x10]         @ 0xc848 <_start+0x30>
    c834: e59f3010     	ldr	r3, [pc, #0x10]         @ 0xc84c <_start+0x34>
    c838: e52dc004     	str	r12, [sp, #-0x4]!
    c83c: ebfffe96     	bl	0xc29c <__libc_start_main@plt> @ imm = #-0x5a8
    c840: ebfffe80     	bl	0xc248 <abort@plt>      @ imm = #-0x600
    c844: 08 19 03 00  	.word	0x00031908
    c848: d8 e2 00 00  	.word	0x0000e2d8
    c84c: 0c 19 03 00  	.word	0x0003190c

