

module decoder (
  input  logic [31:0]  fetched_instr_i,
  output logic [1:0]   a_sel_o,
  output logic [2:0]   b_sel_o,
  output logic [4:0]   alu_op_o,
  output logic [2:0]   csr_op_o,
  output logic         csr_we_o,
  output logic         mem_req_o,
  output logic         mem_we_o,
  output logic [2:0]   mem_size_o,
  output logic         gpr_we_o,
  output logic [1:0]   wb_sel_o,
  output logic         illegal_instr_o,
  output logic         branch_o,
  output logic         jal_o,
  output logic         jalr_o,
  output logic         mret_o
);

  import decoder_pkg::*;
  import alu_opcodes_pkg::*;
  import csr_pkg::*;

  wire [31:0] INSTR;
  wire [1:0]  RR;
  wire [4:0]  opcode;
  wire [2:0]  func3;
  wire [6:0]  func7;
  wire [11:0] imm12;
  wire [19:0] imm20;

  assign INSTR = fetched_instr_i;
  assign RR     = fetched_instr_i[1:0];
  assign opcode = fetched_instr_i[6:2];
  assign func3  = fetched_instr_i[14:12];
  assign func7  = fetched_instr_i[31:25];

  always_comb begin
    // Default values
    a_sel_o         = '0;
    b_sel_o         = '0;
    alu_op_o        = '0;
    csr_op_o        = '0;
    csr_we_o        = '0;
    mem_req_o       = '0;
    mem_we_o        = '0;
    mem_size_o      = '0;
    wb_sel_o        = '0;
    gpr_we_o        = '0;
    branch_o        = '0;
    jal_o           = '0;
    jalr_o          = '0;
    mret_o          = '0;
    illegal_instr_o = '0;

    case (RR)
      2'b11: begin // Only support 32-bit instructions (lower 2 bits = 11)
        case (opcode)
          LOAD_OPCODE: begin
            mem_req_o = 1;
            gpr_we_o  = 1;
            alu_op_o = ALU_ADD;
            a_sel_o = 2'b01; // RS1
            b_sel_o = 3'b001; // I-immediate
            wb_sel_o = 2'b01; // Memory
            case(func3)
              3'b000: mem_size_o = LDST_B;  // LB
              3'b001: mem_size_o = LDST_H;  // LH
              3'b010: mem_size_o = LDST_W;  // LW
              3'b100: mem_size_o = LDST_BU; // LBU
              3'b101: mem_size_o = LDST_HU; // LHU
              default: illegal_instr_o = 1;
            endcase
          end

          STORE_OPCODE: begin
            mem_req_o = 1;
            mem_we_o  = 1;
            alu_op_o = ALU_ADD;
            a_sel_o = 2'b01; // RS1
            b_sel_o = 3'b011; // S-immediate
            case(func3)
              3'b000: mem_size_o = LDST_B; // SB
              3'b001: mem_size_o = LDST_H; // SH
              3'b010: mem_size_o = LDST_W; // SW
              default: illegal_instr_o = 1;
            endcase
          end

          BRANCH_OPCODE: begin
            branch_o = 1;
            a_sel_o = 2'b01; // RS1
            b_sel_o = 3'b011; // B-immediate
            case(func3)
              3'b000: alu_op_o = ALU_EQ;  // BEQ
              3'b001: alu_op_o = ALU_NE;  // BNE
              3'b100: alu_op_o = ALU_LTS; // BLT
              3'b101: alu_op_o = ALU_GES; // BGE
              3'b110: alu_op_o = ALU_LTU; // BLTU
              3'b111: alu_op_o = ALU_GEU; // BGEU
              default: illegal_instr_o = 1;
            endcase
          end

          JAL_OPCODE: begin
            jal_o = 1;
            gpr_we_o = 1;
            a_sel_o = 2'b10; // PC
            b_sel_o = 3'b100; // J-immediate
            alu_op_o = ALU_ADD;
            wb_sel_o = 2'b10; // PC+4
          end

          JALR_OPCODE: begin
            if (func3 == 3'b000) begin
              jalr_o = 1;
              gpr_we_o = 1;
              a_sel_o = 2'b01; // RS1
              b_sel_o = 3'b001; // I-immediate
              alu_op_o = ALU_ADD;
              wb_sel_o = 2'b10; // PC+4
            end else begin
              illegal_instr_o = 1;
            end
          end

          OP_IMM_OPCODE: begin
            gpr_we_o = 1;
            a_sel_o = 2'b01; // RS1
            b_sel_o = 3'b001; // I-immediate
            case(func3)
              3'b000: alu_op_o = ALU_ADD;  // ADDI
              3'b010: alu_op_o = ALU_SLTS; // SLTI
              3'b011: alu_op_o = ALU_SLTU; // SLTIU
              3'b100: alu_op_o = ALU_XOR;  // XORI
              3'b110: alu_op_o = ALU_OR;   // ORI
              3'b111: alu_op_o = ALU_AND;  // ANDI
              3'b001: alu_op_o = ALU_SLL;  // SLLI
              3'b101: begin
                if (func7[5] == 1'b0)
                  alu_op_o = ALU_SRL;  // SRLI
                else
                  alu_op_o = ALU_SRA;  // SRAI
              end
              default: illegal_instr_o = 1;
            endcase
          end

          OP_OPCODE: begin
            gpr_we_o = 1;
            a_sel_o = 2'b01; // RS1
            b_sel_o = 3'b000; // RS2
            case(func3)
              3'b000: begin
                if (func7[5] == 1'b0)
                  alu_op_o = ALU_ADD;  // ADD
                else
                  alu_op_o = ALU_SUB;  // SUB
              end
              3'b001: alu_op_o = ALU_SLL;  // SLL
              3'b010: alu_op_o = ALU_SLTS; // SLT
              3'b011: alu_op_o = ALU_SLTU; // SLTU
              3'b100: alu_op_o = ALU_XOR;  // XOR
              3'b101: begin
                if (func7[5] == 1'b0)
                  alu_op_o = ALU_SRL;  // SRL
                else
                  alu_op_o = ALU_SRA;  // SRA
              end
              3'b110: alu_op_o = ALU_OR;   // OR
              3'b111: alu_op_o = ALU_AND;  // AND
              default: illegal_instr_o = 1;
            endcase
          end

          LUI_OPCODE: begin
            gpr_we_o = 1;
            a_sel_o = 2'b10; // Zero
            b_sel_o = 3'b010; // U-immediate
            alu_op_o = ALU_ADD;
            wb_sel_o = 2'b00; // ALU result
          end

          AUIPC_OPCODE: begin
            gpr_we_o = 1;
            a_sel_o = 2'b01; // PC
            b_sel_o = 3'b010; // U-immediate
            alu_op_o = ALU_ADD;
            wb_sel_o = 2'b00; // ALU result
          end

          MISC_MEM_OPCODE: begin
            if (func3 == 3'b000) begin
              // FENCE instruction - treated as NOP in basic implementation
            end else begin
              illegal_instr_o = 1;
            end
          end

          SYSTEM_OPCODE: begin
            if (func3 == 3'b000) begin
              if (fetched_instr_i[31:20] == 12'h302) begin
                mret_o = 1; // MRET
              end else if (fetched_instr_i[31:20] == 12'h000) begin
                // ECALL - not implemented in basic version
                illegal_instr_o = 1;
              end else if (fetched_instr_i[31:20] == 12'h001) begin
                // EBREAK - not implemented in basic version
                illegal_instr_o = 1;
              end else begin
                illegal_instr_o = 1;
              end
            end else begin
              // CSR instructions - not implemented in basic version
              illegal_instr_o = 1;
            end
          end

          default: begin
            illegal_instr_o = 1;
          end
        endcase
      end
      default: begin
        illegal_instr_o = 1; // Not a 32-bit instruction
      end
    endcase
  end
endmodule