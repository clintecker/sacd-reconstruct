00013a94 <str_replace>:
   13a94: e92d4800     	push	{r11, lr}
   13a98: e28db004     	add	r11, sp, #4
   13a9c: e24dd030     	sub	sp, sp, #48
   13aa0: e50b0028     	str	r0, [r11, #-0x28]
   13aa4: e50b102c     	str	r1, [r11, #-0x2c]
   13aa8: e50b2030     	str	r2, [r11, #-0x30]
   13aac: e51b0028     	ldr	r0, [r11, #-0x28]
   13ab0: ebffe289     	bl	0xc4dc <strlen@plt>     @ imm = #-0x75dc
   13ab4: e1a03000     	mov	r3, r0
   13ab8: e2833001     	add	r3, r3, #1
   13abc: e50b3024     	str	r3, [r11, #-0x24]
   13ac0: e51b002c     	ldr	r0, [r11, #-0x2c]
   13ac4: ebffe284     	bl	0xc4dc <strlen@plt>     @ imm = #-0x75f0
   13ac8: e1a03000     	mov	r3, r0
   13acc: e50b3020     	str	r3, [r11, #-0x20]
   13ad0: e51b0030     	ldr	r0, [r11, #-0x30]
   13ad4: ebffe280     	bl	0xc4dc <strlen@plt>     @ imm = #-0x7600
   13ad8: e1a03000     	mov	r3, r0
   13adc: e50b301c     	str	r3, [r11, #-0x1c]
   13ae0: e51b0024     	ldr	r0, [r11, #-0x24]
   13ae4: ebffe2df     	bl	0xc668 <malloc@plt>     @ imm = #-0x7484
   13ae8: e1a03000     	mov	r3, r0
   13aec: e50b3018     	str	r3, [r11, #-0x18]
   13af0: e51b3018     	ldr	r3, [r11, #-0x18]
   13af4: e50b3014     	str	r3, [r11, #-0x14]
   13af8: e51b3018     	ldr	r3, [r11, #-0x18]
   13afc: e3530000     	cmp	r3, #0
   13b00: 0a000042     	beq	0x13c10 <str_replace+0x17c> @ imm = #0x108
   13b04: e51b0028     	ldr	r0, [r11, #-0x28]
   13b08: e51b102c     	ldr	r1, [r11, #-0x2c]
   13b0c: ebffe2ae     	bl	0xc5cc <strstr@plt>     @ imm = #-0x7548
   13b10: e1a03000     	mov	r3, r0
   13b14: e50b3010     	str	r3, [r11, #-0x10]
   13b18: e51b3010     	ldr	r3, [r11, #-0x10]
   13b1c: e3530000     	cmp	r3, #0
   13b20: 0a000036     	beq	0x13c00 <str_replace+0x16c> @ imm = #0xd8
   13b24: e51b2010     	ldr	r2, [r11, #-0x10]
   13b28: e51b3028     	ldr	r3, [r11, #-0x28]
   13b2c: e0633002     	rsb	r3, r3, r2
   13b30: e50b300c     	str	r3, [r11, #-0xc]
   13b34: e51b201c     	ldr	r2, [r11, #-0x1c]
   13b38: e51b3020     	ldr	r3, [r11, #-0x20]
   13b3c: e0633002     	rsb	r3, r3, r2
   13b40: e51b2024     	ldr	r2, [r11, #-0x24]
   13b44: e0823003     	add	r3, r2, r3
   13b48: e50b3024     	str	r3, [r11, #-0x24]
   13b4c: e51b0018     	ldr	r0, [r11, #-0x18]
   13b50: e51b1024     	ldr	r1, [r11, #-0x24]
   13b54: ebffe30b     	bl	0xc788 <realloc@plt>    @ imm = #-0x73d4
   13b58: e1a03000     	mov	r3, r0
   13b5c: e50b3008     	str	r3, [r11, #-0x8]
   13b60: e51b3008     	ldr	r3, [r11, #-0x8]
   13b64: e3530000     	cmp	r3, #0
   13b68: 1a000003     	bne	0x13b7c <str_replace+0xe8> @ imm = #0xc
   13b6c: e51b0018     	ldr	r0, [r11, #-0x18]
   13b70: ebffe229     	bl	0xc41c <free@plt>       @ imm = #-0x775c
   13b74: e3a03000     	mov	r3, #0
   13b78: ea000025     	b	0x13c14 <str_replace+0x180> @ imm = #0x94
   13b7c: e51b2014     	ldr	r2, [r11, #-0x14]
   13b80: e51b3018     	ldr	r3, [r11, #-0x18]
   13b84: e0633002     	rsb	r3, r3, r2
   13b88: e51b2008     	ldr	r2, [r11, #-0x8]
   13b8c: e0823003     	add	r3, r2, r3
   13b90: e50b3014     	str	r3, [r11, #-0x14]
   13b94: e51b3008     	ldr	r3, [r11, #-0x8]
   13b98: e50b3018     	str	r3, [r11, #-0x18]
   13b9c: e51b0014     	ldr	r0, [r11, #-0x14]
   13ba0: e51b1028     	ldr	r1, [r11, #-0x28]
   13ba4: e51b200c     	ldr	r2, [r11, #-0xc]
   13ba8: ebffe2cf     	bl	0xc6ec <memmove@plt>    @ imm = #-0x74c4
   13bac: e51b2028     	ldr	r2, [r11, #-0x28]
   13bb0: e51b300c     	ldr	r3, [r11, #-0xc]
   13bb4: e0823003     	add	r3, r2, r3
   13bb8: e50b3028     	str	r3, [r11, #-0x28]
   13bbc: e51b2014     	ldr	r2, [r11, #-0x14]
   13bc0: e51b300c     	ldr	r3, [r11, #-0xc]
   13bc4: e0823003     	add	r3, r2, r3
   13bc8: e50b3014     	str	r3, [r11, #-0x14]
   13bcc: e51b0014     	ldr	r0, [r11, #-0x14]
   13bd0: e51b1030     	ldr	r1, [r11, #-0x30]
   13bd4: e51b201c     	ldr	r2, [r11, #-0x1c]
   13bd8: ebffe2c3     	bl	0xc6ec <memmove@plt>    @ imm = #-0x74f4
   13bdc: e51b2028     	ldr	r2, [r11, #-0x28]
   13be0: e51b3020     	ldr	r3, [r11, #-0x20]
   13be4: e0823003     	add	r3, r2, r3
   13be8: e50b3028     	str	r3, [r11, #-0x28]
   13bec: e51b2014     	ldr	r2, [r11, #-0x14]
   13bf0: e51b301c     	ldr	r3, [r11, #-0x1c]
   13bf4: e0823003     	add	r3, r2, r3
   13bf8: e50b3014     	str	r3, [r11, #-0x14]
   13bfc: eaffffc0     	b	0x13b04 <str_replace+0x70> @ imm = #-0x100
   13c00: e51b0014     	ldr	r0, [r11, #-0x14]
   13c04: e51b1028     	ldr	r1, [r11, #-0x28]
   13c08: ebffe24b     	bl	0xc53c <strcpy@plt>     @ imm = #-0x76d4
   13c0c: e1a00000     	mov	r0, r0
   13c10: e51b3018     	ldr	r3, [r11, #-0x18]
   13c14: e1a00003     	mov	r0, r3
   13c18: e24bd004     	sub	sp, r11, #4
   13c1c: e8bd8800     	pop	{r11, pc}

