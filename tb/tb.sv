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
    parameter int    IssueWidth = 2,
    parameter string TableFile  = "table.log",
    parameter string ModelFile  = "model.log"
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
        .IssueWidth (IssueWidth),
        .TableFile  (TableFile),
        .ModelFile  (ModelFile)
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

bit update_fell_both, update_fell_one;
bit stall_write;
bit stall_write1;

initial begin
  file_pointer = $fopen(TableFile, "w");
  $fwrite(file_pointer, "Cycle       F           D           E           M           WB\n");

  cycle_counter = 1;
  final_cycles = 0;
  update_fell_both = 0;
  update_fell_one  = 0;
  stall_write = 0;

  #2

  forever begin
    #2;

    if (update[1]) begin     
      $fwrite(file_pointer, "%5dA  ", cycle_counter);

      if (cycle_counter == 1)
        $fwrite(file_pointer, "0x%08h\n", pc_f[0]);

      else if (cycle_counter == 2)
        $fwrite(file_pointer, "0x%08h  0x%08h\n", pc_f[0], pc_d[0]);
                                                                                             // first cycles  (path1)
      else if (cycle_counter == 3)
        $fwrite(file_pointer, "0x%08h  0x%08h  0x%08h\n", pc_f[0], pc_d[0], pc_e[0]);

      else if (cycle_counter == 4)
        $fwrite(file_pointer, "0x%08h  0x%08h  0x%08h  0x%08h\n", pc_f[0], pc_d[0], pc_e[0], pc_m[0]);

      else if (stall_write) begin
        $fwrite(file_pointer, "Stall     ");
        $fwrite(file_pointer, "  Stall     ");
        $fwrite(file_pointer, "  Flushed     ");
        $fwrite(file_pointer, "0x%08h  ", pc_m[0]);
        $fwrite(file_pointer, "0x%08h\n", pc_wb[0]);

        stall_write = 0;
      end
     

      else begin
        if (StallD[0] || StallF[0] )
          stall_write = 1;

        if (pc_f[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_f[0]);

        if (pc_d[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_d[0]);

        if (pc_e[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else                                                                // typical cycles for first path
          $fwrite(file_pointer, "0x%08h  ", pc_e[0]);

        if (pc_m[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[0]);

        if (pc_wb[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[0]);
      end

    /////////////////////for path2///////////////////////////////////////////////////////////////////////////

      $fwrite(file_pointer, "%5dB  ", cycle_counter);

      if (cycle_counter == 1)
        $fwrite(file_pointer, "0x%08h\n", pc_f[1]);

      else if (cycle_counter == 2)
        $fwrite(file_pointer, "0x%08h  0x%08h\n", pc_f[1], pc_d[1]);
                                                                                             // first cycles  (path2)
      else if (cycle_counter == 3)
        $fwrite(file_pointer, "0x%08h  0x%08h  0x%08h\n", pc_f[1], pc_d[1], pc_e[1]);

      else if (cycle_counter == 4)
        $fwrite(file_pointer, "0x%08h  0x%08h  0x%08h  0x%08h\n", pc_f[1], pc_d[1], pc_e[1], pc_m[1]);

      else if (stall_write1) begin
        $fwrite(file_pointer, "Stall     ");
        $fwrite(file_pointer, "  Stall     ");
        $fwrite(file_pointer, "  Flushed     ");
        $fwrite(file_pointer, "0x%08h  ", pc_m[1]);
        $fwrite(file_pointer, "0x%08h\n", pc_wb[1]);

        stall_write1 = 0;
      end
   

     ///////////////////////////////////////////for stall_write1  ///////////////////////////////////////////////////////////////// 

    else begin
        if (StallD[1] || StallF[1])
          stall_write1 = 1;

        if (pc_f[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_f[1]);

        if (pc_d[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_d[1]);

        if (pc_e[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");                               // typical cycles for second path
        else
          $fwrite(file_pointer, "0x%08h  ", pc_e[1]);

        if (pc_m[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[1]);

        if (pc_wb[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[1]);
      end

      cycle_counter = cycle_counter + 1;                                      // next cycle (for update[1] signal)




    end // end of if(update[1])


    //////////////////////////////////////////// last cycles //////////////////////////////////////////////////
    // BURAYA EKSİK OLANI EKLİYORUZ:
    if (!update[0] && !update[1] && !update_fell_both && !update_fell_one) begin
      update_fell_both = 1;
      final_cycles = 4;  // <------ Eksik olan satır! Artık tamam
    end

    else if (!update[1] && !update_fell_one && !update_fell_both) begin
      update_fell_one = 1;
      final_cycles = 5;  // <------ One more cycle needed
    end

    //////////////////////// last cycles for update_both_fell////////////////////////////////////////////
    if (update_fell_both && (final_cycles > 0)) begin      // last cycles

    ////////////////////////// first path //////////////////////////////////////////

      $fwrite(file_pointer, "%5dA  ", cycle_counter);

      if (final_cycles == 4) begin
        $fwrite(file_pointer, "            "); // F boşluk
        if (pc_d[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_d[0]);

        if (pc_e[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_e[0]);

        if (pc_m[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[0]);

        if (pc_wb[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[0]);
      end

      else if (final_cycles == 3) begin
        $fwrite(file_pointer, "                        "); // F, D boşluk
        if (pc_e[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_e[0]);

        if (pc_m[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[0]);

        if (pc_wb[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[0]);
      end

      else if (final_cycles == 2) begin
        $fwrite(file_pointer, "                                    "); // F, D, E boşluk
        if (pc_m[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[0]);

        if (pc_wb[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[0]);
      end

      else if (final_cycles == 1) begin
        $fwrite(file_pointer, "                                                "); // F, D, E, M boşluk
        if (pc_wb[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[0]);
      end

    ///////////////////////////////// second path/////////////////////////////////////////////////////////
     
     $fwrite(file_pointer, "%5dB  ", cycle_counter);
     
      if (final_cycles == 4) begin
        $fwrite(file_pointer, "            "); // F boşluk
        if (pc_d[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_d[1]);

        if (pc_e[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_e[1]);

        if (pc_m[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[1]);

        if (pc_wb[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[1]);
      end

      else if (final_cycles == 3) begin
        $fwrite(file_pointer, "                        "); // F, D boşluk
        if (pc_e[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_e[1]);

        if (pc_m[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[1]);

        if (pc_wb[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[1]);
      end

      else if (final_cycles == 2) begin
        $fwrite(file_pointer, "                                    "); // F, D, E boşluk
        if (pc_m[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[1]);

        if (pc_wb[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[1]);
      end

      else if (final_cycles == 1) begin
        $fwrite(file_pointer, "                                                "); // F, D, E, M boşluk
        if (pc_wb[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[1]);
      end

          final_cycles = final_cycles - 1;
          cycle_counter = cycle_counter + 1;

    end       // end of update_fell_both
    
   
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////// last cycles for update_fell_one/////////////////////////////////////////////

    else if (update_fell_one && (final_cycles > 0)) begin      // last cycles

    ////////////////////////// first path //////////////////////////////////////////

      $fwrite(file_pointer, "%5dA  ", cycle_counter);

      if (final_cycles == 5) begin

        if (pc_f[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_f[0]);

        if (pc_d[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_d[0]);

        if (pc_e[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_e[0]);

        if (pc_m[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[0]);

        if (pc_wb[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[0]);
      end



      if (final_cycles == 4) begin
        $fwrite(file_pointer, "            "); // F boşluk

        if (pc_d[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_d[0]);

        if (pc_e[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_e[0]);

        if (pc_m[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[0]);

        if (pc_wb[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[0]);
      end

      else if (final_cycles == 3) begin
        $fwrite(file_pointer, "                        "); // F, D boşluk
        if (pc_e[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_e[0]);

        if (pc_m[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[0]);

        if (pc_wb[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[0]);
      end

      else if (final_cycles == 2) begin
        $fwrite(file_pointer, "                                    "); // F, D, E boşluk
        if (pc_m[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[0]);

        if (pc_wb[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[0]);
      end

      else if (final_cycles == 1) begin
        $fwrite(file_pointer, "                                                "); // F, D, E, M boşluk
        if (pc_wb[0] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[0]);
      end

    ///////////////////////////////// second path/////////////////////////////////////////////////////////

     $fwrite(file_pointer, "%5dB  ", cycle_counter);


      if (final_cycles == 5) begin
        $fwrite(file_pointer, "            "); // F boşluk
        if (pc_d[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_d[1]);

        if (pc_e[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_e[1]);

        if (pc_m[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[1]);

        if (pc_wb[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[1]);
      end

      else if (final_cycles == 4) begin
        $fwrite(file_pointer, "                        "); // F, D boşluk
        if (pc_e[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_e[1]);

        if (pc_m[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[1]);

        if (pc_wb[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[1]);
      end

      else if (final_cycles == 3) begin
        $fwrite(file_pointer, "                                    "); // F, D, E boşluk
        if (pc_m[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     ");
        else
          $fwrite(file_pointer, "0x%08h  ", pc_m[1]);

        if (pc_wb[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[1]);
      end

      else if (final_cycles == 2) begin
        $fwrite(file_pointer, "                                                "); // F, D, E, M boşluk
        if (pc_wb[1] == 32'h0)
          $fwrite(file_pointer, "Flushed     \n");
        else
          $fwrite(file_pointer, "0x%08h\n", pc_wb[1]);
      end


      else if (final_cycles == 1) begin
        $fwrite(file_pointer, "                                                            \n"); // F, D, E, M, WB boşluk
        
      end

          final_cycles = final_cycles - 1;
          cycle_counter = cycle_counter + 1;

    end       // end of update_fell_one

  end
end


integer file_pointer_model;
integer write_counter = 0; // Yeni sayaç

initial begin

    file_pointer_model = $fopen(ModelFile, "w");
    #4

    forever begin
        if (update_model [0]) begin

            if (write_counter >= 3) begin // sadece 3 cycle geçtikten sonra yaz

                if (reg_addr [0] == 0 && mem_wrt [0] ==0) begin  //branch
                    $fwrite(file_pointer_model, "0x%8h (0x%8h)\n", pc_o[0], instr[0]);
                end 
                
                else if (!mem_wrt[0] && instr [0] [6:0] != 7'b0000011) begin //not writing to datamem and not load
                
                    if (reg_addr [0] > 9) begin
                        $fwrite(file_pointer_model, "0x%8h (0x%8h) x%0d 0x%8h\n", pc_o[0], instr[0], reg_addr[0], reg_data[0]);
                    end 
                    
                    else begin
                        $fwrite(file_pointer_model, "0x%8h (0x%8h) x%0d  0x%8h\n", pc_o[0], instr[0], reg_addr[0], reg_data[0]);
                    end
                    
                end
                
                else if (mem_wrt[0] == 1) begin  //store
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
                
                else if (!mem_wrt[1] && instr [1][6:0] != 7'b0000011) begin //not writing to datamem and not load
                
                    if (reg_addr [1] > 9) begin
                        $fwrite(file_pointer_model, "0x%8h (0x%8h) x%0d 0x%8h", pc_o[1], instr[1], reg_addr[1], reg_data[1]);
                    end 
                    
                    else begin
                        $fwrite(file_pointer_model, "0x%8h (0x%8h) x%0d  0x%8h", pc_o[1], instr[1], reg_addr[1], reg_data[1]);
                    end
                    
                end
                
                else if (mem_wrt[1] == 1) begin  //store
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

    $finish;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars();
  end

endmodule
