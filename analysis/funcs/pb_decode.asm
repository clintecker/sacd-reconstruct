0000f5d4 <pb_decode>:
    f5d4: e92d4800     	push	{r11, lr}
    f5d8: e28db004     	add	r11, sp, #4
    f5dc: e24dd040     	sub	sp, sp, #64
    f5e0: e50b0038     	str	r0, [r11, #-0x38]
    f5e4: e50b103c     	str	r1, [r11, #-0x3c]
    f5e8: e50b2040     	str	r2, [r11, #-0x40]
    f5ec: e3a03000     	mov	r3, #0
    f5f0: e50b3014     	str	r3, [r11, #-0x14]
    f5f4: e51b003c     	ldr	r0, [r11, #-0x3c]
    f5f8: e51b1040     	ldr	r1, [r11, #-0x40]
    f5fc: ebffff84     	bl	0xf414 <pb_message_set_to_defaults> @ imm = #-0x1f0
    f600: e24b302c     	sub	r3, r11, #44
    f604: e1a00003     	mov	r0, r3
    f608: e51b103c     	ldr	r1, [r11, #-0x3c]
    f60c: e51b2040     	ldr	r2, [r11, #-0x40]
    f610: ebfffddc     	bl	0xed88 <pb_field_init>  @ imm = #-0x890
    f614: ea00003e     	b	0xf714 <pb_decode+0x140> @ imm = #0xf8
    f618: e24b3030     	sub	r3, r11, #48
    f61c: e51b0038     	ldr	r0, [r11, #-0x38]
    f620: e1a01003     	mov	r1, r3
    f624: ebfffcbe     	bl	0xe924 <pb_decode_varint32> @ imm = #-0xd08
    f628: e1a03000     	mov	r3, r0
    f62c: e2233001     	eor	r3, r3, #1
    f630: e6ef3073     	uxtb	r3, r3
    f634: e3530000     	cmp	r3, #0
    f638: 0a000005     	beq	0xf654 <pb_decode+0x80> @ imm = #0x14
    f63c: e51b3038     	ldr	r3, [r11, #-0x38]
    f640: e5933008     	ldr	r3, [r3, #0x8]
    f644: e3530000     	cmp	r3, #0
    f648: 0a000036     	beq	0xf728 <pb_decode+0x154> @ imm = #0xd8
    f64c: e3a03000     	mov	r3, #0
    f650: ea000060     	b	0xf7d8 <pb_decode+0x204> @ imm = #0x180
    f654: e51b3030     	ldr	r3, [r11, #-0x30]
    f658: e3530000     	cmp	r3, #0
    f65c: 0a000033     	beq	0xf730 <pb_decode+0x15c> @ imm = #0xcc
    f660: e51b3030     	ldr	r3, [r11, #-0x30]
    f664: e1a031a3     	lsr	r3, r3, #3
    f668: e50b300c     	str	r3, [r11, #-0xc]
    f66c: e51b3030     	ldr	r3, [r11, #-0x30]
    f670: e2033007     	and	r3, r3, #7
    f674: e50b3008     	str	r3, [r11, #-0x8]
    f678: e24b302c     	sub	r3, r11, #44
    f67c: e1a00003     	mov	r0, r3
    f680: e51b100c     	ldr	r1, [r11, #-0xc]
    f684: ebfffe3c     	bl	0xef7c <pb_field_find>  @ imm = #-0x710
    f688: e1a03000     	mov	r3, r0
    f68c: e2233001     	eor	r3, r3, #1
    f690: e6ef3073     	uxtb	r3, r3
    f694: e3530000     	cmp	r3, #0
    f698: 0a000009     	beq	0xf6c4 <pb_decode+0xf0> @ imm = #0x24
    f69c: e51b0038     	ldr	r0, [r11, #-0x38]
    f6a0: e51b1008     	ldr	r1, [r11, #-0x8]
    f6a4: ebfffd1b     	bl	0xeb18 <skip>           @ imm = #-0xb94
    f6a8: e1a03000     	mov	r3, r0
    f6ac: e2233001     	eor	r3, r3, #1
    f6b0: e6ef3073     	uxtb	r3, r3
    f6b4: e3530000     	cmp	r3, #0
    f6b8: 0a000014     	beq	0xf710 <pb_decode+0x13c> @ imm = #0x50
    f6bc: e3a03000     	mov	r3, #0
    f6c0: ea000044     	b	0xf7d8 <pb_decode+0x204> @ imm = #0x110
    f6c4: e51b3024     	ldr	r3, [r11, #-0x24]
    f6c8: e203301f     	and	r3, r3, #31
    f6cc: e3a02001     	mov	r2, #1
    f6d0: e1a03312     	lsl	r3, r2, r3
    f6d4: e51b2014     	ldr	r2, [r11, #-0x14]
    f6d8: e1823003     	orr	r3, r2, r3
    f6dc: e50b3014     	str	r3, [r11, #-0x14]
    f6e0: e24b302c     	sub	r3, r11, #44
    f6e4: e51b0038     	ldr	r0, [r11, #-0x38]
    f6e8: e51b1008     	ldr	r1, [r11, #-0x8]
    f6ec: e1a02003     	mov	r2, r3
    f6f0: ebfffe3d     	bl	0xefec <decode_field>   @ imm = #-0x70c
    f6f4: e1a03000     	mov	r3, r0
    f6f8: e2233001     	eor	r3, r3, #1
    f6fc: e6ef3073     	uxtb	r3, r3
    f700: e3530000     	cmp	r3, #0
    f704: 0a000002     	beq	0xf714 <pb_decode+0x140> @ imm = #0x8
    f708: e3a03000     	mov	r3, #0
    f70c: ea000031     	b	0xf7d8 <pb_decode+0x204> @ imm = #0xc4
    f710: e1a00000     	mov	r0, r0
    f714: e51b3038     	ldr	r3, [r11, #-0x38]
    f718: e5933008     	ldr	r3, [r3, #0x8]
    f71c: e3530000     	cmp	r3, #0
    f720: 1affffbc     	bne	0xf618 <pb_decode+0x44> @ imm = #-0x110
    f724: ea000002     	b	0xf734 <pb_decode+0x160> @ imm = #0x8
    f728: e1a00000     	mov	r0, r0
    f72c: ea000000     	b	0xf734 <pb_decode+0x160> @ imm = #0x0
    f730: e1a00000     	mov	r0, r0
    f734: e3a03000     	mov	r3, #0
    f738: e50b3010     	str	r3, [r11, #-0x10]
    f73c: ea000019     	b	0xf7a8 <pb_decode+0x1d4> @ imm = #0x64
    f740: e51b2010     	ldr	r2, [r11, #-0x10]
    f744: e1a03002     	mov	r3, r2
    f748: e1a03083     	lsl	r3, r3, #1
    f74c: e0833002     	add	r3, r3, r2
    f750: e1a03103     	lsl	r3, r3, #2
    f754: e0833002     	add	r3, r3, r2
    f758: e51b203c     	ldr	r2, [r11, #-0x3c]
    f75c: e0823003     	add	r3, r2, r3
    f760: e5d33001     	ldrb	r3, [r3, #0x1]
    f764: e20330f0     	and	r3, r3, #240
    f768: e3530000     	cmp	r3, #0
    f76c: 1a00000a     	bne	0xf79c <pb_decode+0x1c8> @ imm = #0x28
    f770: e51b3010     	ldr	r3, [r11, #-0x10]
    f774: e203301f     	and	r3, r3, #31
    f778: e3a02001     	mov	r2, #1
    f77c: e1a03312     	lsl	r3, r2, r3
    f780: e1a02003     	mov	r2, r3
    f784: e51b3014     	ldr	r3, [r11, #-0x14]
    f788: e0023003     	and	r3, r2, r3
    f78c: e3530000     	cmp	r3, #0
    f790: 1a000001     	bne	0xf79c <pb_decode+0x1c8> @ imm = #0x4
    f794: e3a03000     	mov	r3, #0
    f798: ea00000e     	b	0xf7d8 <pb_decode+0x204> @ imm = #0x38
    f79c: e51b3010     	ldr	r3, [r11, #-0x10]
    f7a0: e2833001     	add	r3, r3, #1
    f7a4: e50b3010     	str	r3, [r11, #-0x10]
    f7a8: e51b2010     	ldr	r2, [r11, #-0x10]
    f7ac: e1a03002     	mov	r3, r2
    f7b0: e1a03083     	lsl	r3, r3, #1
    f7b4: e0833002     	add	r3, r3, r2
    f7b8: e1a03103     	lsl	r3, r3, #2
    f7bc: e0833002     	add	r3, r3, r2
    f7c0: e51b203c     	ldr	r2, [r11, #-0x3c]
    f7c4: e0823003     	add	r3, r2, r3
    f7c8: e5d33000     	ldrb	r3, [r3]
    f7cc: e3530000     	cmp	r3, #0
    f7d0: 1affffda     	bne	0xf740 <pb_decode+0x16c> @ imm = #-0x98
    f7d4: e3a03001     	mov	r3, #1
    f7d8: e1a00003     	mov	r0, r3
    f7dc: e24bd004     	sub	sp, r11, #4
    f7e0: e8bd8800     	pop	{r11, pc}

