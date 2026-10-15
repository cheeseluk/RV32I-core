`timescale 1ns/1ps

module branch_unit_tb;
    import riscv_pkg::*;

    logic [31:0] a, b;
    logic [2:0]  funct3;
    logic        taken;
    int errors = 0;

    branch_unit dut (.a(a), .b(b), .funct3(funct3), .taken(taken));

    // The expected result, written separately from the DUT.
    function automatic logic model(input logic [2:0] f3, input logic [31:0] x, y);
        case (f3)
            F3_BEQ:  return x == y;
            F3_BNE:  return x != y;
            F3_BLT:  return $signed(x) <  $signed(y);
            F3_BGE:  return $signed(x) >= $signed(y);
            F3_BLTU: return x <  y;
            F3_BGEU: return x >= y;
            default: return 0;
        endcase
    endfunction

    task automatic check(input logic [2:0] t_f3, input logic [31:0] t_a, t_b, input logic expected);
        funct3 = t_f3; a = t_a; b = t_b;
        #1;
        if (taken !== expected) begin
            $display("FAIL funct3=%b a=%h b=%h : got %b, expected %b", funct3, a, b, taken, expected);
            errors++;
        end
    endtask

    logic [31:0] edges [5] = '{32'h0, 32'h1, 32'hFFFF_FFFF, 32'h8000_0000, 32'h7FFF_FFFF};

    initial begin
        $dumpfile("branch_unit_tb.vcd");
        $dumpvars(0, branch_unit_tb);

        // Hand-picked cases where signed and unsigned disagree
        check(F3_BLT,  32'hFFFF_FFFF, 32'd1, 1);   // -1 < 1
        check(F3_BLTU, 32'hFFFF_FFFF, 32'd1, 0);   // 0xFFFFFFFF > 1
        check(F3_BGE,  32'h8000_0000, 32'h7FFF_FFFF, 0);
        check(F3_BGEU, 32'h8000_0000, 32'h7FFF_FFFF, 1);
        check(F3_BGE,  32'd5, 32'd5, 1);           // equal counts as >=
        check(F3_BEQ,  32'd5, 32'd5, 1);
        check(F3_BNE,  32'd5, 32'd5, 0);
        check(3'b010,  32'd5, 32'd5, 0);           // not a branch funct3

        // Every funct3 against every pair of edge values, then random values
        for (int f = 0; f < 8; f++) begin
            for (int i = 0; i < 5; i++)
                for (int j = 0; j < 5; j++)
                    check(3'(f), edges[i], edges[j], model(3'(f), edges[i], edges[j]));
            for (int i = 0; i < 1000; i++) begin
                logic [31:0] ra, rb;
                ra = $urandom; rb = (i % 4 == 0) ? ra : $urandom;   // some equal pairs
                check(3'(f), ra, rb, model(3'(f), ra, rb));
            end
        end

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
