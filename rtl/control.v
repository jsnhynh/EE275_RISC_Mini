`timescale 1ns/1ps
`include "opcodes.vh"

module control (
  input [31:0] inst,
  input [3:0] ccr,

  output reg pc_sel,
  output reg b_sel,
  output reg dmem_we,
  output reg wb_sel,
  output reg reg_we,

  input [7:0] sc,
  input [1:0] state_mode,
  output reg [1:0] state_mode_next
);

  always @* begin
    // Defaults
    pc_sel  = 'd0; // PC+4/ALU
    b_sel   = 'd0; // RS2/IMM[15:0]
    dmem_we = 'd0;
    wb_sel  = 'd0; // ALU/DMEM
    reg_we  = 'd0;
    state_mode_next = (sc == 16)? 'd0 : state_mode; // IMEM, CALL, RET, Reserve

    case (inst[2:0]) 
      `J_TYPE: begin
        reg_we = 'd1;
      end

      `I_TYPE: begin
        b_sel = 'd1;
        reg_we = 'd1;
      end

      `B_TYPE: begin
        pc_sel = ccr[0];
      end

      `J_TYPE: begin
        case (inst[6:3])
          `JUMP:    pc_sel = 'd1;
        endcase
      end

      `M_TYPE: begin
        case (inst[6:3])
          `LOAD: begin
            b_sel   = 'd1;
            wb_sel  = 'd1;
            reg_we  = 'd1;
          end
          `STORE: begin
            b_sel   = 'd1;
            dmem_we = 'd1;
          end
        endcase
      end

      `S_TYPE: begin
        case (inst[6:3])
          `CALL: begin
            state_mode_next = 'd1;
          end
          `RET: begin
            state_mode_next = 'd2;
          end
        endcase
      end

      default: begin
        // Defaults
        pc_sel  = 'd0;
        b_sel   = 'd0;
        dmem_we = 'd0;
        wb_sel  = 'd0;
        reg_we  = 'd0;
        state_mode_next = 'd0;
      end
    endcase

  end

endmodule