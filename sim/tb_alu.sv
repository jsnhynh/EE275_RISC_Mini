`timescale 1ns/1ps
`include "opcodes.vh"

module alu_tb;
  // DUT signals
  reg  [31:0] a, b;
  reg  [6:0]  opcode;
  wire [31:0] alu_out;
  wire [3:0]  alu_cc;

  // Instantiate DUT
  alu dut (
    .a(a),
    .b(b),
    .opcode(opcode),
    .alu_out(alu_out),
    .alu_cc(alu_cc)
  );

  integer i, errors;

  // Golden model
  reg [31:0] expected_out;
  reg [3:0]  expected_cc;

  task check_result;
    input [255:0] opname;
    begin
      #1; 
      if (alu_out !== expected_out || alu_cc !== expected_cc) begin
        $display("ERROR %s: a=%0d b=%0d => got out=%0d cc=%b, expected out=%0d cc=%b",
                  opname, a, b, alu_out, alu_cc, expected_out, expected_cc);
        errors = errors + 1;
      end else begin
        $display("PASS %s: a=%0d b=%0d => got out=%0d cc=%b, expected out=%0d cc=%b",
                  opname, a, b, alu_out, alu_cc, expected_out, expected_cc);
      end
    end
  endtask

  initial begin
    errors = 0;
    $display("=== Randomized ALU Testbench Start ===");

    for (i=0; i<1; i=i+1) begin
      a = $random;
      b = $random;
      $display("--- Trial %0d: a=%0d b=%0d ---", i, a, b);

      // ---------- Arithmetic ----------
      // ADD
      opcode = {`ADD, `R_TYPE};
      expected_out = a + b;
      expected_cc  = 4'b0000;
      expected_cc[1] = ( a[31] &  b[31] & ~expected_out[31]) |
                       (~a[31] & ~b[31] &  expected_out[31]);
      check_result("ADD");

      // SUB
      opcode = {`SUB, `R_TYPE};
      expected_out = a - b;
      expected_cc  = 4'b0000;
      expected_cc[1] = (a[31] ^ b[31]) & (a[31] ^ expected_out[31]);
      expected_cc[2] = (a < b); // underflow/borrow
      check_result("SUB");

      // MULT
      opcode = {`MULT, `R_TYPE};
      expected_out = a * b;
      expected_cc  = 4'b0000;
      check_result("MULT");

      // ---------- Logic ----------
      // AND
      opcode = {`AND, `R_TYPE};
      expected_out = a & b;
      expected_cc  = 4'b0000;
      check_result("AND");

      // OR
      opcode = {`OR, `R_TYPE};
      expected_out = a | b;
      expected_cc  = 4'b0000;
      check_result("OR");

      // XOR
      opcode = {`XOR, `R_TYPE};
      expected_out = a ^ b;
      expected_cc  = 4'b0000;
      check_result("XOR");

      // NOT
      opcode = {`NOT, `R_TYPE};
      expected_out = ~a;
      expected_cc  = 4'b0000;
      check_result("NOT");

      // ---------- Branches ----------
      // BEQ
      opcode = {`BEQ, `B_TYPE};
      expected_out = 32'd0;
      expected_cc  = 4'b0000;
      expected_cc[0] = (a == b);
      check_result("BEQ");

      // BNE
      opcode = {`BNE, `B_TYPE};
      expected_out = 32'd0;
      expected_cc  = 4'b0000;
      expected_cc[0] = (a != b);
      check_result("BNE");

      // BLT (signed)
      opcode = {`BLT, `B_TYPE};
      expected_out = 32'd0;
      expected_cc  = 4'b0000;
      expected_cc[0] = ($signed(a) < $signed(b));
      check_result("BLT");

      // BLE (signed)
      opcode = {`BLE, `B_TYPE};
      expected_out = 32'd0;
      expected_cc  = 4'b0000;
      expected_cc[0] = ($signed(a) <= $signed(b));
      check_result("BLE");

      // BGT (signed)
      opcode = {`BGT, `B_TYPE};
      expected_out = 32'd0;
      expected_cc  = 4'b0000;
      expected_cc[0] = ($signed(a) > $signed(b));
      check_result("BGT");

      // BGE (signed)
      opcode = {`BGE, `B_TYPE};
      expected_out = 32'd0;
      expected_cc  = 4'b0000;
      expected_cc[0] = ($signed(a) >= $signed(b));
      check_result("BGE");
    end

    $display("=== Testbench Done, errors=%0d ===", errors);
    if (errors == 0)
      $display("All tests PASSED ✅");
    else
      $display("Some tests FAILED ❌");
    $finish;
  end
endmodule
