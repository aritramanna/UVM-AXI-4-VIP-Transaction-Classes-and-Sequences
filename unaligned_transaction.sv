///////////////////////////////////////////////////////////////////////////////////// Unaligned AXI Transactions ///////////////////////////////////////////////////////////////////////////////////
//
// AXI-4 Unaligned Transaction 
//
`include "uvm_macros.svh"
import uvm_pkg::*;

// Class: axi_unaligned_transaction
// Description: Derived class that supports Unaligned AXI addresses.
//              By default, the base class enforces natural alignment.
//              This class disables those constraints to allow stress testing of unaligned cases.
class axi_unaligned_transaction extends axi_transaction;
  `uvm_object_utils(axi_unaligned_transaction)

  function new(string name = "axi_unaligned_transaction");
    super.new(name);
    
    // DISABLE Base Class Alignment Constraints
    this.awaddr_align.constraint_mode(0);
    this.araddr_align.constraint_mode(0);
    
    // Note: 4KB Boundary constraints (aw_4kb_boundary_const) remain ACTIVE 
    // because crossing 4KB is illegal even for unaligned bursts.
  endfunction

  // Constraint: Force Unaligned Address
  // This constraint ensures we actually generate unaligned addresses for testing.
  // Otherwise, random chance might still pick aligned addresses.
  constraint force_unaligned_wr {
    if (awsize > 0) {
       (awaddr % (1 << awsize)) != 0;
    }
  }

  constraint force_unaligned_rd {
    if (arsize > 0) {
       (araddr % (1 << arsize)) != 0;
    }
  }

endclass
