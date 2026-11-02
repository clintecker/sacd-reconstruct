00011ff4 <pb_enc_varint>:
   11ff4: e92d4800     	push	{r11, lr}
   11ff8: e28db004     	add	r11, sp, #4
   11ffc: e24dd018     	sub	sp, sp, #24
   12000: e50b0010     	str	r0, [r11, #-0x10]
   12004: e50b1014     	str	r1, [r11, #-0x14]
   12008: e50b2018     	str	r2, [r11, #-0x18]
   1200c: e3a02000     	mov	r2, #0
   12010: e3a03000     	mov	r3, #0
   12014: e14b20fc     	strd	r2, r3, [r11, #-12]
   12018: e51b3014     	ldr	r3, [r11, #-0x14]
   1201c: e5d32004     	ldrb	r2, [r3, #0x4]
   12020: e5d31005     	ldrb	r1, [r3, #0x5]
   12024: e1a01401     	lsl	r1, r1, #8
   12028: e1812002     	orr	r2, r1, r2
   1202c: e5d31006     	ldrb	r1, [r3, #0x6]
   12030: e1a01801     	lsl	r1, r1, #16
   12034: e1812002     	orr	r2, r1, r2
   12038: e5d33007     	ldrb	r3, [r3, #0x7]
   1203c: e1a03c03     	lsl	r3, r3, #24
   12040: e1833002     	orr	r3, r3, r2
   12044: e24b200c     	sub	r2, r11, #12
   12048: e1a00002     	mov	r0, r2
   1204c: e51b1018     	ldr	r1, [r11, #-0x18]
   12050: e3a02008     	mov	r2, #8
   12054: ebffffd9     	bl	0x11fc0 <endian_copy>   @ imm = #-0x9c
   12058: e14b20dc     	ldrd	r2, r3, [r11, #-12]
   1205c: e51b0010     	ldr	r0, [r11, #-0x10]
   12060: ebffff36     	bl	0x11d40 <pb_encode_varint> @ imm = #-0x328
   12064: e1a03000     	mov	r3, r0
   12068: e1a00003     	mov	r0, r3
   1206c: e24bd004     	sub	sp, r11, #4
   12070: e8bd8800     	pop	{r11, pc}

