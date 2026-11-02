0001af38 <write_thread>:
   1af38: e92d4870     	push	{r4, r5, r6, r11, lr}
   1af3c: e28db010     	add	r11, sp, #16
   1af40: e24dd01c     	sub	sp, sp, #28
   1af44: e50b0028     	str	r0, [r11, #-0x28]
   1af48: e51b3028     	ldr	r3, [r11, #-0x28]
   1af4c: e50b3018     	str	r3, [r11, #-0x18]
   1af50: e59f3228     	ldr	r3, [pc, #0x228]        @ 0x1b180 <write_thread+0x248>
   1af54: e5933000     	ldr	r3, [r3]
   1af58: e5933004     	ldr	r3, [r3, #0x4]
   1af5c: e3530003     	cmp	r3, #3
   1af60: 9a000001     	bls	0x1af6c <write_thread+0x34> @ imm = #0x4
   1af64: e59f0218     	ldr	r0, [pc, #0x218]        @ 0x1b184 <write_thread+0x24c>
   1af68: ebffe751     	bl	0x14cb4 <log_print>     @ imm = #-0x62bc
   1af6c: e3a03000     	mov	r3, #0
   1af70: e50b3024     	str	r3, [r11, #-0x24]
   1af74: e51b3018     	ldr	r3, [r11, #-0x18]
   1af78: e5933040     	ldr	r3, [r3, #0x40]
   1af7c: e1a00003     	mov	r0, r3
   1af80: ebffea0a     	bl	0x157b0 <possess>       @ imm = #-0x57d8
   1af84: e51b3018     	ldr	r3, [r11, #-0x18]
   1af88: e5933040     	ldr	r3, [r3, #0x40]
   1af8c: e1a00003     	mov	r0, r3
   1af90: e3a01000     	mov	r1, #0
   1af94: e51b2024     	ldr	r2, [r11, #-0x24]
   1af98: ebffea4f     	bl	0x158dc <wait_for>      @ imm = #-0x56c4
   1af9c: e51b3018     	ldr	r3, [r11, #-0x18]
   1afa0: e5933044     	ldr	r3, [r3, #0x44]
   1afa4: e50b3020     	str	r3, [r11, #-0x20]
   1afa8: e51b3020     	ldr	r3, [r11, #-0x20]
   1afac: e5932014     	ldr	r2, [r3, #0x14]
   1afb0: e51b3018     	ldr	r3, [r11, #-0x18]
   1afb4: e5832044     	str	r2, [r3, #0x44]
   1afb8: e51b3018     	ldr	r3, [r11, #-0x18]
   1afbc: e5932040     	ldr	r2, [r3, #0x40]
   1afc0: e51b3018     	ldr	r3, [r11, #-0x18]
   1afc4: e5933044     	ldr	r3, [r3, #0x44]
   1afc8: e3530000     	cmp	r3, #0
   1afcc: 0a000003     	beq	0x1afe0 <write_thread+0xa8> @ imm = #0xc
   1afd0: e51b3018     	ldr	r3, [r11, #-0x18]
   1afd4: e5933044     	ldr	r3, [r3, #0x44]
   1afd8: e5933000     	ldr	r3, [r3]
   1afdc: ea000000     	b	0x1afe4 <write_thread+0xac> @ imm = #0x0
   1afe0: e3e03000     	mvn	r3, #0
   1afe4: e1a00002     	mov	r0, r2
   1afe8: e3a01000     	mov	r1, #0
   1afec: e1a02003     	mov	r2, r3
   1aff0: ebffea0e     	bl	0x15830 <twist>         @ imm = #-0x57c8
   1aff4: e51b3020     	ldr	r3, [r11, #-0x20]
   1aff8: e5933004     	ldr	r3, [r3, #0x4]
   1affc: e3530000     	cmp	r3, #0
   1b000: 0a000013     	beq	0x1b054 <write_thread+0x11c> @ imm = #0x4c
   1b004: e51b3018     	ldr	r3, [r11, #-0x18]
   1b008: e5933054     	ldr	r3, [r3, #0x54]
   1b00c: e3530000     	cmp	r3, #0
   1b010: 0a00000f     	beq	0x1b054 <write_thread+0x11c> @ imm = #0x3c
   1b014: e51b3018     	ldr	r3, [r11, #-0x18]
   1b018: e5934054     	ldr	r4, [r3, #0x54]
   1b01c: e51b3020     	ldr	r3, [r11, #-0x20]
   1b020: e5936000     	ldr	r6, [r3]
   1b024: e51b3020     	ldr	r3, [r11, #-0x20]
   1b028: e5935004     	ldr	r5, [r3, #0x4]
   1b02c: e51b3020     	ldr	r3, [r11, #-0x20]
   1b030: e5933004     	ldr	r3, [r3, #0x4]
   1b034: e1a00003     	mov	r0, r3
   1b038: ebfff207     	bl	0x1785c <DST_GetErrorMessage> @ imm = #-0x37e4
   1b03c: e1a02000     	mov	r2, r0
   1b040: e51b3018     	ldr	r3, [r11, #-0x18]
   1b044: e5933058     	ldr	r3, [r3, #0x58]
   1b048: e1a00006     	mov	r0, r6
   1b04c: e1a01005     	mov	r1, r5
   1b050: e12fff34     	blx	r4
   1b054: e51b3020     	ldr	r3, [r11, #-0x20]
   1b058: e5933008     	ldr	r3, [r3, #0x8]
   1b05c: e50b301c     	str	r3, [r11, #-0x1c]
   1b060: e51b301c     	ldr	r3, [r11, #-0x1c]
   1b064: e3530000     	cmp	r3, #0
   1b068: 0a00000f     	beq	0x1b0ac <write_thread+0x174> @ imm = #0x3c
   1b06c: e51b3018     	ldr	r3, [r11, #-0x18]
   1b070: e5933050     	ldr	r3, [r3, #0x50]
   1b074: e51b2020     	ldr	r2, [r11, #-0x20]
   1b078: e5922010     	ldr	r2, [r2, #0x10]
   1b07c: e5922004     	ldr	r2, [r2, #0x4]
   1b080: e1a00002     	mov	r0, r2
   1b084: e51b2020     	ldr	r2, [r11, #-0x20]
   1b088: e5922010     	ldr	r2, [r2, #0x10]
   1b08c: e5921008     	ldr	r1, [r2, #0x8]
   1b090: e51b2018     	ldr	r2, [r11, #-0x18]
   1b094: e5922058     	ldr	r2, [r2, #0x58]
   1b098: e12fff33     	blx	r3
   1b09c: e51b3020     	ldr	r3, [r11, #-0x20]
   1b0a0: e5933010     	ldr	r3, [r3, #0x10]
   1b0a4: e1a00003     	mov	r0, r3
   1b0a8: ebffec91     	bl	0x162f4 <buffer_pool_drop_space> @ imm = #-0x4dbc
   1b0ac: e51b0020     	ldr	r0, [r11, #-0x20]
   1b0b0: ebffc4d9     	bl	0xc41c <free@plt>       @ imm = #-0xec9c
   1b0b4: e51b3024     	ldr	r3, [r11, #-0x24]
   1b0b8: e2833001     	add	r3, r3, #1
   1b0bc: e50b3024     	str	r3, [r11, #-0x24]
   1b0c0: e51b301c     	ldr	r3, [r11, #-0x1c]
   1b0c4: e3530000     	cmp	r3, #0
   1b0c8: 1affffa9     	bne	0x1af74 <write_thread+0x3c> @ imm = #-0x15c
   1b0cc: e51b3018     	ldr	r3, [r11, #-0x18]
   1b0d0: e5933034     	ldr	r3, [r3, #0x34]
   1b0d4: e1a00003     	mov	r0, r3
   1b0d8: ebffe9b4     	bl	0x157b0 <possess>       @ imm = #-0x5930
   1b0dc: e51b3018     	ldr	r3, [r11, #-0x18]
   1b0e0: e5933038     	ldr	r3, [r3, #0x38]
   1b0e4: e3530000     	cmp	r3, #0
   1b0e8: 1a000006     	bne	0x1b108 <write_thread+0x1d0> @ imm = #0x18
   1b0ec: e51b3018     	ldr	r3, [r11, #-0x18]
   1b0f0: e5933034     	ldr	r3, [r3, #0x34]
   1b0f4: e1a00003     	mov	r0, r3
   1b0f8: ebffea52     	bl	0x15a48 <peek_lock>     @ imm = #-0x56b8
   1b0fc: e1a03000     	mov	r3, r0
   1b100: e3530000     	cmp	r3, #0
   1b104: 0a000004     	beq	0x1b11c <write_thread+0x1e4> @ imm = #0x10
   1b108: e59f0078     	ldr	r0, [pc, #0x78]         @ 0x1b188 <write_thread+0x250>
   1b10c: e59f1078     	ldr	r1, [pc, #0x78]         @ 0x1b18c <write_thread+0x254>
   1b110: e59f2078     	ldr	r2, [pc, #0x78]         @ 0x1b190 <write_thread+0x258>
   1b114: e59f3078     	ldr	r3, [pc, #0x78]         @ 0x1b194 <write_thread+0x25c>
   1b118: ebffc4b0     	bl	0xc3e0 <__assert_fail@plt> @ imm = #-0xed40
   1b11c: e51b3018     	ldr	r3, [r11, #-0x18]
   1b120: e5933034     	ldr	r3, [r3, #0x34]
   1b124: e1a00003     	mov	r0, r3
   1b128: ebffe9b0     	bl	0x157f0 <release>       @ imm = #-0x5940
   1b12c: e51b3018     	ldr	r3, [r11, #-0x18]
   1b130: e5933040     	ldr	r3, [r3, #0x40]
   1b134: e1a00003     	mov	r0, r3
   1b138: ebffe99c     	bl	0x157b0 <possess>       @ imm = #-0x5990
   1b13c: e51b3018     	ldr	r3, [r11, #-0x18]
   1b140: e5933044     	ldr	r3, [r3, #0x44]
   1b144: e3530000     	cmp	r3, #0
   1b148: 0a000004     	beq	0x1b160 <write_thread+0x228> @ imm = #0x10
   1b14c: e59f0044     	ldr	r0, [pc, #0x44]         @ 0x1b198 <write_thread+0x260>
   1b150: e59f1034     	ldr	r1, [pc, #0x34]         @ 0x1b18c <write_thread+0x254>
   1b154: e59f2040     	ldr	r2, [pc, #0x40]         @ 0x1b19c <write_thread+0x264>
   1b158: e59f3034     	ldr	r3, [pc, #0x34]         @ 0x1b194 <write_thread+0x25c>
   1b15c: ebffc49f     	bl	0xc3e0 <__assert_fail@plt> @ imm = #-0xed84
   1b160: e51b3018     	ldr	r3, [r11, #-0x18]
   1b164: e5933040     	ldr	r3, [r3, #0x40]
   1b168: e1a00003     	mov	r0, r3
   1b16c: e3a01000     	mov	r1, #0
   1b170: e3e02000     	mvn	r2, #0
   1b174: ebffe9ad     	bl	0x15830 <twist>         @ imm = #-0x594c
   1b178: e24bd010     	sub	sp, r11, #16
   1b17c: e8bd8870     	pop	{r4, r5, r6, r11, pc}
   1b180: 5c 73 05 00  	.word	0x0005735c
   1b184: b0 2f 03 00  	.word	0x00032fb0
   1b188: c8 2f 03 00  	.word	0x00032fc8
   1b18c: e8 2e 03 00  	.word	0x00032ee8
   1b190: 33 01 00 00  	.word	0x00000133
   1b194: 70 30 03 00  	.word	0x00033070
   1b198: 1c 30 03 00  	.word	0x0003301c
   1b19c: 36 01 00 00  	.word	0x00000136

