00014c14 <set_log_buffering>:
   14c14: e92d4800     	push	{r11, lr}
   14c18: e28db004     	add	r11, sp, #4
   14c1c: e24dd008     	sub	sp, sp, #8
   14c20: e50b0008     	str	r0, [r11, #-0x8]
   14c24: eb000142     	bl	0x15134 <log_flush>     @ imm = #0x508
   14c28: e59f3074     	ldr	r3, [pc, #0x74]         @ 0x14ca4 <set_log_buffering+0x90>
   14c2c: e5933000     	ldr	r3, [r3]
   14c30: e3530000     	cmp	r3, #0
   14c34: 0a000003     	beq	0x14c48 <set_log_buffering+0x34> @ imm = #0xc
   14c38: e59f3064     	ldr	r3, [pc, #0x64]         @ 0x14ca4 <set_log_buffering+0x90>
   14c3c: e5933000     	ldr	r3, [r3]
   14c40: e1a00003     	mov	r0, r3
   14c44: ebffddf4     	bl	0xc41c <free@plt>       @ imm = #-0x8830
   14c48: e51b2008     	ldr	r2, [r11, #-0x8]
   14c4c: e59f3054     	ldr	r3, [pc, #0x54]         @ 0x14ca8 <set_log_buffering+0x94>
   14c50: e1520003     	cmp	r2, r3
   14c54: da000010     	ble	0x14c9c <set_log_buffering+0x88> @ imm = #0x40
   14c58: e51b3008     	ldr	r3, [r11, #-0x8]
   14c5c: e1a00003     	mov	r0, r3
   14c60: ebffde80     	bl	0xc668 <malloc@plt>     @ imm = #-0x8600
   14c64: e1a03000     	mov	r3, r0
   14c68: e1a02003     	mov	r2, r3
   14c6c: e59f3030     	ldr	r3, [pc, #0x30]         @ 0x14ca4 <set_log_buffering+0x90>
   14c70: e5832000     	str	r2, [r3]
   14c74: e59f3028     	ldr	r3, [pc, #0x28]         @ 0x14ca4 <set_log_buffering+0x90>
   14c78: e5932000     	ldr	r2, [r3]
   14c7c: e59f3028     	ldr	r3, [pc, #0x28]         @ 0x14cac <set_log_buffering+0x98>
   14c80: e5832000     	str	r2, [r3]
   14c84: e59f3020     	ldr	r3, [pc, #0x20]         @ 0x14cac <set_log_buffering+0x98>
   14c88: e5932000     	ldr	r2, [r3]
   14c8c: e51b3008     	ldr	r3, [r11, #-0x8]
   14c90: e0822003     	add	r2, r2, r3
   14c94: e59f3014     	ldr	r3, [pc, #0x14]         @ 0x14cb0 <set_log_buffering+0x9c>
   14c98: e5832000     	str	r2, [r3]
   14c9c: e24bd004     	sub	sp, r11, #4
   14ca0: e8bd8800     	pop	{r11, pc}
   14ca4: 48 73 05 00  	.word	0x00057348
   14ca8: ff 01 00 00  	.word	0x000001ff
   14cac: 4c 73 05 00  	.word	0x0005734c
   14cb0: 50 73 05 00  	.word	0x00057350

