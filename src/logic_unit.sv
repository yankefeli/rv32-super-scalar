`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2025 22:35:04
// Design Name: 
// Module Name: logic_unit
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

module logic_unit
(
    input logic [31:0] A,B, 
    input logic [1:0] logic_op, 
    output logic [31:0] o
);

integer i;
logic [31:0] o1,o2,o3;

always_comb begin

    for(i=0; i<32; i=i+1) begin
        o1[i] = A[i] ^ B[i];
        o2[i] = A[i] | B[i];
        o3[i] = A[i] & B[i];  
    end
    
    case(logic_op)
        2'b00: o=o3;
        2'b01: o=o2;
        2'b10: o=o1;
        default  : o=0;
    endcase
    
end



endmodule
