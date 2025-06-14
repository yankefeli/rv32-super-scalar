`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2025 22:40:43
// Design Name: 
// Module Name: ALU
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


module ALU
(
    input logic [31:0] A,B,
    input logic [3:0] op,
    output logic [31:0] F,
    output logic Zero 
);

logic [31:0] o1,o2,o3,o4,o5;
logic n2,n3;
logic [32:0] full;

adder_module u0 (.A_i(A), .B_i(B), .Sel_i(op[0]), .Sum_o(o1));
logic_unit u1 (.A(A), .B(B), .logic_op({op[3],op[0]}), .o(o2));
Comparison_Unit u2 (.A(A), .B(B) , .cmp_op({op[3],op[0]}), .o(o3));
Barrel_shift u3 (.A(A), .B(B), .shifter_op({op[3],op[0]}), .out(o4));
Count_Unit u4 ( .A(A), .op(B[1:0]), .out(o5));

always_comb begin
    
    
    
    case(op[2:1]) 
        2'b00 : F=o1;
        2'b01 : F=o2;
        2'b10 : F=o3;
        2'b11 : if(op != 4'b1111) F=o4;
                else  F=o5; //count unit
        default : F=o1;        
    endcase
    
    Zero  = F[0];
end

endmodule
