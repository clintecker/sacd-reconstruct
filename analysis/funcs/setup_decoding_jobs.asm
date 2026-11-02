0001a934 <setup_decoding_jobs>:
   1a934: e92d4800     	push	{r11, lr}
   1a938: e28db004     	add	r11, sp, #4
   1a93c: e24dd008     	sub	sp, sp, #8
   1a940: e50b0008     	str	r0, [r11, #-0x8]
   1a944: e51b3008     	ldr	r3, [r11, #-0x8]
   1a948: e5933034     	ldr	r3, [r3, #0x34]
   1a94c: e3530000     	cmp	r3, #0
   1a950: 1a000024     	bne	0x1a9e8 <setup_decoding_jobs+0xb4> @ imm = #0x90
   1a954: e3a00000     	mov	r0, #0
   1a958: ebffeb70     	bl	0x15720 <new_lock>      @ imm = #-0x5240
   1a95c: e1a02000     	mov	r2, r0
   1a960: e51b3008     	ldr	r3, [r11, #-0x8]
   1a964: e5832034     	str	r2, [r3, #0x34]
   1a968: e51b3008     	ldr	r3, [r11, #-0x8]
   1a96c: e3a02000     	mov	r2, #0
   1a970: e5832038     	str	r2, [r3, #0x38]
   1a974: e51b3008     	ldr	r3, [r11, #-0x8]
   1a978: e2832038     	add	r2, r3, #56
   1a97c: e51b3008     	ldr	r3, [r11, #-0x8]
   1a980: e583203c     	str	r2, [r3, #0x3c]
   1a984: e3e00000     	mvn	r0, #0
   1a988: ebffeb64     	bl	0x15720 <new_lock>      @ imm = #-0x5270
   1a98c: e1a02000     	mov	r2, r0
   1a990: e51b3008     	ldr	r3, [r11, #-0x8]
   1a994: e5832040     	str	r2, [r3, #0x40]
   1a998: e51b3008     	ldr	r3, [r11, #-0x8]
   1a99c: e3a02000     	mov	r2, #0
   1a9a0: e5832044     	str	r2, [r3, #0x44]
   1a9a4: e51b3008     	ldr	r3, [r11, #-0x8]
   1a9a8: e283200c     	add	r2, r3, #12
   1a9ac: e51b3008     	ldr	r3, [r11, #-0x8]
   1a9b0: e5933000     	ldr	r3, [r3]
   1a9b4: e1a03083     	lsl	r3, r3, #1
   1a9b8: e2833002     	add	r3, r3, #2
   1a9bc: e1a00002     	mov	r0, r2
   1a9c0: e3a01801     	mov	r1, #65536
   1a9c4: e1a02003     	mov	r2, r3
   1a9c8: ebffedaf     	bl	0x1608c <buffer_pool_create> @ imm = #-0x4944
   1a9cc: e51b3008     	ldr	r3, [r11, #-0x8]
   1a9d0: e2833020     	add	r3, r3, #32
   1a9d4: e1a00003     	mov	r0, r3
   1a9d8: e3a01801     	mov	r1, #65536
   1a9dc: e3e02000     	mvn	r2, #0
   1a9e0: ebffeda9     	bl	0x1608c <buffer_pool_create> @ imm = #-0x495c
   1a9e4: ea000000     	b	0x1a9ec <setup_decoding_jobs+0xb8> @ imm = #0x0
   1a9e8: e1a00000     	mov	r0, r0
   1a9ec: e24bd004     	sub	sp, r11, #4
   1a9f0: e8bd8800     	pop	{r11, pc}

