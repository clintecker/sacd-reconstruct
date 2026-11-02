00015be4 <ignition>:
   15be4: e92d4800     	push	{r11, lr}
   15be8: e28db004     	add	r11, sp, #4
   15bec: e24dde13     	sub	sp, sp, #304
   15bf0: e50b0130     	str	r0, [r11, #-0x130]
   15bf4: e51b3130     	ldr	r3, [r11, #-0x130]
   15bf8: e50b3014     	str	r3, [r11, #-0x14]
   15bfc: e59f30a0     	ldr	r3, [pc, #0xa0]         @ 0x15ca4 <ignition+0xc0>
   15c00: e50b3010     	str	r3, [r11, #-0x10]
   15c04: e3a03000     	mov	r3, #0
   15c08: e50b300c     	str	r3, [r11, #-0xc]
   15c0c: e24b3f4b     	sub	r3, r11, #300
   15c10: e1a00003     	mov	r0, r3
   15c14: e3a01000     	mov	r1, #0
   15c18: ebffd984     	bl	0xc230 <__sigsetjmp@plt> @ imm = #-0x99f0
   15c1c: e1a03000     	mov	r3, r0
   15c20: e50b3008     	str	r3, [r11, #-0x8]
   15c24: e51b3008     	ldr	r3, [r11, #-0x8]
   15c28: e3530000     	cmp	r3, #0
   15c2c: 0a000005     	beq	0x15c48 <ignition+0x64> @ imm = #0x14
   15c30: e51b3010     	ldr	r3, [r11, #-0x10]
   15c34: e51b000c     	ldr	r0, [r11, #-0xc]
   15c38: e12fff33     	blx	r3
   15c3c: e24b3f4b     	sub	r3, r11, #300
   15c40: e1a00003     	mov	r0, r3
   15c44: ebffdae1     	bl	0xc7d0 <__pthread_unwind_next@plt> @ imm = #-0x947c
   15c48: e24b3f4b     	sub	r3, r11, #300
   15c4c: e1a00003     	mov	r0, r3
   15c50: ebffdab4     	bl	0xc728 <__pthread_register_cancel@plt> @ imm = #-0x9530
   15c54: e51b3014     	ldr	r3, [r11, #-0x14]
   15c58: e5933000     	ldr	r3, [r3]
   15c5c: e51b2014     	ldr	r2, [r11, #-0x14]
   15c60: e5922004     	ldr	r2, [r2, #0x4]
   15c64: e1a00002     	mov	r0, r2
   15c68: e12fff33     	blx	r3
   15c6c: e59f3034     	ldr	r3, [pc, #0x34]         @ 0x15ca8 <ignition+0xc4>
   15c70: e5933000     	ldr	r3, [r3]
   15c74: e51b0014     	ldr	r0, [r11, #-0x14]
   15c78: e12fff33     	blx	r3
   15c7c: e24b3f4b     	sub	r3, r11, #300
   15c80: e1a00003     	mov	r0, r3
   15c84: ebffdaaa     	bl	0xc734 <__pthread_unregister_cancel@plt> @ imm = #-0x9558
   15c88: e51b3010     	ldr	r3, [r11, #-0x10]
   15c8c: e51b000c     	ldr	r0, [r11, #-0xc]
   15c90: e12fff33     	blx	r3
   15c94: e3a03000     	mov	r3, #0
   15c98: e1a00003     	mov	r0, r3
   15c9c: e24bd004     	sub	sp, r11, #4
   15ca0: e8bd8800     	pop	{r11, pc}
   15ca4: e8 5a 01 00  	.word	0x00015ae8
   15ca8: d8 e7 03 00  	.word	0x0003e7d8

