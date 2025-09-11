// Register of D-Type Flip-flops
module REGISTER(q, d, clk);
  parameter N = 1;
  output reg [N-1:0] q;
  input [N-1:0]      d;
  input         clk;
  always @(posedge clk)
    q <= d;
endmodule // REGISTER

// Register with clock enable
module REGISTER_CE(q, d, ce, clk);
  parameter N = 1;
  output reg [N-1:0] q;
  input [N-1:0]      d;
  input          ce, clk;
  always @(posedge clk)
    if (ce) q <= d;
endmodule // REGISTER_CE

// Register with reset value
module REGISTER_R(q, d, rst, clk);
  parameter N = 1;
  parameter INIT = {N{1'b0}};
  output reg [N-1:0] q;
  input [N-1:0]      d;
  input          rst, clk;
  always @(posedge clk)
    if (rst) q <= INIT;
    else q <= d;
endmodule // REGISTER_R

// Register with reset and clock enable
//  Reset works independently of clock enable
module REGISTER_R_CE(q, d, rst, ce, clk);
  parameter N = 1;
  parameter INIT = {N{1'b0}};
  output reg [N-1:0] q;
  input [N-1:0]      d;
  input          rst, ce, clk;
  always @(posedge clk)
    if (rst) q <= INIT;
    else if (ce) q <= d;
endmodule // REGISTER_R_CE

/*
  Asynchronous 4 reads ports
  Synchronous  2 write ports
*/
module regfile #( parameter DEPTH = 32 ) (
  input clk,
  input rst, 
  input we0, we1,
  // Read ports Way 0
  input [$clog2(DEPTH)-1:0] raddr1_0, raddr2_0,
  output [`CPU_DATA_BITS-1:0] rs1_0, rs2_0,
  // Read ports Way 1
  input [$clog2(DEPTH)-1:0] raddr1_1, raddr2_1,
  output [`CPU_DATA_BITS-1:0] rs1_1, rs2_1,
  // Write ports
  input [$clog2(DEPTH)-1:0] waddr0, waddr1,
  input [`CPU_DATA_BITS-1:0] rd0, rd1
);

  genvar i;
  reg [`CPU_DATA_BITS-1:0] reg_d [DEPTH-1:0]; // din
  reg [`CPU_DATA_BITS-1:0] reg_q [DEPTH-1:0]; // dout

  // Register file
  generate
    for (i = 0; i < DEPTH; i++) begin
      REGISTER_R_CE #(.N(`CPU_DATA_BITS)) reg_x (
        .d((we1)? rd1 : rd0),     .q(reg_q[i]),
        .clk(clk),  .rst(rst), 
        .ce(
          (we0 && (i == waddr0) && (waddr0 != 0)) ||
          (we1 && (i == waddr1) && (waddr1 != 0)) ));
    end
  endgenerate

  // Read
  assign rs1_0 = reg_q[raddr1_0];
  assign rs2_0 = reg_q[raddr2_0];

  assign rs1_1 = reg_q[raddr1_1];
  assign rs2_1 = reg_q[raddr2_1];

endmodule
