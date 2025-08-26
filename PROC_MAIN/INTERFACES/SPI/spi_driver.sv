module spi_driver(
input CLK,
input RESET,

input  logic [3:0] KEY,
output logic [3:0] LED,

output logic dc, //A0
output logic mosi,
output logic cs,
output logic sck,
output logic reset_display


);

localparam DIV_FREQ_BY  = 3;
localparam NUM_BYTES    = 8;

logic rst;
assign rst = ~RESET;

wire [7:0] data;
wire [7:0] received_data;
wire busy;

reg load_data;

reg [7:0] ROM [0:30]; // | 1bit | 2bit | 3bit | 4bit | 5bit | 6bit | 7bit | 8bit |
reg    DC_ROM [0:30]; // |  dc  |
reg [7:0] num_byte;

initial begin
	$readmemh("bytes.txt", ROM);
	$readmemb("dc.txt", DC_ROM);
end

logic go_upper;
logic end_count;

//go upper enable logic

always_ff @(posedge CLK) begin
	if (rst)
		go_upper <= 0;
	else begin
		if ( ~KEY[0] & ~go_upper & ~end_count)
			go_upper <= 1;
		else if (end_count)
			go_upper <= 0;
	end
end

//byte counter and load data logic

always_ff @(posedge CLK) begin
	if (rst) begin
		num_byte <= 0;
		load_data <= 0;
	end
	else begin
		if (go_upper & ~busy) begin
			load_data <= 1;
			num_byte <= num_byte + 1;
		end
		else
			load_data <= 0;
	end
end

//end count logic

assign end_count = (num_byte == NUM_BYTES);

//----------------------------------------------------
//to show if cntr works

assign LED[0] = ~(busy);
assign LED[1] = ~(load_data);
assign LED[2] = ~(sck);
assign LED[3] = ~(go_upper);

//output signals logic

assign reset_display = RESET;
assign data =    ROM[num_byte];
assign dc   = DC_ROM[num_byte];

//spi module

wire miso = 0; //not used

spi_norm
#(.DIV_FREQ_BY(DIV_FREQ_BY)) // CLK over SCK 
spi_ent (
.clk(CLK),
.rst(rst),

.data(data),
.load_data(load_data), //and start sending

.miso(miso),
.mosi(mosi),
.cs(cs),
.sck(sck),

.busy(busy),
.received_data(received_data)
);

endmodule

