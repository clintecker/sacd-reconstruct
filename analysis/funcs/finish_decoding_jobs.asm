0001a9f4 <finish_decoding_jobs>:
   1a9f4: e92d4800     	push	{r11, lr}
   1a9f8: e28db004     	add	r11, sp, #4
   1a9fc: e24dd028     	sub	sp, sp, #40
   1aa00: e50b0028     	str	r0, [r11, #-0x28]
   1aa04: e51b3028     	ldr	r3, [r11, #-0x28]
   1aa08: e5933034     	ldr	r3, [r3, #0x34]
   1aa0c: e3530000     	cmp	r3, #0
   1aa10: 0a000056     	beq	0x1ab70 <finish_decoding_jobs+0x17c> @ imm = #0x158
   1aa14: e51b3028     	ldr	r3, [r11, #-0x28]
   1aa18: e5933034     	ldr	r3, [r3, #0x34]
   1aa1c: e1a00003     	mov	r0, r3
   1aa20: ebffeb62     	bl	0x157b0 <possess>       @ imm = #-0x5278
   1aa24: e3a03000     	mov	r3, #0
   1aa28: e50b301c     	str	r3, [r11, #-0x1c]
   1aa2c: e3e03000     	mvn	r3, #0
   1aa30: e50b3020     	str	r3, [r11, #-0x20]
   1aa34: e3a03000     	mov	r3, #0
   1aa38: e50b300c     	str	r3, [r11, #-0xc]
   1aa3c: e51b3028     	ldr	r3, [r11, #-0x28]
   1aa40: e24b2020     	sub	r2, r11, #32
   1aa44: e5832038     	str	r2, [r3, #0x38]
   1aa48: e51b3028     	ldr	r3, [r11, #-0x28]
   1aa4c: e24b2020     	sub	r2, r11, #32
   1aa50: e2822014     	add	r2, r2, #20
   1aa54: e583203c     	str	r2, [r3, #0x3c]
   1aa58: e51b3028     	ldr	r3, [r11, #-0x28]
   1aa5c: e5933034     	ldr	r3, [r3, #0x34]
   1aa60: e1a00003     	mov	r0, r3
   1aa64: e3a01001     	mov	r1, #1
   1aa68: e3a02001     	mov	r2, #1
   1aa6c: ebffeb6f     	bl	0x15830 <twist>         @ imm = #-0x5244
   1aa70: ebffed26     	bl	0x15f10 <join_all>      @ imm = #-0x4b68
   1aa74: e1a03000     	mov	r3, r0
   1aa78: e50b3008     	str	r3, [r11, #-0x8]
   1aa7c: e59f30f8     	ldr	r3, [pc, #0xf8]         @ 0x1ab7c <finish_decoding_jobs+0x188>
   1aa80: e5933000     	ldr	r3, [r3]
   1aa84: e5933004     	ldr	r3, [r3, #0x4]
   1aa88: e3530003     	cmp	r3, #3
   1aa8c: 9a000002     	bls	0x1aa9c <finish_decoding_jobs+0xa8> @ imm = #0x8
   1aa90: e59f00e8     	ldr	r0, [pc, #0xe8]         @ 0x1ab80 <finish_decoding_jobs+0x18c>
   1aa94: e51b1008     	ldr	r1, [r11, #-0x8]
   1aa98: ebffe885     	bl	0x14cb4 <log_print>     @ imm = #-0x5dec
   1aa9c: e51b3028     	ldr	r3, [r11, #-0x28]
   1aaa0: e5932048     	ldr	r2, [r3, #0x48]
   1aaa4: e51b3008     	ldr	r3, [r11, #-0x8]
   1aaa8: e1520003     	cmp	r2, r3
   1aaac: 0a000004     	beq	0x1aac4 <finish_decoding_jobs+0xd0> @ imm = #0x10
   1aab0: e59f00cc     	ldr	r0, [pc, #0xcc]         @ 0x1ab84 <finish_decoding_jobs+0x190>
   1aab4: e59f10cc     	ldr	r1, [pc, #0xcc]         @ 0x1ab88 <finish_decoding_jobs+0x194>
   1aab8: e3a020ad     	mov	r2, #173
   1aabc: e59f30c8     	ldr	r3, [pc, #0xc8]         @ 0x1ab8c <finish_decoding_jobs+0x198>
   1aac0: ebffc646     	bl	0xc3e0 <__assert_fail@plt> @ imm = #-0xe6e8
   1aac4: e51b3028     	ldr	r3, [r11, #-0x28]
   1aac8: e3a02000     	mov	r2, #0
   1aacc: e5832048     	str	r2, [r3, #0x48]
   1aad0: e51b3028     	ldr	r3, [r11, #-0x28]
   1aad4: e2833020     	add	r3, r3, #32
   1aad8: e1a00003     	mov	r0, r3
   1aadc: ebffee3c     	bl	0x163d4 <buffer_pool_free> @ imm = #-0x4710
   1aae0: e1a03000     	mov	r3, r0
   1aae4: e50b3008     	str	r3, [r11, #-0x8]
   1aae8: e59f308c     	ldr	r3, [pc, #0x8c]         @ 0x1ab7c <finish_decoding_jobs+0x188>
   1aaec: e5933000     	ldr	r3, [r3]
   1aaf0: e5933004     	ldr	r3, [r3, #0x4]
   1aaf4: e3530003     	cmp	r3, #3
   1aaf8: 9a000002     	bls	0x1ab08 <finish_decoding_jobs+0x114> @ imm = #0x8
   1aafc: e59f008c     	ldr	r0, [pc, #0x8c]         @ 0x1ab90 <finish_decoding_jobs+0x19c>
   1ab00: e51b1008     	ldr	r1, [r11, #-0x8]
   1ab04: ebffe86a     	bl	0x14cb4 <log_print>     @ imm = #-0x5e58
   1ab08: e51b3028     	ldr	r3, [r11, #-0x28]
   1ab0c: e283300c     	add	r3, r3, #12
   1ab10: e1a00003     	mov	r0, r3
   1ab14: ebffee2e     	bl	0x163d4 <buffer_pool_free> @ imm = #-0x4748
   1ab18: e1a03000     	mov	r3, r0
   1ab1c: e50b3008     	str	r3, [r11, #-0x8]
   1ab20: e59f3054     	ldr	r3, [pc, #0x54]         @ 0x1ab7c <finish_decoding_jobs+0x188>
   1ab24: e5933000     	ldr	r3, [r3]
   1ab28: e5933004     	ldr	r3, [r3, #0x4]
   1ab2c: e3530003     	cmp	r3, #3
   1ab30: 9a000002     	bls	0x1ab40 <finish_decoding_jobs+0x14c> @ imm = #0x8
   1ab34: e59f0058     	ldr	r0, [pc, #0x58]         @ 0x1ab94 <finish_decoding_jobs+0x1a0>
   1ab38: e51b1008     	ldr	r1, [r11, #-0x8]
   1ab3c: ebffe85c     	bl	0x14cb4 <log_print>     @ imm = #-0x5e90
   1ab40: e51b3028     	ldr	r3, [r11, #-0x28]
   1ab44: e5933040     	ldr	r3, [r3, #0x40]
   1ab48: e1a00003     	mov	r0, r3
   1ab4c: ebffebc7     	bl	0x15a70 <free_lock>     @ imm = #-0x50e4
   1ab50: e51b3028     	ldr	r3, [r11, #-0x28]
   1ab54: e5933034     	ldr	r3, [r3, #0x34]
   1ab58: e1a00003     	mov	r0, r3
   1ab5c: ebffebc3     	bl	0x15a70 <free_lock>     @ imm = #-0x50f4
   1ab60: e51b3028     	ldr	r3, [r11, #-0x28]
   1ab64: e3a02000     	mov	r2, #0
   1ab68: e5832034     	str	r2, [r3, #0x34]
   1ab6c: ea000000     	b	0x1ab74 <finish_decoding_jobs+0x180> @ imm = #0x0
   1ab70: e1a00000     	mov	r0, r0
   1ab74: e24bd004     	sub	sp, r11, #4
   1ab78: e8bd8800     	pop	{r11, pc}
   1ab7c: 5c 73 05 00  	.word	0x0005735c
   1ab80: ac 2e 03 00  	.word	0x00032eac
   1ab84: c8 2e 03 00  	.word	0x00032ec8
   1ab88: e8 2e 03 00  	.word	0x00032ee8
   1ab8c: 90 30 03 00  	.word	0x00033090
   1ab90: 18 2f 03 00  	.word	0x00032f18
   1ab94: 34 2f 03 00  	.word	0x00032f34

