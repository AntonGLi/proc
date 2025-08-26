module proc_tb;
logic clk;
logic rst;

proc proc1(
.clk(clk),
.rst(rst)
);

initial begin
  $dumpfile("wave_mul.vcd");
  $dumpvars(0, proc_tb);
  #50 rst = 0;
  #50 rst = 1;
  #75 rst = 0;
  #30000
  $finish;
end

initial begin
  forever begin
    #50 clk = 1;
    #50 clk = 0;
  end
end

endmodule
