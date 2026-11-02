0001c24c <list_del>:
   1c24c: e92d4800     	push	{r11, lr}
   1c250: e28db004     	add	r11, sp, #4
   1c254: e24dd008     	sub	sp, sp, #8
   1c258: e50b0008     	str	r0, [r11, #-0x8]
   1c25c: e51b3008     	ldr	r3, [r11, #-0x8]
   1c260: e5932004     	ldr	r2, [r3, #0x4]
   1c264: e51b3008     	ldr	r3, [r11, #-0x8]
   1c268: e5933000     	ldr	r3, [r3]
   1c26c: e1a00002     	mov	r0, r2
   1c270: e1a01003     	mov	r1, r3
   1c274: ebffffe6     	bl	0x1c214 <__list_del>    @ imm = #-0x68
   1c278: e51b3008     	ldr	r3, [r11, #-0x8]
   1c27c: e59f2014     	ldr	r2, [pc, #0x14]         @ 0x1c298 <list_del+0x4c>
   1c280: e5832000     	str	r2, [r3]
   1c284: e51b3008     	ldr	r3, [r11, #-0x8]
   1c288: e59f200c     	ldr	r2, [pc, #0xc]          @ 0x1c29c <list_del+0x50>
   1c28c: e5832004     	str	r2, [r3, #0x4]
   1c290: e24bd004     	sub	sp, r11, #4
   1c294: e8bd8800     	pop	{r11, pc}
   1c298: 00 01 10 00  	.word	0x00100100
   1c29c: 00 02 20 00  	.word	0x00200200

