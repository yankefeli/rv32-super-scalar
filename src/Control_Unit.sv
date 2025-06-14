`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.04.2025 15:59:25
// Design Name: 
// Module Name: Control_Unit
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

module Control_Unit
(
    input  logic [6:0]   op ,
    input  logic [14:12] funct3,
  //input  logic         rstn_i,
    input  logic         funct7,
    output logic         Jump, Branch, MemWrite, ALUSrc, RegWrite,
    output logic [1:0]   ResultSrc, TargetSrc,
    output logic [2:0]   ImmSrc, 
    output logic [3:0]   ALUControl
);

/*
always_ff @(negedge rstn_i) begin
    Jump        <= 1'b0;
    Branch      <= 1'b0;
    MemWrite    <= 1'b0;
    ALUSrc      <= 1'b0;
    RegWrite    <= 1'b0;    //initial ?
    ResultSrc   <= 2'b00;
    TargetSrc   <= 2'b10;
    ImmSrc      <= 3'b000;
    ALUControl  <= 4'b0000;
end
*/





logic Branch0, Jump0,  MemWrite0, ALUSrc0, RegWrite0; 
logic [1:0] ResultSrc0, ALUOp0,TargetSrc0;
logic [2:0] ImmSrc0;
logic [3:0] ALUControl0;
logic flag;

Main_Decoder m_dec (.op(op), .Branch(Branch0), .Jump(Jump0), .MemWrite(MemWrite0), .ALUSrc(ALUSrc0), .RegWrite(RegWrite0)
, .ResultSrc(ResultSrc0), .ImmSrc(ImmSrc0), .ALUOp(ALUOp0), .TargetSrc(TargetSrc0) );

ALU_dec alu_dec (.opb5(op[5]), .funct3(funct3), .funct7b5(funct7), .ALUOp(ALUOp0), .ALUControl(ALUControl0));

always_comb begin

    Jump = Jump0;
    Branch = Branch0;
    MemWrite= MemWrite0;
    ALUSrc= ALUSrc0;
    RegWrite= RegWrite0;
    ///////////////////////////
    ResultSrc= ResultSrc0; 
    ImmSrc= ImmSrc0;
    TargetSrc = TargetSrc0;
    /////////////////////////
    ALUControl = ALUControl0;
end


endmodule
