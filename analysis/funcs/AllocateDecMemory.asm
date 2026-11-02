0001a3c0 <AllocateDecMemory>:
   1a3c0: e92d4800     	push	{r11, lr}
   1a3c4: e28db004     	add	r11, sp, #4
   1a3c8: e24dd008     	sub	sp, sp, #8
   1a3cc: e50b0008     	str	r0, [r11, #-0x8]
   1a3d0: e51b2008     	ldr	r2, [r11, #-0x8]
   1a3d4: e59f32f4     	ldr	r3, [pc, #0x2f4]        @ 0x1a6d0 <AllocateDecMemory+0x310>
   1a3d8: e7923003     	ldr	r3, [r2, r3]
   1a3dc: e3a00002     	mov	r0, #2
   1a3e0: e3a01002     	mov	r1, #2
   1a3e4: e1a02003     	mov	r2, r3
   1a3e8: e3a03080     	mov	r3, #128
   1a3ec: ebfffec1     	bl	0x19ef8 <AllocateArray> @ imm = #-0x4fc
   1a3f0: e1a03000     	mov	r3, r0
   1a3f4: e1a02003     	mov	r2, r3
   1a3f8: e51b3008     	ldr	r3, [r11, #-0x8]
   1a3fc: e5832074     	str	r2, [r3, #0x74]
   1a400: e51b2008     	ldr	r2, [r11, #-0x8]
   1a404: e59f32c4     	ldr	r3, [pc, #0x2c4]        @ 0x1a6d0 <AllocateDecMemory+0x310>
   1a408: e7923003     	ldr	r3, [r2, r3]
   1a40c: e1a00003     	mov	r0, r3
   1a410: e3a01004     	mov	r1, #4
   1a414: ebfffe92     	bl	0x19e64 <MemoryAllocate> @ imm = #-0x5b8
   1a418: e1a03000     	mov	r3, r0
   1a41c: e1a01003     	mov	r1, r3
   1a420: e51b2008     	ldr	r2, [r11, #-0x8]
   1a424: e59f32a8     	ldr	r3, [pc, #0x2a8]        @ 0x1a6d4 <AllocateDecMemory+0x314>
   1a428: e7821003     	str	r1, [r2, r3]
   1a42c: e51b2008     	ldr	r2, [r11, #-0x8]
   1a430: e59f3298     	ldr	r3, [pc, #0x298]        @ 0x1a6d0 <AllocateDecMemory+0x310>
   1a434: e7923003     	ldr	r3, [r2, r3]
   1a438: e1a00003     	mov	r0, r3
   1a43c: e3a01004     	mov	r1, #4
   1a440: ebfffe87     	bl	0x19e64 <MemoryAllocate> @ imm = #-0x5e4
   1a444: e1a03000     	mov	r3, r0
   1a448: e1a01003     	mov	r1, r3
   1a44c: e51b2008     	ldr	r2, [r11, #-0x8]
   1a450: e59f3280     	ldr	r3, [pc, #0x280]        @ 0x1a6d8 <AllocateDecMemory+0x318>
   1a454: e7821003     	str	r1, [r2, r3]
   1a458: e51b2008     	ldr	r2, [r11, #-0x8]
   1a45c: e59f326c     	ldr	r3, [pc, #0x26c]        @ 0x1a6d0 <AllocateDecMemory+0x310>
   1a460: e7923003     	ldr	r3, [r2, r3]
   1a464: e3a00002     	mov	r0, #2
   1a468: e3a01004     	mov	r1, #4
   1a46c: e1a02003     	mov	r2, r3
   1a470: e3a03003     	mov	r3, #3
   1a474: ebfffe9f     	bl	0x19ef8 <AllocateArray> @ imm = #-0x584
   1a478: e1a03000     	mov	r3, r0
   1a47c: e1a01003     	mov	r1, r3
   1a480: e51b2008     	ldr	r2, [r11, #-0x8]
   1a484: e59f3250     	ldr	r3, [pc, #0x250]        @ 0x1a6dc <AllocateDecMemory+0x31c>
   1a488: e7821003     	str	r1, [r2, r3]
   1a48c: e51b2008     	ldr	r2, [r11, #-0x8]
   1a490: e59f3238     	ldr	r3, [pc, #0x238]        @ 0x1a6d0 <AllocateDecMemory+0x310>
   1a494: e7923003     	ldr	r3, [r2, r3]
   1a498: e3a00002     	mov	r0, #2
   1a49c: e3a01004     	mov	r1, #4
   1a4a0: e1a02003     	mov	r2, r3
   1a4a4: e3a03d12     	mov	r3, #1152
   1a4a8: ebfffe92     	bl	0x19ef8 <AllocateArray> @ imm = #-0x5b8
   1a4ac: e1a03000     	mov	r3, r0
   1a4b0: e1a01003     	mov	r1, r3
   1a4b4: e51b2008     	ldr	r2, [r11, #-0x8]
   1a4b8: e59f3220     	ldr	r3, [pc, #0x220]        @ 0x1a6e0 <AllocateDecMemory+0x320>
   1a4bc: e7821003     	str	r1, [r2, r3]
   1a4c0: e51b2008     	ldr	r2, [r11, #-0x8]
   1a4c4: e59f3204     	ldr	r3, [pc, #0x204]        @ 0x1a6d0 <AllocateDecMemory+0x310>
   1a4c8: e7923003     	ldr	r3, [r2, r3]
   1a4cc: e1a00003     	mov	r0, r3
   1a4d0: e3a01004     	mov	r1, #4
   1a4d4: ebfffe62     	bl	0x19e64 <MemoryAllocate> @ imm = #-0x678
   1a4d8: e1a03000     	mov	r3, r0
   1a4dc: e1a01003     	mov	r1, r3
   1a4e0: e51b2008     	ldr	r2, [r11, #-0x8]
   1a4e4: e59f31f8     	ldr	r3, [pc, #0x1f8]        @ 0x1a6e4 <AllocateDecMemory+0x324>
   1a4e8: e7821003     	str	r1, [r2, r3]
   1a4ec: e3a00003     	mov	r0, #3
   1a4f0: e3a01004     	mov	r1, #4
   1a4f4: ebfffe5a     	bl	0x19e64 <MemoryAllocate> @ imm = #-0x698
   1a4f8: e1a03000     	mov	r3, r0
   1a4fc: e1a01003     	mov	r1, r3
   1a500: e51b2008     	ldr	r2, [r11, #-0x8]
   1a504: e59f31dc     	ldr	r3, [pc, #0x1dc]        @ 0x1a6e8 <AllocateDecMemory+0x328>
   1a508: e7821003     	str	r1, [r2, r3]
   1a50c: e3a00002     	mov	r0, #2
   1a510: e3a01004     	mov	r1, #4
   1a514: e3a02003     	mov	r2, #3
   1a518: e3a03003     	mov	r3, #3
   1a51c: ebfffe75     	bl	0x19ef8 <AllocateArray> @ imm = #-0x62c
   1a520: e1a03000     	mov	r3, r0
   1a524: e1a01003     	mov	r1, r3
   1a528: e51b2008     	ldr	r2, [r11, #-0x8]
   1a52c: e59f31b8     	ldr	r3, [pc, #0x1b8]        @ 0x1a6ec <AllocateDecMemory+0x32c>
   1a530: e7821003     	str	r1, [r2, r3]
   1a534: e51b2008     	ldr	r2, [r11, #-0x8]
   1a538: e59f31b0     	ldr	r3, [pc, #0x1b0]        @ 0x1a6f0 <AllocateDecMemory+0x330>
   1a53c: e7923003     	ldr	r3, [r2, r3]
   1a540: e1a00003     	mov	r0, r3
   1a544: e3a01004     	mov	r1, #4
   1a548: ebfffe45     	bl	0x19e64 <MemoryAllocate> @ imm = #-0x6ec
   1a54c: e1a03000     	mov	r3, r0
   1a550: e1a01003     	mov	r1, r3
   1a554: e51b2008     	ldr	r2, [r11, #-0x8]
   1a558: e59f3194     	ldr	r3, [pc, #0x194]        @ 0x1a6f4 <AllocateDecMemory+0x334>
   1a55c: e7821003     	str	r1, [r2, r3]
   1a560: e51b2008     	ldr	r2, [r11, #-0x8]
   1a564: e59f3184     	ldr	r3, [pc, #0x184]        @ 0x1a6f0 <AllocateDecMemory+0x330>
   1a568: e7923003     	ldr	r3, [r2, r3]
   1a56c: e1a00003     	mov	r0, r3
   1a570: e3a01004     	mov	r1, #4
   1a574: ebfffe3a     	bl	0x19e64 <MemoryAllocate> @ imm = #-0x718
   1a578: e1a03000     	mov	r3, r0
   1a57c: e1a01003     	mov	r1, r3
   1a580: e51b2008     	ldr	r2, [r11, #-0x8]
   1a584: e59f316c     	ldr	r3, [pc, #0x16c]        @ 0x1a6f8 <AllocateDecMemory+0x338>
   1a588: e7821003     	str	r1, [r2, r3]
   1a58c: e51b2008     	ldr	r2, [r11, #-0x8]
   1a590: e59f3158     	ldr	r3, [pc, #0x158]        @ 0x1a6f0 <AllocateDecMemory+0x330>
   1a594: e7923003     	ldr	r3, [r2, r3]
   1a598: e3a00002     	mov	r0, #2
   1a59c: e3a01004     	mov	r1, #4
   1a5a0: e1a02003     	mov	r2, r3
   1a5a4: e3a03003     	mov	r3, #3
   1a5a8: ebfffe52     	bl	0x19ef8 <AllocateArray> @ imm = #-0x6b8
   1a5ac: e1a03000     	mov	r3, r0
   1a5b0: e1a01003     	mov	r1, r3
   1a5b4: e51b2008     	ldr	r2, [r11, #-0x8]
   1a5b8: e59f313c     	ldr	r3, [pc, #0x13c]        @ 0x1a6fc <AllocateDecMemory+0x33c>
   1a5bc: e7821003     	str	r1, [r2, r3]
   1a5c0: e51b2008     	ldr	r2, [r11, #-0x8]
   1a5c4: e59f3124     	ldr	r3, [pc, #0x124]        @ 0x1a6f0 <AllocateDecMemory+0x330>
   1a5c8: e7923003     	ldr	r3, [r2, r3]
   1a5cc: e3a00002     	mov	r0, #2
   1a5d0: e3a01004     	mov	r1, #4
   1a5d4: e1a02003     	mov	r2, r3
   1a5d8: e3a03c02     	mov	r3, #512
   1a5dc: ebfffe45     	bl	0x19ef8 <AllocateArray> @ imm = #-0x6ec
   1a5e0: e1a03000     	mov	r3, r0
   1a5e4: e1a01003     	mov	r1, r3
   1a5e8: e51b2008     	ldr	r2, [r11, #-0x8]
   1a5ec: e59f310c     	ldr	r3, [pc, #0x10c]        @ 0x1a700 <AllocateDecMemory+0x340>
   1a5f0: e7821003     	str	r1, [r2, r3]
   1a5f4: e51b2008     	ldr	r2, [r11, #-0x8]
   1a5f8: e59f30f0     	ldr	r3, [pc, #0xf0]         @ 0x1a6f0 <AllocateDecMemory+0x330>
   1a5fc: e7923003     	ldr	r3, [r2, r3]
   1a600: e1a00003     	mov	r0, r3
   1a604: e3a01004     	mov	r1, #4
   1a608: ebfffe15     	bl	0x19e64 <MemoryAllocate> @ imm = #-0x7ac
   1a60c: e1a03000     	mov	r3, r0
   1a610: e1a01003     	mov	r1, r3
   1a614: e51b2008     	ldr	r2, [r11, #-0x8]
   1a618: e59f30e4     	ldr	r3, [pc, #0xe4]         @ 0x1a704 <AllocateDecMemory+0x344>
   1a61c: e7821003     	str	r1, [r2, r3]
   1a620: e3a00003     	mov	r0, #3
   1a624: e3a01004     	mov	r1, #4
   1a628: ebfffe0d     	bl	0x19e64 <MemoryAllocate> @ imm = #-0x7cc
   1a62c: e1a03000     	mov	r3, r0
   1a630: e1a01003     	mov	r1, r3
   1a634: e51b2008     	ldr	r2, [r11, #-0x8]
   1a638: e59f30c8     	ldr	r3, [pc, #0xc8]         @ 0x1a708 <AllocateDecMemory+0x348>
   1a63c: e7821003     	str	r1, [r2, r3]
   1a640: e3a00002     	mov	r0, #2
   1a644: e3a01004     	mov	r1, #4
   1a648: e3a02003     	mov	r2, #3
   1a64c: e3a03003     	mov	r3, #3
   1a650: ebfffe28     	bl	0x19ef8 <AllocateArray> @ imm = #-0x760
   1a654: e1a03000     	mov	r3, r0
   1a658: e1a01003     	mov	r1, r3
   1a65c: e51b2008     	ldr	r2, [r11, #-0x8]
   1a660: e59f30a4     	ldr	r3, [pc, #0xa4]         @ 0x1a70c <AllocateDecMemory+0x34c>
   1a664: e7821003     	str	r1, [r2, r3]
   1a668: e51b2008     	ldr	r2, [r11, #-0x8]
   1a66c: e59f307c     	ldr	r3, [pc, #0x7c]         @ 0x1a6f0 <AllocateDecMemory+0x330>
   1a670: e7923003     	ldr	r3, [r2, r3]
   1a674: e3a00002     	mov	r0, #2
   1a678: e3a01004     	mov	r1, #4
   1a67c: e1a02003     	mov	r2, r3
   1a680: e3a03040     	mov	r3, #64
   1a684: ebfffe1b     	bl	0x19ef8 <AllocateArray> @ imm = #-0x794
   1a688: e1a03000     	mov	r3, r0
   1a68c: e1a01003     	mov	r1, r3
   1a690: e51b2008     	ldr	r2, [r11, #-0x8]
   1a694: e59f3074     	ldr	r3, [pc, #0x74]         @ 0x1a710 <AllocateDecMemory+0x350>
   1a698: e7821003     	str	r1, [r2, r3]
   1a69c: e51b2008     	ldr	r2, [r11, #-0x8]
   1a6a0: e59f306c     	ldr	r3, [pc, #0x6c]         @ 0x1a714 <AllocateDecMemory+0x354>
   1a6a4: e7923003     	ldr	r3, [r2, r3]
   1a6a8: e1a00003     	mov	r0, r3
   1a6ac: e3a01001     	mov	r1, #1
   1a6b0: ebfffdeb     	bl	0x19e64 <MemoryAllocate> @ imm = #-0x854
   1a6b4: e1a03000     	mov	r3, r0
   1a6b8: e1a01003     	mov	r1, r3
   1a6bc: e51b2008     	ldr	r2, [r11, #-0x8]
   1a6c0: e59f3050     	ldr	r3, [pc, #0x50]         @ 0x1a718 <AllocateDecMemory+0x358>
   1a6c4: e7821003     	str	r1, [r2, r3]
   1a6c8: e24bd004     	sub	sp, r11, #4
   1a6cc: e8bd8800     	pop	{r11, pc}
   1a6d0: 08 e8 06 00  	.word	0x0006e808
   1a6d4: 28 e8 06 00  	.word	0x0006e828
   1a6d8: 2c e8 06 00  	.word	0x0006e82c
   1a6dc: 30 e8 06 00  	.word	0x0006e830
   1a6e0: 34 e8 06 00  	.word	0x0006e834
   1a6e4: 38 e8 06 00  	.word	0x0006e838
   1a6e8: 20 e8 06 00  	.word	0x0006e820
   1a6ec: 24 e8 06 00  	.word	0x0006e824
   1a6f0: 0c e8 06 00  	.word	0x0006e80c
   1a6f4: 4c e8 06 00  	.word	0x0006e84c
   1a6f8: 50 e8 06 00  	.word	0x0006e850
   1a6fc: 54 e8 06 00  	.word	0x0006e854
   1a700: 58 e8 06 00  	.word	0x0006e858
   1a704: 5c e8 06 00  	.word	0x0006e85c
   1a708: 44 e8 06 00  	.word	0x0006e844
   1a70c: 48 e8 06 00  	.word	0x0006e848
   1a710: 68 e8 06 00  	.word	0x0006e868
   1a714: 18 e8 06 00  	.word	0x0006e818
   1a718: 6c e8 06 00  	.word	0x0006e86c

