module dmem #(parameter int DEPTH = 1024,
              parameter INIT = ""   // untyped: iverilog can't pass a string parameter into a string parameter
              )(
    input logic clk,
    input logic [31:0] addr,
    input logic [31:0] wdata,
    input logic [3:0] be,
    output logic [31:0] rdata
);

    logic [31:0] mem [0:DEPTH-1];

    // INIT = "" leaves the memory empty so a testbench can load it instead.
    // On the FPGA it holds the program image, so .data is there at power-up.
    initial if (INIT != "") $readmemh(INIT, mem);
    wire [$clog2(DEPTH)-1: 0] idx = addr[$clog2(DEPTH) + 1 : 2];

    always_ff @(posedge clk) 
        for (int i = 0; i < 4; i++ )
            if (be[i]) mem[idx][8*i +: 8] <= wdata[8*i +: 8];

    assign rdata = mem[idx];

endmodule
