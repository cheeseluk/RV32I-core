# Step 6: the first program. Uses only the book's subset (lw sw R-type beq
# addi). Stores 1 to 0x100 on PASS and 0 on FAIL.
    .globl _start
_start:
      addi x1, x0, 5
      addi x2, x0, 7
      add  x3, x1, x2        # 12
      sub  x4, x2, x1        # 2
      sw   x3, 0x40(x0)
      lw   x5, 0x40(x0)
      beq  x5, x3, pass
fail: sw   x0, 0x100(x0)     # writes 0 = FAIL
      beq  x0, x0, done
pass: addi x6, x0, 1
      sw   x6, 0x100(x0)     # writes 1 = PASS
done: beq  x0, x0, done      # spin forever
