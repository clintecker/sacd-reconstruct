000279f0 <scarletbook_output_enqueue_track>:
   279f0: e92d4800     	push	{r11, lr}
   279f4: e28db004     	add	r11, sp, #4
   279f8: e24dd030     	sub	sp, sp, #48
   279fc: e50b0018     	str	r0, [r11, #-0x18]
   27a00: e50b101c     	str	r1, [r11, #-0x1c]
   27a04: e50b2020     	str	r2, [r11, #-0x20]
   27a08: e50b3024     	str	r3, [r11, #-0x24]
   27a0c: e51b3018     	ldr	r3, [r11, #-0x18]
   27a10: e593303c     	ldr	r3, [r3, #0x3c]
   27a14: e50b3008     	str	r3, [r11, #-0x8]
   27a18: e59b0004     	ldr	r0, [r11, #0x4]
   27a1c: ebffffb8     	bl	0x27904 <find_output_format> @ imm = #-0x120
   27a20: e1a03000     	mov	r3, r0
   27a24: e50b3010     	str	r3, [r11, #-0x10]
   27a28: e51b3010     	ldr	r3, [r11, #-0x10]
   27a2c: e3530000     	cmp	r3, #0
   27a30: 0a000129     	beq	0x27edc <scarletbook_output_enqueue_track+0x4ec> @ imm = #0x4a4
   27a34: e3a00f5e     	mov	r0, #376
   27a38: e3a01001     	mov	r1, #1
   27a3c: ebff9246     	bl	0xc35c <calloc@plt>     @ imm = #-0x1b6e8
   27a40: e1a03000     	mov	r3, r0
   27a44: e50b300c     	str	r3, [r11, #-0xc]
   27a48: e51b300c     	ldr	r3, [r11, #-0xc]
   27a4c: e51b2008     	ldr	r2, [r11, #-0x8]
   27a50: e5832168     	str	r2, [r3, #0x168]
   27a54: e51b3018     	ldr	r3, [r11, #-0x18]
   27a58: e5932038     	ldr	r2, [r3, #0x38]
   27a5c: e51b300c     	ldr	r3, [r11, #-0xc]
   27a60: e583216c     	str	r2, [r3, #0x16c]
   27a64: e51b300c     	ldr	r3, [r11, #-0xc]
   27a68: e51b201c     	ldr	r2, [r11, #-0x1c]
   27a6c: e5832000     	str	r2, [r3]
   27a70: e51b300c     	ldr	r3, [r11, #-0xc]
   27a74: e51b2020     	ldr	r2, [r11, #-0x20]
   27a78: e5832004     	str	r2, [r3, #0x4]
   27a7c: e51b200c     	ldr	r2, [r11, #-0xc]
   27a80: e51b3010     	ldr	r3, [r11, #-0x10]
   27a84: e282c040     	add	r12, r2, #64
   27a88: e1a0e003     	mov	lr, r3
   27a8c: e8be000f     	ldm	lr!, {r0, r1, r2, r3}
   27a90: e8ac000f     	stm	r12!, {r0, r1, r2, r3}
   27a94: e89e0007     	ldm	lr, {r0, r1, r2}
   27a98: e88c0007     	stm	r12, {r0, r1, r2}
   27a9c: e51b0024     	ldr	r0, [r11, #-0x24]
   27aa0: ebff92ea     	bl	0xc650 <strdup@plt>     @ imm = #-0x1b458
   27aa4: e1a03000     	mov	r3, r0
   27aa8: e1a02003     	mov	r2, r3
   27aac: e51b300c     	ldr	r3, [r11, #-0xc]
   27ab0: e5832014     	str	r2, [r3, #0x14]
   27ab4: e51b201c     	ldr	r2, [r11, #-0x1c]
   27ab8: e51b1008     	ldr	r1, [r11, #-0x8]
   27abc: e3a03060     	mov	r3, #96
   27ac0: e59f0424     	ldr	r0, [pc, #0x424]        @ 0x27eec <scarletbook_output_enqueue_track+0x4fc>
   27ac4: e0020290     	mul	r2, r0, r2
   27ac8: e0812002     	add	r2, r1, r2
   27acc: e0823003     	add	r3, r2, r3
   27ad0: e5933000     	ldr	r3, [r3]
   27ad4: e5d33020     	ldrb	r3, [r3, #0x20]
   27ad8: e1a02003     	mov	r2, r3
   27adc: e51b300c     	ldr	r3, [r11, #-0xc]
   27ae0: e5832018     	str	r2, [r3, #0x18]
   27ae4: e51b201c     	ldr	r2, [r11, #-0x1c]
   27ae8: e51b1008     	ldr	r1, [r11, #-0x8]
   27aec: e3a03060     	mov	r3, #96
   27af0: e59f03f4     	ldr	r0, [pc, #0x3f4]        @ 0x27eec <scarletbook_output_enqueue_track+0x4fc>
   27af4: e0020290     	mul	r2, r0, r2
   27af8: e0812002     	add	r2, r1, r2
   27afc: e0823003     	add	r3, r2, r3
   27b00: e5933000     	ldr	r3, [r3]
   27b04: e5d33015     	ldrb	r3, [r3, #0x15]
   27b08: e203300f     	and	r3, r3, #15
   27b0c: e3530000     	cmp	r3, #0
   27b10: 13a02000     	movne	r2, #0
   27b14: 03a02001     	moveq	r2, #1
   27b18: e51b300c     	ldr	r3, [r11, #-0xc]
   27b1c: e5832038     	str	r2, [r3, #0x38]
   27b20: e51b300c     	ldr	r3, [r11, #-0xc]
   27b24: e59b2008     	ldr	r2, [r11, #0x8]
   27b28: e583203c     	str	r2, [r3, #0x3c]
   27b2c: e51b3010     	ldr	r3, [r11, #-0x10]
   27b30: e5933014     	ldr	r3, [r3, #0x14]
   27b34: e2033008     	and	r3, r3, #8
   27b38: e3530000     	cmp	r3, #0
   27b3c: 0a00003e     	beq	0x27c3c <scarletbook_output_enqueue_track+0x24c> @ imm = #0xf8
   27b40: e51b201c     	ldr	r2, [r11, #-0x1c]
   27b44: e51b1008     	ldr	r1, [r11, #-0x8]
   27b48: e3a03060     	mov	r3, #96
   27b4c: e59f0398     	ldr	r0, [pc, #0x398]        @ 0x27eec <scarletbook_output_enqueue_track+0x4fc>
   27b50: e0020290     	mul	r2, r0, r2
   27b54: e0812002     	add	r2, r1, r2
   27b58: e0823003     	add	r3, r2, r3
   27b5c: e5933000     	ldr	r3, [r3]
   27b60: e5d32048     	ldrb	r2, [r3, #0x48]
   27b64: e5d31049     	ldrb	r1, [r3, #0x49]
   27b68: e1a01401     	lsl	r1, r1, #8
   27b6c: e1812002     	orr	r2, r1, r2
   27b70: e5d3104a     	ldrb	r1, [r3, #0x4a]
   27b74: e1a01801     	lsl	r1, r1, #16
   27b78: e1812002     	orr	r2, r1, r2
   27b7c: e5d3304b     	ldrb	r3, [r3, #0x4b]
   27b80: e1a03c03     	lsl	r3, r3, #24
   27b84: e1833002     	orr	r3, r3, r2
   27b88: e1a02003     	mov	r2, r3
   27b8c: e51b300c     	ldr	r3, [r11, #-0xc]
   27b90: e5832008     	str	r2, [r3, #0x8]
   27b94: e51b201c     	ldr	r2, [r11, #-0x1c]
   27b98: e51b1008     	ldr	r1, [r11, #-0x8]
   27b9c: e3a03060     	mov	r3, #96
   27ba0: e59f0344     	ldr	r0, [pc, #0x344]        @ 0x27eec <scarletbook_output_enqueue_track+0x4fc>
   27ba4: e0020290     	mul	r2, r0, r2
   27ba8: e0812002     	add	r2, r1, r2
   27bac: e0823003     	add	r3, r2, r3
   27bb0: e5933000     	ldr	r3, [r3]
   27bb4: e5d3204c     	ldrb	r2, [r3, #0x4c]
   27bb8: e5d3104d     	ldrb	r1, [r3, #0x4d]
   27bbc: e1a01401     	lsl	r1, r1, #8
   27bc0: e1812002     	orr	r2, r1, r2
   27bc4: e5d3104e     	ldrb	r1, [r3, #0x4e]
   27bc8: e1a01801     	lsl	r1, r1, #16
   27bcc: e1812002     	orr	r2, r1, r2
   27bd0: e5d3304f     	ldrb	r3, [r3, #0x4f]
   27bd4: e1a03c03     	lsl	r3, r3, #24
   27bd8: e1833002     	orr	r3, r3, r2
   27bdc: e1a02003     	mov	r2, r3
   27be0: e51b101c     	ldr	r1, [r11, #-0x1c]
   27be4: e51b0008     	ldr	r0, [r11, #-0x8]
   27be8: e3a03060     	mov	r3, #96
   27bec: e59fc2f8     	ldr	r12, [pc, #0x2f8]       @ 0x27eec <scarletbook_output_enqueue_track+0x4fc>
   27bf0: e001019c     	mul	r1, r12, r1
   27bf4: e0801001     	add	r1, r0, r1
   27bf8: e0813003     	add	r3, r1, r3
   27bfc: e5933000     	ldr	r3, [r3]
   27c00: e5d31048     	ldrb	r1, [r3, #0x48]
   27c04: e5d30049     	ldrb	r0, [r3, #0x49]
   27c08: e1a00400     	lsl	r0, r0, #8
   27c0c: e1801001     	orr	r1, r0, r1
   27c10: e5d3004a     	ldrb	r0, [r3, #0x4a]
   27c14: e1a00800     	lsl	r0, r0, #16
   27c18: e1801001     	orr	r1, r0, r1
   27c1c: e5d3304b     	ldrb	r3, [r3, #0x4b]
   27c20: e1a03c03     	lsl	r3, r3, #24
   27c24: e1833001     	orr	r3, r3, r1
   27c28: e0633002     	rsb	r3, r3, r2
   27c2c: e2832001     	add	r2, r3, #1
   27c30: e51b300c     	ldr	r3, [r11, #-0xc]
   27c34: e583200c     	str	r2, [r3, #0xc]
   27c38: ea000089     	b	0x27e64 <scarletbook_output_enqueue_track+0x474> @ imm = #0x224
   27c3c: e51b3020     	ldr	r3, [r11, #-0x20]
   27c40: e3530000     	cmp	r3, #0
   27c44: da000023     	ble	0x27cd8 <scarletbook_output_enqueue_track+0x2e8> @ imm = #0x8c
   27c48: e51b201c     	ldr	r2, [r11, #-0x1c]
   27c4c: e51b1008     	ldr	r1, [r11, #-0x8]
   27c50: e3a03064     	mov	r3, #100
   27c54: e59f0290     	ldr	r0, [pc, #0x290]        @ 0x27eec <scarletbook_output_enqueue_track+0x4fc>
   27c58: e0020290     	mul	r2, r0, r2
   27c5c: e0812002     	add	r2, r1, r2
   27c60: e0823003     	add	r3, r2, r3
   27c64: e5933000     	ldr	r3, [r3]
   27c68: e51b2020     	ldr	r2, [r11, #-0x20]
   27c6c: e2822002     	add	r2, r2, #2
   27c70: e7d31102     	ldrb	r1, [r3, r2, lsl #2]
   27c74: e3a00001     	mov	r0, #1
   27c78: e1a0c102     	lsl	r12, r2, #2
   27c7c: e083c00c     	add	r12, r3, r12
   27c80: e08c0000     	add	r0, r12, r0
   27c84: e5d00000     	ldrb	r0, [r0]
   27c88: e1a00400     	lsl	r0, r0, #8
   27c8c: e1801001     	orr	r1, r0, r1
   27c90: e3a00002     	mov	r0, #2
   27c94: e1a0c102     	lsl	r12, r2, #2
   27c98: e083c00c     	add	r12, r3, r12
   27c9c: e08c0000     	add	r0, r12, r0
   27ca0: e5d00000     	ldrb	r0, [r0]
   27ca4: e1a00800     	lsl	r0, r0, #16
   27ca8: e1801001     	orr	r1, r0, r1
   27cac: e3a00003     	mov	r0, #3
   27cb0: e1a02102     	lsl	r2, r2, #2
   27cb4: e0833002     	add	r3, r3, r2
   27cb8: e0833000     	add	r3, r3, r0
   27cbc: e5d33000     	ldrb	r3, [r3]
   27cc0: e1a03c03     	lsl	r3, r3, #24
   27cc4: e1833001     	orr	r3, r3, r1
   27cc8: e1a02003     	mov	r2, r3
   27ccc: e51b300c     	ldr	r3, [r11, #-0xc]
   27cd0: e5832008     	str	r2, [r3, #0x8]
   27cd4: ea000014     	b	0x27d2c <scarletbook_output_enqueue_track+0x33c> @ imm = #0x50
   27cd8: e51b201c     	ldr	r2, [r11, #-0x1c]
   27cdc: e51b1008     	ldr	r1, [r11, #-0x8]
   27ce0: e3a03060     	mov	r3, #96
   27ce4: e59f0200     	ldr	r0, [pc, #0x200]        @ 0x27eec <scarletbook_output_enqueue_track+0x4fc>
   27ce8: e0020290     	mul	r2, r0, r2
   27cec: e0812002     	add	r2, r1, r2
   27cf0: e0823003     	add	r3, r2, r3
   27cf4: e5933000     	ldr	r3, [r3]
   27cf8: e5d32048     	ldrb	r2, [r3, #0x48]
   27cfc: e5d31049     	ldrb	r1, [r3, #0x49]
   27d00: e1a01401     	lsl	r1, r1, #8
   27d04: e1812002     	orr	r2, r1, r2
   27d08: e5d3104a     	ldrb	r1, [r3, #0x4a]
   27d0c: e1a01801     	lsl	r1, r1, #16
   27d10: e1812002     	orr	r2, r1, r2
   27d14: e5d3304b     	ldrb	r3, [r3, #0x4b]
   27d18: e1a03c03     	lsl	r3, r3, #24
   27d1c: e1833002     	orr	r3, r3, r2
   27d20: e1a02003     	mov	r2, r3
   27d24: e51b300c     	ldr	r3, [r11, #-0xc]
   27d28: e5832008     	str	r2, [r3, #0x8]
   27d2c: e51b201c     	ldr	r2, [r11, #-0x1c]
   27d30: e51b1008     	ldr	r1, [r11, #-0x8]
   27d34: e3a03060     	mov	r3, #96
   27d38: e59f01ac     	ldr	r0, [pc, #0x1ac]        @ 0x27eec <scarletbook_output_enqueue_track+0x4fc>
   27d3c: e0020290     	mul	r2, r0, r2
   27d40: e0812002     	add	r2, r1, r2
   27d44: e0823003     	add	r3, r2, r3
   27d48: e5933000     	ldr	r3, [r3]
   27d4c: e5d33045     	ldrb	r3, [r3, #0x45]
   27d50: e2432001     	sub	r2, r3, #1
   27d54: e51b3020     	ldr	r3, [r11, #-0x20]
   27d58: e1520003     	cmp	r2, r3
   27d5c: da000028     	ble	0x27e04 <scarletbook_output_enqueue_track+0x414> @ imm = #0xa0
   27d60: e51b201c     	ldr	r2, [r11, #-0x1c]
   27d64: e51b1008     	ldr	r1, [r11, #-0x8]
   27d68: e3a03064     	mov	r3, #100
   27d6c: e59f0178     	ldr	r0, [pc, #0x178]        @ 0x27eec <scarletbook_output_enqueue_track+0x4fc>
   27d70: e0020290     	mul	r2, r0, r2
   27d74: e0812002     	add	r2, r1, r2
   27d78: e0823003     	add	r3, r2, r3
   27d7c: e5933000     	ldr	r3, [r3]
   27d80: e51b2020     	ldr	r2, [r11, #-0x20]
   27d84: e2822001     	add	r2, r2, #1
   27d88: e2822002     	add	r2, r2, #2
   27d8c: e7d31102     	ldrb	r1, [r3, r2, lsl #2]
   27d90: e3a00001     	mov	r0, #1
   27d94: e1a0c102     	lsl	r12, r2, #2
   27d98: e083c00c     	add	r12, r3, r12
   27d9c: e08c0000     	add	r0, r12, r0
   27da0: e5d00000     	ldrb	r0, [r0]
   27da4: e1a00400     	lsl	r0, r0, #8
   27da8: e1801001     	orr	r1, r0, r1
   27dac: e3a00002     	mov	r0, #2
   27db0: e1a0c102     	lsl	r12, r2, #2
   27db4: e083c00c     	add	r12, r3, r12
   27db8: e08c0000     	add	r0, r12, r0
   27dbc: e5d00000     	ldrb	r0, [r0]
   27dc0: e1a00800     	lsl	r0, r0, #16
   27dc4: e1801001     	orr	r1, r0, r1
   27dc8: e3a00003     	mov	r0, #3
   27dcc: e1a02102     	lsl	r2, r2, #2
   27dd0: e0833002     	add	r3, r3, r2
   27dd4: e0833000     	add	r3, r3, r0
   27dd8: e5d33000     	ldrb	r3, [r3]
   27ddc: e1a03c03     	lsl	r3, r3, #24
   27de0: e1833001     	orr	r3, r3, r1
   27de4: e1a02003     	mov	r2, r3
   27de8: e51b300c     	ldr	r3, [r11, #-0xc]
   27dec: e5933008     	ldr	r3, [r3, #0x8]
   27df0: e0633002     	rsb	r3, r3, r2
   27df4: e2832001     	add	r2, r3, #1
   27df8: e51b300c     	ldr	r3, [r11, #-0xc]
   27dfc: e583200c     	str	r2, [r3, #0xc]
   27e00: ea000017     	b	0x27e64 <scarletbook_output_enqueue_track+0x474> @ imm = #0x5c
   27e04: e51b201c     	ldr	r2, [r11, #-0x1c]
   27e08: e51b1008     	ldr	r1, [r11, #-0x8]
   27e0c: e3a03060     	mov	r3, #96
   27e10: e59f00d4     	ldr	r0, [pc, #0xd4]         @ 0x27eec <scarletbook_output_enqueue_track+0x4fc>
   27e14: e0020290     	mul	r2, r0, r2
   27e18: e0812002     	add	r2, r1, r2
   27e1c: e0823003     	add	r3, r2, r3
   27e20: e5933000     	ldr	r3, [r3]
   27e24: e5d3204c     	ldrb	r2, [r3, #0x4c]
   27e28: e5d3104d     	ldrb	r1, [r3, #0x4d]
   27e2c: e1a01401     	lsl	r1, r1, #8
   27e30: e1812002     	orr	r2, r1, r2
   27e34: e5d3104e     	ldrb	r1, [r3, #0x4e]
   27e38: e1a01801     	lsl	r1, r1, #16
   27e3c: e1812002     	orr	r2, r1, r2
   27e40: e5d3304f     	ldrb	r3, [r3, #0x4f]
   27e44: e1a03c03     	lsl	r3, r3, #24
   27e48: e1833002     	orr	r3, r3, r2
   27e4c: e1a02003     	mov	r2, r3
   27e50: e51b300c     	ldr	r3, [r11, #-0xc]
   27e54: e5933008     	ldr	r3, [r3, #0x8]
   27e58: e0632002     	rsb	r2, r3, r2
   27e5c: e51b300c     	ldr	r3, [r11, #-0xc]
   27e60: e583200c     	str	r2, [r3, #0xc]
   27e64: e59f3084     	ldr	r3, [pc, #0x84]         @ 0x27ef0 <scarletbook_output_enqueue_track+0x500>
   27e68: e5933000     	ldr	r3, [r3]
   27e6c: e5933004     	ldr	r3, [r3, #0x4]
   27e70: e3530003     	cmp	r3, #3
   27e74: 9a000010     	bls	0x27ebc <scarletbook_output_enqueue_track+0x4cc> @ imm = #0x40
   27e78: e51b300c     	ldr	r3, [r11, #-0xc]
   27e7c: e5930008     	ldr	r0, [r3, #0x8]
   27e80: e51b300c     	ldr	r3, [r11, #-0xc]
   27e84: e593100c     	ldr	r1, [r3, #0xc]
   27e88: e51b300c     	ldr	r3, [r11, #-0xc]
   27e8c: e5932038     	ldr	r2, [r3, #0x38]
   27e90: e51b300c     	ldr	r3, [r11, #-0xc]
   27e94: e593303c     	ldr	r3, [r3, #0x3c]
   27e98: e58d0000     	str	r0, [sp]
   27e9c: e58d1004     	str	r1, [sp, #0x4]
   27ea0: e58d2008     	str	r2, [sp, #0x8]
   27ea4: e58d300c     	str	r3, [sp, #0xc]
   27ea8: e59f0044     	ldr	r0, [pc, #0x44]         @ 0x27ef4 <scarletbook_output_enqueue_track+0x504>
   27eac: e51b1024     	ldr	r1, [r11, #-0x24]
   27eb0: e51b201c     	ldr	r2, [r11, #-0x1c]
   27eb4: e51b3020     	ldr	r3, [r11, #-0x20]
   27eb8: ebffb37d     	bl	0x14cb4 <log_print>     @ imm = #-0x1320c
   27ebc: e51b300c     	ldr	r3, [r11, #-0xc]
   27ec0: e2832e17     	add	r2, r3, #368
   27ec4: e51b3018     	ldr	r3, [r11, #-0x18]
   27ec8: e1a00002     	mov	r0, r2
   27ecc: e1a01003     	mov	r1, r3
   27ed0: ebfffe4d     	bl	0x2780c <list_add_tail> @ imm = #-0x6cc
   27ed4: e3a03000     	mov	r3, #0
   27ed8: ea000000     	b	0x27ee0 <scarletbook_output_enqueue_track+0x4f0> @ imm = #0x0
   27edc: e3e03000     	mvn	r3, #0
   27ee0: e1a00003     	mov	r0, r3
   27ee4: e24bd004     	sub	sp, r11, #4
   27ee8: e8bd8800     	pop	{r11, pc}
   27eec: f0 37 00 00  	.word	0x000037f0
   27ef0: 5c 73 05 00  	.word	0x0005735c
   27ef4: 80 56 03 00  	.word	0x00035680

