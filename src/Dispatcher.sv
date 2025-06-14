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
    output logic [31:0] instr_o_1, instr_o_2,
    output logic        order_change,
    output logic        both_mem
);

logic instr1_mem, instr2_mem;

assign instr1_mem = (instr1[6:0] == 7'b0000011) || (instr1[6:0] == 7'b0100011);
assign instr2_mem = (instr2[6:0] == 7'b0000011) || (instr2[6:0] == 7'b0100011);

logic [31:0] instr_reg;
logic valid, instr_gone;

always_comb begin
    if (!valid) begin
        case ({instr2_mem, instr1_mem})
            2'b00: begin
                instr_o_1 = instr1;
                instr_o_2 = instr2;   // no mem instr
                both_mem = 0;
                order_change = 0;
                instr_gone = 0;
              
            end

            2'b01: begin
                instr_o_1 = instr1;
                instr_o_2 = instr2;   // instr1 is mem instr
                both_mem = 0;
                order_change = 0;
                instr_gone = 0;
           
            end

            2'b10: begin
                instr_o_1 = instr2;
                instr_o_2 = instr1;   // instr2 is mem instr
                both_mem = 0;
                order_change = 1;
                instr_gone = 0;
            
            end

            2'b11: begin
                both_mem = 1;         // both instructions are mem instr
                instr_o_1 = instr1;
                instr_o_2 = 0;
                order_change = 0;
                instr_gone = 0;
             
            end

            default: begin
                instr_o_1 = 0;
                instr_o_2 = 0;
                both_mem = 0;
                order_change = 0;
                instr_gone = 0;
           
            end
        endcase
    end 
    
    
    else begin
        instr_o_1 = instr_reg;
        instr_o_2 = 0;
        instr_gone = 1;
        both_mem = 0;
        order_change = 0;
    end
    
    
end

always_ff @(posedge clk or negedge rstn_i) begin
    if (!rstn_i) begin
        instr_reg <= 0;
        valid <= 0;
    end 
    
    else begin
        if (both_mem) begin
            instr_reg <= instr2;
            valid <= 1;
        end 
        
        else if (instr_gone == 1) begin
            valid <= 0;
        end 
        
    end
    
end

endmodule

