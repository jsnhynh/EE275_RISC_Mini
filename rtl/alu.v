`timescale 1ns/1ps
`include "opcodes.vh"

module alu (
  input  [31:0] a, b,
  input  [6:0]  opcode,
  output reg [31:0] alu_out,
  output reg [3:0]  alu_cc // [Reserve, Underflow, Overflow, Branch True]
);

  wire [31:0] add_res, sub_res;
  wire        add_cout, sub_cout;

  cla32 add_inst (.a(a), .b(b),  .cin(1'b0), .sum(add_res), .cout(add_cout));
  cla32 sub_inst (.a(a), .b(~b), .cin(1'b1), .sum(sub_res), .cout(sub_cout));

  wire sub_zero     = (sub_res == 32'd0);
  wire sub_negative =  sub_res[31];

  wire sa      = a[31];
  wire sb      = b[31];
  wire ss_add  = add_res[31];
  wire ss_sub  = sub_res[31];

  wire add_pos_ovf = (~sa) & (~sb) & ss_add;
  wire add_neg_ovf = sa & sb & (~ss_add);

  wire sub_pos_ovf = (~sa) &  sb  &  ss_sub;
  wire sub_neg_ovf =  sa & (~sb) & (~ss_sub);

  wire sub_overflow = sub_pos_ovf | sub_neg_ovf;

  always @* begin
    if ((opcode[2:0] == `R_TYPE) | (opcode[2:0] == `I_TYPE) | (opcode[2:0] == `B_TYPE)) begin
      alu_out = 32'd0;
      alu_cc  = 4'b0000;

      case (opcode[6:3])
        // Arithmetic
        `ADD: begin
          alu_out   = add_res;
          alu_cc[1] = add_pos_ovf;
          alu_cc[2] = add_neg_ovf;
        end

        `SUB: begin
          alu_out   = sub_res;
          alu_cc[1] = sub_pos_ovf;
          alu_cc[2] = sub_neg_ovf;
        end

        `MULT:  alu_out = a * b;
        // Logic
        `AND:   alu_out = a & b;
        `OR:    alu_out = a | b;
        `XOR:   alu_out = a ^ b;
        `NOT:   alu_out = ~a;

        // Comparisons / Branch
        `BEQ:   alu_cc[0] =  sub_zero;
        `BNE:   alu_cc[0] = ~sub_zero;
        `BLT:   alu_cc[0] =  (sub_negative ^ sub_overflow);                 // N ^ V
        `BLE:   alu_cc[0] =  (sub_negative ^ sub_overflow) | sub_zero;      // (N^V) | Z
        `BGT:   alu_cc[0] = ~((sub_negative ^ sub_overflow) | sub_zero);    // ~(LT | Z)
        `BGE:   alu_cc[0] = ~(sub_negative ^ sub_overflow);                 // ~LT

        default: begin
          alu_out = 32'd0;
          alu_cc  = 4'b0000;
        end
      endcase

    end else begin
      alu_out   = add_res;
      alu_cc    = 4'b0000;
      alu_cc[0] = (opcode[2:0] == `J_TYPE);
      alu_cc[1] = add_pos_ovf;
      alu_cc[2] = add_neg_ovf;
    end
  end

endmodule
