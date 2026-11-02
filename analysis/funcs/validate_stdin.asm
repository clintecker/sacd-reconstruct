0000e154 <validate_stdin>:
    e154: e92d4800     	push	{r11, lr}
    e158: e28db004     	add	r11, sp, #4
    e15c: e24dd008     	sub	sp, sp, #8
    e160: e3a00000     	mov	r0, #0
    e164: ebfff8a9     	bl	0xc410 <tcgetpgrp@plt>  @ imm = #-0x1d5c
    e168: e1a03000     	mov	r3, r0
    e16c: e50b3008     	str	r3, [r11, #-0x8]
    e170: e51b3008     	ldr	r3, [r11, #-0x8]
    e174: e3730001     	cmn	r3, #1
    e178: 0a000009     	beq	0xe1a4 <validate_stdin+0x50> @ imm = #0x24
    e17c: ebfff822     	bl	0xc20c <getpgrp@plt>    @ imm = #-0x1f78
    e180: e1a02000     	mov	r2, r0
    e184: e51b3008     	ldr	r3, [r11, #-0x8]
    e188: e1520003     	cmp	r2, r3
    e18c: 1a000002     	bne	0xe19c <validate_stdin+0x48> @ imm = #0x8
    e190: e3a03000     	mov	r3, #0
    e194: e50b3008     	str	r3, [r11, #-0x8]
    e198: ea000001     	b	0xe1a4 <validate_stdin+0x50> @ imm = #0x4
    e19c: e3e03000     	mvn	r3, #0
    e1a0: e50b3008     	str	r3, [r11, #-0x8]
    e1a4: e51b3008     	ldr	r3, [r11, #-0x8]
    e1a8: e1a00003     	mov	r0, r3
    e1ac: e24bd004     	sub	sp, r11, #4
    e1b0: e8bd8800     	pop	{r11, pc}

