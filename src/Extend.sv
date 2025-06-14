`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2025 22:31:01
// Design Name: 
// Module Name: Extend
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


module Extend
(
    input logic [31:7] Instr, 
    input logic [31:7] Instr_2, 
    input logic [2:0] ImmSrc, ImmSrc_2, 
    output logic [31:0] ImmExt,
    output logic [31:0] ImmExt_2
);

always_comb  begin

    case(ImmSrc)
        3'b000: ImmExt = {{20{Instr[31]}}, Instr[31:20]};  // I
        3'b001: ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]}; // S
        3'b010: ImmExt = {{20{Instr[31]}}, Instr[7], Instr[30:25], Instr[11:8], 1'b0}; // B
        3'b011: ImmExt = {{12{Instr[31]}}, Instr[19:12], Instr[20], Instr[30:21], 1'b0}; // J
        3'b100: ImmExt = {Instr[31:12], {12{1'b0}} }; //U
    endcase
    
    
    case(ImmSrc_2)
        3'b000: ImmExt_2 = {{20{Instr_2[31]}}, Instr_2[31:20]};  // I
        3'b001: ImmExt_2 = {{20{Instr_2[31]}}, Instr_2[31:25], Instr_2[11:7]}; // S
        3'b010: ImmExt_2 = {{20{Instr_2[31]}}, Instr_2[7], Instr_2[30:25], Instr_2[11:8], 1'b0}; // B
        3'b011: ImmExt_2 = {{12{Instr_2[31]}}, Instr_2[19:12], Instr_2[20], Instr_2[30:21], 1'b0}; // J
        3'b100: ImmExt_2 = {Instr_2[31:12], {12{1'b0}} }; //U
    endcase
    
end

endmodule

