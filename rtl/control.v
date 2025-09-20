module control (
  input [31:0] inst,
  input [3:0] ccr,

  output pc_sel,
  output b_sel,
  output dmem_we,
  output wb_sel,
  output reg_we
);

  always @* begin
    // Defaults
    pc_sel  = 'd0; // PC+4/ALU
    b_sel   = 'd0; // RS2/IMM[15:0]
    dmem_we = 'd0;
    wb_sel  = 'd0; // ALU/DMEM
    reg_we  = 'd0;

    case (inst[3:0]) 
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
        case (inst[7:4])
          `JUMP:    pc_sel = 'd1;
        endcase
      end

      `M_TYPE: begin
        case (inst[7:4])
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

      default: begin
        // Defaults
        pc_sel  = 'd0;
        b_sel   = 'd0;
        dmem_we = 'd0;
        wb_sel  = 'd0;
        reg_we  = 'd0;
      end
    endcase

  end

endmodule