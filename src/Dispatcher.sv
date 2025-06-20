`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.06.2025 22:18:23
// Design Name: 
// Module Name: Dispatcher
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

module Dispatcher
(
    input  logic [31:0] instr1, instr2,
    input  logic        rstn_i, clk,
    input  logic [31:0] PCPlus4D, PCPlus4D_2,
    input  logic [31:0] PCD, PCD_2,
    
    input logic         lwstall_parallel,
    
    input               PCSrcE, pcsrce_2,
    
    output logic [31:0] instr_o_1, instr_o_2,
    output logic        order_change,
    output logic        both_mem,
    output logic [31:0] PCPlus4D_new, PCPlus4D_2_new,  
    output logic [31:0] PCD_new, PCD_2_new             
);

logic instr1_mem, instr2_mem;

assign instr1_mem = (instr1[6:0] == 7'b0000011) || (instr1[6:0] == 7'b0100011);
assign instr2_mem = (instr2[6:0] == 7'b0000011) || (instr2[6:0] == 7'b0100011);

logic [31:0] instr_reg, PCPlus4D_reg, PCD_reg;
logic order_change_reg, lwstall_parallel_reg;
logic PCSrcE_reg, pcsrce_2_reg;
logic valid, instr_gone;

always_comb begin
    if (!valid) begin  // not both mem
    
        if (order_change_reg && lwstall_parallel_reg) begin
        
                instr_o_1 = instr_reg;
                instr_o_2 = 0;   // no mem instr
                both_mem = 0;
                order_change = 1;
                instr_gone = 0;
                PCPlus4D_new    =  PCPlus4D_reg;
                PCPlus4D_2_new  =  0;
                PCD_new         =  PCD_reg;
                PCD_2_new       =  0;   
        end
        
    
    
        else begin
    
            case ({instr2_mem, instr1_mem})
                2'b00: begin
                    instr_o_1 = instr1;
                    instr_o_2 = instr2;   // no mem instr
                    both_mem = 0;
                    order_change = 0;
                    instr_gone = 0;
                    PCPlus4D_new    =  PCPlus4D;
                    PCPlus4D_2_new  =  PCPlus4D_2;
                    PCD_new         =  PCD;
                    PCD_2_new       =  PCD_2;   
                end

                2'b01: begin
                    instr_o_1 = instr1;
                    instr_o_2 = instr2;   // instr1 is mem instr
                    both_mem = 0;
                    order_change = 0;
                    instr_gone = 0;
                    PCPlus4D_new    =  PCPlus4D;
                    PCPlus4D_2_new  =  PCPlus4D_2;
                    PCD_new         =  PCD;
                    PCD_2_new       =  PCD_2;   
                end

                2'b10: begin
                    instr_o_1 = instr2;
                    instr_o_2 = instr1;   // instr2 is mem instr
                    both_mem = 0;
                    order_change = 1;
                    instr_gone = 0;
                    PCPlus4D_new    =  PCPlus4D_2;
                    PCPlus4D_2_new  =  PCPlus4D;
                    PCD_new         =  PCD_2;
                    PCD_2_new       =  PCD;  
                end

                2'b11: begin
                    both_mem = 1;         // both instructions are mem instr
                    instr_o_1 = instr1;
                    instr_o_2 = 0;
                    order_change = 0;
                    instr_gone = 0;
                    PCPlus4D_new    =  PCPlus4D;
                    PCPlus4D_2_new  =  0;
                    PCD_new         =  PCD;
                    PCD_2_new       =  0;     
                end

                default: begin
                    instr_o_1 = instr1;
                    instr_o_2 = instr2;
                    both_mem = 0;
                    order_change = 0;
                    instr_gone = 0;
                    PCPlus4D_new    =  PCPlus4D;
                    PCPlus4D_2_new  =  PCPlus4D_2;
                    PCD_new         =  PCD;
                    PCD_2_new       =  PCD_2;   
                end
            endcase
        
        end
        
        
    end 
    
    
    else begin // both mem
    
        if(PCSrcE_reg || pcsrce_2_reg) begin   // jum/branch (ve need to flush)
            instr_o_1 = 0;
            instr_o_2 = 0;
            instr_gone = 1;          // to make valid =0
            both_mem = 0;
            order_change = 0;
            
            PCPlus4D_new    =  0;
            PCPlus4D_2_new  =  0;
            PCD_new         =  0;
            PCD_2_new       =  0;   
        end
    
        else begin
            instr_o_1 = instr_reg;
            instr_o_2 = 0;
            instr_gone = 1;      // to make valid =0
            both_mem = 0;
            order_change = 1;
            
            PCPlus4D_new    =  PCPlus4D_reg;
            PCPlus4D_2_new  =  0;
            PCD_new         =  PCD_reg;
            PCD_2_new       =  0;   
        end
    end
    
    
end

always_ff @(posedge clk or negedge rstn_i) begin
    if (!rstn_i) begin
        instr_reg <= 0;
        PCPlus4D_reg <=0;
        PCD_reg <= 0;
        valid <= 0;
        order_change_reg      <= 0;
        lwstall_parallel_reg<= 0;
    end 
    
    else begin
        if (both_mem) begin
          //instr_reg <= instr2;
            valid <= 1;
          //PCPlus4D_reg<= PCPlus4D_2;
          //PCD_reg <= PCD_2; 
        end 
        
        else if (instr_gone == 1) begin
            valid <= 0;
        end 
        
    end
    
    order_change_reg <= order_change;
    lwstall_parallel_reg<=  lwstall_parallel;
    
    PCPlus4D_reg<= PCPlus4D_2;
    PCD_reg <= PCD_2;  
    instr_reg <= instr2;       
    
    PCSrcE_reg <= PCSrcE;
    pcsrce_2_reg <= pcsrce_2;
end

endmodule

