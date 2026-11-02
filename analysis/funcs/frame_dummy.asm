0000c890 <frame_dummy>:
    c890: e59f0020     	ldr	r0, [pc, #0x20]         @ 0xc8b8 <frame_dummy+0x28>
    c894: e92d4010     	push	{r4, lr}
    c898: e5903000     	ldr	r3, [r0]
    c89c: e3530000     	cmp	r3, #0
    c8a0: 08bd8010     	popeq	{r4, pc}
    c8a4: e59f3010     	ldr	r3, [pc, #0x10]         @ 0xc8bc <frame_dummy+0x2c>
    c8a8: e3530000     	cmp	r3, #0
    c8ac: 08bd8010     	popeq	{r4, pc}
    c8b0: e12fff33     	blx	r3
    c8b4: e8bd8010     	pop	{r4, pc}
    c8b8: b8 e4 03 00  	.word	0x0003e4b8
    c8bc: 00 00 00 00  	.word	0x00000000

