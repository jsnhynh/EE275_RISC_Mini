module alu (
  input  [31:0] a, b,
  input  [3:0]  alu_op,
  output reg [31:0] alu_out,
  output reg [3:0]  alu_cc // [Reserve, Underflow, Overflow, Branch True]
);

  wire [31:0] add_res, sub_res;
  wire        add_cout, sub_cout;

  // add / sub results
  cla32 add_inst (.a(a), .b(b),  .cin(1'b0), .sum(add_res), .cout(add_cout));
  cla32 sub_inst (.a(a), .b(~b), .cin(1'b1), .sum(sub_res), .cout(sub_cout));

  // flag
  wire sub_zero     = (sub_res == 32'd0);                       // Z
  wire sub_negative = sub_res[31];                              // N
  wire sub_overflow = (a[31] ^ b[31]) & (a[31] ^ sub_res[31]);  // V

  always @* begin
    alu_out = 32'd0;
    alu_cc  = 4'b0000;

    case (alu_op)
      // Arithmetic
      `ADD: begin
        alu_out    = add_res;
        // Overflow for addition (signed):
        alu_cc[1]  = ( a[31] &  b[31] & ~add_res[31]) |
                      (~a[31] & ~b[31] &  add_res[31]);
      end

      `SUB: begin
        alu_out    = sub_res;
        alu_cc[1]  = sub_overflow;
        alu_cc[2]  = ~sub_cout;
      end

      `MULT:  alu_out = a * b;

      // Logic
      `AND:   alu_out = a & b;
      `OR:    alu_out = a | b;
      `XOR:   alu_out = a ^ b;
      `NOT:   alu_out = ~a;

      // Comparisons (signed)
      `BEQ:   alu_cc[0] =  sub_zero;
      `BNE:   alu_cc[0] = ~sub_zero;
      `BLT:   alu_cc[0] =  (sub_negative ^ sub_overflow);               // N ^ V
      `BLE:   alu_cc[0] =  (sub_negative ^ sub_overflow) | sub_zero;    // (N^V) | Z
      `BGT:   alu_cc[0] = ~( (sub_negative ^ sub_overflow) | sub_zero );// ~(LT | Z)
      `BGE:   alu_cc[0] = ~(sub_negative ^ sub_overflow);               // ~LT

      default: begin
        alu_out = 32'd0;
        alu_cc  = 4'b0000;
      end
    endcase
  end
endmodule
