
`timescale 1 ps/1 ps
module spi_driver_simple_vlg_vec_tst();

reg CLK;
reg RESET;
reg miso;

wire [3:0] LED;
reg  [3:0] KEY;
wire cs;
wire dc;
wire mosi;
wire reset_display;
wire sck;

// module
spi_driver i1 (
	.CLK(CLK),
	.LED(LED),
	.RESET(RESET),
	.cs(cs),
	.dc(dc),
	.mosi(mosi),
	.reset_display(reset_display),
	.sck(sck),
	.KEY(KEY)
);
initial 
begin 
$dumpfile("dump.vcd");
$dumpvars;
#15000 $stop;
end 

// CLK
always
begin
#50	CLK = ~CLK;
end 

// RESET
initial
begin
	CLK = 0;
	RESET = 1'b0;
	KEY = '1;
	RESET = #75 1'b1;
	KEY = '0;
	#100 KEY = '1;
end

endmodule

