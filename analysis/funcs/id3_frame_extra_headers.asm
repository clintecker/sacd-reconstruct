0001ca60 <id3_frame_extra_headers>:
   1ca60: e52db004     	str	r11, [sp, #-0x4]!
   1ca64: e28db000     	add	r11, sp, #0
   1ca68: e24dd014     	sub	sp, sp, #20
   1ca6c: e50b0010     	str	r0, [r11, #-0x10]
   1ca70: e3a03000     	mov	r3, #0
   1ca74: e50b3008     	str	r3, [r11, #-0x8]
   1ca78: e51b3010     	ldr	r3, [r11, #-0x10]
   1ca7c: e5933008     	ldr	r3, [r3, #0x8]
   1ca80: e2033080     	and	r3, r3, #128
   1ca84: e3530000     	cmp	r3, #0
   1ca88: 0a000002     	beq	0x1ca98 <id3_frame_extra_headers+0x38> @ imm = #0x8
   1ca8c: e51b3008     	ldr	r3, [r11, #-0x8]
   1ca90: e2833004     	add	r3, r3, #4
   1ca94: e50b3008     	str	r3, [r11, #-0x8]
   1ca98: e51b3010     	ldr	r3, [r11, #-0x10]
   1ca9c: e5933008     	ldr	r3, [r3, #0x8]
   1caa0: e2033040     	and	r3, r3, #64
   1caa4: e3530000     	cmp	r3, #0
   1caa8: 0a000002     	beq	0x1cab8 <id3_frame_extra_headers+0x58> @ imm = #0x8
   1caac: e51b3008     	ldr	r3, [r11, #-0x8]
   1cab0: e2833001     	add	r3, r3, #1
   1cab4: e50b3008     	str	r3, [r11, #-0x8]
   1cab8: e51b3010     	ldr	r3, [r11, #-0x10]
   1cabc: e5933008     	ldr	r3, [r3, #0x8]
   1cac0: e2033020     	and	r3, r3, #32
   1cac4: e3530000     	cmp	r3, #0
   1cac8: 0a000002     	beq	0x1cad8 <id3_frame_extra_headers+0x78> @ imm = #0x8
   1cacc: e51b3008     	ldr	r3, [r11, #-0x8]
   1cad0: e2833001     	add	r3, r3, #1
   1cad4: e50b3008     	str	r3, [r11, #-0x8]
   1cad8: e51b3008     	ldr	r3, [r11, #-0x8]
   1cadc: e1a00003     	mov	r0, r3
   1cae0: e28bd000     	add	sp, r11, #0
   1cae4: e8bd0800     	ldm	sp!, {r11}
   1cae8: e12fff1e     	bx	lr

