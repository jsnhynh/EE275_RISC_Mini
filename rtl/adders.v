module cla4 (
  input  [3:0] a, b,
  input        cin,
  output [3:0] sum,
  output       cout,
  output       pg,
  output       gg
);
  wire [3:0] g, p, c;

  assign g = a & b;
  assign p = a ^ b;

  assign c[0] = cin;
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & c[1]);
  assign c[3] = g[2] | (p[2] & c[2]);
  assign cout = g[3] | (p[3] & c[3]);

  assign sum = p ^ c;

  assign pg = &p;
  assign gg = g[3] | (p[3]&g[2]) | (p[3]&p[2]&g[1]) | (p[3]&p[2]&p[1]&g[0]);
endmodule

module cla32 (
  input  [31:0] a, b,
  input         cin,
  output [31:0] sum,
  output        cout
);
  wire [7:0] pg, gg;
  wire [8:0] c;
  assign c[0] = cin;

  genvar i;
  generate
    for (i=0; i<8; i=i+1) begin : cla_blocks
    cla4 cla (
        .a(a[i*4 +: 4]),
        .b(b[i*4 +: 4]),
        .cin(c[i]),
        .sum(sum[i*4 +: 4]),
        .cout(),
        .pg(pg[i]),
        .gg(gg[i])
    );
    end
  endgenerate

  genvar j;
  generate
    for (j=0; j<8; j=j+1) begin : group_carry
      assign c[j+1] = gg[j] | (pg[j] & c[j]);
    end
  endgenerate

  assign cout = c[8];
endmodule
