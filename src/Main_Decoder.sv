`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.04.2025 15:43:29
// Design Name: 
// Module Name: Main_Decoder
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


module Main_Decoder
(
    input logic [6:0] op ,
    output logic Branch,Jump,MemWrite,ALUSrc,RegWrite,
    output logic [1:0] ResultSrc,ALUOp,TargetSrc,
    output logic [2:0] ImmSrc
);

logic [13:0] controls;

always_comb begin
    
    case(op)
        // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump_TargetSrc
        7'b0000000: controls = 14'b0_000_0_0_00_0_00_0_00; //flush
        7'b0000011: controls = 14'b1_000_1_0_01_0_00_0_01; // lw
        7'b0100011: controls = 14'b0_001_1_1_00_0_00_0_01; // sw
        7'b0110011: controls = 14'b1_xxx_0_0_00_0_10_0_01; // R-type
        7'b1100011: controls = 14'b0_010_0_0_00_1_01_0_01; // B-type
        7'b0010011: controls = 14'b1_000_1_0_00_0_10_0_01; // I-type ALU
        7'b0010111: controls = 14'b1_100_x_0_11_0_xx_0_01; // U-type (auipc)
        7'b0110111: controls = 14'b1_100_x_0_11_0_xx_0_00; // U-type (lui)
        7'b1101111: controls = 14'b1_011_0_0_10_0_00_1_01; // j-type (jal)
        7'b1100111: controls = 14'b1_000_1_0_10_0_00_1_10; // jalr
        default:    controls = 14'bx_xxx_x_x_xx_x_xx_x_x; // ???
    endcase
    
    {RegWrite, ImmSrc, ALUSrc, MemWrite,
    ResultSrc, Branch, ALUOp, Jump , TargetSrc} = controls;
    
end

endmodule

