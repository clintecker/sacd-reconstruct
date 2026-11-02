0001cf90 <to_ascii>:
   1cf90: e92d4800     	push	{r11, lr}
   1cf94: e28db004     	add	r11, sp, #4
   1cf98: e24dd020     	sub	sp, sp, #32
   1cf9c: e50b0020     	str	r0, [r11, #-0x20]
   1cfa0: e50b1024     	str	r1, [r11, #-0x24]
   1cfa4: e51b0020     	ldr	r0, [r11, #-0x20]
   1cfa8: ebffffdc     	bl	0x1cf20 <utf16_strlen>  @ imm = #-0x90
   1cfac: e1a03000     	mov	r3, r0
   1cfb0: e1a030a3     	lsr	r3, r3, #1
   1cfb4: e2833001     	add	r3, r3, #1
   1cfb8: e50b3014     	str	r3, [r11, #-0x14]
   1cfbc: e51b3014     	ldr	r3, [r11, #-0x14]
   1cfc0: e2833001     	add	r3, r3, #1
   1cfc4: e1a00003     	mov	r0, r3
   1cfc8: ebffbda6     	bl	0xc668 <malloc@plt>     @ imm = #-0x10968
   1cfcc: e1a03000     	mov	r3, r0
   1cfd0: e50b301c     	str	r3, [r11, #-0x1c]
   1cfd4: e3a03000     	mov	r3, #0
   1cfd8: e50b3018     	str	r3, [r11, #-0x18]
   1cfdc: e3a03000     	mov	r3, #0
   1cfe0: e50b3010     	str	r3, [r11, #-0x10]
   1cfe4: ea000048     	b	0x1d10c <to_ascii+0x17c> @ imm = #0x120
   1cfe8: e51b3018     	ldr	r3, [r11, #-0x18]
   1cfec: e1a03083     	lsl	r3, r3, #1
   1cff0: e50b3008     	str	r3, [r11, #-0x8]
   1cff4: e51b3024     	ldr	r3, [r11, #-0x24]
   1cff8: e3530000     	cmp	r3, #0
   1cffc: 0a00000f     	beq	0x1d040 <to_ascii+0xb0> @ imm = #0x3c
   1d000: e51b3008     	ldr	r3, [r11, #-0x8]
   1d004: e51b2020     	ldr	r2, [r11, #-0x20]
   1d008: e0823003     	add	r3, r2, r3
   1d00c: e5d33000     	ldrb	r3, [r3]
   1d010: e1a02003     	mov	r2, r3
   1d014: e51b3008     	ldr	r3, [r11, #-0x8]
   1d018: e2833001     	add	r3, r3, #1
   1d01c: e51b1020     	ldr	r1, [r11, #-0x20]
   1d020: e0813003     	add	r3, r1, r3
   1d024: e5d33000     	ldrb	r3, [r3]
   1d028: e1a03403     	lsl	r3, r3, #8
   1d02c: e6ff3073     	uxth	r3, r3
   1d030: e1823003     	orr	r3, r2, r3
   1d034: e6ff3073     	uxth	r3, r3
   1d038: e14b30ba     	strh	r3, [r11, #-10]
   1d03c: ea00000d     	b	0x1d078 <to_ascii+0xe8> @ imm = #0x34
   1d040: e51b3008     	ldr	r3, [r11, #-0x8]
   1d044: e51b2020     	ldr	r2, [r11, #-0x20]
   1d048: e0823003     	add	r3, r2, r3
   1d04c: e5d33000     	ldrb	r3, [r3]
   1d050: e1a03403     	lsl	r3, r3, #8
   1d054: e6ff2073     	uxth	r2, r3
   1d058: e51b3008     	ldr	r3, [r11, #-0x8]
   1d05c: e2833001     	add	r3, r3, #1
   1d060: e51b1020     	ldr	r1, [r11, #-0x20]
   1d064: e0813003     	add	r3, r1, r3
   1d068: e5d33000     	ldrb	r3, [r3]
   1d06c: e1823003     	orr	r3, r2, r3
   1d070: e6ff3073     	uxth	r3, r3
   1d074: e14b30ba     	strh	r3, [r11, #-10]
   1d078: e15b20ba     	ldrh	r2, [r11, #-10]
   1d07c: e59f30bc     	ldr	r3, [pc, #0xbc]         @ 0x1d140 <to_ascii+0x1b0>
   1d080: e1520003     	cmp	r2, r3
   1d084: 0a00001a     	beq	0x1d0f4 <to_ascii+0x164> @ imm = #0x68
   1d088: e15b20ba     	ldrh	r2, [r11, #-10]
   1d08c: e59f30b0     	ldr	r3, [pc, #0xb0]         @ 0x1d144 <to_ascii+0x1b4>
   1d090: e1520003     	cmp	r2, r3
   1d094: 9a000003     	bls	0x1d0a8 <to_ascii+0x118> @ imm = #0xc
   1d098: e15b20ba     	ldrh	r2, [r11, #-10]
   1d09c: e59f30a4     	ldr	r3, [pc, #0xa4]         @ 0x1d148 <to_ascii+0x1b8>
   1d0a0: e1520003     	cmp	r2, r3
   1d0a4: 9a000014     	bls	0x1d0fc <to_ascii+0x16c> @ imm = #0x50
   1d0a8: e15b30ba     	ldrh	r3, [r11, #-10]
   1d0ac: e353007f     	cmp	r3, #127
   1d0b0: 8a000006     	bhi	0x1d0d0 <to_ascii+0x140> @ imm = #0x18
   1d0b4: e51b201c     	ldr	r2, [r11, #-0x1c]
   1d0b8: e51b3010     	ldr	r3, [r11, #-0x10]
   1d0bc: e0823003     	add	r3, r2, r3
   1d0c0: e15b20ba     	ldrh	r2, [r11, #-10]
   1d0c4: e6ef2072     	uxtb	r2, r2
   1d0c8: e5c32000     	strb	r2, [r3]
   1d0cc: ea000004     	b	0x1d0e4 <to_ascii+0x154> @ imm = #0x10
   1d0d0: e51b201c     	ldr	r2, [r11, #-0x1c]
   1d0d4: e51b3010     	ldr	r3, [r11, #-0x10]
   1d0d8: e0823003     	add	r3, r2, r3
   1d0dc: e3a0203f     	mov	r2, #63
   1d0e0: e5c32000     	strb	r2, [r3]
   1d0e4: e51b3010     	ldr	r3, [r11, #-0x10]
   1d0e8: e2833001     	add	r3, r3, #1
   1d0ec: e50b3010     	str	r3, [r11, #-0x10]
   1d0f0: ea000002     	b	0x1d100 <to_ascii+0x170> @ imm = #0x8
   1d0f4: e1a00000     	mov	r0, r0
   1d0f8: ea000000     	b	0x1d100 <to_ascii+0x170> @ imm = #0x0
   1d0fc: e1a00000     	mov	r0, r0
   1d100: e51b3018     	ldr	r3, [r11, #-0x18]
   1d104: e2833001     	add	r3, r3, #1
   1d108: e50b3018     	str	r3, [r11, #-0x18]
   1d10c: e51b2018     	ldr	r2, [r11, #-0x18]
   1d110: e51b3014     	ldr	r3, [r11, #-0x14]
   1d114: e1520003     	cmp	r2, r3
   1d118: 3affffb2     	blo	0x1cfe8 <to_ascii+0x58> @ imm = #-0x138
   1d11c: e51b201c     	ldr	r2, [r11, #-0x1c]
   1d120: e51b3010     	ldr	r3, [r11, #-0x10]
   1d124: e0823003     	add	r3, r2, r3
   1d128: e3a02000     	mov	r2, #0
   1d12c: e5c32000     	strb	r2, [r3]
   1d130: e51b301c     	ldr	r3, [r11, #-0x1c]
   1d134: e1a00003     	mov	r0, r3
   1d138: e24bd004     	sub	sp, r11, #4
   1d13c: e8bd8800     	pop	{r11, pc}
   1d140: ff fe 00 00  	.word	0x0000feff
   1d144: ff d7 00 00  	.word	0x0000d7ff
   1d148: ff df 00 00  	.word	0x0000dfff

