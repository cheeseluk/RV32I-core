module alu (input logic [31: 0 ] a, b, 
            logic [3:0] op, 
            output logic [31:0] y);

            always_comb begin : alu_cases
            y = 0; //latch prevention
            case (op) 
                4'b0: y = a+b; //add
                4'b1000: y = a - b; //sub
                4'b0001: y = a << b[4:0]; // SLL
                4'b0010: y = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0 ; // SLT
                4'b0011: y = ((a) < (b)) ? 32'b1 : 32'b0 ; // SLTU
                4'b0100: y =  a ^ b;
                4'b0101: y = a >> b[4:0]; //SRL
                4'b1101: y = $signed(a) >>> b[4:0]; // SRA
                4'b0110: y = a | b; // or
                4'b0111: y = a & b; // and
            endcase
                
            end
endmodule