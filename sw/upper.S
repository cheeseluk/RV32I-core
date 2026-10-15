# Step 7.4: lui and auipc.
#include "check.h"

    .globl _start
_start:
    lui  x5, 0x12345;   CHECK x5, 0x12345000
    lui  x5, 0xFFFFF;   CHECK x5, 0xFFFFF000
    lui  x5, 0;         CHECK x5, 0
    lui  x0, 0x12345;   CHECK x0, 0

    # lui + addi with a negative low part (what li does)
    lui  x5, 0x12346
    addi x5, x5, -0x800; CHECK x5, 0x12345800

    # auipc adds to its own pc
here1:
    auipc x5, 0
    ABS  x6, here1
    CHECKR x5, x6

here2:
    auipc x5, 0x1
    ABS  x6, here2
    li   x7, 0x1000
    add  x6, x6, x7
    CHECKR x5, x6

here3:
    auipc x5, 0xFFFFF        # pc - 0x1000, wraps below 0
    ABS  x6, here3
    li   x7, -0x1000
    add  x6, x6, x7
    CHECKR x5, x6

    jal  x0, pass
    RESULT
