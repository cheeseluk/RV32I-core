# Step 7.1: every R-type and I-type ALU instruction.
#include "check.h"

    .globl _start
_start:
    li   x1, 0x80000000      # most negative
    li   x2, 0x7FFFFFFF      # most positive
    li   x3, -1
    li   x4, 5
    li   x5, 33              # shift amount > 31: only the low 5 bits count

    # ---- R-type ----
    add  x10, x4, x4;   CHECK x10, 10
    add  x10, x2, x4;   CHECK x10, 0x80000004   # signed overflow wraps
    sub  x10, x4, x3;   CHECK x10, 6
    sub  x10, x0, x4;   CHECK x10, -5
    sll  x10, x4, x5;   CHECK x10, 10           # 5 << 1
    sll  x10, x3, x4;   CHECK x10, 0xFFFFFFE0
    slt  x10, x3, x4;   CHECK x10, 1            # -1 < 5 signed
    slt  x10, x4, x3;   CHECK x10, 0
    slt  x10, x1, x2;   CHECK x10, 1
    sltu x10, x3, x4;   CHECK x10, 0            # 0xFFFFFFFF > 5 unsigned
    sltu x10, x4, x3;   CHECK x10, 1
    sltu x10, x0, x4;   CHECK x10, 1            # snez
    xor  x10, x3, x4;   CHECK x10, 0xFFFFFFFA
    srl  x10, x1, x4;   CHECK x10, 0x04000000
    srl  x10, x3, x5;   CHECK x10, 0x7FFFFFFF   # shift by 33 = shift by 1
    sra  x10, x1, x4;   CHECK x10, 0xFC000000   # sign bit copied in
    sra  x10, x2, x4;   CHECK x10, 0x03FFFFFF
    or   x10, x1, x4;   CHECK x10, 0x80000005
    and  x10, x3, x4;   CHECK x10, 5
    and  x10, x1, x2;   CHECK x10, 0

    # ---- I-type ----
    addi x10, x4, -6;   CHECK x10, -1           # negative imm: must not become sub
    addi x10, x0, -2048; CHECK x10, -2048
    addi x10, x2, 1;    CHECK x10, 0x80000000
    slti x10, x3, 0;    CHECK x10, 1
    slti x10, x4, -1;   CHECK x10, 0
    sltiu x10, x4, -1;  CHECK x10, 1            # imm sign-extends to 0xFFFFFFFF
    sltiu x10, x0, 1;   CHECK x10, 1            # seqz
    xori x10, x4, -1;   CHECK x10, -6           # not
    ori  x10, x1, 0x7FF; CHECK x10, 0x800007FF
    andi x10, x3, 0x0F0; CHECK x10, 0xF0
    andi x10, x3, -16;  CHECK x10, 0xFFFFFFF0
    slli x10, x4, 31;   CHECK x10, 0x80000000
    srli x10, x1, 31;   CHECK x10, 1
    srli x10, x3, 4;    CHECK x10, 0x0FFFFFFF
    srai x10, x1, 31;   CHECK x10, -1
    srai x10, x2, 30;   CHECK x10, 1

    # ---- x0 is never written ----
    addi x0, x0, 5;     CHECK x0, 0
    add  x0, x4, x4;    CHECK x0, 0

    jal  x0, pass
    RESULT
