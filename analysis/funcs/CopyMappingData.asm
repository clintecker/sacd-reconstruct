0001890c <CopyMappingData>:
   1890c: e52db004     	str	r11, [sp, #-0x4]!
   18910: e28db000     	add	r11, sp, #0
   18914: e24dd014     	sub	sp, sp, #20
   18918: e50b0010     	str	r0, [r11, #-0x10]
   1891c: e51b2010     	ldr	r2, [r11, #-0x10]
   18920: e59f31dc     	ldr	r3, [pc, #0x1dc]        @ 0x18b04 <CopyMappingData+0x1f8>
   18924: e3a01001     	mov	r1, #1
   18928: e7821003     	str	r1, [r2, r3]
   1892c: e3a03000     	mov	r3, #0
   18930: e50b300c     	str	r3, [r11, #-0xc]
   18934: ea00005b     	b	0x18aa8 <CopyMappingData+0x19c> @ imm = #0x16c
   18938: e51b300c     	ldr	r3, [r11, #-0xc]
   1893c: e51b1010     	ldr	r1, [r11, #-0x10]
   18940: e2833cdd     	add	r3, r3, #56576
   18944: e2833044     	add	r3, r3, #68
   18948: e3a02004     	mov	r2, #4
   1894c: e1a03103     	lsl	r3, r3, #2
   18950: e0813003     	add	r3, r1, r3
   18954: e0833002     	add	r3, r3, r2
   18958: e5932000     	ldr	r2, [r3]
   1895c: e51b300c     	ldr	r3, [r11, #-0xc]
   18960: e51b0010     	ldr	r0, [r11, #-0x10]
   18964: e283105c     	add	r1, r3, #92
   18968: e3a03008     	mov	r3, #8
   1896c: e1a01101     	lsl	r1, r1, #2
   18970: e0801001     	add	r1, r0, r1
   18974: e0813003     	add	r3, r1, r3
   18978: e5933000     	ldr	r3, [r3]
   1897c: e1520003     	cmp	r2, r3
   18980: 1a000046     	bne	0x18aa0 <CopyMappingData+0x194> @ imm = #0x118
   18984: e3a03000     	mov	r3, #0
   18988: e50b3008     	str	r3, [r11, #-0x8]
   1898c: ea000034     	b	0x18a64 <CopyMappingData+0x158> @ imm = #0xd0
   18990: e51b100c     	ldr	r1, [r11, #-0xc]
   18994: e51b3008     	ldr	r3, [r11, #-0x8]
   18998: e51b000c     	ldr	r0, [r11, #-0xc]
   1899c: e51b2008     	ldr	r2, [r11, #-0x8]
   189a0: e51bc010     	ldr	r12, [r11, #-0x10]
   189a4: e1a00180     	lsl	r0, r0, #3
   189a8: e0802002     	add	r2, r0, r2
   189ac: e2820062     	add	r0, r2, #98
   189b0: e3a02008     	mov	r2, #8
   189b4: e1a00100     	lsl	r0, r0, #2
   189b8: e08c0000     	add	r0, r12, r0
   189bc: e0802002     	add	r2, r0, r2
   189c0: e5922000     	ldr	r2, [r2]
   189c4: e51b0010     	ldr	r0, [r11, #-0x10]
   189c8: e1a01181     	lsl	r1, r1, #3
   189cc: e0813003     	add	r3, r1, r3
   189d0: e2833cdd     	add	r3, r3, #56576
   189d4: e283304a     	add	r3, r3, #74
   189d8: e3a01004     	mov	r1, #4
   189dc: e1a03103     	lsl	r3, r3, #2
   189e0: e0803003     	add	r3, r0, r3
   189e4: e0833001     	add	r3, r3, r1
   189e8: e5832000     	str	r2, [r3]
   189ec: e51b200c     	ldr	r2, [r11, #-0xc]
   189f0: e51b3008     	ldr	r3, [r11, #-0x8]
   189f4: e51b1010     	ldr	r1, [r11, #-0x10]
   189f8: e1a02182     	lsl	r2, r2, #3
   189fc: e0823003     	add	r3, r2, r3
   18a00: e2833cdd     	add	r3, r3, #56576
   18a04: e283304a     	add	r3, r3, #74
   18a08: e3a02004     	mov	r2, #4
   18a0c: e1a03103     	lsl	r3, r3, #2
   18a10: e0813003     	add	r3, r1, r3
   18a14: e0833002     	add	r3, r3, r2
   18a18: e5932000     	ldr	r2, [r3]
   18a1c: e51b3008     	ldr	r3, [r11, #-0x8]
   18a20: e51b0010     	ldr	r0, [r11, #-0x10]
   18a24: e2833cdd     	add	r3, r3, #56576
   18a28: e283304a     	add	r3, r3, #74
   18a2c: e3a01004     	mov	r1, #4
   18a30: e1a03103     	lsl	r3, r3, #2
   18a34: e0803003     	add	r3, r0, r3
   18a38: e0833001     	add	r3, r3, r1
   18a3c: e5933000     	ldr	r3, [r3]
   18a40: e1520003     	cmp	r2, r3
   18a44: 0a000003     	beq	0x18a58 <CopyMappingData+0x14c> @ imm = #0xc
   18a48: e51b2010     	ldr	r2, [r11, #-0x10]
   18a4c: e59f30b0     	ldr	r3, [pc, #0xb0]         @ 0x18b04 <CopyMappingData+0x1f8>
   18a50: e3a01000     	mov	r1, #0
   18a54: e7821003     	str	r1, [r2, r3]
   18a58: e51b3008     	ldr	r3, [r11, #-0x8]
   18a5c: e2833001     	add	r3, r3, #1
   18a60: e50b3008     	str	r3, [r11, #-0x8]
   18a64: e51b300c     	ldr	r3, [r11, #-0xc]
   18a68: e51b1010     	ldr	r1, [r11, #-0x10]
   18a6c: e283205c     	add	r2, r3, #92
   18a70: e3a03008     	mov	r3, #8
   18a74: e1a02102     	lsl	r2, r2, #2
   18a78: e0812002     	add	r2, r1, r2
   18a7c: e0823003     	add	r3, r2, r3
   18a80: e5932000     	ldr	r2, [r3]
   18a84: e51b3008     	ldr	r3, [r11, #-0x8]
   18a88: e1520003     	cmp	r2, r3
   18a8c: caffffbf     	bgt	0x18990 <CopyMappingData+0x84> @ imm = #-0x104
   18a90: e51b300c     	ldr	r3, [r11, #-0xc]
   18a94: e2833001     	add	r3, r3, #1
   18a98: e50b300c     	str	r3, [r11, #-0xc]
   18a9c: ea000001     	b	0x18aa8 <CopyMappingData+0x19c> @ imm = #0x4
   18aa0: e3a03008     	mov	r3, #8
   18aa4: ea000012     	b	0x18af4 <CopyMappingData+0x1e8> @ imm = #0x48
   18aa8: e51b3010     	ldr	r3, [r11, #-0x10]
   18aac: e5932004     	ldr	r2, [r3, #0x4]
   18ab0: e51b300c     	ldr	r3, [r11, #-0xc]
   18ab4: e1520003     	cmp	r2, r3
   18ab8: caffff9e     	bgt	0x18938 <CopyMappingData+0x2c> @ imm = #-0x188
   18abc: e51b3010     	ldr	r3, [r11, #-0x10]
   18ac0: e5932008     	ldr	r2, [r3, #0x8]
   18ac4: e51b3010     	ldr	r3, [r11, #-0x10]
   18ac8: e583200c     	str	r2, [r3, #0xc]
   18acc: e51b3010     	ldr	r3, [r11, #-0x10]
   18ad0: e593200c     	ldr	r2, [r3, #0xc]
   18ad4: e51b1010     	ldr	r1, [r11, #-0x10]
   18ad8: e59f3028     	ldr	r3, [pc, #0x28]         @ 0x18b08 <CopyMappingData+0x1fc>
   18adc: e7913003     	ldr	r3, [r1, r3]
   18ae0: e1520003     	cmp	r2, r3
   18ae4: da000001     	ble	0x18af0 <CopyMappingData+0x1e4> @ imm = #0x4
   18ae8: e3a03005     	mov	r3, #5
   18aec: ea000000     	b	0x18af4 <CopyMappingData+0x1e8> @ imm = #0x0
   18af0: e3a03000     	mov	r3, #0
   18af4: e1a00003     	mov	r0, r3
   18af8: e28bd000     	add	sp, r11, #0
   18afc: e8bd0800     	ldm	sp!, {r11}
   18b00: e12fff1e     	bx	lr
   18b04: 00 e8 06 00  	.word	0x0006e800
   18b08: 0c e8 06 00  	.word	0x0006e80c

