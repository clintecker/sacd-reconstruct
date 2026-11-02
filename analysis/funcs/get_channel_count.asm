0002dd64 <get_channel_count>:
   2dd64: e52db004     	str	r11, [sp, #-0x4]!
   2dd68: e28db000     	add	r11, sp, #0
   2dd6c: e24dd00c     	sub	sp, sp, #12
   2dd70: e50b0008     	str	r0, [r11, #-0x8]
   2dd74: e51b3008     	ldr	r3, [r11, #-0x8]
   2dd78: e5d33003     	ldrb	r3, [r3, #0x3]
   2dd7c: e2033002     	and	r3, r3, #2
   2dd80: e3530000     	cmp	r3, #0
   2dd84: 0a000006     	beq	0x2dda4 <get_channel_count+0x40> @ imm = #0x18
   2dd88: e51b3008     	ldr	r3, [r11, #-0x8]
   2dd8c: e5d33003     	ldrb	r3, [r3, #0x3]
   2dd90: e2033001     	and	r3, r3, #1
   2dd94: e3530000     	cmp	r3, #0
   2dd98: 1a000001     	bne	0x2dda4 <get_channel_count+0x40> @ imm = #0x4
   2dd9c: e3a03006     	mov	r3, #6
   2dda0: ea00000c     	b	0x2ddd8 <get_channel_count+0x74> @ imm = #0x30
   2dda4: e51b3008     	ldr	r3, [r11, #-0x8]
   2dda8: e5d33003     	ldrb	r3, [r3, #0x3]
   2ddac: e2033002     	and	r3, r3, #2
   2ddb0: e3530000     	cmp	r3, #0
   2ddb4: 1a000006     	bne	0x2ddd4 <get_channel_count+0x70> @ imm = #0x18
   2ddb8: e51b3008     	ldr	r3, [r11, #-0x8]
   2ddbc: e5d33003     	ldrb	r3, [r3, #0x3]
   2ddc0: e2033001     	and	r3, r3, #1
   2ddc4: e3530000     	cmp	r3, #0
   2ddc8: 0a000001     	beq	0x2ddd4 <get_channel_count+0x70> @ imm = #0x4
   2ddcc: e3a03005     	mov	r3, #5
   2ddd0: ea000000     	b	0x2ddd8 <get_channel_count+0x74> @ imm = #0x0
   2ddd4: e3a03002     	mov	r3, #2
   2ddd8: e1a00003     	mov	r0, r3
   2dddc: e28bd000     	add	sp, r11, #0
   2dde0: e8bd0800     	ldm	sp!, {r11}
   2dde4: e12fff1e     	bx	lr

