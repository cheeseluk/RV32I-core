// Minimal test environment for running riscv-tests on this core.
//
// It replaces riscv-tests' env/p/riscv_test.h, whose startup code uses CSR
// instructions this core doesn't have. Here the program just starts at
// _start (address 0). RVTEST_PASS / RVTEST_FAIL set gp (x3) to 1 on pass,
// or (test_number << 1) | 1 on fail, as before. They also store gp to
// 0x100, the result address core_tb and the FPGA board watch, then ecall,
// which halts the core.

#ifndef _ENV_RV32I_CORE_H
#define _ENV_RV32I_CORE_H

#define RVTEST_RV64U                                                    \
  .macro init;                                                          \
  .endm

// Its own copy: the rv32ui tests redefine RVTEST_RV64U as RVTEST_RV32U.
#define RVTEST_RV32U                                                    \
  .macro init;                                                          \
  .endm

#define TESTNUM gp

#define RVTEST_CODE_BEGIN                                               \
        .section .text.init;                                            \
        .globl _start;                                                  \
_start:                                                                 \
        init;

#define RVTEST_CODE_END                                                 \
        unimp

#define RVTEST_PASS                                                     \
        fence;                                                          \
        li TESTNUM, 1;                                                  \
        sw TESTNUM, 0x100(zero);                                        \
        li a7, 93;                                                      \
        li a0, 0;                                                       \
        ecall

#define RVTEST_FAIL                                                     \
        fence;                                                          \
1:      beqz TESTNUM, 1b;                                               \
        sll TESTNUM, TESTNUM, 1;                                        \
        or TESTNUM, TESTNUM, 1;                                         \
        sw TESTNUM, 0x100(zero);                                        \
        li a7, 93;                                                      \
        addi a0, TESTNUM, 0;                                            \
        ecall

#define EXTRA_DATA

#define RVTEST_DATA_BEGIN                                               \
        EXTRA_DATA                                                      \
        .align 4; .global begin_signature; begin_signature:

#define RVTEST_DATA_END .align 4; .global end_signature; end_signature:

#endif
