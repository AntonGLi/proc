module mux2 (
input logic  [31:0] a_1,
input logic  [31:0] b_0,
input logic         sel,
output logic [31:0] c
);
assign c = sel ? a_1:b_0;
endmodule
