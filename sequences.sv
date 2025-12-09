

///////////////////////////////////////////////////////////////////////////////////// AXI Sequences /////////////////////////////////////////////////////////////////////////////////////////////////////
//
// AXI-4 Sequence
//
// Class: rd_wr_random_sequence
// Description: Generates a completely random mix of Read and Write transactions.
class rd_wr_random_sequence extends uvm_sequence #(axi_transaction);
  `uvm_object_utils(rd_wr_random_sequence)
  axi_transaction tr;

  function new(string name = "rd_wr_random_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("[SEQ]", "................Starting AXI WR/RD Random sequence...............", UVM_HIGH);
    repeat(50)begin
      tr = axi_transaction::type_id::create("tr");
      start_item(tr);  
      assert(tr.randomize());
      $display("------------------------------");
      `uvm_info("[SEQ]", $sformatf("%0s", tr.convert2string()), UVM_HIGH);
      finish_item(tr);
    end
  endtask
endclass

// Class: wr_fixed_sequence
// Description: Generates Fixed address Write transactions.
class wr_fixed_sequence extends uvm_sequence #(axi_transaction);
  `uvm_object_utils(wr_fixed_sequence)
  axi_transaction tr;

  function new(string name = "wr_fixed_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("[SEQ]", "................Starting AXI FIXED WR Sequence...............", UVM_HIGH);
    repeat(50)begin
      tr = axi_transaction::type_id::create("tr");
      tr.op_wr_fixed_mode_constraint.constraint_mode(1);
      start_item(tr);  
      assert(tr.randomize());
      $display("------------------------------");
      `uvm_info("[SEQ]", $sformatf("%0s", tr.convert2string()), UVM_HIGH);
      finish_item(tr);
    end
  endtask
endclass

// Class: rd_fixed_sequence
// Description: Generates Fixed address Read transactions.
class rd_fixed_sequence extends uvm_sequence #(axi_transaction);
  `uvm_object_utils(rd_fixed_sequence)
  axi_transaction tr;

  function new(string name = "rd_fixed_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("[SEQ]", "................Starting AXI FIXED RD Sequence...............", UVM_HIGH);
    repeat(50)begin
      tr = axi_transaction::type_id::create("tr");
      tr.op_rd_fixed_mode_constraint.constraint_mode(1);
      start_item(tr);  
      assert(tr.randomize());
      $display("------------------------------");
      `uvm_info("[SEQ]", $sformatf("%0s", tr.convert2string()), UVM_HIGH);
      finish_item(tr);
    end
  endtask
endclass

// Class: wr_incr_sequence
// Description: Generates Incrementing address Write transactions.
class wr_incr_sequence extends uvm_sequence #(axi_transaction);
  `uvm_object_utils(wr_incr_sequence)
  axi_transaction tr;

  function new(string name = "wr_incr_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("[SEQ]", "................Starting AXI INCR WR Sequence...............", UVM_HIGH);
    repeat(50)begin
      tr = axi_transaction::type_id::create("tr");
      tr.op_wr_incr_mode_constraint.constraint_mode(1);
      start_item(tr);  
      assert(tr.randomize());
      $display("------------------------------");
      `uvm_info("[SEQ]", $sformatf("%0s", tr.convert2string()), UVM_HIGH);
      finish_item(tr);
    end
  endtask
endclass

// Class: rd_incr_sequence
// Description: Generates Incrementing address Read transactions.
class rd_incr_sequence extends uvm_sequence #(axi_transaction);
  `uvm_object_utils(rd_incr_sequence)
  axi_transaction tr;

  function new(string name = "rd_incr_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("[SEQ]", "................Starting AXI INCR RD Sequence...............", UVM_HIGH);
    repeat(50)begin
      tr = axi_transaction::type_id::create("tr");
      tr.op_rd_incr_mode_constraint.constraint_mode(1);
      start_item(tr);  
      assert(tr.randomize());
      $display("------------------------------");
      `uvm_info("[SEQ]", $sformatf("%0s", tr.convert2string()), UVM_HIGH);
      finish_item(tr);
    end
  endtask
endclass

// Class: wr_wrap_sequence
// Description: Generates Wrapping address Write transactions.
class wr_wrap_sequence extends uvm_sequence #(axi_transaction);
  `uvm_object_utils(wr_wrap_sequence)
  axi_transaction tr;

  function new(string name = "wr_wrap_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("[SEQ]", "................Starting AXI WRAP WR Sequence...............", UVM_HIGH);
    repeat(50)begin
      tr = axi_transaction::type_id::create("tr");
      tr.op_wr_wrap_mode_constraint.constraint_mode(1);
      start_item(tr);  
      assert(tr.randomize());
      $display("------------------------------");
      `uvm_info("[SEQ]", $sformatf("%0s", tr.convert2string()), UVM_HIGH);
      finish_item(tr);
    end
  endtask
endclass

// Class: rd_wrap_sequence
// Description: Generates Wrapping address Read transactions.
class rd_wrap_sequence extends uvm_sequence #(axi_transaction);
  `uvm_object_utils(rd_wrap_sequence)
  axi_transaction tr;

  function new(string name = "rd_wrap_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("[SEQ]", "................Starting AXI WRAP RD Sequence...............", UVM_HIGH);
    repeat(50)begin
      tr = axi_transaction::type_id::create("tr");
      tr.op_rd_wrap_mode_constraint.constraint_mode(1);
      start_item(tr);  
      assert(tr.randomize());
      $display("------------------------------");
      `uvm_info("[SEQ]", $sformatf("%0s", tr.convert2string()), UVM_HIGH);
      finish_item(tr);
    end
  endtask
endclass

// Class: rd_wr_error_sequence
// Description: Injects error transactions (DECERR/SLVERR) based on a corruption mask.
class rd_wr_error_sequence extends uvm_sequence #(axi_transaction);
  `uvm_object_utils(rd_wr_error_sequence)
  axi_transaction tr;

  rand bit [49:0] corrupt_flag;   // Sets which transactions to corrupt
  rand int unsigned corruption_level[50]; // Stores corruption Type (1-3)

  // Constraint to ensure exactly 10 transactions are corrupted
  constraint c_corrupt_count {
    $countones(corrupt_flag) == 10;
  }

  // Constraint to ensure corruption level is 1, 2, or 3 where corruption_flag is set
  constraint c_corruption_level {
    foreach (corruption_level[i]) {
      if (corrupt_flag[i]) corruption_level[i] inside {[1:3]};
      else corruption_level[i] == 0;
    }
  }

  function new(string name = "rd_wr_error_sequence");
    super.new(name);
  endfunction


  // Pre-body task to generate corruption flags and type
  virtual task pre_body();
    if (!this.randomize()) begin
      `uvm_error("[SEQ]", "Randomization failed for corrupt_flag and corruption_level")
    end else begin
      `uvm_info("[SEQ]", $sformatf("Corruption Mask: %b", corrupt_flag), UVM_MEDIUM)

      foreach (corrupt_flag[i]) begin
        if (corrupt_flag[i]) begin
          `uvm_info("[SEQ]", $sformatf("Transaction %0d is CORRUPTED with Level %0d", 
            i, corruption_level[i]), UVM_MEDIUM)
        end
      end
    end
  endtask

  virtual task body();
    `uvm_info("[SEQ]", "................Starting AXI WR/RD Error sequence...............", UVM_HIGH);
    for(int i = 0; i < 50; i++) begin
      tr = axi_transaction::type_id::create("tr");
      start_item(tr);  
      
      if(corrupt_flag[i]) begin

        case(corruption_level[i])
          // Use standard enum names
          // DECERR : 2'b11
          1 : if ( (tr.op == WR_ADDR_FIXED) || (tr.op == WR_ADDR_INCR) || (tr.op == WR_ADDR_WRAP) ) begin  
             assert(tr.randomize() with { tr.awaddr >= 128; tr.awsize < 2; });  
          end else begin
             assert(tr.randomize() with { tr.araddr >= 128; tr.arsize <= 2; }); 
          end

          // SLVERR : 2'b10
          2 : if ( (tr.op == WR_ADDR_FIXED) || (tr.op == WR_ADDR_INCR) || (tr.op == WR_ADDR_WRAP) ) begin  
             assert(tr.randomize() with { tr.awsize > 2; });
          end else begin
             assert(tr.randomize() with { tr.arsize > 2; });
          end

          // DECERR : 2'b11
          3 : if ( (tr.op == WR_ADDR_FIXED) || (tr.op == WR_ADDR_INCR) || (tr.op == WR_ADDR_WRAP) ) begin  
             assert(tr.randomize() with { tr.awaddr >= 128; });
          end else begin
             assert(tr.randomize() with { tr.araddr >= 128; });
          end  
        endcase

      end else begin
        assert(tr.randomize());
      end 

      $display("------------------------------");
      `uvm_info("[SEQ]", $sformatf("%0s", tr.convert2string()), UVM_HIGH);
      finish_item(tr);
    end
  endtask
endclass

// Class: concurrent_wr_rd_sequence
// Description: Executes a Write Sequence and a Read Sequence in PARALLEL.
//              Used to verify full-duplex operation and Out-of-Order (OOO) capabilities.
class concurrent_wr_rd_sequence extends uvm_sequence #(axi_transaction);
  `uvm_object_utils(concurrent_wr_rd_sequence)

  wr_incr_sequence wr_seq;
  rd_incr_sequence rd_seq;

  function new(string name = "concurrent_wr_rd_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("[SEQ]", "................Starting Concurrent WR/RD Sequence...............", UVM_HIGH);
    
    wr_seq = wr_incr_sequence::type_id::create("wr_seq");
    rd_seq = rd_incr_sequence::type_id::create("rd_seq");

    fork
      wr_seq.start(m_sequencer);
      rd_seq.start(m_sequencer);
    join
    
    `uvm_info("[SEQ]", "................Finished Concurrent WR/RD Sequence...............", UVM_HIGH);
  endtask
endclass

// Class: stress_concurrent_sequence
// Description: Spawns 4 parallel threads (2 Write, 2 Read) to maximize bus contention.
class stress_concurrent_sequence extends uvm_sequence #(axi_transaction);
  `uvm_object_utils(stress_concurrent_sequence)

  wr_incr_sequence wr_seq_1, wr_seq_2;
  rd_incr_sequence rd_seq_1, rd_seq_2;

  function new(string name = "stress_concurrent_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("[SEQ]", "................Starting Stress Concurrent Sequence...............", UVM_HIGH);
    
    wr_seq_1 = wr_incr_sequence::type_id::create("wr_seq_1");
    wr_seq_2 = wr_incr_sequence::type_id::create("wr_seq_2");
    rd_seq_1 = rd_incr_sequence::type_id::create("rd_seq_1");
    rd_seq_2 = rd_incr_sequence::type_id::create("rd_seq_2");

    fork
      // Thread 1: Write
      wr_seq_1.start(m_sequencer);
      // Thread 2: Write
      wr_seq_2.start(m_sequencer);
      // Thread 3: Read
      rd_seq_1.start(m_sequencer);
      // Thread 4: Read
      rd_seq_2.start(m_sequencer);
    join
    
    `uvm_info("[SEQ]", "................Finished Stress Concurrent Sequence...............", UVM_HIGH);
  endtask
endclass

// Class: long_burst_sequence
// Description: Forces randomization of Long Bursts (> 200 beats) for AXI4 stress testing.
class long_burst_sequence extends uvm_sequence #(axi_transaction);
  `uvm_object_utils(long_burst_sequence)
  axi_transaction tr;

  function new(string name = "long_burst_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("[SEQ]", "................Starting Long Burst Sequence...............", UVM_HIGH);
    repeat(50)begin
      tr = axi_transaction::type_id::create("tr");
      start_item(tr); 
      // Force long INCR bursts (> 200 beats) 
      assert(tr.randomize() with { 
          op inside {WR_ADDR_INCR, RD_ADDR_INCR}; 
          if(op == WR_ADDR_INCR) awlen > 200;
          if(op == RD_ADDR_INCR) arlen > 200;
      });
      $display("------------------------------");
      `uvm_info("[SEQ]", $sformatf("%0s", tr.convert2string()), UVM_HIGH);
      finish_item(tr);
    end
  endtask
endclass

// Class: unaligned_wr_sequence
// Description: Generates Unaligned Write transactions.
class unaligned_wr_sequence extends uvm_sequence #(axi_transaction);
  `uvm_object_utils(unaligned_wr_sequence)
  
  // Use the DERIVED class for generation
  axi_unaligned_transaction unaligned_tr;

  function new(string name = "unaligned_wr_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("[SEQ]", "................Starting Unaligned WR Sequence...............", UVM_HIGH);
    repeat(20)begin
      // Create the UNALIGNED version
      unaligned_tr = axi_unaligned_transaction::type_id::create("unaligned_tr");
      
      start_item(unaligned_tr);  
      
      // randomize() will use the derived constraints (forcing unalignment)
      assert(unaligned_tr.randomize() with {
          op inside {WR_ADDR_INCR}; // Unaligned usually makes sense for INCR/WRAP
          awlen inside {[0:15]};    // Short bursts for easier debug
      });
      
      $display("------------------------------");
      `uvm_info("[SEQ-UNALIGNED]", $sformatf("%0s", unaligned_tr.convert2string()), UVM_HIGH);
      
      finish_item(unaligned_tr);
    end
  endtask
endclass

// Class: unaligned_rd_sequence
// Description: Generates Unaligned Read transactions.
class unaligned_rd_sequence extends uvm_sequence #(axi_transaction);
  `uvm_object_utils(unaligned_rd_sequence)
  
  axi_unaligned_transaction unaligned_tr;

  function new(string name = "unaligned_rd_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("[SEQ]", "................Starting Unaligned RD Sequence...............", UVM_HIGH);
    repeat(20)begin
      unaligned_tr = axi_unaligned_transaction::type_id::create("unaligned_tr");
      
      start_item(unaligned_tr);  
      
      assert(unaligned_tr.randomize() with {
          op inside {RD_ADDR_INCR}; 
          arlen inside {[0:15]};
      });
      
      $display("------------------------------");
      `uvm_info("[SEQ-UNALIGNED]", $sformatf("%0s", unaligned_tr.convert2string()), UVM_HIGH);
      
      finish_item(unaligned_tr);
    end
  endtask
endclass