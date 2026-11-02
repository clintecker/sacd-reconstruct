00011eb0 <pb_encode_tag_for_field>:
   11eb0: e92d4800     	push	{r11, lr}
   11eb4: e28db004     	add	r11, sp, #4
   11eb8: e24dd010     	sub	sp, sp, #16
   11ebc: e50b0010     	str	r0, [r11, #-0x10]
   11ec0: e50b1014     	str	r1, [r11, #-0x14]
   11ec4: e51b3014     	ldr	r3, [r11, #-0x14]
   11ec8: e5d33001     	ldrb	r3, [r3, #0x1]
   11ecc: e203300f     	and	r3, r3, #15
   11ed0: e3530006     	cmp	r3, #6
   11ed4: 979ff103     	ldrls	pc, [pc, r3, lsl #2]
   11ed8: ea000012     	b	0x11f28 <pb_encode_tag_for_field+0x78> @ imm = #0x48
   11edc: f8 1e 01 00  	.word	0x00011ef8
   11ee0: f8 1e 01 00  	.word	0x00011ef8
   11ee4: 04 1f 01 00  	.word	0x00011f04
   11ee8: 10 1f 01 00  	.word	0x00011f10
   11eec: 1c 1f 01 00  	.word	0x00011f1c
   11ef0: 1c 1f 01 00  	.word	0x00011f1c
   11ef4: 1c 1f 01 00  	.word	0x00011f1c
   11ef8: e3a03000     	mov	r3, #0
   11efc: e50b3008     	str	r3, [r11, #-0x8]
   11f00: ea00000a     	b	0x11f30 <pb_encode_tag_for_field+0x80> @ imm = #0x28
   11f04: e3a03005     	mov	r3, #5
   11f08: e50b3008     	str	r3, [r11, #-0x8]
   11f0c: ea000007     	b	0x11f30 <pb_encode_tag_for_field+0x80> @ imm = #0x1c
   11f10: e3a03001     	mov	r3, #1
   11f14: e50b3008     	str	r3, [r11, #-0x8]
   11f18: ea000004     	b	0x11f30 <pb_encode_tag_for_field+0x80> @ imm = #0x10
   11f1c: e3a03002     	mov	r3, #2
   11f20: e50b3008     	str	r3, [r11, #-0x8]
   11f24: ea000001     	b	0x11f30 <pb_encode_tag_for_field+0x80> @ imm = #0x4
   11f28: e3a03000     	mov	r3, #0
   11f2c: ea000006     	b	0x11f4c <pb_encode_tag_for_field+0x9c> @ imm = #0x18
   11f30: e51b3014     	ldr	r3, [r11, #-0x14]
   11f34: e5d33000     	ldrb	r3, [r3]
   11f38: e51b0010     	ldr	r0, [r11, #-0x10]
   11f3c: e51b1008     	ldr	r1, [r11, #-0x8]
   11f40: e1a02003     	mov	r2, r3
   11f44: ebffffc4     	bl	0x11e5c <pb_encode_tag> @ imm = #-0xf0
   11f48: e1a03000     	mov	r3, r0
   11f4c: e1a00003     	mov	r0, r3
   11f50: e24bd004     	sub	sp, r11, #4
   11f54: e8bd8800     	pop	{r11, pc}

