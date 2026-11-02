00022694 <sacd_net_input_total_sectors>:
   22694: e92d4800     	push	{r11, lr}
   22698: e28db004     	add	r11, sp, #4
   2269c: e24dd058     	sub	sp, sp, #88
   226a0: e50b0058     	str	r0, [r11, #-0x58]
   226a4: e51b3058     	ldr	r3, [r11, #-0x58]
   226a8: e3530000     	cmp	r3, #0
   226ac: 1a000001     	bne	0x226b8 <sacd_net_input_total_sectors+0x24> @ imm = #0x4
   226b0: e3a03000     	mov	r3, #0
   226b4: ea000034     	b	0x2278c <sacd_net_input_total_sectors+0xf8> @ imm = #0xd0
   226b8: e51b3058     	ldr	r3, [r11, #-0x58]
   226bc: e24b201c     	sub	r2, r11, #28
   226c0: e1a00002     	mov	r0, r2
   226c4: e1a01003     	mov	r1, r3
   226c8: ebfff84c     	bl	0x20800 <pb_istream_from_socket> @ imm = #-0x1ed0
   226cc: e51b3058     	ldr	r3, [r11, #-0x58]
   226d0: e24b202c     	sub	r2, r11, #44
   226d4: e1a00002     	mov	r0, r2
   226d8: e1a01003     	mov	r1, r3
   226dc: ebfff831     	bl	0x207a8 <pb_ostream_from_socket> @ imm = #-0x1f3c
   226e0: e3a03000     	mov	r3, #0
   226e4: e54b302d     	strb	r3, [r11, #-0x2d]
   226e8: e3a03004     	mov	r3, #4
   226ec: e50b3010     	str	r3, [r11, #-0x10]
   226f0: e24b202c     	sub	r2, r11, #44
   226f4: e24b3010     	sub	r3, r11, #16
   226f8: e1a00002     	mov	r0, r2
   226fc: e59f1094     	ldr	r1, [pc, #0x94]         @ 0x22798 <sacd_net_input_total_sectors+0x104>
   22700: e1a02003     	mov	r2, r3
   22704: ebffbce0     	bl	0x11a8c <pb_encode>     @ imm = #-0x10c80
   22708: e1a03000     	mov	r3, r0
   2270c: e2233001     	eor	r3, r3, #1
   22710: e6ef3073     	uxtb	r3, r3
   22714: e3530000     	cmp	r3, #0
   22718: 0a000001     	beq	0x22724 <sacd_net_input_total_sectors+0x90> @ imm = #0x4
   2271c: e3a03000     	mov	r3, #0
   22720: ea000019     	b	0x2278c <sacd_net_input_total_sectors+0xf8> @ imm = #0x64
   22724: e24b202c     	sub	r2, r11, #44
   22728: e24b302d     	sub	r3, r11, #45
   2272c: e1a00002     	mov	r0, r2
   22730: e1a01003     	mov	r1, r3
   22734: e3a02001     	mov	r2, #1
   22738: ebffbbd6     	bl	0x11698 <pb_write>      @ imm = #-0x110a8
   2273c: e24b201c     	sub	r2, r11, #28
   22740: e24b3054     	sub	r3, r11, #84
   22744: e1a00002     	mov	r0, r2
   22748: e59f104c     	ldr	r1, [pc, #0x4c]         @ 0x2279c <sacd_net_input_total_sectors+0x108>
   2274c: e1a02003     	mov	r2, r3
   22750: ebffb39f     	bl	0xf5d4 <pb_decode>      @ imm = #-0x13184
   22754: e1a03000     	mov	r3, r0
   22758: e2233001     	eor	r3, r3, #1
   2275c: e6ef3073     	uxtb	r3, r3
   22760: e3530000     	cmp	r3, #0
   22764: 0a000001     	beq	0x22770 <sacd_net_input_total_sectors+0xdc> @ imm = #0x4
   22768: e3a03000     	mov	r3, #0
   2276c: ea000006     	b	0x2278c <sacd_net_input_total_sectors+0xf8> @ imm = #0x18
   22770: e51b3054     	ldr	r3, [r11, #-0x54]
   22774: e3530004     	cmp	r3, #4
   22778: 0a000001     	beq	0x22784 <sacd_net_input_total_sectors+0xf0> @ imm = #0x4
   2277c: e3a03000     	mov	r3, #0
   22780: ea000001     	b	0x2278c <sacd_net_input_total_sectors+0xf8> @ imm = #0x4
   22784: e14b24dc     	ldrd	r2, r3, [r11, #-76]
   22788: e1a03002     	mov	r3, r2
   2278c: e1a00003     	mov	r0, r3
   22790: e24bd004     	sub	sp, r11, #4
   22794: e8bd8800     	pop	{r11, pc}
   22798: 90 52 03 00  	.word	0x00035290
   2279c: c4 52 03 00  	.word	0x000352c4

