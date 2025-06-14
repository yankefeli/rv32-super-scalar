`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2025 22:27:14
// Design Name: 
// Module Name: Instruction_Memory
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

module Instruction_Memory
#(
    parameter string IMemInitFile = "imem.mem"  // Parametre tanımı
)
(
    input  logic [31:0] A,          // PC
    output logic [31:0] RD1,        // 1. komut
    output logic [31:0] RD2         // 2. komut
);

/*
Memory Map 
8000_0000 ->2000_0000
8000_FFFF ->2000_3FFF

Only 30 bits (from MSB) from PC output needed.
*/

logic [29:0] A_0;    // 30-bit adres word aligned
logic [31:0] mem [30'h2000_0000 : 30'h2000_3FFF]; 

initial begin  
    int unsigned i;
    for (i = 32'h2000_0000; i <= 32'h2000_3FFF ; i++) begin

        mem[i] = 32'b0;
    end 
    $readmemh(IMemInitFile, mem); // parametre ile dosya adı alınır
end 

always_comb begin
    A_0 = A[31:2];          // 4 byte aligned word adresi

    RD1 = mem[A_0];         // İlk komut
    RD2 = mem[A_0 + 1];     // İkinci komut (sonraki adres)
end

endmodule

