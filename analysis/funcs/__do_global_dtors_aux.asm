0000c874 <__do_global_dtors_aux>:
    c874: e59f3010     	ldr	r3, [pc, #0x10]         @ 0xc88c <__do_global_dtors_aux+0x18>
    c878: e5d32000     	ldrb	r2, [r3]
    c87c: e3520000     	cmp	r2, #0
    c880: 03a02001     	moveq	r2, #1
    c884: 05c32000     	strbeq	r2, [r3]
    c888: e12fff1e     	bx	lr
    c88c: 00 6e 05 00  	.word	0x00056e00

