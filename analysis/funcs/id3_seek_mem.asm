0001e074 <id3_seek_mem>:
   1e074: e92d4800     	push	{r11, lr}
   1e078: e28db004     	add	r11, sp, #4
   1e07c: e24dd008     	sub	sp, sp, #8
   1e080: e50b0008     	str	r0, [r11, #-0x8]
   1e084: e50b100c     	str	r1, [r11, #-0xc]
   1e088: e51b3008     	ldr	r3, [r11, #-0x8]
   1e08c: e5932020     	ldr	r2, [r3, #0x20]
   1e090: e51b300c     	ldr	r3, [r11, #-0xc]
   1e094: e0822003     	add	r2, r2, r3
   1e098: e51b3008     	ldr	r3, [r11, #-0x8]
   1e09c: e593301c     	ldr	r3, [r3, #0x1c]
   1e0a0: e1520003     	cmp	r2, r3
   1e0a4: ca000005     	bgt	0x1e0c0 <id3_seek_mem+0x4c> @ imm = #0x14
   1e0a8: e51b3008     	ldr	r3, [r11, #-0x8]
   1e0ac: e5932020     	ldr	r2, [r3, #0x20]
   1e0b0: e51b300c     	ldr	r3, [r11, #-0xc]
   1e0b4: e0823003     	add	r3, r2, r3
   1e0b8: e3530000     	cmp	r3, #0
   1e0bc: aa00000a     	bge	0x1e0ec <id3_seek_mem+0x78> @ imm = #0x28
   1e0c0: e51b3008     	ldr	r3, [r11, #-0x8]
   1e0c4: e59f2060     	ldr	r2, [pc, #0x60]         @ 0x1e12c <id3_seek_mem+0xb8>
   1e0c8: e5832024     	str	r2, [r3, #0x24]
   1e0cc: e59f305c     	ldr	r3, [pc, #0x5c]         @ 0x1e130 <id3_seek_mem+0xbc>
   1e0d0: e1a00003     	mov	r0, r3
   1e0d4: e59f1058     	ldr	r1, [pc, #0x58]         @ 0x1e134 <id3_seek_mem+0xc0>
   1e0d8: e3a0203a     	mov	r2, #58
   1e0dc: e59f3048     	ldr	r3, [pc, #0x48]         @ 0x1e12c <id3_seek_mem+0xb8>
   1e0e0: ebffb921     	bl	0xc56c <printf@plt>     @ imm = #-0x11b7c
   1e0e4: e3e03000     	mvn	r3, #0
   1e0e8: ea00000c     	b	0x1e120 <id3_seek_mem+0xac> @ imm = #0x30
   1e0ec: e51b3008     	ldr	r3, [r11, #-0x8]
   1e0f0: e5932128     	ldr	r2, [r3, #0x128]
   1e0f4: e51b300c     	ldr	r3, [r11, #-0xc]
   1e0f8: e0822003     	add	r2, r2, r3
   1e0fc: e51b3008     	ldr	r3, [r11, #-0x8]
   1e100: e5832128     	str	r2, [r3, #0x128]
   1e104: e51b3008     	ldr	r3, [r11, #-0x8]
   1e108: e5932020     	ldr	r2, [r3, #0x20]
   1e10c: e51b300c     	ldr	r3, [r11, #-0xc]
   1e110: e0822003     	add	r2, r2, r3
   1e114: e51b3008     	ldr	r3, [r11, #-0x8]
   1e118: e5832020     	str	r2, [r3, #0x20]
   1e11c: e3a03000     	mov	r3, #0
   1e120: e1a00003     	mov	r0, r3
   1e124: e24bd004     	sub	sp, r11, #4
   1e128: e8bd8800     	pop	{r11, pc}
   1e12c: 18 39 03 00  	.word	0x00033918
   1e130: 34 39 03 00  	.word	0x00033934
   1e134: 4c 39 03 00  	.word	0x0003394c

