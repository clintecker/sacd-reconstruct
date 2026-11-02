00020f90 <init_sacd>:
   20f90: e92d4800     	push	{r11, lr}
   20f94: e28db004     	add	r11, sp, #4
   20f98: e24dd018     	sub	sp, sp, #24
   20f9c: e3e03000     	mvn	r3, #0
   20fa0: e50b3008     	str	r3, [r11, #-0x8]
   20fa4: e24b301c     	sub	r3, r11, #28
   20fa8: e1a00003     	mov	r0, r3
   20fac: e3a01000     	mov	r1, #0
   20fb0: e3a02010     	mov	r2, #16
   20fb4: ebffacfa     	bl	0xc3a4 <memset@plt>     @ imm = #-0x14c18
   20fb8: e59f0058     	ldr	r0, [pc, #0x58]         @ 0x21018 <init_sacd+0x88>
   20fbc: e3a01000     	mov	r1, #0
   20fc0: ebffad6c     	bl	0xc578 <open64@plt>     @ imm = #-0x14a50
   20fc4: e1a03000     	mov	r3, r0
   20fc8: e50b300c     	str	r3, [r11, #-0xc]
   20fcc: e51b300c     	ldr	r3, [r11, #-0xc]
   20fd0: e3530000     	cmp	r3, #0
   20fd4: ba00000b     	blt	0x21008 <init_sacd+0x78> @ imm = #0x2c
   20fd8: e24b301c     	sub	r3, r11, #28
   20fdc: e51b000c     	ldr	r0, [r11, #-0xc]
   20fe0: e59f1034     	ldr	r1, [pc, #0x34]         @ 0x2101c <init_sacd+0x8c>
   20fe4: e1a02003     	mov	r2, r3
   20fe8: ebffad2f     	bl	0xc4ac <ioctl@plt>      @ imm = #-0x14b44
   20fec: e1a03000     	mov	r3, r0
   20ff0: e3530000     	cmp	r3, #0
   20ff4: ba000001     	blt	0x21000 <init_sacd+0x70> @ imm = #0x4
   20ff8: e51b301c     	ldr	r3, [r11, #-0x1c]
   20ffc: e50b3008     	str	r3, [r11, #-0x8]
   21000: e51b000c     	ldr	r0, [r11, #-0xc]
   21004: ebffad76     	bl	0xc5e4 <close@plt>      @ imm = #-0x14a28
   21008: e51b3008     	ldr	r3, [r11, #-0x8]
   2100c: e1a00003     	mov	r0, r3
   21010: e24bd004     	sub	sp, r11, #4
   21014: e8bd8800     	pop	{r11, pc}
   21018: f8 52 03 00  	.word	0x000352f8
   2101c: 01 53 10 40  	.word	0x40105301

