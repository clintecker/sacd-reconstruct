00021020 <auth_sacd>:
   21020: e92d4800     	push	{r11, lr}
   21024: e28db004     	add	r11, sp, #4
   21028: e24dd018     	sub	sp, sp, #24
   2102c: e3e03000     	mvn	r3, #0
   21030: e50b3008     	str	r3, [r11, #-0x8]
   21034: e24b301c     	sub	r3, r11, #28
   21038: e1a00003     	mov	r0, r3
   2103c: e3a01000     	mov	r1, #0
   21040: e3a02010     	mov	r2, #16
   21044: ebffacd6     	bl	0xc3a4 <memset@plt>     @ imm = #-0x14ca8
   21048: e59f0058     	ldr	r0, [pc, #0x58]         @ 0x210a8 <auth_sacd+0x88>
   2104c: e3a01000     	mov	r1, #0
   21050: ebffad48     	bl	0xc578 <open64@plt>     @ imm = #-0x14ae0
   21054: e1a03000     	mov	r3, r0
   21058: e50b300c     	str	r3, [r11, #-0xc]
   2105c: e51b300c     	ldr	r3, [r11, #-0xc]
   21060: e3530000     	cmp	r3, #0
   21064: ba00000b     	blt	0x21098 <auth_sacd+0x78> @ imm = #0x2c
   21068: e24b301c     	sub	r3, r11, #28
   2106c: e51b000c     	ldr	r0, [r11, #-0xc]
   21070: e59f1034     	ldr	r1, [pc, #0x34]         @ 0x210ac <auth_sacd+0x8c>
   21074: e1a02003     	mov	r2, r3
   21078: ebffad0b     	bl	0xc4ac <ioctl@plt>      @ imm = #-0x14bd4
   2107c: e1a03000     	mov	r3, r0
   21080: e3530000     	cmp	r3, #0
   21084: ba000001     	blt	0x21090 <auth_sacd+0x70> @ imm = #0x4
   21088: e51b301c     	ldr	r3, [r11, #-0x1c]
   2108c: e50b3008     	str	r3, [r11, #-0x8]
   21090: e51b000c     	ldr	r0, [r11, #-0xc]
   21094: ebffad52     	bl	0xc5e4 <close@plt>      @ imm = #-0x14ab8
   21098: e51b3008     	ldr	r3, [r11, #-0x8]
   2109c: e1a00003     	mov	r0, r3
   210a0: e24bd004     	sub	sp, r11, #4
   210a4: e8bd8800     	pop	{r11, pc}
   210a8: f8 52 03 00  	.word	0x000352f8
   210ac: 02 53 10 40  	.word	0x40105302

