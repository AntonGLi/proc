module mux32x5 (
input  logic [31:0] in0,
input  logic [31:0] in1,
input  logic [31:0] in2,
input  logic [31:0] in3,
input  logic [31:0] in4,
input  logic [02:0] sel,
output logic [31:0] out
);
always_comb begin
  case(sel)
    3'd0: out = in0;
    3'd1: out = in1;
    3'd2: out = in2;
    3'd3: out = in3;
    3'd4: out = in4;
    default: out = '0;
  endcase
end
endmodule

