`timescale 1ns/1ps

// Runs a program on the core with an imem and a dmem attached.
// The program reports its result in one of two ways:
//   - a store to RESULT_ADDR (0x100): 1 = PASS, (n << 1) | 1 = FAIL test #n  (sw/*.S)
//   - ecall / ebreak: x3 (gp) = 1 = PASS, (n << 1) | 1 = FAIL test #n          (riscv-tests)
// It prints exactly one line starting with PASS or FAIL, then stops.
//
// Plusargs (run_prog.ps1 and run_tests.ps1 pass these):
//   +hex=<file>       program; loaded into both imem and dmem (default prog.hex)
//   +trace=<file>     one line per instruction, same format as tools/iss.py
//   +verbose          also print the trace to the console
//   +max_cycles=<n>   timeout (default 100000)
//   +vcd              dump waveforms to core_tb.vcd
module core_tb;
    import riscv_pkg::*;

    localparam int          MEM_WORDS   = 4096;          // 16 KB each; matches tools/iss.py
    localparam logic [31:0] RESULT_ADDR = 32'h0000_0100;

    logic        clk = 0, reset = 1;
    logic [31:0] pc, instr, mem_addr, mem_wdata, mem_rdata;
    logic [3:0]  mem_be;
    logic        mem_write, halt, illegal;

    core dut (.clk(clk), .reset(reset), .pc(pc), .inst(instr),
              .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_be(mem_be),
              .mem_write(mem_write), .mem_rdata(mem_rdata),
              .halt(halt), .illegal(illegal));

    imem #(.DEPTH(MEM_WORDS), .INIT("")) imem_u (.addr(pc), .instr(instr));
    dmem #(.DEPTH(MEM_WORDS)) dmem_u (.clk(clk), .addr(mem_addr), .wdata(mem_wdata),
                                      .be(mem_be), .rdata(mem_rdata));

    always #5 clk = ~clk;

    string hex_file = "prog.hex", trace_file;
    int    trace_fd = 0, max_cycles = 100000, cycles = 0;
    bit    verbose;

    // What the instruction now executing does, in the format tools/iss.py prints:
    //   pc instr [xN=value] [mem[addr]=data]
    // Sampled at the clock edge that commits it, before the registers update.
    function automatic string trace_line();
        string s;
        s = $sformatf("%08x %08x", pc, instr);
        if (dut.reg_write && instr[11:7] != 0)
            s = {s, $sformatf(" x%0d=%08x", instr[11:7], dut.dp.result)};
        if (mem_write)
            case (instr[13:12])     // store size
                2'b00:   s = {s, $sformatf(" mem[%08x]=%02x", mem_addr, dut.dp.rd2[7:0])};
                2'b01:   s = {s, $sformatf(" mem[%08x]=%04x", mem_addr, dut.dp.rd2[15:0])};
                default: s = {s, $sformatf(" mem[%08x]=%08x", mem_addr, dut.dp.rd2)};
            endcase
        return s;
    endfunction

    task automatic finish(input string verdict);
        $display("%s", verdict);
        if (trace_fd) $fclose(trace_fd);
        $finish;
    endtask

    function automatic string verdict(input logic [31:0] code);
        if (code === 32'd1) return "PASS";
        return $sformatf("FAIL test #%0d (result = %08x)", code >> 1, code);
    endfunction

    // Number of words in a hex file from bin2hex.py (one per line), 0 if unreadable.
    function automatic int hex_words(input string path);
        int fd, n = 0;
        string line;
        fd = $fopen(path, "r");
        if (fd == 0) return 0;
        while ($fgets(line, fd)) if (line.len() > 1) n++;
        $fclose(fd);
        return n;
    endfunction

    initial begin
        void'($value$plusargs("hex=%s", hex_file));
        void'($value$plusargs("max_cycles=%d", max_cycles));
        if ($value$plusargs("trace=%s", trace_file)) trace_fd = $fopen(trace_file, "w");
        verbose = $test$plusargs("verbose");
        if ($test$plusargs("vcd")) begin
            $dumpfile("core_tb.vcd");
            $dumpvars(0, core_tb);
        end

        // Same image in both memories: code for imem, .data for dmem.
        // Load exactly the words in the file; the rest stay X, so running
        // off the end of the program shows up as an illegal instruction.
        begin
            int n;
            n = hex_words(hex_file);
            if (n == 0)
                finish($sformatf("FAIL cannot read %s", hex_file));
            else if (n > MEM_WORDS)
                finish($sformatf("FAIL %s is bigger than %0d words", hex_file, MEM_WORDS));
            else begin
                $readmemh(hex_file, imem_u.mem, 0, n - 1);
                $readmemh(hex_file, dmem_u.mem, 0, n - 1);
            end
        end

        repeat (2) @(posedge clk);
        @(negedge clk) reset = 0;
    end

    always @(posedge clk) begin
        if (!reset) begin
            string line;
            line = trace_line();
            if (verbose)  $display("%s", line);
            if (trace_fd) $fdisplay(trace_fd, "%s", line);

            if (illegal)
                finish($sformatf("FAIL illegal instruction %08x at pc %08x", instr, pc));
            else if (halt)
                finish(verdict(dut.dp.rf.x[3]));
            else if (mem_write && mem_addr == RESULT_ADDR)
                finish(verdict(dut.dp.rd2));

            cycles++;
            if (cycles >= max_cycles)
                finish($sformatf("FAIL timeout after %0d cycles (pc %08x)", cycles, pc));
        end
    end
endmodule
