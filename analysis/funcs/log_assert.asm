000151f4 <log_assert>:
   151f4: e92d4800     	push	{r11, lr}
   151f8: e28db004     	add	r11, sp, #4
   151fc: e24dd018     	sub	sp, sp, #24
   15200: e50b0008     	str	r0, [r11, #-0x8]
   15204: e50b100c     	str	r1, [r11, #-0xc]
   15208: e50b2010     	str	r2, [r11, #-0x10]
   1520c: e59f004c     	ldr	r0, [pc, #0x4c]         @ 0x15260 <log_assert+0x6c>
   15210: e51b1008     	ldr	r1, [r11, #-0x8]
   15214: e51b200c     	ldr	r2, [r11, #-0xc]
   15218: e51b3010     	ldr	r3, [r11, #-0x10]
   1521c: ebfffea4     	bl	0x14cb4 <log_print>     @ imm = #-0x570
   15220: e59f303c     	ldr	r3, [pc, #0x3c]         @ 0x15264 <log_assert+0x70>
   15224: e5933000     	ldr	r3, [r3]
   15228: e1a02003     	mov	r2, r3
   1522c: e59f302c     	ldr	r3, [pc, #0x2c]         @ 0x15260 <log_assert+0x6c>
   15230: e51b1010     	ldr	r1, [r11, #-0x10]
   15234: e58d1000     	str	r1, [sp]
   15238: e1a00002     	mov	r0, r2
   1523c: e1a01003     	mov	r1, r3
   15240: e51b2008     	ldr	r2, [r11, #-0x8]
   15244: e51b300c     	ldr	r3, [r11, #-0xc]
   15248: ebffdcfd     	bl	0xc644 <fprintf@plt>    @ imm = #-0x8c0c
   1524c: e59f3010     	ldr	r3, [pc, #0x10]         @ 0x15264 <log_assert+0x70>
   15250: e5933000     	ldr	r3, [r3]
   15254: e1a00003     	mov	r0, r3
   15258: ebffdc8d     	bl	0xc494 <fflush@plt>     @ imm = #-0x8dcc
   1525c: ebffdbf9     	bl	0xc248 <abort@plt>      @ imm = #-0x901c
   15260: 14 2a 03 00  	.word	0x00032a14
   15264: f8 6d 05 00  	.word	0x00056df8

