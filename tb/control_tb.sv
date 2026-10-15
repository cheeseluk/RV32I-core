`timescale 1ns/1ps

module control_tb;
    import riscv_pkg::*;

    logic [31:0] inst;
    logic        reg_write, alu_src_a, alu_src_b, mem_write;
    logic [1:0]  result_src;
    logic        branch, jump, jalr, halt, illegal;
    alu_op_e     alu_op;
    int errors = 0;

    control dut (.inst(inst), .reg_write(reg_write), .alu_op(alu_op),
                 .alu_src_a(alu_src_a), .alu_src_b(alu_src_b), .mem_write(mem_write),
                 .result_src(result_src), .branch(branch), .jump(jump), .jalr(jalr),
                 .halt(halt), .illegal(illegal));

    // Expected outputs, in this order (one row of the plan's control table):
    // reg_write alu_src_a alu_src_b mem_write result_src branch jump jalr halt illegal
    task automatic check(input logic [31:0] t_inst, input string name,
                         input alu_op_e e_op, input logic [10:0] e_sig);
        logic [10:0] sig;
        alu_op_e     op;      // a variable copy: iverilog can't call .name() on a port
        inst = t_inst;
        #1;
        op  = alu_op;
        sig = {reg_write, alu_src_a, alu_src_b, mem_write, result_src,
               branch, jump, jalr, halt, illegal};
        if (sig !== e_sig || op !== e_op) begin
            $display("FAIL %-16s inst=%h : got op=%-6s sig=%b, expected op=%-6s sig=%b",
                     name, inst, op.name(), sig, e_op.name(), e_sig);
            errors++;
        end
    endtask

    initial begin
        $dumpfile("control_tb.vcd");
        $dumpvars(0, control_tb);

        //                                              rw a b mw rs  br j jr h il
        check(32'h002081b3, "add x3,x1,x2",   ALU_ADD,  11'b1_0_0_0_00_0_0_0_0_0);
        check(32'h40208233, "sub x4,x1,x2",   ALU_SUB,  11'b1_0_0_0_00_0_0_0_0_0);
        check(32'h407352b3, "sra x5,x6,x7",   ALU_SRA,  11'b1_0_0_0_00_0_0_0_0_0);
        check(32'h007332b3, "sltu x5,x6,x7",  ALU_SLTU, 11'b1_0_0_0_00_0_0_0_0_0);
        // inst[30] = 1 here is part of the immediate: must stay ADD / XOR
        check(32'hfff00093, "addi x1,x0,-1",  ALU_ADD,  11'b1_0_1_0_00_0_0_0_0_0);
        check(32'hfff14093, "xori x1,x2,-1",  ALU_XOR,  11'b1_0_1_0_00_0_0_0_0_0);
        check(32'h40315093, "srai x1,x2,3",   ALU_SRA,  11'b1_0_1_0_00_0_0_0_0_0);
        check(32'h00311093, "slli x1,x2,3",   ALU_SLL,  11'b1_0_1_0_00_0_0_0_0_0);
        check(32'h04002283, "lw x5,64(x0)",   ALU_ADD,  11'b1_0_1_0_01_0_0_0_0_0);
        check(32'hfff14283, "lbu x5,-1(x2)",  ALU_ADD,  11'b1_0_1_0_01_0_0_0_0_0);
        check(32'h04302023, "sw x3,64(x0)",   ALU_ADD,  11'b0_0_1_1_00_0_0_0_0_0);
        check(32'hfe310fa3, "sb x3,-1(x2)",   ALU_ADD,  11'b0_0_1_1_00_0_0_0_0_0);
        check(32'h00208063, "beq x1,x2",      ALU_ADD,  11'b0_0_0_0_00_1_0_0_0_0);
        check(32'h0020f463, "bgeu x1,x2",     ALU_ADD,  11'b0_0_0_0_00_1_0_0_0_0);
        check(32'h010000ef, "jal x1,16",      ALU_ADD,  11'b1_0_0_0_10_0_1_0_0_0);
        check(32'h00008067, "jalr x0,0(x1)",  ALU_ADD,  11'b1_0_1_0_10_0_0_1_0_0);
        check(32'h123450b7, "lui x1,0x12345", ALU_PASS_B, 11'b1_0_1_0_00_0_0_0_0_0);
        check(32'h00001097, "auipc x1,1",     ALU_ADD,  11'b1_1_1_0_00_0_0_0_0_0);
        check(32'h0ff0000f, "fence",          ALU_ADD,  11'b0_0_0_0_00_0_0_0_0_0);
        check(32'h00000073, "ecall",          ALU_ADD,  11'b0_0_0_0_00_0_0_0_1_0);
        check(32'h00100073, "ebreak",         ALU_ADD,  11'b0_0_0_0_00_0_0_0_1_0);
        check(32'h30002073, "csrr (not RV32I)", ALU_ADD, 11'b0_0_0_0_00_0_0_0_0_1);
        check(32'h00000000, "all zeros",      ALU_ADD,  11'b0_0_0_0_00_0_0_0_0_1);
        check(32'hffffffff, "all ones",       ALU_ADD,  11'b0_0_0_0_00_0_0_0_0_1);

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
