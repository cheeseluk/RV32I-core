`default_nettype none
module control import riscv_pkg::*; (
    input wire logic [31:0] inst,
    output logic        reg_write,
    output alu_op_e     alu_op,      // full ALU operation (alu_dec merged in)
    output logic        alu_src_a,   // 0 = rs1, 1 = pc        (AUIPC)
    output logic        alu_src_b,   // 0 = rs2, 1 = imm
    output logic        mem_write,   // store; LSU makes the byte enables
    output logic [1:0]  result_src,  // 00 = ALU, 01 = mem, 10 = pc+4
    output logic        branch,      // B-type
    output logic        jump,        // JAL
    output logic        jalr,        // JALR
    output logic        halt,        // ecall, ebreak
    output logic        illegal      // opcode not in RV32I
    );


    logic [6:0] opcode;
    logic [2:0] funct3;
    assign opcode = inst[6:0];
    assign funct3 = inst[14:12];

    always_comb begin
        reg_write = 0;
        alu_op = ALU_ADD;
        alu_src_a = 0;
        alu_src_b = 0;
        mem_write = 0;
        result_src = 2'b00;
        branch = 0;
        jump = 0;
        jalr = 0;
        halt = 0;
        illegal = 0;

        case (opcode)

            OP_LOAD: begin              // address = rs1 + imm
                result_src = 2'b01;
                reg_write = 1;
                alu_src_b = 1;
            end

            OP_REG: begin
                reg_write = 1;
                alu_op = alu_op_e'({inst[30], funct3}); // the ALU has it's decoder built in
            end

            OP_STORE: begin             // address = rs1 + imm
                alu_src_b = 1;
                mem_write = 1;
            end

            OP_BRANCH: begin            // branch_unit compares, not the ALU
                branch = 1;
            end

            OP_IMM: begin
                // inst[30] is part of the immediate except for srai
                alu_op = alu_op_e'({(funct3 == 3'b101) & inst[30], funct3});
                reg_write = 1;
                alu_src_b = 1;
            end

            OP_JAL: begin               // target = pc + imm, computed in the datapath
                result_src = 2'b10;
                reg_write = 1;
                jump = 1;
            end

            OP_JALR: begin              // target = (rs1 + imm) & ~1, from the ALU
                result_src = 2'b10;
                alu_src_b = 1;
                reg_write = 1;
                jalr = 1;
            end

            OP_LUI: begin               // rd = imm
                reg_write = 1;
                alu_src_b = 1;
                alu_op = ALU_PASS_B;
            end

            OP_AUIPC: begin             // rd = pc + imm
                reg_write = 1;
                alu_src_a = 1;
                alu_src_b = 1;
            end

            OP_FENCE: ; //nothing

            OP_SYSTEM: begin
                if (funct3 == 3'b000)   // ecall and ebreak; anything else is a CSR op
                    halt = 1;
                else
                    illegal = 1;
            end

            default: illegal = 1;
        endcase
    end

endmodule

`default_nettype wire
