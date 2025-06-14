`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2025 22:41:44
// Design Name: 
// Module Name: Count_Unit
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

module Count_Unit
(
    input logic [31:0] A, // rs value
    input logic  [1:0] op, // first two bits of imm value (31:20)
    output logic [31:0] out
);

logic [31:0] counter; 

always_comb begin

counter = 0; 

    case(op)
        2'b00 : for (int i = 31; i>=0; i=i-1) begin
                    if(A[i] == 0) counter = counter + 1;            //clz
                    else break;
                end
                
        2'b01 : for (int i = 0; i<=31; i=i+1) begin                 //ctz
                    if(A[i] == 0) counter = counter + 1;           
                    else break;
                end
                
        2'b10 : for (int i = 0; i<=31; i=i+1)                       //cpop
                if(A[i] == 1) counter = counter + 1;  
    endcase
    
    out = counter;
end

endmodule
