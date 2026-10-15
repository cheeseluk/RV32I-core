`default_nettype none
module control import riscv_pkg::*; (
    input  logic [31:0] inst,
    output logic        reg_write,
    output logic [3:0]  alu_op,      // full ALU operation (alu_dec merged in)
    output logic        alu_src_a,   // 0 = rs1, 1 = pc        (AUIPC)
    output logic        alu_src_b,   // 0 = rs2, 1 = imm
    output logic        mem_write,   // store; LSU makes the byte enables
    output logic [1:0]  result_src,  // 00 = ALU, 01 = mem, 10 = pc+4
    output logic        branch,      // B-type
    output logic        jump,        // JAL
    output logic        jalr,        // JALR
    output logic        halt         // ecall, break
    );


    logic [6:0] opcode;
    assign opcode = inst[6:0];

    always_comb begin
        reg_write = 0;
        alu_op = 0;
        alu_src_a = 0;
        alu_src_b = 0;
        mem_write = 0;
        result_src = 2'b00;
        branch = 0;
        jump = 0;
        jalr = 0;
        halt = 0;

        case (opcode)

            OP_LOAD: begin 
                result_src = 2'b01;
                reg_write = 1;
                alu_src_b = 1;
            end

            OP_REG: begin
                reg_write = 1;
                alu_op = {inst[30], inst[14:12]}; // the ALU has it's decoder built in
            end

            OP_STORE: begin
                alu_src_b = 0;
                mem_write = 1;
            end

            OP_BRANCH: begin
                branch = 1;
            end

            OP_IMM: begin
                alu_op = {(inst[14:12] == 3'b101) & inst[30], inst[14:12]};
                reg_write = 1;
                alu_src_b = 1;
            end

            OP_JAL: begin
                result_src = 2'b10;
                alu_src_b = 1;
                reg_write = 1;
                jump = 1;
            end

            OP_JALR: begin
                result_src = 2'b10;
                alu_src_b = 1;
                reg_write = 1;
                jalr = 1;
            end

            OP_AUIPC: begin
                reg_write = 1;
                alu_src_a = 1;
                alu_src_b = 1;
            end

            OP_FENCE: ; //nothing
            
            OP_SYSTEM: begin
                if (inst[14:12] == 3'b000 && inst[20] == 1'b0)
                    halt = 1;
            end
        endcase

endmodule 





