000227a0 <sacd_net_input_read>:
   227a0: e92d4800     	push	{r11, lr}
   227a4: e28db004     	add	r11, sp, #4
   227a8: e24dd080     	sub	sp, sp, #128
   227ac: e50b0070     	str	r0, [r11, #-0x70]
   227b0: e50b1074     	str	r1, [r11, #-0x74]
   227b4: e50b2078     	str	r2, [r11, #-0x78]
   227b8: e50b307c     	str	r3, [r11, #-0x7c]
   227bc: e51b3070     	ldr	r3, [r11, #-0x70]
   227c0: e3530000     	cmp	r3, #0
   227c4: 1a000001     	bne	0x227d0 <sacd_net_input_read+0x30> @ imm = #0x4
   227c8: e3a03000     	mov	r3, #0
   227cc: ea00005b     	b	0x22940 <sacd_net_input_read+0x1a0> @ imm = #0x16c
   227d0: e24b2034     	sub	r2, r11, #52
   227d4: e24b3018     	sub	r3, r11, #24
   227d8: e1a00002     	mov	r0, r2
   227dc: e1a01003     	mov	r1, r3
   227e0: e3a02010     	mov	r2, #16
   227e4: ebffbb94     	bl	0x1163c <pb_ostream_from_buffer> @ imm = #-0x111b0
   227e8: e51b3070     	ldr	r3, [r11, #-0x70]
   227ec: e24b2040     	sub	r2, r11, #64
   227f0: e1a00002     	mov	r0, r2
   227f4: e1a01003     	mov	r1, r3
   227f8: ebfff800     	bl	0x20800 <pb_istream_from_socket> @ imm = #-0x2000
   227fc: e3a03000     	mov	r3, #0
   22800: e54b3041     	strb	r3, [r11, #-0x41]
   22804: e3a03003     	mov	r3, #3
   22808: e50b3024     	str	r3, [r11, #-0x24]
   2280c: e51b3074     	ldr	r3, [r11, #-0x74]
   22810: e50b3020     	str	r3, [r11, #-0x20]
   22814: e51b3078     	ldr	r3, [r11, #-0x78]
   22818: e50b301c     	str	r3, [r11, #-0x1c]
   2281c: e24b2034     	sub	r2, r11, #52
   22820: e24b3024     	sub	r3, r11, #36
   22824: e1a00002     	mov	r0, r2
   22828: e59f111c     	ldr	r1, [pc, #0x11c]        @ 0x2294c <sacd_net_input_read+0x1ac>
   2282c: e1a02003     	mov	r2, r3
   22830: ebffbc95     	bl	0x11a8c <pb_encode>     @ imm = #-0x10dac
   22834: e1a03000     	mov	r3, r0
   22838: e2233001     	eor	r3, r3, #1
   2283c: e6ef3073     	uxtb	r3, r3
   22840: e3530000     	cmp	r3, #0
   22844: 0a000001     	beq	0x22850 <sacd_net_input_read+0xb0> @ imm = #0x4
   22848: e3a03000     	mov	r3, #0
   2284c: ea00003b     	b	0x22940 <sacd_net_input_read+0x1a0> @ imm = #0xec
   22850: e24b2034     	sub	r2, r11, #52
   22854: e24b3041     	sub	r3, r11, #65
   22858: e1a00002     	mov	r0, r2
   2285c: e1a01003     	mov	r1, r3
   22860: e3a02001     	mov	r2, #1
   22864: ebffbb8b     	bl	0x11698 <pb_write>      @ imm = #-0x111d4
   22868: e51b0070     	ldr	r0, [r11, #-0x70]
   2286c: e51b2028     	ldr	r2, [r11, #-0x28]
   22870: e24b1018     	sub	r1, r11, #24
   22874: e24b3048     	sub	r3, r11, #72
   22878: e3a0c000     	mov	r12, #0
   2287c: e58dc000     	str	r12, [sp]
   22880: e3a0c000     	mov	r12, #0
   22884: e58dc004     	str	r12, [sp, #0x4]
   22888: ebffc188     	bl	0x12eb0 <socket_send>   @ imm = #-0xf9e0
   2288c: e1a03000     	mov	r3, r0
   22890: e3530000     	cmp	r3, #0
   22894: 1a000005     	bne	0x228b0 <sacd_net_input_read+0x110> @ imm = #0x14
   22898: e51b2028     	ldr	r2, [r11, #-0x28]
   2289c: e51b3048     	ldr	r3, [r11, #-0x48]
   228a0: e1520003     	cmp	r2, r3
   228a4: 1a000001     	bne	0x228b0 <sacd_net_input_read+0x110> @ imm = #0x4
   228a8: e3a03001     	mov	r3, #1
   228ac: ea000000     	b	0x228b4 <sacd_net_input_read+0x114> @ imm = #0x0
   228b0: e3a03000     	mov	r3, #0
   228b4: e54b3005     	strb	r3, [r11, #-0x5]
   228b8: e55b3005     	ldrb	r3, [r11, #-0x5]
   228bc: e2233001     	eor	r3, r3, #1
   228c0: e6ef3073     	uxtb	r3, r3
   228c4: e3530000     	cmp	r3, #0
   228c8: 0a000001     	beq	0x228d4 <sacd_net_input_read+0x134> @ imm = #0x4
   228cc: e3a03000     	mov	r3, #0
   228d0: ea00001a     	b	0x22940 <sacd_net_input_read+0x1a0> @ imm = #0x68
   228d4: e51b307c     	ldr	r3, [r11, #-0x7c]
   228d8: e50b3054     	str	r3, [r11, #-0x54]
   228dc: e24b2040     	sub	r2, r11, #64
   228e0: e24b306c     	sub	r3, r11, #108
   228e4: e1a00002     	mov	r0, r2
   228e8: e59f1060     	ldr	r1, [pc, #0x60]         @ 0x22950 <sacd_net_input_read+0x1b0>
   228ec: e1a02003     	mov	r2, r3
   228f0: ebffb337     	bl	0xf5d4 <pb_decode>      @ imm = #-0x13324
   228f4: e1a03000     	mov	r3, r0
   228f8: e2233001     	eor	r3, r3, #1
   228fc: e6ef3073     	uxtb	r3, r3
   22900: e3530000     	cmp	r3, #0
   22904: 0a000001     	beq	0x22910 <sacd_net_input_read+0x170> @ imm = #0x4
   22908: e3a03000     	mov	r3, #0
   2290c: ea00000b     	b	0x22940 <sacd_net_input_read+0x1a0> @ imm = #0x2c
   22910: e51b306c     	ldr	r3, [r11, #-0x6c]
   22914: e3530003     	cmp	r3, #3
   22918: 0a000001     	beq	0x22924 <sacd_net_input_read+0x184> @ imm = #0x4
   2291c: e3a03000     	mov	r3, #0
   22920: ea000006     	b	0x22940 <sacd_net_input_read+0x1a0> @ imm = #0x18
   22924: e55b305c     	ldrb	r3, [r11, #-0x5c]
   22928: e3530000     	cmp	r3, #0
   2292c: 0a000002     	beq	0x2293c <sacd_net_input_read+0x19c> @ imm = #0x8
   22930: e14b26d4     	ldrd	r2, r3, [r11, #-100]
   22934: e1a03002     	mov	r3, r2
   22938: ea000000     	b	0x22940 <sacd_net_input_read+0x1a0> @ imm = #0x0
   2293c: e3a03000     	mov	r3, #0
   22940: e1a00003     	mov	r0, r3
   22944: e24bd004     	sub	sp, r11, #4
   22948: e8bd8800     	pop	{r11, pc}
   2294c: 90 52 03 00  	.word	0x00035290
   22950: c4 52 03 00  	.word	0x000352c4

