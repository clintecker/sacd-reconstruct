0001f4d4 <scarletbook_print_disc_text>:
   1f4d4: e92d4830     	push	{r4, r5, r11, lr}
   1f4d8: e28db00c     	add	r11, sp, #12
   1f4dc: e24dd010     	sub	sp, sp, #16
   1f4e0: e50b0018     	str	r0, [r11, #-0x18]
   1f4e4: e51b3018     	ldr	r3, [r11, #-0x18]
   1f4e8: e5933008     	ldr	r3, [r3, #0x8]
   1f4ec: e50b3014     	str	r3, [r11, #-0x14]
   1f4f0: e51b3018     	ldr	r3, [r11, #-0x18]
   1f4f4: e2833010     	add	r3, r3, #16
   1f4f8: e50b3010     	str	r3, [r11, #-0x10]
   1f4fc: e59f3248     	ldr	r3, [pc, #0x248]        @ 0x1f74c <scarletbook_print_disc_text+0x278>
   1f500: e5933000     	ldr	r3, [r3]
   1f504: e1a00003     	mov	r0, r3
   1f508: e59f1240     	ldr	r1, [pc, #0x240]        @ 0x1f750 <scarletbook_print_disc_text+0x27c>
   1f50c: e51b3014     	ldr	r3, [r11, #-0x14]
   1f510: e5d33088     	ldrb	r3, [r3, #0x88]
   1f514: e1a02003     	mov	r2, r3
   1f518: e51b3014     	ldr	r3, [r11, #-0x14]
   1f51c: e5d33089     	ldrb	r3, [r3, #0x89]
   1f520: ebffb477     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x12e24
   1f524: e51b3010     	ldr	r3, [r11, #-0x10]
   1f528: e5933020     	ldr	r3, [r3, #0x20]
   1f52c: e3530000     	cmp	r3, #0
   1f530: 0a00000c     	beq	0x1f568 <scarletbook_print_disc_text+0x94> @ imm = #0x30
   1f534: e59f3210     	ldr	r3, [pc, #0x210]        @ 0x1f74c <scarletbook_print_disc_text+0x278>
   1f538: e5933000     	ldr	r3, [r3]
   1f53c: e1a05003     	mov	r5, r3
   1f540: e59f420c     	ldr	r4, [pc, #0x20c]        @ 0x1f754 <scarletbook_print_disc_text+0x280>
   1f544: e51b3010     	ldr	r3, [r11, #-0x10]
   1f548: e5933020     	ldr	r3, [r3, #0x20]
   1f54c: e1a00003     	mov	r0, r3
   1f550: ebffff1a     	bl	0x1f1c0 <ucs>           @ imm = #-0x398
   1f554: e1a03000     	mov	r3, r0
   1f558: e1a00005     	mov	r0, r5
   1f55c: e1a01004     	mov	r1, r4
   1f560: e1a02003     	mov	r2, r3
   1f564: ebffb466     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x12e68
   1f568: e51b3010     	ldr	r3, [r11, #-0x10]
   1f56c: e5933024     	ldr	r3, [r3, #0x24]
   1f570: e3530000     	cmp	r3, #0
   1f574: 0a00000c     	beq	0x1f5ac <scarletbook_print_disc_text+0xd8> @ imm = #0x30
   1f578: e59f31cc     	ldr	r3, [pc, #0x1cc]        @ 0x1f74c <scarletbook_print_disc_text+0x278>
   1f57c: e5933000     	ldr	r3, [r3]
   1f580: e1a05003     	mov	r5, r3
   1f584: e59f41cc     	ldr	r4, [pc, #0x1cc]        @ 0x1f758 <scarletbook_print_disc_text+0x284>
   1f588: e51b3010     	ldr	r3, [r11, #-0x10]
   1f58c: e5933024     	ldr	r3, [r3, #0x24]
   1f590: e1a00003     	mov	r0, r3
   1f594: ebffff09     	bl	0x1f1c0 <ucs>           @ imm = #-0x3dc
   1f598: e1a03000     	mov	r3, r0
   1f59c: e1a00005     	mov	r0, r5
   1f5a0: e1a01004     	mov	r1, r4
   1f5a4: e1a02003     	mov	r2, r3
   1f5a8: ebffb455     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x12eac
   1f5ac: e51b3010     	ldr	r3, [r11, #-0x10]
   1f5b0: e5933028     	ldr	r3, [r3, #0x28]
   1f5b4: e3530000     	cmp	r3, #0
   1f5b8: 0a00000c     	beq	0x1f5f0 <scarletbook_print_disc_text+0x11c> @ imm = #0x30
   1f5bc: e59f3188     	ldr	r3, [pc, #0x188]        @ 0x1f74c <scarletbook_print_disc_text+0x278>
   1f5c0: e5933000     	ldr	r3, [r3]
   1f5c4: e1a05003     	mov	r5, r3
   1f5c8: e59f418c     	ldr	r4, [pc, #0x18c]        @ 0x1f75c <scarletbook_print_disc_text+0x288>
   1f5cc: e51b3010     	ldr	r3, [r11, #-0x10]
   1f5d0: e5933028     	ldr	r3, [r3, #0x28]
   1f5d4: e1a00003     	mov	r0, r3
   1f5d8: ebfffef8     	bl	0x1f1c0 <ucs>           @ imm = #-0x420
   1f5dc: e1a03000     	mov	r3, r0
   1f5e0: e1a00005     	mov	r0, r5
   1f5e4: e1a01004     	mov	r1, r4
   1f5e8: e1a02003     	mov	r2, r3
   1f5ec: ebffb444     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x12ef0
   1f5f0: e51b3010     	ldr	r3, [r11, #-0x10]
   1f5f4: e593302c     	ldr	r3, [r3, #0x2c]
   1f5f8: e3530000     	cmp	r3, #0
   1f5fc: 0a00000c     	beq	0x1f634 <scarletbook_print_disc_text+0x160> @ imm = #0x30
   1f600: e59f3144     	ldr	r3, [pc, #0x144]        @ 0x1f74c <scarletbook_print_disc_text+0x278>
   1f604: e5933000     	ldr	r3, [r3]
   1f608: e1a05003     	mov	r5, r3
   1f60c: e59f414c     	ldr	r4, [pc, #0x14c]        @ 0x1f760 <scarletbook_print_disc_text+0x28c>
   1f610: e51b3010     	ldr	r3, [r11, #-0x10]
   1f614: e593302c     	ldr	r3, [r3, #0x2c]
   1f618: e1a00003     	mov	r0, r3
   1f61c: ebfffee7     	bl	0x1f1c0 <ucs>           @ imm = #-0x464
   1f620: e1a03000     	mov	r3, r0
   1f624: e1a00005     	mov	r0, r5
   1f628: e1a01004     	mov	r1, r4
   1f62c: e1a02003     	mov	r2, r3
   1f630: ebffb433     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x12f34
   1f634: e51b3010     	ldr	r3, [r11, #-0x10]
   1f638: e5933030     	ldr	r3, [r3, #0x30]
   1f63c: e3530000     	cmp	r3, #0
   1f640: 0a00000c     	beq	0x1f678 <scarletbook_print_disc_text+0x1a4> @ imm = #0x30
   1f644: e59f3100     	ldr	r3, [pc, #0x100]        @ 0x1f74c <scarletbook_print_disc_text+0x278>
   1f648: e5933000     	ldr	r3, [r3]
   1f64c: e1a05003     	mov	r5, r3
   1f650: e59f410c     	ldr	r4, [pc, #0x10c]        @ 0x1f764 <scarletbook_print_disc_text+0x290>
   1f654: e51b3010     	ldr	r3, [r11, #-0x10]
   1f658: e5933030     	ldr	r3, [r3, #0x30]
   1f65c: e1a00003     	mov	r0, r3
   1f660: ebfffed6     	bl	0x1f1c0 <ucs>           @ imm = #-0x4a8
   1f664: e1a03000     	mov	r3, r0
   1f668: e1a00005     	mov	r0, r5
   1f66c: e1a01004     	mov	r1, r4
   1f670: e1a02003     	mov	r2, r3
   1f674: ebffb422     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x12f78
   1f678: e51b3010     	ldr	r3, [r11, #-0x10]
   1f67c: e5933034     	ldr	r3, [r3, #0x34]
   1f680: e3530000     	cmp	r3, #0
   1f684: 0a00000c     	beq	0x1f6bc <scarletbook_print_disc_text+0x1e8> @ imm = #0x30
   1f688: e59f30bc     	ldr	r3, [pc, #0xbc]         @ 0x1f74c <scarletbook_print_disc_text+0x278>
   1f68c: e5933000     	ldr	r3, [r3]
   1f690: e1a05003     	mov	r5, r3
   1f694: e59f40cc     	ldr	r4, [pc, #0xcc]         @ 0x1f768 <scarletbook_print_disc_text+0x294>
   1f698: e51b3010     	ldr	r3, [r11, #-0x10]
   1f69c: e5933034     	ldr	r3, [r3, #0x34]
   1f6a0: e1a00003     	mov	r0, r3
   1f6a4: ebfffec5     	bl	0x1f1c0 <ucs>           @ imm = #-0x4ec
   1f6a8: e1a03000     	mov	r3, r0
   1f6ac: e1a00005     	mov	r0, r5
   1f6b0: e1a01004     	mov	r1, r4
   1f6b4: e1a02003     	mov	r2, r3
   1f6b8: ebffb411     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x12fbc
   1f6bc: e51b3010     	ldr	r3, [r11, #-0x10]
   1f6c0: e5933038     	ldr	r3, [r3, #0x38]
   1f6c4: e3530000     	cmp	r3, #0
   1f6c8: 0a00000c     	beq	0x1f700 <scarletbook_print_disc_text+0x22c> @ imm = #0x30
   1f6cc: e59f3078     	ldr	r3, [pc, #0x78]         @ 0x1f74c <scarletbook_print_disc_text+0x278>
   1f6d0: e5933000     	ldr	r3, [r3]
   1f6d4: e1a05003     	mov	r5, r3
   1f6d8: e59f408c     	ldr	r4, [pc, #0x8c]         @ 0x1f76c <scarletbook_print_disc_text+0x298>
   1f6dc: e51b3010     	ldr	r3, [r11, #-0x10]
   1f6e0: e5933038     	ldr	r3, [r3, #0x38]
   1f6e4: e1a00003     	mov	r0, r3
   1f6e8: ebfffeb4     	bl	0x1f1c0 <ucs>           @ imm = #-0x530
   1f6ec: e1a03000     	mov	r3, r0
   1f6f0: e1a00005     	mov	r0, r5
   1f6f4: e1a01004     	mov	r1, r4
   1f6f8: e1a02003     	mov	r2, r3
   1f6fc: ebffb400     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13000
   1f700: e51b3010     	ldr	r3, [r11, #-0x10]
   1f704: e593303c     	ldr	r3, [r3, #0x3c]
   1f708: e3530000     	cmp	r3, #0
   1f70c: 0a00000c     	beq	0x1f744 <scarletbook_print_disc_text+0x270> @ imm = #0x30
   1f710: e59f3034     	ldr	r3, [pc, #0x34]         @ 0x1f74c <scarletbook_print_disc_text+0x278>
   1f714: e5933000     	ldr	r3, [r3]
   1f718: e1a05003     	mov	r5, r3
   1f71c: e59f404c     	ldr	r4, [pc, #0x4c]         @ 0x1f770 <scarletbook_print_disc_text+0x29c>
   1f720: e51b3010     	ldr	r3, [r11, #-0x10]
   1f724: e593303c     	ldr	r3, [r3, #0x3c]
   1f728: e1a00003     	mov	r0, r3
   1f72c: ebfffea3     	bl	0x1f1c0 <ucs>           @ imm = #-0x574
   1f730: e1a03000     	mov	r3, r0
   1f734: e1a00005     	mov	r0, r5
   1f738: e1a01004     	mov	r1, r4
   1f73c: e1a02003     	mov	r2, r3
   1f740: ebffb3ef     	bl	0xc704 <fwprintf@plt>   @ imm = #-0x13044
   1f744: e24bd00c     	sub	sp, r11, #12
   1f748: e8bd8830     	pop	{r4, r5, r11, pc}
   1f74c: f4 6d 05 00  	.word	0x00056df4
   1f750: b8 39 03 00  	.word	0x000339b8
   1f754: f4 39 03 00  	.word	0x000339f4
   1f758: 28 3a 03 00  	.word	0x00033a28
   1f75c: 80 3a 03 00  	.word	0x00033a80
   1f760: b8 3a 03 00  	.word	0x00033ab8
   1f764: 14 3b 03 00  	.word	0x00033b14
   1f768: 58 3b 03 00  	.word	0x00033b58
   1f76c: c0 3b 03 00  	.word	0x00033bc0
   1f770: 04 3c 03 00  	.word	0x00033c04

