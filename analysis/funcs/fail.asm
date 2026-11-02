000155e0 <fail>:
   155e0: e92d4800     	push	{r11, lr}
   155e4: e28db004     	add	r11, sp, #4
   155e8: e24dd010     	sub	sp, sp, #16
   155ec: e50b0008     	str	r0, [r11, #-0x8]
   155f0: e59f3080     	ldr	r3, [pc, #0x80]         @ 0x15678 <fail+0x98>
   155f4: e5933000     	ldr	r3, [r3]
   155f8: e1a00003     	mov	r0, r3
   155fc: e59f1078     	ldr	r1, [pc, #0x78]         @ 0x1567c <fail+0x9c>
   15600: e59f3078     	ldr	r3, [pc, #0x78]         @ 0x15680 <fail+0xa0>
   15604: e5932000     	ldr	r2, [r3]
   15608: e51b3008     	ldr	r3, [r11, #-0x8]
   1560c: e353000c     	cmp	r3, #12
   15610: 1a000001     	bne	0x1561c <fail+0x3c>     @ imm = #0x4
   15614: e59f3068     	ldr	r3, [pc, #0x68]         @ 0x15684 <fail+0xa4>
   15618: ea000000     	b	0x15620 <fail+0x40>     @ imm = #0x0
   1561c: e59f3064     	ldr	r3, [pc, #0x64]         @ 0x15688 <fail+0xa8>
   15620: e51bc008     	ldr	r12, [r11, #-0x8]
   15624: e58dc000     	str	r12, [sp]
   15628: ebffdc05     	bl	0xc644 <fprintf@plt>    @ imm = #-0x8fec
   1562c: e59f3058     	ldr	r3, [pc, #0x58]         @ 0x1568c <fail+0xac>
   15630: e5933000     	ldr	r3, [r3]
   15634: e3530000     	cmp	r3, #0
   15638: 0a000003     	beq	0x1564c <fail+0x6c>     @ imm = #0xc
   1563c: e59f3048     	ldr	r3, [pc, #0x48]         @ 0x1568c <fail+0xac>
   15640: e5933000     	ldr	r3, [r3]
   15644: e51b0008     	ldr	r0, [r11, #-0x8]
   15648: e12fff33     	blx	r3
   1564c: e51b3008     	ldr	r3, [r11, #-0x8]
   15650: e353000c     	cmp	r3, #12
   15654: 0a000002     	beq	0x15664 <fail+0x84>     @ imm = #0x8
   15658: e51b3008     	ldr	r3, [r11, #-0x8]
   1565c: e353000b     	cmp	r3, #11
   15660: 1a000001     	bne	0x1566c <fail+0x8c>     @ imm = #0x4
   15664: e51b3008     	ldr	r3, [r11, #-0x8]
   15668: ea000000     	b	0x15670 <fail+0x90>     @ imm = #0x0
   1566c: e3a03016     	mov	r3, #22
   15670: e1a00003     	mov	r0, r3
   15674: ebffdc52     	bl	0xc7c4 <exit@plt>       @ imm = #-0x8eb8
   15678: f8 6d 05 00  	.word	0x00056df8
   1567c: 5c 2a 03 00  	.word	0x00032a5c
   15680: d0 e7 03 00  	.word	0x0003e7d0
   15684: 78 2a 03 00  	.word	0x00032a78
   15688: 88 2a 03 00  	.word	0x00032a88
   1568c: 60 73 05 00  	.word	0x00057360

