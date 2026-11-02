0001cc04 <find_v24_id>:
   1cc04: e52db004     	str	r11, [sp, #-0x4]!
   1cc08: e28db000     	add	r11, sp, #0
   1cc0c: e24dd014     	sub	sp, sp, #20
   1cc10: e50b0010     	str	r0, [r11, #-0x10]
   1cc14: e3a03000     	mov	r3, #0
   1cc18: e50b3008     	str	r3, [r11, #-0x8]
   1cc1c: ea000010     	b	0x1cc64 <find_v24_id+0x60> @ imm = #0x40
   1cc20: e51b2008     	ldr	r2, [r11, #-0x8]
   1cc24: e59f3058     	ldr	r3, [pc, #0x58]         @ 0x1cc84 <find_v24_id+0x80>
   1cc28: e7932182     	ldr	r2, [r3, r2, lsl #3]
   1cc2c: e51b3010     	ldr	r3, [r11, #-0x10]
   1cc30: e1520003     	cmp	r2, r3
   1cc34: 1a000007     	bne	0x1cc58 <find_v24_id+0x54> @ imm = #0x1c
   1cc38: e51b2008     	ldr	r2, [r11, #-0x8]
   1cc3c: e59f1040     	ldr	r1, [pc, #0x40]         @ 0x1cc84 <find_v24_id+0x80>
   1cc40: e3a03004     	mov	r3, #4
   1cc44: e1a02182     	lsl	r2, r2, #3
   1cc48: e0812002     	add	r2, r1, r2
   1cc4c: e0823003     	add	r3, r2, r3
   1cc50: e5933000     	ldr	r3, [r3]
   1cc54: ea000006     	b	0x1cc74 <find_v24_id+0x70> @ imm = #0x18
   1cc58: e51b3008     	ldr	r3, [r11, #-0x8]
   1cc5c: e2833001     	add	r3, r3, #1
   1cc60: e50b3008     	str	r3, [r11, #-0x8]
   1cc64: e51b3008     	ldr	r3, [r11, #-0x8]
   1cc68: e353003e     	cmp	r3, #62
   1cc6c: daffffeb     	ble	0x1cc20 <find_v24_id+0x1c> @ imm = #-0x54
   1cc70: e3a03000     	mov	r3, #0
   1cc74: e1a00003     	mov	r0, r3
   1cc78: e28bd000     	add	sp, r11, #0
   1cc7c: e8bd0800     	ldm	sp!, {r11}
   1cc80: e12fff1e     	bx	lr
   1cc84: 90 ec 03 00  	.word	0x0003ec90

