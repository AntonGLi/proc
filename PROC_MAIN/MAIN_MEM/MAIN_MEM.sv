

module MAIN_MEM 
(
input  logic        clk,
input  logic [31:0] address,
input  logic        request,
input  logic        write,
input  logic [31:0] write_data,
output logic [31:0] async_read_data,
output logic [31:0] sync_read_data
);

localparam v = 256;

logic [31:0] meme [v-1:0];

always_ff @(posedge clk) begin
  if (request) begin
    if (write) begin
      meme[address-1] <= write_data;
    end 
    else begin
      sync_read_data <= meme[address-1];
    end
  end
end
assign async_read_data = meme[address-1];
endmodule

