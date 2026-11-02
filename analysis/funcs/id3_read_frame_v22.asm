0001cc88 <id3_read_frame_v22>:
   1cc88: e92d4800     	push	{r11, lr}
   1cc8c: e28db004     	add	r11, sp, #4
   1cc90: e24dd020     	sub	sp, sp, #32
   1cc94: e50b0020     	str	r0, [r11, #-0x20]
   1cc98: e51b3020     	ldr	r3, [r11, #-0x20]
   1cc9c: e5933134     	ldr	r3, [r3, #0x134]
   1cca0: e51b0020     	ldr	r0, [r11, #-0x20]
   1cca4: e3a01000     	mov	r1, #0
   1cca8: e3a02006     	mov	r2, #6
   1ccac: e12fff33     	blx	r3
   1ccb0: e1a03000     	mov	r3, r0
   1ccb4: e50b300c     	str	r3, [r11, #-0xc]
   1ccb8: e51b300c     	ldr	r3, [r11, #-0xc]
   1ccbc: e3530000     	cmp	r3, #0
   1ccc0: 1a000001     	bne	0x1cccc <id3_read_frame_v22+0x44> @ imm = #0x4
   1ccc4: e3e03000     	mvn	r3, #0
   1ccc8: ea000090     	b	0x1cf10 <id3_read_frame_v22+0x288> @ imm = #0x240
   1cccc: e51b300c     	ldr	r3, [r11, #-0xc]
   1ccd0: e5d33000     	ldrb	r3, [r3]
   1ccd4: e353002f     	cmp	r3, #47
   1ccd8: 9a000003     	bls	0x1ccec <id3_read_frame_v22+0x64> @ imm = #0xc
   1ccdc: e51b300c     	ldr	r3, [r11, #-0xc]
   1cce0: e5d33000     	ldrb	r3, [r3]
   1cce4: e3530039     	cmp	r3, #57
   1cce8: 9a000013     	bls	0x1cd3c <id3_read_frame_v22+0xb4> @ imm = #0x4c
   1ccec: e51b300c     	ldr	r3, [r11, #-0xc]
   1ccf0: e5d33000     	ldrb	r3, [r3]
   1ccf4: e3530040     	cmp	r3, #64
   1ccf8: 9a000003     	bls	0x1cd0c <id3_read_frame_v22+0x84> @ imm = #0xc
   1ccfc: e51b300c     	ldr	r3, [r11, #-0xc]
   1cd00: e5d33000     	ldrb	r3, [r3]
   1cd04: e353005a     	cmp	r3, #90
   1cd08: 9a00000b     	bls	0x1cd3c <id3_read_frame_v22+0xb4> @ imm = #0x2c
   1cd0c: e51b3020     	ldr	r3, [r11, #-0x20]
   1cd10: e5933130     	ldr	r3, [r3, #0x130]
   1cd14: e51b2020     	ldr	r2, [r11, #-0x20]
   1cd18: e592101c     	ldr	r1, [r2, #0x1c]
   1cd1c: e51b2020     	ldr	r2, [r11, #-0x20]
   1cd20: e5922020     	ldr	r2, [r2, #0x20]
   1cd24: e0622001     	rsb	r2, r2, r1
   1cd28: e51b0020     	ldr	r0, [r11, #-0x20]
   1cd2c: e1a01002     	mov	r1, r2
   1cd30: e12fff33     	blx	r3
   1cd34: e3a03000     	mov	r3, #0
   1cd38: ea000074     	b	0x1cf10 <id3_read_frame_v22+0x288> @ imm = #0x1d0
   1cd3c: e51b300c     	ldr	r3, [r11, #-0xc]
   1cd40: e5d33000     	ldrb	r3, [r3]
   1cd44: e1a02803     	lsl	r2, r3, #16
   1cd48: e51b300c     	ldr	r3, [r11, #-0xc]
   1cd4c: e2833001     	add	r3, r3, #1
   1cd50: e5d33000     	ldrb	r3, [r3]
   1cd54: e1a03403     	lsl	r3, r3, #8
   1cd58: e1822003     	orr	r2, r2, r3
   1cd5c: e51b300c     	ldr	r3, [r11, #-0xc]
   1cd60: e2833002     	add	r3, r3, #2
   1cd64: e5d33000     	ldrb	r3, [r3]
   1cd68: e1823003     	orr	r3, r2, r3
   1cd6c: e50b3014     	str	r3, [r11, #-0x14]
   1cd70: e51b300c     	ldr	r3, [r11, #-0xc]
   1cd74: e2833003     	add	r3, r3, #3
   1cd78: e5d33000     	ldrb	r3, [r3]
   1cd7c: e1a02803     	lsl	r2, r3, #16
   1cd80: e51b300c     	ldr	r3, [r11, #-0xc]
   1cd84: e2833004     	add	r3, r3, #4
   1cd88: e5d33000     	ldrb	r3, [r3]
   1cd8c: e1a03403     	lsl	r3, r3, #8
   1cd90: e1822003     	orr	r2, r2, r3
   1cd94: e51b300c     	ldr	r3, [r11, #-0xc]
   1cd98: e2833005     	add	r3, r3, #5
   1cd9c: e5d33000     	ldrb	r3, [r3]
   1cda0: e1823003     	orr	r3, r2, r3
   1cda4: e50b3008     	str	r3, [r11, #-0x8]
   1cda8: e51b0014     	ldr	r0, [r11, #-0x14]
   1cdac: ebffff94     	bl	0x1cc04 <find_v24_id>   @ imm = #-0x1b0
   1cdb0: e1a03000     	mov	r3, r0
   1cdb4: e50b3010     	str	r3, [r11, #-0x10]
   1cdb8: e51b3010     	ldr	r3, [r11, #-0x10]
   1cdbc: e3530000     	cmp	r3, #0
   1cdc0: 1a00000b     	bne	0x1cdf4 <id3_read_frame_v22+0x16c> @ imm = #0x2c
   1cdc4: e51b3020     	ldr	r3, [r11, #-0x20]
   1cdc8: e5933130     	ldr	r3, [r3, #0x130]
   1cdcc: e51b0020     	ldr	r0, [r11, #-0x20]
   1cdd0: e51b1008     	ldr	r1, [r11, #-0x8]
   1cdd4: e12fff33     	blx	r3
   1cdd8: e1a03000     	mov	r3, r0
   1cddc: e3530000     	cmp	r3, #0
   1cde0: aa000001     	bge	0x1cdec <id3_read_frame_v22+0x164> @ imm = #0x4
   1cde4: e3e03000     	mvn	r3, #0
   1cde8: ea000048     	b	0x1cf10 <id3_read_frame_v22+0x288> @ imm = #0x120
   1cdec: e3a03000     	mov	r3, #0
   1cdf0: ea000046     	b	0x1cf10 <id3_read_frame_v22+0x288> @ imm = #0x118
   1cdf4: e3a00030     	mov	r0, #48
   1cdf8: e3a01001     	mov	r1, #1
   1cdfc: ebffbd56     	bl	0xc35c <calloc@plt>     @ imm = #-0x10aa8
   1ce00: e1a03000     	mov	r3, r0
   1ce04: e50b3018     	str	r3, [r11, #-0x18]
   1ce08: e51b3018     	ldr	r3, [r11, #-0x18]
   1ce0c: e51b2020     	ldr	r2, [r11, #-0x20]
   1ce10: e5832000     	str	r2, [r3]
   1ce14: e51b2008     	ldr	r2, [r11, #-0x8]
   1ce18: e51b3018     	ldr	r3, [r11, #-0x18]
   1ce1c: e583201c     	str	r2, [r3, #0x1c]
   1ce20: e51b3018     	ldr	r3, [r11, #-0x18]
   1ce24: e593201c     	ldr	r2, [r3, #0x1c]
   1ce28: e59f30ec     	ldr	r3, [pc, #0xec]         @ 0x1cf1c <id3_read_frame_v22+0x294>
   1ce2c: e1520003     	cmp	r2, r3
   1ce30: 9a000003     	bls	0x1ce44 <id3_read_frame_v22+0x1bc> @ imm = #0xc
   1ce34: e51b0018     	ldr	r0, [r11, #-0x18]
   1ce38: ebffbd77     	bl	0xc41c <free@plt>       @ imm = #-0x10a24
   1ce3c: e3e03000     	mvn	r3, #0
   1ce40: ea000032     	b	0x1cf10 <id3_read_frame_v22+0x288> @ imm = #0xc8
   1ce44: e51b0010     	ldr	r0, [r11, #-0x10]
   1ce48: ebfffd22     	bl	0x1c2d8 <find_frame_description> @ imm = #-0xb78
   1ce4c: e1a02000     	mov	r2, r0
   1ce50: e51b3018     	ldr	r3, [r11, #-0x18]
   1ce54: e5832004     	str	r2, [r3, #0x4]
   1ce58: e51b3018     	ldr	r3, [r11, #-0x18]
   1ce5c: e593301c     	ldr	r3, [r3, #0x1c]
   1ce60: e2833002     	add	r3, r3, #2
   1ce64: e1a00003     	mov	r0, r3
   1ce68: e3a01001     	mov	r1, #1
   1ce6c: ebffbd3a     	bl	0xc35c <calloc@plt>     @ imm = #-0x10b18
   1ce70: e1a03000     	mov	r3, r0
   1ce74: e1a02003     	mov	r2, r3
   1ce78: e51b3018     	ldr	r3, [r11, #-0x18]
   1ce7c: e5832018     	str	r2, [r3, #0x18]
   1ce80: e51b3020     	ldr	r3, [r11, #-0x20]
   1ce84: e5933134     	ldr	r3, [r3, #0x134]
   1ce88: e51b2018     	ldr	r2, [r11, #-0x18]
   1ce8c: e5921018     	ldr	r1, [r2, #0x18]
   1ce90: e51b2018     	ldr	r2, [r11, #-0x18]
   1ce94: e592201c     	ldr	r2, [r2, #0x1c]
   1ce98: e51b0020     	ldr	r0, [r11, #-0x20]
   1ce9c: e12fff33     	blx	r3
   1cea0: e1a03000     	mov	r3, r0
   1cea4: e3530000     	cmp	r3, #0
   1cea8: 1a000007     	bne	0x1cecc <id3_read_frame_v22+0x244> @ imm = #0x1c
   1ceac: e51b3018     	ldr	r3, [r11, #-0x18]
   1ceb0: e5933018     	ldr	r3, [r3, #0x18]
   1ceb4: e1a00003     	mov	r0, r3
   1ceb8: ebffbd57     	bl	0xc41c <free@plt>       @ imm = #-0x10aa4
   1cebc: e51b0018     	ldr	r0, [r11, #-0x18]
   1cec0: ebffbd55     	bl	0xc41c <free@plt>       @ imm = #-0x10aac
   1cec4: e3e03000     	mvn	r3, #0
   1cec8: ea000010     	b	0x1cf10 <id3_read_frame_v22+0x288> @ imm = #0x40
   1cecc: e51b3018     	ldr	r3, [r11, #-0x18]
   1ced0: e2832028     	add	r2, r3, #40
   1ced4: e51b3020     	ldr	r3, [r11, #-0x20]
   1ced8: e2833f4e     	add	r3, r3, #312
   1cedc: e1a00002     	mov	r0, r2
   1cee0: e1a01003     	mov	r1, r3
   1cee4: ebfffcbd     	bl	0x1c1e0 <list_add_tail> @ imm = #-0xd0c
   1cee8: e51b3018     	ldr	r3, [r11, #-0x18]
   1ceec: e5932018     	ldr	r2, [r3, #0x18]
   1cef0: e51b3018     	ldr	r3, [r11, #-0x18]
   1cef4: e5832010     	str	r2, [r3, #0x10]
   1cef8: e51b3018     	ldr	r3, [r11, #-0x18]
   1cefc: e593301c     	ldr	r3, [r3, #0x1c]
   1cf00: e1a02003     	mov	r2, r3
   1cf04: e51b3018     	ldr	r3, [r11, #-0x18]
   1cf08: e5832014     	str	r2, [r3, #0x14]
   1cf0c: e3a03000     	mov	r3, #0
   1cf10: e1a00003     	mov	r0, r3
   1cf14: e24bd004     	sub	sp, r11, #4
   1cf18: e8bd8800     	pop	{r11, pc}
   1cf1c: 40 42 0f 00  	.word	0x000f4240

