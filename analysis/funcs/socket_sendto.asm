00012fc4 <socket_sendto>:
   12fc4: e92d4800     	push	{r11, lr}
   12fc8: e28db004     	add	r11, sp, #4
   12fcc: e24dd020     	sub	sp, sp, #32
   12fd0: e50b0010     	str	r0, [r11, #-0x10]
   12fd4: e50b1014     	str	r1, [r11, #-0x14]
   12fd8: e50b2018     	str	r2, [r11, #-0x18]
   12fdc: e50b301c     	str	r3, [r11, #-0x1c]
   12fe0: e51b301c     	ldr	r3, [r11, #-0x1c]
   12fe4: e3a02000     	mov	r2, #0
   12fe8: e5832000     	str	r2, [r3]
   12fec: e51b3010     	ldr	r3, [r11, #-0x10]
   12ff0: e5933000     	ldr	r3, [r3]
   12ff4: e3730001     	cmn	r3, #1
   12ff8: 1a000002     	bne	0x13008 <socket_sendto+0x44> @ imm = #0x8
   12ffc: e3e03001     	mvn	r3, #1
   13000: ea000037     	b	0x130e4 <socket_sendto+0x120> @ imm = #0xdc
   13004: e1a00000     	mov	r0, r0
   13008: e51b3010     	ldr	r3, [r11, #-0x10]
   1300c: e5932000     	ldr	r2, [r3]
   13010: e59b1004     	ldr	r1, [r11, #0x4]
   13014: e3a03000     	mov	r3, #0
   13018: e1a03001     	mov	r3, r1
   1301c: e58d3000     	str	r3, [sp]
   13020: e59b3008     	ldr	r3, [r11, #0x8]
   13024: e58d3004     	str	r3, [sp, #0x4]
   13028: e1a00002     	mov	r0, r2
   1302c: e51b1014     	ldr	r1, [r11, #-0x14]
   13030: e51b2018     	ldr	r2, [r11, #-0x18]
   13034: e3a03000     	mov	r3, #0
   13038: ebffe4d0     	bl	0xc380 <sendto@plt>     @ imm = #-0x6cc0
   1303c: e1a03000     	mov	r3, r0
   13040: e50b3008     	str	r3, [r11, #-0x8]
   13044: e51b3008     	ldr	r3, [r11, #-0x8]
   13048: e3530000     	cmp	r3, #0
   1304c: da000004     	ble	0x13064 <socket_sendto+0xa0> @ imm = #0x10
   13050: e51b2008     	ldr	r2, [r11, #-0x8]
   13054: e51b301c     	ldr	r3, [r11, #-0x1c]
   13058: e5832000     	str	r2, [r3]
   1305c: e3a03000     	mov	r3, #0
   13060: ea00001f     	b	0x130e4 <socket_sendto+0x120> @ imm = #0x7c
   13064: ebffe5dc     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x6890
   13068: e1a03000     	mov	r3, r0
   1306c: e5933000     	ldr	r3, [r3]
   13070: e50b300c     	str	r3, [r11, #-0xc]
   13074: e51b3008     	ldr	r3, [r11, #-0x8]
   13078: e3530000     	cmp	r3, #0
   1307c: 0a000002     	beq	0x1308c <socket_sendto+0xc8> @ imm = #0x8
   13080: e51b300c     	ldr	r3, [r11, #-0xc]
   13084: e3530020     	cmp	r3, #32
   13088: 1a000001     	bne	0x13094 <socket_sendto+0xd0> @ imm = #0x4
   1308c: e3e03001     	mvn	r3, #1
   13090: ea000013     	b	0x130e4 <socket_sendto+0x120> @ imm = #0x4c
   13094: e51b300c     	ldr	r3, [r11, #-0xc]
   13098: e3530004     	cmp	r3, #4
   1309c: 1a000001     	bne	0x130a8 <socket_sendto+0xe4> @ imm = #0x4
   130a0: e1a00000     	mov	r0, r0
   130a4: eaffffd7     	b	0x13008 <socket_sendto+0x44> @ imm = #-0xa4
   130a8: e51b300c     	ldr	r3, [r11, #-0xc]
   130ac: e353000b     	cmp	r3, #11
   130b0: 0a000001     	beq	0x130bc <socket_sendto+0xf8> @ imm = #0x4
   130b4: e51b300c     	ldr	r3, [r11, #-0xc]
   130b8: ea000009     	b	0x130e4 <socket_sendto+0x120> @ imm = #0x24
   130bc: e51b0010     	ldr	r0, [r11, #-0x10]
   130c0: e3a01002     	mov	r1, #2
   130c4: e59b200c     	ldr	r2, [r11, #0xc]
   130c8: ebfffd28     	bl	0x12570 <socket_waitfd> @ imm = #-0xb60
   130cc: e1a03000     	mov	r3, r0
   130d0: e50b300c     	str	r3, [r11, #-0xc]
   130d4: e51b300c     	ldr	r3, [r11, #-0xc]
   130d8: e3530000     	cmp	r3, #0
   130dc: 0affffc8     	beq	0x13004 <socket_sendto+0x40> @ imm = #-0xe0
   130e0: e51b300c     	ldr	r3, [r11, #-0xc]
   130e4: e1a00003     	mov	r0, r3
   130e8: e24bd004     	sub	sp, r11, #4
   130ec: e8bd8800     	pop	{r11, pc}

