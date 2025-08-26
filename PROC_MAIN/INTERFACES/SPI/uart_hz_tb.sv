module uart_hz_tb;

reg clk;
reg rst;

reg [7:0]  data;
reg        load_data; //and start sending

reg        miso;
wire       mosi;
wire       cs;
wire       sck;

wire       busy;
wire [7:0] received_data;

spi_norm spi
(
.clk(clk),
.rst(rst),

.data(data),
.load_data(load_data),

.miso(miso),
.mosi(mosi),

.cs(cs),
.sck(sck),

.busy(busy),
.received_data(received_data)
);


initial begin
  miso = 0;
  #50 rst = 0;
  #50 rst = 1;
  #75 rst = 0;
  @(posedge clk) data = 8'd31;
  load_data = 1;
  #150
  load_data = 0;
  @(~busy)
  data = 8'b01011100;
  load_data = 1;
  @(posedge clk)
  @(posedge clk) load_data = 0;
  @(~busy)
  @(posedge clk)
  @(posedge clk)
  $finish;
end

initial begin
  forever begin
    #50 clk = 1;
    #50 clk = 0;
  end
end



endmodule