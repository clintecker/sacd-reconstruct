00015f10 <join_all>:
   15f10: e92d4800     	push	{r11, lr}
   15f14: e28db004     	add	r11, sp, #4
   15f18: e24dd010     	sub	sp, sp, #16
   15f1c: e3a03000     	mov	r3, #0
   15f20: e50b3010     	str	r3, [r11, #-0x10]
   15f24: e59f0108     	ldr	r0, [pc, #0x108]        @ 0x16034 <join_all+0x124>
   15f28: ebfffe20     	bl	0x157b0 <possess>       @ imm = #-0x780
   15f2c: ea000036     	b	0x1600c <join_all+0xfc> @ imm = #0xd8
   15f30: e59f00fc     	ldr	r0, [pc, #0xfc]         @ 0x16034 <join_all+0x124>
   15f34: e3a01001     	mov	r1, #1
   15f38: e3a02000     	mov	r2, #0
   15f3c: ebfffe66     	bl	0x158dc <wait_for>      @ imm = #-0x668
   15f40: e59f30f0     	ldr	r3, [pc, #0xf0]         @ 0x16038 <join_all+0x128>
   15f44: e50b3008     	str	r3, [r11, #-0x8]
   15f48: ea000006     	b	0x15f68 <join_all+0x58> @ imm = #0x18
   15f4c: e51b300c     	ldr	r3, [r11, #-0xc]
   15f50: e5933004     	ldr	r3, [r3, #0x4]
   15f54: e3530000     	cmp	r3, #0
   15f58: 1a000009     	bne	0x15f84 <join_all+0x74> @ imm = #0x24
   15f5c: e51b300c     	ldr	r3, [r11, #-0xc]
   15f60: e2833008     	add	r3, r3, #8
   15f64: e50b3008     	str	r3, [r11, #-0x8]
   15f68: e51b3008     	ldr	r3, [r11, #-0x8]
   15f6c: e5933000     	ldr	r3, [r3]
   15f70: e50b300c     	str	r3, [r11, #-0xc]
   15f74: e51b300c     	ldr	r3, [r11, #-0xc]
   15f78: e3530000     	cmp	r3, #0
   15f7c: 1afffff2     	bne	0x15f4c <join_all+0x3c> @ imm = #-0x38
   15f80: ea000000     	b	0x15f88 <join_all+0x78> @ imm = #0x0
   15f84: e1a00000     	mov	r0, r0
   15f88: e51b300c     	ldr	r3, [r11, #-0xc]
   15f8c: e3530000     	cmp	r3, #0
   15f90: 1a000001     	bne	0x15f9c <join_all+0x8c> @ imm = #0x4
   15f94: e3a00016     	mov	r0, #22
   15f98: ebfffd90     	bl	0x155e0 <fail>          @ imm = #-0x9c0
   15f9c: e51b300c     	ldr	r3, [r11, #-0xc]
   15fa0: e5933000     	ldr	r3, [r3]
   15fa4: e1a00003     	mov	r0, r3
   15fa8: e3a01000     	mov	r1, #0
   15fac: ebffda16     	bl	0xc80c <sprintf@plt+0xc> @ imm = #-0x97a8
   15fb0: e1a03000     	mov	r3, r0
   15fb4: e50b3014     	str	r3, [r11, #-0x14]
   15fb8: e51b3014     	ldr	r3, [r11, #-0x14]
   15fbc: e3530000     	cmp	r3, #0
   15fc0: 0a000001     	beq	0x15fcc <join_all+0xbc> @ imm = #0x4
   15fc4: e51b0014     	ldr	r0, [r11, #-0x14]
   15fc8: ebfffd84     	bl	0x155e0 <fail>          @ imm = #-0x9f0
   15fcc: e59f3060     	ldr	r3, [pc, #0x60]         @ 0x16034 <join_all+0x124>
   15fd0: e5933048     	ldr	r3, [r3, #0x48]
   15fd4: e2432001     	sub	r2, r3, #1
   15fd8: e59f3054     	ldr	r3, [pc, #0x54]         @ 0x16034 <join_all+0x124>
   15fdc: e5832048     	str	r2, [r3, #0x48]
   15fe0: e51b300c     	ldr	r3, [r11, #-0xc]
   15fe4: e5932008     	ldr	r2, [r3, #0x8]
   15fe8: e51b3008     	ldr	r3, [r11, #-0x8]
   15fec: e5832000     	str	r2, [r3]
   15ff0: e59f3044     	ldr	r3, [pc, #0x44]         @ 0x1603c <join_all+0x12c>
   15ff4: e5933000     	ldr	r3, [r3]
   15ff8: e51b000c     	ldr	r0, [r11, #-0xc]
   15ffc: e12fff33     	blx	r3
   16000: e51b3010     	ldr	r3, [r11, #-0x10]
   16004: e2833001     	add	r3, r3, #1
   16008: e50b3010     	str	r3, [r11, #-0x10]
   1600c: e59f3024     	ldr	r3, [pc, #0x24]         @ 0x16038 <join_all+0x128>
   16010: e5933000     	ldr	r3, [r3]
   16014: e3530000     	cmp	r3, #0
   16018: 1affffc4     	bne	0x15f30 <join_all+0x20> @ imm = #-0xf0
   1601c: e59f0010     	ldr	r0, [pc, #0x10]         @ 0x16034 <join_all+0x124>
   16020: ebfffdf2     	bl	0x157f0 <release>       @ imm = #-0x838
   16024: e51b3010     	ldr	r3, [r11, #-0x10]
   16028: e1a00003     	mov	r0, r3
   1602c: e24bd004     	sub	sp, r11, #4
   16030: e8bd8800     	pop	{r11, pc}
   16034: 68 73 05 00  	.word	0x00057368
   16038: b8 73 05 00  	.word	0x000573b8
   1603c: d8 e7 03 00  	.word	0x0003e7d8

