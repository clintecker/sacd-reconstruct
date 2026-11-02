00027994 <destroy_ripping_queue>:
   27994: e92d4800     	push	{r11, lr}
   27998: e28db004     	add	r11, sp, #4
   2799c: e24dd010     	sub	sp, sp, #16
   279a0: e50b0010     	str	r0, [r11, #-0x10]
   279a4: ea000009     	b	0x279d0 <destroy_ripping_queue+0x3c> @ imm = #0x24
   279a8: e51b3010     	ldr	r3, [r11, #-0x10]
   279ac: e5933000     	ldr	r3, [r3]
   279b0: e50b300c     	str	r3, [r11, #-0xc]
   279b4: e51b300c     	ldr	r3, [r11, #-0xc]
   279b8: e2433e17     	sub	r3, r3, #368
   279bc: e50b3008     	str	r3, [r11, #-0x8]
   279c0: e51b000c     	ldr	r0, [r11, #-0xc]
   279c4: ebffffab     	bl	0x27878 <list_del>      @ imm = #-0x154
   279c8: e51b0008     	ldr	r0, [r11, #-0x8]
   279cc: ebff9292     	bl	0xc41c <free@plt>       @ imm = #-0x1b5b8
   279d0: e51b3010     	ldr	r3, [r11, #-0x10]
   279d4: e1a00003     	mov	r0, r3
   279d8: ebffffbb     	bl	0x278cc <list_empty>    @ imm = #-0x114
   279dc: e1a03000     	mov	r3, r0
   279e0: e3530000     	cmp	r3, #0
   279e4: 0affffef     	beq	0x279a8 <destroy_ripping_queue+0x14> @ imm = #-0x44
   279e8: e24bd004     	sub	sp, r11, #4
   279ec: e8bd8800     	pop	{r11, pc}

