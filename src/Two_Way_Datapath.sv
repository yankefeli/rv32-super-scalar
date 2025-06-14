`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.06.2025 19:11:45
// Design Name: 
// Module Name: Two_Way_Datapath
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


module Two_Way_Datapath
#(
    parameter string IMemInitFile  = "imem.mem",   // Parametre tanımı
    parameter string DMemInitFile  = "dmem.mem"  // Parametre tanımı
)
(
    input  logic         Jump,Branch,MemWrite, ALUSrc ,RegWrite, clk, rstn_i,
    input  logic [3:0]   ALUControl, 
    input  logic [1:0]   ResultSrc, TargetSrc,
    input  logic [2:0]   ForwardAE, ForwardBE,
    input  logic [2:0]   ImmSrc, ImmSrc_2,
    
    input  logic         FlushM,
    //////////////////////////////////////////
    
    input logic  [4:0]   RdW_2, //input for A3_2
    input logic          RegWriteW_2, // input for WE3_2
    input logic  [31:0]  ResultW_2, // input for WD3_2
    
    input logic  [31:0]  DataM_2, DataW_2, 
    //DataE_2, // bypass data from second datapath
    
    input logic  [31:0]  PCTargetE_i,   // pc target from second datapath
    
    ////////////////////////////////////////////
    
    input  logic [31:0]  addr_i, //port for reading from outside
    
    input  logic         StallF, StallD, StallE, FlushD,FlushE,
    
    input  logic         StallF_P, StallD_P,   FlushE_P,     FlushD_P, StallD_P_2,  FlushD_P_2,
    
    input  logic         pcsrce_2, //branch/jump flag from second datapath
    
    output logic [31:0]  Instr, //control unit input
    
    output logic [19:15] rs1d,rs1_e, 
    output logic [24:20] rs2d,rs2_e,
    output logic [11:7]  rd_e, rd_m, rd_w, 
    output logic [4:0]   rdd,
    output logic         pcsrce, resultsrce_0, regwrite_m,regwrite_w, regwrite_e,
    
    output logic [31:0]  Instr_o,  //testbench output
    output logic [31:0]  data_o,
    output logic [4:0]   reg_addr_o,
    output logic [31:0]  reg_data_o,          //testbench outputs
    output logic [31:0]  mem_addr_o,
    output logic [31:0]  mem_data_o,
    output logic         mem_wrt_o,
    
    
    output logic [31:0]  DataM,DataW,
    //DataE,        // bypass data for second datapath
    
    
    
    output logic  [31:0] pc_f,        // retired program counter (fetch)      
    output logic  [31:0] pc_d,        // retired program counter (decode)     
    output logic  [31:0] pc_e,        // retired program counter (execute)    
    output logic  [31:0] pc_m,        // retired program counter (memory)     
    output logic  [31:0] pc_wb,       // retired program counter  (write back)
    
    output logic  [31:0] PCF_2_o,     // PCF output for second datapath
    
    output logic  [31:0] Instr_raw, Instr_raw_2,    // Output From Instruction Memory  
    
    output logic  [31:0] RD1_2,
    output logic  [31:0] RD2_2,       //Outputs for second datapath
    output logic  [31:0] InstrD_2_o,    //RS1,2 and RD
    output logic  [31:0] ImmExtD_2,   //
    output logic  [31:0] PCPlus4D_2,
    output logic  [31:0] PCD_o,
    output logic  [2:0]  order_change_o,
    output logic         Order_Change_D_o,
    output logic         Order_Change_F_o,
    
    output logic         both_mem_o
    
    
);




logic  jumpe, branche; 
logic  flag; 
  
/*              
always_ff @(negedge rstn_i)
begin
    jumpe   <= 1'b0;
    branche <= 1'b0;           //initial condition
end             
*/      
       
              
logic [31:0]instr_1, instr_2, RD1,RD2,ImmExtD,PCTargetE, four, PCNext, ALUResult, ReadData, Target;             
logic [31:0] pcnext, result,target;
logic [4:0] a1_1, a1_2, a1_2_test;
logic [4:0] a2_1, a2_2;
logic ZeroE, PCSrcE;
 
logic  memwritee, alusrce, regwritee;  
logic  [3:0] alucontrole;
logic  [1:0] resultsrce;
logic  [31:0] rd_1, rd_2, pcf1 ,pcplus4f1, pcf2, pcplus4f2, pcd,pce,immexte,pcplus4e,rd1e,rd2e;   
logic  [31:0] InstrD_1,InstrD_2, ResultW,PCF,PCD, PCPlus4F , PCPlus4D, PCPlus4W,ImmExtE, ALUResultM;
logic  [11:7] RdD,RdE,RdM,RdW;
logic  [19:15] rs1e;
logic  [24:20] rs2e;
logic  [11:7] rde; 



// New outputs for super-scalar arch.




assign DataW = ResultW;   
assign DataM = ALUResultM;
//assign DataE = ALUResult;


//assign PCPlus4D_2 = PCPlus4D_i2;  
assign InstrD_2_o = InstrD_2;
//assign PCD_o = PCD;

assign four =32'h8;
assign a1_1 = InstrD_1[19:15];
assign a2_1 = InstrD_1[24:20];

assign a1_2 = InstrD_2[19:15];
assign a1_2_test = InstrD_2[19:15];
assign a2_2 = InstrD_2[24:20];


//assign a3 = InstrD[11:7];
assign InstrD_1 = rd_1; 
assign InstrD_2 = rd_2;

assign PCD = pcf1;
assign PCD_o = pcf2;

assign PCPlus4D_2 = pcplus4f2;
assign PCPlus4D = pcplus4f1;


 
 
logic [31:0] srcae, srcbe, writedatae, aluresultw;
logic [31:0] WriteDataE, SrcAE,SrcBE, ALUResultW;

logic [3:0] ALUControlE; 
logic [31:0] WriteDataM, PCPlus4M;
logic [31:0] instr_o_1, instr_o_2;
logic RegWriteM, MemWriteM;
logic [14:12] Funct3M;
logic RegWriteW;


logic order_change, both_mem;
logic order_change_d, order_change_e, order_change_m, order_change_w;
logic Order_Change_D, Order_Change_E, Order_Change_M, Order_Change_W;
  
Instruction_Memory #(
   .IMemInitFile(IMemInitFile)  
)
d0 (.A(PCF) , .RD1(instr_1), .RD2(instr_2));  

Dispatcher d6  ( .instr1(instr_1), .instr2(instr_2), .instr_o_1(instr_o_1), .instr_o_2(instr_o_2), 
.order_change(order_change), .both_mem(both_mem), .clk(clk), .rstn_i(rstn_i));
 
Register_File d1(.A1(a1_1) , .A2(a2_1), .A3(RdW), .A1_2(a1_2), .A2_2(a2_2), .A3_2(RdW_2), .clk(clk),
 .WE3(RegWriteW), .WE3_2(RegWriteW_2), .WD3(ResultW), .WD3_2(ResultW_2),
 .RD1(RD1), .RD2(RD2), .RD1_2(RD1_2), .RD2_2(RD2_2), .reset(rstn_i), .order_change_w(Order_Change_W) ); 
 
Extend d2 (.Instr(InstrD_1[31:7]), .Instr_2(InstrD_2[31:7]), .ImmSrc(ImmSrc), .ImmSrc_2(ImmSrc_2), .ImmExt(ImmExtD), .ImmExt_2(ImmExtD_2) ); 
     
PC d3 (.PCNext(PCNext), .CLK(clk), .PC(PCF), .StallF(StallF | StallF_P | both_mem), .reset(rstn_i));
 
ALU d4 (.A(SrcAE), .B(SrcBE), .F(ALUResult), .Zero(ZeroE),.op(ALUControlE));
 
Data_Memory #(
   .DMemInitFile(DMemInitFile)  
)
d5 (.A(ALUResultM), .WD(WriteDataM), .CLK(clk), .WE(MemWriteM), .RD(ReadData), .funct3(Funct3M), .addr_i(addr_i), .data_o(data_o)); 


assign Instr_raw   = instr_1; // output from imem 
assign Instr_raw_2 = instr_2;       


//---------------------------------------------
always_ff @(posedge clk or negedge rstn_i) begin
    
    if (!rstn_i) begin
        rd_1<=32'b0;
        rd_2<=32'b0;
        
        pcplus4f1<=32'b0;     //reset for pipe
        pcf1<= 32'b0;   
        
        
        
        order_change_d<=1'b0; 
        
        pcplus4f2<=32'b0;     //reset for pipe
        pcf2<= 32'b0; 
                   
    end
    
    else if(StallD) begin
    end
    
    
    else if (FlushD) begin
        rd_1<=32'b0;
        rd_2<=32'b0;
        
        pcplus4f1<=32'b0;     
        pcf1 <= 32'b0; 
        
        order_change_d<=1'b0;                     //pipe1
        
        pcplus4f2<=32'b0;     //reset for pipe
        pcf2<= 32'b0; 
        
    end
    
    else if (StallD_P && FlushD_P_2) begin
        /*
        rd_2 <= instr_o_2;
        pcplus4f2 <= PCPlus4F;
        pcf2 <= PCF;
        */
        
        rd_2 <= 0;
        pcplus4f2 <= 0;
        pcf2 <= 0;
        
    end
    
    
    else if (StallD_P_2 && FlushD_P || both_mem) begin
        /*
        rd_1 <= instr_o_1;
        pcplus4f1 <= PCPlus4F;
        pcf1 <= PCF;
        */
        
        rd_1 <= 0;
        pcplus4f1 <= 0;
        pcf1 <= 0;
        
    end
    
  
    
    
   
    else begin
        rd_1<=instr_o_1;
        rd_2<=instr_o_2;
        
        order_change_d <= order_change;
        
        pcplus4f1<=PCPlus4F;
        pcf1 <= PCF;
        
        pcplus4f2<=PCPlus4F;
        pcf2 <= PCF;
     
    end
    
end   
//--------------------------------------------  
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

assign Order_Change_D = order_change_d;

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

assign Order_Change_E = order_change_e;
//-----------------------------------------------   

always_ff @(posedge clk or negedge rstn_i) begin

    if(!rstn_i) begin
        jumpe   <= 1'b0;
        branche <= 1'b0;           //initial condition for PCSrcE
        order_change_e<=1'b0;
    end
    
    else if (StallE) begin
    
    end
    
    else if(FlushE |FlushE_P) begin
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
        order_change_e<=1'b0;
    end
    
    else begin
        pce<= PCD;
        rs1e<=InstrD_1[19:15];
        rs2e<=InstrD_1[24:20];
        rde<=InstrD_1[11:7];
        immexte<=ImmExtD;                   //pipe2
        regwritee<=RegWrite;
        resultsrce<=ResultSrc;
        memwritee<=MemWrite;
        jumpe<= Jump;
        branche<= Branch;
        alucontrole<=ALUControl;
        alusrce<=ALUSrc;
        pcplus4e<=PCPlus4D;
        rd1e<=RD1;
        rd2e<=RD2;
        targetsrce <= TargetSrc;
        funct3e<=InstrD_1[14:12];
        instre <= InstrD_1;
        order_change_e <= Order_Change_D;
    end
    
end   
   
 
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
assign Order_Change_M = order_change_m;



/*
logic [31:0] resultw_reg;

always_ff @(posedge clk) begin       // circular ?
    resultw_reg <= ResultW;
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
        order_change_m <= 0;
        
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
        order_change_m <= Order_Change_E;
    end    
end
 
 //--------------------------------------------
 
 logic regwritew;
 logic [1:0] resultsrcw;
 logic [31:0] readdataw,pcplus4w,pctargetw;
 logic [11:7] rdw;
 logic [1:0] ResultSrcW;
 logic [31:0] ReadDataW,PCTargetW;
 
 logic [31:0] pcw;
 logic [31:0] PCW;
 
 logic [31:0] instrw;
 logic [31:0] InstrW;
 
 logic [31:0] writedataw;
 logic [31:0] WriteDataW;
 
 logic memwritew;
 logic MemWriteW;
 
 
 
 
 assign RegWriteW = regwritew;
 assign ResultSrcW = resultsrcw;
 assign ReadDataW = readdataw;
 assign PCPlus4W = pcplus4w;
 assign PCTargetW = pctargetw;
 assign RdW = rdw;
 
 assign ALUResultW = aluresultw;  // needed for tb
 assign WriteDataW = writedataw;  // needed for tb
 assign MemWriteW  = memwritew;   // meeded for tb
 assign PCW = pcw;
 assign InstrW = instrw;
 
 assign Order_Change_W = order_change_w;
 
 
 //-------------------------------------------------------------
 always_ff @(posedge clk or negedge rstn_i) begin
 
    if(!rstn_i) begin
    end
 
    else begin
        regwritew <= RegWriteM;
        resultsrcw <= ResultSrcM;
        readdataw <= ReadData;
        pcplus4w <= PCPlus4M;          //pipe4
        pctargetw <= PCTargetM;  
        rdw<= RdM;  
        
        aluresultw <=ALUResultM; // needed for tb
        pcw <=  PCM;  
        instrw <= InstrM;    
        writedataw <= WriteDataM;    // needed for tb
        memwritew <= MemWriteM;  
        order_change_w <= Order_Change_M;
    end
    
 end
 
 //-------------------------------------------------------------------------------

  
core_adder adder0 (.a_i(Target), .b_i(ImmExtE), .sum(PCTargetE));
core_adder adder1 (.a_i(PCF), .b_i(four), .sum(PCPlus4F));        
  
  
assign flag =   (Funct3E[12]) ? ~ZeroE  : ZeroE;
        
assign PCNext = pcnext;

//assign ResultW = result;      

  
assign Target = target;
assign PCSrcE = (flag & BranchE) | JumpE ;


 
assign WriteDataE = writedatae;
assign SrcAE = srcae;
assign SrcBE = srcbe;


assign ResultW = (ResultSrcW == 2'b00) ? ALUResultW :
                 (ResultSrcW == 2'b01) ? ReadDataW :
                 (ResultSrcW == 2'b10) ? (Order_Change_W ? PCPlus4W : (PCPlus4W - 4)) :
                 PCTargetW;



        
always_comb begin 

    /*
    case (Funct3E[12])
    1'b0: flag = ZeroE;
    1'b1: flag =~ZeroE;
    endcase
    */
    Instr = InstrD_1;   //output for control unit
    
    rs1d = InstrD_1[19:15];
    rs2d = InstrD_1[24:20];
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
        3'b011: srcae = DataW_2;
        3'b100: srcae = DataM_2;
       // 3'b101: srcae = DataE_2;
    endcase
    
    case(ForwardBE)
        3'b000: writedatae = RD2E;
        3'b001: writedatae = ResultW;
        3'b010: writedatae = ALUResultM;
        3'b011: writedatae = DataW_2;
        3'b100: writedatae = DataM_2;
       // 3'b101: writedatae = DataE_2;
    endcase
    
    case(ALUSrcE)
        1'b0: srcbe = WriteDataE;
        1'b1: srcbe = ImmExtE;
    endcase
    
    
    case( {pcsrce_2, PCSrcE} ) 
        2'b00 : pcnext = PCPlus4F;
        2'b01 : pcnext = PCTargetE; 
        2'b10 : pcnext = PCTargetE_i;
        
        2'b11 : begin  // jump/branch from both datapaths
        
            if(!Order_Change_E)
            pcnext = PCTargetE;
            
            else
            pcnext = PCTargetE_i;
    
        end
        
    endcase
                  
    /*
    case(ResultSrcW)
        2'b00: result = ALUResultW;           
        2'b01: result = ReadDataW;
        
        2'b10: begin
                   if(!Order_Change_W)   
                   result = PCPlus4W - 4;  // (PC) + 8 -4 = PC +4 (no order change)
                   
                   else
                   result = PCPlus4W;      //  (PC + 4) + 4 = PC +8 (for order chnage)
                   
               end       
  
        2'b11: result = PCTargetW;                  
    endcase   
    */
    
      
        
    
    case(TargetSrcE)
        2'b00: target = 32'h0;
        
        2'b01: begin 
                  if(!Order_Change_E) // if there is no order change then, PCE is PC of first isntr
                  target = PCE;
                  
                  else
                  target = PCE +4;   // if there is an order chnage then , we need PC of the second instr    
                  
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


assign pc_f  =   (PCF == 32'h0) ? 32'h0 : PCF;

assign PCF_2_o = (PCF == 32'h0) ? 32'h0 : PCF+4;

assign pc_d  = (PCD ==32'h0)            ?  32'h0 :
               (Order_Change_D == 1'b0) ?  PCD   : PCD +4;

assign pc_e  = (PCE ==32'h0)            ?  32'h0 :
               (Order_Change_E == 1'b0) ?  PCE   : PCE +4;

assign pc_m  = (PCM ==32'h0)            ?  32'h0 :
               (Order_Change_M == 1'b0) ?  PCM   : PCM +4;

assign pc_wb = (PCW ==32'h0)            ?  32'h0 :
               (Order_Change_W == 1'b0) ?  PCW   : PCW +4;

//-----------------------------     


assign order_change_o = {Order_Change_W, Order_Change_M, Order_Change_E};
assign rdd = InstrD_1[11:7];

assign Order_Change_F_o = order_change;
assign Order_Change_D_o = Order_Change_D;

assign both_mem_o = both_mem;



endmodule
