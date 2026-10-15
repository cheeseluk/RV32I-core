`default_nettype none
// Nexys A7 top level: the core and its two memories, a clock and reset for
// the board, and memory-mapped I/O for the LEDs, switches and 7-segment display.
//
// Memory map
//   0x0000_0000  RAM, MEM_WORDS words. imem holds the code; dmem holds a copy
//                of the same image so .data is there too (as in core_tb).
//   0x0000_0100  RESULT (w): a store here is the program's verdict, as in
//                core_tb: 1 = PASS (LD16 green), anything else = FAIL (LD16
//                red). It also goes to RAM and to the 7-segment display.
//   0x1000_0000  LED (r/w): LD15..LD0
//   0x1000_0004  SW  (r):   SW15..SW0
//   0x1000_0008  SEG (r/w): 8 hex digits on the 7-segment display
// LD17: blue = halted (ecall / ebreak), red = an illegal instruction was seen.
// CPU_RESET (the red button) restarts the program.
module nexys_top #(
    parameter string HEX       = "",     // program image; build.tcl sets it
    parameter int    MEM_WORDS = 4096,   // 16 KB each; crt0.S puts the stack at the top
    parameter real   CLK_DIV   = 40.0    // core clock = 1000 MHz / CLK_DIV = 25 MHz
)(
    input wire logic        CLK100MHZ,
    input wire logic        CPU_RESETN,
    input wire logic [15:0] SW,
    output logic [15:0] LED,
    output logic        LED16_R, LED16_G, LED16_B,
    output logic        LED17_R, LED17_G, LED17_B,
    output logic [7:0]  AN,
    output logic        CA, CB, CC, CD, CE, CF, CG, DP
);

    localparam logic [31:0] RESULT_ADDR = 32'h0000_0100;

    // ---------------- clock and reset ----------------

    // A single-cycle core does a whole instruction (fetch, decode, ALU, data
    // memory, write back) in one clock, so it can't run at 100 MHz.
    logic clk, locked;
`ifdef SYNTHESIS
    logic clk_mmcm, clk_fb;
    // 100 MHz in, x10 = 1000 MHz VCO, / CLK_DIV out.
    MMCME2_BASE #(.CLKIN1_PERIOD(10.0), .CLKFBOUT_MULT_F(10.0), .CLKOUT0_DIVIDE_F(CLK_DIV))
        mmcm (.CLKIN1(CLK100MHZ), .CLKFBIN(clk_fb), .CLKFBOUT(clk_fb),
              .CLKOUT0(clk_mmcm), .LOCKED(locked), .PWRDWN(1'b0), .RST(1'b0));
    BUFG clk_buf (.I(clk_mmcm), .O(clk));
`else
    // Simulation: run straight from the board clock.
    assign clk    = CLK100MHZ;
    assign locked = 1'b1;
`endif

    // The button and LOCKED change at any time, so pass them through two
    // flip-flops. Starts at 1: the core is held in reset at power-up.
    // verilator lint_off PROCASSINIT
    logic [1:0] reset_sync = 2'b11;     // the FPGA's flip-flops power up with this value
    // verilator lint_on PROCASSINIT
    logic       reset;
    always_ff @(posedge clk) reset_sync <= {reset_sync[0], ~(CPU_RESETN & locked)};
    assign reset = reset_sync[1];

    // ---------------- core and memories ----------------

    logic [31:0] pc, instr, mem_addr, mem_wdata, mem_rdata, ram_rdata, io_rdata;
    logic [3:0]  mem_be;
    logic        mem_write, halt, illegal, is_io;

    core cpu (.clk(clk), .reset(reset), .pc(pc), .inst(instr),
              .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_be(mem_be),
              .mem_write(mem_write), .mem_rdata(mem_rdata),
              .halt(halt), .illegal(illegal));

    imem #(.DEPTH(MEM_WORDS), .INIT(HEX)) imem_u (.addr(pc), .instr(instr));

    assign is_io = (mem_addr[31:28] == 4'h1);

    dmem #(.DEPTH(MEM_WORDS), .INIT(HEX)) dmem_u (.clk(clk), .addr(mem_addr), .wdata(mem_wdata),
                                                  .be(is_io ? 4'b0000 : mem_be), .rdata(ram_rdata));

    assign mem_rdata = is_io ? io_rdata : ram_rdata;

    // ---------------- memory-mapped I/O ----------------

    logic [15:0] led, sw_meta, sw_sync;
    logic [31:0] seg, result;
    logic        result_valid, illegal_seen;

    always_ff @(posedge clk) begin
        sw_meta <= SW;              // switches are asynchronous too
        sw_sync <= sw_meta;

        if (reset) begin
            led          <= '0;
            seg          <= '0;
            result       <= '0;
            result_valid <= 1'b0;
            illegal_seen <= 1'b0;
        end else begin
            if (mem_write && is_io)
                case (mem_addr[3:2])
                    2'd0:    led <= mem_wdata[15:0];
                    2'd2:    seg <= mem_wdata;
                    default: ;
                endcase
            if (mem_write && mem_addr == RESULT_ADDR) begin
                result       <= mem_wdata;
                result_valid <= 1'b1;
                seg          <= mem_wdata;
            end
            // The core keeps going after an illegal instruction, so remember it.
            if (illegal) illegal_seen <= 1'b1;
        end
    end

    always_comb
        case (mem_addr[3:2])
            2'd0:    io_rdata = {16'b0, led};
            2'd1:    io_rdata = {16'b0, sw_sync};
            2'd2:    io_rdata = seg;
            default: io_rdata = '0;
        endcase

    // ---------------- board outputs ----------------

    assign LED = led;

    // The RGB LEDs are very bright at full power: light them 1/16 of the time.
    logic [3:0] dim_count;
    logic       dim;
    always_ff @(posedge clk) dim_count <= reset ? '0 : dim_count + 4'd1;
    assign dim = (dim_count == 4'd0);

    assign LED16_G = dim & result_valid & (result == 32'd1);
    assign LED16_R = dim & result_valid & (result != 32'd1);
    assign LED16_B = 1'b0;
    assign LED17_B = dim & halt & ~reset;
    assign LED17_R = dim & illegal_seen;
    assign LED17_G = 1'b0;

    sevenseg display (.clk(clk), .reset(reset), .value(seg),
                      .an(AN), .seg({CG, CF, CE, CD, CC, CB, CA}));
    assign DP = 1'b1;               // decimal points off (active low)

endmodule

`default_nettype wire
