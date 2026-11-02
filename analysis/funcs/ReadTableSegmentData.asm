00017a40 <ReadTableSegmentData>:
   17a40: e92d4800     	push	{r11, lr}
   17a44: e28db004     	add	r11, sp, #4
   17a48: e24dd030     	sub	sp, sp, #48
   17a4c: e50b0028     	str	r0, [r11, #-0x28]
   17a50: e50b102c     	str	r1, [r11, #-0x2c]
   17a54: e50b2030     	str	r2, [r11, #-0x30]
   17a58: e50b3034     	str	r3, [r11, #-0x34]
   17a5c: e3a03000     	mov	r3, #0
   17a60: e50b301c     	str	r3, [r11, #-0x1c]
   17a64: e3a03000     	mov	r3, #0
   17a68: e50b3018     	str	r3, [r11, #-0x18]
   17a6c: e3a03000     	mov	r3, #0
   17a70: e50b3014     	str	r3, [r11, #-0x14]
   17a74: e3a03000     	mov	r3, #0
   17a78: e50b3010     	str	r3, [r11, #-0x10]
   17a7c: e59b3004     	ldr	r3, [r11, #0x4]
   17a80: e2832007     	add	r2, r3, #7
   17a84: e3530000     	cmp	r3, #0
   17a88: b1a03002     	movlt	r3, r2
   17a8c: e1a031c3     	asr	r3, r3, #3
   17a90: e51b2030     	ldr	r2, [r11, #-0x30]
   17a94: e0633002     	rsb	r3, r3, r2
   17a98: e50b300c     	str	r3, [r11, #-0xc]
   17a9c: e51b0028     	ldr	r0, [r11, #-0x28]
   17aa0: e3a01001     	mov	r1, #1
   17aa4: e59b200c     	ldr	r2, [r11, #0xc]
   17aa8: eb000f60     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x3d80
   17aac: e1a03000     	mov	r3, r0
   17ab0: e3530000     	cmp	r3, #0
   17ab4: 0a000001     	beq	0x17ac0 <ReadTableSegmentData+0x80> @ imm = #0x4
   17ab8: e3a03001     	mov	r3, #1
   17abc: ea0001ba     	b	0x181ac <ReadTableSegmentData+0x76c> @ imm = #0x6e8
   17ac0: e59b300c     	ldr	r3, [r11, #0xc]
   17ac4: e5933000     	ldr	r3, [r3]
   17ac8: e3530001     	cmp	r3, #1
   17acc: 1a0001ab     	bne	0x18180 <ReadTableSegmentData+0x740> @ imm = #0x6ac
   17ad0: e24b3020     	sub	r3, r11, #32
   17ad4: e51b0028     	ldr	r0, [r11, #-0x28]
   17ad8: e3a01001     	mov	r1, #1
   17adc: e1a02003     	mov	r2, r3
   17ae0: eb000f52     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x3d48
   17ae4: e1a03000     	mov	r3, r0
   17ae8: e3530000     	cmp	r3, #0
   17aec: 0a000096     	beq	0x17d4c <ReadTableSegmentData+0x30c> @ imm = #0x258
   17af0: e3a03001     	mov	r3, #1
   17af4: ea0001ac     	b	0x181ac <ReadTableSegmentData+0x76c> @ imm = #0x6b0
   17af8: e51b2010     	ldr	r2, [r11, #-0x10]
   17afc: e51b3034     	ldr	r3, [r11, #-0x34]
   17b00: e1520003     	cmp	r2, r3
   17b04: ba000001     	blt	0x17b10 <ReadTableSegmentData+0xd0> @ imm = #0x4
   17b08: e3a03002     	mov	r3, #2
   17b0c: ea0001a6     	b	0x181ac <ReadTableSegmentData+0x76c> @ imm = #0x698
   17b10: e51b3014     	ldr	r3, [r11, #-0x14]
   17b14: e3530000     	cmp	r3, #0
   17b18: 1a000027     	bne	0x17bbc <ReadTableSegmentData+0x17c> @ imm = #0x9c
   17b1c: e59b3004     	ldr	r3, [r11, #0x4]
   17b20: e2832007     	add	r2, r3, #7
   17b24: e3530000     	cmp	r3, #0
   17b28: b1a03002     	movlt	r3, r2
   17b2c: e1a031c3     	asr	r3, r3, #3
   17b30: e51b2030     	ldr	r2, [r11, #-0x30]
   17b34: e0633002     	rsb	r3, r3, r2
   17b38: e1a00003     	mov	r0, r3
   17b3c: ebffffaa     	bl	0x179ec <Log2RoundUp>   @ imm = #-0x158
   17b40: e1a03000     	mov	r3, r0
   17b44: e50b3008     	str	r3, [r11, #-0x8]
   17b48: e59b3008     	ldr	r3, [r11, #0x8]
   17b4c: e51b0028     	ldr	r0, [r11, #-0x28]
   17b50: e51b1008     	ldr	r1, [r11, #-0x8]
   17b54: e1a02003     	mov	r2, r3
   17b58: eb000f34     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x3cd0
   17b5c: e1a03000     	mov	r3, r0
   17b60: e3530000     	cmp	r3, #0
   17b64: 0a000001     	beq	0x17b70 <ReadTableSegmentData+0x130> @ imm = #0x4
   17b68: e3a03001     	mov	r3, #1
   17b6c: ea00018e     	b	0x181ac <ReadTableSegmentData+0x76c> @ imm = #0x638
   17b70: e59b3008     	ldr	r3, [r11, #0x8]
   17b74: e5933000     	ldr	r3, [r3]
   17b78: e3530000     	cmp	r3, #0
   17b7c: 0a00000a     	beq	0x17bac <ReadTableSegmentData+0x16c> @ imm = #0x28
   17b80: e59b3008     	ldr	r3, [r11, #0x8]
   17b84: e5932000     	ldr	r2, [r3]
   17b88: e59b3004     	ldr	r3, [r11, #0x4]
   17b8c: e2831007     	add	r1, r3, #7
   17b90: e3530000     	cmp	r3, #0
   17b94: b1a03001     	movlt	r3, r1
   17b98: e1a031c3     	asr	r3, r3, #3
   17b9c: e51b1030     	ldr	r1, [r11, #-0x30]
   17ba0: e0633001     	rsb	r3, r3, r1
   17ba4: e1520003     	cmp	r2, r3
   17ba8: da000001     	ble	0x17bb4 <ReadTableSegmentData+0x174> @ imm = #0x4
   17bac: e3a03003     	mov	r3, #3
   17bb0: ea00017d     	b	0x181ac <ReadTableSegmentData+0x76c> @ imm = #0x5f4
   17bb4: e3a03001     	mov	r3, #1
   17bb8: e50b3014     	str	r3, [r11, #-0x14]
   17bbc: e59b3008     	ldr	r3, [r11, #0x8]
   17bc0: e5933000     	ldr	r3, [r3]
   17bc4: e51b000c     	ldr	r0, [r11, #-0xc]
   17bc8: e1a01003     	mov	r1, r3
   17bcc: eb00607e     	bl	0x2fdcc <__divsi3>      @ imm = #0x181f8
   17bd0: e1a03000     	mov	r3, r0
   17bd4: e1a00003     	mov	r0, r3
   17bd8: ebffff83     	bl	0x179ec <Log2RoundUp>   @ imm = #-0x1f4
   17bdc: e1a03000     	mov	r3, r0
   17be0: e50b3008     	str	r3, [r11, #-0x8]
   17be4: e59b3008     	ldr	r3, [r11, #0x8]
   17be8: e2833004     	add	r3, r3, #4
   17bec: e1a02003     	mov	r2, r3
   17bf0: e51b3010     	ldr	r3, [r11, #-0x10]
   17bf4: e1a03103     	lsl	r3, r3, #2
   17bf8: e0823003     	add	r3, r2, r3
   17bfc: e51b0028     	ldr	r0, [r11, #-0x28]
   17c00: e51b1008     	ldr	r1, [r11, #-0x8]
   17c04: e1a02003     	mov	r2, r3
   17c08: eb000f08     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x3c20
   17c0c: e1a03000     	mov	r3, r0
   17c10: e3530000     	cmp	r3, #0
   17c14: 0a000001     	beq	0x17c20 <ReadTableSegmentData+0x1e0> @ imm = #0x4
   17c18: e3a03001     	mov	r3, #1
   17c1c: ea000162     	b	0x181ac <ReadTableSegmentData+0x76c> @ imm = #0x588
   17c20: e59b3008     	ldr	r3, [r11, #0x8]
   17c24: e5933000     	ldr	r3, [r3]
   17c28: e1a03183     	lsl	r3, r3, #3
   17c2c: e51b1010     	ldr	r1, [r11, #-0x10]
   17c30: e59b0008     	ldr	r0, [r11, #0x8]
   17c34: e3a02004     	mov	r2, #4
   17c38: e1a01101     	lsl	r1, r1, #2
   17c3c: e0801001     	add	r1, r0, r1
   17c40: e0812002     	add	r2, r1, r2
   17c44: e5922000     	ldr	r2, [r2]
   17c48: e0020392     	mul	r2, r2, r3
   17c4c: e59b3004     	ldr	r3, [r11, #0x4]
   17c50: e1520003     	cmp	r2, r3
   17c54: ba000012     	blt	0x17ca4 <ReadTableSegmentData+0x264> @ imm = #0x48
   17c58: e59b3008     	ldr	r3, [r11, #0x8]
   17c5c: e5933000     	ldr	r3, [r3]
   17c60: e1a03183     	lsl	r3, r3, #3
   17c64: e51b1010     	ldr	r1, [r11, #-0x10]
   17c68: e59b0008     	ldr	r0, [r11, #0x8]
   17c6c: e3a02004     	mov	r2, #4
   17c70: e1a01101     	lsl	r1, r1, #2
   17c74: e0801001     	add	r1, r0, r1
   17c78: e0812002     	add	r2, r1, r2
   17c7c: e5922000     	ldr	r2, [r2]
   17c80: e0020392     	mul	r2, r2, r3
   17c84: e51b3030     	ldr	r3, [r11, #-0x30]
   17c88: e1a01183     	lsl	r1, r3, #3
   17c8c: e51b3018     	ldr	r3, [r11, #-0x18]
   17c90: e0631001     	rsb	r1, r3, r1
   17c94: e59b3004     	ldr	r3, [r11, #0x4]
   17c98: e0633001     	rsb	r3, r3, r1
   17c9c: e1520003     	cmp	r2, r3
   17ca0: da000001     	ble	0x17cac <ReadTableSegmentData+0x26c> @ imm = #0x4
   17ca4: e3a03004     	mov	r3, #4
   17ca8: ea00013f     	b	0x181ac <ReadTableSegmentData+0x76c> @ imm = #0x4fc
   17cac: e59b3008     	ldr	r3, [r11, #0x8]
   17cb0: e5933000     	ldr	r3, [r3]
   17cb4: e1a03183     	lsl	r3, r3, #3
   17cb8: e51b1010     	ldr	r1, [r11, #-0x10]
   17cbc: e59b0008     	ldr	r0, [r11, #0x8]
   17cc0: e3a02004     	mov	r2, #4
   17cc4: e1a01101     	lsl	r1, r1, #2
   17cc8: e0801001     	add	r1, r0, r1
   17ccc: e0812002     	add	r2, r1, r2
   17cd0: e5922000     	ldr	r2, [r2]
   17cd4: e0030392     	mul	r3, r2, r3
   17cd8: e51b2018     	ldr	r2, [r11, #-0x18]
   17cdc: e0823003     	add	r3, r2, r3
   17ce0: e50b3018     	str	r3, [r11, #-0x18]
   17ce4: e59b3008     	ldr	r3, [r11, #0x8]
   17ce8: e5933000     	ldr	r3, [r3]
   17cec: e51b1010     	ldr	r1, [r11, #-0x10]
   17cf0: e59b0008     	ldr	r0, [r11, #0x8]
   17cf4: e3a02004     	mov	r2, #4
   17cf8: e1a01101     	lsl	r1, r1, #2
   17cfc: e0801001     	add	r1, r0, r1
   17d00: e0812002     	add	r2, r1, r2
   17d04: e5922000     	ldr	r2, [r2]
   17d08: e0030392     	mul	r3, r2, r3
   17d0c: e51b200c     	ldr	r2, [r11, #-0xc]
   17d10: e0633002     	rsb	r3, r3, r2
   17d14: e50b300c     	str	r3, [r11, #-0xc]
   17d18: e51b3010     	ldr	r3, [r11, #-0x10]
   17d1c: e2833001     	add	r3, r3, #1
   17d20: e50b3010     	str	r3, [r11, #-0x10]
   17d24: e24b3020     	sub	r3, r11, #32
   17d28: e51b0028     	ldr	r0, [r11, #-0x28]
   17d2c: e3a01001     	mov	r1, #1
   17d30: e1a02003     	mov	r2, r3
   17d34: eb000ebd     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x3af4
   17d38: e1a03000     	mov	r3, r0
   17d3c: e3530000     	cmp	r3, #0
   17d40: 0a000002     	beq	0x17d50 <ReadTableSegmentData+0x310> @ imm = #0x8
   17d44: e3a03001     	mov	r3, #1
   17d48: ea000117     	b	0x181ac <ReadTableSegmentData+0x76c> @ imm = #0x45c
   17d4c: e1a00000     	mov	r0, r0
   17d50: e51b3020     	ldr	r3, [r11, #-0x20]
   17d54: e3530000     	cmp	r3, #0
   17d58: 0affff66     	beq	0x17af8 <ReadTableSegmentData+0xb8> @ imm = #-0x268
   17d5c: e51b3010     	ldr	r3, [r11, #-0x10]
   17d60: e2832001     	add	r2, r3, #1
   17d64: e59b3008     	ldr	r3, [r11, #0x8]
   17d68: e58320c4     	str	r2, [r3, #0xc4]
   17d6c: e51b2010     	ldr	r2, [r11, #-0x10]
   17d70: e59b1008     	ldr	r1, [r11, #0x8]
   17d74: e3a03004     	mov	r3, #4
   17d78: e1a02102     	lsl	r2, r2, #2
   17d7c: e0812002     	add	r2, r1, r2
   17d80: e0823003     	add	r3, r2, r3
   17d84: e3a02000     	mov	r2, #0
   17d88: e5832000     	str	r2, [r3]
   17d8c: e3a03001     	mov	r3, #1
   17d90: e50b301c     	str	r3, [r11, #-0x1c]
   17d94: ea000028     	b	0x17e3c <ReadTableSegmentData+0x3fc> @ imm = #0xa0
   17d98: e51b301c     	ldr	r3, [r11, #-0x1c]
   17d9c: e59b2008     	ldr	r2, [r11, #0x8]
   17da0: e59220c4     	ldr	r2, [r2, #0xc4]
   17da4: e59b0008     	ldr	r0, [r11, #0x8]
   17da8: e2831030     	add	r1, r3, #48
   17dac: e3a03004     	mov	r3, #4
   17db0: e1a01101     	lsl	r1, r1, #2
   17db4: e0801001     	add	r1, r0, r1
   17db8: e0813003     	add	r3, r1, r3
   17dbc: e5832000     	str	r2, [r3]
   17dc0: e3a03000     	mov	r3, #0
   17dc4: e50b3010     	str	r3, [r11, #-0x10]
   17dc8: ea000013     	b	0x17e1c <ReadTableSegmentData+0x3dc> @ imm = #0x4c
   17dcc: e51b101c     	ldr	r1, [r11, #-0x1c]
   17dd0: e51b3010     	ldr	r3, [r11, #-0x10]
   17dd4: e51b0010     	ldr	r0, [r11, #-0x10]
   17dd8: e59bc008     	ldr	r12, [r11, #0x8]
   17ddc: e3a02004     	mov	r2, #4
   17de0: e1a00100     	lsl	r0, r0, #2
   17de4: e08c0000     	add	r0, r12, r0
   17de8: e0802002     	add	r2, r0, r2
   17dec: e5922000     	ldr	r2, [r2]
   17df0: e59b0008     	ldr	r0, [r11, #0x8]
   17df4: e1a01181     	lsl	r1, r1, #3
   17df8: e0811003     	add	r1, r1, r3
   17dfc: e3a03004     	mov	r3, #4
   17e00: e1a01101     	lsl	r1, r1, #2
   17e04: e0801001     	add	r1, r0, r1
   17e08: e0813003     	add	r3, r1, r3
   17e0c: e5832000     	str	r2, [r3]
   17e10: e51b3010     	ldr	r3, [r11, #-0x10]
   17e14: e2833001     	add	r3, r3, #1
   17e18: e50b3010     	str	r3, [r11, #-0x10]
   17e1c: e59b3008     	ldr	r3, [r11, #0x8]
   17e20: e59320c4     	ldr	r2, [r3, #0xc4]
   17e24: e51b3010     	ldr	r3, [r11, #-0x10]
   17e28: e1520003     	cmp	r2, r3
   17e2c: caffffe6     	bgt	0x17dcc <ReadTableSegmentData+0x38c> @ imm = #-0x68
   17e30: e51b301c     	ldr	r3, [r11, #-0x1c]
   17e34: e2833001     	add	r3, r3, #1
   17e38: e50b301c     	str	r3, [r11, #-0x1c]
   17e3c: e51b201c     	ldr	r2, [r11, #-0x1c]
   17e40: e51b302c     	ldr	r3, [r11, #-0x2c]
   17e44: e1520003     	cmp	r2, r3
   17e48: baffffd2     	blt	0x17d98 <ReadTableSegmentData+0x358> @ imm = #-0xb8
   17e4c: ea0000cf     	b	0x18190 <ReadTableSegmentData+0x750> @ imm = #0x33c
   17e50: e51b2010     	ldr	r2, [r11, #-0x10]
   17e54: e51b3034     	ldr	r3, [r11, #-0x34]
   17e58: e1520003     	cmp	r2, r3
   17e5c: ba000001     	blt	0x17e68 <ReadTableSegmentData+0x428> @ imm = #0x4
   17e60: e3a03002     	mov	r3, #2
   17e64: ea0000d0     	b	0x181ac <ReadTableSegmentData+0x76c> @ imm = #0x340
   17e68: e24b3020     	sub	r3, r11, #32
   17e6c: e51b0028     	ldr	r0, [r11, #-0x28]
   17e70: e3a01001     	mov	r1, #1
   17e74: e1a02003     	mov	r2, r3
   17e78: eb000e6c     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x39b0
   17e7c: e1a03000     	mov	r3, r0
   17e80: e3530000     	cmp	r3, #0
   17e84: 0a000001     	beq	0x17e90 <ReadTableSegmentData+0x450> @ imm = #0x4
   17e88: e3a03001     	mov	r3, #1
   17e8c: ea0000c6     	b	0x181ac <ReadTableSegmentData+0x76c> @ imm = #0x318
   17e90: e51b3020     	ldr	r3, [r11, #-0x20]
   17e94: e3530000     	cmp	r3, #0
   17e98: 1a000094     	bne	0x180f0 <ReadTableSegmentData+0x6b0> @ imm = #0x250
   17e9c: e51b3014     	ldr	r3, [r11, #-0x14]
   17ea0: e3530000     	cmp	r3, #0
   17ea4: 1a000027     	bne	0x17f48 <ReadTableSegmentData+0x508> @ imm = #0x9c
   17ea8: e59b3004     	ldr	r3, [r11, #0x4]
   17eac: e2832007     	add	r2, r3, #7
   17eb0: e3530000     	cmp	r3, #0
   17eb4: b1a03002     	movlt	r3, r2
   17eb8: e1a031c3     	asr	r3, r3, #3
   17ebc: e51b2030     	ldr	r2, [r11, #-0x30]
   17ec0: e0633002     	rsb	r3, r3, r2
   17ec4: e1a00003     	mov	r0, r3
   17ec8: ebfffec7     	bl	0x179ec <Log2RoundUp>   @ imm = #-0x4e4
   17ecc: e1a03000     	mov	r3, r0
   17ed0: e50b3008     	str	r3, [r11, #-0x8]
   17ed4: e59b3008     	ldr	r3, [r11, #0x8]
   17ed8: e51b0028     	ldr	r0, [r11, #-0x28]
   17edc: e51b1008     	ldr	r1, [r11, #-0x8]
   17ee0: e1a02003     	mov	r2, r3
   17ee4: eb000e51     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x3944
   17ee8: e1a03000     	mov	r3, r0
   17eec: e3530000     	cmp	r3, #0
   17ef0: 0a000001     	beq	0x17efc <ReadTableSegmentData+0x4bc> @ imm = #0x4
   17ef4: e3a03001     	mov	r3, #1
   17ef8: ea0000ab     	b	0x181ac <ReadTableSegmentData+0x76c> @ imm = #0x2ac
   17efc: e59b3008     	ldr	r3, [r11, #0x8]
   17f00: e5933000     	ldr	r3, [r3]
   17f04: e3530000     	cmp	r3, #0
   17f08: 0a00000a     	beq	0x17f38 <ReadTableSegmentData+0x4f8> @ imm = #0x28
   17f0c: e59b3008     	ldr	r3, [r11, #0x8]
   17f10: e5932000     	ldr	r2, [r3]
   17f14: e59b3004     	ldr	r3, [r11, #0x4]
   17f18: e2831007     	add	r1, r3, #7
   17f1c: e3530000     	cmp	r3, #0
   17f20: b1a03001     	movlt	r3, r1
   17f24: e1a031c3     	asr	r3, r3, #3
   17f28: e51b1030     	ldr	r1, [r11, #-0x30]
   17f2c: e0633001     	rsb	r3, r3, r1
   17f30: e1520003     	cmp	r2, r3
   17f34: da000001     	ble	0x17f40 <ReadTableSegmentData+0x500> @ imm = #0x4
   17f38: e3a03003     	mov	r3, #3
   17f3c: ea00009a     	b	0x181ac <ReadTableSegmentData+0x76c> @ imm = #0x268
   17f40: e3a03001     	mov	r3, #1
   17f44: e50b3014     	str	r3, [r11, #-0x14]
   17f48: e59b3008     	ldr	r3, [r11, #0x8]
   17f4c: e5933000     	ldr	r3, [r3]
   17f50: e51b000c     	ldr	r0, [r11, #-0xc]
   17f54: e1a01003     	mov	r1, r3
   17f58: eb005f9b     	bl	0x2fdcc <__divsi3>      @ imm = #0x17e6c
   17f5c: e1a03000     	mov	r3, r0
   17f60: e1a00003     	mov	r0, r3
   17f64: ebfffea0     	bl	0x179ec <Log2RoundUp>   @ imm = #-0x580
   17f68: e1a03000     	mov	r3, r0
   17f6c: e50b3008     	str	r3, [r11, #-0x8]
   17f70: e59b3008     	ldr	r3, [r11, #0x8]
   17f74: e2833004     	add	r3, r3, #4
   17f78: e1a02003     	mov	r2, r3
   17f7c: e51b301c     	ldr	r3, [r11, #-0x1c]
   17f80: e1a01183     	lsl	r1, r3, #3
   17f84: e51b3010     	ldr	r3, [r11, #-0x10]
   17f88: e0813003     	add	r3, r1, r3
   17f8c: e1a03103     	lsl	r3, r3, #2
   17f90: e0823003     	add	r3, r2, r3
   17f94: e51b0028     	ldr	r0, [r11, #-0x28]
   17f98: e51b1008     	ldr	r1, [r11, #-0x8]
   17f9c: e1a02003     	mov	r2, r3
   17fa0: eb000e22     	bl	0x1b830 <FIO_BitGetIntUnsigned> @ imm = #0x3888
   17fa4: e1a03000     	mov	r3, r0
   17fa8: e3530000     	cmp	r3, #0
   17fac: 0a000001     	beq	0x17fb8 <ReadTableSegmentData+0x578> @ imm = #0x4
   17fb0: e3a03001     	mov	r3, #1
   17fb4: ea00007c     	b	0x181ac <ReadTableSegmentData+0x76c> @ imm = #0x1f0
   17fb8: e59b3008     	ldr	r3, [r11, #0x8]
   17fbc: e5933000     	ldr	r3, [r3]
   17fc0: e1a03183     	lsl	r3, r3, #3
   17fc4: e51b101c     	ldr	r1, [r11, #-0x1c]
   17fc8: e51b2010     	ldr	r2, [r11, #-0x10]
   17fcc: e59b0008     	ldr	r0, [r11, #0x8]
   17fd0: e1a01181     	lsl	r1, r1, #3
   17fd4: e0811002     	add	r1, r1, r2
   17fd8: e3a02004     	mov	r2, #4
   17fdc: e1a01101     	lsl	r1, r1, #2
   17fe0: e0801001     	add	r1, r0, r1
   17fe4: e0812002     	add	r2, r1, r2
   17fe8: e5922000     	ldr	r2, [r2]
   17fec: e0020392     	mul	r2, r2, r3
   17ff0: e59b3004     	ldr	r3, [r11, #0x4]
   17ff4: e1520003     	cmp	r2, r3
   17ff8: ba000015     	blt	0x18054 <ReadTableSegmentData+0x614> @ imm = #0x54
   17ffc: e59b3008     	ldr	r3, [r11, #0x8]
   18000: e5933000     	ldr	r3, [r3]
   18004: e1a03183     	lsl	r3, r3, #3
   18008: e51b101c     	ldr	r1, [r11, #-0x1c]
   1800c: e51b2010     	ldr	r2, [r11, #-0x10]
   18010: e59b0008     	ldr	r0, [r11, #0x8]
   18014: e1a01181     	lsl	r1, r1, #3
   18018: e0811002     	add	r1, r1, r2
   1801c: e3a02004     	mov	r2, #4
   18020: e1a01101     	lsl	r1, r1, #2
   18024: e0801001     	add	r1, r0, r1
   18028: e0812002     	add	r2, r1, r2
   1802c: e5922000     	ldr	r2, [r2]
   18030: e0020392     	mul	r2, r2, r3
   18034: e51b3030     	ldr	r3, [r11, #-0x30]
   18038: e1a01183     	lsl	r1, r3, #3
   1803c: e51b3018     	ldr	r3, [r11, #-0x18]
   18040: e0631001     	rsb	r1, r3, r1
   18044: e59b3004     	ldr	r3, [r11, #0x4]
   18048: e0633001     	rsb	r3, r3, r1
   1804c: e1520003     	cmp	r2, r3
   18050: da000001     	ble	0x1805c <ReadTableSegmentData+0x61c> @ imm = #0x4
   18054: e3a03004     	mov	r3, #4
   18058: ea000053     	b	0x181ac <ReadTableSegmentData+0x76c> @ imm = #0x14c
   1805c: e59b3008     	ldr	r3, [r11, #0x8]
   18060: e5933000     	ldr	r3, [r3]
   18064: e1a03183     	lsl	r3, r3, #3
   18068: e51b101c     	ldr	r1, [r11, #-0x1c]
   1806c: e51b2010     	ldr	r2, [r11, #-0x10]
   18070: e59b0008     	ldr	r0, [r11, #0x8]
   18074: e1a01181     	lsl	r1, r1, #3
   18078: e0811002     	add	r1, r1, r2
   1807c: e3a02004     	mov	r2, #4
   18080: e1a01101     	lsl	r1, r1, #2
   18084: e0801001     	add	r1, r0, r1
   18088: e0812002     	add	r2, r1, r2
   1808c: e5922000     	ldr	r2, [r2]
   18090: e0030392     	mul	r3, r2, r3
   18094: e51b2018     	ldr	r2, [r11, #-0x18]
   18098: e0823003     	add	r3, r2, r3
   1809c: e50b3018     	str	r3, [r11, #-0x18]
   180a0: e59b3008     	ldr	r3, [r11, #0x8]
   180a4: e5933000     	ldr	r3, [r3]
   180a8: e51b101c     	ldr	r1, [r11, #-0x1c]
   180ac: e51b2010     	ldr	r2, [r11, #-0x10]
   180b0: e59b0008     	ldr	r0, [r11, #0x8]
   180b4: e1a01181     	lsl	r1, r1, #3
   180b8: e0811002     	add	r1, r1, r2
   180bc: e3a02004     	mov	r2, #4
   180c0: e1a01101     	lsl	r1, r1, #2
   180c4: e0801001     	add	r1, r0, r1
   180c8: e0812002     	add	r2, r1, r2
   180cc: e5922000     	ldr	r2, [r2]
   180d0: e0030392     	mul	r3, r2, r3
   180d4: e51b200c     	ldr	r2, [r11, #-0xc]
   180d8: e0633002     	rsb	r3, r3, r2
   180dc: e50b300c     	str	r3, [r11, #-0xc]
   180e0: e51b3010     	ldr	r3, [r11, #-0x10]
   180e4: e2833001     	add	r3, r3, #1
   180e8: e50b3010     	str	r3, [r11, #-0x10]
   180ec: ea000023     	b	0x18180 <ReadTableSegmentData+0x740> @ imm = #0x8c
   180f0: e51b301c     	ldr	r3, [r11, #-0x1c]
   180f4: e51b2010     	ldr	r2, [r11, #-0x10]
   180f8: e2822001     	add	r2, r2, #1
   180fc: e59b0008     	ldr	r0, [r11, #0x8]
   18100: e2831030     	add	r1, r3, #48
   18104: e3a03004     	mov	r3, #4
   18108: e1a01101     	lsl	r1, r1, #2
   1810c: e0801001     	add	r1, r0, r1
   18110: e0813003     	add	r3, r1, r3
   18114: e5832000     	str	r2, [r3]
   18118: e51b201c     	ldr	r2, [r11, #-0x1c]
   1811c: e51b3010     	ldr	r3, [r11, #-0x10]
   18120: e59b1008     	ldr	r1, [r11, #0x8]
   18124: e1a02182     	lsl	r2, r2, #3
   18128: e0822003     	add	r2, r2, r3
   1812c: e3a03004     	mov	r3, #4
   18130: e1a02102     	lsl	r2, r2, #2
   18134: e0812002     	add	r2, r1, r2
   18138: e0823003     	add	r3, r2, r3
   1813c: e3a02000     	mov	r2, #0
   18140: e5832000     	str	r2, [r3]
   18144: e3a03000     	mov	r3, #0
   18148: e50b3010     	str	r3, [r11, #-0x10]
   1814c: e3a03000     	mov	r3, #0
   18150: e50b3018     	str	r3, [r11, #-0x18]
   18154: e59b3004     	ldr	r3, [r11, #0x4]
   18158: e2832007     	add	r2, r3, #7
   1815c: e3530000     	cmp	r3, #0
   18160: b1a03002     	movlt	r3, r2
   18164: e1a031c3     	asr	r3, r3, #3
   18168: e51b2030     	ldr	r2, [r11, #-0x30]
   1816c: e0633002     	rsb	r3, r3, r2
   18170: e50b300c     	str	r3, [r11, #-0xc]
   18174: e51b301c     	ldr	r3, [r11, #-0x1c]
   18178: e2833001     	add	r3, r3, #1
   1817c: e50b301c     	str	r3, [r11, #-0x1c]
   18180: e51b201c     	ldr	r2, [r11, #-0x1c]
   18184: e51b302c     	ldr	r3, [r11, #-0x2c]
   18188: e1520003     	cmp	r2, r3
   1818c: baffff2f     	blt	0x17e50 <ReadTableSegmentData+0x410> @ imm = #-0x344
   18190: e51b3014     	ldr	r3, [r11, #-0x14]
   18194: e3530000     	cmp	r3, #0
   18198: 1a000002     	bne	0x181a8 <ReadTableSegmentData+0x768> @ imm = #0x8
   1819c: e59b3008     	ldr	r3, [r11, #0x8]
   181a0: e3a02001     	mov	r2, #1
   181a4: e5832000     	str	r2, [r3]
   181a8: e3a03000     	mov	r3, #0
   181ac: e1a00003     	mov	r0, r3
   181b0: e24bd004     	sub	sp, r11, #4
   181b4: e8bd8800     	pop	{r11, pc}

