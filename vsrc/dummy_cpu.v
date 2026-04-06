module dummy_cpu(
  input clk
);

  import "DPI-C" context function int paddr_read(input int addr, input int len);
  import "DPI-C" context function void difftest_step(input int dut_pc);

  reg [31:0] pc;
  initial pc = 32'h80000000;

  wire [31:0] inst = paddr_read(pc, 4);

  always @(posedge clk) begin
    $display("[Verilog] PC = 0x%h, Inst = 0x%h", pc, inst);
    difftest_step(pc);
    pc <= pc + 4;
  end

endmodule
