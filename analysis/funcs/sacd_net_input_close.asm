00022538 <sacd_net_input_close>:
   22538: e92d4800     	push	{r11, lr}
   2253c: e28db004     	add	r11, sp, #4
   22540: e24dd058     	sub	sp, sp, #88
   22544: e50b0058     	str	r0, [r11, #-0x58]
   22548: e51b3058     	ldr	r3, [r11, #-0x58]
   2254c: e3530000     	cmp	r3, #0
   22550: 1a000001     	bne	0x2255c <sacd_net_input_close+0x24> @ imm = #0x4
   22554: e3a03000     	mov	r3, #0
   22558: ea000048     	b	0x22680 <sacd_net_input_close+0x148> @ imm = #0x120
   2255c: e51b3058     	ldr	r3, [r11, #-0x58]
   22560: e24b201c     	sub	r2, r11, #28
   22564: e1a00002     	mov	r0, r2
   22568: e1a01003     	mov	r1, r3
   2256c: ebfff8a3     	bl	0x20800 <pb_istream_from_socket> @ imm = #-0x1d74
   22570: e51b3058     	ldr	r3, [r11, #-0x58]
   22574: e24b202c     	sub	r2, r11, #44
   22578: e1a00002     	mov	r0, r2
   2257c: e1a01003     	mov	r1, r3
   22580: ebfff888     	bl	0x207a8 <pb_ostream_from_socket> @ imm = #-0x1de0
   22584: e3a03000     	mov	r3, #0
   22588: e54b302d     	strb	r3, [r11, #-0x2d]
   2258c: e3a03002     	mov	r3, #2
   22590: e50b3010     	str	r3, [r11, #-0x10]
   22594: e24b202c     	sub	r2, r11, #44
   22598: e24b3010     	sub	r3, r11, #16
   2259c: e1a00002     	mov	r0, r2
   225a0: e59f10e4     	ldr	r1, [pc, #0xe4]         @ 0x2268c <sacd_net_input_close+0x154>
   225a4: e1a02003     	mov	r2, r3
   225a8: ebffbd37     	bl	0x11a8c <pb_encode>     @ imm = #-0x10b24
   225ac: e1a03000     	mov	r3, r0
   225b0: e2233001     	eor	r3, r3, #1
   225b4: e6ef3073     	uxtb	r3, r3
   225b8: e3530000     	cmp	r3, #0
   225bc: 1a000015     	bne	0x22618 <sacd_net_input_close+0xe0> @ imm = #0x54
   225c0: e24b202c     	sub	r2, r11, #44
   225c4: e24b302d     	sub	r3, r11, #45
   225c8: e1a00002     	mov	r0, r2
   225cc: e1a01003     	mov	r1, r3
   225d0: e3a02001     	mov	r2, #1
   225d4: ebffbc2f     	bl	0x11698 <pb_write>      @ imm = #-0x10f44
   225d8: e24b201c     	sub	r2, r11, #28
   225dc: e24b3054     	sub	r3, r11, #84
   225e0: e1a00002     	mov	r0, r2
   225e4: e59f10a4     	ldr	r1, [pc, #0xa4]         @ 0x22690 <sacd_net_input_close+0x158>
   225e8: e1a02003     	mov	r2, r3
   225ec: ebffb3f8     	bl	0xf5d4 <pb_decode>      @ imm = #-0x13020
   225f0: e1a03000     	mov	r3, r0
   225f4: e2233001     	eor	r3, r3, #1
   225f8: e6ef3073     	uxtb	r3, r3
   225fc: e3530000     	cmp	r3, #0
   22600: 1a000006     	bne	0x22620 <sacd_net_input_close+0xe8> @ imm = #0x18
   22604: e14b04dc     	ldrd	r0, r1, [r11, #-76]
   22608: e1a03000     	mov	r3, r0
   2260c: e1833001     	orr	r3, r3, r1
   22610: e3530000     	cmp	r3, #0
   22614: ea000002     	b	0x22624 <sacd_net_input_close+0xec> @ imm = #0x8
   22618: e1a00000     	mov	r0, r0
   2261c: ea000000     	b	0x22624 <sacd_net_input_close+0xec> @ imm = #0x0
   22620: e1a00000     	mov	r0, r0
   22624: e51b3058     	ldr	r3, [r11, #-0x58]
   22628: e3530000     	cmp	r3, #0
   2262c: 0a000012     	beq	0x2267c <sacd_net_input_close+0x144> @ imm = #0x48
   22630: e51b3058     	ldr	r3, [r11, #-0x58]
   22634: e1a00003     	mov	r0, r3
   22638: ebffc0b8     	bl	0x12920 <socket_destroy> @ imm = #-0xfd20
   2263c: ebffc0b0     	bl	0x12904 <socket_close>  @ imm = #-0xfd40
   22640: e51b3058     	ldr	r3, [r11, #-0x58]
   22644: e5933004     	ldr	r3, [r3, #0x4]
   22648: e3530000     	cmp	r3, #0
   2264c: 0a000006     	beq	0x2266c <sacd_net_input_close+0x134> @ imm = #0x18
   22650: e51b3058     	ldr	r3, [r11, #-0x58]
   22654: e5933004     	ldr	r3, [r3, #0x4]
   22658: e1a00003     	mov	r0, r3
   2265c: ebffa76e     	bl	0xc41c <free@plt>       @ imm = #-0x16248
   22660: e51b3058     	ldr	r3, [r11, #-0x58]
   22664: e3a02000     	mov	r2, #0
   22668: e5832004     	str	r2, [r3, #0x4]
   2266c: e51b0058     	ldr	r0, [r11, #-0x58]
   22670: ebffa769     	bl	0xc41c <free@plt>       @ imm = #-0x1625c
   22674: e3a03000     	mov	r3, #0
   22678: e50b3058     	str	r3, [r11, #-0x58]
   2267c: e3a03000     	mov	r3, #0
   22680: e1a00003     	mov	r0, r3
   22684: e24bd004     	sub	sp, r11, #4
   22688: e8bd8800     	pop	{r11, pc}
   2268c: 90 52 03 00  	.word	0x00035290
   22690: c4 52 03 00  	.word	0x000352c4

