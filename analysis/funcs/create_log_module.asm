00014ad4 <create_log_module>:
   14ad4: e92d4800     	push	{r11, lr}
   14ad8: e28db004     	add	r11, sp, #4
   14adc: e24dd010     	sub	sp, sp, #16
   14ae0: e50b0010     	str	r0, [r11, #-0x10]
   14ae4: e3a0000c     	mov	r0, #12
   14ae8: ebffdede     	bl	0xc668 <malloc@plt>     @ imm = #-0x8488
   14aec: e1a03000     	mov	r3, r0
   14af0: e50b3008     	str	r3, [r11, #-0x8]
   14af4: e51b3008     	ldr	r3, [r11, #-0x8]
   14af8: e3530000     	cmp	r3, #0
   14afc: 0a000011     	beq	0x14b48 <create_log_module+0x74> @ imm = #0x44
   14b00: e51b0010     	ldr	r0, [r11, #-0x10]
   14b04: ebffded1     	bl	0xc650 <strdup@plt>     @ imm = #-0x84bc
   14b08: e1a03000     	mov	r3, r0
   14b0c: e1a02003     	mov	r2, r3
   14b10: e51b3008     	ldr	r3, [r11, #-0x8]
   14b14: e5832000     	str	r2, [r3]
   14b18: e51b3008     	ldr	r3, [r11, #-0x8]
   14b1c: e3a02000     	mov	r2, #0
   14b20: e5832004     	str	r2, [r3, #0x4]
   14b24: e59f302c     	ldr	r3, [pc, #0x2c]         @ 0x14b58 <create_log_module+0x84>
   14b28: e5932000     	ldr	r2, [r3]
   14b2c: e51b3008     	ldr	r3, [r11, #-0x8]
   14b30: e5832008     	str	r2, [r3, #0x8]
   14b34: e59f301c     	ldr	r3, [pc, #0x1c]         @ 0x14b58 <create_log_module+0x84>
   14b38: e51b2008     	ldr	r2, [r11, #-0x8]
   14b3c: e5832000     	str	r2, [r3]
   14b40: e51b0008     	ldr	r0, [r11, #-0x8]
   14b44: ebffff7b     	bl	0x14938 <set_log_module_level> @ imm = #-0x214
   14b48: e51b3008     	ldr	r3, [r11, #-0x8]
   14b4c: e1a00003     	mov	r0, r3
   14b50: e24bd004     	sub	sp, r11, #4
   14b54: e8bd8800     	pop	{r11, pc}
   14b58: 44 73 05 00  	.word	0x00057344

