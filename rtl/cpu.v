// RISC CODE GOES HERE

module cpu #(
    parameter WIDTH = 32,
)(
  input clk, rst,
);
  wire [WIDTH-1:0] rs1, rs2, alu_out, dmem_out;
  wire pc_sel, b_sel, dmem_we, wb_sel, reg_we;
  wire [15:0] pc, sp_count, sp_next;
  wire [3:0] ccr, alu_cc;

  // PC, Stack Pointer, CCR Registers
  REGISTER_R #(.N(16)) pc_reg (
    .q(pc), 
    .d((pc_sel)? pc+(inst[31:20]<<2) : pc+4), 
    .rst(rst), 
    .clk(clk));
  REGISTER_R #(.N(16)) sp_count_reg (
    .q(sp_count), 
    .d(sp_next), 
    .rst(rst), 
    .ce(ce), 
    .clk(clk));
  REGISTER_R #(.N(4)) ccr_reg (
    .q(ccr), 
    .d(alu_cc), 
    .rst(rst), 
    .clk(clk));

  // IMEM
  imem im (.addr(pc), .inst(inst));

  // REGFILE
  regfile #(.DEPTH(16)) rf (
    .waddr(inst[11:8]), 
    .raddr1(inst[15:12]), 
    .raddr2(inst[19:16]),
    .rd((wb_sel)? dmem_out : alu_out),
    .rs1(rs1),
    .rs2(rs2),
    .we(reg_we), 
    .clk(clk), 
    .rst(rst));

  // ALU
  alu alu_inst (
    .a(rs1), 
    .b((bsel)? inst[31:20] : rs2), 
    .alu_out(alu_out),
    .alu_op(inst[7:0]),  
    .alu_cc(alu_cc));

  // DMEM
  dmem dm (
    .clk(clk), 
    .we(dmem_we), 
    .addr(alu_out), 
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
    .reg_we(reg_we));

endmodule
