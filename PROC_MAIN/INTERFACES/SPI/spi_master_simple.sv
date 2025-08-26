module spi_master_simple (

input clk,
input spi_clk,
input rst,

input [7:0] data,
input       load_data, //and start sending

input       miso,
output      mosi,
output      cs,
output      sck,

output      busy

);

assign sck = spi_clk;

enum logic
    {
        READY   = 1'b0,
        SENDING = 1'b1
    }
state, next_state;

logic [7:0] shreg;
logic [7:0] shreg_next;

logic [2:0] cntr;
logic [2:0] cntr_next;

always_comb
begin
    next_state  = state;
    busy        = 0;
    mosi        = shreg[7];

    shreg_next  = '0;

    cs = 1;
    
    case(state)
        READY:
        begin
            cntr_next = 3'b111;

            if (load_data)
            begin
                shreg_next = data;
                next_state = SENDING;
            end
        end
        SENDING:
        begin
            cs         = 0;
            busy       = 1;
            shreg_next = {shreg[6:0], miso};
            cntr_next  = cntr - 3'b001;
            if (cntr == 0)
                next_state = READY;
        end
    endcase
end
    
always_ff @(posedge spi_clk)
    if (rst)
        state <= READY;
    else
        state <= next_state;

always_ff @(posedge spi_clk)
    if (rst)
        shreg <= '0;
    else
        shreg <= shreg_next;

always_ff @(posedge spi_clk)
    if (rst)
        cntr <= '0;
    else
        cntr <= cntr_next;
endmodule

