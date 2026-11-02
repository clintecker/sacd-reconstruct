00029f88 <scarletbook_close>:
   29f88: e92d4800     	push	{r11, lr}
   29f8c: e28db004     	add	r11, sp, #4
   29f90: e24dd010     	sub	sp, sp, #16
   29f94: e50b0010     	str	r0, [r11, #-0x10]
   29f98: e51b3010     	ldr	r3, [r11, #-0x10]
   29f9c: e3530000     	cmp	r3, #0
   29fa0: 0a00008f     	beq	0x2a1e4 <scarletbook_close+0x25c> @ imm = #0x23c
   29fa4: e51b0010     	ldr	r0, [r11, #-0x10]
   29fa8: ebfffde9     	bl	0x29754 <has_two_channel> @ imm = #-0x85c
   29fac: e1a03000     	mov	r3, r0
   29fb0: e3530000     	cmp	r3, #0
   29fb4: 0a000013     	beq	0x2a008 <scarletbook_close+0x80> @ imm = #0x4c
   29fb8: e51b3010     	ldr	r3, [r11, #-0x10]
   29fbc: e283205c     	add	r2, r3, #92
   29fc0: e51b3010     	ldr	r3, [r11, #-0x10]
   29fc4: e5933050     	ldr	r3, [r3, #0x50]
   29fc8: e59f1220     	ldr	r1, [pc, #0x220]        @ 0x2a1f0 <scarletbook_close+0x268>
   29fcc: e0030391     	mul	r3, r1, r3
   29fd0: e0823003     	add	r3, r2, r3
   29fd4: e1a00003     	mov	r0, r3
   29fd8: ebffff23     	bl	0x29c6c <free_area>     @ imm = #-0x374
   29fdc: e51b3010     	ldr	r3, [r11, #-0x10]
   29fe0: e5932050     	ldr	r2, [r3, #0x50]
   29fe4: e51b1010     	ldr	r1, [r11, #-0x10]
   29fe8: e3a0305c     	mov	r3, #92
   29fec: e59f01fc     	ldr	r0, [pc, #0x1fc]        @ 0x2a1f0 <scarletbook_close+0x268>
   29ff0: e0020290     	mul	r2, r0, r2
   29ff4: e0812002     	add	r2, r1, r2
   29ff8: e0823003     	add	r3, r2, r3
   29ffc: e5933000     	ldr	r3, [r3]
   2a000: e1a00003     	mov	r0, r3
   2a004: ebff8904     	bl	0xc41c <free@plt>       @ imm = #-0x1dbf0
   2a008: e51b0010     	ldr	r0, [r11, #-0x10]
   2a00c: ebfffddd     	bl	0x29788 <has_multi_channel> @ imm = #-0x88c
   2a010: e1a03000     	mov	r3, r0
   2a014: e3530000     	cmp	r3, #0
   2a018: 0a000013     	beq	0x2a06c <scarletbook_close+0xe4> @ imm = #0x4c
   2a01c: e51b3010     	ldr	r3, [r11, #-0x10]
   2a020: e283205c     	add	r2, r3, #92
   2a024: e51b3010     	ldr	r3, [r11, #-0x10]
   2a028: e5933054     	ldr	r3, [r3, #0x54]
   2a02c: e59f11bc     	ldr	r1, [pc, #0x1bc]        @ 0x2a1f0 <scarletbook_close+0x268>
   2a030: e0030391     	mul	r3, r1, r3
   2a034: e0823003     	add	r3, r2, r3
   2a038: e1a00003     	mov	r0, r3
   2a03c: ebffff0a     	bl	0x29c6c <free_area>     @ imm = #-0x3d8
   2a040: e51b3010     	ldr	r3, [r11, #-0x10]
   2a044: e5932054     	ldr	r2, [r3, #0x54]
   2a048: e51b1010     	ldr	r1, [r11, #-0x10]
   2a04c: e3a0305c     	mov	r3, #92
   2a050: e59f0198     	ldr	r0, [pc, #0x198]        @ 0x2a1f0 <scarletbook_close+0x268>
   2a054: e0020290     	mul	r2, r0, r2
   2a058: e0812002     	add	r2, r1, r2
   2a05c: e0823003     	add	r3, r2, r3
   2a060: e5933000     	ldr	r3, [r3]
   2a064: e1a00003     	mov	r0, r3
   2a068: ebff88eb     	bl	0xc41c <free@plt>       @ imm = #-0x1dc54
   2a06c: e51b3010     	ldr	r3, [r11, #-0x10]
   2a070: e2833010     	add	r3, r3, #16
   2a074: e50b3008     	str	r3, [r11, #-0x8]
   2a078: e51b3008     	ldr	r3, [r11, #-0x8]
   2a07c: e5933000     	ldr	r3, [r3]
   2a080: e1a00003     	mov	r0, r3
   2a084: ebff88e4     	bl	0xc41c <free@plt>       @ imm = #-0x1dc70
   2a088: e51b3008     	ldr	r3, [r11, #-0x8]
   2a08c: e5933004     	ldr	r3, [r3, #0x4]
   2a090: e1a00003     	mov	r0, r3
   2a094: ebff88e0     	bl	0xc41c <free@plt>       @ imm = #-0x1dc80
   2a098: e51b3008     	ldr	r3, [r11, #-0x8]
   2a09c: e5933008     	ldr	r3, [r3, #0x8]
   2a0a0: e1a00003     	mov	r0, r3
   2a0a4: ebff88dc     	bl	0xc41c <free@plt>       @ imm = #-0x1dc90
   2a0a8: e51b3008     	ldr	r3, [r11, #-0x8]
   2a0ac: e593300c     	ldr	r3, [r3, #0xc]
   2a0b0: e1a00003     	mov	r0, r3
   2a0b4: ebff88d8     	bl	0xc41c <free@plt>       @ imm = #-0x1dca0
   2a0b8: e51b3008     	ldr	r3, [r11, #-0x8]
   2a0bc: e5933010     	ldr	r3, [r3, #0x10]
   2a0c0: e1a00003     	mov	r0, r3
   2a0c4: ebff88d4     	bl	0xc41c <free@plt>       @ imm = #-0x1dcb0
   2a0c8: e51b3008     	ldr	r3, [r11, #-0x8]
   2a0cc: e5933014     	ldr	r3, [r3, #0x14]
   2a0d0: e1a00003     	mov	r0, r3
   2a0d4: ebff88d0     	bl	0xc41c <free@plt>       @ imm = #-0x1dcc0
   2a0d8: e51b3008     	ldr	r3, [r11, #-0x8]
   2a0dc: e5933018     	ldr	r3, [r3, #0x18]
   2a0e0: e1a00003     	mov	r0, r3
   2a0e4: ebff88cc     	bl	0xc41c <free@plt>       @ imm = #-0x1dcd0
   2a0e8: e51b3008     	ldr	r3, [r11, #-0x8]
   2a0ec: e593301c     	ldr	r3, [r3, #0x1c]
   2a0f0: e1a00003     	mov	r0, r3
   2a0f4: ebff88c8     	bl	0xc41c <free@plt>       @ imm = #-0x1dce0
   2a0f8: e51b3008     	ldr	r3, [r11, #-0x8]
   2a0fc: e5933020     	ldr	r3, [r3, #0x20]
   2a100: e1a00003     	mov	r0, r3
   2a104: ebff88c4     	bl	0xc41c <free@plt>       @ imm = #-0x1dcf0
   2a108: e51b3008     	ldr	r3, [r11, #-0x8]
   2a10c: e5933024     	ldr	r3, [r3, #0x24]
   2a110: e1a00003     	mov	r0, r3
   2a114: ebff88c0     	bl	0xc41c <free@plt>       @ imm = #-0x1dd00
   2a118: e51b3008     	ldr	r3, [r11, #-0x8]
   2a11c: e5933028     	ldr	r3, [r3, #0x28]
   2a120: e1a00003     	mov	r0, r3
   2a124: ebff88bc     	bl	0xc41c <free@plt>       @ imm = #-0x1dd10
   2a128: e51b3008     	ldr	r3, [r11, #-0x8]
   2a12c: e593302c     	ldr	r3, [r3, #0x2c]
   2a130: e1a00003     	mov	r0, r3
   2a134: ebff88b8     	bl	0xc41c <free@plt>       @ imm = #-0x1dd20
   2a138: e51b3008     	ldr	r3, [r11, #-0x8]
   2a13c: e5933030     	ldr	r3, [r3, #0x30]
   2a140: e1a00003     	mov	r0, r3
   2a144: ebff88b4     	bl	0xc41c <free@plt>       @ imm = #-0x1dd30
   2a148: e51b3008     	ldr	r3, [r11, #-0x8]
   2a14c: e5933034     	ldr	r3, [r3, #0x34]
   2a150: e1a00003     	mov	r0, r3
   2a154: ebff88b0     	bl	0xc41c <free@plt>       @ imm = #-0x1dd40
   2a158: e51b3008     	ldr	r3, [r11, #-0x8]
   2a15c: e5933038     	ldr	r3, [r3, #0x38]
   2a160: e1a00003     	mov	r0, r3
   2a164: ebff88ac     	bl	0xc41c <free@plt>       @ imm = #-0x1dd50
   2a168: e51b3008     	ldr	r3, [r11, #-0x8]
   2a16c: e593303c     	ldr	r3, [r3, #0x3c]
   2a170: e1a00003     	mov	r0, r3
   2a174: ebff88a8     	bl	0xc41c <free@plt>       @ imm = #-0x1dd60
   2a178: e51b3010     	ldr	r3, [r11, #-0x10]
   2a17c: e5933004     	ldr	r3, [r3, #0x4]
   2a180: e3530000     	cmp	r3, #0
   2a184: 0a000003     	beq	0x2a198 <scarletbook_close+0x210> @ imm = #0xc
   2a188: e51b3010     	ldr	r3, [r11, #-0x10]
   2a18c: e5933004     	ldr	r3, [r3, #0x4]
   2a190: e1a00003     	mov	r0, r3
   2a194: ebff88a0     	bl	0xc41c <free@plt>       @ imm = #-0x1dd80
   2a198: e51b2010     	ldr	r2, [r11, #-0x10]
   2a19c: e59f3050     	ldr	r3, [pc, #0x50]         @ 0x2a1f4 <scarletbook_close+0x26c>
   2a1a0: e7923003     	ldr	r3, [r2, r3]
   2a1a4: e3530000     	cmp	r3, #0
   2a1a8: 0a000004     	beq	0x2a1c0 <scarletbook_close+0x238> @ imm = #0x10
   2a1ac: e51b2010     	ldr	r2, [r11, #-0x10]
   2a1b0: e59f303c     	ldr	r3, [pc, #0x3c]         @ 0x2a1f4 <scarletbook_close+0x26c>
   2a1b4: e7923003     	ldr	r3, [r2, r3]
   2a1b8: e1a00003     	mov	r0, r3
   2a1bc: ebff8896     	bl	0xc41c <free@plt>       @ imm = #-0x1dda8
   2a1c0: e51b0010     	ldr	r0, [r11, #-0x10]
   2a1c4: e3a01000     	mov	r1, #0
   2a1c8: e59f2028     	ldr	r2, [pc, #0x28]         @ 0x2a1f8 <scarletbook_close+0x270>
   2a1cc: ebff8874     	bl	0xc3a4 <memset@plt>     @ imm = #-0x1de30
   2a1d0: e51b0010     	ldr	r0, [r11, #-0x10]
   2a1d4: ebff8890     	bl	0xc41c <free@plt>       @ imm = #-0x1ddc0
   2a1d8: e3a03000     	mov	r3, #0
   2a1dc: e50b3010     	str	r3, [r11, #-0x10]
   2a1e0: ea000000     	b	0x2a1e8 <scarletbook_close+0x260> @ imm = #0x0
   2a1e4: e1a00000     	mov	r0, r0
   2a1e8: e24bd004     	sub	sp, r11, #4
   2a1ec: e8bd8800     	pop	{r11, pc}
   2a1f0: f0 37 00 00  	.word	0x000037f0
   2a1f4: 3c 70 00 00  	.word	0x0000703c
   2a1f8: 84 70 00 00  	.word	0x00007084

