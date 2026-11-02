00027904 <find_output_format>:
   27904: e92d4800     	push	{r11, lr}
   27908: e28db004     	add	r11, sp, #4
   2790c: e24dd010     	sub	sp, sp, #16
   27910: e50b0010     	str	r0, [r11, #-0x10]
   27914: e3a03000     	mov	r3, #0
   27918: e50b300c     	str	r3, [r11, #-0xc]
   2791c: ea000012     	b	0x2796c <find_output_format+0x68> @ imm = #0x48
   27920: e51b200c     	ldr	r2, [r11, #-0xc]
   27924: e59f3064     	ldr	r3, [pc, #0x64]         @ 0x27990 <find_output_format+0x8c>
   27928: e7933102     	ldr	r3, [r3, r2, lsl #2]
   2792c: e12fff33     	blx	r3
   27930: e1a03000     	mov	r3, r0
   27934: e50b3008     	str	r3, [r11, #-0x8]
   27938: e51b3008     	ldr	r3, [r11, #-0x8]
   2793c: e5933004     	ldr	r3, [r3, #0x4]
   27940: e1a00003     	mov	r0, r3
   27944: e51b1010     	ldr	r1, [r11, #-0x10]
   27948: ebff927d     	bl	0xc344 <strcasecmp@plt> @ imm = #-0x1b60c
   2794c: e1a03000     	mov	r3, r0
   27950: e3530000     	cmp	r3, #0
   27954: 1a000001     	bne	0x27960 <find_output_format+0x5c> @ imm = #0x4
   27958: e51b3008     	ldr	r3, [r11, #-0x8]
   2795c: ea000008     	b	0x27984 <find_output_format+0x80> @ imm = #0x20
   27960: e51b300c     	ldr	r3, [r11, #-0xc]
   27964: e2833001     	add	r3, r3, #1
   27968: e50b300c     	str	r3, [r11, #-0xc]
   2796c: e51b200c     	ldr	r2, [r11, #-0xc]
   27970: e59f3018     	ldr	r3, [pc, #0x18]         @ 0x27990 <find_output_format+0x8c>
   27974: e7933102     	ldr	r3, [r3, r2, lsl #2]
   27978: e3530000     	cmp	r3, #0
   2797c: 1affffe7     	bne	0x27920 <find_output_format+0x1c> @ imm = #-0x64
   27980: e3a03000     	mov	r3, #0
   27984: e1a00003     	mov	r0, r3
   27988: e24bd004     	sub	sp, r11, #4
   2798c: e8bd8800     	pop	{r11, pc}
   27990: ec ee 03 00  	.word	0x0003eeec

