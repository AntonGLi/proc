module core (
input logic         clk_i,
input logic         rst_i,
input logic  [31:0] instr_i,
input logic  [31:0] mem_rd_i,
output logic [31:0] mem_wd_o,
output logic        mem_we_o,
output logic [31:0] mem_addr_o,
output logic [2:0]  mem_size_o,
output logic        mem_req_o,
output logic [31:0] instr_addr_o
);

assign mem_wd_o = rd2;
assign mem_addr_o = alu_res;


//instruction address (pc)
logic [31:0] pc;
logic [31:0] pc_next;
logic pc_en;

always_ff @(posedge clk_i) begin
  if (rst_i) begin
    pc = '0;
  end else begin
    if (pc_en) begin
      pc = pc_next;
    end
  end
end

assign instr_addr_o = pc;

//decoding instruction
logic [31:0] fetched_instr;

assign fetched_instr = instr_i;

  //defining constants
logic [11:0] cI;
logic [11:0] cS;
logic [12:0] cB;
logic [20:0] cJ;
logic [19:0] cU;

logic [31:0] I;
logic [31:0] S;
logic [31:0] B;
logic [31:0] J;
logic [31:0] U;

  //from instr
assign cI =   fetched_instr[31:20];
assign cS = {
              fetched_instr[31:25], 
              fetched_instr[11:7]
            };
assign cB = {
              fetched_instr[31], 
              fetched_instr[7], 
              fetched_instr[30:25], 
              fetched_instr[11:8], 
              1'b0
            };
assign cJ = {
              fetched_instr[31], 
              fetched_instr[19:12], 
              fetched_instr[20], 
              fetched_instr[30:21], 
              1'b0
            };
assign cU =   fetched_instr[31:12];

  //to 32 bit
assign  I = {{20{cI[11]}}, cI};
assign  S = {{20{cS[11]}}, cS};
assign  B = {{19{cB[12]}}, cB};
assign  J = {{11{cJ[20]}}, cJ};
assign  U = {cU, 12'b0};

//control signals
logic [1:0]   a_sel;
logic [2:0]   b_sel;
logic [4:0]   alu_oper;
logic [2:0]   csr_oper;
logic         csr_we;
logic         mem_req;
logic         mem_we;
logic [2:0]   mem_size;
logic         gpr_we;
logic [1:0]   wb_sel;
logic         illegal_instr;
logic         branch;
logic         jal;
logic         jalr;
logic         mret;

assign mem_we_o   = mem_we;
assign mem_size_o = mem_size;
assign mem_req_o  = mem_req;
assign pc_en = illegal_instr;

//decoder
decoder dc1 (
.fetched_instr_i  (fetched_instr),
.a_sel_o          (a_sel),
.b_sel_o          (b_sel),
.alu_op_o         (alu_oper),
.csr_op_o         (csr_oper),
.csr_we_o         (csr_we),
.mem_req_o        (mem_req),
.mem_we_o         (mem_we),
.mem_size_o       (mem_size),
.gpr_we_o         (gpr_we),
.wb_sel_o         (wb_sel),
.illegal_instr_o  (illegal_instr),
.branch_o         (branch),
.jal_o            (jal),
.jalr_o           (jalr),
.mret_o           (mret)
);

//reg file ports and connect
logic [4:0]   ra1; 
logic [4:0]   ra2; 
logic [4:0]   wa; 
logic         we; 
logic [31:0]  wdata; 
logic [31:0]  rd1; 
logic [31:0]  rd2;

always_comb begin
  we  = gpr_we;
  ra1 = fetched_instr[19:15];
  ra2 = fetched_instr[24:20];
  wa  = fetched_instr[11:7];
  case (wb_sel)
    2'd0: wdata = alu_res;
    2'd1: wdata = mem_rd_i;
    default: wdata = '0;
  endcase
end

REG_FILE meme1 (
  .clk(clk_i),

  .WE(we),
  .WA(wa),
  .WD(wdata),

  .RA1(ra1),
  .RA2(ra2),

  .RD1(rd1),
  .RD2(rd2)
);

//alu
logic [31:0] alu_a;
logic [31:0] alu_b;
logic [31:0] alu_res;
logic        flag;

always_comb begin
  case (a_sel)
    2'd0:     alu_a = rd1;
    2'd1:     alu_a = pc;
    2'd2:     alu_a = '0;
    default:  alu_a = '0;
  endcase
  case (b_sel)
    3'd0:     alu_b = rd2;
    3'd1:     alu_b = I;
    3'd2:     alu_b = U;
    3'd3:     alu_b = S;
    3'd4:     alu_b = 32'd4;
    default:  alu_b = 32'b0;
  endcase
end

ALU alu1 (
  .A(alu_a),
  .B(alu_b),
  .Upr_ALU(alu_oper),
  .C(flag),
  .Out_ALU(alu_res)
);

//pc logic
logic [31:0] I_addr;
logic [31:0] bj;
logic [31:0] bj4;
logic [31:0] bj4_addr;
logic        bj_sel;
logic        bj4_sel;

assign I_addr   = rd1 + I;
assign bj4_addr = bj4 + pc;

assign bj_sel   = branch;
assign bj4_sel  = jal | (flag & branch);

mux2 mux_bj (
.a_1(B),
.b_0(J),
.sel(bj_sel),
.c(bj)
);

mux2 mux_bj4 (
.a_1(bj),
.b_0(32'd4),
.sel(bj4_sel),
.c(bj4)
);

mux2 mux_pc_next (
.a_1(I_addr),
.b_0(bj4_addr),
.sel(jalr),
.c(pc_next)
);

endmodule

