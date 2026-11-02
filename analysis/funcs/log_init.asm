000144ec <log_init>:
   144ec: e92d4800     	push	{r11, lr}
   144f0: e28db004     	add	r11, sp, #4
   144f4: e24dd070     	sub	sp, sp, #112
   144f8: e3a03000     	mov	r3, #0
   144fc: e50b3024     	str	r3, [r11, #-0x24]
   14500: e59f02fc     	ldr	r0, [pc, #0x2fc]        @ 0x14804 <log_init+0x318>
   14504: ebffdf7f     	bl	0xc308 <getenv@plt>     @ imm = #-0x8204
   14508: e1a03000     	mov	r3, r0
   1450c: e50b3024     	str	r3, [r11, #-0x24]
   14510: e51b3024     	ldr	r3, [r11, #-0x24]
   14514: e3530000     	cmp	r3, #0
   14518: 0a0000b7     	beq	0x147fc <log_init+0x310> @ imm = #0x2dc
   1451c: e51b3024     	ldr	r3, [r11, #-0x24]
   14520: e5d33000     	ldrb	r3, [r3]
   14524: e3530000     	cmp	r3, #0
   14528: 0a0000b3     	beq	0x147fc <log_init+0x310> @ imm = #0x2cc
   1452c: e3a03000     	mov	r3, #0
   14530: e50b3020     	str	r3, [r11, #-0x20]
   14534: e51b0024     	ldr	r0, [r11, #-0x24]
   14538: ebffdfe7     	bl	0xc4dc <strlen@plt>     @ imm = #-0x8064
   1453c: e1a03000     	mov	r3, r0
   14540: e50b301c     	str	r3, [r11, #-0x1c]
   14544: e3a03000     	mov	r3, #0
   14548: e50b3018     	str	r3, [r11, #-0x18]
   1454c: e3a03901     	mov	r3, #16384
   14550: e50b3014     	str	r3, [r11, #-0x14]
   14554: ea000079     	b	0x14740 <log_init+0x254> @ imm = #0x1e4
   14558: e3a03001     	mov	r3, #1
   1455c: e50b3028     	str	r3, [r11, #-0x28]
   14560: e3a03000     	mov	r3, #0
   14564: e50b3010     	str	r3, [r11, #-0x10]
   14568: e3a03000     	mov	r3, #0
   1456c: e50b302c     	str	r3, [r11, #-0x2c]
   14570: e51b2024     	ldr	r2, [r11, #-0x24]
   14574: e51b3018     	ldr	r3, [r11, #-0x18]
   14578: e0820003     	add	r0, r2, r3
   1457c: e59f1284     	ldr	r1, [pc, #0x284]        @ 0x14808 <log_init+0x31c>
   14580: e24b206c     	sub	r2, r11, #108
   14584: e24b302c     	sub	r3, r11, #44
   14588: e24bc028     	sub	r12, r11, #40
   1458c: e58dc000     	str	r12, [sp]
   14590: e24bc02c     	sub	r12, r11, #44
   14594: e58dc004     	str	r12, [sp, #0x4]
   14598: ebffdfd2     	bl	0xc4e8 <sscanf@plt>     @ imm = #-0x80b8
   1459c: e1a03000     	mov	r3, r0
   145a0: e50b3010     	str	r3, [r11, #-0x10]
   145a4: e51b302c     	ldr	r3, [r11, #-0x2c]
   145a8: e51b2018     	ldr	r2, [r11, #-0x18]
   145ac: e0823003     	add	r3, r2, r3
   145b0: e50b3018     	str	r3, [r11, #-0x18]
   145b4: e51b3010     	ldr	r3, [r11, #-0x10]
   145b8: e3530000     	cmp	r3, #0
   145bc: 0a000064     	beq	0x14754 <log_init+0x268> @ imm = #0x190
   145c0: e24b306c     	sub	r3, r11, #108
   145c4: e1a00003     	mov	r0, r3
   145c8: e59f123c     	ldr	r1, [pc, #0x23c]        @ 0x1480c <log_init+0x320>
   145cc: ebffdf5c     	bl	0xc344 <strcasecmp@plt> @ imm = #-0x8290
   145d0: e1a03000     	mov	r3, r0
   145d4: e3530000     	cmp	r3, #0
   145d8: 1a000002     	bne	0x145e8 <log_init+0xfc> @ imm = #0x8
   145dc: e3a03001     	mov	r3, #1
   145e0: e50b3020     	str	r3, [r11, #-0x20]
   145e4: ea000043     	b	0x146f8 <log_init+0x20c> @ imm = #0x10c
   145e8: e24b306c     	sub	r3, r11, #108
   145ec: e1a00003     	mov	r0, r3
   145f0: e59f1218     	ldr	r1, [pc, #0x218]        @ 0x14810 <log_init+0x324>
   145f4: ebffdf52     	bl	0xc344 <strcasecmp@plt> @ imm = #-0x82b8
   145f8: e1a03000     	mov	r3, r0
   145fc: e3530000     	cmp	r3, #0
   14600: 1a000006     	bne	0x14620 <log_init+0x134> @ imm = #0x18
   14604: e51b2028     	ldr	r2, [r11, #-0x28]
   14608: e59f3204     	ldr	r3, [pc, #0x204]        @ 0x14814 <log_init+0x328>
   1460c: e1520003     	cmp	r2, r3
   14610: da000037     	ble	0x146f4 <log_init+0x208> @ imm = #0xdc
   14614: e51b3028     	ldr	r3, [r11, #-0x28]
   14618: e50b3014     	str	r3, [r11, #-0x14]
   1461c: ea000035     	b	0x146f8 <log_init+0x20c> @ imm = #0xd4
   14620: e24b306c     	sub	r3, r11, #108
   14624: e1a00003     	mov	r0, r3
   14628: e59f11e8     	ldr	r1, [pc, #0x1e8]        @ 0x14818 <log_init+0x32c>
   1462c: ebffdf44     	bl	0xc344 <strcasecmp@plt> @ imm = #-0x82f0
   14630: e1a03000     	mov	r3, r0
   14634: e3530000     	cmp	r3, #0
   14638: 1a000003     	bne	0x1464c <log_init+0x160> @ imm = #0xc
   1463c: e59f31d8     	ldr	r3, [pc, #0x1d8]        @ 0x1481c <log_init+0x330>
   14640: e3a02001     	mov	r2, #1
   14644: e5832000     	str	r2, [r3]
   14648: ea00002a     	b	0x146f8 <log_init+0x20c> @ imm = #0xa8
   1464c: e59f31cc     	ldr	r3, [pc, #0x1cc]        @ 0x14820 <log_init+0x334>
   14650: e5933000     	ldr	r3, [r3]
   14654: e50b300c     	str	r3, [r11, #-0xc]
   14658: e24b306c     	sub	r3, r11, #108
   1465c: e1a00003     	mov	r0, r3
   14660: e59f11bc     	ldr	r1, [pc, #0x1bc]        @ 0x14824 <log_init+0x338>
   14664: ebffdf36     	bl	0xc344 <strcasecmp@plt> @ imm = #-0x8328
   14668: e1a03000     	mov	r3, r0
   1466c: e3530000     	cmp	r3, #0
   14670: 13a03000     	movne	r3, #0
   14674: 03a03001     	moveq	r3, #1
   14678: e50b3008     	str	r3, [r11, #-0x8]
   1467c: ea000018     	b	0x146e4 <log_init+0x1f8> @ imm = #0x60
   14680: e51b3008     	ldr	r3, [r11, #-0x8]
   14684: e3530000     	cmp	r3, #0
   14688: 0a000004     	beq	0x146a0 <log_init+0x1b4> @ imm = #0x10
   1468c: e51b3028     	ldr	r3, [r11, #-0x28]
   14690: e1a02003     	mov	r2, r3
   14694: e51b300c     	ldr	r3, [r11, #-0xc]
   14698: e5832004     	str	r2, [r3, #0x4]
   1469c: ea00000d     	b	0x146d8 <log_init+0x1ec> @ imm = #0x34
   146a0: e51b300c     	ldr	r3, [r11, #-0xc]
   146a4: e5933000     	ldr	r3, [r3]
   146a8: e24b206c     	sub	r2, r11, #108
   146ac: e1a00002     	mov	r0, r2
   146b0: e1a01003     	mov	r1, r3
   146b4: ebffdf22     	bl	0xc344 <strcasecmp@plt> @ imm = #-0x8378
   146b8: e1a03000     	mov	r3, r0
   146bc: e3530000     	cmp	r3, #0
   146c0: 1a000004     	bne	0x146d8 <log_init+0x1ec> @ imm = #0x10
   146c4: e51b3028     	ldr	r3, [r11, #-0x28]
   146c8: e1a02003     	mov	r2, r3
   146cc: e51b300c     	ldr	r3, [r11, #-0xc]
   146d0: e5832004     	str	r2, [r3, #0x4]
   146d4: ea000007     	b	0x146f8 <log_init+0x20c> @ imm = #0x1c
   146d8: e51b300c     	ldr	r3, [r11, #-0xc]
   146dc: e5933008     	ldr	r3, [r3, #0x8]
   146e0: e50b300c     	str	r3, [r11, #-0xc]
   146e4: e51b300c     	ldr	r3, [r11, #-0xc]
   146e8: e3530000     	cmp	r3, #0
   146ec: 1affffe3     	bne	0x14680 <log_init+0x194> @ imm = #-0x74
   146f0: ea000000     	b	0x146f8 <log_init+0x20c> @ imm = #0x0
   146f4: e1a00000     	mov	r0, r0
   146f8: e51b2024     	ldr	r2, [r11, #-0x24]
   146fc: e51b3018     	ldr	r3, [r11, #-0x18]
   14700: e0821003     	add	r1, r2, r3
   14704: e59f211c     	ldr	r2, [pc, #0x11c]        @ 0x14828 <log_init+0x33c>
   14708: e24b302c     	sub	r3, r11, #44
   1470c: e1a00001     	mov	r0, r1
   14710: e1a01002     	mov	r1, r2
   14714: e1a02003     	mov	r2, r3
   14718: ebffdf72     	bl	0xc4e8 <sscanf@plt>     @ imm = #-0x8238
   1471c: e1a03000     	mov	r3, r0
   14720: e50b3010     	str	r3, [r11, #-0x10]
   14724: e51b302c     	ldr	r3, [r11, #-0x2c]
   14728: e51b2018     	ldr	r2, [r11, #-0x18]
   1472c: e0823003     	add	r3, r2, r3
   14730: e50b3018     	str	r3, [r11, #-0x18]
   14734: e51b3010     	ldr	r3, [r11, #-0x10]
   14738: e3730001     	cmn	r3, #1
   1473c: 0a000006     	beq	0x1475c <log_init+0x270> @ imm = #0x18
   14740: e51b2018     	ldr	r2, [r11, #-0x18]
   14744: e51b301c     	ldr	r3, [r11, #-0x1c]
   14748: e1520003     	cmp	r2, r3
   1474c: baffff81     	blt	0x14558 <log_init+0x6c> @ imm = #-0x1fc
   14750: ea000002     	b	0x14760 <log_init+0x274> @ imm = #0x8
   14754: e1a00000     	mov	r0, r0
   14758: ea000000     	b	0x14760 <log_init+0x274> @ imm = #0x0
   1475c: e1a00000     	mov	r0, r0
   14760: e51b3020     	ldr	r3, [r11, #-0x20]
   14764: e3530000     	cmp	r3, #0
   14768: 1a000001     	bne	0x14774 <log_init+0x288> @ imm = #0x4
   1476c: e51b3014     	ldr	r3, [r11, #-0x14]
   14770: ea000000     	b	0x14778 <log_init+0x28c> @ imm = #0x0
   14774: e3a03000     	mov	r3, #0
   14778: e1a00003     	mov	r0, r3
   1477c: eb000124     	bl	0x14c14 <set_log_buffering> @ imm = #0x490
   14780: e59f00a4     	ldr	r0, [pc, #0xa4]         @ 0x1482c <log_init+0x340>
   14784: ebffdedf     	bl	0xc308 <getenv@plt>     @ imm = #-0x8484
   14788: e1a03000     	mov	r3, r0
   1478c: e50b3024     	str	r3, [r11, #-0x24]
   14790: e51b3024     	ldr	r3, [r11, #-0x24]
   14794: e3530000     	cmp	r3, #0
   14798: 0a000011     	beq	0x147e4 <log_init+0x2f8> @ imm = #0x44
   1479c: e51b3024     	ldr	r3, [r11, #-0x24]
   147a0: e5d33000     	ldrb	r3, [r3]
   147a4: e3530000     	cmp	r3, #0
   147a8: 0a00000d     	beq	0x147e4 <log_init+0x2f8> @ imm = #0x34
   147ac: e51b0024     	ldr	r0, [r11, #-0x24]
   147b0: eb0000e9     	bl	0x14b5c <set_log_file>  @ imm = #0x3a4
   147b4: e1a03000     	mov	r3, r0
   147b8: e3530000     	cmp	r3, #0
   147bc: 0a00000d     	beq	0x147f8 <log_init+0x30c> @ imm = #0x34
   147c0: e59f3068     	ldr	r3, [pc, #0x68]         @ 0x14830 <log_init+0x344>
   147c4: e5933000     	ldr	r3, [r3]
   147c8: e1a02003     	mov	r2, r3
   147cc: e59f3060     	ldr	r3, [pc, #0x60]         @ 0x14834 <log_init+0x348>
   147d0: e1a00002     	mov	r0, r2
   147d4: e1a01003     	mov	r1, r3
   147d8: e51b2024     	ldr	r2, [r11, #-0x24]
   147dc: ebffdf98     	bl	0xc644 <fprintf@plt>    @ imm = #-0x81a0
   147e0: ea000005     	b	0x147fc <log_init+0x310> @ imm = #0x14
   147e4: e59f3044     	ldr	r3, [pc, #0x44]         @ 0x14830 <log_init+0x344>
   147e8: e5932000     	ldr	r2, [r3]
   147ec: e59f3044     	ldr	r3, [pc, #0x44]         @ 0x14838 <log_init+0x34c>
   147f0: e5832000     	str	r2, [r3]
   147f4: ea000000     	b	0x147fc <log_init+0x310> @ imm = #0x0
   147f8: e1a00000     	mov	r0, r0
   147fc: e24bd004     	sub	sp, r11, #4
   14800: e8bd8800     	pop	{r11, pc}
   14804: 28 29 03 00  	.word	0x00032928
   14808: 34 29 03 00  	.word	0x00032934
   1480c: 84 29 03 00  	.word	0x00032984
   14810: 8c 29 03 00  	.word	0x0003298c
   14814: ff 01 00 00  	.word	0x000001ff
   14818: 94 29 03 00  	.word	0x00032994
   1481c: 58 73 05 00  	.word	0x00057358
   14820: 44 73 05 00  	.word	0x00057344
   14824: a0 29 03 00  	.word	0x000329a0
   14828: a4 29 03 00  	.word	0x000329a4
   1482c: ac 29 03 00  	.word	0x000329ac
   14830: f8 6d 05 00  	.word	0x00056df8
   14834: b8 29 03 00  	.word	0x000329b8
   14838: 54 73 05 00  	.word	0x00057354

