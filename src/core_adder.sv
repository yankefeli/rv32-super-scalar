`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2025 22:33:00
// Design Name: 
// Module Name: core_adder
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

module core_adder #( 
    parameter SIZE = 32  
) 
(
    input logic [31:0] a_i,b_i,
    output logic [31:0] sum 
);

logic [SIZE:0] n; //SIZE+1 wire bits 
 
assign n[0] =  1'b0; // op -> sum 

 
genvar j; 
 
generate 
    for(j=0;j<SIZE;j=j+1)  //SIZE times iteration, last iteration parameter is SIZE-1 
    begin 
        full_adder  
        FA_unit 
        ( 
            .a(a_i[j]), 
            .b(b_i[j]), 
            .c(n[j]), 
            .cr(n[j+1]), 
            .s(sum[j]) 
        ); 
     end 
      
endgenerate 

endmodule

