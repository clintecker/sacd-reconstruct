0001350c <socket_hoststrerror>:
   1350c: e92d4800     	push	{r11, lr}
   13510: e28db004     	add	r11, sp, #4
   13514: e24dd008     	sub	sp, sp, #8
   13518: e50b0008     	str	r0, [r11, #-0x8]
   1351c: e51b3008     	ldr	r3, [r11, #-0x8]
   13520: e3530000     	cmp	r3, #0
   13524: ca000003     	bgt	0x13538 <socket_hoststrerror+0x2c> @ imm = #0xc
   13528: e51b0008     	ldr	r0, [r11, #-0x8]
   1352c: eb000053     	bl	0x13680 <io_strerror>   @ imm = #0x14c
   13530: e1a03000     	mov	r3, r0
   13534: ea000007     	b	0x13558 <socket_hoststrerror+0x4c> @ imm = #0x1c
   13538: e51b3008     	ldr	r3, [r11, #-0x8]
   1353c: e3530001     	cmp	r3, #1
   13540: 1a000001     	bne	0x1354c <socket_hoststrerror+0x40> @ imm = #0x4
   13544: e59f3018     	ldr	r3, [pc, #0x18]         @ 0x13564 <socket_hoststrerror+0x58>
   13548: ea000002     	b	0x13558 <socket_hoststrerror+0x4c> @ imm = #0x8
   1354c: e51b0008     	ldr	r0, [r11, #-0x8]
   13550: ebffe38d     	bl	0xc38c <hstrerror@plt>  @ imm = #-0x71cc
   13554: e1a03000     	mov	r3, r0
   13558: e1a00003     	mov	r0, r3
   1355c: e24bd004     	sub	sp, r11, #4
   13560: e8bd8800     	pop	{r11, pc}
   13564: 4c 28 03 00  	.word	0x0003284c

