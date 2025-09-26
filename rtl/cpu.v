`timescale 1ns/1ps
`include "opcodes.vh"

module cpu #(
    parameter WIDTH = 32
)(
  input clk, rst
);
  wire [WIDTH-1:0] rs1, rs2, alu_out, imem_out, dmem_out, call_out, ret_out;
  reg [WIDTH-1:0] inst;
  wire pc_sel, b_sel, dmem_we, wb_sel, reg_we;
  wire [15:0] pc;
  wire [3:0] ccr, alu_cc;

  wire [7:0] sc;
  wire [1:0] state_mode, state_mode_next;

  // PC, Stack Pointer, CCR Registers
  REGISTER_R_CE #(.N(16)) pc_reg (
    .q(pc), 
    .d((pc_sel)? pc+{2'b00, inst[31:22], 2'b00} : pc+16'd4), 
    .rst(rst),
    .ce(state_mode == 'd0), 
    .clk(clk));
  REGISTER_R_CE #(.N(8)) sc_reg (
    .q(sc), 
    .d((sc >= 'd64)? 8'd0 : sc+8'd4), 
    .rst(rst), 
    .ce(state_mode != 'd0), 
    .clk(clk));
  REGISTER_R #(.N(2)) state_mode_reg (
    .q(state_mode),
    .d(state_mode_next),
    .rst(rst),
    .clk(clk));
  REGISTER_R #(.N(4)) ccr_reg (
    .q(ccr), 
    .d(alu_cc), 
    .rst(rst), 
    .clk(clk));

  // IMEM
  imem #(.ADDR_WIDTH(16), .INIT_FILE("program.hex")) im (.addr(pc), .inst(imem_out));
  imem #(.ADDR_WIDTH(8), .INIT_FILE("CALL.hex")) im_call (.addr(sc), .inst(call_out));
  imem #(.ADDR_WIDTH(8), .INIT_FILE("RET.hex")) im_ret (.addr(sc), .inst(ret_out));

  always @* begin
    inst = 'd0;
    case(state_mode)
      'd0: inst = imem_out;
      'd1: inst = call_out;
      'd2: inst = ret_out;
    endcase
  end

  // REGFILE
  regfile #(.DEPTH(32)) rf (
    .waddr(inst[11:7]), 
    .raddr1(inst[16:12]), 
    .raddr2(inst[21:17]),
    .rd((wb_sel)? dmem_out : alu_out),
    .rs1(rs1),
    .rs2(rs2),
    .we(reg_we), 
    .clk(clk), 
    .rst(rst));

  // ALU
  alu alu_inst (
    .a(rs1), 
    .b((b_sel)? {{22{inst[31]}}, inst[31:22]} : rs2), 
    .alu_out(alu_out),
    .opcode(inst[6:0]),
    .alu_cc(alu_cc));

  // DMEM
  dmem dm (
    .clk(clk), 
    .we(dmem_we), 
    .addr(alu_out[15:0]), 
    .wdata(rs2), 
    .rdata(dmem_out));

  // Control Logic
  control ctrl (
    .inst(inst),
    .ccr(alu_cc),
    .pc_sel(pc_sel),
    .b_sel(b_sel),
    .dmem_we(dmem_we),
    .wb_sel(wb_sel),
    .reg_we(reg_we),
    .sc(sc),
    .state_mode(state_mode),
    .state_mode_next(state_mode_next));

endmodule
