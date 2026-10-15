`timescale 1ns/1ps

module regfile_tb;
    logic        clk = 0, we, reset;
    logic [4:0]  a1, a2, a3;
    logic [31:0] wd, rd1, rd2;
    logic [31:0] model [0:31];   // expected register contents
    int errors = 0;

    regfile dut (.clk(clk), .we(we), .reset(reset), .a1(a1), .a2(a2), .a3(a3),
              .wd(wd), .rd1(rd1), .rd2(rd2));

    always #5 clk = ~clk;

    // Drive a write on the falling edge so it is stable for the next rising edge.
    task automatic write(input logic [4:0] addr, input logic [31:0] data);
        @(negedge clk);
        we = 1; a3 = addr; wd = data;
        @(negedge clk);
        we = 0;
        if (addr != 0) model[addr] = data;
    endtask

    // Reads are combinational: change the address, wait a moment, check.
    task automatic check_read(input logic [4:0] r1, r2, input string name);
        a1 = r1; a2 = r2;
        #1;
        if (rd1 !== model[r1] || rd2 !== model[r2]) begin
            $display("FAIL %-14s x%0d=%h (exp %h)  x%0d=%h (exp %h)",
                     name, r1, rd1, model[r1], r2, rd2, model[r2]);
            errors++;
        end
    endtask

    initial begin
        $dumpfile("regfile_tb.vcd");
        $dumpvars(0, regfile_tb);

        we = 0; a1 = 0; a2 = 0; a3 = 0; wd = 0;
        foreach (model[i]) model[i] = '0;

        // Reset clears every register
        reset = 1;
        @(negedge clk);
        @(negedge clk);
        reset = 0;
        for (int i = 0; i < 32; i++) check_read(i, 31 - i, "after reset");

        // Basic write, read back on both ports
        write(5, 32'hDEAD_BEEF);
        check_read(5, 5, "write x5");

        // x0 is hardwired to zero
        write(0, 32'hFFFF_FFFF);
        check_read(0, 5, "x0 stays 0");

        // we = 0 must not write
        @(negedge clk);
        we = 0; a3 = 5; wd = 32'h1234_5678;
        @(negedge clk);
        check_read(5, 0, "we=0 no write");

        // Fill every register with a distinct value, read all back
        for (int i = 1; i < 32; i++) write(i, 32'hA000_0000 | (i << 8) | i);
        for (int i = 0; i < 32; i++) check_read(i, 31 - i, "fill all");

        // Write only lands on the clock edge: before the edge the old value shows
        @(negedge clk);
        we = 1; a3 = 7; wd = 32'h0BAD_F00D;
        check_read(7, 7, "before edge");
        @(posedge clk); #1;
        we = 0;
        model[7] = 32'h0BAD_F00D;
        check_read(7, 7, "after edge");

        // Reset clears everything again
        @(negedge clk);
        reset = 1;
        @(negedge clk);
        reset = 0;
        foreach (model[i]) model[i] = '0;
        for (int i = 0; i < 32; i++) check_read(i, 31 - i, "second reset");

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
