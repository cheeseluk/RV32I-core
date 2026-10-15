module lsu import riscv_pkg::*; (
    input logic [2:0] funct3,
    input logic [1:0] byte_off,
    input logic mem_write,
    input logic [31:0] rs2_data, // regfile rd2
    input logic [31:0] rdata, // dmem output
    output logic [3:0] be,
    output logic [31:0] wdata, // dmem write
    output logic [31:0] load_data
);

    always_comb begin //store
        be = 4'b0000;
        wdata = 32'b0;
        if (mem_write) begin
            case (funct3) 
                F3_B: begin 
                    be = 4'b0001 << byte_off;
                    wdata = {4{rs2_data[7:0]}};
                end
                F3_H: begin
                    be = 4'b0011 << byte_off;
                    wdata = {2{rs2_data[15:0]}};
                end
                default: begin // SW
                    be = 4'b1111;
                    wdata = rs2_data;
                end
            
            endcase
        end
    end

    logic [31:0] shifted;
    assign shifted = rdata >> {byte_off, 3'b000};

    always_comb begin //load
        case (funct3) 
            F3_B: load_data = {{24{shifted[7]}}, shifted[7:0]};
            F3_H: load_data = {{16{shifted[15]}}, shifted[15:0]};
            F3_BU: load_data = {24'b0, shifted[7:0]};
            F3_HU: load_data = {16'b0, shifted[15:0]};
            default: load_data = rdata; // lw.
        endcase

    end
endmodule



