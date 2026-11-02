00015134 <log_flush>:
   15134: e92d4800     	push	{r11, lr}
   15138: e28db004     	add	r11, sp, #4
   1513c: e59f308c     	ldr	r3, [pc, #0x8c]         @ 0x151d0 <log_flush+0x9c>
   15140: e5933000     	ldr	r3, [r3]
   15144: e3530000     	cmp	r3, #0
   15148: 0a00001f     	beq	0x151cc <log_flush+0x98> @ imm = #0x7c
   1514c: e59f3080     	ldr	r3, [pc, #0x80]         @ 0x151d4 <log_flush+0xa0>
   15150: e5933000     	ldr	r3, [r3]
   15154: e3530000     	cmp	r3, #0
   15158: 0a00001b     	beq	0x151cc <log_flush+0x98> @ imm = #0x6c
   1515c: e59f3074     	ldr	r3, [pc, #0x74]         @ 0x151d8 <log_flush+0xa4>
   15160: e5932000     	ldr	r2, [r3]
   15164: e59f3064     	ldr	r3, [pc, #0x64]         @ 0x151d0 <log_flush+0x9c>
   15168: e5933000     	ldr	r3, [r3]
   1516c: e1520003     	cmp	r2, r3
   15170: 9a000015     	bls	0x151cc <log_flush+0x98> @ imm = #0x54
   15174: e59f3054     	ldr	r3, [pc, #0x54]         @ 0x151d0 <log_flush+0x9c>
   15178: e5931000     	ldr	r1, [r3]
   1517c: e59f3054     	ldr	r3, [pc, #0x54]         @ 0x151d8 <log_flush+0xa4>
   15180: e5933000     	ldr	r3, [r3]
   15184: e1a02003     	mov	r2, r3
   15188: e59f3040     	ldr	r3, [pc, #0x40]         @ 0x151d0 <log_flush+0x9c>
   1518c: e5933000     	ldr	r3, [r3]
   15190: e0633002     	rsb	r3, r3, r2
   15194: e1a02003     	mov	r2, r3
   15198: e59f3034     	ldr	r3, [pc, #0x34]         @ 0x151d4 <log_flush+0xa0>
   1519c: e5933000     	ldr	r3, [r3]
   151a0: e1a00001     	mov	r0, r1
   151a4: e3a01001     	mov	r1, #1
   151a8: ebffdd10     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x8bc0
   151ac: e59f3020     	ldr	r3, [pc, #0x20]         @ 0x151d4 <log_flush+0xa0>
   151b0: e5933000     	ldr	r3, [r3]
   151b4: e1a00003     	mov	r0, r3
   151b8: ebffdcb5     	bl	0xc494 <fflush@plt>     @ imm = #-0x8d2c
   151bc: e59f300c     	ldr	r3, [pc, #0xc]          @ 0x151d0 <log_flush+0x9c>
   151c0: e5932000     	ldr	r2, [r3]
   151c4: e59f300c     	ldr	r3, [pc, #0xc]          @ 0x151d8 <log_flush+0xa4>
   151c8: e5832000     	str	r2, [r3]
   151cc: e8bd8800     	pop	{r11, pc}
   151d0: 48 73 05 00  	.word	0x00057348
   151d4: 54 73 05 00  	.word	0x00057354
   151d8: 4c 73 05 00  	.word	0x0005734c

