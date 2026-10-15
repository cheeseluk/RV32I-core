`timescale 1ns/1ps

module lsu_tb;
    import riscv_pkg::*;

    logic [2:0]  funct3;
    logic [1:0]  addr_lo;
    logic        mem_write;
    logic [31:0] store_data, wdata, rdata, load_data;
    logic [3:0]  be;
    int errors = 0;

    lsu dut (.funct3(funct3), .byte_off(addr_lo), .mem_write(mem_write),
             .rs2_data(store_data), .wdata(wdata), .be(be),
             .rdata(rdata), .load_data(load_data));

    // Store: check the enables, and that every enabled lane carries the right byte.
    task automatic check_store(input logic [2:0] t_f3, input logic [1:0] t_lo,
                               input logic t_mw, input logic [31:0] t_data,
                               input logic [3:0] e_be, input logic [31:0] e_lanes,
                               input string name);
        funct3 = t_f3; addr_lo = t_lo; mem_write = t_mw; store_data = t_data;
        #1;
        if (be !== e_be) begin
            $display("FAIL %-14s be: got %b, expected %b", name, be, e_be);
            errors++;
        end
        for (int i = 0; i < 4; i++)
            if (e_be[i] && wdata[8*i +: 8] !== e_lanes[8*i +: 8]) begin
                $display("FAIL %-14s lane %0d: got %h, expected %h",
                         name, i, wdata[8*i +: 8], e_lanes[8*i +: 8]);
                errors++;
            end
    endtask

    task automatic check_load(input logic [2:0] t_f3, input logic [1:0] t_lo,
                              input logic [31:0] expected, input string name);
        funct3 = t_f3; addr_lo = t_lo; mem_write = 0;
        #1;
        if (load_data !== expected) begin
            $display("FAIL %-14s rdata=%h lo=%0d : got %h, expected %h",
                     name, rdata, addr_lo, load_data, expected);
            errors++;
        end
    endtask

    initial begin
        $dumpfile("lsu_tb.vcd");
        $dumpvars(0, lsu_tb);

        // ---- stores ----
        check_store(F3_W, 2'd0, 1, 32'h1234_5678, 4'b1111, 32'h1234_5678, "sw");
        check_store(F3_B, 2'd0, 1, 32'h1234_56AA, 4'b0001, 32'h0000_00AA, "sb lane 0");
        check_store(F3_B, 2'd1, 1, 32'h1234_56AA, 4'b0010, 32'h0000_AA00, "sb lane 1");
        check_store(F3_B, 2'd2, 1, 32'h1234_56AA, 4'b0100, 32'h00AA_0000, "sb lane 2");
        check_store(F3_B, 2'd3, 1, 32'h1234_56AA, 4'b1000, 32'hAA00_0000, "sb lane 3");
        check_store(F3_H, 2'd0, 1, 32'h1234_BEEF, 4'b0011, 32'h0000_BEEF, "sh low");
        check_store(F3_H, 2'd2, 1, 32'h1234_BEEF, 4'b1100, 32'hBEEF_0000, "sh high");
        check_store(F3_W, 2'd0, 0, 32'h1234_5678, 4'b0000, 32'h0,         "no store");
        check_store(F3_B, 2'd3, 0, 32'h1234_5678, 4'b0000, 32'h0,         "no store sb");

        // ---- loads ----
        rdata = 32'h80F1_7F82;   // bytes (lane 3..0): 80 F1 7F 82
        check_load(F3_W,  2'd0, 32'h80F1_7F82, "lw");
        check_load(F3_B,  2'd0, 32'hFFFF_FF82, "lb lane 0");    // negative byte
        check_load(F3_B,  2'd1, 32'h0000_007F, "lb lane 1");    // positive byte
        check_load(F3_B,  2'd2, 32'hFFFF_FFF1, "lb lane 2");
        check_load(F3_B,  2'd3, 32'hFFFF_FF80, "lb lane 3");
        check_load(F3_BU, 2'd0, 32'h0000_0082, "lbu lane 0");
        check_load(F3_BU, 2'd3, 32'h0000_0080, "lbu lane 3");
        check_load(F3_H,  2'd0, 32'h0000_7F82, "lh low");       // positive half
        check_load(F3_H,  2'd2, 32'hFFFF_80F1, "lh high");      // negative half
        check_load(F3_HU, 2'd0, 32'h0000_7F82, "lhu low");
        check_load(F3_HU, 2'd2, 32'h0000_80F1, "lhu high");

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
