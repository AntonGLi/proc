module fp_div (
  input  logic clk,
  input  logic rst,

  input  logic arg_vld,
  output logic busy,
  output logic res_vld,
  
  input  logic [31:0] a,
  input  logic [31:0] b,
  output logic [31:0] c
);

//sign

logic sign_c;

assign sign_c = a[31] ^ b[31];

//power

logic [7:0] power_a;
logic [7:0] power_b;
logic [7:0] power_c;

assign power_a = a[30:23];
assign power_b = b[30:23];

assign power_c = power_a - power_b;

//divider 

logic [23:0] mantiss_a; // !! larger width for shift
logic [22:0] mantiss_b;
logic [22:0] mantiss_c;

logic [04:0] cnt_shift;

always_ff @(posedge clk) begin
  
  if (rst) begin
    mantiss_a <= '0;
    mantiss_b <= '0;
    mantiss_c <= '0;

    cnt_shift <= '0;

    busy <= '0;
    res_vld <= '0;
  end

  else begin
    
    if (arg_vld & ~busy) begin
      busy        <= '1;
      res_vld     <= '0;
      mantiss_a   <= {1'b0, a[22:0]};
      mantiss_b   <= b[22:0];
    end
    
    if (busy) begin
      
      cnt_shift <= cnt_shift + 5'd1;

      if (mantiss_a >= mantiss_b) begin
        mantiss_c <= mantiss_c | (23'd1 << (5'd22-cnt_shift));
        mantiss_a <= (mantiss_a - mantiss_b) << 1'b1;;
      end
      
      else begin
        
        mantiss_a <= (mantiss_a << 1);

        if (mantiss_a == '0) begin
          busy <= '0;
          res_vld <= '1;
        end
      
      end

    end

  end

end

endmodule