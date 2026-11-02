0001a15c <FreeDecMemory>:
   1a15c: e92d4800     	push	{r11, lr}
   1a160: e28db004     	add	r11, sp, #4
   1a164: e24dd008     	sub	sp, sp, #8
   1a168: e50b0008     	str	r0, [r11, #-0x8]
   1a16c: e51b3008     	ldr	r3, [r11, #-0x8]
   1a170: e5933074     	ldr	r3, [r3, #0x74]
   1a174: e5933000     	ldr	r3, [r3]
   1a178: e1a00003     	mov	r0, r3
   1a17c: ebffff55     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x2ac
   1a180: e51b3008     	ldr	r3, [r11, #-0x8]
   1a184: e5933074     	ldr	r3, [r3, #0x74]
   1a188: e1a00003     	mov	r0, r3
   1a18c: ebffff51     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x2bc
   1a190: e51b2008     	ldr	r2, [r11, #-0x8]
   1a194: e59f31e4     	ldr	r3, [pc, #0x1e4]        @ 0x1a380 <FreeDecMemory+0x224>
   1a198: e7923003     	ldr	r3, [r2, r3]
   1a19c: e5933000     	ldr	r3, [r3]
   1a1a0: e1a00003     	mov	r0, r3
   1a1a4: ebffff4b     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x2d4
   1a1a8: e51b2008     	ldr	r2, [r11, #-0x8]
   1a1ac: e59f31cc     	ldr	r3, [pc, #0x1cc]        @ 0x1a380 <FreeDecMemory+0x224>
   1a1b0: e7923003     	ldr	r3, [r2, r3]
   1a1b4: e1a00003     	mov	r0, r3
   1a1b8: ebffff46     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x2e8
   1a1bc: e51b2008     	ldr	r2, [r11, #-0x8]
   1a1c0: e59f31bc     	ldr	r3, [pc, #0x1bc]        @ 0x1a384 <FreeDecMemory+0x228>
   1a1c4: e7923003     	ldr	r3, [r2, r3]
   1a1c8: e5933000     	ldr	r3, [r3]
   1a1cc: e1a00003     	mov	r0, r3
   1a1d0: ebffff40     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x300
   1a1d4: e51b2008     	ldr	r2, [r11, #-0x8]
   1a1d8: e59f31a4     	ldr	r3, [pc, #0x1a4]        @ 0x1a384 <FreeDecMemory+0x228>
   1a1dc: e7923003     	ldr	r3, [r2, r3]
   1a1e0: e1a00003     	mov	r0, r3
   1a1e4: ebffff3b     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x314
   1a1e8: e51b2008     	ldr	r2, [r11, #-0x8]
   1a1ec: e59f3194     	ldr	r3, [pc, #0x194]        @ 0x1a388 <FreeDecMemory+0x22c>
   1a1f0: e7923003     	ldr	r3, [r2, r3]
   1a1f4: e1a00003     	mov	r0, r3
   1a1f8: ebffff36     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x328
   1a1fc: e51b2008     	ldr	r2, [r11, #-0x8]
   1a200: e59f3184     	ldr	r3, [pc, #0x184]        @ 0x1a38c <FreeDecMemory+0x230>
   1a204: e7923003     	ldr	r3, [r2, r3]
   1a208: e5933000     	ldr	r3, [r3]
   1a20c: e1a00003     	mov	r0, r3
   1a210: ebffff30     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x340
   1a214: e51b2008     	ldr	r2, [r11, #-0x8]
   1a218: e59f316c     	ldr	r3, [pc, #0x16c]        @ 0x1a38c <FreeDecMemory+0x230>
   1a21c: e7923003     	ldr	r3, [r2, r3]
   1a220: e1a00003     	mov	r0, r3
   1a224: ebffff2b     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x354
   1a228: e51b2008     	ldr	r2, [r11, #-0x8]
   1a22c: e59f315c     	ldr	r3, [pc, #0x15c]        @ 0x1a390 <FreeDecMemory+0x234>
   1a230: e7923003     	ldr	r3, [r2, r3]
   1a234: e1a00003     	mov	r0, r3
   1a238: ebffff26     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x368
   1a23c: e51b2008     	ldr	r2, [r11, #-0x8]
   1a240: e59f314c     	ldr	r3, [pc, #0x14c]        @ 0x1a394 <FreeDecMemory+0x238>
   1a244: e7923003     	ldr	r3, [r2, r3]
   1a248: e1a00003     	mov	r0, r3
   1a24c: ebffff21     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x37c
   1a250: e51b2008     	ldr	r2, [r11, #-0x8]
   1a254: e59f313c     	ldr	r3, [pc, #0x13c]        @ 0x1a398 <FreeDecMemory+0x23c>
   1a258: e7923003     	ldr	r3, [r2, r3]
   1a25c: e1a00003     	mov	r0, r3
   1a260: ebffff1c     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x390
   1a264: e51b2008     	ldr	r2, [r11, #-0x8]
   1a268: e59f312c     	ldr	r3, [pc, #0x12c]        @ 0x1a39c <FreeDecMemory+0x240>
   1a26c: e7923003     	ldr	r3, [r2, r3]
   1a270: e5933000     	ldr	r3, [r3]
   1a274: e1a00003     	mov	r0, r3
   1a278: ebffff16     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x3a8
   1a27c: e51b2008     	ldr	r2, [r11, #-0x8]
   1a280: e59f3114     	ldr	r3, [pc, #0x114]        @ 0x1a39c <FreeDecMemory+0x240>
   1a284: e7923003     	ldr	r3, [r2, r3]
   1a288: e1a00003     	mov	r0, r3
   1a28c: ebffff11     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x3bc
   1a290: e51b2008     	ldr	r2, [r11, #-0x8]
   1a294: e59f3104     	ldr	r3, [pc, #0x104]        @ 0x1a3a0 <FreeDecMemory+0x244>
   1a298: e7923003     	ldr	r3, [r2, r3]
   1a29c: e5933000     	ldr	r3, [r3]
   1a2a0: e1a00003     	mov	r0, r3
   1a2a4: ebffff0b     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x3d4
   1a2a8: e51b2008     	ldr	r2, [r11, #-0x8]
   1a2ac: e59f30ec     	ldr	r3, [pc, #0xec]         @ 0x1a3a0 <FreeDecMemory+0x244>
   1a2b0: e7923003     	ldr	r3, [r2, r3]
   1a2b4: e1a00003     	mov	r0, r3
   1a2b8: ebffff06     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x3e8
   1a2bc: e51b2008     	ldr	r2, [r11, #-0x8]
   1a2c0: e59f30dc     	ldr	r3, [pc, #0xdc]         @ 0x1a3a4 <FreeDecMemory+0x248>
   1a2c4: e7923003     	ldr	r3, [r2, r3]
   1a2c8: e1a00003     	mov	r0, r3
   1a2cc: ebffff01     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x3fc
   1a2d0: e51b2008     	ldr	r2, [r11, #-0x8]
   1a2d4: e59f30cc     	ldr	r3, [pc, #0xcc]         @ 0x1a3a8 <FreeDecMemory+0x24c>
   1a2d8: e7923003     	ldr	r3, [r2, r3]
   1a2dc: e5933000     	ldr	r3, [r3]
   1a2e0: e1a00003     	mov	r0, r3
   1a2e4: ebfffefb     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x414
   1a2e8: e51b2008     	ldr	r2, [r11, #-0x8]
   1a2ec: e59f30b4     	ldr	r3, [pc, #0xb4]         @ 0x1a3a8 <FreeDecMemory+0x24c>
   1a2f0: e7923003     	ldr	r3, [r2, r3]
   1a2f4: e1a00003     	mov	r0, r3
   1a2f8: ebfffef6     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x428
   1a2fc: e51b2008     	ldr	r2, [r11, #-0x8]
   1a300: e59f30a4     	ldr	r3, [pc, #0xa4]         @ 0x1a3ac <FreeDecMemory+0x250>
   1a304: e7923003     	ldr	r3, [r2, r3]
   1a308: e1a00003     	mov	r0, r3
   1a30c: ebfffef1     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x43c
   1a310: e51b2008     	ldr	r2, [r11, #-0x8]
   1a314: e59f3094     	ldr	r3, [pc, #0x94]         @ 0x1a3b0 <FreeDecMemory+0x254>
   1a318: e7923003     	ldr	r3, [r2, r3]
   1a31c: e1a00003     	mov	r0, r3
   1a320: ebfffeec     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x450
   1a324: e51b2008     	ldr	r2, [r11, #-0x8]
   1a328: e59f3084     	ldr	r3, [pc, #0x84]         @ 0x1a3b4 <FreeDecMemory+0x258>
   1a32c: e7923003     	ldr	r3, [r2, r3]
   1a330: e1a00003     	mov	r0, r3
   1a334: ebfffee7     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x464
   1a338: e51b2008     	ldr	r2, [r11, #-0x8]
   1a33c: e59f3074     	ldr	r3, [pc, #0x74]         @ 0x1a3b8 <FreeDecMemory+0x25c>
   1a340: e7923003     	ldr	r3, [r2, r3]
   1a344: e5933000     	ldr	r3, [r3]
   1a348: e1a00003     	mov	r0, r3
   1a34c: ebfffee1     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x47c
   1a350: e51b2008     	ldr	r2, [r11, #-0x8]
   1a354: e59f305c     	ldr	r3, [pc, #0x5c]         @ 0x1a3b8 <FreeDecMemory+0x25c>
   1a358: e7923003     	ldr	r3, [r2, r3]
   1a35c: e1a00003     	mov	r0, r3
   1a360: ebfffedc     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x490
   1a364: e51b2008     	ldr	r2, [r11, #-0x8]
   1a368: e59f304c     	ldr	r3, [pc, #0x4c]         @ 0x1a3bc <FreeDecMemory+0x260>
   1a36c: e7923003     	ldr	r3, [r2, r3]
   1a370: e1a00003     	mov	r0, r3
   1a374: ebfffed7     	bl	0x19ed8 <MemoryFree>    @ imm = #-0x4a4
   1a378: e24bd004     	sub	sp, r11, #4
   1a37c: e8bd8800     	pop	{r11, pc}
   1a380: 30 e8 06 00  	.word	0x0006e830
   1a384: 34 e8 06 00  	.word	0x0006e834
   1a388: 20 e8 06 00  	.word	0x0006e820
   1a38c: 24 e8 06 00  	.word	0x0006e824
   1a390: 28 e8 06 00  	.word	0x0006e828
   1a394: 2c e8 06 00  	.word	0x0006e82c
   1a398: 38 e8 06 00  	.word	0x0006e838
   1a39c: 54 e8 06 00  	.word	0x0006e854
   1a3a0: 58 e8 06 00  	.word	0x0006e858
   1a3a4: 44 e8 06 00  	.word	0x0006e844
   1a3a8: 48 e8 06 00  	.word	0x0006e848
   1a3ac: 4c e8 06 00  	.word	0x0006e84c
   1a3b0: 50 e8 06 00  	.word	0x0006e850
   1a3b4: 5c e8 06 00  	.word	0x0006e85c
   1a3b8: 68 e8 06 00  	.word	0x0006e868
   1a3bc: 6c e8 06 00  	.word	0x0006e86c

