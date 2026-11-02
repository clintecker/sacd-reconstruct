0002f5d8 <dsf_close>:
   2f5d8: e92d4800     	push	{r11, lr}
   2f5dc: e28db004     	add	r11, sp, #4
   2f5e0: e24dd010     	sub	sp, sp, #16
   2f5e4: e50b0010     	str	r0, [r11, #-0x10]
   2f5e8: e51b3010     	ldr	r3, [r11, #-0x10]
   2f5ec: e593305c     	ldr	r3, [r3, #0x5c]
   2f5f0: e50b3008     	str	r3, [r11, #-0x8]
   2f5f4: e51b3008     	ldr	r3, [r11, #-0x8]
   2f5f8: e5931008     	ldr	r1, [r3, #0x8]
   2f5fc: e51b3008     	ldr	r3, [r11, #-0x8]
   2f600: e593200c     	ldr	r2, [r3, #0xc]
   2f604: e51b3010     	ldr	r3, [r11, #-0x10]
   2f608: e593301c     	ldr	r3, [r3, #0x1c]
   2f60c: e1a00001     	mov	r0, r1
   2f610: e3a01001     	mov	r1, #1
   2f614: ebff73f5     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0x2302c
   2f618: e51b3010     	ldr	r3, [r11, #-0x10]
   2f61c: e593301c     	ldr	r3, [r3, #0x1c]
   2f620: e1a00003     	mov	r0, r3
   2f624: e3a01000     	mov	r1, #0
   2f628: e3a02000     	mov	r2, #0
   2f62c: ebff738c     	bl	0xc464 <fseek@plt>      @ imm = #-0x231d0
   2f630: e51b0010     	ldr	r0, [r11, #-0x10]
   2f634: ebfffdc5     	bl	0x2ed50 <dsf_create_header> @ imm = #-0x8ec
   2f638: e51b3008     	ldr	r3, [r11, #-0x8]
   2f63c: e5933000     	ldr	r3, [r3]
   2f640: e3530000     	cmp	r3, #0
   2f644: 0a000003     	beq	0x2f658 <dsf_close+0x80> @ imm = #0xc
   2f648: e51b3008     	ldr	r3, [r11, #-0x8]
   2f64c: e5933000     	ldr	r3, [r3]
   2f650: e1a00003     	mov	r0, r3
   2f654: ebff7370     	bl	0xc41c <free@plt>       @ imm = #-0x23240
   2f658: e51b3008     	ldr	r3, [r11, #-0x8]
   2f65c: e5933008     	ldr	r3, [r3, #0x8]
   2f660: e3530000     	cmp	r3, #0
   2f664: 0a000003     	beq	0x2f678 <dsf_close+0xa0> @ imm = #0xc
   2f668: e51b3008     	ldr	r3, [r11, #-0x8]
   2f66c: e5933008     	ldr	r3, [r3, #0x8]
   2f670: e1a00003     	mov	r0, r3
   2f674: ebff7368     	bl	0xc41c <free@plt>       @ imm = #-0x23260
   2f678: e3a03000     	mov	r3, #0
   2f67c: e1a00003     	mov	r0, r3
   2f680: e24bd004     	sub	sp, r11, #4
   2f684: e8bd8800     	pop	{r11, pc}

