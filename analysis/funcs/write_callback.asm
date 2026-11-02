000205f0 <write_callback>:
   205f0: e92d4800     	push	{r11, lr}
   205f4: e28db004     	add	r11, sp, #4
   205f8: e24dd028     	sub	sp, sp, #40
   205fc: e50b0018     	str	r0, [r11, #-0x18]
   20600: e50b101c     	str	r1, [r11, #-0x1c]
   20604: e50b2020     	str	r2, [r11, #-0x20]
   20608: e51b3018     	ldr	r3, [r11, #-0x18]
   2060c: e5933004     	ldr	r3, [r3, #0x4]
   20610: e50b3008     	str	r3, [r11, #-0x8]
   20614: e24b3010     	sub	r3, r11, #16
   20618: e3a02000     	mov	r2, #0
   2061c: e58d2000     	str	r2, [sp]
   20620: e3a02000     	mov	r2, #0
   20624: e58d2004     	str	r2, [sp, #0x4]
   20628: e51b0008     	ldr	r0, [r11, #-0x8]
   2062c: e51b101c     	ldr	r1, [r11, #-0x1c]
   20630: e51b2020     	ldr	r2, [r11, #-0x20]
   20634: ebffca1d     	bl	0x12eb0 <socket_send>   @ imm = #-0xd78c
   20638: e1a03000     	mov	r3, r0
   2063c: e3530000     	cmp	r3, #0
   20640: 1a000005     	bne	0x2065c <write_callback+0x6c> @ imm = #0x14
   20644: e51b2010     	ldr	r2, [r11, #-0x10]
   20648: e51b3020     	ldr	r3, [r11, #-0x20]
   2064c: e1520003     	cmp	r2, r3
   20650: 1a000001     	bne	0x2065c <write_callback+0x6c> @ imm = #0x4
   20654: e3a03001     	mov	r3, #1
   20658: ea000000     	b	0x20660 <write_callback+0x70> @ imm = #0x0
   2065c: e3a03000     	mov	r3, #0
   20660: e54b3009     	strb	r3, [r11, #-0x9]
   20664: e55b3009     	ldrb	r3, [r11, #-0x9]
   20668: e1a00003     	mov	r0, r3
   2066c: e24bd004     	sub	sp, r11, #4
   20670: e8bd8800     	pop	{r11, pc}

