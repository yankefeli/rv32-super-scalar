`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.04.2025 22:28:46
// Design Name: 
// Module Name: Register_File
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

module Register_File
(
    input  logic [4:0]  A1, A2, A3,        // Read Address Set 1 + Write Addr 1
    input  logic [4:0]  A1_2, A2_2, A3_2,  // Read Address Set 2 + Write Addr 2
    input  logic        clk,
    input  logic        WE3,              // Write Enable for A3
    input  logic        WE3_2,            // Write Enable for A3_2
    input  logic        reset,            // Active-low reset
    input  logic        order_change_w,   // order chnage flag for wb pipe
    input  logic [31:0] WD3,              // Write Data 1
    input  logic [31:0] WD3_2,            // Write Data 2
    output logic [31:0] RD1, RD2,         // Read Outputs 1
    output logic [31:0] RD1_2, RD2_2      // Read Outputs 2
);

  logic [31:0] file [31:0];
  integer i;

  // Synchronous write: Write on negedge clk or reset
  always_ff @(negedge clk or negedge reset) begin
    if (!reset) begin
      for (i = 0; i <= 31; i = i + 1)
        file[i] <= 32'd0;
    end
    else begin
      if (WE3 && (A3 != 5'd0) && !(WE3 && (A3 == A3_2)))
        file[A3] <= WD3;
      if (WE3_2 && (A3_2 != 5'd0))  //!(WE3 && (A3 == A3_2))
        file[A3_2] <= WD3_2;
      // Çakışma durumunda A3 yazması öncelikli olur
    end
  end

  // Combinational read: destekli forwarding
  always_comb begin
  
      if(!order_change_w) begin
          file[5'd0] = 32'd0; // x0 sabit sıfır

          // Read Port Set 1
          if (WE3_2 && (A1 == A3_2) && (A1 != 5'd0))
            RD1 = WD3_2;
            
          else if (WE3 && (A1 == A3) && (A1 != 5'd0))
            RD1 = WD3;  
            
          else
            RD1 = file[A1];
          
          if (WE3_2 && (A2 == A3_2) && (A2 != 5'd0))
            RD2 = WD3_2;

          else if (WE3 && (A2 == A3) && (A2 != 5'd0))
            RD2 = WD3;
          else
            RD2 = file[A2];

          // Read Port Set 2
          
          if (WE3_2 && (A1_2 == A3_2) && (A1_2 != 5'd0))
            RD1_2 = WD3_2;
          
          else if (WE3 && (A1_2 == A3) && (A1_2 != 5'd0))
            RD1_2 = WD3;
            
          else
            RD1_2 = file[A1_2];
          
          if (WE3_2 && (A2_2 == A3_2) && (A2_2 != 5'd0))
            RD2_2 = WD3_2;
          
          else if (WE3 && (A2_2 == A3) && (A2_2 != 5'd0))
            RD2_2 = WD3;
            
          else
            RD2_2 = file[A2_2];
      end 
      
      
      
      
      else begin
          file[5'd0] = 32'd0; // x0 sabit sıfır

          // Read Port Set 1
          
          if (WE3_2 && (A1 == A3_2) && (A1 != 5'd0))
            RD1 = WD3_2;
          
            
          else if (WE3 && (A1 == A3) && (A1 != 5'd0))
            RD1 = WD3;    
            
          else
            RD1 = file[A1];
          
      
         if (WE3 && (A2 == A3) && (A2 != 5'd0))
            RD2 = WD3;
            
         else if (WE3_2 && (A2 == A3_2) && (A2 != 5'd0))
            RD2 = WD3_2;   
            
          else
            RD2 = file[A2];

          // Read Port Set 2
          
          
          if (WE3 && (A1_2 == A3) && (A1_2 != 5'd0))
            RD1_2 = WD3;
          
          else if (WE3_2 && (A1_2 == A3_2) && (A1_2 != 5'd0))
            RD1_2 = WD3_2;
         
          else
            RD1_2 = file[A1_2];
          
          if (WE3 && (A2_2 == A3) && (A2_2 != 5'd0))
            RD2_2 = WD3;
            
          else if (WE3_2 && (A2_2 == A3_2) && (A2_2 != 5'd0))
            RD2_2 = WD3_2;  
            
          else
            RD2_2 = file[A2_2];
      end   
      
  end
  
endmodule
