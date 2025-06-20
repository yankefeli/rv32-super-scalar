`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.04.2025 16:34:30
// Design Name: 
// Module Name: riscv_multicycle
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

module riscv_multicycle 
#(
    parameter DMemInitFile  = "dmem.mem",       // data memory initialization file
    parameter IMemInitFile  = "imem.mem",       // instruction memory initialization file
    parameter XLEN          = 32,
    parameter TableFile     =  "table.log",    // processor state and used for verification/grading
    parameter ModelFile     =  "model.log",    // I added this file to make sure the core is working properly (just like the prev. homeworks)
    parameter IssueWidth    = 2               // 
    
)   
(
    input  logic             clk_i,       // system clock
    input  logic             rstn_i,      // system reset
    
    
    input  logic  [XLEN-1:0] addr_i,      // memory adddres input for reading
    output logic  [XLEN-1:0] data_o,      // memory data output for reading
    
    
    output logic             update_model [IssueWidth],
    output logic             update_o     [IssueWidth],    // retire signal
    output logic  [XLEN-1:0] Instr_o      [IssueWidth],     // retired instruction
    output logic  [     4:0] reg_addr_o   [IssueWidth],  // retired register address
    output logic  [XLEN-1:0] reg_data_o   [IssueWidth],  // retired register data
    output logic  [XLEN-1:0] mem_addr_o   [IssueWidth],  // retired memory address
    output logic  [XLEN-1:0] mem_data_o   [IssueWidth],  // retired memory data
    output logic  [XLEN-1:0] pc_o         [IssueWidth],
    output logic             mem_wrt_o    [IssueWidth],    // retired memory write enable signal
    
    output logic  [XLEN-1:0] pc_f [IssueWidth],        // retired program counter (fetch)
    output logic  [XLEN-1:0] pc_d [IssueWidth],        // retired program counter (decode)
    output logic  [XLEN-1:0] pc_e [IssueWidth],        // retired program counter (execute)
    output logic  [XLEN-1:0] pc_m [IssueWidth],        // retired program counter (memory) 
    output logic  [XLEN-1:0] pc_wb[IssueWidth],       // retired program counter  (write back)
    
    output logic             StallF [IssueWidth],
    output logic             StallD [IssueWidth],      // Stall outputs for tb
    
    output logic             FlushD [IssueWidth],
    output logic             FlushE [IssueWidth],      // Flush outputs for tb
    
    
    output logic             StallF_P_o ,
    output logic             StallD_P_o [IssueWidth],      // Stall outputs for tb
    
    output logic             FlushD_P_o [IssueWidth],
    output logic             FlushE_P_o [IssueWidth]      // Flush outputs for tb
    
    
);
  
logic pcsrce1,MemWrite1, ALUSrc1 ,RegWrite1, Jump1, Branch1, resultsrce_01, regwrite_m1, regwrite_w1;
logic [3:0] ALUControl1;
logic [2:0] ImmSrc1;
logic [1:0] ResultSrc1, TargetSrc1;
logic [2:0] ForwardAE1, ForwardBE1;
logic StallF1, StallD1, FlushD1, FlushE1;
logic [31:0] Instr1, PCF;
logic [19:15] rs1d1, rs1_e1;
logic [24:20] rs2d1, rs2_e1;
logic [11:7]  rd_e1, rd_m1, rd_w1;
logic [31:0] DataM, DataM_2, DataW, DataW_2;

logic [31:0]  Instr_raw, Instr_raw_2, Instr_o_0, Instr_o_0_2;

logic [4:0] reg_addr_o1;




logic pcsrce1_2, MemWrite1_2, ALUSrc1_2, RegWrite1_2, Jump1_2, Branch1_2, resultsrce_01_2, regwrite_m1_2, regwrite_w1_2;
logic [3:0] ALUControl1_2;
logic [2:0] ImmSrc1_2;
logic [1:0] ResultSrc1_2, TargetSrc1_2;
logic [2:0] ForwardAE1_2, ForwardBE1_2;
logic StallF1_2, StallD1_2, FlushD1_2, FlushE1_2;
//logic [31:0] Instr1_2;
logic [19:15] rs1d1_2, rs1_e1_2;
logic [24:20] rs2d1_2, rs2_e1_2;
logic [11:7]  rd_e1_2, rd_m1_2, rd_w1_2;
logic [4:0] rdd, rdd_2;
logic StallE1, StallE1_2;
logic FlushM, FlushM_2;
logic [2:0] order_change_o;
logic regwrite_e1, regwrite_e1_2;
//logic [31:0] DataE, DataE_2;


logic [31:0] reg_data_o1, reg_data_o1_2;
logic [31:0] mem_addr_o1, mem_addr_o1_2;
logic [31:0] mem_data_o1, mem_data_o1_2;
logic        mem_wrt_o1,  mem_wrt_o1_2;
logic        path1_zero, path2_zero;
logic [31:0] pc_wb_1, pc_wb_2;
logic [31:0] pc_e_1, pc_e_2;
logic [31:0] pc_d_1, pc_d_2;
logic [31:0] pc_f_1, pc_f_2;
logic [31:0] pc_m_1, pc_m_2;



logic          StallF_P, StallD_P,   FlushE_P,     FlushD_P;
logic                    StallD_P_2, FlushE_P_2, FlushD_P_2; 

logic both_mem;



//logic [31:0]  Instr_raw;

logic [4:0] reg_addr_o1_2;

logic Order_Change_D;



//assign reg_addr_o [0] = (Instr_o[6:0] == 7'b1100011) ? 5'h0 : reg_addr_o1; // send zero for branch, Instr_o = InstrW
                                                              // reg_addr_o1 = a3 (from regfile)
/*
always_comb begin
    update_o = 1;

    if (Instr_raw == 32'h0) begin
        update_o = 0;
    end
 
 end
 */
 
logic [1:0] update_counter;

always_ff @(negedge rstn_i or posedge clk_i) begin
    if (!rstn_i)
        update_counter <= 2'd0;
    else if (update_counter < 2'd3)
        update_counter <= update_counter + 2'd1;
end


/*
always_comb begin
    update_model = 1;

    if (update_counter >= 2'd3) begin
        if (Instr_o == 32'h0)
            update_model = 0;
    end
end
*/

 
assign StallF_P_o      =  StallF_P;         
assign StallD_P_o [0]  =  StallD_P;
assign FlushD_P_o [0]  =  FlushD_P;
assign FlushE_P_o [0]  =  FlushE_P;

assign StallD_P_o [1]  =  StallD_P_2;
assign FlushD_P_o [1]  =  FlushD_P_2;
assign FlushE_P_o [1]  =  FlushE_P_2;
 
 
assign pc_o[0]         =  (!order_change_o[2]) ? pc_wb_1   : pc_wb_2;
assign pc_o[1]         =  (!order_change_o[2]) ? pc_wb_2   : pc_wb_1  ;

assign pc_f [0] = pc_f_1;
assign pc_d [0] = pc_d_1;
assign pc_e [0] = pc_e_1;
assign pc_m [0] = pc_m_1;
assign pc_wb[0] = pc_wb_1;


assign pc_f [1] = pc_f_2;
assign pc_d [1] = pc_d_2;
assign pc_e [1] = pc_e_2;
assign pc_m [1] = pc_m_2;
assign pc_wb[1] = pc_wb_2;


// path1_zero ve path2_zero sinyalleri
assign path1_zero = (Instr_o_0   == 32'h0 && update_counter >= 2'd3) ? 1'b1 : 1'b0;
assign path2_zero = (Instr_o_0_2 == 32'h0 && update_counter >= 2'd3) ? 1'b1 : 1'b0;

// Ortak seçim durumu
wire [1:0] path_case = {path1_zero, path2_zero};

// update_model[0]
assign update_model[0] = 
    (path_case == 2'b00) ? 1'b1 :
    (path_case == 2'b01) ? (order_change_o[2] ? 1'b0 : 1'b1) :
    (path_case == 2'b10) ? (order_change_o[2] ? 1'b1 : 1'b0) :
    /* path_case == 2'b11 */             1'b0;

// update_model[1]
assign update_model[1] = 
    (path_case == 2'b00) ? 1'b1 :
    (path_case == 2'b01) ? (order_change_o[2] ? 1'b1 : 1'b0) :
    (path_case == 2'b10) ? (order_change_o[2] ? 1'b0 : 1'b1) :
    /* path_case == 2'b11 */             1'b0;



assign update_o[0]     =  (Instr_raw == 32'h0)   ? 1'b0 : 1'b1;
assign update_o[1]     =  (Instr_raw_2 == 32'h0) ? 1'b0 : 1'b1;  

assign Instr_o[0]      =  (!order_change_o[2]) ? Instr_o_0   : Instr_o_0_2;
assign Instr_o[1]      =  (!order_change_o[2]) ? Instr_o_0_2 : Instr_o_0  ; 

assign reg_addr_o[0] = (order_change_o[2] == 1'b0) ?
                      ((Instr_o_0[6:0]    == 7'b1100011) ? 5'h0 : reg_addr_o1) :
                      ((Instr_o_0_2[6:0]  == 7'b1100011) ? 5'h0 : reg_addr_o1_2);

assign reg_addr_o[1] = (order_change_o[2] == 1'b0) ?
                      ((Instr_o_0_2[6:0]    == 7'b1100011) ? 5'h0 : reg_addr_o1_2) :
                      ((Instr_o_0[6:0]      == 7'b1100011) ? 5'h0 : reg_addr_o1  );

assign reg_data_o[0]   =  (!order_change_o[2]) ? reg_data_o1   : reg_data_o1_2;
assign reg_data_o[1]   =  (!order_change_o[2]) ? reg_data_o1_2 : reg_data_o1  ;

assign mem_addr_o[0]   =  (!order_change_o[2]) ? mem_addr_o1 : mem_addr_o1;
assign mem_addr_o[1]   =  (!order_change_o[2]) ? mem_addr_o1 : mem_addr_o1  ;

assign mem_data_o[0]   =  (!order_change_o[2]) ? mem_data_o1 : mem_data_o1;
assign mem_data_o[1]   =  (!order_change_o[2]) ? mem_data_o1 : mem_data_o1  ;

assign mem_wrt_o[0]    =  (!order_change_o[2]) ? mem_wrt_o1  : mem_wrt_o1;
assign mem_wrt_o[1]    =  (!order_change_o[2]) ? mem_wrt_o1 : mem_wrt_o1  ;
    

assign StallF[0]= StallF1;
assign StallD[0]= StallD1;

assign StallF[1]= StallF1_2;
assign StallD[1]= StallD1_2;

assign FlushD[0] = FlushD1;
assign FlushE[0] = FlushE1;

assign FlushD[1] = FlushD1_2;
assign FlushE[1] = FlushE1_2;



logic [31:0] RD1_2;           
logic [31:0] RD2_2;        
logic [31:0] InstrD_2_o; 
logic [31:0] ImmExtD_2;  
logic [31:0] PCPlus4D_2; 
logic [31:0] PCD_o;
logic [31:0] PCTargetE_o;          
                       
logic [4:0] RdW_2;            
logic RegWriteW_2;
logic [31:0] ResultW_2;    


Two_Way_Datapath #(
   .DMemInitFile(DMemInitFile),
   .IMemInitFile(IMemInitFile) 
)
Datapath_Common 
(   
    .Jump(Jump1),
    .Branch(Branch1),
    .MemWrite(MemWrite1),
    .ALUSrc(ALUSrc1),
    .RegWrite(RegWrite1),
    
    .clk(clk_i),
    .rstn_i(rstn_i),            
    
    .TargetSrc(TargetSrc1),
    .ALUControl(ALUControl1),
    .ImmSrc(ImmSrc1),
    .ResultSrc(ResultSrc1),
    .Instr(Instr1),            // Control Unit Output
    
    .ForwardAE(ForwardAE1),
    .ForwardBE(ForwardBE1),
    
    .StallF(StallF1),
    .StallD(StallD1),
    .StallE(StallE1),
    
    .FlushD(FlushD1),
    .FlushE(FlushE1),
    .FlushM(FlushM),
    
    .rs1d(rs1d1),
    .rs1_e(rs1_e1),
    .rs2d(rs2d1),
    .rs2_e(rs2_e1),
    .rd_e(rd_e1),
    .rd_m(rd_m1),
    .rd_w(rd_w1),
    .rdd(rdd),
    
    .pcsrce(pcsrce1), 
    .pcsrce_2(pcsrce1_2),
    
    .resultsrce_0(resultsrce_01),
    .regwrite_m(regwrite_m1),
    .regwrite_w(regwrite_w1),
    .regwrite_e(regwrite_e1),
    
    .addr_i(addr_i),                 //input for data mem port (additional)
    
    .data_o(data_o),        
    .Instr_o(Instr_o_0),   
    
    .reg_addr_o(reg_addr_o1),        //conditional output for tb
    
    .reg_data_o(reg_data_o1),
    
    .mem_addr_o(mem_addr_o1),         //testbecnh outputs
    .mem_data_o(mem_data_o1),
    .mem_wrt_o(mem_wrt_o1),
    
    
    .pc_f (pc_f_1),  
    .pc_d (pc_d_1),  
    .pc_e (pc_e_1),                     // table components for pipe.log
    .pc_m (pc_m_1),  
    .pc_wb(pc_wb_1),
    
    .PCF_2_o(pc_f_2),                    // Second Fethced output (Datapath2)
    
    .Instr_raw(Instr_raw),            // output from imem   
    .Instr_raw_2 (Instr_raw_2),     
    
    
    .RD1_2(RD1_2),     
    .RD2_2(RD2_2),     
    .InstrD_2_o(InstrD_2_o),
    .ImmExtD_2(ImmExtD_2),            // output to the second datapath
    .PCPlus4D_2_o(PCPlus4D_2),
    .PCD_o(PCD_o),
    
    .order_change_o(order_change_o),
    
    
    .RdW_2(RdW_2),
    .RegWriteW_2(RegWriteW_2),         //  inputs from the second datapath
    .ResultW_2(ResultW_2),
    .PCTargetE_i(PCTargetE_o),
    
    .DataM(DataM),
    .DataW(DataW),  // outputs
    //.DataE(DataE),
    
    .DataM_2(DataM_2),  //inputs
    .DataW_2(DataW_2),
    //.DataE_2(DataE_2),
    
    .ImmSrc_2(ImmSrc1_2),
    
    //.Order_Change_F_o(Order_Change_F),
    .Order_Change_D_o(Order_Change_D),
    
    .StallF_P(StallF_P), 
    .StallD_P(StallD_P),   
        
    .FlushD_P(FlushD_P),
    .StallD_P_2(StallD_P_2), 
    .FlushD_P_2(FlushD_P_2),
    .FlushE_P(FlushE_P),
    
    .StallD_2(StallD1_2),
    .FlushD_2(FlushD1_2),
    
    .both_mem_o(both_mem) 
    
     
 ); 
 
 

Control_Unit 
ctrl 
(
    .op(Instr1[6:0]),
  //.rstn_i(rstn_i),               
    .funct3(Instr1[14:12]),
    .funct7(Instr1[30]),
    .Jump(Jump1),
    .Branch(Branch1),
    .MemWrite(MemWrite1),
    .ALUSrc(ALUSrc1),
    .RegWrite(RegWrite1),
    .ResultSrc(ResultSrc1),
    .ImmSrc(ImmSrc1),
    .ALUControl(ALUControl1),
    .TargetSrc(TargetSrc1)
);
 
 
 Hazard_Unit 
unit_combined 
(
    // Datapath 1
    .rs1d(rs1d1),
    .rs1e(rs1_e1),
    .rs2d(rs2d1),
    .rs2e(rs2_e1),
    .rde(rd_e1),
    .rdm(rd_m1),
    .rdw(rd_w1),
    .rdd(rdd),
    .rdd_2(rdd_2),
    
    
    .resultsrce0(resultsrce_01),
    .regwritem(regwrite_m1),
    .regwritew(regwrite_w1),
    .pcsrce(pcsrce1),
    
    .StallF(StallF1),
    .StallD(StallD1),
    .StallE(StallE1),
    
    .FlushD(FlushD1),
    .FlushE(FlushE1),
    .FlushM(FlushM),
    
    .StallF_P(StallF_P), 
    .StallD_P(StallD_P),   
        
    .FlushD_P(FlushD_P),
    .StallD_P_2(StallD_P_2), 
    .FlushD_P_2(FlushD_P_2),
    
    .FlushE_P_2(FlushE_P_2), 
    .FlushE_P(FlushE_P), 
     
      
    
    .ForwardAE(ForwardAE1),
    .ForwardBE(ForwardBE1),

    // Datapath 2
    .rs1d_2(rs1d1_2),
    .rs1e_2(rs1_e1_2),
    .rs2d_2(rs2d1_2),
    .rs2e_2(rs2_e1_2),
    .rde_2(rd_e1_2),
    .rdm_2(rd_m1_2),
    .rdw_2(rd_w1_2),
    .resultsrce0_2(resultsrce_01_2),
    .regwritem_2(regwrite_m1_2),
    .regwritew_2(regwrite_w1_2),
    
    .regwritee(regwrite_e1),
    .regwritee_2(regwrite_e1_2),
    
    .pcsrce_2(pcsrce1_2),
    
    .StallF_2(StallF1_2),
    .StallD_2(StallD1_2),
    .StallE_2(StallE1_2),
    
    .FlushD_2(FlushD1_2),
    .FlushE_2(FlushE1_2),
    .FlushM_2(FlushM_2),
    
    .ForwardAE_2(ForwardAE1_2),
    .ForwardBE_2(ForwardBE1_2),
    
    
    .order_change_e(order_change_o[0]),
    .order_change_m(order_change_o[1]),
    .order_change_w(order_change_o[2]),
    
    .Order_Change_D(Order_Change_D)
);



Two_Way_Datapath_ALU 
Datapath_2 
(   
    .Jump(Jump1_2),
    .Branch(Branch1_2),
    .MemWrite(MemWrite1_2),
    .ALUSrc(ALUSrc1_2),
    .RegWrite(RegWrite1_2),
    
    .clk(clk_i),
    .rstn_i(rstn_i),            
    
    .TargetSrc(TargetSrc1_2),
    .ALUControl(ALUControl1_2),
    .ImmSrc(ImmSrc1_2),
    .ResultSrc(ResultSrc1_2),
    //.Instr(Instr1_2),            // Control Unit Output
    
    .ForwardAE(ForwardAE1_2),
    .ForwardBE(ForwardBE1_2),
    
    .StallF(StallF1_2),
    .StallD(StallD1_2),
    .StallE(StallE1_2),
    
    .FlushD(FlushD1_2),
    .FlushE(FlushE1_2),
    .FlushM(FlushM_2),
    
    .rs1d(rs1d1_2),
    .rs1_e(rs1_e1_2),
    .rs2d(rs2d1_2),
    .rs2_e(rs2_e1_2),
    .rd_e(rd_e1_2),
    .rd_m(rd_m1_2),
    .rd_w(rd_w1_2),
    .rdd(rdd_2),
    
    .pcsrce(pcsrce1_2), 
    .resultsrce_0(resultsrce_01_2),
    .regwrite_m(regwrite_m1_2),
    .regwrite_w(regwrite_w1_2),
    .regwrite_e(regwrite_e1_2),
    
    .FlushE_P_2(FlushE_P_2),
    
    
  //.addr_i(addr_i_2),                 //input for data mem port (additional)
    
  //.data_o(data_o_2),        
    .Instr_o(Instr_o_0_2),   
    
    .reg_addr_o(reg_addr_o1_2),        //conditional output for tb
    
    .reg_data_o(reg_data_o1_2),
    .mem_addr_o(mem_addr_o1_2),         //testbench outputs
    .mem_data_o(mem_data_o1_2),
    .mem_wrt_o(mem_wrt_o1_2),
    
    
  //.pc_f(pc_f_2),  
    .pc_d(pc_d_2),  
    .pc_e(pc_e_2),                     // table components for pipe.log
    .pc_m(pc_m_2),  
    .pc_wb(pc_wb_2),
    
  //.PCF(PCF),
    
  //.Instr_raw(Instr_raw_2),            // output from imem        
   
    
    .RD1_2(RD1_2),     
    .RD2_2(RD2_2),     
    .InstrD_2_o(InstrD_2_o),
    .ImmExtD_2(ImmExtD_2),            // second datapath inputs from common datapath
    .PCPlus4D_2(PCPlus4D_2),
    .PCD(PCD_o),
    
    
    .RdW_2(RdW_2),
    .RegWriteW_2(RegWriteW_2),         //  output to the common datapath
    .ResultW_2(ResultW_2),
    .PCTargetE_o(PCTargetE_o),
    
    
    .DataM(DataM),
    .DataW(DataW),  // inputs
    //.DataE(DataE),
    
    .DataM_2(DataM_2),  //outputs
    .DataW_2(DataW_2),
    //.DataE_2(DataE_2),
    
    .order_change_i(order_change_o),
    
    //.Order_Change_F(Order_Change_F),
    .Order_Change_D(Order_Change_D),
    
    .both_mem_i(both_mem)
    
);
 
 
Control_Unit 
ctrl_2 
(
    .op(InstrD_2_o[6:0]),
  //.rstn_i(rstn_i),               
    .funct3(InstrD_2_o[14:12]),
    .funct7(InstrD_2_o[30]),
    .Jump(Jump1_2),
    .Branch(Branch1_2),
    .MemWrite(MemWrite1_2),
    .ALUSrc(ALUSrc1_2),
    .RegWrite(RegWrite1_2),
    .ResultSrc(ResultSrc1_2),
    .ImmSrc(ImmSrc1_2),
    .ALUControl(ALUControl1_2),
    .TargetSrc(TargetSrc1_2)
); 


endmodule

