`default_nettype none
// Shows a 32-bit value as 8 hex digits on the Nexys 7-segment display.
// The digits share their segment lines, so it lights one digit at a time,
// fast enough that all 8 look lit: at 25 MHz each digit is on for
// 2^14 cycles = 0.66 ms. Anodes and segments are active low.
module sevenseg (
    input wire logic        clk, reset,
    input wire logic [31:0] value,
    output logic [7:0]  an,         // digit enables; an[0] is the rightmost
    output logic [6:0]  seg         // {g, f, e, d, c, b, a}
);

    logic [16:0] count;
    logic [2:0]  digit;
    logic [3:0]  nibble;
    logic [6:0]  lit;               // segments on, active high

    always_ff @(posedge clk) count <= reset ? '0 : count + 17'd1;

    assign digit  = count[16:14];
    assign nibble = value[4*digit +: 4];
    assign an     = ~(8'b1 << digit);

    always_comb
        case (nibble)               //   gfedcba
            4'h0: lit = 7'b0111111;
            4'h1: lit = 7'b0000110;
            4'h2: lit = 7'b1011011;
            4'h3: lit = 7'b1001111;
            4'h4: lit = 7'b1100110;
            4'h5: lit = 7'b1101101;
            4'h6: lit = 7'b1111101;
            4'h7: lit = 7'b0000111;
            4'h8: lit = 7'b1111111;
            4'h9: lit = 7'b1101111;
            4'hA: lit = 7'b1110111;
            4'hB: lit = 7'b1111100; // b
            4'hC: lit = 7'b0111001;
            4'hD: lit = 7'b1011110; // d
            4'hE: lit = 7'b1111001;
            default: lit = 7'b1110001; // F
        endcase

    assign seg = ~lit;

endmodule

`default_nettype wire
