module dummy_cpu(
  input clk
);

  import "DPI-C" context function void nemu_step();

  always @(posedge clk) begin
    $display("[Verilog] Clock posedge triggered!");
    nemu_step();
  end

endmodule
