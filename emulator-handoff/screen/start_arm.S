/* ARM EABI glibc startup for a C main with no executable constructors.
 * SPDX-License-Identifier: GPL-2.0-or-later */
.syntax unified
.arm
.text
.global _start
.type _start, %function
_start:
    mov fp, #0
    mov lr, #0
    pop {r1}
    mov r2, sp
    push {r2}
    push {r0}
    mov ip, #0
    push {ip}
    mov r3, #0
    ldr r0, =main
    bl __libc_start_main
    bl abort
.size _start, .-_start
.ltorg
.section .note.GNU-stack,"",%progbits
