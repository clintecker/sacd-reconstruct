0000d5fc <safe_fwprintf>:
    d5fc: e92d000e     	push	{r1, r2, r3}
    d600: e92d4800     	push	{r11, lr}
    d604: e28db004     	add	r11, sp, #4
    d608: e24dd014     	sub	sp, sp, #20
    d60c: e50b0014     	str	r0, [r11, #-0x14]
    d610: e59f305c     	ldr	r3, [pc, #0x5c]         @ 0xd674 <safe_fwprintf+0x78>
    d614: e5933000     	ldr	r3, [r3]
    d618: e1a00003     	mov	r0, r3
    d61c: eb002063     	bl	0x157b0 <possess>       @ imm = #0x818c
    d620: e28b3008     	add	r3, r11, #8
    d624: e50b3010     	str	r3, [r11, #-0x10]
    d628: e51b3014     	ldr	r3, [r11, #-0x14]
    d62c: e1a00003     	mov	r0, r3
    d630: e59b1004     	ldr	r1, [r11, #0x4]
    d634: e51b2010     	ldr	r2, [r11, #-0x10]
    d638: ebfffb2c     	bl	0xc2f0 <vfwprintf@plt>  @ imm = #-0x1350
    d63c: e1a03000     	mov	r3, r0
    d640: e50b300c     	str	r3, [r11, #-0xc]
    d644: e51b0014     	ldr	r0, [r11, #-0x14]
    d648: ebfffb91     	bl	0xc494 <fflush@plt>     @ imm = #-0x11bc
    d64c: e59f3020     	ldr	r3, [pc, #0x20]         @ 0xd674 <safe_fwprintf+0x78>
    d650: e5933000     	ldr	r3, [r3]
    d654: e1a00003     	mov	r0, r3
    d658: eb002064     	bl	0x157f0 <release>       @ imm = #0x8190
    d65c: e51b300c     	ldr	r3, [r11, #-0xc]
    d660: e1a00003     	mov	r0, r3
    d664: e24bd004     	sub	sp, r11, #4
    d668: e8bd4800     	pop	{r11, lr}
    d66c: e28dd00c     	add	sp, sp, #12
    d670: e12fff1e     	bx	lr
    d674: 3c 71 05 00  	.word	0x0005713c

