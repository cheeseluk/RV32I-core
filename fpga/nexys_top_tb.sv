`timescale 1ns/1ps

// Simulates the board: runs a program on nexys_top, then reports what the
// LEDs and the 7-segment display show. build.ps1 -Sim runs this.
// It stops when the program stores a result, hits an illegal instruction,
// or after max_cycles (programs like leds.S never finish).
//
// Plusargs: +hex=<file>  +sw=<hex value for the switches>  +max_cycles=<n>
module nexys_top_tb;
    logic        CLK100MHZ = 0, CPU_RESETN = 0;
    logic [15:0] SW = '0, LED;
    logic        LED16_R, LED16_G, LED16_B, LED17_R, LED17_G, LED17_B;
    logic [7:0]  AN;
    logic        CA, CB, CC, CD, CE, CF, CG, DP;

    nexys_top dut (.*);

    always #5 CLK100MHZ = ~CLK100MHZ;

    localparam int MEM_WORDS = 4096;    // nexys_top's default

    string hex_file;
    int    max_cycles = 1000000;

    // Number of words in a hex file from bin2hex.py (one per line), 0 if unreadable.
    function automatic int hex_words(input string path);
        int fd, count = 0;
        string line;
        fd = $fopen(path, "r");
        if (fd == 0) return 0;
        while ($fgets(line, fd)) if (line.len() > 1) count++;
        $fclose(fd);
        return count;
    endfunction

    // Segment pattern back to a hex digit (-1 if it isn't one).
    function automatic int digit_of(input logic [6:0] gfedcba);
        case (~gfedcba)
            7'b0111111: return 'h0;  7'b0000110: return 'h1;
            7'b1011011: return 'h2;  7'b1001111: return 'h3;
            7'b1100110: return 'h4;  7'b1101101: return 'h5;
            7'b1111101: return 'h6;  7'b0000111: return 'h7;
            7'b1111111: return 'h8;  7'b1101111: return 'h9;
            7'b1110111: return 'hA;  7'b1111100: return 'hB;
            7'b0111001: return 'hC;  7'b1011110: return 'hD;
            7'b1111001: return 'hE;  7'b1110001: return 'hF;
            default:    return -1;
        endcase
    endfunction

    // Watch the display for one full refresh (all 8 digits) and read it back.
    task automatic read_display(output logic [31:0] shown, output bit ok);
        int d;
        bit seen [8];
        ok = 1;
        repeat (1 << 17) begin
            @(posedge CLK100MHZ);
            for (int i = 0; i < 8; i++)
                if (AN == ~(8'b1 << i)) begin
                    d = digit_of({CG, CF, CE, CD, CC, CB, CA});
                    if (d < 0) ok = 0;
                    else shown[4*i +: 4] = d[3:0];
                    seen[i] = 1;
                end
        end
        foreach (seen[i]) if (!seen[i]) ok = 0;
    endtask

    initial begin
        logic [31:0] shown;
        bit          shown_ok;
        string       seg_text, ld16, ld17;
        int          n;

        if (!$value$plusargs("hex=%s", hex_file)) begin
            $display("FAIL no +hex=<file>");
            $finish;
        end
        void'($value$plusargs("sw=%h", SW));
        if (dut.MEM_WORDS != MEM_WORDS) $display("WARNING: testbench MEM_WORDS doesn't match nexys_top");
        void'($value$plusargs("max_cycles=%d", max_cycles));

        // What build.tcl does with the HEX parameter, done here instead.
        // On the FPGA the rest of the memory is 0, which is an illegal
        // instruction, so running off the end of the program shows on LD17.
        n = hex_words(hex_file);
        if (n == 0 || n > MEM_WORDS) begin
            $display("FAIL cannot load %s", hex_file);
            $finish;
        end
        for (int i = 0; i < MEM_WORDS; i++) begin
            dut.imem_u.mem[i] = '0;
            dut.dmem_u.mem[i] = '0;
        end
        $readmemh(hex_file, dut.imem_u.mem, 0, n - 1);
        $readmemh(hex_file, dut.dmem_u.mem, 0, n - 1);

        repeat (4) @(posedge CLK100MHZ);
        CPU_RESETN = 1;

        for (int c = 0; c < max_cycles; c++) begin
            @(posedge CLK100MHZ);
            if (dut.result_valid || dut.illegal_seen) break;
        end
        repeat (2) @(posedge CLK100MHZ);

        read_display(shown, shown_ok);
        seg_text = "(unreadable)";
        if (shown_ok) seg_text = $sformatf("%08h", shown);
        ld16 = "off";
        if (dut.result_valid) ld16 = (dut.result == 1) ? "green" : "red";
        ld17 = "off";
        if (dut.halt)         ld17 = "blue (halted)";
        if (dut.illegal_seen) ld17 = "red (illegal)";
        $display("SW = %04h   LED = %04h   7-seg = %s   LD16 %s   LD17 %s",
                 SW, LED, seg_text, ld16, ld17);

        if (!shown_ok || shown !== dut.seg)
            $display("FAIL 7-segment display shows the wrong value (SEG register = %08h)", dut.seg);
        else if (dut.illegal_seen)
            $display("FAIL illegal instruction");
        else if (dut.result_valid && dut.result == 1)
            $display("PASS");
        else if (dut.result_valid)
            $display("FAIL test #%0d (result = %08h)", dut.result >> 1, dut.result);
        else
            $display("RUNNING (no result after %0d cycles)", max_cycles);
        $finish;
    end
endmodule
