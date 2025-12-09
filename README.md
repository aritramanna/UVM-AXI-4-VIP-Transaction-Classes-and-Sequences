# UVM-AXI-4-VIP-Transaction-Classes-and-Sequences
AXI-4 Verification-IP Transaction Classes and Sequences

## Project Overview

This repository contains transaction-level stimulus components (UVM sequence items and sequences) designed to exercise AXI4 read/write behavior, corner cases, and stress scenarios for AXI-4 Verification IP. It is intended to be integrated into a UVM environment (sequencer/driver/monitor/scoreboard) to drive a DUT or verify monitor behavior.

Primary goals:

- Generate well-formed aligned AXI bursts (FIXED / INCR / WRAP).
- Exercise unaligned address cases and validate byte-enable / split-beat handling.
- Stress the bus with long bursts, concurrent sequences, and error-injection scenarios.

## Files (summary)

- `transaction.sv` — Core transaction class (`axi_transaction`) with randomized fields, constraints for alignment and 4KB boundaries, per-beat payload/strobe generation, and pretty-print utilities.
- `unaligned_transaction.sv` — Derived class (`axi_unaligned_transaction`) that disables natural alignment constraints and adds forced-unaligned constraints for stress testing misaligned accesses.
- `sequences.sv` — A collection of UVM sequences that create and randomize transactions: random mixes, fixed/incr/wrap variants, error injection, concurrent/stress sequences, long-burst generators, and unaligned sequences.

## Detailed File Descriptions

**`transaction.sv`**
- **Purpose:** Defines the main AXI transaction representation used by the sequences and UVM testbench.
- **Key class:** `axi_transaction extends uvm_sequence_item` (registered with `uvm_object_utils`).
- **Core fields:**
  - `op` (enum `axi_oper_mode_e`): selects operation mode (WR/RD + FIXED/INCR/WRAP).
  - `awid/arid`, `awaddr/araddr`, `awlen/arlen`, `awsize/arsize`, `awburst/arburst`: standard AXI address-channel signals.
  - Write-side fields: `wdata`, `wstrb`, `data_payload[$]`, `strb_payload[$]` — write-data per-beat storage populated during `post_randomize()`.
  - Read-side fields: `rid`, `rdata`, `rresp` — read response fields captured by a monitor; `axi_rd_transaction_latency` models expected read response latency.
  - latency fields: `axi_wr_transaction_latency`, `axi_rd_transaction_latency`.
- **Constraints and behavior:**
  - Alignment constraints: `awaddr_align` / `araddr_align` ensure addresses are naturally aligned to the beat-size ((awaddr % (1<<awsize)) == 0).
  - 4KB boundary check: `aw_4kb_boundary_const` / `ar_4kb_boundary_const` prevent bursts crossing 4KB.
  - Burst-type constraints: different limits for INCR vs FIXED/WRAP bursts (awlen/arlen ranges and awsize/arsize allowable values).
  - `wstrb` generation constraints ensure per-beat strobe counts match the declared beat size.
- **Utility methods:**
  - `post_randomize()`: decodes burst strings and — for writes — populates `data_payload` and `strb_payload` arrays from randomization helper arrays.
  - `convert2string()`: pretty-prints a transaction (mode, IDs, address, len/size/burst, and generated write-data per beat).
- **Usage pattern:** typical sequences create an `axi_transaction`, call `start_item(tr)`, `tr.randomize()` (sometimes with inline modifiers), then `finish_item(tr)`. The transaction's `data_payload` is populated automatically for write bursts in `post_randomize()`.

**`unaligned_transaction.sv`**
- **Purpose:** Provides a derived transaction class to generate intentionally unaligned AXI addresses for stress testing.
- **Key class:** `axi_unaligned_transaction extends axi_transaction` (registered with `uvm_object_utils`).
- **What it changes:**
  - Disables the base-class alignment constraints (`awaddr_align` and `araddr_align`) so generated addresses can be unaligned to the beat-size.
  - Adds explicit `force_unaligned_wr` and `force_unaligned_rd` constraints to bias generation toward unaligned addresses (so randomization actually produces unaligned cases).
  - Note: 4KB boundary constraints remain active because crossing 4KB is illegal on AXI and must be preserved even in unaligned tests.
- **Intended use:** use `axi_unaligned_transaction` in sequences where you want to exercise partial-beat writes/reads and ensure the design correctly handles byte enables, misaligned addresses, and beat splitting.

**`sequences.sv`**
- **Purpose:** A library of UVM sequences that produce a variety of AXI transaction patterns used to drive the DUT and validate behavior.
- **Representative sequences (and behavior):**
  - `rd_wr_random_sequence`: generates a mixed random set of read/write transactions.
  - `wr_fixed_sequence` / `rd_fixed_sequence`: generate fixed-address bursts.
  - `wr_incr_sequence` / `rd_incr_sequence`: generate incrementing-address bursts.
  - `wr_wrap_sequence` / `rd_wrap_sequence`: generate wrapping bursts.
  - `rd_wr_error_sequence`: injects corrupted transactions using a `corrupt_flag` mask and `corruption_level` array to test error handling (DECERR/SLVERR scenarios).
  - `concurrent_wr_rd_sequence` and `stress_concurrent_sequence`: start multiple sequences in parallel (fork/join) to stress concurrency and out-of-order conditions.
  - `long_burst_sequence`: forces very long INCR bursts (>200 beats) for stress testing.
  - `unaligned_wr_sequence` / `unaligned_rd_sequence`: use `axi_unaligned_transaction` to generate unaligned write/read transactions (short bursts by default in these sequences).
- **How sequences drive transactions:**
  - Sequences create transactions via the `::type_id::create()` factory and use the standard UVM `start_item` / `randomize()` / `finish_item` pattern.
  - Example (from the file):
    ```systemverilog
    unaligned_tr = axi_unaligned_transaction::type_id::create("unaligned_tr");
    start_item(unaligned_tr);
    assert(unaligned_tr.randomize() with { op inside {WR_ADDR_INCR}; awlen inside {[0:15]}; });
    finish_item(unaligned_tr);
    ```
  - Sequences that run in parallel use `fork ... join` and call `.start(m_sequencer)` on nested sequences (e.g., `wr_seq.start(m_sequencer);`).

## Key notes about aligned vs unaligned handling
- **Aligned transactions** are the default in `axi_transaction`: `awaddr` and `araddr` are constrained to be multiples of the beat size (1<<awsize / 1<<arsize). This models well-formed AXI bursts and simplifies DUT expectations (no split-beat handling needed).
- **Unaligned transactions** are created by using `axi_unaligned_transaction`. When unaligned addresses are generated:
  - The testbench must exercise or model splitting a logical unaligned transfer into beat-aligned bus transfers (the provided sequences print and expose payload/strobes but the DUT/testbench monitor must check proper byte-enable and alignment behavior).
  - The `unaligned_*_sequence` classes generate shorter bursts and deliberately set `awsize/arsize` and `awlen/arlen` to produce practical unaligned scenarios.

## Quick tips for testbench authors
- Use `convert2string()` to log human-friendly transaction descriptions (includes per-beat write-data and strobes).
- For DUT checks of unaligned behavior, ensure your monitor or scoreboard understands how an unaligned logical transfer should be decomposed into AXI beats and checks per-beat `wstrb` values.

---

If you want, I can also:

- add a minimal `tb_top.sv` scaffold that calls one sequence, or
- add a GitHub Actions workflow to run Verilator smoke tests and linting (commercial simulators need licenses).

Please tell me which you'd like next.


## Detailed File Descriptions

**`transaction.sv`**
- **Purpose:** Defines the main AXI transaction representation used by the sequences and UVM testbench.
- **Key class:** `axi_transaction extends uvm_sequence_item` (registered with `uvm_object_utils`).
- **Core fields:**
  - `op` (enum `axi_oper_mode_e`): selects operation mode (WR/RD + FIXED/INCR/WRAP).
  - `awid/arid`, `awaddr/araddr`, `awlen/arlen`, `awsize/arsize`, `awburst/arburst`: standard AXI address-channel signals.
  - Write-side fields: `wdata`, `wstrb`, `data_payload[$]`, `strb_payload[$]` — write-data per-beat storage populated during `post_randomize()`.
  - Read-side fields: `rid`, `rdata`, `rresp` — read response fields captured by a monitor; `axi_rd_transaction_latency` models expected read response latency.
  - latency fields: `axi_wr_transaction_latency`, `axi_rd_transaction_latency`.
- **Constraints and behavior:**
  - Alignment constraints: `awaddr_align` / `araddr_align` ensure addresses are naturally aligned to the beat-size ((awaddr % (1<<awsize)) == 0).
  - 4KB boundary check: `aw_4kb_boundary_const` / `ar_4kb_boundary_const` prevent bursts crossing 4KB.
  - Burst-type constraints: different limits for INCR vs FIXED/WRAP bursts (awlen/arlen ranges and awsize/arsize allowable values).
  - `wstrb` generation constraints ensure per-beat strobe counts match the declared beat size.
- **Utility methods:**
  - `post_randomize()`: decodes burst strings and — for writes — populates `data_payload` and `strb_payload` arrays from randomization helper arrays.
  - `convert2string()`: pretty-prints a transaction (mode, IDs, address, len/size/burst, and generated write-data per beat).
- **Usage pattern:** typical sequences create an `axi_transaction`, call `start_item(tr)`, `tr.randomize()` (sometimes with inline modifiers), then `finish_item(tr)`. The transaction's `data_payload` is populated automatically for write bursts in `post_randomize()`.

**`unaligned_transaction.sv`**
- **Purpose:** Provides a derived transaction class to generate intentionally unaligned AXI addresses for stress testing.
- **Key class:** `axi_unaligned_transaction extends axi_transaction` (registered with `uvm_object_utils`).
- **What it changes:**
  - Disables the base-class alignment constraints (`awaddr_align` and `araddr_align`) so generated addresses can be unaligned to the beat-size.
  - Adds explicit `force_unaligned_wr` and `force_unaligned_rd` constraints to bias generation toward unaligned addresses (so randomization actually produces unaligned cases).
  - Note: 4KB boundary constraints remain active because crossing 4KB is illegal on AXI and must be preserved even in unaligned tests.
- **Intended use:** use `axi_unaligned_transaction` in sequences where you want to exercise partial-beat writes/reads and ensure the design correctly handles byte enables, misaligned addresses, and beat splitting.

**`sequences.sv`**
- **Purpose:** A library of UVM sequences that produce a variety of AXI transaction patterns used to drive the DUT and validate behavior.
- **Representative sequences (and behavior):**
  - `rd_wr_random_sequence`: generates a mixed random set of read/write transactions.
  - `wr_fixed_sequence` / `rd_fixed_sequence`: generate fixed-address bursts.
  - `wr_incr_sequence` / `rd_incr_sequence`: generate incrementing-address bursts.
  - `wr_wrap_sequence` / `rd_wrap_sequence`: generate wrapping bursts.
  - `rd_wr_error_sequence`: injects corrupted transactions using a `corrupt_flag` mask and `corruption_level` array to test error handling (DECERR/SLVERR scenarios).
  - `concurrent_wr_rd_sequence` and `stress_concurrent_sequence`: start multiple sequences in parallel (fork/join) to stress concurrency and out-of-order conditions.
  - `long_burst_sequence`: forces very long INCR bursts (>200 beats) for stress testing.
  - `unaligned_wr_sequence` / `unaligned_rd_sequence`: use `axi_unaligned_transaction` to generate unaligned write/read transactions (short bursts by default in these sequences).
- **How sequences drive transactions:**
  - Sequences create transactions via the `::type_id::create()` factory and use the standard UVM `start_item` / `randomize()` / `finish_item` pattern.
  - Example (from the file):
    ```systemverilog
    unaligned_tr = axi_unaligned_transaction::type_id::create("unaligned_tr");
    start_item(unaligned_tr);
    assert(unaligned_tr.randomize() with { op inside {WR_ADDR_INCR}; awlen inside {[0:15]}; });
    finish_item(unaligned_tr);
    ```
  - Sequences that run in parallel use `fork ... join` and call `.start(m_sequencer)` on nested sequences (e.g., `wr_seq.start(m_sequencer);`).

## Key notes about aligned vs unaligned handling
- **Aligned transactions** are the default in `axi_transaction`: `awaddr` and `araddr` are constrained to be multiples of the beat size (1<<awsize / 1<<arsize). This models well-formed AXI bursts and simplifies DUT expectations (no split-beat handling needed).
- **Unaligned transactions** are created by using `axi_unaligned_transaction`. When unaligned addresses are generated:
  - The testbench must exercise or model splitting a logical unaligned transfer into beat-aligned bus transfers (the provided sequences print and expose payload/strobes but the DUT/testbench monitor must check proper byte-enable and alignment behavior).
  - The `unaligned_*_sequence` classes generate shorter bursts and deliberately set `awsize/arsize` and `awlen/arlen` to produce practical unaligned scenarios.

## Quick tips for testbench authors
- Use `convert2string()` to log human-friendly transaction descriptions (includes per-beat write-data and strobes).
- For DUT checks of unaligned behavior, ensure your monitor or scoreboard understands how an unaligned logical transfer should be decomposed into AXI beats and checks per-beat `wstrb` values.

===== AXI Transaction UVM Testbench =====


==============================================
READ TRANSACTION
Mode: RD_ADDR_WRAP
ARID: 3
ARADDR: 32'bx0000000e
ARLEN: 6
ARSIZE: 1 (2 Bytes)
ARBURST: WRAP

==============================================


==============================================
READ TRANSACTION
Mode: RD_ADDR_WRAP
ARID: 4
ARADDR: 32'bx0000003a
ARLEN: 0
ARSIZE: 1 (2 Bytes)
ARBURST: WRAP

==============================================


==============================================
WRITE TRANSACTION
Mode: WR_ADDR_WRAP
AWID: b
AWADDR: 32'bx00000009
AWLEN: 8
AWSIZE: 0 (1 Bytes)
AWBURST: WRAP
Generated Write Data:
 [Beat:0] wrdata = 0x51c22db2 wstrb = 0x0001
 [Beat:1] wrdata = 0x5891ca0c wstrb = 0x0010
 [Beat:2] wrdata = 0x3f91ce78 wstrb = 0x0001
 [Beat:3] wrdata = 0x3f401074 wstrb = 0x0001
 [Beat:4] wrdata = 0xe2ace01a wstrb = 0x0010
 [Beat:5] wrdata = 0xb7b9cd6e wstrb = 0x0100
 [Beat:6] wrdata = 0xd6bb67e8 wstrb = 0x0001
 [Beat:7] wrdata = 0xd5cddf0b wstrb = 0x0100
 [Beat:8] wrdata = 0x4ad8da30 wstrb = 0x0100
==============================================


==============================================
READ TRANSACTION
Mode: RD_ADDR_FIXED
ARID: 7
ARADDR: 32'bx00000058
ARLEN: 15
ARSIZE: 0 (1 Bytes)
ARBURST: FIXED

==============================================


==============================================
WRITE TRANSACTION
Mode: WR_ADDR_FIXED
AWID: 9
AWADDR: 32'bx00000004
AWLEN: 0
AWSIZE: 2 (4 Bytes)
AWBURST: FIXED
Generated Write Data:
 [Beat:0] wrdata = 0x9cd7bbcb wstrb = 0x1111
==============================================


==============================================
WRITE TRANSACTION
Mode: WR_ADDR_WRAP
AWID: 7
AWADDR: 32'bx0000004a
AWLEN: 0
AWSIZE: 1 (2 Bytes)
AWBURST: WRAP
Generated Write Data:
 [Beat:0] wrdata = 0x280f6a4b wstrb = 0x0011
==============================================


==============================================
READ TRANSACTION
Mode: RD_ADDR_WRAP
ARID: a
ARADDR: 32'bx00000077
ARLEN: 6
ARSIZE: 0 (1 Bytes)
ARBURST: WRAP

==============================================


==============================================
WRITE TRANSACTION
Mode: WR_ADDR_WRAP
AWID: f
AWADDR: 32'bx0000005a
AWLEN: 8
AWSIZE: 1 (2 Bytes)
AWBURST: WRAP
Generated Write Data:
 [Beat:0] wrdata = 0xfdb5205e wstrb = 0x0101
 [Beat:1] wrdata = 0xaf336e9f wstrb = 0x1100
 [Beat:2] wrdata = 0x85607ecd wstrb = 0x0011
 [Beat:3] wrdata = 0x33d8adc9 wstrb = 0x0110
 [Beat:4] wrdata = 0x33d67fb6 wstrb = 0x0011
 [Beat:5] wrdata = 0x859074fb wstrb = 0x0110
 [Beat:6] wrdata = 0x28c2ed26 wstrb = 0x0011
 [Beat:7] wrdata = 0xed4ff661 wstrb = 0x1010
 [Beat:8] wrdata = 0xf0a3c4e2 wstrb = 0x0011
==============================================


==============================================
READ TRANSACTION
Mode: RD_ADDR_WRAP
ARID: c
ARADDR: 32'bx0000003c
ARLEN: 14
ARSIZE: 2 (4 Bytes)
ARBURST: WRAP

==============================================


==============================================
WRITE TRANSACTION
Mode: WR_ADDR_WRAP
AWID: e
AWADDR: 32'bx00000028
AWLEN: 9
AWSIZE: 1 (2 Bytes)
AWBURST: WRAP
Generated Write Data:
 [Beat:0] wrdata = 0xfa0b4731 wstrb = 0x1001
 [Beat:1] wrdata = 0x5ec35fd9 wstrb = 0x1010
 [Beat:2] wrdata = 0x4e5247ba wstrb = 0x1010
 [Beat:3] wrdata = 0xe36c1230 wstrb = 0x1001
 [Beat:4] wrdata = 0xcdcad76c wstrb = 0x0011
 [Beat:5] wrdata = 0xcc39d51c wstrb = 0x1100
 [Beat:6] wrdata = 0xc99ace30 wstrb = 0x1100
 [Beat:7] wrdata = 0xb09b5196 wstrb = 0x0110
 [Beat:8] wrdata = 0x084651c1 wstrb = 0x0110
 [Beat:9] wrdata = 0x129a95bb wstrb = 0x0101
==============================================



