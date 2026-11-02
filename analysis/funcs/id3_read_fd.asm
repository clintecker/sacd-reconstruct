0001e2f0 <id3_read_fd>:
   1e2f0: e92d4800     	push	{r11, lr}
   1e2f4: e28db004     	add	r11, sp, #4
   1e2f8: e24dd020     	sub	sp, sp, #32
   1e2fc: e50b0018     	str	r0, [r11, #-0x18]
   1e300: e50b101c     	str	r1, [r11, #-0x1c]
   1e304: e50b2020     	str	r2, [r11, #-0x20]
   1e308: e3a03000     	mov	r3, #0
   1e30c: e50b3010     	str	r3, [r11, #-0x10]
   1e310: e51b3018     	ldr	r3, [r11, #-0x18]
   1e314: e5932020     	ldr	r2, [r3, #0x20]
   1e318: e51b3020     	ldr	r3, [r11, #-0x20]
   1e31c: e0822003     	add	r2, r2, r3
   1e320: e51b3018     	ldr	r3, [r11, #-0x18]
   1e324: e593301c     	ldr	r3, [r3, #0x1c]
   1e328: e1520003     	cmp	r2, r3
   1e32c: da000001     	ble	0x1e338 <id3_read_fd+0x48> @ imm = #0x4
   1e330: e3a03000     	mov	r3, #0
   1e334: ea000035     	b	0x1e410 <id3_read_fd+0x120> @ imm = #0xd4
   1e338: e51b301c     	ldr	r3, [r11, #-0x1c]
   1e33c: e3530000     	cmp	r3, #0
   1e340: 1a00002d     	bne	0x1e3fc <id3_read_fd+0x10c> @ imm = #0xb4
   1e344: e51b3020     	ldr	r3, [r11, #-0x20]
   1e348: e3530a02     	cmp	r3, #8192
   1e34c: da000001     	ble	0x1e358 <id3_read_fd+0x68> @ imm = #0x4
   1e350: e3a03000     	mov	r3, #0
   1e354: ea00002d     	b	0x1e410 <id3_read_fd+0x120> @ imm = #0xb4
   1e358: e51b3018     	ldr	r3, [r11, #-0x18]
   1e35c: e593312c     	ldr	r3, [r3, #0x12c]
   1e360: e50b301c     	str	r3, [r11, #-0x1c]
   1e364: ea000024     	b	0x1e3fc <id3_read_fd+0x10c> @ imm = #0x90
   1e368: e51b201c     	ldr	r2, [r11, #-0x1c]
   1e36c: e51b3010     	ldr	r3, [r11, #-0x10]
   1e370: e0823003     	add	r3, r2, r3
   1e374: e50b300c     	str	r3, [r11, #-0xc]
   1e378: e51b3018     	ldr	r3, [r11, #-0x18]
   1e37c: e5932128     	ldr	r2, [r3, #0x128]
   1e380: e51b3020     	ldr	r3, [r11, #-0x20]
   1e384: e1a00002     	mov	r0, r2
   1e388: e51b100c     	ldr	r1, [r11, #-0xc]
   1e38c: e1a02003     	mov	r2, r3
   1e390: ebffb824     	bl	0xc428 <read@plt>       @ imm = #-0x11f70
   1e394: e1a03000     	mov	r3, r0
   1e398: e50b3008     	str	r3, [r11, #-0x8]
   1e39c: e51b3008     	ldr	r3, [r11, #-0x8]
   1e3a0: e3530000     	cmp	r3, #0
   1e3a4: ca00000a     	bgt	0x1e3d4 <id3_read_fd+0xe4> @ imm = #0x28
   1e3a8: e51b3018     	ldr	r3, [r11, #-0x18]
   1e3ac: e59f2068     	ldr	r2, [pc, #0x68]         @ 0x1e41c <id3_read_fd+0x12c>
   1e3b0: e5832024     	str	r2, [r3, #0x24]
   1e3b4: e59f3064     	ldr	r3, [pc, #0x64]         @ 0x1e420 <id3_read_fd+0x130>
   1e3b8: e1a00003     	mov	r0, r3
   1e3bc: e59f1060     	ldr	r1, [pc, #0x60]         @ 0x1e424 <id3_read_fd+0x134>
   1e3c0: e3a020b5     	mov	r2, #181
   1e3c4: e59f3050     	ldr	r3, [pc, #0x50]         @ 0x1e41c <id3_read_fd+0x12c>
   1e3c8: ebffb867     	bl	0xc56c <printf@plt>     @ imm = #-0x11e64
   1e3cc: e3a03000     	mov	r3, #0
   1e3d0: ea00000e     	b	0x1e410 <id3_read_fd+0x120> @ imm = #0x38
   1e3d4: e51b3018     	ldr	r3, [r11, #-0x18]
   1e3d8: e5932020     	ldr	r2, [r3, #0x20]
   1e3dc: e51b3008     	ldr	r3, [r11, #-0x8]
   1e3e0: e0822003     	add	r2, r2, r3
   1e3e4: e51b3018     	ldr	r3, [r11, #-0x18]
   1e3e8: e5832020     	str	r2, [r3, #0x20]
   1e3ec: e51b2010     	ldr	r2, [r11, #-0x10]
   1e3f0: e51b3008     	ldr	r3, [r11, #-0x8]
   1e3f4: e0823003     	add	r3, r2, r3
   1e3f8: e50b3010     	str	r3, [r11, #-0x10]
   1e3fc: e51b2010     	ldr	r2, [r11, #-0x10]
   1e400: e51b3020     	ldr	r3, [r11, #-0x20]
   1e404: e1520003     	cmp	r2, r3
   1e408: baffffd6     	blt	0x1e368 <id3_read_fd+0x78> @ imm = #-0xa8
   1e40c: e51b301c     	ldr	r3, [r11, #-0x1c]
   1e410: e1a00003     	mov	r0, r3
   1e414: e24bd004     	sub	sp, r11, #4
   1e418: e8bd8800     	pop	{r11, pc}
   1e41c: 70 39 03 00  	.word	0x00033970
   1e420: 34 39 03 00  	.word	0x00033934
   1e424: 4c 39 03 00  	.word	0x0003394c

