`timescale 1ns/1ps

module alu_tb;
    logic [31:0] a, b, y;
    logic [3:0]  op;
    int errors = 0;

    alu dut (.a(a), .b(b), .op(op), .y(y));

    task automatic check(input logic [3:0] t_op, input logic [31:0] t_a, t_b, expected, input string name);
        op = t_op; a = t_a; b = t_b;
        #1;
        if (y !== expected) begin
            $display("FAIL %-4s a=%h b=%h : got %h, expected %h", name, a, b, y, expected);
            errors++;
        end
    endtask

    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);

        // ADD
        check(4'b0000, 32'd5,          32'd7,          32'd12,         "ADD");
        check(4'b0000, 32'hFFFF_FFFF,  32'd1,          32'd0,          "ADD");  // wraparound
        // SUB
        check(4'b1000, 32'd10,         32'd3,          32'd7,          "SUB");
        check(4'b1000, 32'd0,          32'd1,          32'hFFFF_FFFF,  "SUB");
        // SLL
        check(4'b0001, 32'h0000_0001,  32'd4,          32'h0000_0010,  "SLL");
        check(4'b0001, 32'h0000_0001,  32'd33,         32'h0000_0002,  "SLL");  // only b[4:0] used
        // SLT (signed)
        check(4'b0010, 32'hFFFF_FFFF,  32'd1,          32'd1,          "SLT");  // -1 < 1
        check(4'b0010, 32'd1,          32'hFFFF_FFFF,  32'd0,          "SLT");
        // SLTU (unsigned)
        check(4'b0011, 32'hFFFF_FFFF,  32'd1,          32'd0,          "SLTU");
        check(4'b0011, 32'd1,          32'hFFFF_FFFF,  32'd1,          "SLTU");
        // XOR
        check(4'b0100, 32'hF0F0_F0F0,  32'hFF00_FF00,  32'h0FF0_0FF0,  "XOR");
        // SRL
        check(4'b0101, 32'h8000_0000,  32'd4,          32'h0800_0000,  "SRL");
        // SRA
        check(4'b1101, 32'h8000_0000,  32'd4,          32'hF800_0000,  "SRA");
        check(4'b1101, 32'h4000_0000,  32'd4,          32'h0400_0000,  "SRA");  // positive stays positive
        // OR
        check(4'b0110, 32'hF0F0_0000,  32'h0F0F_0000,  32'hFFFF_0000,  "OR");
        // AND
        check(4'b0111, 32'hF0F0_FFFF,  32'hFF00_00FF,  32'hF000_00FF,  "AND");
        // Unused opcode -> 0
        check(4'b1111, 32'd123,        32'd456,        32'd0,          "DEF");

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
