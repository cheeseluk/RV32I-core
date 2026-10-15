module imm_gen import riscv_pkg::*; (input logic [31:0] inst, 
                output logic [31:0] out);

                always_comb begin
                case (inst[6:0])
                    OP_JALR,
                    OP_SYSTEM, 
                    OP_FENCE, 
                    OP_LOAD, 
                    OP_IMM: out = { {20{inst[31]}} , inst[31:20]}; // I type
                    OP_STORE: out = {{20{inst[31]}}, {inst[31:25], inst[11:7]}}; // S type
                    OP_BRANCH: out = {{19{inst[31]}}, {inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}}; //B type
                    OP_AUIPC,
                    OP_LUI: out = {inst[31:12], {12'b0}};  // U Type
                    OP_JAL: out = {{11{inst[31]}}, {inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}}; // J type
                    default: out = '0; // R type
                endcase
                end

endmodule
