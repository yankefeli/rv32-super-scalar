`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2025 22:50:31
// Design Name: 
// Module Name: Data_Memory
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


module Data_Memory
#(
    parameter string DMemInitFile = "dmem.mem"  // Parametre tanımı
)
(
    input logic [31:0] A,WD,addr_i,
    input logic CLK, WE, 
    input logic [2:0] funct3,
    output logic [31:0] RD,data_o 
);


logic [31:0] mem [32'h8000_0000 : 32'h8001_FFFF];

initial begin  

    int unsigned i;
    for (i = 32'h8000_0000; i <= 32'h8001_FFFF; i++) begin
        mem[i] = 32'b0;
    end

    $readmemh(DMemInitFile ,mem);
    
end 


always_comb  begin

    case(funct3) 
        3'b000: RD = { {24{mem[A] [7]}} ,   mem[A] [7:0] };    //lb
        3'b001: RD = { {16{mem[A] [15]}} ,   mem[A] [15:0] };  //lh
        3'b010: RD = mem[A];                                   //lw
        3'b100: RD = { {24{1'b0}} ,   mem[A] [7:0] };          //lbu 
        3'b101: RD = { {16{1'b0}} ,   mem[A] [15:0] };         //lhu
    endcase

    data_o = mem[addr_i]; //memory port for reading from outside

end


always_ff @(posedge CLK) begin
    
    if (WE) begin
        case (funct3)
            3'b000: mem[A] [7:0] <= WD [7:0];        //sb
            3'b001: mem[A] [15:0] <= WD [15:0];      //sh
            3'b010: mem[A]  <= WD;                   //sw
        endcase
    end
end


endmodule
