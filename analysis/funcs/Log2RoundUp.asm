000179ec <Log2RoundUp>:
   179ec: e52db004     	str	r11, [sp, #-0x4]!
   179f0: e28db000     	add	r11, sp, #0
   179f4: e24dd014     	sub	sp, sp, #20
   179f8: e50b0010     	str	r0, [r11, #-0x10]
   179fc: e3a03000     	mov	r3, #0
   17a00: e50b3008     	str	r3, [r11, #-0x8]
   17a04: ea000002     	b	0x17a14 <Log2RoundUp+0x28> @ imm = #0x8
   17a08: e51b3008     	ldr	r3, [r11, #-0x8]
   17a0c: e2833001     	add	r3, r3, #1
   17a10: e50b3008     	str	r3, [r11, #-0x8]
   17a14: e3a02001     	mov	r2, #1
   17a18: e51b3008     	ldr	r3, [r11, #-0x8]
   17a1c: e1a02312     	lsl	r2, r2, r3
   17a20: e51b3010     	ldr	r3, [r11, #-0x10]
   17a24: e1520003     	cmp	r2, r3
   17a28: dafffff6     	ble	0x17a08 <Log2RoundUp+0x1c> @ imm = #-0x28
   17a2c: e51b3008     	ldr	r3, [r11, #-0x8]
   17a30: e1a00003     	mov	r0, r3
   17a34: e28bd000     	add	sp, r11, #0
   17a38: e8bd0800     	ldm	sp!, {r11}
   17a3c: e12fff1e     	bx	lr

