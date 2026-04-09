module dummy_cpu(
  input clk
);

  import "DPI-C" context function int paddr_read(input int addr, input int len);
  import "DPI-C" context function void difftest_step(input int dut_pc);

  reg [31:0] pc;
  reg [31:0] rf [31:0];

  initial begin
    pc = 32'h80000000;
    for (int i = 0; i < 32; i = i + 1) rf[i] = 0;
  end

  // Instruction Fetch
  wire [31:0] inst = paddr_read(pc, 4);

  // Decode
  wire [6:0] opcode = inst[6:0];
  wire [4:0] rd     = inst[11:7];
  wire [4:0] rs1    = inst[19:15];
  wire [4:0] rs2    = inst[24:20];
  wire [2:0] funct3 = inst[14:12];

  // Immediates
  wire [31:0] imm_i = {{20{inst[31]}}, inst[31:20]};
  wire [31:0] imm_b = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
  wire [31:0] imm_j = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

  // Branch Logic (Simple comparison)
  reg branch_taken;
  always @(*) begin
    case (funct3)
      3'b000: branch_taken = (rf[rs1] == rf[rs2]); // BEQ
      3'b001: branch_taken = (rf[rs1] != rf[rs2]); // BNE
      default: branch_taken = 0;
    endcase
  end

  // Next PC Logic
  reg [31:0] next_pc;
  always @(*) begin
    if (opcode == 7'h6f)      next_pc = pc + imm_j;           // JAL
    else if (opcode == 7'h67) next_pc = (rf[rs1] + imm_i) & ~32'h1; // JALR
    else if (opcode == 7'h63 && branch_taken) next_pc = pc + imm_b; // Branch
    else                      next_pc = pc + 4;               // Default
  end

  always @(posedge clk) begin
    $display("[Verilog] PC = 0x%h, Inst = 0x%h", pc, inst);
    
    // Register Write-back for JAL/JALR
    if ((opcode == 7'h6f || opcode == 7'h67) && rd != 0) begin
      rf[rd] <= pc + 4;
    end

    // Diff-Test and PC update
    difftest_step(pc);
    pc <= next_pc;
  end

endmodule
