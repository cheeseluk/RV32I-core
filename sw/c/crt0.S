# Startup code for C programs on the core.
# Sets up the stack, zeroes .bss, calls main, and reports main's return
# value the same way riscv-tests do: gp = 1 on PASS (main returned 0), or
# (n << 1) | 1 for FAIL #n, then ecall halts the core.

#define STACK_TOP 0x4000         // top of the 16 KB dmem (core_tb MEM_WORDS)

    .section .text.init
    .globl _start
_start:
    li   sp, STACK_TOP

    # .bss isn't in the hex file and dmem starts out as X, so clear it
    la   t0, __bss_start
    la   t1, _end
1:  bgeu t0, t1, 2f
    sw   zero, 0(t0)
    addi t0, t0, 4
    j    1b

2:  call main

    li   gp, 1
    beqz a0, 3f
    slli gp, a0, 1
    ori  gp, gp, 1
3:  ecall
