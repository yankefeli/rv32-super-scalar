`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2025 22:33:57
// Design Name: 
// Module Name: adder_module
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


module adder_module #( 
    parameter SIZE = 32  
) 
(
    input logic [31:0] A_i,
    input logic [31:0] B_i,
    input logic Sel_i, 
    output logic [31:0] Sum_o
);

logic [SIZE:0] n; //SIZE+1 wire bits 
 
assign n[0] =  Sel_i; 

 
genvar j; 
 
generate 
    for(j=0;j<SIZE;j=j+1)  //SIZE times iteration, last iteration parameter is SIZE-1 
    begin 
        full_adder  
        FA_unit 
        ( 
            .a(A_i[j]), 
            .b(B_i[j]^Sel_i), 
            .c(n[j]), 
            .cr(n[j+1]), 
            .s(Sum_o[j]) 
        ); 
     end 
      
endgenerate 

endmodule
