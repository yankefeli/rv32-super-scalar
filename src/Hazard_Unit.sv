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
    //-------------------------------------------------------------
    // Datapath-1 (common) girişleri
    input  logic  [19:15] rs1d,  rs1e,
    input  logic  [24:20] rs2d,  rs2e,
    input  logic  [11:7]  rde,   rdm,   rdw,
    input  logic          resultsrce0,
    input  logic          regwritee, regwritem, regwritew,
    input  logic          pcsrce,

    //-------------------------------------------------------------
    // Ortak kontrol
    input  logic          order_change_e, order_change_m, order_change_w,
    input  logic          Order_Change_D,
    input  logic  [4:0]   rdd,   rdd_2,

    //-------------------------------------------------------------
    // Datapath-1 (common) çıkışları
    output logic          StallF,  StallD,  StallE,
    output logic          FlushD,  FlushE,  FlushM,
    output logic          FlushM_2,                    // Datapath-2'yi etkiler
    output logic  [2:0]   ForwardAE, ForwardBE,

    //-------------------------------------------------------------
    // Datapath-2 (ALU) girişleri
    input  logic  [19:15] rs1d_2, rs1e_2,
    input  logic  [24:20] rs2d_2, rs2e_2,
    input  logic  [11:7]  rde_2,  rdm_2,  rdw_2,
    input  logic          resultsrce0_2,
    input  logic          regwritee_2, regwritem_2, regwritew_2,
    input  logic          pcsrce_2,

    //-------------------------------------------------------------
    // Datapath-2 (ALU) çıkışları
    output logic          StallF_2, StallD_2, StallE_2,
    output logic          FlushD_2, FlushE_2,
    output logic  [2:0]   ForwardAE_2, ForwardBE_2,

    //-------------------------------------------------------------
    // Paralel bağımlılık (pipeline interlock) çıktıları
    output logic          StallF_P,  StallD_P,  FlushE_P,  FlushD_P,
    output logic          StallD_P_2, FlushE_P_2, FlushD_P_2
);

    //-----------------------------------------------------------------
    // Internal nets (yalnızca bu module içinde)
    //-----------------------------------------------------------------
    logic [2:0] order_flag;
    logic       lwstall_mem,       lwstall_parallel;
    logic       lwstall_mem_2,     lwstall_parallel_2;

    //-----------------------------------------------------------------
    // Tek yönlü çıktı üretimi - sürekli atamalar (assign)
    //-----------------------------------------------------------------
    assign order_flag = {order_change_e, order_change_m, order_change_w};

    // --- Paralel (inter-pipeline) bağımlılıklar ----------------------
    assign StallF_P   = (lwstall_parallel  | lwstall_parallel_2)  & (~pcsrce) & (~pcsrce_2);
    assign StallD_P   =  lwstall_parallel                         & (~pcsrce) & (~pcsrce_2);
    assign StallD_P_2 =                       lwstall_parallel_2  & (~pcsrce) & (~pcsrce_2);

    assign FlushE_P   =  lwstall_parallel                         & (~pcsrce) & (~pcsrce_2);
    assign FlushE_P_2 =                      lwstall_parallel_2   & (~pcsrce) & (~pcsrce_2);

    assign FlushD_P   =                      lwstall_parallel_2   & (~pcsrce) & (~pcsrce_2);
    assign FlushD_P_2 =  lwstall_parallel                         & (~pcsrce) & (~pcsrce_2);

    // --- Global stall/flush sinyalleri ------------------------------
    assign StallF   = lwstall_mem | lwstall_mem_2;
    assign StallD   = lwstall_mem | lwstall_mem_2;
    assign StallE   = 1'b0;   // full-forwarding tasarımında E sahnesi hiç tutulmuyor

    assign StallF_2 = lwstall_mem_2;              // sadece kendi MEM stall'ı
    assign StallD_2 = lwstall_mem_2 | lwstall_mem; // karşılıklı etki olabilir
    assign StallE_2 = 1'b0;

    assign FlushD   = pcsrce  | pcsrce_2;
    assign FlushE   = (lwstall_mem | lwstall_mem_2) | (pcsrce | pcsrce_2);
    assign FlushM   =  order_change_e & pcsrce_2;    // Datapath-1'in M sahnesini temizle

    assign FlushD_2 = pcsrce_2 | pcsrce;
    assign FlushE_2 = (lwstall_mem_2 | lwstall_mem) | (pcsrce_2 | pcsrce);
    assign FlushM_2 = (!order_change_e) & pcsrce;    // Datapath-2'nin M sahnesini temizle

    //-----------------------------------------------------------------
    // Datapath-1 (common) hazard & forwarding birimi
    //-----------------------------------------------------------------
    always_comb begin : DP1_HAZARDS
        // Varsayılanlar
        ForwardAE        = 3'b000;
        ForwardBE        = 3'b000;
        lwstall_mem      = 1'b0;
        lwstall_parallel = 1'b0;

        // ---------------- Forwarding mantığı -----------------------
        unique case (order_flag)
            3'b000, 3'b100: begin
                if ( (rs1e == rdm_2) &&  regwritem_2 && (rs1e != 0) )       ForwardAE = 3'b100; // 2. DP M
                else if ( (rs1e == rdm)   &&  regwritem  && (rs1e != 0) )   ForwardAE = 3'b010; // 1. DP M
                else if ( (rs1e == rdw_2) &&  regwritew_2 && (rs1e != 0) )  ForwardAE = 3'b011; // 2. DP W
                else if ( (rs1e == rdw)   &&  regwritew  && (rs1e != 0) )   ForwardAE = 3'b001; // 1. DP W
                // BE (rs2) aynı kalıp ile
                if ( (rs2e == rdm_2) &&  regwritem_2 && (rs2e != 0) )       ForwardBE = 3'b100;
                else if ( (rs2e == rdm)   &&  regwritem  && (rs2e != 0) )   ForwardBE = 3'b010;
                else if ( (rs2e == rdw_2) &&  regwritew_2 && (rs2e != 0) )  ForwardBE = 3'b011;
                else if ( (rs2e == rdw)   &&  regwritew  && (rs2e != 0) )   ForwardBE = 3'b001;
            end

            3'b001, 3'b101: begin
                if ( (rs1e == rdm_2) &&  regwritem_2 && (rs1e != 0) )       ForwardAE = 3'b100;
                else if ( (rs1e == rdm)   &&  regwritem  && (rs1e != 0) )   ForwardAE = 3'b010;
                else if ( (rs1e == rdw)   &&  regwritew  && (rs1e != 0) )   ForwardAE = 3'b001;
                else if ( (rs1e == rdw_2) &&  regwritew_2 && (rs1e != 0) )  ForwardAE = 3'b011;

                if ( (rs2e == rdm_2) &&  regwritem_2 && (rs2e != 0) )       ForwardBE = 3'b100;
                else if ( (rs2e == rdm)   &&  regwritem  && (rs2e != 0) )   ForwardBE = 3'b010;
                else if ( (rs2e == rdw)   &&  regwritew  && (rs2e != 0) )   ForwardBE = 3'b001;
                else if ( (rs2e == rdw_2) &&  regwritew_2 && (rs2e != 0) )  ForwardBE = 3'b011;
            end

            3'b010, 3'b110: begin
                if ( (rs1e == rdm)   &&  regwritem  && (rs1e != 0) )        ForwardAE = 3'b010;
                else if ( (rs1e == rdm_2) &&  regwritem_2 && (rs1e != 0) )  ForwardAE = 3'b100;
                else if ( (rs1e == rdw_2) &&  regwritew_2 && (rs1e != 0) )  ForwardAE = 3'b011;
                else if ( (rs1e == rdw)   &&  regwritew  && (rs1e != 0) )   ForwardAE = 3'b001;

                if ( (rs2e == rdm)   &&  regwritem  && (rs2e != 0) )        ForwardBE = 3'b010;
                else if ( (rs2e == rdm_2) &&  regwritem_2 && (rs2e != 0) )  ForwardBE = 3'b100;
                else if ( (rs2e == rdw_2) &&  regwritew_2 && (rs2e != 0) )  ForwardBE = 3'b011;
                else if ( (rs2e == rdw)   &&  regwritew  && (rs2e != 0) )   ForwardBE = 3'b001;
            end

            3'b011, 3'b111: begin
                if ( (rs1e == rdm)   &&  regwritem  && (rs1e != 0) )        ForwardAE = 3'b010;
                else if ( (rs1e == rdm_2) &&  regwritem_2 && (rs1e != 0) )  ForwardAE = 3'b100;
                else if ( (rs1e == rdw)   &&  regwritew  && (rs1e != 0) )   ForwardAE = 3'b001;
                else if ( (rs1e == rdw_2) &&  regwritew_2 && (rs1e != 0) )  ForwardAE = 3'b011;

                if ( (rs2e == rdm)   &&  regwritem  && (rs2e != 0) )        ForwardBE = 3'b010;
                else if ( (rs2e == rdm_2) &&  regwritem_2 && (rs2e != 0) )  ForwardBE = 3'b100;
                else if ( (rs2e == rdw)   &&  regwritew  && (rs2e != 0) )   ForwardBE = 3'b001;
                else if ( (rs2e == rdw_2) &&  regwritew_2 && (rs2e != 0) )  ForwardBE = 3'b011;
            end
        endcase

        // ---------------- MEM/parallel stall mantığı ----------------
        if (!Order_Change_D) begin
            lwstall_parallel = 1'b0;
            if (!order_change_e) begin
                lwstall_mem = !( (rs1d == rde_2 && rs1d!=0) || (rs2d == rde_2 && rs2d!=0) || pcsrce || pcsrce_2 ) &&
                              resultsrce0 && ((rs1d == rde) || (rs2d == rde)) && (~pcsrce) && (~pcsrce_2);
            end else begin
                lwstall_mem = !(pcsrce || pcsrce_2) &&
                              resultsrce0 && ((rs1d == rde) || (rs2d == rde)) && (~pcsrce) && (~pcsrce_2);
            end
        end else begin
            lwstall_parallel = ( (rs1d == rdd_2  && rs1d != 0) || (rs2d == rdd_2 && rs2d != 0) );
            if (!order_change_e) begin
                lwstall_mem = !( (rs1d == rde_2 && rs1d!=0) || (rs2d == rde_2 && rs2d!=0) || lwstall_parallel || pcsrce || pcsrce_2 ) &&
                              resultsrce0 && ((rs1d == rde) || (rs2d == rde)) && (~pcsrce) && (~pcsrce_2);
            end else begin
                lwstall_mem = !(pcsrce || pcsrce_2) && !lwstall_parallel &&
                              resultsrce0 && ((rs1d == rde) || (rs2d == rde) ) && (~pcsrce) && (~pcsrce_2);
            end
        end
    end // always_comb DP1_HAZARDS

    //-----------------------------------------------------------------
    // Datapath-2 (ALU) hazard & forwarding birimi
    //-----------------------------------------------------------------
    always_comb begin : DP2_HAZARDS
        // Varsayılanlar
        ForwardAE_2        = 3'b000;
        ForwardBE_2        = 3'b000;
        lwstall_mem_2      = 1'b0;
        lwstall_parallel_2 = 1'b0;

        // ---------------- Forwarding mantığı -----------------------
        unique case (order_flag)
            3'b000, 3'b100: begin
                if ( (rs1e_2 == rdm_2) && regwritem_2 && (rs1e_2 != 0) )       ForwardAE_2 = 3'b010; // kendi M
                else if ( (rs1e_2 == rdm)   && regwritem  && (rs1e_2 != 0) )   ForwardAE_2 = 3'b100; // diğer M
                else if ( (rs1e_2 == rdw_2) && regwritew_2 && (rs1e_2 != 0) )  ForwardAE_2 = 3'b001; // kendi W
                else if ( (rs1e_2 == rdw)   && regwritew  && (rs1e_2 != 0) )   ForwardAE_2 = 3'b011; // diğer W

                if ( (rs2e_2 == rdm_2) && regwritem_2 && (rs2e_2 != 0) )        ForwardBE_2 = 3'b010;
                else if ( (rs2e_2 == rdm)   && regwritem  && (rs2e_2 != 0) )    ForwardBE_2 = 3'b100;
                else if ( (rs2e_2 == rdw_2) && regwritew_2 && (rs2e_2 != 0) )   ForwardBE_2 = 3'b001;
                else if ( (rs2e_2 == rdw)   && regwritew  && (rs2e_2 != 0) )    ForwardBE_2 = 3'b011;
            end

            3'b001, 3'b101: begin
                if ( (rs1e_2 == rdm_2) && regwritem_2 && (rs1e_2 != 0) )       ForwardAE_2 = 3'b010;
                else if ( (rs1e_2 == rdm)   && regwritem  && (rs1e_2 != 0) )   ForwardAE_2 = 3'b100;
                else if ( (rs1e_2 == rdw)   && regwritew  && (rs1e_2 != 0) )   ForwardAE_2 = 3'b011;
                else if ( (rs1e_2 == rdw_2) && regwritew_2 && (rs1e_2 != 0) )  ForwardAE_2 = 3'b001;

                if ( (rs2e_2 == rdm_2) && regwritem_2 && (rs2e_2 != 0) )        ForwardBE_2 = 3'b010;
                else if ( (rs2e_2 == rdm)   && regwritem  && (rs2e_2 != 0) )    ForwardBE_2 = 3'b100;
                else if ( (rs2e_2 == rdw)   && regwritew  && (rs2e_2 != 0) )    ForwardBE_2 = 3'b011;
                else if ( (rs2e_2 == rdw_2) && regwritew_2 && (rs2e_2 != 0) )   ForwardBE_2 = 3'b001;
            end

            3'b010, 3'b110: begin
                if ( (rs1e_2 == rdm)   && regwritem  && (rs1e_2 != 0) )        ForwardAE_2 = 3'b100;
                else if ( (rs1e_2 == rdm_2) && regwritem_2 && (rs1e_2 != 0) )  ForwardAE_2 = 3'b010;
                else if ( (rs1e_2 == rdw_2) && regwritew_2 && (rs1e_2 != 0) )  ForwardAE_2 = 3'b001;
                else if ( (rs1e_2 == rdw)   && regwritew  && (rs1e_2 != 0) )   ForwardAE_2 = 3'b011;

                if ( (rs2e_2 == rdm)   && regwritem  && (rs2e_2 != 0) )        ForwardBE_2 = 3'b100;
                else if ( (rs2e_2 == rdm_2) && regwritem_2 && (rs2e_2 != 0) )  ForwardBE_2 = 3'b010;
                else if ( (rs2e_2 == rdw_2) && regwritew_2 && (rs2e_2 != 0) )  ForwardBE_2 = 3'b001;
                else if ( (rs2e_2 == rdw)   && regwritew  && (rs2e_2 != 0) )   ForwardBE_2 = 3'b011;
            end

            3'b011, 3'b111: begin
                if ( (rs1e_2 == rdm)   && regwritem  && (rs1e_2 != 0) )        ForwardAE_2 = 3'b100;
                else if ( (rs1e_2 == rdm_2) && regwritem_2 && (rs1e_2 != 0) )  ForwardAE_2 = 3'b010;
                else if ( (rs1e_2 == rdw)   && regwritew  && (rs1e_2 != 0) )   ForwardAE_2 = 3'b011;
                else if ( (rs1e_2 == rdw_2) && regwritew_2 && (rs1e_2 != 0) )  ForwardAE_2 = 3'b001;

                if ( (rs2e_2 == rdm)   && regwritem  && (rs2e_2 != 0) )        ForwardBE_2 = 3'b100;
                else if ( (rs2e_2 == rdm_2) && regwritem_2 && (rs2e_2 != 0) )  ForwardBE_2 = 3'b010;
                else if ( (rs2e_2 == rdw)   && regwritew  && (rs2e_2 != 0) )   ForwardBE_2 = 3'b011;
                else if ( (rs2e_2 == rdw_2) && regwritew_2 && (rs2e_2 != 0) )  ForwardBE_2 = 3'b001;
            end
        endcase

        // ---------------- MEM/parallel stall mantığı ----------------
        if (Order_Change_D) begin
            lwstall_parallel_2 = 1'b0;
            if (!order_change_e) begin
                lwstall_mem_2 = !( (rs1d_2 == rde_2 && rs1d_2!=0) || (rs2d_2 == rde_2 && rs2d_2!=0) || pcsrce || pcsrce_2 ) &&
                                resultsrce0 && ((rs1d_2 == rde) || (rs2d_2 == rde)) && (~pcsrce) && (~pcsrce_2);
            end else begin
                lwstall_mem_2 = !(pcsrce || pcsrce_2) &&
                                resultsrce0 && ((rs1d_2 == rde) || (rs2d_2 == rde)) && (~pcsrce) && (~pcsrce_2);
            end
        end else begin
            lwstall_parallel_2 = ( (rs1d_2 == rdd  && rs1d_2 != 0) || (rs2d_2 == rdd && rs2d_2 != 0) ) && (~pcsrce) && (~pcsrce_2);
            if (!order_change_e) begin
                lwstall_mem_2 = !( (rs1d_2 == rde_2 && rs1d_2 !=0) || (rs2d_2 == rde_2 && rs2d_2 !=0) || lwstall_parallel_2 || pcsrce || pcsrce_2 ) &&
                                resultsrce0 && ((rs1d_2 == rde) || (rs2d_2 == rde)) && (~pcsrce) && (~pcsrce_2);
            end else begin
                lwstall_mem_2 = !(pcsrce || pcsrce_2) && !lwstall_parallel_2 &&
                                resultsrce0 && ((rs1d_2 == rde) || (rs2d_2 == rde)) && (~pcsrce) && (~pcsrce_2);
            end
        end
    end // always_comb DP2_HAZARDS

endmodule

