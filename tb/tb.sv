`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.04.2025 17:05:32
// Design Name: 
// Module Name: tb
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
module tb #(
    // <<<<<<  ÜST MODÜLDEN KONTROL EDİLECEK PARAMETRELER  >>>>>>
    parameter int    IssueWidth    = 2
   // parameter string TableFile     = "table.log",
   // parameter string ModelFile     = "model.log"
    //parameter string IMemInitFile  = "imem.mem"    // instruction memory initialization file
) ();



  logic [31:0] addr;
  logic [31:0] data;
  logic [31:0] instr    [IssueWidth];
  logic [4:0]  reg_addr [IssueWidth];
  logic [31:0] reg_data [IssueWidth];
  logic [31:0] mem_addr [IssueWidth];
  logic [31:0] mem_data [IssueWidth];
  logic        mem_wrt  [IssueWidth];
  logic [31:0] pc_o     [IssueWidth];
  
  logic        update   [IssueWidth];
  logic        update_model [IssueWidth];

  logic        clk;
  logic        rstn;

  logic [31:0] pc_f [IssueWidth];
  logic [31:0] pc_d [IssueWidth];
  logic [31:0] pc_e [IssueWidth];
  logic [31:0] pc_m [IssueWidth];
  logic [31:0] pc_wb[IssueWidth];
  
  logic [31:0] pc_f_r [IssueWidth];
  logic [31:0] pc_d_r [IssueWidth];
  logic [31:0] pc_e_r [IssueWidth];
  logic [31:0] pc_m_r [IssueWidth];
  logic [31:0] pc_wb_r[IssueWidth];
  
  

  logic        StallF [IssueWidth];
  logic        StallD [IssueWidth];
  logic        FlushD [IssueWidth];
  logic        FlushE [IssueWidth];
  
  
  logic             StallF_P_o ;            
  logic             StallD_P_o [IssueWidth];                            
  logic             FlushD_P_o [IssueWidth];
  logic             FlushE_P_o [IssueWidth];
  
  
 
  riscv_multicycle
  #(
        .IssueWidth (IssueWidth)
        //.TableFile  (TableFile),
        //.ModelFile  (ModelFile)
        //.IMemInitFile(IMemInitFile)   
   ) i_core_model 
  (
      .clk_i(clk),
      .rstn_i(rstn),
      .addr_i(addr),

      .update_o(update),
      .update_model(update_model),

      .data_o(data),
      .Instr_o(instr),

      .reg_addr_o(reg_addr),
      .reg_data_o(reg_data),
      .mem_addr_o(mem_addr),
      .mem_data_o(mem_data),
      .mem_wrt_o(mem_wrt),
      .pc_o(pc_o),

      .pc_f(pc_f),
      .pc_d(pc_d),
      .pc_e(pc_e),
      .pc_m(pc_m),
      .pc_wb(pc_wb),

      .StallF(StallF),
      .StallD(StallD),

      .FlushD(FlushD),
      .FlushE(FlushE),
      
      .StallF_P_o(StallF_P_o),
      .StallD_P_o(StallD_P_o),
      .FlushD_P_o(FlushD_P_o),
      .FlushE_P_o(FlushE_P_o)
      
  );

integer file_pointer;
integer cycle_counter;
integer final_cycles;

bit update_fell_both;
bit stall_write;
bit stall_write1;
bit finish_start = 0;


localparam int unsigned MEM_LOW  = 32'h2000_0000;
localparam int unsigned MEM_HIGH = 32'h2000_3FFF;

// Instruction memory
logic [31:0] imem [MEM_LOW : MEM_HIGH];

// Son satır "0" hariç buyruk sayısı
int instr_cnt = 0;

//-------------------------------------------------
// Dosyayı oku ve say
//-------------------------------------------------
initial begin
  // Dosya adını DUT'taki parametreden al
  $readmemh(i_core_model.IMemInitFile, imem);

  // Döngü sayaç ismi addr → idx  (VARHIDDEN kalkar)
  for (int unsigned idx = MEM_LOW; idx <= MEM_HIGH; idx++) begin
    if (imem[idx] === 32'bx) break;  // dosya bitti
    if (imem[idx] == 32'h0)  break;  // son satır 0
    instr_cnt++;
  end
end

int finish_counter = 0;

logic [31:0] end_pc;  // program sonu (sentinel 0 adresi)
localparam logic [31:0] FIRST_PC = 32'h8000_0000;

initial end_pc = FIRST_PC + (instr_cnt-1) * 32'd4;  // 4-bayt hizalı

//--------------------------------------------------------------
// PC sınırı kontrolü - pipeline içinde dilediğiniz yerde:
//logic beyond_prog;
//assign beyond_prog = (pc >= end_pc);   // true → PC program alanını aşt

initial begin
  file_pointer = $fopen(i_core_model.TableFile, "w");
  
  $fwrite(file_pointer, "- This core contains two datapaths, each implementing a 5-stage pipeline (Fetch and Decode stages are common).\n");
  $fwrite(file_pointer, "- An explicit issue stage was deemed unnecessary. Instruction dispatching is handled by a dispatcher integrated within the decode stage.\n");
  $fwrite(file_pointer, "- Datapath B -> ALU + MEM (A common datapath which includes Fetch and Decode stages), Datapath A-> ALU.\n");
  $fwrite(file_pointer, "- Instructions that appear earlier in program order are directed to the B datapath by default. Therefore, the B datapath is listed first.\n");
  $fwrite(file_pointer, "- If necessary, the instruction order is modified by the dispatcher in the Decode stage, particularly when a memory instruction is encountered.\n");
  $fwrite(file_pointer, "- If a stage's corresponding column is left blank, it indicates that there is no instruction at that program counter (PC) value.\n");
  $fwrite(file_pointer, "- All data dependencies are resolved through stalling and bypassing (+20 bonus points).\n");
  $fwrite(file_pointer, "- For each instruction, the updates to architectural registers and data memory addresses can be tracked in the file defined by the ModelFile parameter.\n");
  $fwrite(file_pointer, "- These messages can be removed by deleting lines 167 - 176 in the tb.sv file.\n");
  $fwrite(file_pointer, "\n");
  
  $fwrite(file_pointer, "Cycle       F           D           E           M           WB\n");

  cycle_counter = 1;
  final_cycles = 0;
  update_fell_both = 0;
  //update_fell_one  = 0;
  stall_write = 0;
  stall_write1 = 0;
  
  pc_f_r  [0]   = 0;
  pc_d_r  [0]   = 0;
  pc_e_r  [0]   = 0;
  pc_m_r  [0]   = 0;
  pc_wb_r [0]   = 0;
  
  pc_f_r  [1]   = 0;
  pc_d_r  [1]   = 0;
  pc_e_r  [1]   = 0;
  pc_m_r  [1]   = 0;
  pc_wb_r [1]   = 0;
  
  #2

  forever begin
    #2;

    if (!update_fell_both) begin     
      $fwrite(file_pointer, "%5dB  ", cycle_counter);

      if (cycle_counter == 1)
        $fwrite(file_pointer, "0x%08h\n", pc_f[0]);

      else if (cycle_counter == 2)
        $fwrite(file_pointer, "0x%08h  0x%08h\n", pc_f[0], pc_d[0]);
                                                                                             // first cycles  (path1)
      else if (cycle_counter == 3)
        $fwrite(file_pointer, "0x%08h  0x%08h  0x%08h\n", pc_f[0], pc_d[0], pc_e[0]);

      else if (cycle_counter == 4)
        $fwrite(file_pointer, "0x%08h  0x%08h  0x%08h  0x%08h\n", pc_f[0], pc_d[0], pc_e[0], pc_m[0]);

      else begin
      
        if (pc_f[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else if(pc_f[0] > end_pc)
          $fwrite(file_pointer, "            ");  
        else if(pc_f[0] == pc_f_r[0])
          $fwrite(file_pointer, "Stall       ");    
        else
          $fwrite(file_pointer, "0x%08h  ", pc_f[0]);

        if (pc_d[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else if(pc_d[0] > end_pc)
          $fwrite(file_pointer, "            ");  
        else if(pc_d[0] == pc_d_r[0])
          $fwrite(file_pointer, "Stall       ");   
        else
          $fwrite(file_pointer, "0x%08h  ", pc_d[0]);

        if (pc_e[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");                               // typical cycles for second path
        else if(pc_e[0] > end_pc)
          $fwrite(file_pointer, "            ");  
        else if(pc_e[0] == pc_e_r[0])
          $fwrite(file_pointer, "Stall       ");    
        else
          $fwrite(file_pointer, "0x%08h  ", pc_e[0]);

        if (pc_m[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else if(pc_m[0] > end_pc)
          $fwrite(file_pointer, "            "); 
        else if(pc_m[0] == pc_m_r[0])
          $fwrite(file_pointer, "Stall       ");      
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[0]);

        if (pc_wb[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else if(pc_wb[0] > end_pc)
          $fwrite(file_pointer, "            ");  
        else if(pc_wb[0] == pc_wb_r[0])
          $fwrite(file_pointer, "Stall       ");    
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[0]);


        pc_f_r  [0] = pc_f[0];
        pc_d_r  [0] = pc_d[0];   
        pc_e_r  [0] = pc_e[0];
        pc_m_r  [0] = pc_m[0];
        pc_wb_r [0] = pc_wb[0];  
      end

    /////////////////////for path2///////////////////////////////////////////////////////////////////////////

      $fwrite(file_pointer, "%5dA  ", cycle_counter);

      if (cycle_counter == 1)
        $fwrite(file_pointer, "0x%08h\n", pc_f[1]);

      else if (cycle_counter == 2)
        $fwrite(file_pointer, "0x%08h  0x%08h\n", pc_f[1], pc_d[1]);
                                                                                             // first cycles  (path2)
      else if (cycle_counter == 3)
        $fwrite(file_pointer, "0x%08h  0x%08h  0x%08h\n", pc_f[1], pc_d[1], pc_e[1]);

      else if (cycle_counter == 4)
        $fwrite(file_pointer, "0x%08h  0x%08h  0x%08h  0x%08h\n", pc_f[1], pc_d[1], pc_e[1], pc_m[1]);

     ///////////////////////////////////////////for stall_write1  ///////////////////////////////////////////////////////////////// 
    else begin
        if (pc_f[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else if(pc_f[1] > end_pc)
          $fwrite(file_pointer, "            ");  
        else if(pc_f[1] == pc_f_r[1])
          $fwrite(file_pointer, "Stall       ");    
        else
          $fwrite(file_pointer, "0x%08h  ", pc_f[1]);

        if (pc_d[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else if(pc_d[1] > end_pc)
          $fwrite(file_pointer, "            ");  
        else if(pc_d[1] == pc_d_r[1])
          $fwrite(file_pointer, "Stall       ");   
        else
          $fwrite(file_pointer, "0x%08h  ", pc_d[1]);

        if (pc_e[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");                               // typical cycles for second path
        else if(pc_e[1] > end_pc)
          $fwrite(file_pointer, "            ");  
        else if(pc_e[1] == pc_e_r[1])
          $fwrite(file_pointer, "Stall       ");    
        else
          $fwrite(file_pointer, "0x%08h  ", pc_e[1]);

        if (pc_m[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else if(pc_m[1] > end_pc)
          $fwrite(file_pointer, "            "); 
        else if(pc_m[1] == pc_m_r[1])
          $fwrite(file_pointer, "Stall       ");      
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[1]);

        if (pc_wb[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else if(pc_wb[1] > end_pc)
          $fwrite(file_pointer, "            ");  
        else if(pc_wb[1] == pc_wb_r[1])
          $fwrite(file_pointer, "Stall       ");    
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[1]);
        
        pc_f_r  [1] = pc_f[1];
        pc_d_r  [1] = pc_d[1];   
        pc_e_r  [1] = pc_e[1];
        pc_m_r  [1] = pc_m[1];
        pc_wb_r [1] = pc_wb[1]; 
      end

      cycle_counter = cycle_counter + 1;                                      // next cycle (for update[1] signal)

    end // end of if(update[1])


    if (!update[0] && !update[1] && finish_start && !update_fell_both) begin

       finish_counter = finish_counter +1 ;
       //final_cycles = 4;  // <------ Eksik olan satır! Artık tamam

    end   

    if(finish_counter == 1  && !update_fell_both) begin
        finish_counter = 0;
        finish_start = 0;
    end    

    if(finish_counter == 2  && !update_fell_both) begin
        update_fell_both = 1;
        final_cycles = 3;
    end

    //////////////////////////////////////////// last cycles //////////////////////////////////////////////////
    // BURAYA EKSİK OLANI EKLİYORUZ:
    if (!update[0] && !update[1] && !finish_start && !update_fell_both) begin

       finish_counter = finish_counter +1 ;
       finish_start = 1;
       //final_cycles = 4;  // <------ Eksik olan satır! Artık tamam

    end   

    //////////////////////// last cycles for update_both_fell////////////////////////////////////////////
    if (update_fell_both && (final_cycles > 0)) begin      // last cycles

    ////////////////////////// first path //////////////////////////////////////////

      $fwrite(file_pointer, "%5dB  ", cycle_counter);

      if (final_cycles == 3) begin
        $fwrite(file_pointer, "                        "); // F, D boşluk
        
        if (pc_e[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else if(pc_e[0] > end_pc)
          $fwrite(file_pointer, "            ");    
        else
          $fwrite(file_pointer, "0x%08h  ", pc_e[0]);

        if (pc_m[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else if(pc_m[0] > end_pc)
          $fwrite(file_pointer, "            ");    
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[0]);

        if (pc_wb[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else if(pc_wb[0] > end_pc)
          $fwrite(file_pointer, "            \n");    
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[0]);
      end

      else if (final_cycles == 2) begin
        $fwrite(file_pointer, "                                    "); // F, D, E boşluk
        if (pc_m[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else if(pc_m[0] > end_pc)
          $fwrite(file_pointer, "            ");    
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[0]);

        if (pc_wb[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else if(pc_wb[0] > end_pc)
          $fwrite(file_pointer, "            \n");    
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[0]);
      end

      else if (final_cycles == 1) begin
        $fwrite(file_pointer, "                                                "); // F, D, E, M boşluk
        if (pc_wb[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else if(pc_wb[0] > end_pc)
          $fwrite(file_pointer, "            \n");    
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[0]);
      end

    ///////////////////////////////// second path/////////////////////////////////////////////////////////
     
     $fwrite(file_pointer, "%5dA  ", cycle_counter);
     
      if (final_cycles == 3) begin
        $fwrite(file_pointer, "                        "); // F, D boşluk
        
        if (pc_e[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else if(pc_e[1] > end_pc)
          $fwrite(file_pointer, "            ");    
        else
          $fwrite(file_pointer, "0x%08h  ", pc_e[1]);

        if (pc_m[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else if(pc_m[1] > end_pc)
          $fwrite(file_pointer, "            ");    
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[1]);

        if (pc_wb[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else if(pc_wb[1] > end_pc)
          $fwrite(file_pointer, "            \n");    
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[1]);
      end

      else if (final_cycles == 2) begin
        $fwrite(file_pointer, "                                    "); // F, D, E boşluk
        
        if (pc_m[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else if(pc_m[1] > end_pc)
          $fwrite(file_pointer, "            ");    
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[1]);

        if (pc_wb[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else if(pc_wb[1] > end_pc)
          $fwrite(file_pointer, "            \n");    
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[1]);
      end

      else if (final_cycles == 1) begin
        $fwrite(file_pointer, "                                                "); // F, D, E, M boşluk
        if (pc_wb[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else if(pc_wb[1] > end_pc)
          $fwrite(file_pointer, "            \n");    
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[1]);
      end

          final_cycles = final_cycles - 1;
          cycle_counter = cycle_counter + 1;

    end       // end of update_fell_both

  end
end

integer file_pointer_model;
integer write_counter = 0; // Yeni sayaç

initial begin

    file_pointer_model = $fopen(i_core_model.ModelFile, "w");
    #4

    forever begin
        if (update_model [0]) begin

            if (write_counter >= 3) begin // sadece 3 cycle geçtikten sonra yaz

                if (reg_addr [0] == 0 && mem_wrt [0] ==0) begin  //branch
                    $fwrite(file_pointer_model, "0x%8h (0x%8h)\n", pc_o[0], instr[0]);
                end 
                
                else if (instr [0][6:0] != 7'b0100011  &&  instr [0] [6:0] != 7'b0000011) begin //not writing to datamem and not load
                
                    if (reg_addr [0] > 9) begin
                        $fwrite(file_pointer_model, "0x%8h (0x%8h) x%0d 0x%8h\n", pc_o[0], instr[0], reg_addr[0], reg_data[0]);
                    end 
                    
                    else begin
                        $fwrite(file_pointer_model, "0x%8h (0x%8h) x%0d  0x%8h\n", pc_o[0], instr[0], reg_addr[0], reg_data[0]);
                    end
                    
                end
                
                else if (mem_wrt[0] == 1 && instr [0][6:0] == 7'b0100011 ) begin  //store
                    $fwrite(file_pointer_model, "0x%8h (0x%8h) mem 0x%8h 0x%8h\n",pc_o[0], instr[0],  mem_addr[0], mem_data[0]);
                end
                
                
                else if (instr [0][6:0] == 7'b0000011) begin  //load to register  (from memory)
                    $fwrite(file_pointer_model, "0x%8h (0x%8h) x%0d 0x%8h mem 0x%8h\n"
                    , pc_o[0], instr[0], reg_addr[0], reg_data[0], mem_addr[0]);    
                end

                //$fwrite(file_pointer_model, "\n");

            end

            // Sayaç sadece 3'ten küçükken artacak
            //if (write_counter < 3)
                //write_counter = write_counter + 1;

        end
        
        
        if (update_model [1]) begin

            if (write_counter >= 3) begin // sadece 3 cycle geçtikten sonra yaz

                if (reg_addr [1] == 0 && mem_wrt [1] ==0) begin  //branch
                    $fwrite(file_pointer_model, "0x%8h (0x%8h)", pc_o[1], instr[1]);
                end 
                
                else if (instr [1][6:0] != 7'b0100011  && instr [1][6:0] != 7'b0000011) begin //not writing to datamem and not load
                
                    if (reg_addr [1] > 9) begin
                        $fwrite(file_pointer_model, "0x%8h (0x%8h) x%0d 0x%8h", pc_o[1], instr[1], reg_addr[1], reg_data[1]);
                    end 
                    
                    else begin
                        $fwrite(file_pointer_model, "0x%8h (0x%8h) x%0d  0x%8h", pc_o[1], instr[1], reg_addr[1], reg_data[1]);
                    end
                    
                end
                
                else if (mem_wrt[1] == 1 && instr [1] [6:0] == 7'b0100011) begin  //store
                    $fwrite(file_pointer_model, "0x%8h (0x%8h) mem 0x%8h 0x%8h",pc_o[1], instr[1],  mem_addr[1], mem_data[1]);
                end
                
                
                else if (instr [1] [6:0] == 7'b0000011) begin  //load to register  (from memory)
                    $fwrite(file_pointer_model, "0x%8h (0x%8h) x%0d 0x%8h mem 0x%8h"
                    , pc_o[1], instr[1], reg_addr[1], reg_data[1], mem_addr[1]);    
                end

                $fwrite(file_pointer_model, "\n");

            end

            // Sayaç sadece 3'ten küçükken artacak
            if (write_counter < 3)
                write_counter = write_counter + 1;

        end
        
        #2;
    end
end
 



  initial forever begin
    clk = 0;
    #1;
    clk = 1;
    #1;
  end

  initial begin
    rstn = 0;
    #4;
    rstn = 1;
    #10000;

    
    for (logic [31:0] i = 32'h8000_0000; i < 32'h8000_0000 + 'h20; i = i + 4) begin
      addr = i;
      #4;
      $display("data @ mem[0x%8h] = %8h", addr, data);
    end
    
    /*
    for (logic [31:0] i = 32'h8001_0008; i < 32'h8001_0020 + 'h20; i = i + 8) begin
      addr = i;
      #4;
      $display("data @ mem[0x%8h] = %8h", addr, data);
    end
    */

    $finish;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars();
  end

endmodule
