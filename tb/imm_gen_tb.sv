`timescale 1ns/1ps

module imm_gen_tb;
    logic [31:0] inst, out;
    int errors = 0;

    imm_gen dut (.inst(inst), .out(out));

    task automatic check(input logic [31:0] t_inst, expected, input string asm);
        inst = t_inst;
        #1;
        if (out !== expected) begin
            $display("FAIL %-22s (%h) : got %h, expected %h", asm, inst, out, expected);
            errors++;
        end
    endtask

    // Encodings are from riscv64-unknown-elf-as -march=rv32i, so the
    // expected values don't depend on how imm_gen slices the bits.
    initial begin
        $dumpfile("imm_gen_tb.vcd");
        $dumpvars(0, imm_gen_tb);

        // I type
        check(32'h0050_0093, 32'h0000_0005, "addi x1, x0, 5");
        check(32'hffb0_0093, 32'hffff_fffb, "addi x1, x0, -5");
        check(32'h7ff0_0093, 32'h0000_07ff, "addi x1, x0, 2047");      // largest
        check(32'h8000_0093, 32'hffff_f800, "addi x1, x0, -2048");     // smallest
        check(32'h4031_5093, 32'h0000_0403, "srai x1, x2, 3");         // funct7 lands in imm[11:5]
        check(32'h0400_2283, 32'h0000_0040, "lw x5, 0x40(x0)");
        check(32'hfff1_0283, 32'hffff_ffff, "lb x5, -1(x2)");
        check(32'hffc2_80e7, 32'hffff_fffc, "jalr x1, -4(x5)");
        check(32'h0ff0_000f, 32'h0000_00ff, "fence");
        check(32'h0000_0073, 32'h0000_0000, "ecall");
        check(32'h0010_0073, 32'h0000_0001, "ebreak");

        // S type: imm is split across inst[31:25] and inst[11:7]
        check(32'h0430_2023, 32'h0000_0040, "sw x3, 0x40(x0)");
        check(32'hfe11_2e23, 32'hffff_fffc, "sw x1, -4(x2)");
        check(32'h7e11_0fa3, 32'h0000_07ff, "sb x1, 2047(x2)");
        check(32'h8011_1023, 32'hffff_f800, "sh x1, -2048(x2)");
        check(32'h5411_2aa3, 32'h0000_0555, "sw x1, 0x555(x2)");       // alternating bits catch
        check(32'h2a11_2523, 32'h0000_02aa, "sw x1, 0x2aa(x2)");       // swapped or shifted fields

        // B type: imm[12|10:5] in inst[31:25], imm[4:1|11] in inst[11:7]
        check(32'hfe00_0ce3, 32'hffff_fff8, "beq x0, x0, -8");
        check(32'h0020_9863, 32'h0000_0010, "bne x1, x2, 16");
        check(32'h7e20_cfe3, 32'h0000_0ffe, "blt x1, x2, 4094");       // largest
        check(32'h8020_d063, 32'hffff_f000, "bge x1, x2, -4096");      // smallest
        check(32'h0020_e0e3, 32'h0000_0800, "bltu x1, x2, 0x800");     // imm[11] alone, from inst[7]
        check(32'h2a20_f5e3, 32'h0000_0aaa, "bgeu x1, x2, 0xaaa");
        check(32'h5420_8a63, 32'h0000_0554, "beq x1, x2, 0x554");

        // U type
        check(32'h1234_50b7, 32'h1234_5000, "lui x1, 0x12345");
        check(32'hffff_f0b7, 32'hffff_f000, "lui x1, 0xfffff");
        check(32'h0000_00b7, 32'h0000_0000, "lui x1, 0");
        check(32'h8000_0097, 32'h8000_0000, "auipc x1, 0x80000");

        // J type: imm[20|10:1|11|19:12] in inst[31:12]
        check(32'hff9f_f06f, 32'hffff_fff8, "jal x0, -8");
        check(32'h0010_00ef, 32'h0000_0800, "jal x1, 0x800");          // imm[11] alone, from inst[20]
        check(32'h7fff_f0ef, 32'h000f_fffe, "jal x1, 0xffffe");        // largest
        check(32'h8000_00ef, 32'hfff0_0000, "jal x1, -0x100000");      // smallest
        check(32'h2aba_a0ef, 32'h000a_aaaa, "jal x1, 0xaaaaa");
        check(32'h5545_50ef, 32'h0005_5554, "jal x1, 0x55554");

        // R type has no immediate
        check(32'h0020_81b3, 32'h0000_0000, "add x3, x1, x2");
        check(32'h4031_50b3, 32'h0000_0000, "sra x1, x2, x3");

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
