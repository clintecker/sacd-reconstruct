0001ab98 <decode_thread>:
   1ab98: e92d4800     	push	{r11, lr}
   1ab9c: e28db004     	add	r11, sp, #4
   1aba0: e24dda6e     	sub	sp, sp, #450560
   1aba4: e24dde8b     	sub	sp, sp, #2224
   1aba8: e59f3358     	ldr	r3, [pc, #0x358]        @ 0x1af08 <decode_thread+0x370>
   1abac: e24b1004     	sub	r1, r11, #4
   1abb0: e7810003     	str	r0, [r1, r3]
   1abb4: e59f334c     	ldr	r3, [pc, #0x34c]        @ 0x1af08 <decode_thread+0x370>
   1abb8: e24b2004     	sub	r2, r11, #4
   1abbc: e7923003     	ldr	r3, [r2, r3]
   1abc0: e50b3008     	str	r3, [r11, #-0x8]
   1abc4: e51b3008     	ldr	r3, [r11, #-0x8]
   1abc8: e5932004     	ldr	r2, [r3, #0x4]
   1abcc: e59f3338     	ldr	r3, [pc, #0x338]        @ 0x1af0c <decode_thread+0x374>
   1abd0: e24b3a6e     	sub	r3, r11, #450560
   1abd4: e2433e8a     	sub	r3, r3, #2208
   1abd8: e1a00003     	mov	r0, r3
   1abdc: e1a01002     	mov	r1, r2
   1abe0: e3a02040     	mov	r2, #64
   1abe4: ebfffecc     	bl	0x1a71c <DST_InitDecoder> @ imm = #-0x4d0
   1abe8: e1a03000     	mov	r3, r0
   1abec: e3530000     	cmp	r3, #0
   1abf0: 0a000001     	beq	0x1abfc <decode_thread+0x64> @ imm = #0x4
   1abf4: e3a00000     	mov	r0, #0
   1abf8: ebffc5a4     	bl	0xc290 <pthread_exit@plt> @ imm = #-0xe970
   1abfc: e51b3008     	ldr	r3, [r11, #-0x8]
   1ac00: e5933034     	ldr	r3, [r3, #0x34]
   1ac04: e1a00003     	mov	r0, r3
   1ac08: ebffeae8     	bl	0x157b0 <possess>       @ imm = #-0x5460
   1ac0c: e51b3008     	ldr	r3, [r11, #-0x8]
   1ac10: e5933034     	ldr	r3, [r3, #0x34]
   1ac14: e1a00003     	mov	r0, r3
   1ac18: e3a01001     	mov	r1, #1
   1ac1c: e3a02000     	mov	r2, #0
   1ac20: ebffeb2d     	bl	0x158dc <wait_for>      @ imm = #-0x534c
   1ac24: e51b3008     	ldr	r3, [r11, #-0x8]
   1ac28: e5933038     	ldr	r3, [r3, #0x38]
   1ac2c: e50b3014     	str	r3, [r11, #-0x14]
   1ac30: e51b3014     	ldr	r3, [r11, #-0x14]
   1ac34: e3530000     	cmp	r3, #0
   1ac38: 1a000004     	bne	0x1ac50 <decode_thread+0xb8> @ imm = #0x10
   1ac3c: e59f02cc     	ldr	r0, [pc, #0x2cc]        @ 0x1af10 <decode_thread+0x378>
   1ac40: e59f12cc     	ldr	r1, [pc, #0x2cc]        @ 0x1af14 <decode_thread+0x37c>
   1ac44: e3a020d2     	mov	r2, #210
   1ac48: e59f32c8     	ldr	r3, [pc, #0x2c8]        @ 0x1af18 <decode_thread+0x380>
   1ac4c: ebffc5e3     	bl	0xc3e0 <__assert_fail@plt> @ imm = #-0xe874
   1ac50: e51b3014     	ldr	r3, [r11, #-0x14]
   1ac54: e5933000     	ldr	r3, [r3]
   1ac58: e3730001     	cmn	r3, #1
   1ac5c: 1a00000c     	bne	0x1ac94 <decode_thread+0xfc> @ imm = #0x30
   1ac60: e51b3008     	ldr	r3, [r11, #-0x8]
   1ac64: e5933034     	ldr	r3, [r3, #0x34]
   1ac68: e1a00003     	mov	r0, r3
   1ac6c: ebffeadf     	bl	0x157f0 <release>       @ imm = #-0x5484
   1ac70: e59f3294     	ldr	r3, [pc, #0x294]        @ 0x1af0c <decode_thread+0x374>
   1ac74: e24b3a6e     	sub	r3, r11, #450560
   1ac78: e2433e8a     	sub	r3, r3, #2208
   1ac7c: e1a00003     	mov	r0, r3
   1ac80: ebffff19     	bl	0x1a8ec <DST_CloseDecoder> @ imm = #-0x39c
   1ac84: e1a03000     	mov	r3, r0
   1ac88: e3530000     	cmp	r3, #0
   1ac8c: 1a000099     	bne	0x1aef8 <decode_thread+0x360> @ imm = #0x264
   1ac90: ea00009a     	b	0x1af00 <decode_thread+0x368> @ imm = #0x268
   1ac94: e51b3014     	ldr	r3, [r11, #-0x14]
   1ac98: e5932014     	ldr	r2, [r3, #0x14]
   1ac9c: e51b3008     	ldr	r3, [r11, #-0x8]
   1aca0: e5832038     	str	r2, [r3, #0x38]
   1aca4: e51b3014     	ldr	r3, [r11, #-0x14]
   1aca8: e5933014     	ldr	r3, [r3, #0x14]
   1acac: e3530000     	cmp	r3, #0
   1acb0: 1a000003     	bne	0x1acc4 <decode_thread+0x12c> @ imm = #0xc
   1acb4: e51b3008     	ldr	r3, [r11, #-0x8]
   1acb8: e2832038     	add	r2, r3, #56
   1acbc: e51b3008     	ldr	r3, [r11, #-0x8]
   1acc0: e583203c     	str	r2, [r3, #0x3c]
   1acc4: e51b3008     	ldr	r3, [r11, #-0x8]
   1acc8: e5933034     	ldr	r3, [r3, #0x34]
   1accc: e1a00003     	mov	r0, r3
   1acd0: e3a01001     	mov	r1, #1
   1acd4: e3e02000     	mvn	r2, #0
   1acd8: ebffead4     	bl	0x15830 <twist>         @ imm = #-0x54b0
   1acdc: e59f3238     	ldr	r3, [pc, #0x238]        @ 0x1af1c <decode_thread+0x384>
   1ace0: e5933000     	ldr	r3, [r3]
   1ace4: e5933004     	ldr	r3, [r3, #0x4]
   1ace8: e3530003     	cmp	r3, #3
   1acec: 9a000004     	bls	0x1ad04 <decode_thread+0x16c> @ imm = #0x10
   1acf0: e51b3014     	ldr	r3, [r11, #-0x14]
   1acf4: e5933000     	ldr	r3, [r3]
   1acf8: e59f0220     	ldr	r0, [pc, #0x220]        @ 0x1af20 <decode_thread+0x388>
   1acfc: e1a01003     	mov	r1, r3
   1ad00: ebffe7eb     	bl	0x14cb4 <log_print>     @ imm = #-0x6054
   1ad04: e51b3014     	ldr	r3, [r11, #-0x14]
   1ad08: e5933008     	ldr	r3, [r3, #0x8]
   1ad0c: e3530000     	cmp	r3, #0
   1ad10: 0a00004f     	beq	0x1ae54 <decode_thread+0x2bc> @ imm = #0x13c
   1ad14: e51b3008     	ldr	r3, [r11, #-0x8]
   1ad18: e2833020     	add	r3, r3, #32
   1ad1c: e1a00003     	mov	r0, r3
   1ad20: ebffecf2     	bl	0x160f0 <buffer_pool_get_space> @ imm = #-0x4c38
   1ad24: e1a02000     	mov	r2, r0
   1ad28: e51b3014     	ldr	r3, [r11, #-0x14]
   1ad2c: e5832010     	str	r2, [r3, #0x10]
   1ad30: e51b3014     	ldr	r3, [r11, #-0x14]
   1ad34: e593300c     	ldr	r3, [r3, #0xc]
   1ad38: e5933004     	ldr	r3, [r3, #0x4]
   1ad3c: e1a00003     	mov	r0, r3
   1ad40: e51b3014     	ldr	r3, [r11, #-0x14]
   1ad44: e5933010     	ldr	r3, [r3, #0x10]
   1ad48: e5933004     	ldr	r3, [r3, #0x4]
   1ad4c: e1a01003     	mov	r1, r3
   1ad50: e51b3014     	ldr	r3, [r11, #-0x14]
   1ad54: e593300c     	ldr	r3, [r3, #0xc]
   1ad58: e5933008     	ldr	r3, [r3, #0x8]
   1ad5c: e1a02003     	mov	r2, r3
   1ad60: e51b3014     	ldr	r3, [r11, #-0x14]
   1ad64: e593c000     	ldr	r12, [r3]
   1ad68: e59f319c     	ldr	r3, [pc, #0x19c]        @ 0x1af0c <decode_thread+0x374>
   1ad6c: e24b3a6e     	sub	r3, r11, #450560
   1ad70: e2433e8a     	sub	r3, r3, #2208
   1ad74: e58d3000     	str	r3, [sp]
   1ad78: e1a0300c     	mov	r3, r12
   1ad7c: ebffefcd     	bl	0x16cb8 <DST_FramDSTDecode> @ imm = #-0x40cc
   1ad80: e1a02000     	mov	r2, r0
   1ad84: e51b3014     	ldr	r3, [r11, #-0x14]
   1ad88: e5832004     	str	r2, [r3, #0x4]
   1ad8c: e51b3014     	ldr	r3, [r11, #-0x14]
   1ad90: e5933004     	ldr	r3, [r3, #0x4]
   1ad94: e3530000     	cmp	r3, #0
   1ad98: 0a000010     	beq	0x1ade0 <decode_thread+0x248> @ imm = #0x40
   1ad9c: e59f3178     	ldr	r3, [pc, #0x178]        @ 0x1af1c <decode_thread+0x384>
   1ada0: e5933000     	ldr	r3, [r3]
   1ada4: e5933004     	ldr	r3, [r3, #0x4]
   1ada8: e3530001     	cmp	r3, #1
   1adac: 9a00000b     	bls	0x1ade0 <decode_thread+0x248> @ imm = #0x2c
   1adb0: e51b3014     	ldr	r3, [r11, #-0x14]
   1adb4: e5933004     	ldr	r3, [r3, #0x4]
   1adb8: e1a00003     	mov	r0, r3
   1adbc: ebfff2a6     	bl	0x1785c <DST_GetErrorMessage> @ imm = #-0x3568
   1adc0: e1a02000     	mov	r2, r0
   1adc4: e59f3140     	ldr	r3, [pc, #0x140]        @ 0x1af0c <decode_thread+0x374>
   1adc8: e24b1004     	sub	r1, r11, #4
   1adcc: e7913003     	ldr	r3, [r1, r3]
   1add0: e59f014c     	ldr	r0, [pc, #0x14c]        @ 0x1af24 <decode_thread+0x38c>
   1add4: e1a01002     	mov	r1, r2
   1add8: e1a02003     	mov	r2, r3
   1addc: ebffe7b4     	bl	0x14cb4 <log_print>     @ imm = #-0x6130
   1ade0: e51b3014     	ldr	r3, [r11, #-0x14]
   1ade4: e5933010     	ldr	r3, [r3, #0x10]
   1ade8: e51b2008     	ldr	r2, [r11, #-0x8]
   1adec: e5922004     	ldr	r2, [r2, #0x4]
   1adf0: e59f1130     	ldr	r1, [pc, #0x130]        @ 0x1af28 <decode_thread+0x390>
   1adf4: e0020291     	mul	r2, r1, r2
   1adf8: e5832008     	str	r2, [r3, #0x8]
   1adfc: e51b3014     	ldr	r3, [r11, #-0x14]
   1ae00: e593300c     	ldr	r3, [r3, #0xc]
   1ae04: e1a00003     	mov	r0, r3
   1ae08: ebffed39     	bl	0x162f4 <buffer_pool_drop_space> @ imm = #-0x4b1c
   1ae0c: e59f3108     	ldr	r3, [pc, #0x108]        @ 0x1af1c <decode_thread+0x384>
   1ae10: e5933000     	ldr	r3, [r3]
   1ae14: e5933004     	ldr	r3, [r3, #0x4]
   1ae18: e3530003     	cmp	r3, #3
   1ae1c: 9a00000c     	bls	0x1ae54 <decode_thread+0x2bc> @ imm = #0x30
   1ae20: e51b3014     	ldr	r3, [r11, #-0x14]
   1ae24: e5932000     	ldr	r2, [r3]
   1ae28: e51b3014     	ldr	r3, [r11, #-0x14]
   1ae2c: e5933008     	ldr	r3, [r3, #0x8]
   1ae30: e3530000     	cmp	r3, #0
   1ae34: 0a000001     	beq	0x1ae40 <decode_thread+0x2a8> @ imm = #0x4
   1ae38: e59f30ec     	ldr	r3, [pc, #0xec]         @ 0x1af2c <decode_thread+0x394>
   1ae3c: ea000000     	b	0x1ae44 <decode_thread+0x2ac> @ imm = #0x0
   1ae40: e59f30e8     	ldr	r3, [pc, #0xe8]         @ 0x1af30 <decode_thread+0x398>
   1ae44: e59f00e8     	ldr	r0, [pc, #0xe8]         @ 0x1af34 <decode_thread+0x39c>
   1ae48: e1a01002     	mov	r1, r2
   1ae4c: e1a02003     	mov	r2, r3
   1ae50: ebffe797     	bl	0x14cb4 <log_print>     @ imm = #-0x61a4
   1ae54: e51b3008     	ldr	r3, [r11, #-0x8]
   1ae58: e5933040     	ldr	r3, [r3, #0x40]
   1ae5c: e1a00003     	mov	r0, r3
   1ae60: ebffea52     	bl	0x157b0 <possess>       @ imm = #-0x56b8
   1ae64: e51b3008     	ldr	r3, [r11, #-0x8]
   1ae68: e2833044     	add	r3, r3, #68
   1ae6c: e50b300c     	str	r3, [r11, #-0xc]
   1ae70: ea000008     	b	0x1ae98 <decode_thread+0x300> @ imm = #0x20
   1ae74: e51b3010     	ldr	r3, [r11, #-0x10]
   1ae78: e5932000     	ldr	r2, [r3]
   1ae7c: e51b3014     	ldr	r3, [r11, #-0x14]
   1ae80: e5933000     	ldr	r3, [r3]
   1ae84: e1520003     	cmp	r2, r3
   1ae88: ca000009     	bgt	0x1aeb4 <decode_thread+0x31c> @ imm = #0x24
   1ae8c: e51b3010     	ldr	r3, [r11, #-0x10]
   1ae90: e2833014     	add	r3, r3, #20
   1ae94: e50b300c     	str	r3, [r11, #-0xc]
   1ae98: e51b300c     	ldr	r3, [r11, #-0xc]
   1ae9c: e5933000     	ldr	r3, [r3]
   1aea0: e50b3010     	str	r3, [r11, #-0x10]
   1aea4: e51b3010     	ldr	r3, [r11, #-0x10]
   1aea8: e3530000     	cmp	r3, #0
   1aeac: 1afffff0     	bne	0x1ae74 <decode_thread+0x2dc> @ imm = #-0x40
   1aeb0: ea000000     	b	0x1aeb8 <decode_thread+0x320> @ imm = #0x0
   1aeb4: e1a00000     	mov	r0, r0
   1aeb8: e51b3014     	ldr	r3, [r11, #-0x14]
   1aebc: e51b2010     	ldr	r2, [r11, #-0x10]
   1aec0: e5832014     	str	r2, [r3, #0x14]
   1aec4: e51b300c     	ldr	r3, [r11, #-0xc]
   1aec8: e51b2014     	ldr	r2, [r11, #-0x14]
   1aecc: e5832000     	str	r2, [r3]
   1aed0: e51b3008     	ldr	r3, [r11, #-0x8]
   1aed4: e5932040     	ldr	r2, [r3, #0x40]
   1aed8: e51b3008     	ldr	r3, [r11, #-0x8]
   1aedc: e5933044     	ldr	r3, [r3, #0x44]
   1aee0: e5933000     	ldr	r3, [r3]
   1aee4: e1a00002     	mov	r0, r2
   1aee8: e3a01000     	mov	r1, #0
   1aeec: e1a02003     	mov	r2, r3
   1aef0: ebffea4e     	bl	0x15830 <twist>         @ imm = #-0x56c8
   1aef4: eaffff40     	b	0x1abfc <decode_thread+0x64> @ imm = #-0x300
   1aef8: e3a00000     	mov	r0, #0
   1aefc: ebffc4e3     	bl	0xc290 <pthread_exit@plt> @ imm = #-0xec74
   1af00: e24bd004     	sub	sp, r11, #4
   1af04: e8bd8800     	pop	{r11, pc}
   1af08: 5c 17 f9 ff  	.word	0xfff9175c
   1af0c: 64 17 f9 ff  	.word	0xfff91764
   1af10: 50 2f 03 00  	.word	0x00032f50
   1af14: e8 2e 03 00  	.word	0x00032ee8
   1af18: 80 30 03 00  	.word	0x00033080
   1af1c: 5c 73 05 00  	.word	0x0005735c
   1af20: 64 2f 03 00  	.word	0x00032f64
   1af24: 78 2f 03 00  	.word	0x00032f78
   1af28: 60 12 00 00  	.word	0x00001260
   1af2c: 90 2f 03 00  	.word	0x00032f90
   1af30: 94 2f 03 00  	.word	0x00032f94
   1af34: 9c 2f 03 00  	.word	0x00032f9c

