module rv32im_cpu(
  input clk,
  input rst_n
);

  /* verilator lint_off UNUSEDSIGNAL */

  // DPI-C interface for memory access and diff-test
  import "DPI-C" context function int paddr_read(input int addr, input int len);
  import "DPI-C" context function void paddr_write(input int addr, input int len, input int data);
  import "DPI-C" context function void difftest_step(input int dut_pc);

  // ==================== Pipeline Registers ====================
  reg [31:0] pc;
  reg [31:0] rf [31:0];  // Register File

  // ==================== Instruction Fetch ====================
  wire [31:0] inst;
  assign inst = paddr_read(pc, 4);

  // ==================== Instruction Decode ====================
  // RISC-V instruction fields
  wire [6:0] opcode = inst[6:0];
  wire [4:0] rd     = inst[11:7];
  wire [4:0] rs1    = inst[19:15];
  wire [4:0] rs2    = inst[24:20];
  wire [2:0] funct3 = inst[14:12];
  wire [6:0] funct7 = inst[31:25];

  // Register read
  wire [31:0] rs1_val = (rs1 != 0) ? rf[rs1] : 32'h0;
  wire [31:0] rs2_val = (rs2 != 0) ? rf[rs2] : 32'h0;

  // Immediate generation
  wire [31:0] imm_i = {{20{inst[31]}}, inst[31:20]};
  wire [31:0] imm_s = {{20{inst[31]}}, inst[31:25], inst[11:7]};
  wire [31:0] imm_b = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
  wire [31:0] imm_u = {inst[31:12], 12'b0};
  wire [31:0] imm_j = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

  // ==================== Execute Stage ====================
  // ALU operation
  reg [31:0] alu_result;
  reg alu_zero;
  reg [31:0] alu_b;

  // ALU B input selection
  always @(*) begin
    case (opcode)
      7'b0010011, 7'b0000011, 7'b1100111: alu_b = imm_i;  // OP-IMM, Load, JALR
      7'b0100011: alu_b = imm_s;                          // Store
      7'b0110011, 7'b1100011: alu_b = rs2_val;            // R-type, Branch
      default: alu_b = 32'h0;                             // Others
    endcase
  end

  // ALU operation
  always @(*) begin
    alu_result = 32'h0;
    alu_zero = 1'b0;
    
    case (opcode)
      // OP-IMM
      7'b0010011: begin
        case (funct3)
          3'b000: alu_result = rs1_val + alu_b;                     // ADDI
          3'b001: alu_result = rs1_val << alu_b[4:0];               // SLLI
          3'b010: alu_result = ($signed(rs1_val) < $signed(alu_b)) ? 32'h1 : 32'h0; // SLTI
          3'b011: alu_result = (rs1_val < alu_b) ? 32'h1 : 32'h0;   // SLTIU
          3'b100: alu_result = rs1_val ^ alu_b;                     // XORI
          3'b101: alu_result = (funct7[5]) ? 
                              $signed(rs1_val) >>> alu_b[4:0] :     // SRAI
                              rs1_val >> alu_b[4:0];                // SRLI
          3'b110: alu_result = rs1_val | alu_b;                     // ORI
          3'b111: alu_result = rs1_val & alu_b;                     // ANDI
          default: alu_result = 32'h0;
        endcase
      end
      
      // OP (R-Type)
      7'b0110011: begin
        case (funct3)
          3'b000: alu_result = (funct7[5]) ? 
                              rs1_val - alu_b :                     // SUB
                              rs1_val + alu_b;                      // ADD
          3'b001: alu_result = rs1_val << alu_b[4:0];               // SLL
          3'b010: alu_result = ($signed(rs1_val) < $signed(alu_b)) ? 32'h1 : 32'h0; // SLT
          3'b011: alu_result = (rs1_val < alu_b) ? 32'h1 : 32'h0;   // SLTU
          3'b100: alu_result = rs1_val ^ alu_b;                     // XOR
          3'b101: alu_result = (funct7[5]) ? 
                              $signed(rs1_val) >>> alu_b[4:0] :     // SRA
                              rs1_val >> alu_b[4:0];                // SRL
          3'b110: alu_result = rs1_val | alu_b;                     // OR
          3'b111: alu_result = rs1_val & alu_b;                     // AND
          default: alu_result = 32'h0;
        endcase
      end
      
      // Load/Store address calculation
      7'b0000011, 7'b0100011: begin
        alu_result = rs1_val + alu_b;    // Memory address
      end
      
      // Branch comparison
      7'b1100011: begin
        case (funct3)
          3'b000: alu_zero = (rs1_val == rs2_val);  // BEQ
          3'b001: alu_zero = (rs1_val != rs2_val);  // BNE
          3'b100: alu_zero = ($signed(rs1_val) < $signed(rs2_val));  // BLT
          3'b101: alu_zero = ($signed(rs1_val) >= $signed(rs2_val)); // BGE
          3'b110: alu_zero = (rs1_val < rs2_val);   // BLTU
          3'b111: alu_zero = (rs1_val >= rs2_val);  // BGEU
          default: alu_zero = 1'b0;
        endcase
        alu_result = 32'h0;  // Not used for branches
      end
      
      // LUI
      7'b0110111: begin
        alu_result = imm_u;
      end
      
      // AUIPC
      7'b0010111: begin
        alu_result = pc + imm_u;
      end
      
      default: begin
        alu_result = 32'h0;
        alu_zero = 1'b0;
      end
    endcase
  end

  // ==================== Memory Access ====================
  reg [31:0] mem_data;
  
  // Temporary registers for memory read results
  reg [31:0] mem_read_result;
  
  always @(*) begin
    mem_data = 32'h0;
    mem_read_result = 32'h0;
    
    if (opcode == 7'b0000011) begin  // Load instructions
      // Read memory
      mem_read_result = paddr_read(alu_result, 4);  // Always read word, we'll extract needed bits
      
      case (funct3)
        3'b000: mem_data = {{24{mem_read_result[7]}}, mem_read_result[7:0]};   // LB
        3'b001: mem_data = {{16{mem_read_result[15]}}, mem_read_result[15:0]}; // LH
        3'b010: mem_data = mem_read_result;                                    // LW
        3'b100: mem_data = {24'b0, mem_read_result[7:0]};                     // LBU
        3'b101: mem_data = {16'b0, mem_read_result[15:0]};                    // LHU
        default: mem_data = 32'h0;
      endcase
    end else if (opcode == 7'b0100011) begin  // Store instructions
      case (funct3)
        3'b000: paddr_write(alu_result, 1, {{24{1'b0}}, rs2_val[7:0]});     // SB
        3'b001: paddr_write(alu_result, 2, {{16{1'b0}}, rs2_val[15:0]});    // SH
        3'b010: paddr_write(alu_result, 4, rs2_val);                        // SW
        default: ; // Do nothing for other funct3 values
      endcase
    end
  end

  // ==================== Write Back ====================
  reg [31:0] wb_data;
  
  always @(*) begin
    wb_data = 32'h0;
    
    case (opcode)
      7'b0110111: wb_data = alu_result;                     // LUI
      7'b0010111: wb_data = alu_result;                     // AUIPC
      7'b1101111: wb_data = pc + 4;                         // JAL
      7'b1100111: wb_data = pc + 4;                         // JALR
      7'b0010011: wb_data = alu_result;                     // OP-IMM
      7'b0110011: wb_data = alu_result;                     // OP
      7'b0000011: wb_data = mem_data;                       // Load
      default: wb_data = 32'h0;
    endcase
  end

  // ==================== Next PC Logic ====================
  reg [31:0] next_pc;
  reg pc_update;
  
  always @(*) begin
    pc_update = 1'b0;
    next_pc = pc + 4;
    
    case (opcode)
      // JAL
      7'b1101111: begin
        next_pc = pc + imm_j;
        pc_update = 1'b1;
      end
      
      // JALR
      7'b1100111: begin
        next_pc = (rs1_val + imm_i) & ~32'h1;
        pc_update = 1'b1;
      end
      
      // Branch
      7'b1100011: begin
        if (alu_zero) begin
          next_pc = pc + imm_b;
          pc_update = 1'b1;
        end
      end
      
      default: begin
        // For all other instructions, PC increments by 4
        next_pc = pc + 4;
        pc_update = 1'b0;
      end
    endcase
  end

  // ==================== Clock Cycle ====================
  integer i;
  
  initial begin
    pc = 32'h80000000;  // Reset vector
    for (i = 0; i < 32; i = i + 1) rf[i] = 32'h0;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc <= 32'h80000000;
      for (i = 0; i < 32; i = i + 1) rf[i] <= 32'h0;
    end else begin
      // Debug output
      $display("[RV32IM] PC = 0x%08h, Inst = 0x%08h, Opcode = 0x%02h", pc, inst, opcode);
      
      // Register write-back (excluding x0)
      if (rd != 0) begin
        case (opcode)
          7'b0110111,  // LUI
          7'b0010111,  // AUIPC
          7'b1101111,  // JAL
          7'b1100111,  // JALR
          7'b0010011,  // OP-IMM
          7'b0110011,  // OP
          7'b0000011: begin  // Load
            rf[rd] <= wb_data;
            $display("[RV32IM] Write x%0d = 0x%08h", rd, wb_data);
          end
          default: ; // No write for other instructions
        endcase
      end
      
      // PC update
      if (pc_update) begin
        pc <= next_pc;
        $display("[RV32IM] Branch/Jump to PC = 0x%08h", next_pc);
      end else begin
        pc <= pc + 4;
      end
      
      // Diff-test
      difftest_step(pc);
    end
  end

  // ==================== M Extension (Multiply/Divide) ====================
  // Note: M extension will be implemented in the next phase
  // For now, we'll leave it as a placeholder

  /* verilator lint_on UNUSEDSIGNAL */
endmodule
