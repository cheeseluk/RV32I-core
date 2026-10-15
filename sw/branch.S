# Step 7.2: all six branches, taken and not taken, with signed/unsigned
# edge cases and a backward branch.
#include "check.h"

// The branch must jump over the "jal fail"
.macro TAKEN br, r1, r2
    addi x28, x28, 1
    \br  \r1, \r2, 201f
    jal  x0, fail
201:
.endm

// The branch must fall through
.macro NOT_TAKEN br, r1, r2
    addi x28, x28, 1
    \br  \r1, \r2, fail
.endm

    .globl _start
_start:
    li   x1, 0x80000000      # most negative / large unsigned
    li   x2, 0x7FFFFFFF
    li   x3, -1
    li   x4, 5
    li   x5, 5

    TAKEN     beq,  x4, x5
    NOT_TAKEN beq,  x4, x3
    TAKEN     beq,  x0, x0
    TAKEN     bne,  x4, x3
    NOT_TAKEN bne,  x4, x5

    TAKEN     blt,  x3, x4       # -1 < 5
    NOT_TAKEN blt,  x4, x3
    NOT_TAKEN blt,  x4, x5       # equal is not less
    TAKEN     blt,  x1, x2
    TAKEN     bge,  x4, x3
    TAKEN     bge,  x4, x5       # equal
    NOT_TAKEN bge,  x1, x2

    TAKEN     bltu, x4, x3       # 5 < 0xFFFFFFFF
    NOT_TAKEN bltu, x3, x4
    NOT_TAKEN bltu, x4, x5
    TAKEN     bltu, x2, x1
    TAKEN     bgeu, x3, x4
    TAKEN     bgeu, x4, x5
    NOT_TAKEN bgeu, x2, x1

    # Backward branch: count x10 down from 5, x11 counts iterations
    li   x10, 5
    li   x11, 0
loop:
    addi x11, x11, 1
    addi x10, x10, -1
    bne  x10, x0, loop
    CHECK x11, 5

    jal  x0, pass
    RESULT
