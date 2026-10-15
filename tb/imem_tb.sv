`timescale 1ns/1ps

module imem_tb;
    localparam int DEPTH = 16;

    logic [31:0] addr, instr;
    int errors = 0;

    // Same words as imem_tb.hex, written out here so the check doesn't
    // depend on $readmemh having worked.
    logic [31:0] expected [0:DEPTH-1] = '{
        32'h0050_0093, 32'h0070_0113, 32'h0020_81b3, 32'h4020_8233,
        32'ha5a5_0004, 32'ha5a5_0005, 32'ha5a5_0006, 32'ha5a5_0007,
        32'ha5a5_0008, 32'ha5a5_0009, 32'ha5a5_000a, 32'ha5a5_000b,
        32'ha5a5_000c, 32'ha5a5_000d, 32'ha5a5_000e, 32'hdead_beef
    };

    // sim.ps1 runs the simulation from build/, so the path is relative to that.
    imem #(.DEPTH(DEPTH), .INIT("../tb/imem_tb.hex")) dut (.addr(addr), .instr(instr));

    // Reads are combinational: set the address, wait a moment, check.
    task automatic check(input logic [31:0] t_addr, expected_instr, input string name);
        addr = t_addr;
        #1;
        if (instr !== expected_instr) begin
            $display("FAIL %-16s addr=%h : got %h, expected %h", name, addr, instr, expected_instr);
            errors++;
        end
    endtask

    initial begin
        $dumpfile("imem_tb.vcd");
        $dumpvars(0, imem_tb);

        addr = '0;
        #1;
        if ($isunknown(instr))
            $display("NOTE: word 0 is X. Was imem_tb.hex found? (path is relative to build/)");

        // Every word, at its aligned address
        for (int i = 0; i < DEPTH; i++)
            check(32'(i * 4), expected[i], $sformatf("word %0d", i));

        // The low two bits pick a byte within the word, so imem ignores them
        check(32'h0000_0009, expected[2], "addr[1:0]=01");
        check(32'h0000_000a, expected[2], "addr[1:0]=10");
        check(32'h0000_000b, expected[2], "addr[1:0]=11");
        check(32'h0000_003f, expected[15], "last word +3");

        // Bits above the index are ignored too, so addresses wrap around
        check(32'(DEPTH * 4),     expected[0], "wrap to word 0");
        check(32'(DEPTH * 4 + 8), expected[2], "wrap to word 2");

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
