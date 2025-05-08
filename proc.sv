module core (
input logic clk
);

//decoding instruction
wire [31:0] fetched_instr;

  //defining constants
wire [11:0] cI;
wire [11:0] cS;
wire [12:0] cB;
wire [20:0] cJ;
wire [31:0] cU;

assign cI = fetched_instr[31:20];
assign cS = fetched_instr[31:25];
assign cB = fetched_instr[31], fetched_instr[7], fetched_instr[30:25], fetched_instr[11:8];
assign cJ = fetched_instr[:20];
assign cU = fetched_instr[31:20];


//reg file ports and connect
wire [4:0]  RA1; 
wire [4:0]  RA2; 
wire [4:0]  WA; 
wire        WE; 
wire [31:0] WDATA; 
wire [31:0] RD1; 
wire [31:0] RD2;

Register_file mem1 (
  .clk(clk),

  .WrEn(WE),
  .upr_in(WA),
  .in(WDATA),

  .upr_A(RA1),
  .upr_B(RA2),

  .A(RD1),
  .B(RD2)
);

//alu
wire [31:0] a, 
wire [31:0] b, 
wire [31:0] result, 
wire [4:0] oper, 
wire flag;

ALU alu (
  .A(a),
  .B(b),
  .Upr_ALU(oper),
  .C(flag)
);




//datapath





endmodule

