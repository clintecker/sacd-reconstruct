000210b0 <read_sacd>:
   210b0: e92d4800     	push	{r11, lr}
   210b4: e28db004     	add	r11, sp, #4
   210b8: e24dd028     	sub	sp, sp, #40
   210bc: e50b0020     	str	r0, [r11, #-0x20]
   210c0: e50b1024     	str	r1, [r11, #-0x24]
   210c4: e50b2028     	str	r2, [r11, #-0x28]
   210c8: e3e03000     	mvn	r3, #0
   210cc: e50b3008     	str	r3, [r11, #-0x8]
   210d0: e24b301c     	sub	r3, r11, #28
   210d4: e1a00003     	mov	r0, r3
   210d8: e3a01000     	mov	r1, #0
   210dc: e3a02010     	mov	r2, #16
   210e0: ebffacaf     	bl	0xc3a4 <memset@plt>     @ imm = #-0x14d44
   210e4: e59f0070     	ldr	r0, [pc, #0x70]         @ 0x2115c <read_sacd+0xac>
   210e8: e3a01000     	mov	r1, #0
   210ec: ebffad21     	bl	0xc578 <open64@plt>     @ imm = #-0x14b7c
   210f0: e1a03000     	mov	r3, r0
   210f4: e50b300c     	str	r3, [r11, #-0xc]
   210f8: e51b300c     	ldr	r3, [r11, #-0xc]
   210fc: e3530000     	cmp	r3, #0
   21100: ba000011     	blt	0x2114c <read_sacd+0x9c> @ imm = #0x44
   21104: e51b3020     	ldr	r3, [r11, #-0x20]
   21108: e50b3018     	str	r3, [r11, #-0x18]
   2110c: e51b3024     	ldr	r3, [r11, #-0x24]
   21110: e50b3014     	str	r3, [r11, #-0x14]
   21114: e51b3028     	ldr	r3, [r11, #-0x28]
   21118: e50b3010     	str	r3, [r11, #-0x10]
   2111c: e24b301c     	sub	r3, r11, #28
   21120: e51b000c     	ldr	r0, [r11, #-0xc]
   21124: e59f1034     	ldr	r1, [pc, #0x34]         @ 0x21160 <read_sacd+0xb0>
   21128: e1a02003     	mov	r2, r3
   2112c: ebffacde     	bl	0xc4ac <ioctl@plt>      @ imm = #-0x14c88
   21130: e1a03000     	mov	r3, r0
   21134: e3530000     	cmp	r3, #0
   21138: ba000001     	blt	0x21144 <read_sacd+0x94> @ imm = #0x4
   2113c: e51b301c     	ldr	r3, [r11, #-0x1c]
   21140: e50b3008     	str	r3, [r11, #-0x8]
   21144: e51b000c     	ldr	r0, [r11, #-0xc]
   21148: ebffad25     	bl	0xc5e4 <close@plt>      @ imm = #-0x14b6c
   2114c: e51b3008     	ldr	r3, [r11, #-0x8]
   21150: e1a00003     	mov	r0, r3
   21154: e24bd004     	sub	sp, r11, #4
   21158: e8bd8800     	pop	{r11, pc}
   2115c: f8 52 03 00  	.word	0x000352f8
   21160: 03 53 10 40  	.word	0x40105303

