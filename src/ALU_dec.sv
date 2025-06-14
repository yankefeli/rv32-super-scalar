`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.04.2025 15:47:01
// Design Name: 
// Module Name: ALU_dec
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


module ALU_dec
(
    input logic opb5,
    input logic [2:0] funct3,
    input logic funct7b5,
    input logic [1:0] ALUOp,
    output logic [3:0] ALUControl
);


logic RtypeSub;
assign RtypeSub = funct7b5 & opb5; // TRUE for R-type subtract

always_comb begin
    
    case(ALUOp)
        2'b00: ALUControl = 4'b0000; // addition
        
        2'b01: case(funct3) //B-type
                   3'b000: ALUControl = 4'b1101;  //se
                   3'b001: ALUControl = 4'b1101;
                   3'b100: ALUControl = 4'b0101;  //slt
                   3'b101: ALUControl = 4'b0101; 
                   3'b110: ALUControl = 4'b1100;  //sltu
                   3'b111: ALUControl = 4'b1100;
               endcase
    
        default: case(funct3) // R-type or I-type ALU
                     3'b000: if (RtypeSub) ALUControl = 4'b0001; // sub
                             else ALUControl = 4'b0000; // add, addi
                     
                     3'b001: if (!funct7b5) ALUControl = 4'b1110; // sll, slli   
                             else ALUControl = 4'b1111; //clz, cpop, ctz  
                                                                   
                     3'b010: ALUControl = 4'b0101; // slt, slti
                     3'b011: ALUControl = 4'b1100; // sltu, sltiu
                     3'b100: ALUControl = 4'b1010; // xor, xori
                     3'b110: ALUControl = 4'b0011; // or, ori
                     3'b111: ALUControl = 4'b0010; // and, andi
                     
                     3'b101: if (funct7b5) ALUControl = 4'b0111; //sra, srai
                             else ALUControl = 4'b0110;
                     
                     default: ALUControl = 4'bxxxx; // ???
                 endcase
    endcase
    
end


endmodule
