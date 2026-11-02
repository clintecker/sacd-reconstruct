0000f414 <pb_message_set_to_defaults>:
    f414: e92d4800     	push	{r11, lr}
    f418: e28db004     	add	r11, sp, #4
    f41c: e24dd020     	sub	sp, sp, #32
    f420: e50b0020     	str	r0, [r11, #-0x20]
    f424: e50b1024     	str	r1, [r11, #-0x24]
    f428: e24b301c     	sub	r3, r11, #28
    f42c: e1a00003     	mov	r0, r3
    f430: e51b1020     	ldr	r1, [r11, #-0x20]
    f434: e51b2024     	ldr	r2, [r11, #-0x24]
    f438: ebfffe52     	bl	0xed88 <pb_field_init>  @ imm = #-0x6b8
    f43c: e51b3018     	ldr	r3, [r11, #-0x18]
    f440: e5d33000     	ldrb	r3, [r3]
    f444: e3530000     	cmp	r3, #0
    f448: 0a000056     	beq	0xf5a8 <pb_message_set_to_defaults+0x194> @ imm = #0x158
    f44c: e51b3018     	ldr	r3, [r11, #-0x18]
    f450: e5d33001     	ldrb	r3, [r3, #0x1]
    f454: e20330f0     	and	r3, r3, #240
    f458: e3530010     	cmp	r3, #16
    f45c: 1a000003     	bne	0xf470 <pb_message_set_to_defaults+0x5c> @ imm = #0xc
    f460: e51b3008     	ldr	r3, [r11, #-0x8]
    f464: e3a02000     	mov	r2, #0
    f468: e5c32000     	strb	r2, [r3]
    f46c: ea000008     	b	0xf494 <pb_message_set_to_defaults+0x80> @ imm = #0x20
    f470: e51b3018     	ldr	r3, [r11, #-0x18]
    f474: e5d33001     	ldrb	r3, [r3, #0x1]
    f478: e20330f0     	and	r3, r3, #240
    f47c: e3530020     	cmp	r3, #32
    f480: 1a000003     	bne	0xf494 <pb_message_set_to_defaults+0x80> @ imm = #0xc
    f484: e51b3008     	ldr	r3, [r11, #-0x8]
    f488: e3a02000     	mov	r2, #0
    f48c: e5832000     	str	r2, [r3]
    f490: ea000047     	b	0xf5b4 <pb_message_set_to_defaults+0x1a0> @ imm = #0x11c
    f494: e51b3018     	ldr	r3, [r11, #-0x18]
    f498: e5d33001     	ldrb	r3, [r3, #0x1]
    f49c: e20330f0     	and	r3, r3, #240
    f4a0: e3530030     	cmp	r3, #48
    f4a4: 0a000041     	beq	0xf5b0 <pb_message_set_to_defaults+0x19c> @ imm = #0x104
    f4a8: e51b3018     	ldr	r3, [r11, #-0x18]
    f4ac: e5d33001     	ldrb	r3, [r3, #0x1]
    f4b0: e203300f     	and	r3, r3, #15
    f4b4: e3530006     	cmp	r3, #6
    f4b8: 1a000010     	bne	0xf500 <pb_message_set_to_defaults+0xec> @ imm = #0x40
    f4bc: e51b3018     	ldr	r3, [r11, #-0x18]
    f4c0: e5d32009     	ldrb	r2, [r3, #0x9]
    f4c4: e5d3100a     	ldrb	r1, [r3, #0xa]
    f4c8: e1a01401     	lsl	r1, r1, #8
    f4cc: e1812002     	orr	r2, r1, r2
    f4d0: e5d3100b     	ldrb	r1, [r3, #0xb]
    f4d4: e1a01801     	lsl	r1, r1, #16
    f4d8: e1812002     	orr	r2, r1, r2
    f4dc: e5d3300c     	ldrb	r3, [r3, #0xc]
    f4e0: e1a03c03     	lsl	r3, r3, #24
    f4e4: e1833002     	orr	r3, r3, r2
    f4e8: e1a02003     	mov	r2, r3
    f4ec: e51b300c     	ldr	r3, [r11, #-0xc]
    f4f0: e1a00002     	mov	r0, r2
    f4f4: e1a01003     	mov	r1, r3
    f4f8: ebffffc5     	bl	0xf414 <pb_message_set_to_defaults> @ imm = #-0xec
    f4fc: ea00002c     	b	0xf5b4 <pb_message_set_to_defaults+0x1a0> @ imm = #0xb0
    f500: e51b3018     	ldr	r3, [r11, #-0x18]
    f504: e5d32009     	ldrb	r2, [r3, #0x9]
    f508: e5d3100a     	ldrb	r1, [r3, #0xa]
    f50c: e1a01401     	lsl	r1, r1, #8
    f510: e1812002     	orr	r2, r1, r2
    f514: e5d3100b     	ldrb	r1, [r3, #0xb]
    f518: e1a01801     	lsl	r1, r1, #16
    f51c: e1812002     	orr	r2, r1, r2
    f520: e5d3300c     	ldrb	r3, [r3, #0xc]
    f524: e1a03c03     	lsl	r3, r3, #24
    f528: e1833002     	orr	r3, r3, r2
    f52c: e3530000     	cmp	r3, #0
    f530: 0a00001f     	beq	0xf5b4 <pb_message_set_to_defaults+0x1a0> @ imm = #0x7c
    f534: e51b100c     	ldr	r1, [r11, #-0xc]
    f538: e51b3018     	ldr	r3, [r11, #-0x18]
    f53c: e5d32009     	ldrb	r2, [r3, #0x9]
    f540: e5d3000a     	ldrb	r0, [r3, #0xa]
    f544: e1a00400     	lsl	r0, r0, #8
    f548: e1802002     	orr	r2, r0, r2
    f54c: e5d3000b     	ldrb	r0, [r3, #0xb]
    f550: e1a00800     	lsl	r0, r0, #16
    f554: e1802002     	orr	r2, r0, r2
    f558: e5d3300c     	ldrb	r3, [r3, #0xc]
    f55c: e1a03c03     	lsl	r3, r3, #24
    f560: e1833002     	orr	r3, r3, r2
    f564: e1a02003     	mov	r2, r3
    f568: e51b3018     	ldr	r3, [r11, #-0x18]
    f56c: e5d30004     	ldrb	r0, [r3, #0x4]
    f570: e5d3c005     	ldrb	r12, [r3, #0x5]
    f574: e1a0c40c     	lsl	r12, r12, #8
    f578: e18c0000     	orr	r0, r12, r0
    f57c: e5d3c006     	ldrb	r12, [r3, #0x6]
    f580: e1a0c80c     	lsl	r12, r12, #16
    f584: e18c0000     	orr	r0, r12, r0
    f588: e5d33007     	ldrb	r3, [r3, #0x7]
    f58c: e1a03c03     	lsl	r3, r3, #24
    f590: e1833000     	orr	r3, r3, r0
    f594: e1a00001     	mov	r0, r1
    f598: e1a01002     	mov	r1, r2
    f59c: e1a02003     	mov	r2, r3
    f5a0: ebfff3d9     	bl	0xc50c <memcpy@plt>     @ imm = #-0x309c
    f5a4: ea000002     	b	0xf5b4 <pb_message_set_to_defaults+0x1a0> @ imm = #0x8
    f5a8: e1a00000     	mov	r0, r0
    f5ac: ea000000     	b	0xf5b4 <pb_message_set_to_defaults+0x1a0> @ imm = #0x0
    f5b0: e1a00000     	mov	r0, r0
    f5b4: e24b301c     	sub	r3, r11, #28
    f5b8: e1a00003     	mov	r0, r3
    f5bc: ebfffe17     	bl	0xee20 <pb_field_next>  @ imm = #-0x7a4
    f5c0: e1a03000     	mov	r3, r0
    f5c4: e3530000     	cmp	r3, #0
    f5c8: 1affff9b     	bne	0xf43c <pb_message_set_to_defaults+0x28> @ imm = #-0x194
    f5cc: e24bd004     	sub	sp, r11, #4
    f5d0: e8bd8800     	pop	{r11, pc}

