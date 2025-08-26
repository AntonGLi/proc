module spi_driver_simple(
input CLK,
input RESET,

input wire [3:0] KEY,
output reg [3:0] LED,

output dc, //A0

output mosi,
output cs,
output sck,
input miso,
output reset_display


);

localparam CNT_CLK      = 50000000;
localparam NUM_COMMANDS = 5;
localparam NUM_DATA     = 5;


reg [7:0] ROM [0:30];
reg [31:0] cnt;
reg [7:0] adr_rom;
reg cnt_end;
wire [7:0] data;
wire busy;
wire [7:0] received_data;


assign reset_display = RESET;
assign data = ROM[adr_rom];
assign dc = 1;

initial begin
	$readmemh("bytes.txt", ROM);
end

//fsm

enum logic [2:0] {
	IDLE           = 3'b000,
	COUNT_1S_1     = 3'b001,
	SEND_COMMANDS  = 3'b010,
	COUNT_1S_2     = 3'b011,
	SEND_DATA      = 3'b100
	} state, next_state;

//control signals

reg cnt_en;
reg spi_rst;
reg load_data;
reg adr_incr;


always_comb begin
	next_state = state;
	
	cnt_en    = 0;
	load_data = 0;
	adr_incr  = 0;

	case (state)
		IDLE: begin
			if (~KEY[0]) 
				next_state = COUNT_1S_1;
		end
		COUNT_1S_1: begin
			cnt_en = 1;
			if (cnt_end) begin
				next_state = SEND_COMMANDS;
			end
		end
		SEND_COMMANDS: begin
			if (~busy) begin
				load_data = 1;
				adr_incr  = 1;
			end
			if (adr_rom == NUM_COMMANDS) begin
				next_state = COUNT_1S_2;
			end
		end
		COUNT_1S_2: begin
			cnt_en = 1;
			if (cnt_end) begin
				next_state = SEND_DATA;
			end
		end
		SEND_DATA: begin
			if (~busy) begin
				load_data = 1;
				adr_incr  = 1;
			end else begin
				if (adr_rom == (NUM_COMMANDS + NUM_DATA)) begin
					next_state = IDLE;
				end
			end
		end
	endcase
end

always_ff @(posedge CLK) begin
	if (~RESET) begin
		state <= IDLE;
	end else begin
		state <= next_state;
	end
end

//cntr

always_ff @(posedge CLK) begin
	if (~RESET) begin
		cnt <= '0;
	end else begin
		if (cnt_en == 1) begin

			if (cnt == CNT_CLK) begin
				cnt <= '0;
			end else begin
				cnt <= cnt + 1;
			end

		end else begin
			cnt <= cnt;
		end
	end
end

always_ff @(posedge CLK) begin
	if (~RESET) begin
		cnt_end <= 0;
	end else begin
		if (cnt_en == 1) begin
			if (cnt == CNT_CLK) begin
				cnt_end <= 1;
			end else begin
				cnt_end <= 0;
			end
		end else begin
			cnt_end <= cnt_end;
		end
	end
end

//rom address incrementor

always_ff @(posedge CLK) begin
	if (~RESET) begin
		adr_rom <= '0;
	end else begin

		if (adr_incr) begin
			adr_rom <= adr_rom + 1;
		end else begin

			if (state == IDLE) begin
				adr_rom <= '0;
			end else begin
				adr_rom <= adr_rom;
			end

		end

	end
end

//to show if cntr works

assign LED[0] = (state == COUNT_1S_1);
assign LED[1] = (state == SEND_COMMANDS);
assign LED[2] = (state == COUNT_1S_2);
assign LED[3] = (state == SEND_DATA);

//spi module

spi_norm
#(.DIV_FREQ_BY(50000000)) // CLK over SCK 
spi_ent (
.clk(CLK),
.rst(~RESET),

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

