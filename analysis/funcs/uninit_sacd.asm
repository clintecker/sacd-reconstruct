0002120c <uninit_sacd>:
   2120c: e92d4800     	push	{r11, lr}
   21210: e28db004     	add	r11, sp, #4
   21214: e24dd018     	sub	sp, sp, #24
   21218: e24b3018     	sub	r3, r11, #24
   2121c: e1a00003     	mov	r0, r3
   21220: e3a01000     	mov	r1, #0
   21224: e3a02010     	mov	r2, #16
   21228: ebffac5d     	bl	0xc3a4 <memset@plt>     @ imm = #-0x14e8c
   2122c: e59f003c     	ldr	r0, [pc, #0x3c]         @ 0x21270 <uninit_sacd+0x64>
   21230: e3a01000     	mov	r1, #0
   21234: ebffaccf     	bl	0xc578 <open64@plt>     @ imm = #-0x14cc4
   21238: e1a03000     	mov	r3, r0
   2123c: e50b3008     	str	r3, [r11, #-0x8]
   21240: e51b3008     	ldr	r3, [r11, #-0x8]
   21244: e3530000     	cmp	r3, #0
   21248: ba000006     	blt	0x21268 <uninit_sacd+0x5c> @ imm = #0x18
   2124c: e24b3018     	sub	r3, r11, #24
   21250: e51b0008     	ldr	r0, [r11, #-0x8]
   21254: e59f1018     	ldr	r1, [pc, #0x18]         @ 0x21274 <uninit_sacd+0x68>
   21258: e1a02003     	mov	r2, r3
   2125c: ebffac92     	bl	0xc4ac <ioctl@plt>      @ imm = #-0x14db8
   21260: e51b0008     	ldr	r0, [r11, #-0x8]
   21264: ebffacde     	bl	0xc5e4 <close@plt>      @ imm = #-0x14c88
   21268: e24bd004     	sub	sp, r11, #4
   2126c: e8bd8800     	pop	{r11, pc}
   21270: f8 52 03 00  	.word	0x000352f8
   21274: 05 53 10 40  	.word	0x40105305

