module core import riscv_pkg::*; (
    input logic clk, reset,
    // instruction memory
    output logic [31:0] pc,
    input logic [31:0] inst,
    // data memory
    output logic [31:0] mem_addr,
    output logic [31:0] mem_wdata,
    output logic [3:0] mem_be,      // 0000 = no write
    output logic mem_write,
    input logic [31:0] mem_rdata,
    // status
    output logic halt,        // ecall / ebreak: the PC stops
    output logic illegal      // unknown opcode
    );

    logic reg_write, alu_src_a, alu_src_b;
    logic [1:0] result_src;
    logic branch, jump, jalr;
    alu_op_e alu_op;

    control ctrl (.inst(inst), .reg_write(reg_write), .alu_op(alu_op),
                  .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
                  .mem_write(mem_write), .result_src(result_src),
                  .branch(branch), .jump(jump), .jalr(jalr),
                  .halt(halt), .illegal(illegal));

    datapath dp (.clk(clk), .reset(reset),
                     .reg_write(reg_write), .alu_op(alu_op),
                     .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
                     .mem_write(mem_write), .result_src(result_src),
                     .branch(branch), .jump(jump), .jalr(jalr), .halt(halt),
                     .pc(pc), .inst(inst),
                     .alu_result(mem_addr), .write_data(mem_wdata), .byte_en(mem_be),
                     .read_data(mem_rdata));

endmodule

