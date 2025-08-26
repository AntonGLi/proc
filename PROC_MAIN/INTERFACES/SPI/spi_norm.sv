module spi_norm
#(parameter DIV_FREQ_BY = 8) // CLK over SCK 
                                //(for values less than 2 unsafe behavior expected)
(
input logic clk,
input logic rst,

input logic [7:0]  data,
input logic        load_data, //and start sending

input logic        miso,
output logic       mosi,
output logic       cs,
output logic       sck,

output logic       busy,
output logic [7:0] received_data
);

localparam DIV_FREQ_WIDTH = $clog2(DIV_FREQ_BY); //width of frequency divider

enum logic
  {
    READY_FSM         = 1'b0,
    TRANSMIT_DATA_FSM = 1'b1
  }
state, next_state;

logic [7:0] shreg; //shift register for data
logic [7:0] shreg_next;

logic [3:0] bit_cntr;
logic [3:0] bit_cntr_next;

logic [DIV_FREQ_WIDTH-1:0] clk_to_sck_cntr;

logic sck_next;
logic [7:0] received_data_next;

wire  [DIV_FREQ_WIDTH-1:0] rst_clk_cntr_val = '0;

wire  [DIV_FREQ_WIDTH-1:0] end_clk_cntr_val = '1;

//frequency divider
always_ff @(posedge clk) begin
  if (rst)
    clk_to_sck_cntr <= rst_clk_cntr_val;
  else
    if (clk_to_sck_cntr == end_clk_cntr_val || state == READY_FSM)
      clk_to_sck_cntr <= rst_clk_cntr_val;
    else
      clk_to_sck_cntr <= clk_to_sck_cntr + 1;
end

assign sck           = clk_to_sck_cntr[DIV_FREQ_WIDTH-1];
assign mosi          = shreg[7];

always_comb
begin
  next_state  = state;
  
  received_data_next = received_data;

  case(state)
    READY_FSM:
    begin
      busy          = 0;
      cs            = 1;
      bit_cntr_next = 4'b0;
      if (load_data)
      begin
        busy = 1;
        shreg_next = data;
        next_state = TRANSMIT_DATA_FSM;
      end
      else
        shreg_next  = '0;
    end
    TRANSMIT_DATA_FSM:
      begin
        cs            = 0;
        busy          = 1;
        bit_cntr_next = bit_cntr + 4'b1;
        shreg_next    = {shreg[6:0], miso};
        if (bit_cntr == 4'b0111 && (clk_to_sck_cntr == end_clk_cntr_val))
        begin
          next_state = READY_FSM;
          received_data_next = shreg;
        end
      end
  endcase
end
    
always_ff @(posedge clk)
    if (rst)
        state <= READY_FSM;
    else
        state <= next_state;

always_ff @(posedge clk)
    if (rst)
        shreg <= '0;
    else
    if ((clk_to_sck_cntr == end_clk_cntr_val) || (state == READY_FSM))
        shreg <= shreg_next;

always_ff @(posedge clk)
  if (rst)
    bit_cntr <= 4'b0;
  else
    if ((clk_to_sck_cntr == end_clk_cntr_val) || (state == READY_FSM))
      bit_cntr <= bit_cntr_next;


always_ff @(posedge clk)
    if (rst)
        received_data <= '0;
    else
        received_data <= received_data_next;

endmodule

