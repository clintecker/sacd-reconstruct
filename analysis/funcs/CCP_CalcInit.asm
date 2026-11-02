0001bd8c <CCP_CalcInit>:
   1bd8c: e92d4800     	push	{r11, lr}
   1bd90: e28db004     	add	r11, sp, #4
   1bd94: e24dd010     	sub	sp, sp, #16
   1bd98: e50b0010     	str	r0, [r11, #-0x10]
   1bd9c: e3a03000     	mov	r3, #0
   1bda0: e50b300c     	str	r3, [r11, #-0xc]
   1bda4: e51b3010     	ldr	r3, [r11, #-0x10]
   1bda8: e5933020     	ldr	r3, [r3, #0x20]
   1bdac: e3530000     	cmp	r3, #0
   1bdb0: 0a000002     	beq	0x1bdc0 <CCP_CalcInit+0x34> @ imm = #0x8
   1bdb4: e3530001     	cmp	r3, #1
   1bdb8: 0a000072     	beq	0x1bf88 <CCP_CalcInit+0x1fc> @ imm = #0x1c8
   1bdbc: ea0000e3     	b	0x1c150 <CCP_CalcInit+0x3c4> @ imm = #0x38c
   1bdc0: e51b3010     	ldr	r3, [r11, #-0x10]
   1bdc4: e5933000     	ldr	r3, [r3]
   1bdc8: e3a02001     	mov	r2, #1
   1bdcc: e5832000     	str	r2, [r3]
   1bdd0: e51b3010     	ldr	r3, [r11, #-0x10]
   1bdd4: e5933004     	ldr	r3, [r3, #0x4]
   1bdd8: e5933000     	ldr	r3, [r3]
   1bddc: e3e02007     	mvn	r2, #7
   1bde0: e5832000     	str	r2, [r3]
   1bde4: e51b3010     	ldr	r3, [r11, #-0x10]
   1bde8: e5933000     	ldr	r3, [r3]
   1bdec: e5933000     	ldr	r3, [r3]
   1bdf0: e50b3008     	str	r3, [r11, #-0x8]
   1bdf4: ea00000a     	b	0x1be24 <CCP_CalcInit+0x98> @ imm = #0x28
   1bdf8: e51b3010     	ldr	r3, [r11, #-0x10]
   1bdfc: e5933004     	ldr	r3, [r3, #0x4]
   1be00: e5932000     	ldr	r2, [r3]
   1be04: e51b3008     	ldr	r3, [r11, #-0x8]
   1be08: e1a03103     	lsl	r3, r3, #2
   1be0c: e0823003     	add	r3, r2, r3
   1be10: e3a02000     	mov	r2, #0
   1be14: e5832000     	str	r2, [r3]
   1be18: e51b3008     	ldr	r3, [r11, #-0x8]
   1be1c: e2833001     	add	r3, r3, #1
   1be20: e50b3008     	str	r3, [r11, #-0x8]
   1be24: e51b3008     	ldr	r3, [r11, #-0x8]
   1be28: e3530002     	cmp	r3, #2
   1be2c: dafffff1     	ble	0x1bdf8 <CCP_CalcInit+0x6c> @ imm = #-0x3c
   1be30: e51b3010     	ldr	r3, [r11, #-0x10]
   1be34: e5933000     	ldr	r3, [r3]
   1be38: e2833004     	add	r3, r3, #4
   1be3c: e3a02002     	mov	r2, #2
   1be40: e5832000     	str	r2, [r3]
   1be44: e51b3010     	ldr	r3, [r11, #-0x10]
   1be48: e5933004     	ldr	r3, [r3, #0x4]
   1be4c: e2833004     	add	r3, r3, #4
   1be50: e5933000     	ldr	r3, [r3]
   1be54: e3e0200f     	mvn	r2, #15
   1be58: e5832000     	str	r2, [r3]
   1be5c: e51b3010     	ldr	r3, [r11, #-0x10]
   1be60: e5933004     	ldr	r3, [r3, #0x4]
   1be64: e2833004     	add	r3, r3, #4
   1be68: e5933000     	ldr	r3, [r3]
   1be6c: e2833004     	add	r3, r3, #4
   1be70: e3a02008     	mov	r2, #8
   1be74: e5832000     	str	r2, [r3]
   1be78: e51b3010     	ldr	r3, [r11, #-0x10]
   1be7c: e5933000     	ldr	r3, [r3]
   1be80: e2833004     	add	r3, r3, #4
   1be84: e5933000     	ldr	r3, [r3]
   1be88: e50b3008     	str	r3, [r11, #-0x8]
   1be8c: ea00000b     	b	0x1bec0 <CCP_CalcInit+0x134> @ imm = #0x2c
   1be90: e51b3010     	ldr	r3, [r11, #-0x10]
   1be94: e5933004     	ldr	r3, [r3, #0x4]
   1be98: e2833004     	add	r3, r3, #4
   1be9c: e5932000     	ldr	r2, [r3]
   1bea0: e51b3008     	ldr	r3, [r11, #-0x8]
   1bea4: e1a03103     	lsl	r3, r3, #2
   1bea8: e0823003     	add	r3, r2, r3
   1beac: e3a02000     	mov	r2, #0
   1beb0: e5832000     	str	r2, [r3]
   1beb4: e51b3008     	ldr	r3, [r11, #-0x8]
   1beb8: e2833001     	add	r3, r3, #1
   1bebc: e50b3008     	str	r3, [r11, #-0x8]
   1bec0: e51b3008     	ldr	r3, [r11, #-0x8]
   1bec4: e3530002     	cmp	r3, #2
   1bec8: dafffff0     	ble	0x1be90 <CCP_CalcInit+0x104> @ imm = #-0x40
   1becc: e51b3010     	ldr	r3, [r11, #-0x10]
   1bed0: e5933000     	ldr	r3, [r3]
   1bed4: e2833008     	add	r3, r3, #8
   1bed8: e3a02003     	mov	r2, #3
   1bedc: e5832000     	str	r2, [r3]
   1bee0: e51b3010     	ldr	r3, [r11, #-0x10]
   1bee4: e5933004     	ldr	r3, [r3, #0x4]
   1bee8: e2833008     	add	r3, r3, #8
   1beec: e5933000     	ldr	r3, [r3]
   1bef0: e3e02008     	mvn	r2, #8
   1bef4: e5832000     	str	r2, [r3]
   1bef8: e51b3010     	ldr	r3, [r11, #-0x10]
   1befc: e5933004     	ldr	r3, [r3, #0x4]
   1bf00: e2833008     	add	r3, r3, #8
   1bf04: e5933000     	ldr	r3, [r3]
   1bf08: e2833004     	add	r3, r3, #4
   1bf0c: e3e02004     	mvn	r2, #4
   1bf10: e5832000     	str	r2, [r3]
   1bf14: e51b3010     	ldr	r3, [r11, #-0x10]
   1bf18: e5933004     	ldr	r3, [r3, #0x4]
   1bf1c: e2833008     	add	r3, r3, #8
   1bf20: e5933000     	ldr	r3, [r3]
   1bf24: e2833008     	add	r3, r3, #8
   1bf28: e3a02006     	mov	r2, #6
   1bf2c: e5832000     	str	r2, [r3]
   1bf30: e51b3010     	ldr	r3, [r11, #-0x10]
   1bf34: e5933000     	ldr	r3, [r3]
   1bf38: e2833008     	add	r3, r3, #8
   1bf3c: e5933000     	ldr	r3, [r3]
   1bf40: e50b3008     	str	r3, [r11, #-0x8]
   1bf44: ea00000b     	b	0x1bf78 <CCP_CalcInit+0x1ec> @ imm = #0x2c
   1bf48: e51b3010     	ldr	r3, [r11, #-0x10]
   1bf4c: e5933004     	ldr	r3, [r3, #0x4]
   1bf50: e2833008     	add	r3, r3, #8
   1bf54: e5932000     	ldr	r2, [r3]
   1bf58: e51b3008     	ldr	r3, [r11, #-0x8]
   1bf5c: e1a03103     	lsl	r3, r3, #2
   1bf60: e0823003     	add	r3, r2, r3
   1bf64: e3a02000     	mov	r2, #0
   1bf68: e5832000     	str	r2, [r3]
   1bf6c: e51b3008     	ldr	r3, [r11, #-0x8]
   1bf70: e2833001     	add	r3, r3, #1
   1bf74: e50b3008     	str	r3, [r11, #-0x8]
   1bf78: e51b3008     	ldr	r3, [r11, #-0x8]
   1bf7c: e3530002     	cmp	r3, #2
   1bf80: dafffff0     	ble	0x1bf48 <CCP_CalcInit+0x1bc> @ imm = #-0x40
   1bf84: ea00007a     	b	0x1c174 <CCP_CalcInit+0x3e8> @ imm = #0x1e8
   1bf88: e51b3010     	ldr	r3, [r11, #-0x10]
   1bf8c: e5933000     	ldr	r3, [r3]
   1bf90: e3a02001     	mov	r2, #1
   1bf94: e5832000     	str	r2, [r3]
   1bf98: e51b3010     	ldr	r3, [r11, #-0x10]
   1bf9c: e5933004     	ldr	r3, [r3, #0x4]
   1bfa0: e5933000     	ldr	r3, [r3]
   1bfa4: e3e02007     	mvn	r2, #7
   1bfa8: e5832000     	str	r2, [r3]
   1bfac: e51b3010     	ldr	r3, [r11, #-0x10]
   1bfb0: e5933000     	ldr	r3, [r3]
   1bfb4: e5933000     	ldr	r3, [r3]
   1bfb8: e50b3008     	str	r3, [r11, #-0x8]
   1bfbc: ea00000a     	b	0x1bfec <CCP_CalcInit+0x260> @ imm = #0x28
   1bfc0: e51b3010     	ldr	r3, [r11, #-0x10]
   1bfc4: e5933004     	ldr	r3, [r3, #0x4]
   1bfc8: e5932000     	ldr	r2, [r3]
   1bfcc: e51b3008     	ldr	r3, [r11, #-0x8]
   1bfd0: e1a03103     	lsl	r3, r3, #2
   1bfd4: e0823003     	add	r3, r2, r3
   1bfd8: e3a02000     	mov	r2, #0
   1bfdc: e5832000     	str	r2, [r3]
   1bfe0: e51b3008     	ldr	r3, [r11, #-0x8]
   1bfe4: e2833001     	add	r3, r3, #1
   1bfe8: e50b3008     	str	r3, [r11, #-0x8]
   1bfec: e51b3008     	ldr	r3, [r11, #-0x8]
   1bff0: e3530002     	cmp	r3, #2
   1bff4: dafffff1     	ble	0x1bfc0 <CCP_CalcInit+0x234> @ imm = #-0x3c
   1bff8: e51b3010     	ldr	r3, [r11, #-0x10]
   1bffc: e5933000     	ldr	r3, [r3]
   1c000: e2833004     	add	r3, r3, #4
   1c004: e3a02002     	mov	r2, #2
   1c008: e5832000     	str	r2, [r3]
   1c00c: e51b3010     	ldr	r3, [r11, #-0x10]
   1c010: e5933004     	ldr	r3, [r3, #0x4]
   1c014: e2833004     	add	r3, r3, #4
   1c018: e5933000     	ldr	r3, [r3]
   1c01c: e3e0200f     	mvn	r2, #15
   1c020: e5832000     	str	r2, [r3]
   1c024: e51b3010     	ldr	r3, [r11, #-0x10]
   1c028: e5933004     	ldr	r3, [r3, #0x4]
   1c02c: e2833004     	add	r3, r3, #4
   1c030: e5933000     	ldr	r3, [r3]
   1c034: e2833004     	add	r3, r3, #4
   1c038: e3a02008     	mov	r2, #8
   1c03c: e5832000     	str	r2, [r3]
   1c040: e51b3010     	ldr	r3, [r11, #-0x10]
   1c044: e5933000     	ldr	r3, [r3]
   1c048: e2833004     	add	r3, r3, #4
   1c04c: e5933000     	ldr	r3, [r3]
   1c050: e50b3008     	str	r3, [r11, #-0x8]
   1c054: ea00000b     	b	0x1c088 <CCP_CalcInit+0x2fc> @ imm = #0x2c
   1c058: e51b3010     	ldr	r3, [r11, #-0x10]
   1c05c: e5933004     	ldr	r3, [r3, #0x4]
   1c060: e2833004     	add	r3, r3, #4
   1c064: e5932000     	ldr	r2, [r3]
   1c068: e51b3008     	ldr	r3, [r11, #-0x8]
   1c06c: e1a03103     	lsl	r3, r3, #2
   1c070: e0823003     	add	r3, r2, r3
   1c074: e3a02000     	mov	r2, #0
   1c078: e5832000     	str	r2, [r3]
   1c07c: e51b3008     	ldr	r3, [r11, #-0x8]
   1c080: e2833001     	add	r3, r3, #1
   1c084: e50b3008     	str	r3, [r11, #-0x8]
   1c088: e51b3008     	ldr	r3, [r11, #-0x8]
   1c08c: e3530002     	cmp	r3, #2
   1c090: dafffff0     	ble	0x1c058 <CCP_CalcInit+0x2cc> @ imm = #-0x40
   1c094: e51b3010     	ldr	r3, [r11, #-0x10]
   1c098: e5933000     	ldr	r3, [r3]
   1c09c: e2833008     	add	r3, r3, #8
   1c0a0: e3a02003     	mov	r2, #3
   1c0a4: e5832000     	str	r2, [r3]
   1c0a8: e51b3010     	ldr	r3, [r11, #-0x10]
   1c0ac: e5933004     	ldr	r3, [r3, #0x4]
   1c0b0: e2833008     	add	r3, r3, #8
   1c0b4: e5933000     	ldr	r3, [r3]
   1c0b8: e3e02017     	mvn	r2, #23
   1c0bc: e5832000     	str	r2, [r3]
   1c0c0: e51b3010     	ldr	r3, [r11, #-0x10]
   1c0c4: e5933004     	ldr	r3, [r3, #0x4]
   1c0c8: e2833008     	add	r3, r3, #8
   1c0cc: e5933000     	ldr	r3, [r3]
   1c0d0: e2833004     	add	r3, r3, #4
   1c0d4: e3a02018     	mov	r2, #24
   1c0d8: e5832000     	str	r2, [r3]
   1c0dc: e51b3010     	ldr	r3, [r11, #-0x10]
   1c0e0: e5933004     	ldr	r3, [r3, #0x4]
   1c0e4: e2833008     	add	r3, r3, #8
   1c0e8: e5933000     	ldr	r3, [r3]
   1c0ec: e2833008     	add	r3, r3, #8
   1c0f0: e3e02007     	mvn	r2, #7
   1c0f4: e5832000     	str	r2, [r3]
   1c0f8: e51b3010     	ldr	r3, [r11, #-0x10]
   1c0fc: e5933000     	ldr	r3, [r3]
   1c100: e2833008     	add	r3, r3, #8
   1c104: e5933000     	ldr	r3, [r3]
   1c108: e50b3008     	str	r3, [r11, #-0x8]
   1c10c: ea00000b     	b	0x1c140 <CCP_CalcInit+0x3b4> @ imm = #0x2c
   1c110: e51b3010     	ldr	r3, [r11, #-0x10]
   1c114: e5933004     	ldr	r3, [r3, #0x4]
   1c118: e2833008     	add	r3, r3, #8
   1c11c: e5932000     	ldr	r2, [r3]
   1c120: e51b3008     	ldr	r3, [r11, #-0x8]
   1c124: e1a03103     	lsl	r3, r3, #2
   1c128: e0823003     	add	r3, r2, r3
   1c12c: e3a02000     	mov	r2, #0
   1c130: e5832000     	str	r2, [r3]
   1c134: e51b3008     	ldr	r3, [r11, #-0x8]
   1c138: e2833001     	add	r3, r3, #1
   1c13c: e50b3008     	str	r3, [r11, #-0x8]
   1c140: e51b3008     	ldr	r3, [r11, #-0x8]
   1c144: e3530002     	cmp	r3, #2
   1c148: dafffff0     	ble	0x1c110 <CCP_CalcInit+0x384> @ imm = #-0x40
   1c14c: ea000008     	b	0x1c174 <CCP_CalcInit+0x3e8> @ imm = #0x20
   1c150: e59f202c     	ldr	r2, [pc, #0x2c]         @ 0x1c184 <CCP_CalcInit+0x3f8>
   1c154: e59f302c     	ldr	r3, [pc, #0x2c]         @ 0x1c188 <CCP_CalcInit+0x3fc>
   1c158: e5933000     	ldr	r3, [r3]
   1c15c: e1a00002     	mov	r0, r2
   1c160: e3a01001     	mov	r1, #1
   1c164: e3a0201a     	mov	r2, #26
   1c168: ebffc120     	bl	0xc5f0 <fwrite@plt>     @ imm = #-0xfb80
   1c16c: e3a03001     	mov	r3, #1
   1c170: e50b300c     	str	r3, [r11, #-0xc]
   1c174: e51b300c     	ldr	r3, [r11, #-0xc]
   1c178: e1a00003     	mov	r0, r3
   1c17c: e24bd004     	sub	sp, r11, #4
   1c180: e8bd8800     	pop	{r11, pc}
   1c184: d8 30 03 00  	.word	0x000330d8
   1c188: f8 6d 05 00  	.word	0x00056df8

