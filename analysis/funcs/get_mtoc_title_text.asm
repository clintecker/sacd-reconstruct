00022bac <get_mtoc_title_text>:
   22bac: e52db004     	str	r11, [sp, #-0x4]!
   22bb0: e28db000     	add	r11, sp, #0
   22bb4: e24dd014     	sub	sp, sp, #20
   22bb8: e50b0010     	str	r0, [r11, #-0x10]
   22bbc: e51b3010     	ldr	r3, [r11, #-0x10]
   22bc0: e2833010     	add	r3, r3, #16
   22bc4: e50b3008     	str	r3, [r11, #-0x8]
   22bc8: e51b3008     	ldr	r3, [r11, #-0x8]
   22bcc: e5933000     	ldr	r3, [r3]
   22bd0: e3530000     	cmp	r3, #0
   22bd4: 0a000002     	beq	0x22be4 <get_mtoc_title_text+0x38> @ imm = #0x8
   22bd8: e51b3008     	ldr	r3, [r11, #-0x8]
   22bdc: e5933000     	ldr	r3, [r3]
   22be0: ea000007     	b	0x22c04 <get_mtoc_title_text+0x58> @ imm = #0x1c
   22be4: e51b3008     	ldr	r3, [r11, #-0x8]
   22be8: e5933020     	ldr	r3, [r3, #0x20]
   22bec: e3530000     	cmp	r3, #0
   22bf0: 0a000002     	beq	0x22c00 <get_mtoc_title_text+0x54> @ imm = #0x8
   22bf4: e51b3008     	ldr	r3, [r11, #-0x8]
   22bf8: e5933020     	ldr	r3, [r3, #0x20]
   22bfc: ea000000     	b	0x22c04 <get_mtoc_title_text+0x58> @ imm = #0x0
   22c00: e59f300c     	ldr	r3, [pc, #0xc]          @ 0x22c14 <get_mtoc_title_text+0x68>
   22c04: e1a00003     	mov	r0, r3
   22c08: e28bd000     	add	sp, r11, #0
   22c0c: e8bd0800     	ldm	sp!, {r11}
   22c10: e12fff1e     	bx	lr
   22c14: 28 55 03 00  	.word	0x00035528

