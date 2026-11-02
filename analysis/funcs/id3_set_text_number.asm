0001db58 <id3_set_text_number>:
   1db58: e92d4800     	push	{r11, lr}
   1db5c: e28db004     	add	r11, sp, #4
   1db60: e24dd050     	sub	sp, sp, #80
   1db64: e50b0050     	str	r0, [r11, #-0x50]
   1db68: e50b1054     	str	r1, [r11, #-0x54]
   1db6c: e51b3050     	ldr	r3, [r11, #-0x50]
   1db70: e5933004     	ldr	r3, [r3, #0x4]
   1db74: e5d33004     	ldrb	r3, [r3, #0x4]
   1db78: e3530054     	cmp	r3, #84
   1db7c: 0a000001     	beq	0x1db88 <id3_set_text_number+0x30> @ imm = #0x4
   1db80: e3e03000     	mvn	r3, #0
   1db84: ea000076     	b	0x1dd64 <id3_set_text_number+0x20c> @ imm = #0x1d8
   1db88: e51b0050     	ldr	r0, [r11, #-0x50]
   1db8c: ebfffbf4     	bl	0x1cb64 <id3_frame_clear_data> @ imm = #-0x1030
   1db90: e3a03000     	mov	r3, #0
   1db94: e50b300c     	str	r3, [r11, #-0xc]
   1db98: ea00001d     	b	0x1dc14 <id3_set_text_number+0xbc> @ imm = #0x74
   1db9c: e51b000c     	ldr	r0, [r11, #-0xc]
   1dba0: e51b1054     	ldr	r1, [r11, #-0x54]
   1dba4: e59f31c4     	ldr	r3, [pc, #0x1c4]        @ 0x1dd70 <id3_set_text_number+0x218>
   1dba8: e0c32193     	smull	r2, r3, r3, r1
   1dbac: e1a02143     	asr	r2, r3, #2
   1dbb0: e1a03fc1     	asr	r3, r1, #31
   1dbb4: e0632002     	rsb	r2, r3, r2
   1dbb8: e1a03002     	mov	r3, r2
   1dbbc: e1a03103     	lsl	r3, r3, #2
   1dbc0: e0833002     	add	r3, r3, r2
   1dbc4: e1a03083     	lsl	r3, r3, #1
   1dbc8: e0632001     	rsb	r2, r3, r1
   1dbcc: e6ef3072     	uxtb	r3, r2
   1dbd0: e2833030     	add	r3, r3, #48
   1dbd4: e6ef2073     	uxtb	r2, r3
   1dbd8: e3e03047     	mvn	r3, #71
   1dbdc: e24bc004     	sub	r12, r11, #4
   1dbe0: e08c1000     	add	r1, r12, r0
   1dbe4: e0813003     	add	r3, r1, r3
   1dbe8: e5c32000     	strb	r2, [r3]
   1dbec: e51b300c     	ldr	r3, [r11, #-0xc]
   1dbf0: e2833001     	add	r3, r3, #1
   1dbf4: e50b300c     	str	r3, [r11, #-0xc]
   1dbf8: e51b3054     	ldr	r3, [r11, #-0x54]
   1dbfc: e59f216c     	ldr	r2, [pc, #0x16c]        @ 0x1dd70 <id3_set_text_number+0x218>
   1dc00: e0c21392     	smull	r1, r2, r2, r3
   1dc04: e1a02142     	asr	r2, r2, #2
   1dc08: e1a03fc3     	asr	r3, r3, #31
   1dc0c: e0633002     	rsb	r3, r3, r2
   1dc10: e50b3054     	str	r3, [r11, #-0x54]
   1dc14: e51b3054     	ldr	r3, [r11, #-0x54]
   1dc18: e3530000     	cmp	r3, #0
   1dc1c: da000002     	ble	0x1dc2c <id3_set_text_number+0xd4> @ imm = #0x8
   1dc20: e51b300c     	ldr	r3, [r11, #-0xc]
   1dc24: e353003f     	cmp	r3, #63
   1dc28: daffffdb     	ble	0x1db9c <id3_set_text_number+0x44> @ imm = #-0x94
   1dc2c: e51b300c     	ldr	r3, [r11, #-0xc]
   1dc30: e3530040     	cmp	r3, #64
   1dc34: 1a000001     	bne	0x1dc40 <id3_set_text_number+0xe8> @ imm = #0x4
   1dc38: e3e03000     	mvn	r3, #0
   1dc3c: ea000048     	b	0x1dd64 <id3_set_text_number+0x20c> @ imm = #0x120
   1dc40: e51b300c     	ldr	r3, [r11, #-0xc]
   1dc44: e3530000     	cmp	r3, #0
   1dc48: 1a000009     	bne	0x1dc74 <id3_set_text_number+0x11c> @ imm = #0x24
   1dc4c: e51b200c     	ldr	r2, [r11, #-0xc]
   1dc50: e3e03047     	mvn	r3, #71
   1dc54: e24bc004     	sub	r12, r11, #4
   1dc58: e08c2002     	add	r2, r12, r2
   1dc5c: e0823003     	add	r3, r2, r3
   1dc60: e3a02030     	mov	r2, #48
   1dc64: e5c32000     	strb	r2, [r3]
   1dc68: e51b300c     	ldr	r3, [r11, #-0xc]
   1dc6c: e2833001     	add	r3, r3, #1
   1dc70: e50b300c     	str	r3, [r11, #-0xc]
   1dc74: e51b300c     	ldr	r3, [r11, #-0xc]
   1dc78: e2833001     	add	r3, r3, #1
   1dc7c: e1a02003     	mov	r2, r3
   1dc80: e51b3050     	ldr	r3, [r11, #-0x50]
   1dc84: e583201c     	str	r2, [r3, #0x1c]
   1dc88: e51b3050     	ldr	r3, [r11, #-0x50]
   1dc8c: e593301c     	ldr	r3, [r3, #0x1c]
   1dc90: e2833001     	add	r3, r3, #1
   1dc94: e1a00003     	mov	r0, r3
   1dc98: ebffba72     	bl	0xc668 <malloc@plt>     @ imm = #-0x11638
   1dc9c: e1a03000     	mov	r3, r0
   1dca0: e1a02003     	mov	r2, r3
   1dca4: e51b3050     	ldr	r3, [r11, #-0x50]
   1dca8: e5832018     	str	r2, [r3, #0x18]
   1dcac: e51b3050     	ldr	r3, [r11, #-0x50]
   1dcb0: e5933018     	ldr	r3, [r3, #0x18]
   1dcb4: e3a02000     	mov	r2, #0
   1dcb8: e5c32000     	strb	r2, [r3]
   1dcbc: e51b3050     	ldr	r3, [r11, #-0x50]
   1dcc0: e5933018     	ldr	r3, [r3, #0x18]
   1dcc4: e2833001     	add	r3, r3, #1
   1dcc8: e50b3008     	str	r3, [r11, #-0x8]
   1dccc: ea00000a     	b	0x1dcfc <id3_set_text_number+0x1a4> @ imm = #0x28
   1dcd0: e51b200c     	ldr	r2, [r11, #-0xc]
   1dcd4: e3e03047     	mvn	r3, #71
   1dcd8: e24b1004     	sub	r1, r11, #4
   1dcdc: e0812002     	add	r2, r1, r2
   1dce0: e0823003     	add	r3, r2, r3
   1dce4: e5d32000     	ldrb	r2, [r3]
   1dce8: e51b3008     	ldr	r3, [r11, #-0x8]
   1dcec: e5c32000     	strb	r2, [r3]
   1dcf0: e51b3008     	ldr	r3, [r11, #-0x8]
   1dcf4: e2833001     	add	r3, r3, #1
   1dcf8: e50b3008     	str	r3, [r11, #-0x8]
   1dcfc: e51b300c     	ldr	r3, [r11, #-0xc]
   1dd00: e2433001     	sub	r3, r3, #1
   1dd04: e50b300c     	str	r3, [r11, #-0xc]
   1dd08: e51b300c     	ldr	r3, [r11, #-0xc]
   1dd0c: e3530000     	cmp	r3, #0
   1dd10: aaffffee     	bge	0x1dcd0 <id3_set_text_number+0x178> @ imm = #-0x48
   1dd14: e51b3008     	ldr	r3, [r11, #-0x8]
   1dd18: e3a02000     	mov	r2, #0
   1dd1c: e5c32000     	strb	r2, [r3]
   1dd20: e51b3050     	ldr	r3, [r11, #-0x50]
   1dd24: e3a02001     	mov	r2, #1
   1dd28: e5c3200e     	strb	r2, [r3, #0xe]
   1dd2c: e51b3050     	ldr	r3, [r11, #-0x50]
   1dd30: e5933000     	ldr	r3, [r3]
   1dd34: e3a02001     	mov	r2, #1
   1dd38: e583200c     	str	r2, [r3, #0xc]
   1dd3c: e51b3050     	ldr	r3, [r11, #-0x50]
   1dd40: e5932018     	ldr	r2, [r3, #0x18]
   1dd44: e51b3050     	ldr	r3, [r11, #-0x50]
   1dd48: e5832010     	str	r2, [r3, #0x10]
   1dd4c: e51b3050     	ldr	r3, [r11, #-0x50]
   1dd50: e593301c     	ldr	r3, [r3, #0x1c]
   1dd54: e1a02003     	mov	r2, r3
   1dd58: e51b3050     	ldr	r3, [r11, #-0x50]
   1dd5c: e5832014     	str	r2, [r3, #0x14]
   1dd60: e3a03000     	mov	r3, #0
   1dd64: e1a00003     	mov	r0, r3
   1dd68: e24bd004     	sub	sp, r11, #4
   1dd6c: e8bd8800     	pop	{r11, pc}
   1dd70: 67 66 66 66  	.word	0x66666667

