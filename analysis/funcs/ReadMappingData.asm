00018b0c <ReadMappingData>:
   18b0c: e92d4800     	push	{r11, lr}
   18b10: e28db004     	add	r11, sp, #4
   18b14: e24dd018     	sub	sp, sp, #24
   18b18: e50b0010     	str	r0, [r11, #-0x10]
   18b1c: e50b1014     	str	r1, [r11, #-0x14]
   18b20: e51b3014     	ldr	r3, [r11, #-0x14]
   18b24: e2833a6e     	add	r3, r3, #450560
   18b28: e2833e7f     	add	r3, r3, #2032
   18b2c: e51b0010     	ldr	r0, [r11, #-0x10]
   18b30: e3a01001     	mov	r1, #1
   18b34: e1a02003     	mov	r2, r3
   18b38: eb000b3c     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x2cf0
   18b3c: e1a03000     	mov	r3, r0
   18b40: e3530000     	cmp	r3, #0
   18b44: 0a000001     	beq	0x18b50 <ReadMappingData+0x44> @ imm = #0x4
   18b48: e3a03001     	mov	r3, #1
   18b4c: ea000059     	b	0x18cb8 <ReadMappingData+0x1ac> @ imm = #0x164
   18b50: e51b3014     	ldr	r3, [r11, #-0x14]
   18b54: e5931004     	ldr	r1, [r3, #0x4]
   18b58: e51b2014     	ldr	r2, [r11, #-0x14]
   18b5c: e59f3160     	ldr	r3, [pc, #0x160]        @ 0x18cc4 <ReadMappingData+0x1b8>
   18b60: e7922003     	ldr	r2, [r2, r3]
   18b64: e51b3014     	ldr	r3, [r11, #-0x14]
   18b68: e283c0b4     	add	r12, r3, #180
   18b6c: e51b3014     	ldr	r3, [r11, #-0x14]
   18b70: e2830008     	add	r0, r3, #8
   18b74: e51be014     	ldr	lr, [r11, #-0x14]
   18b78: e59f3148     	ldr	r3, [pc, #0x148]        @ 0x18cc8 <ReadMappingData+0x1bc>
   18b7c: e08e3003     	add	r3, lr, r3
   18b80: e58d0000     	str	r0, [sp]
   18b84: e58d3004     	str	r3, [sp, #0x4]
   18b88: e51b0010     	ldr	r0, [r11, #-0x10]
   18b8c: e1a0300c     	mov	r3, r12
   18b90: ebfffe6b     	bl	0x18544 <ReadTableMappingData> @ imm = #-0x654
   18b94: e1a03000     	mov	r3, r0
   18b98: e50b3008     	str	r3, [r11, #-0x8]
   18b9c: e51b3008     	ldr	r3, [r11, #-0x8]
   18ba0: e3530000     	cmp	r3, #0
   18ba4: 0a000001     	beq	0x18bb0 <ReadMappingData+0xa4> @ imm = #0x4
   18ba8: e51b3008     	ldr	r3, [r11, #-0x8]
   18bac: ea000041     	b	0x18cb8 <ReadMappingData+0x1ac> @ imm = #0x104
   18bb0: e51b2014     	ldr	r2, [r11, #-0x14]
   18bb4: e59f3110     	ldr	r3, [pc, #0x110]        @ 0x18ccc <ReadMappingData+0x1c0>
   18bb8: e7923003     	ldr	r3, [r2, r3]
   18bbc: e3530001     	cmp	r3, #1
   18bc0: 1a000008     	bne	0x18be8 <ReadMappingData+0xdc> @ imm = #0x20
   18bc4: e51b0014     	ldr	r0, [r11, #-0x14]
   18bc8: ebffff4f     	bl	0x1890c <CopyMappingData> @ imm = #-0x2c4
   18bcc: e1a03000     	mov	r3, r0
   18bd0: e50b3008     	str	r3, [r11, #-0x8]
   18bd4: e51b3008     	ldr	r3, [r11, #-0x8]
   18bd8: e3530000     	cmp	r3, #0
   18bdc: 0a00001a     	beq	0x18c4c <ReadMappingData+0x140> @ imm = #0x68
   18be0: e51b3008     	ldr	r3, [r11, #-0x8]
   18be4: ea000033     	b	0x18cb8 <ReadMappingData+0x1ac> @ imm = #0xcc
   18be8: e51b3014     	ldr	r3, [r11, #-0x14]
   18bec: e5931004     	ldr	r1, [r3, #0x4]
   18bf0: e51b2014     	ldr	r2, [r11, #-0x14]
   18bf4: e59f30d4     	ldr	r3, [pc, #0xd4]         @ 0x18cd0 <ReadMappingData+0x1c4>
   18bf8: e792c003     	ldr	r12, [r2, r3]
   18bfc: e51b3014     	ldr	r3, [r11, #-0x14]
   18c00: e2833bdd     	add	r3, r3, #226304
   18c04: e2833050     	add	r3, r3, #80
   18c08: e51b2014     	ldr	r2, [r11, #-0x14]
   18c0c: e282000c     	add	r0, r2, #12
   18c10: e51b2014     	ldr	r2, [r11, #-0x14]
   18c14: e2822a6e     	add	r2, r2, #450560
   18c18: e2822b02     	add	r2, r2, #2048
   18c1c: e58d0000     	str	r0, [sp]
   18c20: e58d2004     	str	r2, [sp, #0x4]
   18c24: e51b0010     	ldr	r0, [r11, #-0x10]
   18c28: e1a0200c     	mov	r2, r12
   18c2c: ebfffe44     	bl	0x18544 <ReadTableMappingData> @ imm = #-0x6f0
   18c30: e1a03000     	mov	r3, r0
   18c34: e50b3008     	str	r3, [r11, #-0x8]
   18c38: e51b3008     	ldr	r3, [r11, #-0x8]
   18c3c: e3530000     	cmp	r3, #0
   18c40: 0a000002     	beq	0x18c50 <ReadMappingData+0x144> @ imm = #0x8
   18c44: e51b3008     	ldr	r3, [r11, #-0x8]
   18c48: ea00001a     	b	0x18cb8 <ReadMappingData+0x1ac> @ imm = #0x68
   18c4c: e1a00000     	mov	r0, r0
   18c50: e3a03000     	mov	r3, #0
   18c54: e50b300c     	str	r3, [r11, #-0xc]
   18c58: ea000010     	b	0x18ca0 <ReadMappingData+0x194> @ imm = #0x40
   18c5c: e51b3014     	ldr	r3, [r11, #-0x14]
   18c60: e2832084     	add	r2, r3, #132
   18c64: e51b300c     	ldr	r3, [r11, #-0xc]
   18c68: e1a03103     	lsl	r3, r3, #2
   18c6c: e0823003     	add	r3, r2, r3
   18c70: e51b0010     	ldr	r0, [r11, #-0x10]
   18c74: e3a01001     	mov	r1, #1
   18c78: e1a02003     	mov	r2, r3
   18c7c: eb000aeb     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x2bac
   18c80: e1a03000     	mov	r3, r0
   18c84: e3530000     	cmp	r3, #0
   18c88: 0a000001     	beq	0x18c94 <ReadMappingData+0x188> @ imm = #0x4
   18c8c: e3a03001     	mov	r3, #1
   18c90: ea000008     	b	0x18cb8 <ReadMappingData+0x1ac> @ imm = #0x20
   18c94: e51b300c     	ldr	r3, [r11, #-0xc]
   18c98: e2833001     	add	r3, r3, #1
   18c9c: e50b300c     	str	r3, [r11, #-0xc]
   18ca0: e51b3014     	ldr	r3, [r11, #-0x14]
   18ca4: e5932004     	ldr	r2, [r3, #0x4]
   18ca8: e51b300c     	ldr	r3, [r11, #-0xc]
   18cac: e1520003     	cmp	r2, r3
   18cb0: caffffe9     	bgt	0x18c5c <ReadMappingData+0x150> @ imm = #-0x5c
   18cb4: e3a03000     	mov	r3, #0
   18cb8: e1a00003     	mov	r0, r3
   18cbc: e24bd004     	sub	sp, r11, #4
   18cc0: e8bd8800     	pop	{r11, pc}
   18cc4: 08 e8 06 00  	.word	0x0006e808
   18cc8: f8 e7 06 00  	.word	0x0006e7f8
   18ccc: f0 e7 06 00  	.word	0x0006e7f0
   18cd0: 0c e8 06 00  	.word	0x0006e80c

