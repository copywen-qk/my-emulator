// Simple Pipeline Demonstration
// Shows basic 5-stage pipeline operation

module simple_pipeline_demo;

  // Test program in memory
  reg [31:0] memory [0:15];
  reg [31:0] pc;
  reg [31:0] registers [0:31];
  
  // Pipeline registers
  reg [31:0] if_id_pc;
  reg [31:0] if_id_inst;
  
  reg [31:0] id_ex_pc;
  reg [31:0] id_ex_inst;
  reg [4:0]  id_ex_rd;
  reg [31:0] id_ex_a;
  reg [31:0] id_ex_b;
  
  reg [31:0] ex_mem_pc;
  reg [31:0] ex_mem_result;
  reg [4:0]  ex_mem_rd;
  
  reg [31:0] mem_wb_pc;
  reg [31:0] mem_wb_result;
  reg [4:0]  mem_wb_rd;
  
  integer cycle;
  
  // Initialize
  initial begin
    $display("=== SIMPLE PIPELINE DEMONSTRATION ===");
    $display("");
    
    // Initialize memory with simple program
    // Program: addi x1, x0, 1
    //          addi x2, x0, 2
    //          add  x3, x1, x2
    memory[0] = 32'h00100093;  // addi x1, x0, 1
    memory[1] = 32'h00200113;  // addi x2, x0, 2
    memory[2] = 32'h002081b3;  // add  x3, x1, x2
    memory[3] = 32'h00000013;  // nop
    memory[4] = 32'h00000013;  // nop
    
    // Initialize registers
    for (integer i = 0; i < 32; i = i + 1) begin
      registers[i] = 32'h0;
    end
    
    pc = 32'h0;
    if_id_pc = 32'h0;
    if_id_inst = 32'h00000013;
    
    id_ex_pc = 32'h0;
    id_ex_inst = 32'h00000013;
    id_ex_rd = 5'h0;
    id_ex_a = 32'h0;
    id_ex_b = 32'h0;
    
    ex_mem_pc = 32'h0;
    ex_mem_result = 32'h0;
    ex_mem_rd = 5'h0;
    
    mem_wb_pc = 32'h0;
    mem_wb_result = 32'h0;
    mem_wb_rd = 5'h0;
    
    cycle = 0;
    
    $display("Initial state:");
    print_state();
    $display("");
    
    // Run pipeline for 10 cycles
    for (cycle = 1; cycle <= 10; cycle = cycle + 1) begin
      $display("=== CYCLE %0d ===", cycle);
      
      // Pipeline stages (in reverse order to show flow)
      
      // 5. WRITE BACK
      if (mem_wb_rd != 0) begin
        registers[mem_wb_rd] = mem_wb_result;
        $display("  WB: Write x%0d = %h", mem_wb_rd, mem_wb_result);
      end
      
      // 4. MEMORY (pass through)
      mem_wb_pc = ex_mem_pc;
      mem_wb_result = ex_mem_result;
      mem_wb_rd = ex_mem_rd;
      $display("  MEM: Pass result %h for x%0d", ex_mem_result, ex_mem_rd);
      
      // 3. EXECUTE
      ex_mem_pc = id_ex_pc;
      ex_mem_rd = id_ex_rd;
      
      // Simple ALU: handle addi and add
      if (id_ex_inst[6:0] == 7'b0010011) begin // addi
        ex_mem_result = id_ex_a + {{20{id_ex_inst[31]}}, id_ex_inst[31:20]};
        $display("  EX: addi x%0d = %h + %h = %h", 
                 id_ex_rd, id_ex_a, {{20{id_ex_inst[31]}}, id_ex_inst[31:20]}, ex_mem_result);
      end else if (id_ex_inst[6:0] == 7'b0110011) begin // add
        ex_mem_result = id_ex_a + id_ex_b;
        $display("  EX: add x%0d = %h + %h = %h", 
                 id_ex_rd, id_ex_a, id_ex_b, ex_mem_result);
      end else begin // nop
        ex_mem_result = 32'h0;
        $display("  EX: NOP");
      end
      
      // 2. DECODE
      id_ex_pc = if_id_pc;
      id_ex_inst = if_id_inst;
      id_ex_rd = if_id_inst[11:7];
      id_ex_a = registers[if_id_inst[19:15]];
      id_ex_b = registers[if_id_inst[24:20]];
      $display("  ID: Decode inst=%h, rd=x%0d", if_id_inst, if_id_inst[11:7]);
      
      // 1. FETCH
      if_id_pc = pc;
      if_id_inst = memory[pc[3:2]]; // Simple 2-bit index for demo
      $display("  IF: Fetch inst=%h from PC=%h", memory[pc[3:2]], pc);
      
      // Update PC
      pc = pc + 4;
      
      print_state();
      $display("");
    end
    
    $display("=== FINAL RESULTS ===");
    $display("x1 = %h (expected: 00000001)", registers[1]);
    $display("x2 = %h (expected: 00000002)", registers[2]);
    $display("x3 = %h (expected: 00000003)", registers[3]);
    
    if (registers[1] == 32'h1 && registers[2] == 32'h2 && registers[3] == 32'h3) begin
      $display("[SUCCESS] Pipeline demonstration completed successfully!");
    end else begin
      $display("[FAILURE] Results incorrect");
    end
    
    $finish;
  end
  
  // Helper function to print pipeline state
  task print_state;
    begin
      $display("Pipeline State:");
      $display("  PC: %h", pc);
      $display("  IF/ID: pc=%h, inst=%h", if_id_pc, if_id_inst);
      $display("  ID/EX: pc=%h, inst=%h, rd=x%0d", id_ex_pc, id_ex_inst, id_ex_rd);
      $display("  EX/MEM: pc=%h, result=%h, rd=x%0d", ex_mem_pc, ex_mem_result, ex_mem_rd);
      $display("  MEM/WB: pc=%h, result=%h, rd=x%0d", mem_wb_pc, mem_wb_result, mem_wb_rd);
    end
  endtask
  
endmodule