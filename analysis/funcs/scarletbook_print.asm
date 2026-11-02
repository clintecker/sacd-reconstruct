00020514 <scarletbook_print>:
   20514: e92d4800     	push	{r11, lr}
   20518: e28db004     	add	r11, sp, #4
   2051c: e24dd010     	sub	sp, sp, #16
   20520: e50b0010     	str	r0, [r11, #-0x10]
   20524: e51b3010     	ldr	r3, [r11, #-0x10]
   20528: e3530000     	cmp	r3, #0
   2052c: 1a000007     	bne	0x20550 <scarletbook_print+0x3c> @ imm = #0x1c
   20530: e59f20a8     	ldr	r2, [pc, #0xa8]         @ 0x205e0 <scarletbook_print+0xcc>
   20534: e59f30a8     	ldr	r3, [pc, #0xa8]         @ 0x205e4 <scarletbook_print+0xd0>
   20538: e5933000     	ldr	r3, [r3]
   2053c: e1a00002     	mov	r0, r2
   20540: e3a01001     	mov	r1, #1
   20544: e3a02026     	mov	r2, #38
   20548: ebffb028     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x13f60
   2054c: ea000021     	b	0x205d8 <scarletbook_print+0xc4> @ imm = #0x84
   20550: e51b3010     	ldr	r3, [r11, #-0x10]
   20554: e5933008     	ldr	r3, [r3, #0x8]
   20558: e3530000     	cmp	r3, #0
   2055c: 0a000001     	beq	0x20568 <scarletbook_print+0x54> @ imm = #0x4
   20560: e51b0010     	ldr	r0, [r11, #-0x10]
   20564: ebfffc82     	bl	0x1f774 <scarletbook_print_master_toc> @ imm = #-0xdf8
   20568: e59f3078     	ldr	r3, [pc, #0x78]         @ 0x205e8 <scarletbook_print+0xd4>
   2056c: e5933000     	ldr	r3, [r3]
   20570: e1a01003     	mov	r1, r3
   20574: e59f2070     	ldr	r2, [pc, #0x70]         @ 0x205ec <scarletbook_print+0xd8>
   20578: e51b3010     	ldr	r3, [r11, #-0x10]
   2057c: e5933058     	ldr	r3, [r3, #0x58]
   20580: e1a00001     	mov	r0, r1
   20584: e1a01002     	mov	r1, r2
   20588: e1a02003     	mov	r2, r3
   2058c: ebffb05c     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13e90
   20590: e51b3010     	ldr	r3, [r11, #-0x10]
   20594: e5933058     	ldr	r3, [r3, #0x58]
   20598: e3530000     	cmp	r3, #0
   2059c: da00000d     	ble	0x205d8 <scarletbook_print+0xc4> @ imm = #0x34
   205a0: e3a03000     	mov	r3, #0
   205a4: e50b3008     	str	r3, [r11, #-0x8]
   205a8: ea000005     	b	0x205c4 <scarletbook_print+0xb0> @ imm = #0x14
   205ac: e51b0010     	ldr	r0, [r11, #-0x10]
   205b0: e51b1008     	ldr	r1, [r11, #-0x8]
   205b4: ebfffe8f     	bl	0x1fff8 <scarletbook_print_area_toc> @ imm = #-0x5c4
   205b8: e51b3008     	ldr	r3, [r11, #-0x8]
   205bc: e2833001     	add	r3, r3, #1
   205c0: e50b3008     	str	r3, [r11, #-0x8]
   205c4: e51b3010     	ldr	r3, [r11, #-0x10]
   205c8: e5932058     	ldr	r2, [r3, #0x58]
   205cc: e51b3008     	ldr	r3, [r11, #-0x8]
   205d0: e1520003     	cmp	r2, r3
   205d4: cafffff4     	bgt	0x205ac <scarletbook_print+0x98> @ imm = #-0x30
   205d8: e24bd004     	sub	sp, r11, #4
   205dc: e8bd8800     	pop	{r11, pc}
   205e0: 04 49 03 00  	.word	0x00034904
   205e4: f8 6d 05 00  	.word	0x00056df8
   205e8: f4 6d 05 00  	.word	0x00056df4
   205ec: 2c 49 03 00  	.word	0x0003492c

