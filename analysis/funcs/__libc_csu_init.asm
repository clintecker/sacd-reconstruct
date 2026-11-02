0003190c <__libc_csu_init>:
   3190c: e92d47f0     	push	{r4, r5, r6, r7, r8, r9, r10, lr}
   31910: e59fa050     	ldr	r10, [pc, #0x50]        @ 0x31968 <__libc_csu_init+0x5c>
   31914: e59f5050     	ldr	r5, [pc, #0x50]         @ 0x3196c <__libc_csu_init+0x60>
   31918: e1a06000     	mov	r6, r0
   3191c: e1a07001     	mov	r7, r1
   31920: e1a08002     	mov	r8, r2
   31924: ebff6a30     	bl	0xc1ec <_init>          @ imm = #-0x25740
   31928: e59f3040     	ldr	r3, [pc, #0x40]         @ 0x31970 <__libc_csu_init+0x64>
   3192c: e06a5005     	rsb	r5, r10, r5
   31930: e08f3003     	add	r3, pc, r3
   31934: e1b05145     	asrs	r5, r5, #2
   31938: e083a00a     	add	r10, r3, r10
   3193c: 08bd87f0     	popeq	{r4, r5, r6, r7, r8, r9, r10, pc}
   31940: e3a04000     	mov	r4, #0
   31944: e1a00006     	mov	r0, r6
   31948: e1a01007     	mov	r1, r7
   3194c: e1a02008     	mov	r2, r8
   31950: e1a0e00f     	mov	lr, pc
   31954: e79af104     	ldr	pc, [r10, r4, lsl #2]
   31958: e2844001     	add	r4, r4, #1
   3195c: e1540005     	cmp	r4, r5
   31960: 3afffff7     	blo	0x31944 <__libc_csu_init+0x38> @ imm = #-0x24
   31964: e8bd87f0     	pop	{r4, r5, r6, r7, r8, r9, r10, pc}
   31968: fc fe ff ff  	.word	0xfffffefc
   3196c: 00 ff ff ff  	.word	0xffffff00
   31970: 7c cc 00 00  	.word	0x0000cc7c

