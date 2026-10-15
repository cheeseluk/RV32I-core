`timescale 1ns/1ps

module alu_tb;
    import riscv_pkg::*;

    logic [31:0] a, b, y;
    alu_op_e     op;
    int errors = 0;

    alu dut (.a(a), .b(b), .op(op), .y(y));

    task automatic check(input alu_op_e t_op, input logic [31:0] t_a, t_b, expected);
        op = t_op; a = t_a; b = t_b;
        #1;
        if (y !== expected) begin
            $display("FAIL %-8s (%b) a=%h b=%h : got %h, expected %h",
                     op.name(), op, a, b, y, expected);
            errors++;
        end
    endtask

    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);

        // ADD
        check(ALU_ADD,  32'd5,          32'd7,          32'd12);
        check(ALU_ADD,  32'hFFFF_FFFF,  32'd1,          32'd0);          // wraparound
        // SUB
        check(ALU_SUB,  32'd10,         32'd3,          32'd7);
        check(ALU_SUB,  32'd0,          32'd1,          32'hFFFF_FFFF);
        // SLL
        check(ALU_SLL,  32'h0000_0001,  32'd4,          32'h0000_0010);
        check(ALU_SLL,  32'h0000_0001,  32'd33,         32'h0000_0002);  // only b[4:0] used
        // SLT (signed)
        check(ALU_SLT,  32'hFFFF_FFFF,  32'd1,          32'd1);          // -1 < 1
        check(ALU_SLT,  32'd1,          32'hFFFF_FFFF,  32'd0);
        // SLTU (unsigned)
        check(ALU_SLTU, 32'hFFFF_FFFF,  32'd1,          32'd0);
        check(ALU_SLTU, 32'd1,          32'hFFFF_FFFF,  32'd1);
        // XOR
        check(ALU_XOR,  32'hF0F0_F0F0,  32'hFF00_FF00,  32'h0FF0_0FF0);
        // SRL
        check(ALU_SRL,  32'h8000_0000,  32'd4,          32'h0800_0000);
        // SRA
        check(ALU_SRA,  32'h8000_0000,  32'd4,          32'hF800_0000);
        check(ALU_SRA,  32'h4000_0000,  32'd4,          32'h0400_0000);  // positive stays positive
        // OR
        check(ALU_OR,   32'hF0F0_0000,  32'h0F0F_0000,  32'hFFFF_0000);
        // AND
        check(ALU_AND,  32'hF0F0_FFFF,  32'hFF00_00FF,  32'hF000_00FF);
        // Unused code -> 0. The cast is needed because 1111 isn't an alu_op_e value.
        check(alu_op_e'(4'b1111), 32'd123, 32'd456,     32'd0);

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
