0001d674 <id3_set_encoding>:
   1d674: e92d4800     	push	{r11, lr}
   1d678: e28db004     	add	r11, sp, #4
   1d67c: e24dd008     	sub	sp, sp, #8
   1d680: e50b0008     	str	r0, [r11, #-0x8]
   1d684: e1a03001     	mov	r3, r1
   1d688: e54b3009     	strb	r3, [r11, #-0x9]
   1d68c: e51b3008     	ldr	r3, [r11, #-0x8]
   1d690: e5933004     	ldr	r3, [r3, #0x4]
   1d694: e5d33004     	ldrb	r3, [r3, #0x4]
   1d698: e3530054     	cmp	r3, #84
   1d69c: 0a00003d     	beq	0x1d798 <id3_set_encoding+0x124> @ imm = #0xf4
   1d6a0: e51b3008     	ldr	r3, [r11, #-0x8]
   1d6a4: e5933004     	ldr	r3, [r3, #0x4]
   1d6a8: e5932000     	ldr	r2, [r3]
   1d6ac: e59f3144     	ldr	r3, [pc, #0x144]        @ 0x1d7f8 <id3_set_encoding+0x184>
   1d6b0: e1520003     	cmp	r2, r3
   1d6b4: 0a000037     	beq	0x1d798 <id3_set_encoding+0x124> @ imm = #0xdc
   1d6b8: e51b3008     	ldr	r3, [r11, #-0x8]
   1d6bc: e5933004     	ldr	r3, [r3, #0x4]
   1d6c0: e5932000     	ldr	r2, [r3]
   1d6c4: e59f3130     	ldr	r3, [pc, #0x130]        @ 0x1d7fc <id3_set_encoding+0x188>
   1d6c8: e1520003     	cmp	r2, r3
   1d6cc: 0a000031     	beq	0x1d798 <id3_set_encoding+0x124> @ imm = #0xc4
   1d6d0: e51b3008     	ldr	r3, [r11, #-0x8]
   1d6d4: e5933004     	ldr	r3, [r3, #0x4]
   1d6d8: e5932000     	ldr	r2, [r3]
   1d6dc: e59f311c     	ldr	r3, [pc, #0x11c]        @ 0x1d800 <id3_set_encoding+0x18c>
   1d6e0: e1520003     	cmp	r2, r3
   1d6e4: 0a00002b     	beq	0x1d798 <id3_set_encoding+0x124> @ imm = #0xac
   1d6e8: e51b3008     	ldr	r3, [r11, #-0x8]
   1d6ec: e5933004     	ldr	r3, [r3, #0x4]
   1d6f0: e5932000     	ldr	r2, [r3]
   1d6f4: e59f3108     	ldr	r3, [pc, #0x108]        @ 0x1d804 <id3_set_encoding+0x190>
   1d6f8: e1520003     	cmp	r2, r3
   1d6fc: 0a000025     	beq	0x1d798 <id3_set_encoding+0x124> @ imm = #0x94
   1d700: e51b3008     	ldr	r3, [r11, #-0x8]
   1d704: e5933004     	ldr	r3, [r3, #0x4]
   1d708: e5932000     	ldr	r2, [r3]
   1d70c: e59f30f4     	ldr	r3, [pc, #0xf4]         @ 0x1d808 <id3_set_encoding+0x194>
   1d710: e1520003     	cmp	r2, r3
   1d714: 0a00001f     	beq	0x1d798 <id3_set_encoding+0x124> @ imm = #0x7c
   1d718: e51b3008     	ldr	r3, [r11, #-0x8]
   1d71c: e5933004     	ldr	r3, [r3, #0x4]
   1d720: e5932000     	ldr	r2, [r3]
   1d724: e59f30e0     	ldr	r3, [pc, #0xe0]         @ 0x1d80c <id3_set_encoding+0x198>
   1d728: e1520003     	cmp	r2, r3
   1d72c: 0a000019     	beq	0x1d798 <id3_set_encoding+0x124> @ imm = #0x64
   1d730: e51b3008     	ldr	r3, [r11, #-0x8]
   1d734: e5933004     	ldr	r3, [r3, #0x4]
   1d738: e5932000     	ldr	r2, [r3]
   1d73c: e59f30cc     	ldr	r3, [pc, #0xcc]         @ 0x1d810 <id3_set_encoding+0x19c>
   1d740: e1520003     	cmp	r2, r3
   1d744: 0a000013     	beq	0x1d798 <id3_set_encoding+0x124> @ imm = #0x4c
   1d748: e51b3008     	ldr	r3, [r11, #-0x8]
   1d74c: e5933004     	ldr	r3, [r3, #0x4]
   1d750: e5932000     	ldr	r2, [r3]
   1d754: e59f30b8     	ldr	r3, [pc, #0xb8]         @ 0x1d814 <id3_set_encoding+0x1a0>
   1d758: e1520003     	cmp	r2, r3
   1d75c: 0a00000d     	beq	0x1d798 <id3_set_encoding+0x124> @ imm = #0x34
   1d760: e51b3008     	ldr	r3, [r11, #-0x8]
   1d764: e5933004     	ldr	r3, [r3, #0x4]
   1d768: e5932000     	ldr	r2, [r3]
   1d76c: e59f30a4     	ldr	r3, [pc, #0xa4]         @ 0x1d818 <id3_set_encoding+0x1a4>
   1d770: e1520003     	cmp	r2, r3
   1d774: 0a000007     	beq	0x1d798 <id3_set_encoding+0x124> @ imm = #0x1c
   1d778: e51b3008     	ldr	r3, [r11, #-0x8]
   1d77c: e5933004     	ldr	r3, [r3, #0x4]
   1d780: e5932000     	ldr	r2, [r3]
   1d784: e59f3090     	ldr	r3, [pc, #0x90]         @ 0x1d81c <id3_set_encoding+0x1a8>
   1d788: e1520003     	cmp	r2, r3
   1d78c: 0a000001     	beq	0x1d798 <id3_set_encoding+0x124> @ imm = #0x4
   1d790: e3e03000     	mvn	r3, #0
   1d794: ea000014     	b	0x1d7ec <id3_set_encoding+0x178> @ imm = #0x50
   1d798: e51b0008     	ldr	r0, [r11, #-0x8]
   1d79c: ebfffbf7     	bl	0x1c780 <id3_decompress_frame> @ imm = #-0x1024
   1d7a0: e1a03000     	mov	r3, r0
   1d7a4: e3730001     	cmn	r3, #1
   1d7a8: 1a000001     	bne	0x1d7b4 <id3_set_encoding+0x140> @ imm = #0x4
   1d7ac: e3e03000     	mvn	r3, #0
   1d7b0: ea00000d     	b	0x1d7ec <id3_set_encoding+0x178> @ imm = #0x34
   1d7b4: e51b3008     	ldr	r3, [r11, #-0x8]
   1d7b8: e5933010     	ldr	r3, [r3, #0x10]
   1d7bc: e5d33000     	ldrb	r3, [r3]
   1d7c0: e15b20d9     	ldrsb	r2, [r11, #-9]
   1d7c4: e6af3073     	sxtb	r3, r3
   1d7c8: e1520003     	cmp	r2, r3
   1d7cc: 0a000001     	beq	0x1d7d8 <id3_set_encoding+0x164> @ imm = #0x4
   1d7d0: e3e03000     	mvn	r3, #0
   1d7d4: ea000004     	b	0x1d7ec <id3_set_encoding+0x178> @ imm = #0x10
   1d7d8: e51b3008     	ldr	r3, [r11, #-0x8]
   1d7dc: e5933010     	ldr	r3, [r3, #0x10]
   1d7e0: e55b2009     	ldrb	r2, [r11, #-0x9]
   1d7e4: e5c32000     	strb	r2, [r3]
   1d7e8: e3a03000     	mov	r3, #0
   1d7ec: e1a00003     	mov	r0, r3
   1d7f0: e24bd004     	sub	sp, r11, #4
   1d7f4: e8bd8800     	pop	{r11, pc}
   1d7f8: 58 58 58 57  	.word	0x57585858
   1d7fc: 53 4c 50 49  	.word	0x49504c53
   1d800: 54 4c 53 55  	.word	0x55534c54
   1d804: 54 4c 59 53  	.word	0x53594c54
   1d808: 4d 4d 4f 43  	.word	0x434f4d4d
   1d80c: 43 49 50 41  	.word	0x41504943
   1d810: 42 4f 45 47  	.word	0x47454f42
   1d814: 52 45 53 55  	.word	0x55534552
   1d818: 45 4e 57 4f  	.word	0x4f574e45
   1d81c: 52 4d 4f 43  	.word	0x434f4d52

