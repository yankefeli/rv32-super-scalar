`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2025 22:25:25
// Design Name: 
// Module Name: PC
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

module PC
(
    input logic [31:0] PCNext,
    input logic  CLK, 
    input logic reset,
    input logic StallF,
    output logic [31:0] PC
);


always_ff @(posedge CLK or negedge reset)
begin
    if(!reset) 
    PC<=32'h8000_0000;       //inital address for reset
    
    else if(StallF) begin
    end                      //stall 
    
    else
    PC<=PCNext;

end    


endmodule
