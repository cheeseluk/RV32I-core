module imem #(parameter int DEPTH = 1024, 
            parameter string INIT = "prog.hex"
            )(input logic [31:0] addr, 
            output logic [31:0] instr);

            logic [31:0] mem [0:DEPTH-1]; 
            
            initial $readmemh(INIT, mem);
            assign instr = mem[addr[$clog2(DEPTH) + 1:2]]; //assigning instr to mem[addr]

endmodule
