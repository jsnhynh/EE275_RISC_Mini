`timescale 1ns/1ps
`include "opcodes.vh"

module alu_tb;
  reg  [31:0] a, b;
  reg  [6:0]  opcode;
  wire [31:0] alu_out;
  wire [3:0]  alu_cc;

  alu dut (
    .a(a),
    .b(b),
    .opcode(opcode),
    .alu_out(alu_out),
    .alu_cc(alu_cc)
  );

  integer i, errors;

  reg [31:0] expected_out;
  reg [3:0]  expected_cc;

  task check_output;
    input [63:0] opname;
    begin
      #1;
      if (alu_out !== expected_out) begin
        $display("ERROR %-6s: a=%0d b=%0d => got out=%0d expected out=%0d",
                  opname, $signed(a), $signed(b), $signed(alu_out), $signed(expected_out));
        errors = errors + 1;
      end else begin
        $display("PASS %-6s: a=%0d b=%0d => got out=%0d expected out=%0d",
                  opname, $signed(a), $signed(b), $signed(alu_out), $signed(expected_out));
      end
    end
  endtask
  task check_cc;
    input [63:0] opname;
    begin
      #1;
      if (alu_cc[0] !== expected_cc[0]) begin
        $display("ERROR %-6s: a=%0d b=%0d => got cc=%b, expected cc=%b",
                  opname, $signed(a), $signed(b), alu_cc, expected_cc);
        errors = errors + 1;
      end else begin
        $display("PASS %-6s: a=%0d b=%0d => got cc=%b, expected cc=%b",
                  opname, $signed(a), $signed(b), alu_cc, expected_cc);
      end
    end
  endtask

  initial begin
    errors = 0;
    $display("---- Randomized ALU Test ----");

    for (i = 0; i < 10; i = i + 1) begin
      $display("-- Test Suite %0d ----", i);
      a = $random;
      b = $random;

      // Arithmetic
      opcode = {`ADD, `R_TYPE};
      expected_out   = a + b;
      check_output("ADD");
      opcode = {`SUB, `R_TYPE};
      expected_out   = a - b;
      check_output("SUB");
      opcode = {`MULT, `R_TYPE};
      expected_out = a * b;
      check_output("MULT");

      // Logic
      opcode = {`AND, `R_TYPE}; 
      expected_out = a & b; 
      check_output("AND");
      opcode = {`OR , `R_TYPE}; 
      expected_out = a | b; 
      check_output("OR");
      opcode = {`XOR, `R_TYPE}; 
      expected_out = a ^ b; 
      check_output("XOR");
      opcode = {`NOT, `R_TYPE}; 
      expected_out = ~a;    
      check_output("NOT");

      // Branches
      expected_cc = 4'b0000;
      opcode = {`BEQ, `B_TYPE}; 
      expected_cc[0] = (a == b);                       
      check_cc("BEQ");
      opcode = {`BNE, `B_TYPE};
      expected_cc[0] = (a != b);                       
      check_cc("BNE");
      opcode = {`BLT, `B_TYPE};
      expected_cc[0] = ($signed(a) <  $signed(b));     
      check_cc("BLT");
      opcode = {`BLE, `B_TYPE};
      expected_cc[0] = ($signed(a) <= $signed(b));     
      check_cc("BLE");
      opcode = {`BGT, `B_TYPE};
      expected_cc[0] = ($signed(a) >  $signed(b));    
      check_cc("BGT");
      opcode = {`BGE, `B_TYPE};
      expected_cc[0] = ($signed(a) >= $signed(b));     
      check_cc("BGE");
    end

    $display("---- Directed Overflow/Underflow Tests ----");
    expected_cc = 4'b0000;
    // ADD positive overflow: INT_MAX + 1 -> negative
    a = 32'h7fffffff; 
    b = 32'd1; 
    opcode = {`ADD, `R_TYPE};
    expected_cc[1] = (~a[31] & ~b[31] &  expected_out[31]); // Overflow
    expected_cc[2] = ( a[31] &  b[31] & ~expected_out[31]); // Underflow
    check_cc("ADD+OVF");

    // ADD negative overflow (underflow): INT_MIN + (-1) -> positive
    a = 32'h80000000; 
    b = -32'sd1; 
    opcode = {`ADD, `R_TYPE};
    expected_cc[1] = (~a[31] & ~b[31] &  expected_out[31]);
    expected_cc[2] = ( a[31] &  b[31] & ~expected_out[31]);
    check_cc("ADD-UNF");

    // SUB positive overflow: INT_MAX - (-1) -> negative
    a = 32'h7fffffff; 
    b = -32'sd1; 
    opcode = {`SUB, `R_TYPE};
    expected_cc[1] = (~a[31] &  b[31] &  expected_out[31]); // Overflow
    expected_cc[2] = ( a[31] & ~b[31] & ~expected_out[31]); // Underflow
    check_cc("SUB+OVF");

    // SUB negative overflow (underflow): INT_MIN - 1 -> positive
    a = 32'h80000000; 
    b = 32'd1; 
    opcode = {`SUB, `R_TYPE};
    expected_cc[1] = (~a[31] &  b[31] &  expected_out[31]);
    expected_cc[2] = ( a[31] & ~b[31] & ~expected_out[31]);
    check_cc("SUB-UNF");

    $display("=== Testbench Done, errors=%0d ===", errors);
    if (errors == 0) $display("All tests PASSED");
    else             $display("Some tests FAILED");
    $finish;
  end
endmodule
