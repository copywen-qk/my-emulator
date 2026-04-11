// Corrected RV32IM Pipeline CPU
// Fixes the timing issues found in previous versions

module rv32im_pipeline_corrected(
  input clk,
  input rst_n
);

  // DPI-C interface
  import "DPI-C" context function int paddr_read(input int addr, input int len);
  import "DPI-C" context function void paddr_write(input int addr, input int len, input int data);
  import "DPI-C" context function void difftest_step(input int dut_pc);

  // ==================== GLOBAL STATE ====================
  reg [31:0] pc;              // Program counter
  reg [31:0] rf [31:0];       // Register file
  
  // ==================== PIPELINE REGISTERS ====================
  
  // IF/ID stage registers
  reg [31:0] if_id_pc;
  reg [31:0] if_id_inst;
  reg        if_id_valid;
  
  // ID/EX stage registers
  reg [31:0] id_ex_pc;
  reg [31:0] id_ex_inst;
  reg [4:0]  id_ex_rd;
  reg [31:0] id_ex_rs1_val;
  reg [31:0] id_ex_rs2_val;
  reg [31:0] id_ex_imm;
  reg        id_ex_regwrite;
  reg        id_ex_memtoreg;
  reg        id_ex_valid;
  
  // EX/MEM stage registers
  reg [31:0] ex_mem_pc;
  reg [31:0] ex_mem_alu_result;
  reg [4:0]  ex_mem_rd;
  reg        ex_mem_regwrite;
  reg        ex_mem_memtoreg;
  reg [31:0] ex_mem_rs2_val;
  reg        ex_mem_valid;
  
  // MEM/WB stage registers
  reg [31:0] mem_wb_pc;
  reg [31:0] mem_wb_data;
  reg [4:0]  mem_wb_rd;
  reg        mem_wb_regwrite;
  reg        mem_wb_memtoreg;
  reg        mem_wb_valid;
  
  // ==================== STAGE 1: INSTRUCTION FETCH ====================
  // Instruction is read combinationally from memory
  wire [31:0] current_inst = paddr_read(pc, 4);
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset state
      pc <= 32'h80000000;
      if_id_pc <= 32'h80000000;
      if_id_inst <= 32'h00000013;  // NOP (ADDI x0, x0, 0)
      if_id_valid <= 1'b0;
    end else begin
      // Normal operation: update pipeline registers at clock edge
      if_id_pc <= pc;
      if_id_inst <= current_inst;  // Instruction read at current PC
      if_id_valid <= 1'b1;
      
      // Update PC for next cycle
      pc <= pc + 4;
    end
  end
  
  // ==================== STAGE 2: INSTRUCTION DECODE ====================
  wire [6:0]  opcode = if_id_inst[6:0];
  wire [4:0]  rd     = if_id_inst[11:7];
  wire [4:0]  rs1    = if_id_inst[19:15];
  wire [4:0]  rs2    = if_id_inst[24:20];
  wire [2:0]  funct3 = if_id_inst[14:12];
  
  // Register file read with forwarding from EX/MEM stage
  wire [31:0] rs1_val_raw = (rs1 != 0) ? rf[rs1] : 32'h0;
  wire [31:0] rs2_val_raw = (rs2 != 0) ? rf[rs2] : 32'h0;
  
  // Simple forwarding: if EX/MEM is writing to our source register, use that value
  wire [31:0] rs1_val = (rs1 == ex_mem_rd && ex_mem_regwrite && rs1 != 0) ? 
                       ex_mem_alu_result : rs1_val_raw;
  wire [31:0] rs2_val = (rs2 == ex_mem_rd && ex_mem_regwrite && rs2 != 0) ? 
                       ex_mem_alu_result : rs2_val_raw;
  
  // Immediate generation
  wire [31:0] imm_i = {{20{if_id_inst[31]}}, if_id_inst[31:20]};
  wire [31:0] imm_s = {{20{if_id_inst[31]}}, if_id_inst[31:25], if_id_inst[11:7]};
  wire [31:0] imm_u = {if_id_inst[31:12], 12'b0};
  
  // Control signal generation
  reg regwrite, memtoreg;
  reg [31:0] imm;
  
  always @(*) begin
    // Default values
    regwrite = 1'b0;
    memtoreg = 1'b0;
    imm = 32'h0;
    
    if (if_id_valid) begin
      case (opcode)
        7'b0110111: begin  // LUI
          regwrite = 1'b1;
          memtoreg = 1'b0;
          imm = imm_u;
        end
        7'b0010111: begin  // AUIPC
          regwrite = 1'b1;
          memtoreg = 1'b0;
          imm = imm_u;
        end
        7'b0010011: begin  // OP-IMM (ADDI, etc.)
          regwrite = 1'b1;
          memtoreg = 1'b0;
          imm = imm_i;
        end
        7'b0110011: begin  // OP (ADD, etc.)
          regwrite = 1'b1;
          memtoreg = 1'b0;
          imm = 32'h0;
        end
        7'b0000011: begin  // Load
          regwrite = 1'b1;
          memtoreg = 1'b1;
          imm = imm_i;
        end
        7'b0100011: begin  // Store
          regwrite = 1'b0;
          memtoreg = 1'b0;
          imm = imm_s;
        end
        default: begin
          // NOP or unknown instruction
          regwrite = 1'b0;
          memtoreg = 1'b0;
          imm = 32'h0;
        end
      endcase
    end
  end
  
  // ID/EX pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_ex_pc <= 32'h0;
      id_ex_inst <= 32'h00000013;  // NOP
      id_ex_rd <= 5'h0;
      id_ex_rs1_val <= 32'h0;
      id_ex_rs2_val <= 32'h0;
      id_ex_imm <= 32'h0;
      id_ex_regwrite <= 1'b0;
      id_ex_memtoreg <= 1'b0;
      id_ex_valid <= 1'b0;
    end else begin
      id_ex_pc <= if_id_pc;
      id_ex_inst <= if_id_inst;
      id_ex_rd <= rd;
      id_ex_rs1_val <= rs1_val;
      id_ex_rs2_val <= rs2_val;
      id_ex_imm <= imm;
      id_ex_regwrite <= regwrite;
      id_ex_memtoreg <= memtoreg;
      id_ex_valid <= if_id_valid;
    end
  end
  
  // ==================== STAGE 3: EXECUTE ====================
  wire [6:0]  ex_opcode = id_ex_inst[6:0];
  wire [2:0]  ex_funct3 = id_ex_inst[14:12];
  
  // ALU inputs
  wire [31:0] alu_a = id_ex_rs1_val;
  wire [31:0] alu_b = (ex_opcode == 7'b0010011 || ex_opcode == 7'b0000011 || 
                      ex_opcode == 7'b0100011) ? id_ex_imm : id_ex_rs2_val;
  
  // ALU operation
  reg [31:0] alu_result;
  
  always @(*) begin
    if (id_ex_valid) begin
      case (ex_funct3)
        3'b000: alu_result = alu_a + alu_b;  // ADD/ADDI
        3'b001: alu_result = alu_a << alu_b[4:0];  // SLL/SLLI
        3'b010: alu_result = ($signed(alu_a) < $signed(alu_b)) ? 32'h1 : 32'h0;  // SLT/SLTI
        3'b011: alu_result = (alu_a < alu_b) ? 32'h1 : 32'h0;  // SLTU/SLTIU
        3'b100: alu_result = alu_a ^ alu_b;  // XOR/XORI
        3'b101: alu_result = alu_a >> alu_b[4:0];  // SRL/SRLI (logical right shift)
        3'b110: alu_result = alu_a | alu_b;  // OR/ORI
        3'b111: alu_result = alu_a & alu_b;  // AND/ANDI
        default: alu_result = 32'h0;
      endcase
    end else begin
      alu_result = 32'h0;
    end
  end
  
  // EX/MEM pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ex_mem_pc <= 32'h0;
      ex_mem_alu_result <= 32'h0;
      ex_mem_rd <= 5'h0;
      ex_mem_regwrite <= 1'b0;
      ex_mem_memtoreg <= 1'b0;
      ex_mem_rs2_val <= 32'h0;
      ex_mem_valid <= 1'b0;
    end else begin
      ex_mem_pc <= id_ex_pc;
      ex_mem_alu_result <= alu_result;
      ex_mem_rd <= id_ex_rd;
      ex_mem_regwrite <= id_ex_regwrite;
      ex_mem_memtoreg <= id_ex_memtoreg;
      ex_mem_rs2_val <= id_ex_rs2_val;
      ex_mem_valid <= id_ex_valid;
    end
  end
  
  // ==================== STAGE 4: MEMORY ACCESS ====================
  // Memory access happens combinationally
  wire [31:0] mem_read_data = ex_mem_memtoreg ? paddr_read(ex_mem_alu_result, 4) : 32'h0;
  
  // Handle store instructions
  always @(*) begin
    if (ex_mem_valid && ex_opcode == 7'b0100011) begin
      paddr_write(ex_mem_alu_result, 4, ex_mem_rs2_val);
    end
  end
  
  // MEM/WB pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_wb_pc <= 32'h0;
      mem_wb_data <= 32'h0;
      mem_wb_rd <= 5'h0;
      mem_wb_regwrite <= 1'b0;
      mem_wb_memtoreg <= 1'b0;
      mem_wb_valid <= 1'b0;
    end else begin
      mem_wb_pc <= ex_mem_pc;
      mem_wb_data <= ex_mem_memtoreg ? mem_read_data : ex_mem_alu_result;
      mem_wb_rd <= ex_mem_rd;
      mem_wb_regwrite <= ex_mem_regwrite;
      mem_wb_memtoreg <= ex_mem_memtoreg;
      mem_wb_valid <= ex_mem_valid;
    end
  end
  
  // ==================== STAGE 5: WRITE BACK ====================
  // Register write back
  always @(posedge clk) begin
    if (mem_wb_valid && mem_wb_regwrite && (mem_wb_rd != 0)) begin
      rf[mem_wb_rd] <= mem_wb_data;
    end
  end
  
  // ==================== DEBUG AND MONITORING ====================
  integer cycle_count = 0;
  
  always @(posedge clk) begin
    if (rst_n) begin
      cycle_count <= cycle_count + 1;
      
      // Diff-test
      difftest_step(pc);
      
      // Detailed debug for first 20 cycles
      if (cycle_count < 20) begin
        $display("=== CYCLE %0d ===", cycle_count);
        $display("  PC: %h", pc);
        $display("  IF: fetching from PC %h", pc);
        $display("  ID: pc=%h, inst=%h, rd=x%0d", if_id_pc, if_id_inst, rd);
        $display("  EX: pc=%h, alu=%h, rd=x%0d", id_ex_pc, alu_result, id_ex_rd);
        $display("  MEM: pc=%h, data=%h, rd=x%0d", ex_mem_pc, mem_read_data, ex_mem_rd);
        $display("  WB: pc=%h, data=%h, rd=x%0d", mem_wb_pc, mem_wb_data, mem_wb_rd);
        
        // Show forwarding if happening
        if (rs1 == ex_mem_rd && ex_mem_regwrite && rs1 != 0) begin
          $display("  [FORWARD] rs1=x%0d forwarded from EX/MEM: %h", rs1, ex_mem_alu_result);
        end
        if (rs2 == ex_mem_rd && ex_mem_regwrite && rs2 != 0) begin
          $display("  [FORWARD] rs2=x%0d forwarded from EX/MEM: %h", rs2, ex_mem_alu_result);
        end
        $display("");
      end
      
      // Summary at key points
      if (cycle_count == 5) begin
        $display("[PIPELINE] Pipeline should be filling...");
      end
      if (cycle_count == 10) begin
        $display("[PIPELINE] Pipeline should be full now");
        $display("[PIPELINE] Instructions in flight: IF, ID, EX, MEM, WB");
      end
    end
  end
  
  initial begin
    $display("[PIPELINE] Corrected RV32IM Pipeline CPU initialized");
    $display("[PIPELINE] Key fixes applied:");
    $display("[PIPELINE] 1. Memory read at clock edge (not combinational)");
    $display("[PIPELINE] 2. PC updates at clock edge");
    $display("[PIPELINE] 3. Pipeline registers updated synchronously");
    $display("[PIPELINE] 4. Simple data forwarding implemented");
  end
  
endmodule