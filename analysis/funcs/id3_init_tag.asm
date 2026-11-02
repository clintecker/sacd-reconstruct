0001eedc <id3_init_tag>:
   1eedc: e92d4800     	push	{r11, lr}
   1eee0: e28db004     	add	r11, sp, #4
   1eee4: e24dd008     	sub	sp, sp, #8
   1eee8: e50b0008     	str	r0, [r11, #-0x8]
   1eeec: e51b3008     	ldr	r3, [r11, #-0x8]
   1eef0: e3a02003     	mov	r2, #3
   1eef4: e5832014     	str	r2, [r3, #0x14]
   1eef8: e51b3008     	ldr	r3, [r11, #-0x8]
   1eefc: e3a02000     	mov	r2, #0
   1ef00: e5832018     	str	r2, [r3, #0x18]
   1ef04: e51b3008     	ldr	r3, [r11, #-0x8]
   1ef08: e3a02000     	mov	r2, #0
   1ef0c: e5832008     	str	r2, [r3, #0x8]
   1ef10: e51b3008     	ldr	r3, [r11, #-0x8]
   1ef14: e3a02000     	mov	r2, #0
   1ef18: e583201c     	str	r2, [r3, #0x1c]
   1ef1c: e51b3008     	ldr	r3, [r11, #-0x8]
   1ef20: e3a02001     	mov	r2, #1
   1ef24: e583200c     	str	r2, [r3, #0xc]
   1ef28: e51b3008     	ldr	r3, [r11, #-0x8]
   1ef2c: e3a02001     	mov	r2, #1
   1ef30: e5832010     	str	r2, [r3, #0x10]
   1ef34: e51b3008     	ldr	r3, [r11, #-0x8]
   1ef38: e3a02000     	mov	r2, #0
   1ef3c: e5832020     	str	r2, [r3, #0x20]
   1ef40: e51b3008     	ldr	r3, [r11, #-0x8]
   1ef44: e2833f4e     	add	r3, r3, #312
   1ef48: e1a00003     	mov	r0, r3
   1ef4c: ebffffd5     	bl	0x1eea8 <INIT_LIST_HEAD> @ imm = #-0xac
   1ef50: e24bd004     	sub	sp, r11, #4
   1ef54: e8bd8800     	pop	{r11, pc}

