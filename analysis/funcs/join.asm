00015e0c <join>:
   15e0c: e92d4800     	push	{r11, lr}
   15e10: e28db004     	add	r11, sp, #4
   15e14: e24dd018     	sub	sp, sp, #24
   15e18: e50b0018     	str	r0, [r11, #-0x18]
   15e1c: e51b3018     	ldr	r3, [r11, #-0x18]
   15e20: e5933000     	ldr	r3, [r3]
   15e24: e1a00003     	mov	r0, r3
   15e28: e3a01000     	mov	r1, #0
   15e2c: ebffda76     	bl	0xc80c <sprintf@plt+0xc> @ imm = #-0x9628
   15e30: e1a03000     	mov	r3, r0
   15e34: e50b3010     	str	r3, [r11, #-0x10]
   15e38: e51b3010     	ldr	r3, [r11, #-0x10]
   15e3c: e3530000     	cmp	r3, #0
   15e40: 0a000001     	beq	0x15e4c <join+0x40>     @ imm = #0x4
   15e44: e51b0010     	ldr	r0, [r11, #-0x10]
   15e48: ebfffde4     	bl	0x155e0 <fail>          @ imm = #-0x870
   15e4c: e59f00b0     	ldr	r0, [pc, #0xb0]         @ 0x15f04 <join+0xf8>
   15e50: ebfffe56     	bl	0x157b0 <possess>       @ imm = #-0x6a8
   15e54: e59f30ac     	ldr	r3, [pc, #0xac]         @ 0x15f08 <join+0xfc>
   15e58: e50b3008     	str	r3, [r11, #-0x8]
   15e5c: ea000006     	b	0x15e7c <join+0x70>     @ imm = #0x18
   15e60: e51b200c     	ldr	r2, [r11, #-0xc]
   15e64: e51b3018     	ldr	r3, [r11, #-0x18]
   15e68: e1520003     	cmp	r2, r3
   15e6c: 0a000009     	beq	0x15e98 <join+0x8c>     @ imm = #0x24
   15e70: e51b300c     	ldr	r3, [r11, #-0xc]
   15e74: e2833008     	add	r3, r3, #8
   15e78: e50b3008     	str	r3, [r11, #-0x8]
   15e7c: e51b3008     	ldr	r3, [r11, #-0x8]
   15e80: e5933000     	ldr	r3, [r3]
   15e84: e50b300c     	str	r3, [r11, #-0xc]
   15e88: e51b300c     	ldr	r3, [r11, #-0xc]
   15e8c: e3530000     	cmp	r3, #0
   15e90: 1afffff2     	bne	0x15e60 <join+0x54>     @ imm = #-0x38
   15e94: ea000000     	b	0x15e9c <join+0x90>     @ imm = #0x0
   15e98: e1a00000     	mov	r0, r0
   15e9c: e51b300c     	ldr	r3, [r11, #-0xc]
   15ea0: e3530000     	cmp	r3, #0
   15ea4: 1a000001     	bne	0x15eb0 <join+0xa4>     @ imm = #0x4
   15ea8: e3a00016     	mov	r0, #22
   15eac: ebfffdcb     	bl	0x155e0 <fail>          @ imm = #-0x8d4
   15eb0: e51b300c     	ldr	r3, [r11, #-0xc]
   15eb4: e5933004     	ldr	r3, [r3, #0x4]
   15eb8: e3530000     	cmp	r3, #0
   15ebc: 0a000004     	beq	0x15ed4 <join+0xc8>     @ imm = #0x10
   15ec0: e59f303c     	ldr	r3, [pc, #0x3c]         @ 0x15f04 <join+0xf8>
   15ec4: e5933048     	ldr	r3, [r3, #0x48]
   15ec8: e2432001     	sub	r2, r3, #1
   15ecc: e59f3030     	ldr	r3, [pc, #0x30]         @ 0x15f04 <join+0xf8>
   15ed0: e5832048     	str	r2, [r3, #0x48]
   15ed4: e51b300c     	ldr	r3, [r11, #-0xc]
   15ed8: e5932008     	ldr	r2, [r3, #0x8]
   15edc: e51b3008     	ldr	r3, [r11, #-0x8]
   15ee0: e5832000     	str	r2, [r3]
   15ee4: e59f0018     	ldr	r0, [pc, #0x18]         @ 0x15f04 <join+0xf8>
   15ee8: ebfffe40     	bl	0x157f0 <release>       @ imm = #-0x700
   15eec: e59f3018     	ldr	r3, [pc, #0x18]         @ 0x15f0c <join+0x100>
   15ef0: e5933000     	ldr	r3, [r3]
   15ef4: e51b0018     	ldr	r0, [r11, #-0x18]
   15ef8: e12fff33     	blx	r3
   15efc: e24bd004     	sub	sp, r11, #4
   15f00: e8bd8800     	pop	{r11, pc}
   15f04: 68 73 05 00  	.word	0x00057368
   15f08: b8 73 05 00  	.word	0x000573b8
   15f0c: d8 e7 03 00  	.word	0x0003e7d8

