`timescale 1ns/1ps
`include "opcodes.vh"

module cpu_tb;
  reg clk, rst;

  // DUT
  cpu dut (
    .clk(clk),
    .rst(rst)
  );

  // Clock gen
  initial clk = 0;
  always #5 clk = ~clk;

  // Reset
  initial begin
    rst = 1;
    #20;
    rst = 0;
  end

  // Decode helper
  function [127:0] opcode_to_str(input [6:0] opcode);
    begin
      case (opcode[2:0])
        `R_TYPE, `I_TYPE: begin
          case (opcode[6:3])
            `ADD:   opcode_to_str = "ADD";
            `SUB:   opcode_to_str = "SUB";
            `MULT:  opcode_to_str = "MULT";
            `AND:   opcode_to_str = "AND";
            `OR:    opcode_to_str = "OR";
            `XOR:   opcode_to_str = "XOR";
            `NOT:   opcode_to_str = "NOT";
            default: opcode_to_str = "R/I-????";
          endcase
        end
        `B_TYPE: begin
          case (opcode[6:3])
            `BEQ:   opcode_to_str = "BEQ";
            `BNE:   opcode_to_str = "BNE";
            `BLT:   opcode_to_str = "BLT";
            `BLE:   opcode_to_str = "BLE";
            `BGT:   opcode_to_str = "BGT";
            `BGE:   opcode_to_str = "BGE";
            default: opcode_to_str = "B-????";
          endcase
        end
        `J_TYPE: begin
          case (opcode[6:3])
            `JUMP:  opcode_to_str = "JUMP";
            default: opcode_to_str = "J-????";
          endcase
        end
        `M_TYPE: begin
          case (opcode[6:3])
            `LOAD:  opcode_to_str = "LOAD";
            `STORE: opcode_to_str = "STORE";
            default: opcode_to_str = "M-????";
          endcase
        end
        `S_TYPE: begin
          case (opcode[6:3])
            `CALL:  opcode_to_str = "CALL";
            `RET:   opcode_to_str = "RET";
            default: opcode_to_str = "S-????";
          endcase
        end
        default: opcode_to_str = "????";
      endcase
    end
  endfunction

  // Monitor
  initial begin
    $display("Time\tPC\tInst\tOpcode\t\tALU_out\t\tCCR");
    $monitor("%0t\t%h\t%h\t%s\t%h\t%b",
            $time,
            dut.pc,
            dut.inst,
            opcode_to_str(dut.inst[6:0]),
            dut.alu_out,
            dut.ccr);
  end

  // Run for some cycles
  initial begin
    #2000;
    $finish;
  end
endmodule
