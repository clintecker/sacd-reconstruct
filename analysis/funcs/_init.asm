0000c1ec <_init>:
    c1ec: e92d4010     	push	{r4, lr}
    c1f0: eb000196     	bl	0xc850 <call_gmon_start> @ imm = #0x658
    c1f4: e8bd8010     	pop	{r4, pc}

Disassembly of section .plt:

0000c1f8 <.plt>:
    c1f8: e52de004     	str	lr, [sp, #-0x4]!
    c1fc: e59fe004     	ldr	lr, [pc, #0x4]          @ 0xc208 <.plt+0x10>
    c200: e08fe00e     	add	lr, pc, lr
    c204: e5bef008     	ldr	pc, [lr, #0x8]!
    c208: ac 23 03 00  	.word	0x000323ac

0000c20c <getpgrp@plt>:
    c20c: e28fc600     	add	r12, pc, #0, #12
    c210: e28cca32     	add	r12, r12, #204800
    c214: e5bcf3ac     	ldr	pc, [r12, #0x3ac]!

0000c218 <strerror@plt>:
    c218: e28fc600     	add	r12, pc, #0, #12
    c21c: e28cca32     	add	r12, r12, #204800
    c220: e5bcf3a4     	ldr	pc, [r12, #0x3a4]!

0000c224 <mkdir@plt>:
    c224: e28fc600     	add	r12, pc, #0, #12
    c228: e28cca32     	add	r12, r12, #204800
    c22c: e5bcf39c     	ldr	pc, [r12, #0x39c]!

0000c230 <__sigsetjmp@plt>:
    c230: e28fc600     	add	r12, pc, #0, #12
    c234: e28cca32     	add	r12, r12, #204800
    c238: e5bcf394     	ldr	pc, [r12, #0x394]!

0000c23c <get_nprocs@plt>:
    c23c: e28fc600     	add	r12, pc, #0, #12
    c240: e28cca32     	add	r12, r12, #204800
    c244: e5bcf38c     	ldr	pc, [r12, #0x38c]!

0000c248 <abort@plt>:
    c248: e28fc600     	add	r12, pc, #0, #12
    c24c: e28cca32     	add	r12, r12, #204800
    c250: e5bcf384     	ldr	pc, [r12, #0x384]!

0000c254 <connect@plt>:
    c254: e28fc600     	add	r12, pc, #0, #12
    c258: e28cca32     	add	r12, r12, #204800
    c25c: e5bcf37c     	ldr	pc, [r12, #0x37c]!

0000c260 <localtime@plt>:
    c260: e28fc600     	add	r12, pc, #0, #12
    c264: e28cca32     	add	r12, r12, #204800
    c268: e5bcf374     	ldr	pc, [r12, #0x374]!

0000c26c <wcscpy@plt>:
    c26c: e28fc600     	add	r12, pc, #0, #12
    c270: e28cca32     	add	r12, r12, #204800
    c274: e5bcf36c     	ldr	pc, [r12, #0x36c]!

0000c278 <memcmp@plt>:
    c278: e28fc600     	add	r12, pc, #0, #12
    c27c: e28cca32     	add	r12, r12, #204800
    c280: e5bcf364     	ldr	pc, [r12, #0x364]!

0000c284 <pthread_attr_setdetachstate@plt>:
    c284: e28fc600     	add	r12, pc, #0, #12
    c288: e28cca32     	add	r12, r12, #204800
    c28c: e5bcf35c     	ldr	pc, [r12, #0x35c]!

0000c290 <pthread_exit@plt>:
    c290: e28fc600     	add	r12, pc, #0, #12
    c294: e28cca32     	add	r12, r12, #204800
    c298: e5bcf354     	ldr	pc, [r12, #0x354]!

0000c29c <__libc_start_main@plt>:
    c29c: e28fc600     	add	r12, pc, #0, #12
    c2a0: e28cca32     	add	r12, r12, #204800
    c2a4: e5bcf34c     	ldr	pc, [r12, #0x34c]!

0000c2a8 <fwide@plt>:
    c2a8: e28fc600     	add	r12, pc, #0, #12
    c2ac: e28cca32     	add	r12, r12, #204800
    c2b0: e5bcf344     	ldr	pc, [r12, #0x344]!

0000c2b4 <signal@plt>:
    c2b4: e28fc600     	add	r12, pc, #0, #12
    c2b8: e28cca32     	add	r12, r12, #204800
    c2bc: e5bcf33c     	ldr	pc, [r12, #0x33c]!

0000c2c0 <__gmon_start__@plt>:
    c2c0: e28fc600     	add	r12, pc, #0, #12
    c2c4: e28cca32     	add	r12, r12, #204800
    c2c8: e5bcf334     	ldr	pc, [r12, #0x334]!

0000c2cc <vsnprintf@plt>:
    c2cc: e28fc600     	add	r12, pc, #0, #12
    c2d0: e28cca32     	add	r12, r12, #204800
    c2d4: e5bcf32c     	ldr	pc, [r12, #0x32c]!

0000c2d8 <strncpy@plt>:
    c2d8: e28fc600     	add	r12, pc, #0, #12
    c2dc: e28cca32     	add	r12, r12, #204800
    c2e0: e5bcf324     	ldr	pc, [r12, #0x324]!

0000c2e4 <fclose@plt>:
    c2e4: e28fc600     	add	r12, pc, #0, #12
    c2e8: e28cca32     	add	r12, r12, #204800
    c2ec: e5bcf31c     	ldr	pc, [r12, #0x31c]!

0000c2f0 <vfwprintf@plt>:
    c2f0: e28fc600     	add	r12, pc, #0, #12
    c2f4: e28cca32     	add	r12, r12, #204800
    c2f8: e5bcf314     	ldr	pc, [r12, #0x314]!

0000c2fc <recv@plt>:
    c2fc: e28fc600     	add	r12, pc, #0, #12
    c300: e28cca32     	add	r12, r12, #204800
    c304: e5bcf30c     	ldr	pc, [r12, #0x30c]!

0000c308 <getenv@plt>:
    c308: e28fc600     	add	r12, pc, #0, #12
    c30c: e28cca32     	add	r12, r12, #204800
    c310: e5bcf304     	ldr	pc, [r12, #0x304]!

0000c314 <ftello64@plt>:
    c314: e28fc600     	add	r12, pc, #0, #12
    c318: e28cca32     	add	r12, r12, #204800
    c31c: e5bcf2fc     	ldr	pc, [r12, #0x2fc]!

0000c320 <system@plt>:
    c320: e28fc600     	add	r12, pc, #0, #12
    c324: e28cca32     	add	r12, r12, #204800
    c328: e5bcf2f4     	ldr	pc, [r12, #0x2f4]!

0000c32c <strchr@plt>:
    c32c: e28fc600     	add	r12, pc, #0, #12
    c330: e28cca32     	add	r12, r12, #204800
    c334: e5bcf2ec     	ldr	pc, [r12, #0x2ec]!

0000c338 <putchar@plt>:
    c338: e28fc600     	add	r12, pc, #0, #12
    c33c: e28cca32     	add	r12, r12, #204800
    c340: e5bcf2e4     	ldr	pc, [r12, #0x2e4]!

0000c344 <strcasecmp@plt>:
    c344: e28fc600     	add	r12, pc, #0, #12
    c348: e28cca32     	add	r12, r12, #204800
    c34c: e5bcf2dc     	ldr	pc, [r12, #0x2dc]!

0000c350 <listen@plt>:
    c350: e28fc600     	add	r12, pc, #0, #12
    c354: e28cca32     	add	r12, r12, #204800
    c358: e5bcf2d4     	ldr	pc, [r12, #0x2d4]!

0000c35c <calloc@plt>:
    c35c: e28fc600     	add	r12, pc, #0, #12
    c360: e28cca32     	add	r12, r12, #204800
    c364: e5bcf2cc     	ldr	pc, [r12, #0x2cc]!

0000c368 <memalign@plt>:
    c368: e28fc600     	add	r12, pc, #0, #12
    c36c: e28cca32     	add	r12, r12, #204800
    c370: e5bcf2c4     	ldr	pc, [r12, #0x2c4]!

0000c374 <pthread_cond_wait@plt>:
    c374: e28fc600     	add	r12, pc, #0, #12
    c378: e28cca32     	add	r12, r12, #204800
    c37c: e5bcf2bc     	ldr	pc, [r12, #0x2bc]!

0000c380 <sendto@plt>:
    c380: e28fc600     	add	r12, pc, #0, #12
    c384: e28cca32     	add	r12, r12, #204800
    c388: e5bcf2b4     	ldr	pc, [r12, #0x2b4]!

0000c38c <hstrerror@plt>:
    c38c: e28fc600     	add	r12, pc, #0, #12
    c390: e28cca32     	add	r12, r12, #204800
    c394: e5bcf2ac     	ldr	pc, [r12, #0x2ac]!

0000c398 <htons@plt>:
    c398: e28fc600     	add	r12, pc, #0, #12
    c39c: e28cca32     	add	r12, r12, #204800
    c3a0: e5bcf2a4     	ldr	pc, [r12, #0x2a4]!

0000c3a4 <memset@plt>:
    c3a4: e28fc600     	add	r12, pc, #0, #12
    c3a8: e28cca32     	add	r12, r12, #204800
    c3ac: e5bcf29c     	ldr	pc, [r12, #0x29c]!

0000c3b0 <strrchr@plt>:
    c3b0: e28fc600     	add	r12, pc, #0, #12
    c3b4: e28cca32     	add	r12, r12, #204800
    c3b8: e5bcf294     	ldr	pc, [r12, #0x294]!

0000c3bc <perror@plt>:
    c3bc: e28fc600     	add	r12, pc, #0, #12
    c3c0: e28cca32     	add	r12, r12, #204800
    c3c4: e5bcf28c     	ldr	pc, [r12, #0x28c]!

0000c3c8 <iconv@plt>:
    c3c8: e28fc600     	add	r12, pc, #0, #12
    c3cc: e28cca32     	add	r12, r12, #204800
    c3d0: e5bcf284     	ldr	pc, [r12, #0x284]!

0000c3d4 <chmod@plt>:
    c3d4: e28fc600     	add	r12, pc, #0, #12
    c3d8: e28cca32     	add	r12, r12, #204800
    c3dc: e5bcf27c     	ldr	pc, [r12, #0x27c]!

0000c3e0 <__assert_fail@plt>:
    c3e0: e28fc600     	add	r12, pc, #0, #12
    c3e4: e28cca32     	add	r12, r12, #204800
    c3e8: e5bcf274     	ldr	pc, [r12, #0x274]!

0000c3ec <tmpnam@plt>:
    c3ec: e28fc600     	add	r12, pc, #0, #12
    c3f0: e28cca32     	add	r12, r12, #204800
    c3f4: e5bcf26c     	ldr	pc, [r12, #0x26c]!

0000c3f8 <pthread_cond_broadcast@plt>:
    c3f8: e28fc600     	add	r12, pc, #0, #12
    c3fc: e28cca32     	add	r12, r12, #204800
    c400: e5bcf264     	ldr	pc, [r12, #0x264]!

0000c404 <__fxstat64@plt>:
    c404: e28fc600     	add	r12, pc, #0, #12
    c408: e28cca32     	add	r12, r12, #204800
    c40c: e5bcf25c     	ldr	pc, [r12, #0x25c]!

0000c410 <tcgetpgrp@plt>:
    c410: e28fc600     	add	r12, pc, #0, #12
    c414: e28cca32     	add	r12, r12, #204800
    c418: e5bcf254     	ldr	pc, [r12, #0x254]!

0000c41c <free@plt>:
    c41c: e28fc600     	add	r12, pc, #0, #12
    c420: e28cca32     	add	r12, r12, #204800
    c424: e5bcf24c     	ldr	pc, [r12, #0x24c]!

0000c428 <read@plt>:
    c428: e28fc600     	add	r12, pc, #0, #12
    c42c: e28cca32     	add	r12, r12, #204800
    c430: e5bcf244     	ldr	pc, [r12, #0x244]!

0000c434 <write@plt>:
    c434: e28fc600     	add	r12, pc, #0, #12
    c438: e28cca32     	add	r12, r12, #204800
    c43c: e5bcf23c     	ldr	pc, [r12, #0x23c]!

0000c440 <getopt_long@plt>:
    c440: e28fc600     	add	r12, pc, #0, #12
    c444: e28cca32     	add	r12, r12, #204800
    c448: e5bcf234     	ldr	pc, [r12, #0x234]!

0000c44c <wcslen@plt>:
    c44c: e28fc600     	add	r12, pc, #0, #12
    c450: e28cca32     	add	r12, r12, #204800
    c454: e5bcf22c     	ldr	pc, [r12, #0x22c]!

0000c458 <gettimeofday@plt>:
    c458: e28fc600     	add	r12, pc, #0, #12
    c45c: e28cca32     	add	r12, r12, #204800
    c460: e5bcf224     	ldr	pc, [r12, #0x224]!

0000c464 <fseek@plt>:
    c464: e28fc600     	add	r12, pc, #0, #12
    c468: e28cca32     	add	r12, r12, #204800
    c46c: e5bcf21c     	ldr	pc, [r12, #0x21c]!

0000c470 <accept@plt>:
    c470: e28fc600     	add	r12, pc, #0, #12
    c474: e28cca32     	add	r12, r12, #204800
    c478: e5bcf214     	ldr	pc, [r12, #0x214]!

0000c47c <pthread_mutex_unlock@plt>:
    c47c: e28fc600     	add	r12, pc, #0, #12
    c480: e28cca32     	add	r12, r12, #204800
    c484: e5bcf20c     	ldr	pc, [r12, #0x20c]!

0000c488 <socket@plt>:
    c488: e28fc600     	add	r12, pc, #0, #12
    c48c: e28cca32     	add	r12, r12, #204800
    c490: e5bcf204     	ldr	pc, [r12, #0x204]!

0000c494 <fflush@plt>:
    c494: e28fc600     	add	r12, pc, #0, #12
    c498: e28cca32     	add	r12, r12, #204800
    c49c: e5bcf1fc     	ldr	pc, [r12, #0x1fc]!

0000c4a0 <inet_aton@plt>:
    c4a0: e28fc600     	add	r12, pc, #0, #12
    c4a4: e28cca32     	add	r12, r12, #204800
    c4a8: e5bcf1f4     	ldr	pc, [r12, #0x1f4]!

0000c4ac <ioctl@plt>:
    c4ac: e28fc600     	add	r12, pc, #0, #12
    c4b0: e28cca32     	add	r12, r12, #204800
    c4b4: e5bcf1ec     	ldr	pc, [r12, #0x1ec]!

0000c4b8 <posix_memalign@plt>:
    c4b8: e28fc600     	add	r12, pc, #0, #12
    c4bc: e28cca32     	add	r12, r12, #204800
    c4c0: e5bcf1e4     	ldr	pc, [r12, #0x1e4]!

0000c4c4 <pthread_mutex_lock@plt>:
    c4c4: e28fc600     	add	r12, pc, #0, #12
    c4c8: e28cca32     	add	r12, r12, #204800
    c4cc: e5bcf1dc     	ldr	pc, [r12, #0x1dc]!

0000c4d0 <iconv_close@plt>:
    c4d0: e28fc600     	add	r12, pc, #0, #12
    c4d4: e28cca32     	add	r12, r12, #204800
    c4d8: e5bcf1d4     	ldr	pc, [r12, #0x1d4]!

0000c4dc <strlen@plt>:
    c4dc: e28fc600     	add	r12, pc, #0, #12
    c4e0: e28cca32     	add	r12, r12, #204800
    c4e4: e5bcf1cc     	ldr	pc, [r12, #0x1cc]!

0000c4e8 <sscanf@plt>:
    c4e8: e28fc600     	add	r12, pc, #0, #12
    c4ec: e28cca32     	add	r12, r12, #204800
    c4f0: e5bcf1c4     	ldr	pc, [r12, #0x1c4]!

0000c4f4 <unlink@plt>:
    c4f4: e28fc600     	add	r12, pc, #0, #12
    c4f8: e28cca32     	add	r12, r12, #204800
    c4fc: e5bcf1bc     	ldr	pc, [r12, #0x1bc]!

0000c500 <pthread_create@plt>:
    c500: e28fc600     	add	r12, pc, #0, #12
    c504: e28cca32     	add	r12, r12, #204800
    c508: e5bcf1b4     	ldr	pc, [r12, #0x1b4]!

0000c50c <memcpy@plt>:
    c50c: e28fc600     	add	r12, pc, #0, #12
    c510: e28cca32     	add	r12, r12, #204800
    c514: e5bcf1ac     	ldr	pc, [r12, #0x1ac]!

0000c518 <setlocale@plt>:
    c518: e28fc600     	add	r12, pc, #0, #12
    c51c: e28cca32     	add	r12, r12, #204800
    c520: e5bcf1a4     	ldr	pc, [r12, #0x1a4]!

0000c524 <__h_errno_location@plt>:
    c524: e28fc600     	add	r12, pc, #0, #12
    c528: e28cca32     	add	r12, r12, #204800
    c52c: e5bcf19c     	ldr	pc, [r12, #0x19c]!

0000c530 <fopen64@plt>:
    c530: e28fc600     	add	r12, pc, #0, #12
    c534: e28cca32     	add	r12, r12, #204800
    c538: e5bcf194     	ldr	pc, [r12, #0x194]!

0000c53c <strcpy@plt>:
    c53c: e28fc600     	add	r12, pc, #0, #12
    c540: e28cca32     	add	r12, r12, #204800
    c544: e5bcf18c     	ldr	pc, [r12, #0x18c]!

0000c548 <pthread_cond_destroy@plt>:
    c548: e28fc600     	add	r12, pc, #0, #12
    c54c: e28cca32     	add	r12, r12, #204800
    c550: e5bcf184     	ldr	pc, [r12, #0x184]!

0000c554 <pthread_equal@plt>:
    c554: e28fc600     	add	r12, pc, #0, #12
    c558: e28cca32     	add	r12, r12, #204800
    c55c: e5bcf17c     	ldr	pc, [r12, #0x17c]!

0000c560 <pthread_mutex_destroy@plt>:
    c560: e28fc600     	add	r12, pc, #0, #12
    c564: e28cca32     	add	r12, r12, #204800
    c568: e5bcf174     	ldr	pc, [r12, #0x174]!

0000c56c <printf@plt>:
    c56c: e28fc600     	add	r12, pc, #0, #12
    c570: e28cca32     	add	r12, r12, #204800
    c574: e5bcf16c     	ldr	pc, [r12, #0x16c]!

0000c578 <open64@plt>:
    c578: e28fc600     	add	r12, pc, #0, #12
    c57c: e28cca32     	add	r12, r12, #204800
    c580: e5bcf164     	ldr	pc, [r12, #0x164]!

0000c584 <raise@plt>:
    c584: e28fc600     	add	r12, pc, #0, #12
    c588: e28cca32     	add	r12, r12, #204800
    c58c: e5bcf15c     	ldr	pc, [r12, #0x15c]!

0000c590 <atoi@plt>:
    c590: e28fc600     	add	r12, pc, #0, #12
    c594: e28cca32     	add	r12, r12, #204800
    c598: e5bcf154     	ldr	pc, [r12, #0x154]!

0000c59c <gethostbyaddr@plt>:
    c59c: e28fc600     	add	r12, pc, #0, #12
    c5a0: e28cca32     	add	r12, r12, #204800
    c5a4: e5bcf14c     	ldr	pc, [r12, #0x14c]!

0000c5a8 <pthread_mutex_init@plt>:
    c5a8: e28fc600     	add	r12, pc, #0, #12
    c5ac: e28cca32     	add	r12, r12, #204800
    c5b0: e5bcf144     	ldr	pc, [r12, #0x144]!

0000c5b4 <shutdown@plt>:
    c5b4: e28fc600     	add	r12, pc, #0, #12
    c5b8: e28cca32     	add	r12, r12, #204800
    c5bc: e5bcf13c     	ldr	pc, [r12, #0x13c]!

0000c5c0 <bind@plt>:
    c5c0: e28fc600     	add	r12, pc, #0, #12
    c5c4: e28cca32     	add	r12, r12, #204800
    c5c8: e5bcf134     	ldr	pc, [r12, #0x134]!

0000c5cc <strstr@plt>:
    c5cc: e28fc600     	add	r12, pc, #0, #12
    c5d0: e28cca32     	add	r12, r12, #204800
    c5d4: e5bcf12c     	ldr	pc, [r12, #0x12c]!

0000c5d8 <select@plt>:
    c5d8: e28fc600     	add	r12, pc, #0, #12
    c5dc: e28cca32     	add	r12, r12, #204800
    c5e0: e5bcf124     	ldr	pc, [r12, #0x124]!

0000c5e4 <close@plt>:
    c5e4: e28fc600     	add	r12, pc, #0, #12
    c5e8: e28cca32     	add	r12, r12, #204800
    c5ec: e5bcf11c     	ldr	pc, [r12, #0x11c]!

0000c5f0 <fwrite@plt>:
    c5f0: e28fc600     	add	r12, pc, #0, #12
    c5f4: e28cca32     	add	r12, r12, #204800
    c5f8: e5bcf114     	ldr	pc, [r12, #0x114]!

0000c5fc <pthread_attr_setstacksize@plt>:
    c5fc: e28fc600     	add	r12, pc, #0, #12
    c600: e28cca32     	add	r12, r12, #204800
    c604: e5bcf10c     	ldr	pc, [r12, #0x10c]!

0000c608 <remove@plt>:
    c608: e28fc600     	add	r12, pc, #0, #12
    c60c: e28cca32     	add	r12, r12, #204800
    c610: e5bcf104     	ldr	pc, [r12, #0x104]!

0000c614 <time@plt>:
    c614: e28fc600     	add	r12, pc, #0, #12
    c618: e28cca32     	add	r12, r12, #204800
    c61c: e5bcf0fc     	ldr	pc, [r12, #0xfc]!

0000c620 <setvbuf@plt>:
    c620: e28fc600     	add	r12, pc, #0, #12
    c624: e28cca32     	add	r12, r12, #204800
    c628: e5bcf0f4     	ldr	pc, [r12, #0xf4]!

0000c62c <__ctype_b_loc@plt>:
    c62c: e28fc600     	add	r12, pc, #0, #12
    c630: e28cca32     	add	r12, r12, #204800
    c634: e5bcf0ec     	ldr	pc, [r12, #0xec]!

0000c638 <__xstat64@plt>:
    c638: e28fc600     	add	r12, pc, #0, #12
    c63c: e28cca32     	add	r12, r12, #204800
    c640: e5bcf0e4     	ldr	pc, [r12, #0xe4]!

0000c644 <fprintf@plt>:
    c644: e28fc600     	add	r12, pc, #0, #12
    c648: e28cca32     	add	r12, r12, #204800
    c64c: e5bcf0dc     	ldr	pc, [r12, #0xdc]!

0000c650 <strdup@plt>:
    c650: e28fc600     	add	r12, pc, #0, #12
    c654: e28cca32     	add	r12, r12, #204800
    c658: e5bcf0d4     	ldr	pc, [r12, #0xd4]!

0000c65c <lseek64@plt>:
    c65c: e28fc600     	add	r12, pc, #0, #12
    c660: e28cca32     	add	r12, r12, #204800
    c664: e5bcf0cc     	ldr	pc, [r12, #0xcc]!

0000c668 <malloc@plt>:
    c668: e28fc600     	add	r12, pc, #0, #12
    c66c: e28cca32     	add	r12, r12, #204800
    c670: e5bcf0c4     	ldr	pc, [r12, #0xc4]!

0000c674 <freopen64@plt>:
    c674: e28fc600     	add	r12, pc, #0, #12
    c678: e28cca32     	add	r12, r12, #204800
    c67c: e5bcf0bc     	ldr	pc, [r12, #0xbc]!

0000c680 <sigaction@plt>:
    c680: e28fc600     	add	r12, pc, #0, #12
    c684: e28cca32     	add	r12, r12, #204800
    c688: e5bcf0b4     	ldr	pc, [r12, #0xb4]!

0000c68c <chdir@plt>:
    c68c: e28fc600     	add	r12, pc, #0, #12
    c690: e28cca32     	add	r12, r12, #204800
    c694: e5bcf0ac     	ldr	pc, [r12, #0xac]!

0000c698 <pthread_attr_init@plt>:
    c698: e28fc600     	add	r12, pc, #0, #12
    c69c: e28cca32     	add	r12, r12, #204800
    c6a0: e5bcf0a4     	ldr	pc, [r12, #0xa4]!

0000c6a4 <getmntent@plt>:
    c6a4: e28fc600     	add	r12, pc, #0, #12
    c6a8: e28cca32     	add	r12, r12, #204800
    c6ac: e5bcf09c     	ldr	pc, [r12, #0x9c]!

0000c6b0 <fputc@plt>:
    c6b0: e28fc600     	add	r12, pc, #0, #12
    c6b4: e28cca32     	add	r12, r12, #204800
    c6b8: e5bcf094     	ldr	pc, [r12, #0x94]!

0000c6bc <strtok@plt>:
    c6bc: e28fc600     	add	r12, pc, #0, #12
    c6c0: e28cca32     	add	r12, r12, #204800
    c6c4: e5bcf08c     	ldr	pc, [r12, #0x8c]!

0000c6c8 <getcwd@plt>:
    c6c8: e28fc600     	add	r12, pc, #0, #12
    c6cc: e28cca32     	add	r12, r12, #204800
    c6d0: e5bcf084     	ldr	pc, [r12, #0x84]!

0000c6d4 <sleep@plt>:
    c6d4: e28fc600     	add	r12, pc, #0, #12
    c6d8: e28cca32     	add	r12, r12, #204800
    c6dc: e5bcf07c     	ldr	pc, [r12, #0x7c]!

0000c6e0 <send@plt>:
    c6e0: e28fc600     	add	r12, pc, #0, #12
    c6e4: e28cca32     	add	r12, r12, #204800
    c6e8: e5bcf074     	ldr	pc, [r12, #0x74]!

0000c6ec <memmove@plt>:
    c6ec: e28fc600     	add	r12, pc, #0, #12
    c6f0: e28cca32     	add	r12, r12, #204800
    c6f4: e5bcf06c     	ldr	pc, [r12, #0x6c]!

0000c6f8 <fcntl@plt>:
    c6f8: e28fc600     	add	r12, pc, #0, #12
    c6fc: e28cca32     	add	r12, r12, #204800
    c700: e5bcf064     	ldr	pc, [r12, #0x64]!

0000c704 <fwprintf@plt>:
    c704: e28fc600     	add	r12, pc, #0, #12
    c708: e28cca32     	add	r12, r12, #204800
    c70c: e5bcf05c     	ldr	pc, [r12, #0x5c]!

0000c710 <htonl@plt>:
    c710: e28fc600     	add	r12, pc, #0, #12
    c714: e28cca32     	add	r12, r12, #204800
    c718: e5bcf054     	ldr	pc, [r12, #0x54]!

0000c71c <pthread_attr_destroy@plt>:
    c71c: e28fc600     	add	r12, pc, #0, #12
    c720: e28cca32     	add	r12, r12, #204800
    c724: e5bcf04c     	ldr	pc, [r12, #0x4c]!

0000c728 <__pthread_register_cancel@plt>:
    c728: e28fc600     	add	r12, pc, #0, #12
    c72c: e28cca32     	add	r12, r12, #204800
    c730: e5bcf044     	ldr	pc, [r12, #0x44]!

0000c734 <__pthread_unregister_cancel@plt>:
    c734: e28fc600     	add	r12, pc, #0, #12
    c738: e28cca32     	add	r12, r12, #204800
    c73c: e5bcf03c     	ldr	pc, [r12, #0x3c]!

0000c740 <snprintf@plt>:
    c740: e28fc600     	add	r12, pc, #0, #12
    c744: e28cca32     	add	r12, r12, #204800
    c748: e5bcf034     	ldr	pc, [r12, #0x34]!

0000c74c <fread@plt>:
    c74c: e28fc600     	add	r12, pc, #0, #12
    c750: e28cca32     	add	r12, r12, #204800
    c754: e5bcf02c     	ldr	pc, [r12, #0x2c]!

0000c758 <fchdir@plt>:
    c758: e28fc600     	add	r12, pc, #0, #12
    c75c: e28cca32     	add	r12, r12, #204800
    c760: e5bcf024     	ldr	pc, [r12, #0x24]!

0000c764 <pthread_cond_init@plt>:
    c764: e28fc600     	add	r12, pc, #0, #12
    c768: e28cca32     	add	r12, r12, #204800
    c76c: e5bcf01c     	ldr	pc, [r12, #0x1c]!

0000c770 <strncmp@plt>:
    c770: e28fc600     	add	r12, pc, #0, #12
    c774: e28cca32     	add	r12, r12, #204800
    c778: e5bcf014     	ldr	pc, [r12, #0x14]!

0000c77c <gethostbyname@plt>:
    c77c: e28fc600     	add	r12, pc, #0, #12
    c780: e28cca32     	add	r12, r12, #204800
    c784: e5bcf00c     	ldr	pc, [r12, #0xc]!

0000c788 <realloc@plt>:
    c788: e28fc600     	add	r12, pc, #0, #12
    c78c: e28cca32     	add	r12, r12, #204800
    c790: e5bcf004     	ldr	pc, [r12, #0x4]!

0000c794 <iconv_open@plt>:
    c794: e28fc600     	add	r12, pc, #0, #12
    c798: e28cca31     	add	r12, r12, #200704
    c79c: e5bcfffc     	ldr	pc, [r12, #0xffc]!

0000c7a0 <recvfrom@plt>:
    c7a0: e28fc600     	add	r12, pc, #0, #12
    c7a4: e28cca31     	add	r12, r12, #200704
    c7a8: e5bcfff4     	ldr	pc, [r12, #0xff4]!

0000c7ac <setenv@plt>:
    c7ac: e28fc600     	add	r12, pc, #0, #12
    c7b0: e28cca31     	add	r12, r12, #200704
    c7b4: e5bcffec     	ldr	pc, [r12, #0xfec]!

0000c7b8 <strcmp@plt>:
    c7b8: e28fc600     	add	r12, pc, #0, #12
    c7bc: e28cca31     	add	r12, r12, #200704
    c7c0: e5bcffe4     	ldr	pc, [r12, #0xfe4]!

0000c7c4 <exit@plt>:
    c7c4: e28fc600     	add	r12, pc, #0, #12
    c7c8: e28cca31     	add	r12, r12, #200704
    c7cc: e5bcffdc     	ldr	pc, [r12, #0xfdc]!

0000c7d0 <__pthread_unwind_next@plt>:
    c7d0: e28fc600     	add	r12, pc, #0, #12
    c7d4: e28cca31     	add	r12, r12, #200704
    c7d8: e5bcffd4     	ldr	pc, [r12, #0xfd4]!

0000c7dc <__errno_location@plt>:
    c7dc: e28fc600     	add	r12, pc, #0, #12
    c7e0: e28cca31     	add	r12, r12, #200704
    c7e4: e5bcffcc     	ldr	pc, [r12, #0xfcc]!

0000c7e8 <pthread_self@plt>:
    c7e8: e28fc600     	add	r12, pc, #0, #12
    c7ec: e28cca31     	add	r12, r12, #200704
    c7f0: e5bcffc4     	ldr	pc, [r12, #0xfc4]!

0000c7f4 <pthread_cancel@plt>:
    c7f4: e28fc600     	add	r12, pc, #0, #12
    c7f8: e28cca31     	add	r12, r12, #200704
    c7fc: e5bcffbc     	ldr	pc, [r12, #0xfbc]!

0000c800 <sprintf@plt>:
    c800: e28fc600     	add	r12, pc, #0, #12
    c804: e28cca31     	add	r12, r12, #200704
    c808: e5bcffb4     	ldr	pc, [r12, #0xfb4]!
    c80c: e28fc600     	add	r12, pc, #0, #12
    c810: e28cca31     	add	r12, r12, #200704
    c814: e5bcffac     	ldr	pc, [r12, #0xfac]!

Disassembly of section .text:

