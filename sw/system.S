# Step 7.6: fence is a NOP, and ebreak halts the core.
# This one reports through the halt path (like riscv-tests): gp = 1 on PASS.
#include "check.h"

    .globl _start
_start:
    li   x5, 42
    fence
    fence rw, rw
    CHECK x5, 42             # nothing changed

    li   gp, 1
    ebreak
    jal  x0, fail            # never reached: the core stops at ebreak

fail:
    slli gp, x28, 1
    ori  gp, gp, 1
    ebreak
