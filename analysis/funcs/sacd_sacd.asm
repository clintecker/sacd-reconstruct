00021308 <sacd_sacd>:
   21308: e92d4800     	push	{r11, lr}
   2130c: e28db004     	add	r11, sp, #4
   21310: e24dd018     	sub	sp, sp, #24
   21314: e3e03000     	mvn	r3, #0
   21318: e50b3008     	str	r3, [r11, #-0x8]
   2131c: e24b301c     	sub	r3, r11, #28
   21320: e1a00003     	mov	r0, r3
   21324: e3a01000     	mov	r1, #0
   21328: e3a02010     	mov	r2, #16
   2132c: ebffac1c     	bl	0xc3a4 <memset@plt>     @ imm = #-0x14f90
   21330: e59f0058     	ldr	r0, [pc, #0x58]         @ 0x21390 <sacd_sacd+0x88>
   21334: e3a01000     	mov	r1, #0
   21338: ebffac8e     	bl	0xc578 <open64@plt>     @ imm = #-0x14dc8
   2133c: e1a03000     	mov	r3, r0
   21340: e50b300c     	str	r3, [r11, #-0xc]
   21344: e51b300c     	ldr	r3, [r11, #-0xc]
   21348: e3530000     	cmp	r3, #0
   2134c: ba00000b     	blt	0x21380 <sacd_sacd+0x78> @ imm = #0x2c
   21350: e24b301c     	sub	r3, r11, #28
   21354: e51b000c     	ldr	r0, [r11, #-0xc]
   21358: e59f1034     	ldr	r1, [pc, #0x34]         @ 0x21394 <sacd_sacd+0x8c>
   2135c: e1a02003     	mov	r2, r3
   21360: ebffac51     	bl	0xc4ac <ioctl@plt>      @ imm = #-0x14ebc
   21364: e1a03000     	mov	r3, r0
   21368: e3530000     	cmp	r3, #0
   2136c: ba000001     	blt	0x21378 <sacd_sacd+0x70> @ imm = #0x4
   21370: e51b301c     	ldr	r3, [r11, #-0x1c]
   21374: e50b3008     	str	r3, [r11, #-0x8]
   21378: e51b000c     	ldr	r0, [r11, #-0xc]
   2137c: ebffac98     	bl	0xc5e4 <close@plt>      @ imm = #-0x14da0
   21380: e51b3008     	ldr	r3, [r11, #-0x8]
   21384: e1a00003     	mov	r0, r3
   21388: e24bd004     	sub	sp, r11, #4
   2138c: e8bd8800     	pop	{r11, pc}
   21390: f8 52 03 00  	.word	0x000352f8
   21394: 07 53 10 40  	.word	0x40105307

