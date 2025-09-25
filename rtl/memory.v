`timescale 1ns/1ps
// Instruction Memory (async read)
module imem #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter INIT_FILE  = "program.hex"
)(
    input  wire [ADDR_WIDTH-1:0] addr,   // byte address (PC)
    output wire [DATA_WIDTH-1:0] inst
);
    localparam WORDS = (1 << (ADDR_WIDTH-2));
    reg [DATA_WIDTH-1:0] mem [0:WORDS-1];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    // async read (word-aligned)
    assign inst = mem[addr[ADDR_WIDTH-1:2]];
endmodule

// Data Memory (async read, sync write)
module dmem #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  we,       // write enable
    input  wire [ADDR_WIDTH-1:0] addr,      // byte address
    input  wire [DATA_WIDTH-1:0] wdata,     // write data
    output wire [DATA_WIDTH-1:0] rdata      // read data (async)
);

    localparam WORDS = (1 << (ADDR_WIDTH-2)); // word depth
    reg [DATA_WIDTH-1:0] mem [0:WORDS-1];

    // async read
    assign rdata = mem[addr[ADDR_WIDTH-1:2]];

    // sync write
    always @(posedge clk) begin
        if (we)
            mem[addr[ADDR_WIDTH-1:2]] <= wdata;
    end

endmodule
