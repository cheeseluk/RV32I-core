# Step 7.3: jal and jalr, including the link value, clearing bit 0 of the
# jalr target, and jalr with rd == rs1.
#include "check.h"

    .globl _start
_start:
    # jal forward: x1 = address after the jal
    jal  x1, 1f
after_jal:
    jal  x0, fail
1:  ABS  x5, after_jal
    CHECKR x1, x5

    # jal backward
    jal  x0, 3f
2:  jal  x0, 4f              # lands here from below, then skips ahead
3:  jal  x0, 2b
4:
    # jal with rd = x0 does not write x0
    jal  x0, 5f
5:  CHECK x0, 0

    # call / return through jalr
    li   x10, 0
    ABS  x6, func
    jalr x1, 0(x6)
after_call:
    CHECK x10, 1             # func ran
    ABS  x5, after_call
    CHECKR x1, x5            # link = pc + 4

    # jalr with an offset
    ABS  x6, func
    addi x6, x6, -8
    jalr x1, 8(x6)
    CHECK x10, 2

    # jalr to an odd address: bit 0 is cleared
    ABS  x6, func
    addi x6, x6, 1
    jalr x1, 0(x6)
    CHECK x10, 3

    # jalr with rd == rs1: the target uses the old value
    ABS  x7, func2
    jalr x7, 0(x7)
after_self:
    ABS  x5, after_self
    CHECKR x7, x5
    CHECK x11, 1

    jal  x0, pass

func:                        # x10++ and return
    addi x10, x10, 1
    jalr x0, 0(x1)

func2:                       # x11 = 1 and return through x7
    li   x11, 1
    jalr x0, 0(x7)

    RESULT
