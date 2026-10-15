`default_nettype none
// Shared definitions for the RV32I core. No hardware here: every RTL file
// pulls these names in with `import riscv_pkg::*;`.
package riscv_pkg;

    localparam int XLEN = 32;
    localparam logic [31:0] RESET_PC = 32'h0000_0000;

    // Major opcodes: instr[6:0]. These 11 cover all of RV32I.
    typedef enum logic [6:0] {
        OP_LOAD   = 7'b0000011, // lb lh lw lbu lhu
        OP_FENCE  = 7'b0001111, // fence (treated as a NOP)
        OP_IMM    = 7'b0010011, // addi slti sltiu xori ori andi slli srli srai
        OP_AUIPC  = 7'b0010111, // auipc
        OP_STORE  = 7'b0100011, // sb sh sw
        OP_REG    = 7'b0110011, // add sub sll slt sltu xor srl sra or and
        OP_LUI    = 7'b0110111, // lui
        OP_BRANCH = 7'b1100011, // beq bne blt bge bltu bgeu
        OP_JALR   = 7'b1100111, // jalr
        OP_JAL    = 7'b1101111, // jal
        OP_SYSTEM = 7'b1110011  // ecall ebreak
    } opcode_e;

    // ALU operations, encoded as {instr[30], funct3} so R-type
    // instructions can pass those bits straight through.
    typedef enum logic [3:0] {
        ALU_ADD  = 4'b0000,
        ALU_SUB  = 4'b1000,
        ALU_SLL  = 4'b0001,
        ALU_SLT  = 4'b0010,
        ALU_SLTU = 4'b0011,
        ALU_XOR  = 4'b0100,
        ALU_SRL  = 4'b0101,
        ALU_SRA  = 4'b1101,
        ALU_OR   = 4'b0110,
        ALU_AND  = 4'b0111
    } alu_op_e;

    // funct3 values (instr[14:12]) for branches: used by branch_unit.
    localparam logic [2:0] F3_BEQ  = 3'b000;
    localparam logic [2:0] F3_BNE  = 3'b001;
    localparam logic [2:0] F3_BLT  = 3'b100;
    localparam logic [2:0] F3_BGE  = 3'b101;
    localparam logic [2:0] F3_BLTU = 3'b110;
    localparam logic [2:0] F3_BGEU = 3'b111;

    // funct3 values for loads and stores: access size, and for loads
    // whether to sign- or zero-extend. Used by dmem and load_unit.
    localparam logic [2:0] F3_B  = 3'b000; // lb / sb
    localparam logic [2:0] F3_H  = 3'b001; // lh / sh
    localparam logic [2:0] F3_W  = 3'b010; // lw / sw
    localparam logic [2:0] F3_BU = 3'b100; // lbu
    localparam logic [2:0] F3_HU = 3'b101; // lhu

endpackage
