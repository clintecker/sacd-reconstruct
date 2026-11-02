00028218 <scarletbook_output_init_stats>:
   28218: e52db004     	str	r11, [sp, #-0x4]!
   2821c: e28db000     	add	r11, sp, #0
   28220: e24dd014     	sub	sp, sp, #20
   28224: e50b0010     	str	r0, [r11, #-0x10]
   28228: e51b3010     	ldr	r3, [r11, #-0x10]
   2822c: e3a02000     	mov	r2, #0
   28230: e5832020     	str	r2, [r3, #0x20]
   28234: e51b3010     	ldr	r3, [r11, #-0x10]
   28238: e3a02000     	mov	r2, #0
   2823c: e5832024     	str	r2, [r3, #0x24]
   28240: e51b3010     	ldr	r3, [r11, #-0x10]
   28244: e3a02000     	mov	r2, #0
   28248: e5832028     	str	r2, [r3, #0x28]
   2824c: e51b3010     	ldr	r3, [r11, #-0x10]
   28250: e3a02000     	mov	r2, #0
   28254: e583202c     	str	r2, [r3, #0x2c]
   28258: e51b3010     	ldr	r3, [r11, #-0x10]
   2825c: e3a02000     	mov	r2, #0
   28260: e583201c     	str	r2, [r3, #0x1c]
   28264: e51b3010     	ldr	r3, [r11, #-0x10]
   28268: e3a02000     	mov	r2, #0
   2826c: e5832018     	str	r2, [r3, #0x18]
   28270: e51b3010     	ldr	r3, [r11, #-0x10]
   28274: e5933000     	ldr	r3, [r3]
   28278: e50b300c     	str	r3, [r11, #-0xc]
   2827c: ea000011     	b	0x282c8 <scarletbook_output_init_stats+0xb0> @ imm = #0x44
   28280: e51b300c     	ldr	r3, [r11, #-0xc]
   28284: e2433e17     	sub	r3, r3, #368
   28288: e50b3008     	str	r3, [r11, #-0x8]
   2828c: e51b3010     	ldr	r3, [r11, #-0x10]
   28290: e5932020     	ldr	r2, [r3, #0x20]
   28294: e51b3008     	ldr	r3, [r11, #-0x8]
   28298: e593300c     	ldr	r3, [r3, #0xc]
   2829c: e0822003     	add	r2, r2, r3
   282a0: e51b3010     	ldr	r3, [r11, #-0x10]
   282a4: e5832020     	str	r2, [r3, #0x20]
   282a8: e51b3010     	ldr	r3, [r11, #-0x10]
   282ac: e5933018     	ldr	r3, [r3, #0x18]
   282b0: e2832001     	add	r2, r3, #1
   282b4: e51b3010     	ldr	r3, [r11, #-0x10]
   282b8: e5832018     	str	r2, [r3, #0x18]
   282bc: e51b300c     	ldr	r3, [r11, #-0xc]
   282c0: e5933000     	ldr	r3, [r3]
   282c4: e50b300c     	str	r3, [r11, #-0xc]
   282c8: e51b300c     	ldr	r3, [r11, #-0xc]
   282cc: e5932000     	ldr	r2, [r3]
   282d0: e51b300c     	ldr	r3, [r11, #-0xc]
   282d4: e5832000     	str	r2, [r3]
   282d8: e51b2010     	ldr	r2, [r11, #-0x10]
   282dc: e51b300c     	ldr	r3, [r11, #-0xc]
   282e0: e1520003     	cmp	r2, r3
   282e4: 1affffe5     	bne	0x28280 <scarletbook_output_init_stats+0x68> @ imm = #-0x6c
   282e8: e28bd000     	add	sp, r11, #0
   282ec: e8bd0800     	ldm	sp!, {r11}
   282f0: e12fff1e     	bx	lr

