`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "opcodes.vh"

/*
  Interface
*/
interface alu_if(input logic clk);
  logic [31:0] a, b;
  logic [3:0]  alu_op;    // DUT sees upper nibble [7:4] of full opcode
  logic [31:0] alu_out;
  logic [3:0]  alu_cc;
endinterface

/* 
  Transaction
*/
class alu_txn extends uvm_sequence_item;
  rand bit [31:0] a, b;
  rand bit [7:0]  opcode;   // full opcode (upper nibble = op, lower nibble = type)
  bit [31:0] exp_out;
  bit [3:0]  exp_cc;

  `uvm_object_utils(alu_txn)

  function new(string name="alu_txn"); super.new(name); endfunction

  constraint valid_ops {
    (opcode[3:0] inside {`R_TYPE, `I_TYPE}) &&
    (opcode[7:4] inside {
        `ADD, `SUB, `MULT,
        `AND, `OR, `XOR, `NOT,
        `BEQ, `BNE,
        `BLT, `BLE,
        `BGT, `BGE
    });
  }
endclass

/*
  Sequence
*/
class alu_seq extends uvm_sequence #(alu_txn);
  `uvm_object_utils(alu_seq)

  rand int unsigned reps = 5;

  function new(string name="alu_seq"); super.new(name); endfunction

  virtual task body();
    alu_txn tr;
    for (int unsigned r = 0; r < reps; r++) begin
      for (int unsigned op = `ADD; op <= `GREATER_THAN_EQUAL; op++) begin
        tr = alu_txn::type_id::create($sformatf("tr_r%0d_op%0d", r, op));

        void'( std::randomize(tr.a, tr.b) );  // randomize operands

        tr.opcode = { op[3:0], 4'd0 };        // lower nibble fixed

        start_item(tr);
        finish_item(tr);
      end
    end
  endtask
endclass

/*
  Driver
*/
class alu_driver extends uvm_driver #(alu_txn);
  `uvm_component_utils(alu_driver)

  virtual alu_if vif;

  function new(string name="alu_driver", uvm_component parent=null); super.new(name, parent); endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "alu_if not set for driver")
  endfunction

  virtual task run_phase(uvm_phase phase);
    alu_txn tr;
    forever begin
      seq_item_port.get_next_item(tr);

      // Drive on negedge so monitor (posedge)
      @(negedge vif.clk);
      vif.a      <= tr.a;
      vif.b      <= tr.b;
      vif.alu_op <= tr.opcode[7:4];

      // Give the DUT one posedge to compute, then finish the item
      @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask
endclass

/*
  Monitor  (samples @posedge)
*/
class alu_monitor extends uvm_component;
  `uvm_component_utils(alu_monitor)

  virtual alu_if vif;
  uvm_analysis_port #(alu_txn) ap;

  function new(string name="alu_monitor", uvm_component parent=null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "alu_if not set for monitor")
  endfunction

  virtual task run_phase(uvm_phase phase);
    alu_txn tr;
    forever begin
      @(posedge vif.clk);
      tr = alu_txn::type_id::create("tr_mon");
      tr.a       = vif.a;
      tr.b       = vif.b;
      tr.opcode  = {vif.alu_op, 4'b0000}; // reconstruct full opcode
      tr.exp_out = vif.alu_out;
      tr.exp_cc  = vif.alu_cc;
      ap.write(tr);
    end
  endtask
endclass

/*
  Scoreboard
*/
class alu_scoreboard extends uvm_component;
  `uvm_component_utils(alu_scoreboard)

  uvm_analysis_imp #(alu_txn, alu_scoreboard) imp;

  function new(string name="alu_scoreboard", uvm_component parent=null);
    super.new(name, parent);
    imp = new("imp", this);
  endfunction

  virtual function void write(alu_txn tr);
    bit [31:0] ref_out = 32'd0;
    bit [3:0]  ref_cc  = 4'b0000;

    case (tr.opcode[7:4])
      `ADD: begin
        ref_out = tr.a + tr.b;
        ref_cc[1] = (($signed(tr.a) > 0 && $signed(tr.b) > 0 && $signed(ref_out) < 0) ||
                    ($signed(tr.a) < 0 && $signed(tr.b) < 0 && $signed(ref_out) > 0));
      end
      `SUB: begin
        ref_out = tr.a - tr.b;
        ref_cc[1] = (($signed(tr.a) > 0 && $signed(tr.b) < 0 && $signed(ref_out) < 0) ||
                    ($signed(tr.a) < 0 && $signed(tr.b) > 0 && $signed(ref_out) > 0));
        ref_cc[2] = (tr.a < tr.b);
      end
      `MULT: ref_out = tr.a * tr.b;
      `AND:  ref_out = tr.a & tr.b;
      `OR:   ref_out = tr.a | tr.b;
      `XOR:  ref_out = tr.a ^ tr.b;
      `NOT:  ref_out = ~tr.a;

      `BEQ: ref_cc[0] = ($signed(tr.a) == $signed(tr.b));
      `BNE: ref_cc[0] = ($signed(tr.a) != $signed(tr.b));
      `BLT: ref_cc[0] = ($signed(tr.a) <  $signed(tr.b));
      `BLE: ref_cc[0] = ($signed(tr.a) <= $signed(tr.b));
      `BGT: ref_cc[0] = ($signed(tr.a) >  $signed(tr.b));
      `BGE: ref_cc[0] = ($signed(tr.a) >= $signed(tr.b));
    endcase

    if (ref_out !== tr.exp_out || ref_cc !== tr.exp_cc) begin
      `uvm_error("ALU_SB",
        $sformatf("Failed: op=%0d a=%0h b=%0h got out=%0h cc=%0b exp out=%0h exp cc=%0b",
          tr.opcode[7:4], tr.a, tr.b, tr.exp_out, tr.exp_cc, ref_out, ref_cc))
    end else begin
      `uvm_info("ALU_SB",
        $sformatf("Passed: op=%0d a=%0h b=%0h got out=%0h cc=%0b exp out=%0h exp cc=%0b",
          tr.opcode[7:4], tr.a, tr.b, tr.exp_out, tr.exp_cc, ref_out, ref_cc), UVM_MEDIUM)
    end
  endfunction
endclass

/*
  Environment (sequencer connects driver & sequences)
*/
class alu_env extends uvm_env;
  `uvm_component_utils(alu_env)

  uvm_sequencer #(alu_txn) sqr;

  alu_driver     drv;
  alu_monitor    mon;
  alu_scoreboard sb;

  function new(string name="alu_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sqr = uvm_sequencer #(alu_txn)::type_id::create("sqr", this);
    drv = alu_driver   ::type_id::create("drv", this);
    mon = alu_monitor  ::type_id::create("mon", this);
    sb  = alu_scoreboard::type_id::create("sb",  this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export); // driver <-> sequencer
    mon.ap.connect(sb.imp);                         // monitor -> scoreboard
  endfunction
endclass

/*
  Test: builds env and runs alu_seq
*/
class alu_test extends uvm_test;
  `uvm_component_utils(alu_test)

  alu_env e;

  function new(string name="alu_test", uvm_component parent=null); super.new(name, parent); endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = alu_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    alu_seq s;
    phase.raise_objection(this);
    s = alu_seq::type_id::create("seq");
    void'(s.randomize());
    s.start(e.sqr);

    phase.drop_objection(this);
  endtask
endclass

/*
  Top-level Testbench
*/
module alu_top;
  // Clock
  logic clk = 0;
  always #5 clk = ~clk; // 100MHz

  // Interface instance
  alu_if alu_bus(clk);

  // DUT instance (compile your RTL 'alu.sv' separately)
  alu dut (
    .a      (alu_bus.a),
    .b      (alu_bus.b),
    .alu_op (alu_bus.alu_op),
    .alu_out(alu_bus.alu_out),
    .alu_cc (alu_bus.alu_cc)
  );

  // Provide virtual interface to UVM
  initial begin
    uvm_config_db#(virtual alu_if)::set(null, "*", "vif", alu_bus);
  end

  // Run the test
  initial begin
    run_test("alu_test");
  end
endmodule
