module proc(
input  logic clk,
input  logic rst,
output logic [31:0] dmem_addr_o
);

logic [31:0] dmem_rd;
logic [31:0] dmem_wd;
logic [31:0] dmem_addr;
logic [04:0] dmem_memi;
logic        dmem_we;

assign dmem_addr_o = ~dmem_addr;

logic [31:0] cmem_addr;
logic [31:0] cmem_instr;

core core1(
.clk_i         (clk),
.rst_i         (rst),

.instr_i       (cmem_instr),
.instr_addr_o  (cmem_addr),

.mem_rd_i      (dmem_rd),
.mem_wd_o      (dmem_wd),
.mem_addr_o    (dmem_addr),
.memi_o        (dmem_memi),
.mem_we_o      (dmem_we)

);

command_memory meme_c(
.upr           (cmem_addr),
.out           (cmem_instr)
);

data_mem meme_d(
.clk           (clk),

.memi          (dmem_memi),
.data          (dmem_wd),
.upr_in        (dmem_addr),
.out           (dmem_rd),
.WrEn          (dmem_we)
);
endmodule


