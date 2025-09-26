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
    #10;
    rst = 0;
  end

  // Decode helper
  function [63:0] opcode_to_str(input [6:0] opcode);
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
  #20;
  // Keep the Time column stable (ns) so alignment doesn't jitter
  $timeformat(-9, 0, " ns", 12);

  $display( "| %-12s | %-4s | %-4s | %-8s | %-8s | %8s | %8s | %8s | %8s | %8s | %8s | %-8s | %-4s | %-4s |" , 
            "Time", "PC", "SC", "Inst", "Opcode", "Rs1", "Rs2", "Imm", "ALU_out", "Dmem_we", "WB_Data", "Reg_we", "CCR", "State_mode");

  $monitor( "| %t | %04h | %04h | %08h | %-8s | %8d | %8d | %8d | %8d | %8d | %8d | %8d | %04b | %04b |",
            $time,
            dut.pc,
            dut.sc,
            dut.inst,
            opcode_to_str(dut.inst[6:0]),
            $signed(dut.rs1),
            $signed(dut.rs2),
            $signed(dut.inst[31:22]),
            $signed(dut.alu_out),
            $signed(dut.dmem_we),
            $signed(dut.rf.rd),
            dut.reg_we,
            dut.alu_cc,
            dut.state_mode_next);
end

  // Run for some cycles
  initial begin
    #2000;
    $finish;
  end
endmodule
