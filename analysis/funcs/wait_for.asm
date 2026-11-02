000158dc <wait_for>:
   158dc: e92d4800     	push	{r11, lr}
   158e0: e28db004     	add	r11, sp, #4
   158e4: e24dd018     	sub	sp, sp, #24
   158e8: e50b0010     	str	r0, [r11, #-0x10]
   158ec: e50b1014     	str	r1, [r11, #-0x14]
   158f0: e50b2018     	str	r2, [r11, #-0x18]
   158f4: e51b3014     	ldr	r3, [r11, #-0x14]
   158f8: e3530003     	cmp	r3, #3
   158fc: 979ff103     	ldrls	pc, [pc, r3, lsl #2]
   15900: ea00004e     	b	0x15a40 <wait_for+0x164> @ imm = #0x138
   15904: 48 59 01 00  	.word	0x00015948
   15908: 94 59 01 00  	.word	0x00015994
   1590c: e0 59 01 00  	.word	0x000159e0
   15910: 2c 5a 01 00  	.word	0x00015a2c
   15914: e51b3010     	ldr	r3, [r11, #-0x10]
   15918: e2832018     	add	r2, r3, #24
   1591c: e51b3010     	ldr	r3, [r11, #-0x10]
   15920: e1a00002     	mov	r0, r2
   15924: e1a01003     	mov	r1, r3
   15928: ebffda91     	bl	0xc374 <pthread_cond_wait@plt> @ imm = #-0x95bc
   1592c: e1a03000     	mov	r3, r0
   15930: e50b3008     	str	r3, [r11, #-0x8]
   15934: e51b3008     	ldr	r3, [r11, #-0x8]
   15938: e3530000     	cmp	r3, #0
   1593c: 0a000001     	beq	0x15948 <wait_for+0x6c> @ imm = #0x4
   15940: e51b0008     	ldr	r0, [r11, #-0x8]
   15944: ebffff25     	bl	0x155e0 <fail>          @ imm = #-0x36c
   15948: e51b3010     	ldr	r3, [r11, #-0x10]
   1594c: e5932048     	ldr	r2, [r3, #0x48]
   15950: e51b3018     	ldr	r3, [r11, #-0x18]
   15954: e1520003     	cmp	r2, r3
   15958: 1affffed     	bne	0x15914 <wait_for+0x38> @ imm = #-0x4c
   1595c: ea000037     	b	0x15a40 <wait_for+0x164> @ imm = #0xdc
   15960: e51b3010     	ldr	r3, [r11, #-0x10]
   15964: e2832018     	add	r2, r3, #24
   15968: e51b3010     	ldr	r3, [r11, #-0x10]
   1596c: e1a00002     	mov	r0, r2
   15970: e1a01003     	mov	r1, r3
   15974: ebffda7e     	bl	0xc374 <pthread_cond_wait@plt> @ imm = #-0x9608
   15978: e1a03000     	mov	r3, r0
   1597c: e50b3008     	str	r3, [r11, #-0x8]
   15980: e51b3008     	ldr	r3, [r11, #-0x8]
   15984: e3530000     	cmp	r3, #0
   15988: 0a000001     	beq	0x15994 <wait_for+0xb8> @ imm = #0x4
   1598c: e51b0008     	ldr	r0, [r11, #-0x8]
   15990: ebffff12     	bl	0x155e0 <fail>          @ imm = #-0x3b8
   15994: e51b3010     	ldr	r3, [r11, #-0x10]
   15998: e5932048     	ldr	r2, [r3, #0x48]
   1599c: e51b3018     	ldr	r3, [r11, #-0x18]
   159a0: e1520003     	cmp	r2, r3
   159a4: 0affffed     	beq	0x15960 <wait_for+0x84> @ imm = #-0x4c
   159a8: ea000024     	b	0x15a40 <wait_for+0x164> @ imm = #0x90
   159ac: e51b3010     	ldr	r3, [r11, #-0x10]
   159b0: e2832018     	add	r2, r3, #24
   159b4: e51b3010     	ldr	r3, [r11, #-0x10]
   159b8: e1a00002     	mov	r0, r2
   159bc: e1a01003     	mov	r1, r3
   159c0: ebffda6b     	bl	0xc374 <pthread_cond_wait@plt> @ imm = #-0x9654
   159c4: e1a03000     	mov	r3, r0
   159c8: e50b3008     	str	r3, [r11, #-0x8]
   159cc: e51b3008     	ldr	r3, [r11, #-0x8]
   159d0: e3530000     	cmp	r3, #0
   159d4: 0a000001     	beq	0x159e0 <wait_for+0x104> @ imm = #0x4
   159d8: e51b0008     	ldr	r0, [r11, #-0x8]
   159dc: ebfffeff     	bl	0x155e0 <fail>          @ imm = #-0x404
   159e0: e51b3010     	ldr	r3, [r11, #-0x10]
   159e4: e5932048     	ldr	r2, [r3, #0x48]
   159e8: e51b3018     	ldr	r3, [r11, #-0x18]
   159ec: e1520003     	cmp	r2, r3
   159f0: daffffed     	ble	0x159ac <wait_for+0xd0> @ imm = #-0x4c
   159f4: ea000011     	b	0x15a40 <wait_for+0x164> @ imm = #0x44
   159f8: e51b3010     	ldr	r3, [r11, #-0x10]
   159fc: e2832018     	add	r2, r3, #24
   15a00: e51b3010     	ldr	r3, [r11, #-0x10]
   15a04: e1a00002     	mov	r0, r2
   15a08: e1a01003     	mov	r1, r3
   15a0c: ebffda58     	bl	0xc374 <pthread_cond_wait@plt> @ imm = #-0x96a0
   15a10: e1a03000     	mov	r3, r0
   15a14: e50b3008     	str	r3, [r11, #-0x8]
   15a18: e51b3008     	ldr	r3, [r11, #-0x8]
   15a1c: e3530000     	cmp	r3, #0
   15a20: 0a000001     	beq	0x15a2c <wait_for+0x150> @ imm = #0x4
   15a24: e51b0008     	ldr	r0, [r11, #-0x8]
   15a28: ebfffeec     	bl	0x155e0 <fail>          @ imm = #-0x450
   15a2c: e51b3010     	ldr	r3, [r11, #-0x10]
   15a30: e5932048     	ldr	r2, [r3, #0x48]
   15a34: e51b3018     	ldr	r3, [r11, #-0x18]
   15a38: e1520003     	cmp	r2, r3
   15a3c: aaffffed     	bge	0x159f8 <wait_for+0x11c> @ imm = #-0x4c
   15a40: e24bd004     	sub	sp, r11, #4
   15a44: e8bd8800     	pop	{r11, pc}

