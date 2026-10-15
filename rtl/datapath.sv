`default_nettype none

module datapath import riscv_pkg::*; (
    input wire logic clk, reset,
    // inst memory
    input wire logic [31:0] inst,
    output logic [31:0] pc,
    // control
    input wire logic reg_write,
    input wire alu_op_e alu_op,
    input wire logic alu_src_a, alu_src_b,
    input wire logic mem_write,
    input wire logic [1:0] result_src,
    input wire logic branch, jump, jalr,
    input wire logic halt,
    // data memory
    output logic [31:0] alu_result,  // also the data address
    output logic [31:0] write_data,  // in byte lanes
    output logic [3:0]  byte_en,
    input wire logic [31:0] read_data
    
);

    logic [31:0] pc_next, pc_plus4, pc_target;
    logic [31:0] imm_ext;
    logic [31:0] rd1, rd2;
    logic [31:0] src_a, src_b; 
    logic [31:0] load_data, result;
    logic taken;
    logic [1:0] pc_src;

    // PC
    assign pc_plus4 = pc + 32'd4;
    assign pc_target = pc + imm_ext;
    // 00 = pc+4, 01 = pc + imm_ext, 10 = jalr target (ALU result with bit 0 cleared)
    assign pc_src = jalr ? 2'b10 : 
                    ((branch & taken) | jump) ? 2'b01 : 2'b00;

    always_comb begin
        case (pc_src)
        2'b01: pc_next = pc_target;
        2'b10: pc_next = {alu_result[31:1], 1'b0}; //0 bit might be odd
        default: pc_next = pc_plus4;
        endcase
    end

    // PC register ecall / ebreak
    always_ff @(posedge clk) begin
        if (reset) pc <= RESET_PC;
        else if (!halt) pc <= pc_next;
    end

    // register files and imms
    
    regfile rf (.clk(clk), .we(reg_write), .reset(reset), 
            .a1(inst[19:15]), .a2(inst[24:20]), .a3(inst[11:7]), 
            .wd(result), .rd1(rd1), .rd2(rd2));

    imm_gen ig (.inst(inst), .out(imm_ext));

    // ALU and branch
    assign src_a = alu_src_a ? pc : rd1;
    assign src_b = alu_src_b ? imm_ext : rd2;

    alu alu_u (.a(src_a), .b(src_b), .op(alu_op), .y(alu_result));

    branch_unit bu (.a(rd1), .b(rd2), .funct3(inst[14:12]), .taken(taken));

    // memory access

    lsu lsu_u (.funct3(inst[14:12]), .byte_off(alu_result[1:0]), .mem_write(mem_write),
                    .rs2_data(rd2), .wdata(write_data), .be(byte_en),
                    .rdata(read_data), .load_data(load_data));

    // result mux

    always_comb begin
        case (result_src)
            2'b01: result = load_data;
            2'b10: result = pc_plus4;
            default: result = alu_result;
        endcase
    end
    
endmodule


`default_nettype wire
