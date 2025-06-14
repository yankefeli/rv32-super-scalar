`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.04.2025 16:25:21
// Design Name: 
// Module Name: Hazard_Unit
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


module Hazard_Unit
( 
    input  logic  [19:15] rs1d,rs1e,
    input  logic  [24:20] rs2d,rs2e,
    input  logic  [11:7]  rde, rdm, rdw,
    input  logic          resultsrce0,regwritee, regwritem,regwritew, pcsrce,
  //input  logic          rstn_i,                                       // Datapath1 (common)
  
  
    input  logic          order_change_e, order_change_m, order_change_w, // order change flags from common datapath  
    input  logic  [4:0]   rdd, rdd_2,     
  
    output logic          StallF, StallD, FlushD, FlushE, FlushM, FlushM_2,
    output logic          StallE, StallE_2,
    output logic  [2:0]   ForwardAE, ForwardBE,
    
    
    input  logic  [19:15] rs1d_2, rs1e_2,
    input  logic  [24:20] rs2d_2, rs2e_2,
    input  logic  [11:7]  rde_2, rdm_2, rdw_2,
    input  logic          resultsrce0_2, regwritee_2, regwritem_2, regwritew_2, pcsrce_2,
  //input  logic          rstn_i_2,                                    // Datapath2 (ALU)
    output logic          StallF_2, StallD_2, FlushD_2, FlushE_2,
    output logic  [2:0]   ForwardAE_2, ForwardBE_2,
    output logic          StallF_P, StallD_P,   FlushE_P,     FlushD_P,
    output logic                    StallD_P_2, FlushE_P_2, FlushD_P_2
);
    
logic lwstall_mem, lwstall_parallel;  
logic lwstall_mem_2, lwstall_parallel_2;  
logic [2:0] order_flag;

assign order_flag = {order_change_e, order_change_m, order_change_w}; 

assign StallF_P = lwstall_parallel | lwstall_parallel_2;
//assign StallF_P_2 = lwstall_parallel | lwstall_parallel_2;

assign StallD_P =  lwstall_parallel;
assign StallD_P_2 = lwstall_parallel_2;

assign FlushE_P = lwstall_parallel;
assign FlushE_P_2 = lwstall_parallel_2;

assign FlushD_P = lwstall_parallel_2;
assign FlushD_P_2 = lwstall_parallel;

/*
always_ff @(negedge rstn_i) begin
    StallF     <= 1'b0;
    StallD     <= 1'b0;
    FlushD     <= 1'b1;        //initial ?
    FlushE     <= 1'b1;
    ForwardAE  <= 2'b00;
    ForwardBE  <= 2'b00;
end
*/
/////////////////////////////////////////////////////////////////////////////////////////
always_comb begin
    
  
        // if ( ((rs1e == rde_2) &&  regwritee_2) && (rs1e != 0) && order_change_e)  ForwardAE = 3'b101;       // parallel forwarding
         
    if ( ((rs1e == rdm_2) &&  regwritem_2) && (rs1e != 0))  ForwardAE = 3'b100; // forward from second datapath M  
    
    else if ( ((rs1e == rdm) &&  regwritem) && (rs1e != 0)) ForwardAE = 3'b010;    // forward from common datapath M
    
    else if ( ((rs1e == rdw_2) &&  regwritew_2) && (rs1e != 0)) ForwardAE = 3'b011; //forward from second datapath W
       
    else if ( ((rs1e == rdw) && regwritew) && (rs1e != 0)) ForwardAE = 3'b001;     // forward from common datapath W
    
    else ForwardAE = 3'b000;     // No forwarding                // rs1 forwarding for Datapath1 (common)
      
      
    if (order_change_e)  begin
        lwstall_mem = resultsrce0 && ((rs1d ==rde) || (rs2d==rde));  
        lwstall_parallel = (rs1d == rdd_2  && rs1d != 0) | (rs2d == rdd_2  && rs2d != 0); // decoede stage
    end    
    
    else begin
        lwstall_mem = resultsrce0 && ((rs1d ==rde) || (rs2d==rde));
        lwstall_parallel =0;
    end    
    
    StallF = lwstall_mem;
    StallD = lwstall_mem;
    StallE = 0;                      // common datapath stall, flush
    
    FlushD = pcsrce | pcsrce_2;      // flush when bracnh
    FlushE = lwstall_mem | pcsrce | pcsrce_2; // flush when branch or mem stall
    
    
    FlushM = (order_change_e && pcsrce_2); // flush when branch
    
end
    

always_comb begin

        //if ( ((rs2e == rde_2) &&  regwritee_2) && (rs2e != 0)&& order_change_e)  ForwardBE = 3'b101;       // parallel forwarding
        
   if ( ((rs2e == rdm_2) &&  regwritem_2) && (rs2e != 0))  ForwardBE = 3'b100; // forward from second datapath M  

   else if ( ((rs2e == rdm) &&  regwritem) && (rs2e != 0)) ForwardBE = 3'b010;    // forward from common datapath M
   
   else if ( ((rs2e == rdw_2) &&  regwritew_2) && (rs2e != 0)) ForwardBE = 3'b011; //forward from second datapath W
          
   else if ( ((rs2e == rdw) && regwritew) && (rs2e != 0)) ForwardBE = 3'b001;     // forward from common datapath W
   
   else ForwardBE = 3'b000;     // No forwarding                // rs2 forwarding for Datapath1 (common)
 
end


//////////////////////////////////////////////////////////////////////////////////



always_comb begin
          
       //   if ( ((rs1e_2 == rde) &&  regwritee) && (rs1e_2 != 0) && !order_change_e)  ForwardAE_2 = 3'b101;       // parallel forwarding      
    
    if (((rs1e_2 == rdm_2) &&  regwritem_2) && (rs1e_2 != 0)) ForwardAE_2 = 3'b010;
    
    else  if (((rs1e_2 == rdm) &&  regwritem) && (rs1e_2 != 0))     ForwardAE_2 = 3'b100;
    
    else if (((rs1e_2 == rdw_2) && regwritew_2) && (rs1e_2 != 0)) ForwardAE_2 = 3'b001;
    
    else if (((rs1e_2 == rdw) &&  regwritew) && (rs1e_2 != 0)) ForwardAE_2 = 3'b011;
    
    else ForwardAE_2 = 3'b000; 
        
   // Forwarding for second datapath
     
    if (!order_change_e) begin 
        lwstall_mem_2 = resultsrce0_2 && ((rs1d_2 ==rde_2) || (rs2d_2==rde_2));  
        lwstall_parallel_2 = (rs1d_2 == rdd  && rs1d_2 !=0) | (rs2d_2 == rdd && rs2d_2 != 0);
    end     
    
    else begin
        lwstall_mem_2 = resultsrce0_2 && ((rs1d_2 ==rde_2) || (rs2d_2==rde_2));
        lwstall_parallel_2 =0;
    end  
    
    StallF_2 = lwstall_mem_2; 
    StallD_2 = lwstall_mem_2; 
    StallE_2 = 0;               
    
    FlushD_2 = pcsrce_2 | pcsrce;
    FlushE_2 = lwstall_mem_2 | pcsrce_2 | pcsrce;
    
    FlushM_2 = (!order_change_e && pcsrce); // flush when branch
 
end


always_comb begin

       // if ( ((rs2e_2 == rde) &&  regwritee) && (rs2e_2 != 0) && !order_change_e)  ForwardBE_2 = 3'b101;       // parallel forwarding   

   if (((rs2e_2 == rdm_2) &&  regwritem_2) && (rs2e_2 != 0)) ForwardBE_2 = 3'b010;
   
   else if (((rs2e_2 == rdm) &&  regwritem) && (rs2e_2 != 0))     ForwardBE_2 = 3'b100;
   
   else if (((rs2e_2 == rdw_2) && regwritew_2) && (rs2e_2 != 0)) ForwardBE_2 = 3'b001;
   
   else if (((rs2e_2 == rdw) &&  regwritew) && (rs2e_2 != 0)) ForwardBE_2 = 3'b011;
   
   else ForwardBE_2 = 3'b000;

end

endmodule
