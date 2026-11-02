0001c69c <id3_get_frame>:
   1c69c: e52db004     	str	r11, [sp, #-0x4]!
   1c6a0: e28db000     	add	r11, sp, #0
   1c6a4: e24dd01c     	sub	sp, sp, #28
   1c6a8: e50b0010     	str	r0, [r11, #-0x10]
   1c6ac: e50b1014     	str	r1, [r11, #-0x14]
   1c6b0: e50b2018     	str	r2, [r11, #-0x18]
   1c6b4: e51b3010     	ldr	r3, [r11, #-0x10]
   1c6b8: e5933138     	ldr	r3, [r3, #0x138]
   1c6bc: e50b300c     	str	r3, [r11, #-0xc]
   1c6c0: ea000017     	b	0x1c724 <id3_get_frame+0x88> @ imm = #0x5c
   1c6c4: e51b300c     	ldr	r3, [r11, #-0xc]
   1c6c8: e2433028     	sub	r3, r3, #40
   1c6cc: e50b3008     	str	r3, [r11, #-0x8]
   1c6d0: e51b3008     	ldr	r3, [r11, #-0x8]
   1c6d4: e5933004     	ldr	r3, [r3, #0x4]
   1c6d8: e3530000     	cmp	r3, #0
   1c6dc: 0a00000d     	beq	0x1c718 <id3_get_frame+0x7c> @ imm = #0x34
   1c6e0: e51b3008     	ldr	r3, [r11, #-0x8]
   1c6e4: e5933004     	ldr	r3, [r3, #0x4]
   1c6e8: e5932000     	ldr	r2, [r3]
   1c6ec: e51b3014     	ldr	r3, [r11, #-0x14]
   1c6f0: e1520003     	cmp	r2, r3
   1c6f4: 1a000007     	bne	0x1c718 <id3_get_frame+0x7c> @ imm = #0x1c
   1c6f8: e51b3018     	ldr	r3, [r11, #-0x18]
   1c6fc: e2433001     	sub	r3, r3, #1
   1c700: e50b3018     	str	r3, [r11, #-0x18]
   1c704: e51b3018     	ldr	r3, [r11, #-0x18]
   1c708: e3530000     	cmp	r3, #0
   1c70c: ca000001     	bgt	0x1c718 <id3_get_frame+0x7c> @ imm = #0x4
   1c710: e51b3008     	ldr	r3, [r11, #-0x8]
   1c714: ea00000c     	b	0x1c74c <id3_get_frame+0xb0> @ imm = #0x30
   1c718: e51b300c     	ldr	r3, [r11, #-0xc]
   1c71c: e5933000     	ldr	r3, [r3]
   1c720: e50b300c     	str	r3, [r11, #-0xc]
   1c724: e51b300c     	ldr	r3, [r11, #-0xc]
   1c728: e5932000     	ldr	r2, [r3]
   1c72c: e51b300c     	ldr	r3, [r11, #-0xc]
   1c730: e5832000     	str	r2, [r3]
   1c734: e51b3010     	ldr	r3, [r11, #-0x10]
   1c738: e2832f4e     	add	r2, r3, #312
   1c73c: e51b300c     	ldr	r3, [r11, #-0xc]
   1c740: e1520003     	cmp	r2, r3
   1c744: 1affffde     	bne	0x1c6c4 <id3_get_frame+0x28> @ imm = #-0x88
   1c748: e3a03000     	mov	r3, #0
   1c74c: e1a00003     	mov	r0, r3
   1c750: e28bd000     	add	sp, r11, #0
   1c754: e8bd0800     	ldm	sp!, {r11}
   1c758: e12fff1e     	bx	lr

