module branch_unit import riscv_pkg::*; (
    input logic [2:0] funct3,
    input logic [31:0] a, b, //rd1, rd2
    output logic taken
);

    always_comb begin
        case (funct3) 
            F3_BEQ:  taken = (a == b);
            F3_BNE:  taken = (a != b);
            F3_BLT:  taken = ($signed(a) <  $signed(b));
            F3_BGE:  taken = ($signed(a) >= $signed(b));
            F3_BLTU: taken = (a <  b);
            F3_BGEU: taken = (a >= b);
            default: taken = 0;
        endcase
    end

endmodule
