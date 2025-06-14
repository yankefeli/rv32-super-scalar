`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2025 22:37:00
// Design Name: 
// Module Name: Comparison_Unit
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

module Comparison_Unit
(
    input logic [31:0] A,B,
    input logic [1:0] cmp_op,
    output logic [31:0] o 
);
 

logic [31:0] f0;
logic f1 ,f3,f4;
logic sign;
integer i,j;
logic t, o_0;

always_comb begin
    
    t=0;
    
    for(i=0; i<=31; i=i+1) begin
        f0[i] = A[i] ^B[i];
    end
    
    if((A[31]==1 && B[31] ==1) || (A[31]==0 && B[31]==0))
    sign =1; //ayni isaret
    
    else
    sign =0;//farkli isaret
    
    
    if(sign==0) begin
        
        if(A[31])
        f3=0; //A negatif B pozitif
        
        else
        f3=1;//A pozitif B negatif
        
    end
    
    
    if(sign==1) begin
    
        if(A[31])
        f4=1; // A ve B negatif
        
        else 
        f4=0;// A ve B pozitif
    
    end
    
    
    
    for(j=0;j<=31;j=j+1) begin
        
        if(f0[31-j]==1 && t==0) begin //isaretsiz say  karsilastirma
        
           if(A[31-j]) begin
               f1=1; // A buyuk
               t=1;
           end
           
           else begin //B buyuk
               f1=0;
               t=1;
           end 
        end
    end
    
    
    case (cmp_op)
        2'b11: o_0 = !(|(f0)); //esit ise?
        //3'b001: o = o0 || o0;
        2'b01: o_0 =((!sign)&&(!f3) || (sign)&&(!f1)&&(!f4) || (sign)&&f4&&(!f1))  && (|(f0)) ; //kucuk ise
        //3'b011: o = !(((!sign)&&(!o3) || (sign)&&(!o1)&&(!o4) || (sign)&&o4&&(!o1))  && (o0 || o0));
        2'b10: o_0 = !f1 && (|(f0)); // isaretsiz kucuk ise
        //3'b101: o = !(!o1 && (o0 || o0));
    endcase

end

    assign o = {31'b0, o_0};


endmodule
