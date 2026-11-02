0001eae8 <id3_write_tag>:
   1eae8: e92d4800     	push	{r11, lr}
   1eaec: e28db004     	add	r11, sp, #4
   1eaf0: e24dd030     	sub	sp, sp, #48
   1eaf4: e50b0030     	str	r0, [r11, #-0x30]
   1eaf8: e50b1034     	str	r1, [r11, #-0x34]
   1eafc: e3a03000     	mov	r3, #0
   1eb00: e50b3014     	str	r3, [r11, #-0x14]
   1eb04: e51b3034     	ldr	r3, [r11, #-0x34]
   1eb08: e50b3010     	str	r3, [r11, #-0x10]
   1eb0c: e51b3030     	ldr	r3, [r11, #-0x30]
   1eb10: e5933138     	ldr	r3, [r3, #0x138]
   1eb14: e50b300c     	str	r3, [r11, #-0xc]
   1eb18: ea00000b     	b	0x1eb4c <id3_write_tag+0x64> @ imm = #0x2c
   1eb1c: e51b300c     	ldr	r3, [r11, #-0xc]
   1eb20: e2433028     	sub	r3, r3, #40
   1eb24: e50b3018     	str	r3, [r11, #-0x18]
   1eb28: e51b3018     	ldr	r3, [r11, #-0x18]
   1eb2c: e5933014     	ldr	r3, [r3, #0x14]
   1eb30: e283300a     	add	r3, r3, #10
   1eb34: e51b2014     	ldr	r2, [r11, #-0x14]
   1eb38: e0823003     	add	r3, r2, r3
   1eb3c: e50b3014     	str	r3, [r11, #-0x14]
   1eb40: e51b300c     	ldr	r3, [r11, #-0xc]
   1eb44: e5933000     	ldr	r3, [r3]
   1eb48: e50b300c     	str	r3, [r11, #-0xc]
   1eb4c: e51b300c     	ldr	r3, [r11, #-0xc]
   1eb50: e5932000     	ldr	r2, [r3]
   1eb54: e51b300c     	ldr	r3, [r11, #-0xc]
   1eb58: e5832000     	str	r2, [r3]
   1eb5c: e51b3030     	ldr	r3, [r11, #-0x30]
   1eb60: e2832f4e     	add	r2, r3, #312
   1eb64: e51b300c     	ldr	r3, [r11, #-0xc]
   1eb68: e1520003     	cmp	r2, r3
   1eb6c: 1affffea     	bne	0x1eb1c <id3_write_tag+0x34> @ imm = #-0x58
   1eb70: e51b3030     	ldr	r3, [r11, #-0x30]
   1eb74: e5933014     	ldr	r3, [r3, #0x14]
   1eb78: e6ef3073     	uxtb	r3, r3
   1eb7c: e54b3020     	strb	r3, [r11, #-0x20]
   1eb80: e51b3030     	ldr	r3, [r11, #-0x30]
   1eb84: e5933018     	ldr	r3, [r3, #0x18]
   1eb88: e6ef3073     	uxtb	r3, r3
   1eb8c: e54b301f     	strb	r3, [r11, #-0x1f]
   1eb90: e51b3030     	ldr	r3, [r11, #-0x30]
   1eb94: e5933008     	ldr	r3, [r3, #0x8]
   1eb98: e6ef3073     	uxtb	r3, r3
   1eb9c: e54b301e     	strb	r3, [r11, #-0x1e]
   1eba0: e51b3014     	ldr	r3, [r11, #-0x14]
   1eba4: e2033502     	and	r3, r3, #8388608
   1eba8: e1a03bc3     	asr	r3, r3, #23
   1ebac: e6ef2073     	uxtb	r2, r3
   1ebb0: e51b3014     	ldr	r3, [r11, #-0x14]
   1ebb4: e203347f     	and	r3, r3, #2130706432
   1ebb8: e1a03c43     	asr	r3, r3, #24
   1ebbc: e1a03083     	lsl	r3, r3, #1
   1ebc0: e6ef3073     	uxtb	r3, r3
   1ebc4: e1823003     	orr	r3, r2, r3
   1ebc8: e6ef3073     	uxtb	r3, r3
   1ebcc: e6ef3073     	uxtb	r3, r3
   1ebd0: e54b301d     	strb	r3, [r11, #-0x1d]
   1ebd4: e51b3014     	ldr	r3, [r11, #-0x14]
   1ebd8: e2033902     	and	r3, r3, #32768
   1ebdc: e1a037c3     	asr	r3, r3, #15
   1ebe0: e6ef2073     	uxtb	r2, r3
   1ebe4: e51b3014     	ldr	r3, [r11, #-0x14]
   1ebe8: e203387f     	and	r3, r3, #8323072
   1ebec: e1a03843     	asr	r3, r3, #16
   1ebf0: e1a03083     	lsl	r3, r3, #1
   1ebf4: e6ef3073     	uxtb	r3, r3
   1ebf8: e1823003     	orr	r3, r2, r3
   1ebfc: e6ef3073     	uxtb	r3, r3
   1ec00: e6ef3073     	uxtb	r3, r3
   1ec04: e54b301c     	strb	r3, [r11, #-0x1c]
   1ec08: e51b3014     	ldr	r3, [r11, #-0x14]
   1ec0c: e2033080     	and	r3, r3, #128
   1ec10: e1a033c3     	asr	r3, r3, #7
   1ec14: e6ef2073     	uxtb	r2, r3
   1ec18: e51b3014     	ldr	r3, [r11, #-0x14]
   1ec1c: e2033c7f     	and	r3, r3, #32512
   1ec20: e1a03443     	asr	r3, r3, #8
   1ec24: e1a03083     	lsl	r3, r3, #1
   1ec28: e6ef3073     	uxtb	r3, r3
   1ec2c: e1823003     	orr	r3, r2, r3
   1ec30: e6ef3073     	uxtb	r3, r3
   1ec34: e6ef3073     	uxtb	r3, r3
   1ec38: e54b301b     	strb	r3, [r11, #-0x1b]
   1ec3c: e51b3014     	ldr	r3, [r11, #-0x14]
   1ec40: e6ef3073     	uxtb	r3, r3
   1ec44: e203307f     	and	r3, r3, #127
   1ec48: e54b301a     	strb	r3, [r11, #-0x1a]
   1ec4c: e51b0010     	ldr	r0, [r11, #-0x10]
   1ec50: e59f124c     	ldr	r1, [pc, #0x24c]        @ 0x1eea4 <id3_write_tag+0x3bc>
   1ec54: e3a02003     	mov	r2, #3
   1ec58: ebffb62b     	bl	0xc50c <memcpy@plt>     @ imm = #-0x12754
   1ec5c: e51b3010     	ldr	r3, [r11, #-0x10]
   1ec60: e2833003     	add	r3, r3, #3
   1ec64: e50b3010     	str	r3, [r11, #-0x10]
   1ec68: e24b3020     	sub	r3, r11, #32
   1ec6c: e51b0010     	ldr	r0, [r11, #-0x10]
   1ec70: e1a01003     	mov	r1, r3
   1ec74: e3a02007     	mov	r2, #7
   1ec78: ebffb623     	bl	0xc50c <memcpy@plt>     @ imm = #-0x12774
   1ec7c: e51b3010     	ldr	r3, [r11, #-0x10]
   1ec80: e2833007     	add	r3, r3, #7
   1ec84: e50b3010     	str	r3, [r11, #-0x10]
   1ec88: e51b3030     	ldr	r3, [r11, #-0x30]
   1ec8c: e5933138     	ldr	r3, [r3, #0x138]
   1ec90: e50b300c     	str	r3, [r11, #-0xc]
   1ec94: ea000073     	b	0x1ee68 <id3_write_tag+0x380> @ imm = #0x1cc
   1ec98: e24b302c     	sub	r3, r11, #44
   1ec9c: e50b3008     	str	r3, [r11, #-0x8]
   1eca0: e51b300c     	ldr	r3, [r11, #-0xc]
   1eca4: e2433028     	sub	r3, r3, #40
   1eca8: e50b3018     	str	r3, [r11, #-0x18]
   1ecac: e51b3018     	ldr	r3, [r11, #-0x18]
   1ecb0: e5933004     	ldr	r3, [r3, #0x4]
   1ecb4: e2833004     	add	r3, r3, #4
   1ecb8: e51b0008     	ldr	r0, [r11, #-0x8]
   1ecbc: e1a01003     	mov	r1, r3
   1ecc0: e3a02004     	mov	r2, #4
   1ecc4: ebffb610     	bl	0xc50c <memcpy@plt>     @ imm = #-0x127c0
   1ecc8: e51b3008     	ldr	r3, [r11, #-0x8]
   1eccc: e2833004     	add	r3, r3, #4
   1ecd0: e50b3008     	str	r3, [r11, #-0x8]
   1ecd4: e51b3018     	ldr	r3, [r11, #-0x18]
   1ecd8: e5933014     	ldr	r3, [r3, #0x14]
   1ecdc: e2033502     	and	r3, r3, #8388608
   1ece0: e1a03bc3     	asr	r3, r3, #23
   1ece4: e6ef2073     	uxtb	r2, r3
   1ece8: e51b3018     	ldr	r3, [r11, #-0x18]
   1ecec: e5933014     	ldr	r3, [r3, #0x14]
   1ecf0: e203347f     	and	r3, r3, #2130706432
   1ecf4: e1a03c43     	asr	r3, r3, #24
   1ecf8: e1a03083     	lsl	r3, r3, #1
   1ecfc: e6ef3073     	uxtb	r3, r3
   1ed00: e1823003     	orr	r3, r2, r3
   1ed04: e6ef3073     	uxtb	r3, r3
   1ed08: e6ef2073     	uxtb	r2, r3
   1ed0c: e51b3008     	ldr	r3, [r11, #-0x8]
   1ed10: e5c32000     	strb	r2, [r3]
   1ed14: e51b3008     	ldr	r3, [r11, #-0x8]
   1ed18: e2833001     	add	r3, r3, #1
   1ed1c: e51b2018     	ldr	r2, [r11, #-0x18]
   1ed20: e5922014     	ldr	r2, [r2, #0x14]
   1ed24: e2022902     	and	r2, r2, #32768
   1ed28: e1a027c2     	asr	r2, r2, #15
   1ed2c: e6ef1072     	uxtb	r1, r2
   1ed30: e51b2018     	ldr	r2, [r11, #-0x18]
   1ed34: e5922014     	ldr	r2, [r2, #0x14]
   1ed38: e202287f     	and	r2, r2, #8323072
   1ed3c: e1a02842     	asr	r2, r2, #16
   1ed40: e1a02082     	lsl	r2, r2, #1
   1ed44: e6ef2072     	uxtb	r2, r2
   1ed48: e1812002     	orr	r2, r1, r2
   1ed4c: e6ef2072     	uxtb	r2, r2
   1ed50: e6ef2072     	uxtb	r2, r2
   1ed54: e5c32000     	strb	r2, [r3]
   1ed58: e51b3008     	ldr	r3, [r11, #-0x8]
   1ed5c: e2833002     	add	r3, r3, #2
   1ed60: e51b2018     	ldr	r2, [r11, #-0x18]
   1ed64: e5922014     	ldr	r2, [r2, #0x14]
   1ed68: e2022080     	and	r2, r2, #128
   1ed6c: e1a023c2     	asr	r2, r2, #7
   1ed70: e6ef1072     	uxtb	r1, r2
   1ed74: e51b2018     	ldr	r2, [r11, #-0x18]
   1ed78: e5922014     	ldr	r2, [r2, #0x14]
   1ed7c: e2022c7f     	and	r2, r2, #32512
   1ed80: e1a02442     	asr	r2, r2, #8
   1ed84: e1a02082     	lsl	r2, r2, #1
   1ed88: e6ef2072     	uxtb	r2, r2
   1ed8c: e1812002     	orr	r2, r1, r2
   1ed90: e6ef2072     	uxtb	r2, r2
   1ed94: e6ef2072     	uxtb	r2, r2
   1ed98: e5c32000     	strb	r2, [r3]
   1ed9c: e51b3008     	ldr	r3, [r11, #-0x8]
   1eda0: e2832003     	add	r2, r3, #3
   1eda4: e51b3018     	ldr	r3, [r11, #-0x18]
   1eda8: e5933014     	ldr	r3, [r3, #0x14]
   1edac: e6ef3073     	uxtb	r3, r3
   1edb0: e203307f     	and	r3, r3, #127
   1edb4: e5c23000     	strb	r3, [r2]
   1edb8: e51b3008     	ldr	r3, [r11, #-0x8]
   1edbc: e2833004     	add	r3, r3, #4
   1edc0: e50b3008     	str	r3, [r11, #-0x8]
   1edc4: e51b3018     	ldr	r3, [r11, #-0x18]
   1edc8: e5933008     	ldr	r3, [r3, #0x8]
   1edcc: e1a03443     	asr	r3, r3, #8
   1edd0: e6ef2073     	uxtb	r2, r3
   1edd4: e51b3008     	ldr	r3, [r11, #-0x8]
   1edd8: e5c32000     	strb	r2, [r3]
   1eddc: e51b3008     	ldr	r3, [r11, #-0x8]
   1ede0: e2833001     	add	r3, r3, #1
   1ede4: e50b3008     	str	r3, [r11, #-0x8]
   1ede8: e51b3018     	ldr	r3, [r11, #-0x18]
   1edec: e5933008     	ldr	r3, [r3, #0x8]
   1edf0: e6ef2073     	uxtb	r2, r3
   1edf4: e51b3008     	ldr	r3, [r11, #-0x8]
   1edf8: e5c32000     	strb	r2, [r3]
   1edfc: e51b3008     	ldr	r3, [r11, #-0x8]
   1ee00: e2833001     	add	r3, r3, #1
   1ee04: e50b3008     	str	r3, [r11, #-0x8]
   1ee08: e24b302c     	sub	r3, r11, #44
   1ee0c: e51b0010     	ldr	r0, [r11, #-0x10]
   1ee10: e1a01003     	mov	r1, r3
   1ee14: e3a0200a     	mov	r2, #10
   1ee18: ebffb5bb     	bl	0xc50c <memcpy@plt>     @ imm = #-0x12914
   1ee1c: e51b3010     	ldr	r3, [r11, #-0x10]
   1ee20: e283300a     	add	r3, r3, #10
   1ee24: e50b3010     	str	r3, [r11, #-0x10]
   1ee28: e51b3018     	ldr	r3, [r11, #-0x18]
   1ee2c: e5932010     	ldr	r2, [r3, #0x10]
   1ee30: e51b3018     	ldr	r3, [r11, #-0x18]
   1ee34: e5933014     	ldr	r3, [r3, #0x14]
   1ee38: e51b0010     	ldr	r0, [r11, #-0x10]
   1ee3c: e1a01002     	mov	r1, r2
   1ee40: e1a02003     	mov	r2, r3
   1ee44: ebffb5b0     	bl	0xc50c <memcpy@plt>     @ imm = #-0x12940
   1ee48: e51b3018     	ldr	r3, [r11, #-0x18]
   1ee4c: e5933014     	ldr	r3, [r3, #0x14]
   1ee50: e51b2010     	ldr	r2, [r11, #-0x10]
   1ee54: e0823003     	add	r3, r2, r3
   1ee58: e50b3010     	str	r3, [r11, #-0x10]
   1ee5c: e51b300c     	ldr	r3, [r11, #-0xc]
   1ee60: e5933000     	ldr	r3, [r3]
   1ee64: e50b300c     	str	r3, [r11, #-0xc]
   1ee68: e51b300c     	ldr	r3, [r11, #-0xc]
   1ee6c: e5932000     	ldr	r2, [r3]
   1ee70: e51b300c     	ldr	r3, [r11, #-0xc]
   1ee74: e5832000     	str	r2, [r3]
   1ee78: e51b3030     	ldr	r3, [r11, #-0x30]
   1ee7c: e2832f4e     	add	r2, r3, #312
   1ee80: e51b300c     	ldr	r3, [r11, #-0xc]
   1ee84: e1520003     	cmp	r2, r3
   1ee88: 1affff82     	bne	0x1ec98 <id3_write_tag+0x1b0> @ imm = #-0x1f8
   1ee8c: e51b2010     	ldr	r2, [r11, #-0x10]
   1ee90: e51b3034     	ldr	r3, [r11, #-0x34]
   1ee94: e0633002     	rsb	r3, r3, r2
   1ee98: e1a00003     	mov	r0, r3
   1ee9c: e24bd004     	sub	sp, r11, #4
   1eea0: e8bd8800     	pop	{r11, pc}
   1eea4: a4 39 03 00  	.word	0x000339a4

