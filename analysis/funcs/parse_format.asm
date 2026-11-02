00010718 <parse_format>:
   10718: e92d4810     	push	{r4, r11, lr}
   1071c: e28db008     	add	r11, sp, #8
   10720: e24dd024     	sub	sp, sp, #36
   10724: e50b0020     	str	r0, [r11, #-0x20]
   10728: e50b1024     	str	r1, [r11, #-0x24]
   1072c: e50b2028     	str	r2, [r11, #-0x28]
   10730: e50b302c     	str	r3, [r11, #-0x2c]
   10734: e3a03000     	mov	r3, #0
   10738: e50b301c     	str	r3, [r11, #-0x1c]
   1073c: e3a03000     	mov	r3, #0
   10740: e50b3018     	str	r3, [r11, #-0x18]
   10744: e3a03000     	mov	r3, #0
   10748: e50b3014     	str	r3, [r11, #-0x14]
   1074c: e3a03000     	mov	r3, #0
   10750: e50b3010     	str	r3, [r11, #-0x10]
   10754: e3a03000     	mov	r3, #0
   10758: e50b301c     	str	r3, [r11, #-0x1c]
   1075c: ea000095     	b	0x109b8 <parse_format+0x2a0> @ imm = #0x254
   10760: e51b2020     	ldr	r2, [r11, #-0x20]
   10764: e51b301c     	ldr	r3, [r11, #-0x1c]
   10768: e0823003     	add	r3, r2, r3
   1076c: e5d33000     	ldrb	r3, [r3]
   10770: e3530025     	cmp	r3, #37
   10774: 1a000089     	bne	0x109a0 <parse_format+0x288> @ imm = #0x224
   10778: e51b301c     	ldr	r3, [r11, #-0x1c]
   1077c: e2834001     	add	r4, r3, #1
   10780: e51b0020     	ldr	r0, [r11, #-0x20]
   10784: ebffef54     	bl	0xc4dc <strlen@plt>     @ imm = #-0x42b0
   10788: e1a03000     	mov	r3, r0
   1078c: e1540003     	cmp	r4, r3
   10790: 2a000082     	bhs	0x109a0 <parse_format+0x288> @ imm = #0x208
   10794: e51b301c     	ldr	r3, [r11, #-0x1c]
   10798: e2833001     	add	r3, r3, #1
   1079c: e51b2020     	ldr	r2, [r11, #-0x20]
   107a0: e0823003     	add	r3, r2, r3
   107a4: e5d33000     	ldrb	r3, [r3]
   107a8: e2433025     	sub	r3, r3, #37
   107ac: e3530034     	cmp	r3, #52
   107b0: 979ff103     	ldrls	pc, [pc, r3, lsl #2]
   107b4: ea000075     	b	0x10990 <parse_format+0x278> @ imm = #0x1d4
   107b8: 54 09 01 00  	.word	0x00010954
   107bc: 90 09 01 00  	.word	0x00010990
   107c0: 90 09 01 00  	.word	0x00010990
   107c4: 90 09 01 00  	.word	0x00010990
   107c8: 90 09 01 00  	.word	0x00010990
   107cc: 90 09 01 00  	.word	0x00010990
   107d0: 90 09 01 00  	.word	0x00010990
   107d4: 90 09 01 00  	.word	0x00010990
   107d8: 90 09 01 00  	.word	0x00010990
   107dc: 90 09 01 00  	.word	0x00010990
   107e0: 90 09 01 00  	.word	0x00010990
   107e4: 90 09 01 00  	.word	0x00010990
   107e8: 90 09 01 00  	.word	0x00010990
   107ec: 90 09 01 00  	.word	0x00010990
   107f0: 90 09 01 00  	.word	0x00010990
   107f4: 90 09 01 00  	.word	0x00010990
   107f8: 90 09 01 00  	.word	0x00010990
   107fc: 90 09 01 00  	.word	0x00010990
   10800: 90 09 01 00  	.word	0x00010990
   10804: 90 09 01 00  	.word	0x00010990
   10808: 90 09 01 00  	.word	0x00010990
   1080c: 90 09 01 00  	.word	0x00010990
   10810: 90 09 01 00  	.word	0x00010990
   10814: 90 09 01 00  	.word	0x00010990
   10818: 90 09 01 00  	.word	0x00010990
   1081c: 90 09 01 00  	.word	0x00010990
   10820: 90 09 01 00  	.word	0x00010990
   10824: 90 09 01 00  	.word	0x00010990
   10828: 8c 08 01 00  	.word	0x0001088c
   1082c: 90 09 01 00  	.word	0x00010990
   10830: 90 09 01 00  	.word	0x00010990
   10834: 90 09 01 00  	.word	0x00010990
   10838: 90 09 01 00  	.word	0x00010990
   1083c: 90 09 01 00  	.word	0x00010990
   10840: 90 09 01 00  	.word	0x00010990
   10844: 90 09 01 00  	.word	0x00010990
   10848: 90 09 01 00  	.word	0x00010990
   1084c: 90 09 01 00  	.word	0x00010990
   10850: 90 09 01 00  	.word	0x00010990
   10854: b4 08 01 00  	.word	0x000108b4
   10858: 90 09 01 00  	.word	0x00010990
   1085c: dc 08 01 00  	.word	0x000108dc
   10860: 90 09 01 00  	.word	0x00010990
   10864: 90 09 01 00  	.word	0x00010990
   10868: 90 09 01 00  	.word	0x00010990
   1086c: 90 09 01 00  	.word	0x00010990
   10870: 90 09 01 00  	.word	0x00010990
   10874: 2c 09 01 00  	.word	0x0001092c
   10878: 90 09 01 00  	.word	0x00010990
   1087c: 90 09 01 00  	.word	0x00010990
   10880: 90 09 01 00  	.word	0x00010990
   10884: 90 09 01 00  	.word	0x00010990
   10888: 04 09 01 00  	.word	0x00010904
   1088c: e51b302c     	ldr	r3, [r11, #-0x2c]
   10890: e3530000     	cmp	r3, #0
   10894: 0a000032     	beq	0x10964 <parse_format+0x24c> @ imm = #0xc8
   10898: e51b002c     	ldr	r0, [r11, #-0x2c]
   1089c: ebffef0e     	bl	0xc4dc <strlen@plt>     @ imm = #-0x43c8
   108a0: e1a02000     	mov	r2, r0
   108a4: e51b3018     	ldr	r3, [r11, #-0x18]
   108a8: e0823003     	add	r3, r2, r3
   108ac: e50b3018     	str	r3, [r11, #-0x18]
   108b0: ea000036     	b	0x10990 <parse_format+0x278> @ imm = #0xd8
   108b4: e59b3004     	ldr	r3, [r11, #0x4]
   108b8: e3530000     	cmp	r3, #0
   108bc: 0a00002a     	beq	0x1096c <parse_format+0x254> @ imm = #0xa8
   108c0: e59b0004     	ldr	r0, [r11, #0x4]
   108c4: ebffef04     	bl	0xc4dc <strlen@plt>     @ imm = #-0x43f0
   108c8: e1a02000     	mov	r2, r0
   108cc: e51b3018     	ldr	r3, [r11, #-0x18]
   108d0: e0823003     	add	r3, r2, r3
   108d4: e50b3018     	str	r3, [r11, #-0x18]
   108d8: ea00002c     	b	0x10990 <parse_format+0x278> @ imm = #0xb0
   108dc: e51b3024     	ldr	r3, [r11, #-0x24]
   108e0: e3530000     	cmp	r3, #0
   108e4: da000022     	ble	0x10974 <parse_format+0x25c> @ imm = #0x88
   108e8: e51b3024     	ldr	r3, [r11, #-0x24]
   108ec: e3530063     	cmp	r3, #99
   108f0: ca000021     	bgt	0x1097c <parse_format+0x264> @ imm = #0x84
   108f4: e51b3018     	ldr	r3, [r11, #-0x18]
   108f8: e2833002     	add	r3, r3, #2
   108fc: e50b3018     	str	r3, [r11, #-0x18]
   10900: ea000022     	b	0x10990 <parse_format+0x278> @ imm = #0x88
   10904: e51b3028     	ldr	r3, [r11, #-0x28]
   10908: e3530000     	cmp	r3, #0
   1090c: 0a00001c     	beq	0x10984 <parse_format+0x26c> @ imm = #0x70
   10910: e51b0028     	ldr	r0, [r11, #-0x28]
   10914: ebffeef0     	bl	0xc4dc <strlen@plt>     @ imm = #-0x4440
   10918: e1a02000     	mov	r2, r0
   1091c: e51b3018     	ldr	r3, [r11, #-0x18]
   10920: e0823003     	add	r3, r2, r3
   10924: e50b3018     	str	r3, [r11, #-0x18]
   10928: ea000018     	b	0x10990 <parse_format+0x278> @ imm = #0x60
   1092c: e59b3008     	ldr	r3, [r11, #0x8]
   10930: e3530000     	cmp	r3, #0
   10934: 0a000014     	beq	0x1098c <parse_format+0x274> @ imm = #0x50
   10938: e59b0008     	ldr	r0, [r11, #0x8]
   1093c: ebffeee6     	bl	0xc4dc <strlen@plt>     @ imm = #-0x4468
   10940: e1a02000     	mov	r2, r0
   10944: e51b3018     	ldr	r3, [r11, #-0x18]
   10948: e0823003     	add	r3, r2, r3
   1094c: e50b3018     	str	r3, [r11, #-0x18]
   10950: ea00000e     	b	0x10990 <parse_format+0x278> @ imm = #0x38
   10954: e51b3018     	ldr	r3, [r11, #-0x18]
   10958: e2833001     	add	r3, r3, #1
   1095c: e50b3018     	str	r3, [r11, #-0x18]
   10960: ea00000a     	b	0x10990 <parse_format+0x278> @ imm = #0x28
   10964: e1a00000     	mov	r0, r0
   10968: ea000008     	b	0x10990 <parse_format+0x278> @ imm = #0x20
   1096c: e1a00000     	mov	r0, r0
   10970: ea000006     	b	0x10990 <parse_format+0x278> @ imm = #0x18
   10974: e1a00000     	mov	r0, r0
   10978: ea000004     	b	0x10990 <parse_format+0x278> @ imm = #0x10
   1097c: e1a00000     	mov	r0, r0
   10980: ea000002     	b	0x10990 <parse_format+0x278> @ imm = #0x8
   10984: e1a00000     	mov	r0, r0
   10988: ea000000     	b	0x10990 <parse_format+0x278> @ imm = #0x0
   1098c: e1a00000     	mov	r0, r0
   10990: e51b301c     	ldr	r3, [r11, #-0x1c]
   10994: e2833001     	add	r3, r3, #1
   10998: e50b301c     	str	r3, [r11, #-0x1c]
   1099c: ea000002     	b	0x109ac <parse_format+0x294> @ imm = #0x8
   109a0: e51b3018     	ldr	r3, [r11, #-0x18]
   109a4: e2833001     	add	r3, r3, #1
   109a8: e50b3018     	str	r3, [r11, #-0x18]
   109ac: e51b301c     	ldr	r3, [r11, #-0x1c]
   109b0: e2833001     	add	r3, r3, #1
   109b4: e50b301c     	str	r3, [r11, #-0x1c]
   109b8: e51b0020     	ldr	r0, [r11, #-0x20]
   109bc: ebffeec6     	bl	0xc4dc <strlen@plt>     @ imm = #-0x44e8
   109c0: e1a02000     	mov	r2, r0
   109c4: e51b301c     	ldr	r3, [r11, #-0x1c]
   109c8: e1520003     	cmp	r2, r3
   109cc: 8affff63     	bhi	0x10760 <parse_format+0x48> @ imm = #-0x274
   109d0: e51b3018     	ldr	r3, [r11, #-0x18]
   109d4: e2833001     	add	r3, r3, #1
   109d8: e1a00003     	mov	r0, r3
   109dc: ebffef21     	bl	0xc668 <malloc@plt>     @ imm = #-0x437c
   109e0: e1a03000     	mov	r3, r0
   109e4: e50b3014     	str	r3, [r11, #-0x14]
   109e8: e51b3014     	ldr	r3, [r11, #-0x14]
   109ec: e3530000     	cmp	r3, #0
   109f0: 1a000006     	bne	0x10a10 <parse_format+0x2f8> @ imm = #0x18
   109f4: e59f3408     	ldr	r3, [pc, #0x408]        @ 0x10e04 <parse_format+0x6ec>
   109f8: e5933000     	ldr	r3, [r3]
   109fc: e5933004     	ldr	r3, [r3, #0x4]
   10a00: e3530001     	cmp	r3, #1
   10a04: 9a000001     	bls	0x10a10 <parse_format+0x2f8> @ imm = #0x4
   10a08: e59f03f8     	ldr	r0, [pc, #0x3f8]        @ 0x10e08 <parse_format+0x6f0>
   10a0c: eb0010a8     	bl	0x14cb4 <log_print>     @ imm = #0x42a0
   10a10: e3a03000     	mov	r3, #0
   10a14: e50b301c     	str	r3, [r11, #-0x1c]
   10a18: ea0000ea     	b	0x10dc8 <parse_format+0x6b0> @ imm = #0x3a8
   10a1c: e51b2020     	ldr	r2, [r11, #-0x20]
   10a20: e51b301c     	ldr	r3, [r11, #-0x1c]
   10a24: e0823003     	add	r3, r2, r3
   10a28: e5d33000     	ldrb	r3, [r3]
   10a2c: e3530025     	cmp	r3, #37
   10a30: 1a0000d6     	bne	0x10d90 <parse_format+0x678> @ imm = #0x358
   10a34: e51b301c     	ldr	r3, [r11, #-0x1c]
   10a38: e2834001     	add	r4, r3, #1
   10a3c: e51b0020     	ldr	r0, [r11, #-0x20]
   10a40: ebffeea5     	bl	0xc4dc <strlen@plt>     @ imm = #-0x456c
   10a44: e1a03000     	mov	r3, r0
   10a48: e1540003     	cmp	r4, r3
   10a4c: 2a0000cf     	bhs	0x10d90 <parse_format+0x678> @ imm = #0x33c
   10a50: e51b301c     	ldr	r3, [r11, #-0x1c]
   10a54: e2833001     	add	r3, r3, #1
   10a58: e51b2020     	ldr	r2, [r11, #-0x20]
   10a5c: e0823003     	add	r3, r2, r3
   10a60: e5d33000     	ldrb	r3, [r3]
   10a64: e2433025     	sub	r3, r3, #37
   10a68: e3530034     	cmp	r3, #52
   10a6c: 979ff103     	ldrls	pc, [pc, r3, lsl #2]
   10a70: ea0000c2     	b	0x10d80 <parse_format+0x668> @ imm = #0x308
   10a74: 30 0d 01 00  	.word	0x00010d30
   10a78: 80 0d 01 00  	.word	0x00010d80
   10a7c: 80 0d 01 00  	.word	0x00010d80
   10a80: 80 0d 01 00  	.word	0x00010d80
   10a84: 80 0d 01 00  	.word	0x00010d80
   10a88: 80 0d 01 00  	.word	0x00010d80
   10a8c: 80 0d 01 00  	.word	0x00010d80
   10a90: 80 0d 01 00  	.word	0x00010d80
   10a94: 80 0d 01 00  	.word	0x00010d80
   10a98: 80 0d 01 00  	.word	0x00010d80
   10a9c: 80 0d 01 00  	.word	0x00010d80
   10aa0: 80 0d 01 00  	.word	0x00010d80
   10aa4: 80 0d 01 00  	.word	0x00010d80
   10aa8: 80 0d 01 00  	.word	0x00010d80
   10aac: 80 0d 01 00  	.word	0x00010d80
   10ab0: 80 0d 01 00  	.word	0x00010d80
   10ab4: 80 0d 01 00  	.word	0x00010d80
   10ab8: 80 0d 01 00  	.word	0x00010d80
   10abc: 80 0d 01 00  	.word	0x00010d80
   10ac0: 80 0d 01 00  	.word	0x00010d80
   10ac4: 80 0d 01 00  	.word	0x00010d80
   10ac8: 80 0d 01 00  	.word	0x00010d80
   10acc: 80 0d 01 00  	.word	0x00010d80
   10ad0: 80 0d 01 00  	.word	0x00010d80
   10ad4: 80 0d 01 00  	.word	0x00010d80
   10ad8: 80 0d 01 00  	.word	0x00010d80
   10adc: 80 0d 01 00  	.word	0x00010d80
   10ae0: 80 0d 01 00  	.word	0x00010d80
   10ae4: 48 0b 01 00  	.word	0x00010b48
   10ae8: 80 0d 01 00  	.word	0x00010d80
   10aec: 80 0d 01 00  	.word	0x00010d80
   10af0: 80 0d 01 00  	.word	0x00010d80
   10af4: 80 0d 01 00  	.word	0x00010d80
   10af8: 80 0d 01 00  	.word	0x00010d80
   10afc: 80 0d 01 00  	.word	0x00010d80
   10b00: 80 0d 01 00  	.word	0x00010d80
   10b04: 80 0d 01 00  	.word	0x00010d80
   10b08: 80 0d 01 00  	.word	0x00010d80
   10b0c: 80 0d 01 00  	.word	0x00010d80
   10b10: 98 0b 01 00  	.word	0x00010b98
   10b14: 80 0d 01 00  	.word	0x00010d80
   10b18: e8 0b 01 00  	.word	0x00010be8
   10b1c: 80 0d 01 00  	.word	0x00010d80
   10b20: 80 0d 01 00  	.word	0x00010d80
   10b24: 80 0d 01 00  	.word	0x00010d80
   10b28: 80 0d 01 00  	.word	0x00010d80
   10b2c: 80 0d 01 00  	.word	0x00010d80
   10b30: e0 0c 01 00  	.word	0x00010ce0
   10b34: 80 0d 01 00  	.word	0x00010d80
   10b38: 80 0d 01 00  	.word	0x00010d80
   10b3c: 80 0d 01 00  	.word	0x00010d80
   10b40: 80 0d 01 00  	.word	0x00010d80
   10b44: 90 0c 01 00  	.word	0x00010c90
   10b48: e51b302c     	ldr	r3, [r11, #-0x2c]
   10b4c: e3530000     	cmp	r3, #0
   10b50: 0a00007f     	beq	0x10d54 <parse_format+0x63c> @ imm = #0x1fc
   10b54: e51b3010     	ldr	r3, [r11, #-0x10]
   10b58: e51b2014     	ldr	r2, [r11, #-0x14]
   10b5c: e0824003     	add	r4, r2, r3
   10b60: e51b002c     	ldr	r0, [r11, #-0x2c]
   10b64: ebffee5c     	bl	0xc4dc <strlen@plt>     @ imm = #-0x4690
   10b68: e1a03000     	mov	r3, r0
   10b6c: e1a00004     	mov	r0, r4
   10b70: e51b102c     	ldr	r1, [r11, #-0x2c]
   10b74: e1a02003     	mov	r2, r3
   10b78: ebffedd6     	bl	0xc2d8 <strncpy@plt>    @ imm = #-0x48a8
   10b7c: e51b002c     	ldr	r0, [r11, #-0x2c]
   10b80: ebffee55     	bl	0xc4dc <strlen@plt>     @ imm = #-0x46ac
   10b84: e1a02000     	mov	r2, r0
   10b88: e51b3010     	ldr	r3, [r11, #-0x10]
   10b8c: e0823003     	add	r3, r2, r3
   10b90: e50b3010     	str	r3, [r11, #-0x10]
   10b94: ea000079     	b	0x10d80 <parse_format+0x668> @ imm = #0x1e4
   10b98: e59b3004     	ldr	r3, [r11, #0x4]
   10b9c: e3530000     	cmp	r3, #0
   10ba0: 0a00006d     	beq	0x10d5c <parse_format+0x644> @ imm = #0x1b4
   10ba4: e51b3010     	ldr	r3, [r11, #-0x10]
   10ba8: e51b2014     	ldr	r2, [r11, #-0x14]
   10bac: e0824003     	add	r4, r2, r3
   10bb0: e59b0004     	ldr	r0, [r11, #0x4]
   10bb4: ebffee48     	bl	0xc4dc <strlen@plt>     @ imm = #-0x46e0
   10bb8: e1a03000     	mov	r3, r0
   10bbc: e1a00004     	mov	r0, r4
   10bc0: e59b1004     	ldr	r1, [r11, #0x4]
   10bc4: e1a02003     	mov	r2, r3
   10bc8: ebffedc2     	bl	0xc2d8 <strncpy@plt>    @ imm = #-0x48f8
   10bcc: e59b0004     	ldr	r0, [r11, #0x4]
   10bd0: ebffee41     	bl	0xc4dc <strlen@plt>     @ imm = #-0x46fc
   10bd4: e1a02000     	mov	r2, r0
   10bd8: e51b3010     	ldr	r3, [r11, #-0x10]
   10bdc: e0823003     	add	r3, r2, r3
   10be0: e50b3010     	str	r3, [r11, #-0x10]
   10be4: ea000065     	b	0x10d80 <parse_format+0x668> @ imm = #0x194
   10be8: e51b3024     	ldr	r3, [r11, #-0x24]
   10bec: e3530000     	cmp	r3, #0
   10bf0: da00005b     	ble	0x10d64 <parse_format+0x64c> @ imm = #0x16c
   10bf4: e51b3024     	ldr	r3, [r11, #-0x24]
   10bf8: e3530063     	cmp	r3, #99
   10bfc: ca00005a     	bgt	0x10d6c <parse_format+0x654> @ imm = #0x168
   10c00: e51b3010     	ldr	r3, [r11, #-0x10]
   10c04: e51b2014     	ldr	r2, [r11, #-0x14]
   10c08: e0822003     	add	r2, r2, r3
   10c0c: e51b3024     	ldr	r3, [r11, #-0x24]
   10c10: e59f11f4     	ldr	r1, [pc, #0x1f4]        @ 0x10e0c <parse_format+0x6f4>
   10c14: e0c10391     	smull	r0, r1, r1, r3
   10c18: e1a01141     	asr	r1, r1, #2
   10c1c: e1a03fc3     	asr	r3, r3, #31
   10c20: e0633001     	rsb	r3, r3, r1
   10c24: e6ef3073     	uxtb	r3, r3
   10c28: e2833030     	add	r3, r3, #48
   10c2c: e6ef3073     	uxtb	r3, r3
   10c30: e5c23000     	strb	r3, [r2]
   10c34: e51b3010     	ldr	r3, [r11, #-0x10]
   10c38: e2833001     	add	r3, r3, #1
   10c3c: e51b2014     	ldr	r2, [r11, #-0x14]
   10c40: e0820003     	add	r0, r2, r3
   10c44: e51b1024     	ldr	r1, [r11, #-0x24]
   10c48: e59f31bc     	ldr	r3, [pc, #0x1bc]        @ 0x10e0c <parse_format+0x6f4>
   10c4c: e0c32193     	smull	r2, r3, r3, r1
   10c50: e1a02143     	asr	r2, r3, #2
   10c54: e1a03fc1     	asr	r3, r1, #31
   10c58: e0632002     	rsb	r2, r3, r2
   10c5c: e1a03002     	mov	r3, r2
   10c60: e1a03103     	lsl	r3, r3, #2
   10c64: e0833002     	add	r3, r3, r2
   10c68: e1a03083     	lsl	r3, r3, #1
   10c6c: e0632001     	rsb	r2, r3, r1
   10c70: e6ef3072     	uxtb	r3, r2
   10c74: e2833030     	add	r3, r3, #48
   10c78: e6ef3073     	uxtb	r3, r3
   10c7c: e5c03000     	strb	r3, [r0]
   10c80: e51b3010     	ldr	r3, [r11, #-0x10]
   10c84: e2833002     	add	r3, r3, #2
   10c88: e50b3010     	str	r3, [r11, #-0x10]
   10c8c: ea00003b     	b	0x10d80 <parse_format+0x668> @ imm = #0xec
   10c90: e51b3028     	ldr	r3, [r11, #-0x28]
   10c94: e3530000     	cmp	r3, #0
   10c98: 0a000035     	beq	0x10d74 <parse_format+0x65c> @ imm = #0xd4
   10c9c: e51b3010     	ldr	r3, [r11, #-0x10]
   10ca0: e51b2014     	ldr	r2, [r11, #-0x14]
   10ca4: e0824003     	add	r4, r2, r3
   10ca8: e51b0028     	ldr	r0, [r11, #-0x28]
   10cac: ebffee0a     	bl	0xc4dc <strlen@plt>     @ imm = #-0x47d8
   10cb0: e1a03000     	mov	r3, r0
   10cb4: e1a00004     	mov	r0, r4
   10cb8: e51b1028     	ldr	r1, [r11, #-0x28]
   10cbc: e1a02003     	mov	r2, r3
   10cc0: ebffed84     	bl	0xc2d8 <strncpy@plt>    @ imm = #-0x49f0
   10cc4: e51b0028     	ldr	r0, [r11, #-0x28]
   10cc8: ebffee03     	bl	0xc4dc <strlen@plt>     @ imm = #-0x47f4
   10ccc: e1a02000     	mov	r2, r0
   10cd0: e51b3010     	ldr	r3, [r11, #-0x10]
   10cd4: e0823003     	add	r3, r2, r3
   10cd8: e50b3010     	str	r3, [r11, #-0x10]
   10cdc: ea000027     	b	0x10d80 <parse_format+0x668> @ imm = #0x9c
   10ce0: e59b3008     	ldr	r3, [r11, #0x8]
   10ce4: e3530000     	cmp	r3, #0
   10ce8: 0a000023     	beq	0x10d7c <parse_format+0x664> @ imm = #0x8c
   10cec: e51b3010     	ldr	r3, [r11, #-0x10]
   10cf0: e51b2014     	ldr	r2, [r11, #-0x14]
   10cf4: e0824003     	add	r4, r2, r3
   10cf8: e59b0008     	ldr	r0, [r11, #0x8]
   10cfc: ebffedf6     	bl	0xc4dc <strlen@plt>     @ imm = #-0x4828
   10d00: e1a03000     	mov	r3, r0
   10d04: e1a00004     	mov	r0, r4
   10d08: e59b1008     	ldr	r1, [r11, #0x8]
   10d0c: e1a02003     	mov	r2, r3
   10d10: ebffed70     	bl	0xc2d8 <strncpy@plt>    @ imm = #-0x4a40
   10d14: e59b0008     	ldr	r0, [r11, #0x8]
   10d18: ebffedef     	bl	0xc4dc <strlen@plt>     @ imm = #-0x4844
   10d1c: e1a02000     	mov	r2, r0
   10d20: e51b3010     	ldr	r3, [r11, #-0x10]
   10d24: e0823003     	add	r3, r2, r3
   10d28: e50b3010     	str	r3, [r11, #-0x10]
   10d2c: ea000013     	b	0x10d80 <parse_format+0x668> @ imm = #0x4c
   10d30: e51b3010     	ldr	r3, [r11, #-0x10]
   10d34: e51b2014     	ldr	r2, [r11, #-0x14]
   10d38: e0823003     	add	r3, r2, r3
   10d3c: e3a02025     	mov	r2, #37
   10d40: e5c32000     	strb	r2, [r3]
   10d44: e51b3010     	ldr	r3, [r11, #-0x10]
   10d48: e2833001     	add	r3, r3, #1
   10d4c: e50b3010     	str	r3, [r11, #-0x10]
   10d50: ea00000a     	b	0x10d80 <parse_format+0x668> @ imm = #0x28
   10d54: e1a00000     	mov	r0, r0
   10d58: ea000008     	b	0x10d80 <parse_format+0x668> @ imm = #0x20
   10d5c: e1a00000     	mov	r0, r0
   10d60: ea000006     	b	0x10d80 <parse_format+0x668> @ imm = #0x18
   10d64: e1a00000     	mov	r0, r0
   10d68: ea000004     	b	0x10d80 <parse_format+0x668> @ imm = #0x10
   10d6c: e1a00000     	mov	r0, r0
   10d70: ea000002     	b	0x10d80 <parse_format+0x668> @ imm = #0x8
   10d74: e1a00000     	mov	r0, r0
   10d78: ea000000     	b	0x10d80 <parse_format+0x668> @ imm = #0x0
   10d7c: e1a00000     	mov	r0, r0
   10d80: e51b301c     	ldr	r3, [r11, #-0x1c]
   10d84: e2833001     	add	r3, r3, #1
   10d88: e50b301c     	str	r3, [r11, #-0x1c]
   10d8c: ea00000a     	b	0x10dbc <parse_format+0x6a4> @ imm = #0x28
   10d90: e51b3010     	ldr	r3, [r11, #-0x10]
   10d94: e51b2014     	ldr	r2, [r11, #-0x14]
   10d98: e0823003     	add	r3, r2, r3
   10d9c: e51b1020     	ldr	r1, [r11, #-0x20]
   10da0: e51b201c     	ldr	r2, [r11, #-0x1c]
   10da4: e0812002     	add	r2, r1, r2
   10da8: e5d22000     	ldrb	r2, [r2]
   10dac: e5c32000     	strb	r2, [r3]
   10db0: e51b3010     	ldr	r3, [r11, #-0x10]
   10db4: e2833001     	add	r3, r3, #1
   10db8: e50b3010     	str	r3, [r11, #-0x10]
   10dbc: e51b301c     	ldr	r3, [r11, #-0x1c]
   10dc0: e2833001     	add	r3, r3, #1
   10dc4: e50b301c     	str	r3, [r11, #-0x1c]
   10dc8: e51b0020     	ldr	r0, [r11, #-0x20]
   10dcc: ebffedc2     	bl	0xc4dc <strlen@plt>     @ imm = #-0x48f8
   10dd0: e1a02000     	mov	r2, r0
   10dd4: e51b301c     	ldr	r3, [r11, #-0x1c]
   10dd8: e1520003     	cmp	r2, r3
   10ddc: 8affff0e     	bhi	0x10a1c <parse_format+0x304> @ imm = #-0x3c8
   10de0: e51b3010     	ldr	r3, [r11, #-0x10]
   10de4: e51b2014     	ldr	r2, [r11, #-0x14]
   10de8: e0823003     	add	r3, r2, r3
   10dec: e3a02000     	mov	r2, #0
   10df0: e5c32000     	strb	r2, [r3]
   10df4: e51b3014     	ldr	r3, [r11, #-0x14]
   10df8: e1a00003     	mov	r0, r3
   10dfc: e24bd008     	sub	sp, r11, #8
   10e00: e8bd8810     	pop	{r4, r11, pc}
   10e04: 5c 73 05 00  	.word	0x0005735c
   10e08: 98 27 03 00  	.word	0x00032798
   10e0c: 67 66 66 66  	.word	0x66666667

