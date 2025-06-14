`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2025 22:38:21
// Design Name: 
// Module Name: Barrel_shift
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module Barrel_shift
(
    input logic [31:0] A,B,
    input logic [1:0] shifter_op,
    output logic [31:0] out
);


logic [4:0] shamt;
assign shamt = B[4:0];

always_comb begin
    case (shifter_op)
        2'b00: out = A >> shamt;   // Sağa lojik kaydırma
        2'b10: out = A << shamt;   // Sola lojik kaydırma
        2'b01: out = $signed(A) >>> shamt; // Sağa aritmetik kaydırma
        default: out = 32'd0;      // Geçersiz op için default
    endcase
end

endmodule
