`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.06.2025 21:37:13
// Design Name: 
// Module Name: Two_Way_Datapath_ALU
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


module Two_Way_Datapath_ALU
(
    input logic         rstn_i,
    input logic         clk,
    
    //////////////////////////////////////
    input logic  [31:0] RD1_2,
    input logic  [31:0] RD2_2,          //inputs from first datapath
    input logic  [31:0] InstrD_2_o,    //RS1,2 and RD
    input logic  [31:0] ImmExtD_2,   //
    input logic  [31:0] PCPlus4D_2,  
    input logic  [31:0] PCD, 
    
    input logic Order_Change_F, Order_Change_D,
    
    input logic  [31:0] DataM, DataW,
    // DataE,
   
   
   
    input  logic         Jump,Branch,MemWrite, ALUSrc ,RegWrite,
    input  logic [3:0]   ALUControl, 
    input  logic [1:0]   ResultSrc, TargetSrc, 
    input  logic [2:0]   ForwardAE, ForwardBE,
    input  logic [2:0]   ImmSrc,
    input  logic [2:0]   order_change_i, // w, m, e
  //input  logic [31:0]  PCF,
   
    //input  logic [31:0]  addr_i, //port for reading from outside
    
    input  logic         StallF, StallD, StallE, FlushD,FlushE, FlushM,
    
    input  logic         FlushE_P_2, 
    
    input  logic         both_mem_i,
    
    
   // output logic [31:0]  Instr, //control unit input
    
  //output logic  [31:0] pc_f,        // retired program counter (fetch)      
    output logic  [31:0] pc_d,        // retired program counter (decode)     
    output logic  [31:0] pc_e,        // retired program counter (execute)    
    output logic  [31:0] pc_m,        // retired program counter (memory)     
    output logic  [31:0] pc_wb,       // retired program counter  (write back)
    
    output logic [19:15] rs1d,rs1_e, 
    output logic [24:20] rs2d,rs2_e,
    output logic [11:7]  rd_e, rd_m, rd_w, 
    output logic [4:0]   rdd,
    output logic         pcsrce, resultsrce_0, regwrite_m,regwrite_w, regwrite_e,
    
    output logic [31:0]  PCTargetE_o,
    
    /////////////////////////////////////////////////
     output logic  [4:0]   RdW_2, //output for A3_2             
     output logic          RegWriteW_2, // output for WE3_2     
     output logic  [31:0]  ResultW_2, // output for WD3_2  
     
     output logic  [31:0]  DataM_2, DataW_2,
     // DataE_2,
     
     
     output logic [31:0] Instr_o,                
     output logic [4:0 ] reg_addr_o,                   
     output logic [31:0] reg_data_o,
     output logic [31:0] mem_addr_o,
     output logic [31:0] mem_data_o,
     output logic        mem_wrt_o
     

    //////////////////////////////////////////////////
   
);
 
 // logic [31:0]instr_1, instr_2, RD1,RD2,ImmExtD,PCTargetE, four, PCNext, ALUResult, ReadData, Target;     // control define   
  
logic  memwritee, alusrce, regwritee;  
logic  [3:0] alucontrole;
logic  [1:0] resultsrce;
logic  [31:0] rd_1, rd_2, pcf, pcd, pce, immexte, pcplus4e, rd1e, rd2e;   
logic  [31:0] InstrD_1,ResultW,PCPlus4W,ImmExtE, ALUResultM, Target, PCTargetE;
logic  [11:7] RdD,RdE,RdM,RdW;
logic  [19:15] rs1e;
logic  [24:20] rs2e;
logic  [11:7] rde; 
logic [3:0] ALUControlE; 
logic  jumpe, branche; 
logic  flag;

logic Order_Change_E, Order_Change_M, Order_Change_W;
 
 
logic [1:0] targetsrce;   
logic RegWriteE, MemWriteE,JumpE,BranchE,ALUSrcE;
logic [1:0] ResultSrcE, TargetSrcE ;
logic [31:0] RD1E,RD2E,PCE,PCPlus4E;
logic [19:15] Rs1E;
logic [24:20] Rs2E;
logic [14:12] funct3e;
logic [14:12] Funct3E;
logic [31:0] instre;
logic [31:0] InstrE;

assign InstrE = instre;

assign RegWriteE = regwritee;
assign MemWriteE = memwritee;
assign JumpE = jumpe;
assign BranchE = branche;
assign ALUSrcE = alusrce;
assign ResultSrcE = resultsrce;
assign ALUControlE = alucontrole;
assign RD1E =rd1e;
assign RD2E =rd2e;
assign PCE = pce;
assign ImmExtE = immexte;
assign PCPlus4E =pcplus4e;
assign Rs1E = rs1e;
assign Rs2E = rs2e;
assign RdE = rde;
assign TargetSrcE = targetsrce;
assign Funct3E = funct3e;

assign Order_Change_E = order_change_i[0];
assign Order_Change_M = order_change_i[1];
assign Order_Change_W = order_change_i[2];


logic [31:0] ALUResult;

//-----------------------------------------------   

always_ff @(posedge clk or negedge rstn_i) begin

    if(!rstn_i) begin
        jumpe   <= 1'b0;
        branche <= 1'b0;           //initial condition for PCSrcE
    end
    
    
    else if(StallE) begin
    
    end
    
   
    else if(FlushE | FlushE_P_2) begin
        pce<= 32'b0;
        rs1e<=5'b0;
        rs2e<=5'b0;
        rde<=5'b0;
        immexte<=32'b0;
        regwritee<=1'b0;
        resultsrce<=2'b0;
        memwritee<=1'b0;
        jumpe<=1'b0;
        branche<=1'b0;
        alucontrole<=4'b0;
        alusrce<=1'b0;
        pcplus4e<=32'b0;
        rd1e<=32'b0;
        rd2e<=32'b0;
        targetsrce<=2'b0;
        funct3e<=3'b0;
        instre<=32'b0;
    end
    
    else begin
        pce<= PCD;
        rs1e<=InstrD_2_o[19:15];
        rs2e<=InstrD_2_o[24:20];
        rde<=InstrD_2_o[11:7];
        immexte<=ImmExtD_2;                   //pipe2 (first pipe)
        regwritee<=RegWrite;
        resultsrce<=ResultSrc;
        memwritee<=MemWrite;
        jumpe<= Jump;
        branche<= Branch;
        alucontrole<=ALUControl;
        alusrce<=ALUSrc;
        pcplus4e<=PCPlus4D_2;
        rd1e<=RD1_2;
        rd2e<=RD2_2;
        targetsrce <= TargetSrc;
        funct3e<=InstrD_2_o[14:12];
        instre <= InstrD_2_o;
    end
    
end   
   

logic [31:0] srcae, srcbe, writedatae, aluresultw;
logic [31:0] WriteDataE, SrcAE,SrcBE, ALUResultW;


logic [31:0] WriteDataM, PCPlus4M;
logic RegWriteM, MemWriteM;
logic [14:12] Funct3M;
logic RegWriteW;   
   
 
logic regwritem ,memwritem;
logic [1:0] resultsrcm;
logic [1:0] ResultSrcM;
logic [31:0] aluresultm, writedatam,pcplus4m,pctargetm;
logic [11:7] rdm;
logic [14:12] funct3m;
logic [31:0] PCTargetM;
logic [31:0] pcm;
logic [31:0] PCM;
logic [31:0] instrm;
logic [31:0] InstrM;
 
assign RegWriteM = regwritem;
assign ResultSrcM = resultsrcm;
assign MemWriteM = memwritem;
assign ALUResultM = aluresultm;
assign WriteDataM = writedatam;
assign RdM = rdm;
assign PCPlus4M = pcplus4m;
assign Funct3M = funct3m;
assign PCTargetM = pctargetm;
assign PCM = pcm;
assign InstrM = instrm;


/*
logic [31:0] resultw_reg, aluresult_reg;

always_ff @(posedge clk) begin
    resultw_reg <= ResultW;             //circular ? 
    
end
*/


//--------------------------------------------------------------- 
always_ff @(posedge clk or negedge rstn_i) begin
    
    if(!rstn_i) begin
    end
    
 
    else if(FlushM) begin
    
         regwritem <=  0;                       
        resultsrcm <=  0;
        memwritem <=   0;
        aluresultm <=  0;
        writedatam <=  0;
        rdm <=         0;
        pcplus4m <=    0;
        funct3m <=     0;
        pctargetm <=   0;
        pcm <=         0;
        instrm <=      0;
    end
    

    else begin
        regwritem <= RegWriteE;                          //pipe3
        resultsrcm <=ResultSrcE;
        memwritem <= MemWriteE;
        aluresultm <= ALUResult;
        writedatam <= WriteDataE;
        rdm <=RdE;
        pcplus4m <=PCPlus4E;
        funct3m <= Funct3E;
        pctargetm <= PCTargetE;
        pcm <= PCE;
        instrm <= InstrE;
    end    
end
 
 //--------------------------------------------
 
 logic regwritew;
 logic [1:0] resultsrcw;
 logic [31:0] pcplus4w,pctargetw;
 logic [11:7] rdw;
 logic [1:0] ResultSrcW;
 logic [31:0] PCTargetW;
 
 logic [31:0] pcw;
 logic [31:0] PCW;
 
 logic [31:0] instrw;
 logic [31:0] InstrW;
 
 logic [31:0] writedataw;
 logic [31:0] WriteDataW, ReadData;
 
 logic ZeroE, PCSrcE;
 
 logic [31:0] target;
 
 //logic [31:0] result;
 
 //logic [31:0] pcnext;
 
 logic memwritew;
 logic MemWriteW;
 
  

 
 
 assign RegWriteW = regwritew;
 assign ResultSrcW = resultsrcw;
 //assign ReadDataW = readdataw;
 assign PCPlus4W = pcplus4w;
 assign PCTargetW = pctargetw;
 assign RdW = rdw;
 
 assign ALUResultW = aluresultw;  // needed for tb
 assign WriteDataW = writedataw;  // needed for tb
 assign MemWriteW  = memwritew;   // meeded for tb
 assign PCW = pcw;
 assign InstrW = instrw;
 
 
 //-------------------------------------------------------------
 always_ff @(posedge clk or negedge rstn_i) begin
 
    if(!rstn_i) begin
    end
 
    else begin
        regwritew <= RegWriteM;
        resultsrcw <= ResultSrcM;
        //readdataw <= ReadData;
        pcplus4w <= PCPlus4M;          //pipe4
        pctargetw <= PCTargetM;  
        rdw<= RdM;  
        
        aluresultw <=ALUResultM; // needed for tb
        pcw <=  PCM;  
        instrw <= InstrM;    
        writedataw <= WriteDataM;    // needed for tb
        memwritew <= MemWriteM;  
    end
    
 end
 
 //-------------------------------------------------------------------------------

  
core_adder adder0 (.a_i(Target), .b_i(ImmExtE), .sum(PCTargetE));
//core_adder adder1 (.a_i(PCF), .b_i(four), .sum(PCPlus4F));     

assign PCTargetE_o = PCTargetE;   
  
  
assign flag =   (Funct3E[12]) ? ~ZeroE  : ZeroE;
        
// assign PCNext = pcnext;
//assign ResultW = result;     

assign ResultW = (ResultSrcW == 2'b00) ? ALUResultW :
                 //(ResultSrcW == 2'b01) ? ReadDataW :
                 (ResultSrcW == 2'b10) ? (Order_Change_W ? PCPlus4W - 4 : PCPlus4W) :
                 PCTargetW;

   
assign Target = target;
assign PCSrcE = (flag & BranchE) | JumpE ;


 
assign WriteDataE = writedatae;
assign SrcAE = srcae;
assign SrcBE = srcbe;
        
always_comb begin 

    /*
    case (Funct3E[12])
    1'b0: flag = ZeroE;
    1'b1: flag =~ZeroE;
    endcase
    */
    //Instr = InstrD_2;   //output for control unit
    
    rs1d = InstrD_2_o[19:15];
    rs2d = InstrD_2_o[24:20];
    rs1_e = Rs1E;
    rs2_e = Rs2E;
    rd_e = RdE;
    pcsrce= PCSrcE;
    resultsrce_0 = ResultSrcE[0];
    rd_m = RdM;
    regwrite_m = RegWriteM;
    rd_w = RdW;
    regwrite_w = RegWriteW;
    //
    //pcnext = PCNext;
    //srcb = SrcB;
    //result = Result;
    
    
    
    case(ForwardAE)
        3'b000: srcae = RD1E;
        3'b001: srcae = ResultW;
        3'b010: srcae = ALUResultM;
        3'b011: srcae = DataW;
        3'b100: srcae = DataM;
       // 3'b101: srcae = DataE;
    endcase
    
    case(ForwardBE)
        3'b000: writedatae = RD2E;
        3'b001: writedatae = ResultW;
        3'b010: writedatae = ALUResultM;
        3'b011: writedatae = DataW;
        3'b100: writedatae = DataM;
        //3'b101: writedatae = DataE;
    endcase
    
    case(ALUSrcE)
        1'b0: srcbe = WriteDataE;
        1'b1: srcbe = ImmExtE;
    endcase
    
    /*
    case(PCSrcE) 
        1'b0 : pcnext = PCPlus4F;
        1'b1 : pcnext = PCTargetE; 
    endcase
    */              
    
    /*
    case(ResultSrcW)
        2'b00: result = ALUResultW;           
       // 2'b01: result = ReadDataW;
       
        2'b10: begin
                  if (!order_change_i[2]) //!Order_Change_W
                  result = PCPlus4W; // no order chnage (PC + 8 = PC + 4 + 4 = PC_next +4)
                  
                  else
                  result = PCPlus4W - 4;  // order chnage -> PC + 8 - 4 = PC +4 
               
               end    
         
        2'b11: result = PCTargetW;   
                       
    endcase         
    */
    
    
    case(TargetSrcE)
        2'b00: target = 32'h0;
        
        2'b01: begin
                  if(!order_change_i[0])
                  target = PCE + 4; //Current PC +4 
                  
                  else
                  target = PCE;
                  
               end
        
        2'b10: target =SrcAE;
    endcase

end



//control outputs for testbench
//-----------------------------
assign reg_addr_o = RdW;
assign reg_data_o = ResultW;

assign mem_addr_o = ALUResultW;
assign mem_data_o = WriteDataW;   //32 bit
assign Instr_o    = InstrW;

assign mem_wrt_o  = MemWriteW;    //1  bit


assign regwrite_e = RegWriteE;


//assign pc_f  = PCF ;
assign pc_d  = (PCD == 32'h0)            ? 32'h0  : 
               (Order_Change_D == 1'b0)  ? PCD +4 : PCD ; 

assign pc_e  = (PCE == 32'h0)            ? 32'h0  : 
               (Order_Change_E == 1'b0)  ? PCE +4 : PCE ;
               
assign pc_m  = (PCM == 32'h0)            ? 32'h0  : 
               (Order_Change_M == 1'b0)  ? PCM +4 : PCM ; 
               
assign pc_wb = (PCW == 32'h0)            ? 32'h0  : 
               (Order_Change_W == 1'b0)  ? PCW +4 : PCW ; 




assign RdW_2 =  RdW;
assign RegWriteW_2 = RegWriteW;
assign ResultW_2 = ResultW;


assign DataM_2 = ALUResultM;
assign DataW_2 = ResultW;
//assign DataE_2 = ALUResult;




assign rdd = InstrD_2_o [11:7];


ALU d4 (.A(SrcAE), .B(SrcBE), .F(ALUResult), .Zero(ZeroE),.op(ALUControlE));

//-----------------------------     


endmodule
