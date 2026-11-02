0000d678 <handle_sigint>:
    d678: e92d4800     	push	{r11, lr}
    d67c: e28db004     	add	r11, sp, #4
    d680: e24dd008     	sub	sp, sp, #8
    d684: e50b0008     	str	r0, [r11, #-0x8]
    d688: e59f303c     	ldr	r3, [pc, #0x3c]         @ 0xd6cc <handle_sigint+0x54>
    d68c: e5933000     	ldr	r3, [r3]
    d690: e1a00003     	mov	r0, r3
    d694: e59f1034     	ldr	r1, [pc, #0x34]         @ 0xd6d0 <handle_sigint+0x58>
    d698: ebffffd7     	bl	0xd5fc <safe_fwprintf>  @ imm = #-0xa4
    d69c: e59f3030     	ldr	r3, [pc, #0x30]         @ 0xd6d4 <handle_sigint+0x5c>
    d6a0: e5933000     	ldr	r3, [r3]
    d6a4: e3530000     	cmp	r3, #0
    d6a8: 0a000003     	beq	0xd6bc <handle_sigint+0x44> @ imm = #0xc
    d6ac: e59f3020     	ldr	r3, [pc, #0x20]         @ 0xd6d4 <handle_sigint+0x5c>
    d6b0: e5933000     	ldr	r3, [r3]
    d6b4: e1a00003     	mov	r0, r3
    d6b8: eb006db2     	bl	0x28d88 <scarletbook_output_interrupt> @ imm = #0x1b6c8
    d6bc: e3a00001     	mov	r0, #1
    d6c0: ebfffc90     	bl	0xc908 <requested_for_exit> @ imm = #-0xdc0
    d6c4: e24bd004     	sub	sp, r11, #4
    d6c8: e8bd8800     	pop	{r11, pc}
    d6cc: f4 6d 05 00  	.word	0x00056df4
    d6d0: b0 19 03 00  	.word	0x000319b0
    d6d4: f8 9d 05 00  	.word	0x00059df8

