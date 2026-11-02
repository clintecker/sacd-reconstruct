000131f8 <socket_recvfrom>:
   131f8: e92d4800     	push	{r11, lr}
   131fc: e28db004     	add	r11, sp, #4
   13200: e24dd020     	sub	sp, sp, #32
   13204: e50b0010     	str	r0, [r11, #-0x10]
   13208: e50b1014     	str	r1, [r11, #-0x14]
   1320c: e50b2018     	str	r2, [r11, #-0x18]
   13210: e50b301c     	str	r3, [r11, #-0x1c]
   13214: e51b301c     	ldr	r3, [r11, #-0x1c]
   13218: e3a02000     	mov	r2, #0
   1321c: e5832000     	str	r2, [r3]
   13220: e51b3010     	ldr	r3, [r11, #-0x10]
   13224: e5933000     	ldr	r3, [r3]
   13228: e3730001     	cmn	r3, #1
   1322c: 1a000002     	bne	0x1323c <socket_recvfrom+0x44> @ imm = #0x8
   13230: e3e03001     	mvn	r3, #1
   13234: ea000034     	b	0x1330c <socket_recvfrom+0x114> @ imm = #0xd0
   13238: e1a00000     	mov	r0, r0
   1323c: e51b3010     	ldr	r3, [r11, #-0x10]
   13240: e5932000     	ldr	r2, [r3]
   13244: e59b1004     	ldr	r1, [r11, #0x4]
   13248: e3a03000     	mov	r3, #0
   1324c: e1a03001     	mov	r3, r1
   13250: e58d3000     	str	r3, [sp]
   13254: e59b3008     	ldr	r3, [r11, #0x8]
   13258: e58d3004     	str	r3, [sp, #0x4]
   1325c: e1a00002     	mov	r0, r2
   13260: e51b1014     	ldr	r1, [r11, #-0x14]
   13264: e51b2018     	ldr	r2, [r11, #-0x18]
   13268: e3a03000     	mov	r3, #0
   1326c: ebffe54b     	bl	0xc7a0 <recvfrom@plt>   @ imm = #-0x6ad4
   13270: e1a03000     	mov	r3, r0
   13274: e50b3008     	str	r3, [r11, #-0x8]
   13278: e51b3008     	ldr	r3, [r11, #-0x8]
   1327c: e3530000     	cmp	r3, #0
   13280: da000004     	ble	0x13298 <socket_recvfrom+0xa0> @ imm = #0x10
   13284: e51b2008     	ldr	r2, [r11, #-0x8]
   13288: e51b301c     	ldr	r3, [r11, #-0x1c]
   1328c: e5832000     	str	r2, [r3]
   13290: e3a03000     	mov	r3, #0
   13294: ea00001c     	b	0x1330c <socket_recvfrom+0x114> @ imm = #0x70
   13298: ebffe54f     	bl	0xc7dc <__errno_location@plt> @ imm = #-0x6ac4
   1329c: e1a03000     	mov	r3, r0
   132a0: e5933000     	ldr	r3, [r3]
   132a4: e50b300c     	str	r3, [r11, #-0xc]
   132a8: e51b3008     	ldr	r3, [r11, #-0x8]
   132ac: e3530000     	cmp	r3, #0
   132b0: 1a000001     	bne	0x132bc <socket_recvfrom+0xc4> @ imm = #0x4
   132b4: e3e03001     	mvn	r3, #1
   132b8: ea000013     	b	0x1330c <socket_recvfrom+0x114> @ imm = #0x4c
   132bc: e51b300c     	ldr	r3, [r11, #-0xc]
   132c0: e3530004     	cmp	r3, #4
   132c4: 1a000001     	bne	0x132d0 <socket_recvfrom+0xd8> @ imm = #0x4
   132c8: e1a00000     	mov	r0, r0
   132cc: eaffffda     	b	0x1323c <socket_recvfrom+0x44> @ imm = #-0x98
   132d0: e51b300c     	ldr	r3, [r11, #-0xc]
   132d4: e353000b     	cmp	r3, #11
   132d8: 0a000001     	beq	0x132e4 <socket_recvfrom+0xec> @ imm = #0x4
   132dc: e51b300c     	ldr	r3, [r11, #-0xc]
   132e0: ea000009     	b	0x1330c <socket_recvfrom+0x114> @ imm = #0x24
   132e4: e51b0010     	ldr	r0, [r11, #-0x10]
   132e8: e3a01001     	mov	r1, #1
   132ec: e59b200c     	ldr	r2, [r11, #0xc]
   132f0: ebfffc9e     	bl	0x12570 <socket_waitfd> @ imm = #-0xd88
   132f4: e1a03000     	mov	r3, r0
   132f8: e50b300c     	str	r3, [r11, #-0xc]
   132fc: e51b300c     	ldr	r3, [r11, #-0xc]
   13300: e3530000     	cmp	r3, #0
   13304: 0affffcb     	beq	0x13238 <socket_recvfrom+0x40> @ imm = #-0xd4
   13308: e51b300c     	ldr	r3, [r11, #-0xc]
   1330c: e1a00003     	mov	r0, r3
   13310: e24bd004     	sub	sp, r11, #4
   13314: e8bd8800     	pop	{r11, pc}

