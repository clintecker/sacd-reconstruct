00011054 <get_unique_filename>:
   11054: e92d4800     	push	{r11, lr}
   11058: e28db004     	add	r11, sp, #4
   1105c: e24dd090     	sub	sp, sp, #144
   11060: e50b0088     	str	r0, [r11, #-0x88]
   11064: e50b108c     	str	r1, [r11, #-0x8c]
   11068: e3a03001     	mov	r3, #1
   1106c: e50b3018     	str	r3, [r11, #-0x18]
   11070: e51b3088     	ldr	r3, [r11, #-0x88]
   11074: e5933000     	ldr	r3, [r3]
   11078: e1a00003     	mov	r0, r3
   1107c: ebffed73     	bl	0xc650 <strdup@plt>     @ imm = #-0x4a34
   11080: e1a03000     	mov	r3, r0
   11084: e50b3014     	str	r3, [r11, #-0x14]
   11088: e51b3088     	ldr	r3, [r11, #-0x88]
   1108c: e5933000     	ldr	r3, [r3]
   11090: e3a00000     	mov	r0, #0
   11094: e3a01000     	mov	r1, #0
   11098: e1a02003     	mov	r2, r3
   1109c: e51b308c     	ldr	r3, [r11, #-0x8c]
   110a0: ebfffcd6     	bl	0x10400 <make_filename> @ imm = #-0xca8
   110a4: e1a03000     	mov	r3, r0
   110a8: e50b3010     	str	r3, [r11, #-0x10]
   110ac: e51b2010     	ldr	r2, [r11, #-0x10]
   110b0: e24b3084     	sub	r3, r11, #132
   110b4: e1a00002     	mov	r0, r2
   110b8: e1a01003     	mov	r1, r3
   110bc: eb00822c     	bl	0x31974 <stat64>        @ imm = #0x208b0
   110c0: e1a03000     	mov	r3, r0
   110c4: e3530000     	cmp	r3, #0
   110c8: 13a03000     	movne	r3, #0
   110cc: 03a03001     	moveq	r3, #1
   110d0: e50b301c     	str	r3, [r11, #-0x1c]
   110d4: e51b0010     	ldr	r0, [r11, #-0x10]
   110d8: ebffeccf     	bl	0xc41c <free@plt>       @ imm = #-0x4cc4
   110dc: ea00002f     	b	0x111a0 <get_unique_filename+0x14c> @ imm = #0xbc
   110e0: e51b0014     	ldr	r0, [r11, #-0x14]
   110e4: ebffecfc     	bl	0xc4dc <strlen@plt>     @ imm = #-0x4c10
   110e8: e1a03000     	mov	r3, r0
   110ec: e283300a     	add	r3, r3, #10
   110f0: e50b300c     	str	r3, [r11, #-0xc]
   110f4: e51b300c     	ldr	r3, [r11, #-0xc]
   110f8: e1a00003     	mov	r0, r3
   110fc: ebffed59     	bl	0xc668 <malloc@plt>     @ imm = #-0x4a9c
   11100: e1a03000     	mov	r3, r0
   11104: e50b3008     	str	r3, [r11, #-0x8]
   11108: e51b200c     	ldr	r2, [r11, #-0xc]
   1110c: e59f30a8     	ldr	r3, [pc, #0xa8]         @ 0x111bc <get_unique_filename+0x168>
   11110: e51b1018     	ldr	r1, [r11, #-0x18]
   11114: e51b0018     	ldr	r0, [r11, #-0x18]
   11118: e2800001     	add	r0, r0, #1
   1111c: e50b0018     	str	r0, [r11, #-0x18]
   11120: e58d1000     	str	r1, [sp]
   11124: e51b0008     	ldr	r0, [r11, #-0x8]
   11128: e1a01002     	mov	r1, r2
   1112c: e1a02003     	mov	r2, r3
   11130: e51b3014     	ldr	r3, [r11, #-0x14]
   11134: ebffed81     	bl	0xc740 <snprintf@plt>   @ imm = #-0x49fc
   11138: e51b3088     	ldr	r3, [r11, #-0x88]
   1113c: e5933000     	ldr	r3, [r3]
   11140: e1a00003     	mov	r0, r3
   11144: ebffecb4     	bl	0xc41c <free@plt>       @ imm = #-0x4d30
   11148: e51b3088     	ldr	r3, [r11, #-0x88]
   1114c: e51b2008     	ldr	r2, [r11, #-0x8]
   11150: e5832000     	str	r2, [r3]
   11154: e3a00000     	mov	r0, #0
   11158: e3a01000     	mov	r1, #0
   1115c: e51b2008     	ldr	r2, [r11, #-0x8]
   11160: e51b308c     	ldr	r3, [r11, #-0x8c]
   11164: ebfffca5     	bl	0x10400 <make_filename> @ imm = #-0xd6c
   11168: e1a03000     	mov	r3, r0
   1116c: e50b3010     	str	r3, [r11, #-0x10]
   11170: e51b2008     	ldr	r2, [r11, #-0x8]
   11174: e24b3084     	sub	r3, r11, #132
   11178: e1a00002     	mov	r0, r2
   1117c: e1a01003     	mov	r1, r3
   11180: eb0081fb     	bl	0x31974 <stat64>        @ imm = #0x207ec
   11184: e1a03000     	mov	r3, r0
   11188: e3530000     	cmp	r3, #0
   1118c: 13a03000     	movne	r3, #0
   11190: 03a03001     	moveq	r3, #1
   11194: e50b301c     	str	r3, [r11, #-0x1c]
   11198: e51b0010     	ldr	r0, [r11, #-0x10]
   1119c: ebffec9e     	bl	0xc41c <free@plt>       @ imm = #-0x4d88
   111a0: e51b301c     	ldr	r3, [r11, #-0x1c]
   111a4: e3530000     	cmp	r3, #0
   111a8: 1affffcc     	bne	0x110e0 <get_unique_filename+0x8c> @ imm = #-0xd0
   111ac: e51b0014     	ldr	r0, [r11, #-0x14]
   111b0: ebffec99     	bl	0xc41c <free@plt>       @ imm = #-0x4d9c
   111b4: e24bd004     	sub	sp, r11, #4
   111b8: e8bd8800     	pop	{r11, pc}
   111bc: d0 27 03 00  	.word	0x000327d0

