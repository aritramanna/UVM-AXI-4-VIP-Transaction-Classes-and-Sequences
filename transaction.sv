//////////////////////////////////////////////////////////// AXI-4 Stimulus Generation ///////////////////////////////////////////////////////////////

`include "uvm_macros.svh"
import uvm_pkg::*;

// Enum defines channel operation modes
typedef enum bit[2:0] {
  WR_ADDR_FIXED = 0, WR_ADDR_INCR = 1, 
  RD_ADDR_FIXED = 2, RD_ADDR_INCR = 3, 
  WR_ADDR_WRAP  = 4, RD_ADDR_WRAP = 5
} axi_oper_mode_e;

// Class: axi_transaction
// Description: Represents a single AXI4 Read or Write transaction.
//
class axi_transaction extends uvm_sequence_item;
  `uvm_object_utils(axi_transaction)

  // Transaction Variables
  rand axi_oper_mode_e op;
  int len = 0; // Burst Length (calculated)

  rand int axi_wr_transaction_latency = 0; 
  rand int axi_rd_transaction_latency = 0; 
  
  // Storage for full burst payload (populated post-randomize)
  bit [31:0] data_payload [$];
  bit [3:0]  strb_payload [$];

  // Helper arrays for randomization
  rand bit [31:0] write_data_arr []; 
  rand bit [3:0]  wstrb_arr[];       

  // Address Write Channel Signals
  rand bit [3:0]  awid;
  rand bit [7:0]  awlen;
  rand bit [2:0]  awsize; 
  rand bit [31:0] awaddr;
  rand bit [1:0]  awburst;
  
  // Write Data Channel Signals (Single Beat)
  rand bit [31:0] wdata;
  rand bit [3:0]  wstrb;
  
  // Write Response Channel Signals (Captured by Monitor)
  bit [3:0] bid;
  bit [1:0] bresp;
  
  // Address Read Channel Signals
  rand bit [3:0]  arid;         
  rand bit [7:0]  arlen;  
  rand bit [2:0]  arsize;      
  rand bit [31:0] araddr; 
  rand bit [1:0]  arburst; 
  
  // Read Data Channel Signals (Captured by Monitor)
  bit [3:0]  rid;         
  bit [31:0] rdata;     
  bit [1:0]  rresp;        

  // Helper fields for string conversion
  string wr_burst_type_str;
  string rd_burst_type_str;

  // Constructor
  function new(string name = "axi_transaction");
    super.new(name);
    // Disable bias constraints by default
    this.op_wr_fixed_mode_constraint.constraint_mode(0); 
    this.op_wr_incr_mode_constraint.constraint_mode(0);   
    this.op_wr_wrap_mode_constraint.constraint_mode(0);   
    this.op_rd_fixed_mode_constraint.constraint_mode(0);  
    this.op_rd_incr_mode_constraint.constraint_mode(0);  
    this.op_rd_wrap_mode_constraint.constraint_mode(0);  
  endfunction

  /////////////////////////////// Constraints //////////////////////////////////
  
  constraint op_mode_constraint {
    op inside {WR_ADDR_FIXED, WR_ADDR_INCR, WR_ADDR_WRAP, RD_ADDR_FIXED, RD_ADDR_INCR, RD_ADDR_WRAP}; 
  }
  
  // Write Constraints
  constraint awaddr_align {
    (awaddr % (1 << awsize)) == 0;
  }

  constraint aw_wrap_addr_align {
    if (awburst == 2'b10) { 
      (awaddr % ((awlen + 1) * (1 << awsize))) == 0; 
    }
  }

  // Critical AXI Constraint: Burst must not cross 4KB boundary
  constraint aw_4kb_boundary_const {
    (awaddr[11:0] + ((awlen + 1) * (1 << awsize))) <= 4096;
  }
  
  constraint wr_addr_fixed_mode_const {  
    if (op == WR_ADDR_FIXED) awburst == 2'b00; 
  }
  
  constraint wr_addr_incr_mode_const {  
    if (op == WR_ADDR_INCR) awburst == 2'b01; 
  } 
      
  constraint wr_addr_wrap_mode_const {  
    if (op == WR_ADDR_WRAP) awburst == 2'b10;
  }

  constraint wr_mode_const {
    if (op == WR_ADDR_INCR) {
      awlen inside {[0:255]}; 
    } else {
      awlen inside {[0:15]}; 
    }
    awsize inside {0,1,2};     
    awaddr dist {
      [32'h0000_0000 : 32'h0000_003F] :/ 70,
      [32'h0000_0040 : 32'h0000_005F] :/ 20,
      [32'h0000_0060 : 32'h0000_007F] :/ 10
    };
  }
  
  constraint wr_trans_latency_const  { 
    axi_wr_transaction_latency dist {
      [0:5]   :/ 60,
      [6:10]  :/ 30,
      [11:15] :/ 10
    };
  }

  constraint write_arr_const {
    solve awlen before write_data_arr; 
    write_data_arr.size() == awlen+1; 
    unique {write_data_arr};          
  }

  constraint wstrb_const {
    solve awlen before wstrb_arr;
    solve awsize before wstrb_arr;
    wstrb_arr.size() == awlen+1;
    foreach(wstrb_arr[j]){             
      if (awsize == 3'b000) $countones(wstrb_arr[j]) == 1;
      else if (awsize == 3'b001) $countones(wstrb_arr[j]) == 2;
      else if (awsize == 3'b010) $countones(wstrb_arr[j]) == 4;
    }
  }
      
  // Read Constraints

  constraint araddr_align {
    (araddr % (1 << arsize)) == 0;
  }

  constraint ar_wrap_addr_align {
    if (arburst == 2'b10) {
      (araddr % ((arlen + 1) * (1 << arsize))) == 0;
    }
  }

  // Critical AXI Constraint: Burst must not cross 4KB boundary
  constraint ar_4kb_boundary_const {
    (araddr[11:0] + ((arlen + 1) * (1 << arsize))) <= 4096;
  }

  constraint rd_trans_latency_const  { 
    axi_rd_transaction_latency dist {
      [0:5]   :/ 60,
      [6:10]  :/ 30,
      [11:15] :/ 10
    };
  }
      
  constraint rd_addr_fixed_mode_const {  
    if (op == RD_ADDR_FIXED) arburst == 2'b00; 
  }
  
  constraint rd_addr_incr_mode_const {  
    if (op == RD_ADDR_INCR) arburst == 2'b01; 
  } 
      
  constraint rd_addr_wrap_mode_const {  
    if (op == RD_ADDR_WRAP) arburst == 2'b10;
  }   

  constraint rd_mode_const {
    if (op == RD_ADDR_INCR) {
      arlen inside {[0:255]}; 
    } else {
      arlen inside {[0:15]}; 
    }
    arsize inside {0,1,2};     
    araddr dist {
      [32'h0000_0000 : 32'h0000_003F] :/ 70,
      [32'h0000_0040 : 32'h0000_005F] :/ 20,
      [32'h0000_0060 : 32'h0000_007F] :/ 10 
    };
  }

  // Biased Constraints 
  constraint op_wr_fixed_mode_constraint {
    op dist {WR_ADDR_FIXED := 60, WR_ADDR_INCR := 20, WR_ADDR_WRAP := 20, RD_ADDR_FIXED := 33, RD_ADDR_INCR := 33, RD_ADDR_WRAP := 33}; 
  }
  constraint op_wr_incr_mode_constraint  {
    op dist {WR_ADDR_FIXED := 20, WR_ADDR_INCR := 60, WR_ADDR_WRAP := 20, RD_ADDR_FIXED := 33, RD_ADDR_INCR := 33, RD_ADDR_WRAP := 33}; 
  }
  constraint op_wr_wrap_mode_constraint  {
    op dist {WR_ADDR_FIXED := 20, WR_ADDR_INCR := 20, WR_ADDR_WRAP := 60, RD_ADDR_FIXED := 33, RD_ADDR_INCR := 33, RD_ADDR_WRAP := 33}; 
  }
  constraint op_rd_fixed_mode_constraint {
    op dist {WR_ADDR_FIXED := 33, WR_ADDR_INCR := 33, WR_ADDR_WRAP := 33, RD_ADDR_FIXED := 60, RD_ADDR_INCR := 20, RD_ADDR_WRAP := 20}; 
  }
  constraint op_rd_incr_mode_constraint {
    op dist {WR_ADDR_FIXED := 33, WR_ADDR_INCR := 33, WR_ADDR_WRAP := 33, RD_ADDR_FIXED := 20, RD_ADDR_INCR := 60, RD_ADDR_WRAP := 20}; 
  }
  constraint op_rd_wrap_mode_constraint {
    op dist {WR_ADDR_FIXED := 33, WR_ADDR_INCR := 33, WR_ADDR_WRAP := 33, RD_ADDR_FIXED := 20, RD_ADDR_INCR := 20, RD_ADDR_WRAP := 60}; 
  }
  
  // Functions
  function void post_randomize();
    // Decode Burst Type Strings for display
    case(awburst)
      2'b00: wr_burst_type_str = "FIXED";
      2'b01: wr_burst_type_str = "INCR";
      2'b10: wr_burst_type_str = "WRAP";
      default: wr_burst_type_str = "INVALID";
    endcase
    
    case(arburst)
      2'b00: rd_burst_type_str = "FIXED";
      2'b01: rd_burst_type_str = "INCR";
      2'b10: rd_burst_type_str = "WRAP";
      default: rd_burst_type_str = "INVALID";
    endcase

    if ( (op == WR_ADDR_FIXED) || (op == WR_ADDR_INCR) || (op == WR_ADDR_WRAP) ) begin
      len = awlen + 1;
      // Populate payload queues for easy access
      data_payload.delete();
      strb_payload.delete();
      for(int i = 0; i < len; i++) begin
        data_payload.push_back(write_data_arr[i]);
        strb_payload.push_back(wstrb_arr[i]);
      end
    end
  endfunction
    
  function string convert2string();
    string msg; 
    string op_str = op.name(); 

    case (op)
      WR_ADDR_FIXED, WR_ADDR_INCR, WR_ADDR_WRAP: begin
        msg = { 
          "\n==============================================\n",
          "WRITE TRANSACTION\n",
          $sformatf("Mode: %s\n", op_str),
          $sformatf("AWID: %0h\n", awid),
          $sformatf("AWADDR: 32'bx%08X\n", awaddr),
          $sformatf("AWLEN: %0d\n", awlen),
          $sformatf("AWSIZE: %0d (%0d Bytes)\n", awsize, (1 << awsize)),
          $sformatf("AWBURST: %0s\n", wr_burst_type_str),
          "Generated Write Data:"
        };
        foreach (data_payload[j]) begin
          msg = { msg, $sformatf(
            "\n [Beat:%0d] wrdata = 0x%08X wstrb = 0x%b",
            j, data_payload[j], strb_payload[j]
          )};
        end
      end

      RD_ADDR_FIXED, RD_ADDR_INCR, RD_ADDR_WRAP: begin
        msg = { 
          "\n==============================================\n",
          "READ TRANSACTION\n",
          $sformatf("Mode: %s\n", op_str),
          $sformatf("ARID: %0h\n", arid),
          $sformatf("ARADDR: 32'bx%08X\n", araddr),
          $sformatf("ARLEN: %0d\n", arlen),
          $sformatf("ARSIZE: %0d (%0d Bytes)\n", arsize, (1 << arsize)),
          $sformatf("ARBURST: %0s\n", rd_burst_type_str)
        };
      end
      default: msg = "UNKNOWN TRANSACTION TYPE";
    endcase

    return {msg, "\n==============================================\n"};
  endfunction
    
endclass : axi_transaction
