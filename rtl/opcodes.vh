/**
    * List of opcodes.
    * The design is aimed at simplicity, hence the removal of funct3/7 normally found in RISC-V
    * Opcode is 7 bits split into 2 sections
    * Bits [2:0] Function Type (R/I/B/J/M)
    * Bits [6:3] Operation
 */

`ifndef OPCODE
`define OPCODE

// ***** Opcodes *****

// Opcode Types
`define R_TYPE 3'd0
`define I_TYPE 3'd1
`define B_TYPE 3'd2
`define J_TYPE 3'd3
`define M_TYPE 3'd4
`define S_TYPE 3'd5

// Opcode Operation

// R-TYPES / I-TYPES
`define ADD 4'd0
`define SUB 4'd1
`define MULT 4'd2

`define AND 4'd3
`define OR 4'd4
`define XOR 4'd5
`define NOT 4'd6

// B-TYPES
`define BEQ 4'd7
`define BNE 4'd8
`define BLT 4'd9
`define BLE 4'd10
`define BGT 4'd11
`define BGE 4'd12

// J-TYPE
`define JUMP 4'd0

// M-TYPE
`define LOAD 4'd0
`define STORE 4'd1

// S-TYPE
`define CALL 4'd0
`define RET 4'd1

`endif //OPCODE
