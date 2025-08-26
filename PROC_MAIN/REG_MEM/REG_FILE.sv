module REG_FILE (
input clk,

  //write signals
input WE,             //enable
input [4:0] WA,       //address
input [31:0] WD,      //data

  //read signals
input [4:0] RA1,      //address 1
input [4:0] RA2,      //address 2

output [31:0] RD1,    //data 1
output [31:0] RD2     //data 2
);

logic [31:0] register [0:31];

always @(posedge clk) begin
  if (WE)
    register[WA] <= WD;
end

assign RD1 = (RA1 == 5'b0) ? 32'b0 : register[RA1];
assign RD2 = (RA2 == 5'b0) ? 32'b0 : register[RA2];

endmodule
