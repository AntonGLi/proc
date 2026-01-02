module tb #(parameter T=10);

wire [31:0] a = 32'b01000001011100000000000000000000;
wire [31:0] b = 32'b01000000010000000000000000000000;

logic [31:0] c;
logic busy;
logic res_vld;

logic clk;
logic rst;

fp_div DUT (
  .clk(clk),
  .rst(rst),

  .arg_vld('1),
  .busy(busy),
  .res_vld(res_vld),

  .a(a),
  .b(b),
  .c(c)
);

initial begin
  $dumpvars;
          rst = 0;
  #200  rst = 1;
  #200  rst = 0;
  @(negedge busy)
  $finish;
end

initial begin
  clk = 0;
  forever begin
    #50 clk = ~clk;
  end
end

endmodule