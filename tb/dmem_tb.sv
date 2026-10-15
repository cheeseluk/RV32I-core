`timescale 1ns/1ps

module dmem_tb;
    localparam int DEPTH = 16;

    logic        clk = 0;
    logic [31:0] addr, wdata, rdata;
    logic [3:0]  be;
    logic [31:0] model [0:DEPTH-1];   // expected memory contents
    int errors = 0;

    dmem #(.DEPTH(DEPTH)) dut (.clk(clk), .addr(addr), .wdata(wdata), .be(be), .rdata(rdata));

    always #5 clk = ~clk;

    // Drive a write on the falling edge so it is stable for the next rising edge.
    // wdata must already sit in the byte lanes that be selects.
    task automatic write(input logic [31:0] t_addr, t_wdata, input logic [3:0] t_be);
        @(negedge clk);
        addr = t_addr; wdata = t_wdata; be = t_be;
        @(negedge clk);
        be = '0;
        for (int i = 0; i < 4; i++)
            if (t_be[i]) model[t_addr[5:2]][8*i +: 8] = t_wdata[8*i +: 8];
    endtask

    // Reads are combinational: set the address, wait a moment, check.
    task automatic check(input logic [31:0] t_addr, input string name);
        addr = t_addr;
        #1;
        if (rdata !== model[t_addr[5:2]]) begin
            $display("FAIL %-18s addr=%h : got %h, expected %h",
                     name, addr, rdata, model[t_addr[5:2]]);
            errors++;
        end
    endtask

    initial begin
        $dumpfile("dmem_tb.vcd");
        $dumpvars(0, dmem_tb);
        be = '0; wdata = '0; addr = '0;

        // sw: fill every word, then read them all back
        for (int i = 0; i < DEPTH; i++)
            write(32'(i * 4), 32'h1111_1111 * (i + 1), 4'b1111);
        for (int i = 0; i < DEPTH; i++)
            check(32'(i * 4), $sformatf("sw word %0d", i));

        // sb: one lane at a time; the other three bytes must be untouched.
        // Bytes of wdata outside the enabled lane are junk on purpose.
        write(32'h10, 32'hEEEE_EEAA, 4'b0001);  check(32'h10, "sb lane 0");
        write(32'h11, 32'hEEEE_BBEE, 4'b0010);  check(32'h10, "sb lane 1");
        write(32'h12, 32'hEECC_EEEE, 4'b0100);  check(32'h10, "sb lane 2");
        write(32'h13, 32'hDDEE_EEEE, 4'b1000);  check(32'h10, "sb lane 3");

        // sh: lower and upper half
        write(32'h20, 32'hEEEE_1234, 4'b0011);  check(32'h20, "sh lower half");
        write(32'h22, 32'h5678_EEEE, 4'b1100);  check(32'h20, "sh upper half");

        // be = 0 is not a store: nothing changes
        write(32'h24, 32'hBAD0_BAD0, 4'b0000);  check(32'h24, "be=0 no write");

        // The write happens on the rising edge, not before it
        @(negedge clk);
        addr = 32'h28; wdata = 32'hCAFE_F00D; be = 4'b1111;
        #1;
        if (rdata === 32'hCAFE_F00D) begin
            $display("FAIL %-18s rdata changed before the clock edge", "write timing");
            errors++;
        end
        @(negedge clk);
        be = '0;
        model[10] = 32'hCAFE_F00D;
        check(32'h28, "write timing");

        // Reads ignore addr[1:0] and the bits above the index (addresses wrap)
        check(32'h2B,                "read addr[1:0]=11");
        check(32'(DEPTH * 4 + 32'h28), "read wrap");

        // The last word, to catch an index that is one bit too narrow
        write(32'h3C, 32'h0BAD_C0DE, 4'b1111);  check(32'h3C, "last word");
        check(32'h00, "word 0 unaffected");

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
