00015ae8 <reenter>:
   15ae8: e92d4800     	push	{r11, lr}
   15aec: e28db004     	add	r11, sp, #4
   15af0: e24dd018     	sub	sp, sp, #24
   15af4: e50b0018     	str	r0, [r11, #-0x18]
   15af8: ebffdb3a     	bl	0xc7e8 <pthread_self@plt> @ imm = #-0x9318
   15afc: e1a03000     	mov	r3, r0
   15b00: e50b3008     	str	r3, [r11, #-0x8]
   15b04: e59f00d0     	ldr	r0, [pc, #0xd0]         @ 0x15bdc <reenter+0xf4>
   15b08: ebffff28     	bl	0x157b0 <possess>       @ imm = #-0x360
   15b0c: e59f30cc     	ldr	r3, [pc, #0xcc]         @ 0x15be0 <reenter+0xf8>
   15b10: e50b300c     	str	r3, [r11, #-0xc]
   15b14: ea00000a     	b	0x15b44 <reenter+0x5c>  @ imm = #0x28
   15b18: e51b3010     	ldr	r3, [r11, #-0x10]
   15b1c: e5933000     	ldr	r3, [r3]
   15b20: e1a00003     	mov	r0, r3
   15b24: e51b1008     	ldr	r1, [r11, #-0x8]
   15b28: ebffda89     	bl	0xc554 <pthread_equal@plt> @ imm = #-0x95dc
   15b2c: e1a03000     	mov	r3, r0
   15b30: e3530000     	cmp	r3, #0
   15b34: 1a000009     	bne	0x15b60 <reenter+0x78>  @ imm = #0x24
   15b38: e51b3010     	ldr	r3, [r11, #-0x10]
   15b3c: e2833008     	add	r3, r3, #8
   15b40: e50b300c     	str	r3, [r11, #-0xc]
   15b44: e51b300c     	ldr	r3, [r11, #-0xc]
   15b48: e5933000     	ldr	r3, [r3]
   15b4c: e50b3010     	str	r3, [r11, #-0x10]
   15b50: e51b3010     	ldr	r3, [r11, #-0x10]
   15b54: e3530000     	cmp	r3, #0
   15b58: 1affffee     	bne	0x15b18 <reenter+0x30>  @ imm = #-0x48
   15b5c: ea000000     	b	0x15b64 <reenter+0x7c>  @ imm = #0x0
   15b60: e1a00000     	mov	r0, r0
   15b64: e51b3010     	ldr	r3, [r11, #-0x10]
   15b68: e3530000     	cmp	r3, #0
   15b6c: 1a000001     	bne	0x15b78 <reenter+0x90>  @ imm = #0x4
   15b70: e3a00016     	mov	r0, #22
   15b74: ebfffe99     	bl	0x155e0 <fail>          @ imm = #-0x59c
   15b78: e51b3010     	ldr	r3, [r11, #-0x10]
   15b7c: e3a02001     	mov	r2, #1
   15b80: e5832004     	str	r2, [r3, #0x4]
   15b84: e59f3054     	ldr	r3, [pc, #0x54]         @ 0x15be0 <reenter+0xf8>
   15b88: e5932000     	ldr	r2, [r3]
   15b8c: e51b3010     	ldr	r3, [r11, #-0x10]
   15b90: e1520003     	cmp	r2, r3
   15b94: 0a00000a     	beq	0x15bc4 <reenter+0xdc>  @ imm = #0x28
   15b98: e51b3010     	ldr	r3, [r11, #-0x10]
   15b9c: e5932008     	ldr	r2, [r3, #0x8]
   15ba0: e51b300c     	ldr	r3, [r11, #-0xc]
   15ba4: e5832000     	str	r2, [r3]
   15ba8: e59f3030     	ldr	r3, [pc, #0x30]         @ 0x15be0 <reenter+0xf8>
   15bac: e5932000     	ldr	r2, [r3]
   15bb0: e51b3010     	ldr	r3, [r11, #-0x10]
   15bb4: e5832008     	str	r2, [r3, #0x8]
   15bb8: e59f3020     	ldr	r3, [pc, #0x20]         @ 0x15be0 <reenter+0xf8>
   15bbc: e51b2010     	ldr	r2, [r11, #-0x10]
   15bc0: e5832000     	str	r2, [r3]
   15bc4: e59f0010     	ldr	r0, [pc, #0x10]         @ 0x15bdc <reenter+0xf4>
   15bc8: e3a01001     	mov	r1, #1
   15bcc: e3a02001     	mov	r2, #1
   15bd0: ebffff16     	bl	0x15830 <twist>         @ imm = #-0x3a8
   15bd4: e24bd004     	sub	sp, r11, #4
   15bd8: e8bd8800     	pop	{r11, pc}
   15bdc: 68 73 05 00  	.word	0x00057368
   15be0: b8 73 05 00  	.word	0x000573b8

