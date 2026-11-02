0000c850 <call_gmon_start>:
    c850: e59f3014     	ldr	r3, [pc, #0x14]         @ 0xc86c <call_gmon_start+0x1c>
    c854: e59f2014     	ldr	r2, [pc, #0x14]         @ 0xc870 <call_gmon_start+0x20>
    c858: e08f3003     	add	r3, pc, r3
    c85c: e7932002     	ldr	r2, [r3, r2]
    c860: e3520000     	cmp	r2, #0
    c864: 012fff1e     	bxeq	lr
    c868: eaffffff     	b	0xc86c <call_gmon_start+0x1c> @ imm = #-0x4
    c86c: 54 1d 03 00  	.word	0x00031d54
    c870: 10 02 00 00  	.word	0x00000210

