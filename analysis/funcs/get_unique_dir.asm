000111c0 <get_unique_dir>:
   111c0: e92d4800     	push	{r11, lr}
   111c4: e28db004     	add	r11, sp, #4
   111c8: e24dd090     	sub	sp, sp, #144
   111cc: e50b0088     	str	r0, [r11, #-0x88]
   111d0: e50b108c     	str	r1, [r11, #-0x8c]
   111d4: e3a03001     	mov	r3, #1
   111d8: e50b3018     	str	r3, [r11, #-0x18]
   111dc: e51b308c     	ldr	r3, [r11, #-0x8c]
   111e0: e5933000     	ldr	r3, [r3]
   111e4: e1a00003     	mov	r0, r3
   111e8: ebffed18     	bl	0xc650 <strdup@plt>     @ imm = #-0x4ba0
   111ec: e1a03000     	mov	r3, r0
   111f0: e50b3014     	str	r3, [r11, #-0x14]
   111f4: e51b308c     	ldr	r3, [r11, #-0x8c]
   111f8: e5933000     	ldr	r3, [r3]
   111fc: e51b0088     	ldr	r0, [r11, #-0x88]
   11200: e1a01003     	mov	r1, r3
   11204: e3a02000     	mov	r2, #0
   11208: e3a03000     	mov	r3, #0
   1120c: ebfffc7b     	bl	0x10400 <make_filename> @ imm = #-0xe14
   11210: e1a03000     	mov	r3, r0
   11214: e50b3010     	str	r3, [r11, #-0x10]
   11218: e51b3088     	ldr	r3, [r11, #-0x88]
   1121c: e3530000     	cmp	r3, #0
   11220: 1a000002     	bne	0x11230 <get_unique_dir+0x70> @ imm = #0x8
   11224: e51b308c     	ldr	r3, [r11, #-0x8c]
   11228: e5933000     	ldr	r3, [r3]
   1122c: ea000000     	b	0x11234 <get_unique_dir+0x74> @ imm = #0x0
   11230: e51b3010     	ldr	r3, [r11, #-0x10]
   11234: e1a02003     	mov	r2, r3
   11238: e24b3084     	sub	r3, r11, #132
   1123c: e1a00002     	mov	r0, r2
   11240: e1a01003     	mov	r1, r3
   11244: eb0081ca     	bl	0x31974 <stat64>        @ imm = #0x20728
   11248: e1a03000     	mov	r3, r0
   1124c: e3530000     	cmp	r3, #0
   11250: 13a03000     	movne	r3, #0
   11254: 03a03001     	moveq	r3, #1
   11258: e50b301c     	str	r3, [r11, #-0x1c]
   1125c: e51b0010     	ldr	r0, [r11, #-0x10]
   11260: ebffec6d     	bl	0xc41c <free@plt>       @ imm = #-0x4e4c
   11264: ea000035     	b	0x11340 <get_unique_dir+0x180> @ imm = #0xd4
   11268: e51b0014     	ldr	r0, [r11, #-0x14]
   1126c: ebffec9a     	bl	0xc4dc <strlen@plt>     @ imm = #-0x4d98
   11270: e1a03000     	mov	r3, r0
   11274: e283300a     	add	r3, r3, #10
   11278: e50b300c     	str	r3, [r11, #-0xc]
   1127c: e51b300c     	ldr	r3, [r11, #-0xc]
   11280: e1a00003     	mov	r0, r3
   11284: ebffecf7     	bl	0xc668 <malloc@plt>     @ imm = #-0x4c24
   11288: e1a03000     	mov	r3, r0
   1128c: e50b3008     	str	r3, [r11, #-0x8]
   11290: e51b200c     	ldr	r2, [r11, #-0xc]
   11294: e59f30c0     	ldr	r3, [pc, #0xc0]         @ 0x1135c <get_unique_dir+0x19c>
   11298: e51b1018     	ldr	r1, [r11, #-0x18]
   1129c: e51b0018     	ldr	r0, [r11, #-0x18]
   112a0: e2800001     	add	r0, r0, #1
   112a4: e50b0018     	str	r0, [r11, #-0x18]
   112a8: e58d1000     	str	r1, [sp]
   112ac: e51b0008     	ldr	r0, [r11, #-0x8]
   112b0: e1a01002     	mov	r1, r2
   112b4: e1a02003     	mov	r2, r3
   112b8: e51b3014     	ldr	r3, [r11, #-0x14]
   112bc: ebffed1f     	bl	0xc740 <snprintf@plt>   @ imm = #-0x4b84
   112c0: e51b308c     	ldr	r3, [r11, #-0x8c]
   112c4: e5933000     	ldr	r3, [r3]
   112c8: e1a00003     	mov	r0, r3
   112cc: ebffec52     	bl	0xc41c <free@plt>       @ imm = #-0x4eb8
   112d0: e51b308c     	ldr	r3, [r11, #-0x8c]
   112d4: e51b2008     	ldr	r2, [r11, #-0x8]
   112d8: e5832000     	str	r2, [r3]
   112dc: e51b0088     	ldr	r0, [r11, #-0x88]
   112e0: e51b1008     	ldr	r1, [r11, #-0x8]
   112e4: e3a02000     	mov	r2, #0
   112e8: e3a03000     	mov	r3, #0
   112ec: ebfffc43     	bl	0x10400 <make_filename> @ imm = #-0xef4
   112f0: e1a03000     	mov	r3, r0
   112f4: e50b3010     	str	r3, [r11, #-0x10]
   112f8: e51b3088     	ldr	r3, [r11, #-0x88]
   112fc: e3530000     	cmp	r3, #0
   11300: 0a000001     	beq	0x1130c <get_unique_dir+0x14c> @ imm = #0x4
   11304: e51b3010     	ldr	r3, [r11, #-0x10]
   11308: ea000000     	b	0x11310 <get_unique_dir+0x150> @ imm = #0x0
   1130c: e51b3008     	ldr	r3, [r11, #-0x8]
   11310: e1a02003     	mov	r2, r3
   11314: e24b3084     	sub	r3, r11, #132
   11318: e1a00002     	mov	r0, r2
   1131c: e1a01003     	mov	r1, r3
   11320: eb008193     	bl	0x31974 <stat64>        @ imm = #0x2064c
   11324: e1a03000     	mov	r3, r0
   11328: e3530000     	cmp	r3, #0
   1132c: 13a03000     	movne	r3, #0
   11330: 03a03001     	moveq	r3, #1
   11334: e50b301c     	str	r3, [r11, #-0x1c]
   11338: e51b0010     	ldr	r0, [r11, #-0x10]
   1133c: ebffec36     	bl	0xc41c <free@plt>       @ imm = #-0x4f28
   11340: e51b301c     	ldr	r3, [r11, #-0x1c]
   11344: e3530000     	cmp	r3, #0
   11348: 1affffc6     	bne	0x11268 <get_unique_dir+0xa8> @ imm = #-0xe8
   1134c: e51b0014     	ldr	r0, [r11, #-0x14]
   11350: ebffec31     	bl	0xc41c <free@plt>       @ imm = #-0x4f3c
   11354: e24bd004     	sub	sp, r11, #4
   11358: e8bd8800     	pop	{r11, pc}
   1135c: d0 27 03 00  	.word	0x000327d0

