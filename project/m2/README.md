# Milestone 2 — Hardware Accelerator for Transformer Self-Attention Inference
## ECE 510 Spring 2026 | Sri Chandana Reddy Vanukuri

---

## Overview

This milestone implements the full scaled dot-product attention pipeline
in synthesizable SystemVerilog. The compute core is decomposed into four
submodules instantiated by the top-level `compute_core.sv`:

| Module | Stage | Function |
|--------|-------|----------|
| `mac_unit.sv` | 1 | QKᵀ dot product (INT8 × INT8 → 32-bit accum) |
| `scale_unit.sv` | 2 | Scale by 1/√d_k (arithmetic right shift by 3) |
| `relu_approx.sv` | 3 | Softmax approximation (ReLU clips negatives) |
| `av_unit.sv` | 4 | AV weighted sum (attention weight × V element) |

The `interface_axi4s` module in `interface.sv` connects the host processor
to the compute core via AXI4-Stream protocol.

---

## How to Reproduce M2 Simulation

### Simulator
**ModelSim - Intel FPGA Edition 10.5b** (Compiler 2016.10)

### Step 1 — Open ModelSim and set up
```
vlib work
cd "project/m2"
```

### Step 2 — Compile all RTL submodules
```
vlog -sv rtl/mac_unit.sv
vlog -sv rtl/scale_unit.sv
vlog -sv rtl/relu_approx.sv
vlog -sv rtl/av_unit.sv
vlog -sv rtl/compute_core.sv
vlog -sv rtl/interface.sv
```

### Step 3 — Compile and run compute core testbench
```
vlog -sv tb/tb_compute_core.sv
vsim tb_compute_core
run -all
```
Expected: `OVERALL: PASS` (3/3 tests) | Log: `sim/compute_core_run.log`

### Step 4 — Compile and run interface testbench
```
vlog -sv tb/tb_interface.sv
vsim tb_interface
run -all
```
Expected: `OVERALL: PASS` (4/4 tests) | Log: `sim/interface_run.log`

### Step 5 — View waveform
```
vsim tb_compute_core
add wave -divider "INPUTS"
add wave /tb_compute_core/clk
add wave /tb_compute_core/rst
add wave /tb_compute_core/q_in
add wave /tb_compute_core/k_in
add wave /tb_compute_core/v_in
add wave /tb_compute_core/valid_in
add wave /tb_compute_core/seq_last
add wave -divider "PIPELINE"
add wave /tb_compute_core/dut/mac_accum
add wave /tb_compute_core/dut/scaled_data
add wave /tb_compute_core/dut/relu_data
add wave -divider "OUTPUT"
add wave /tb_compute_core/attn_out
add wave /tb_compute_core/valid_out
run -all
wave zoom full
```
Screenshot saved as: `sim/waveform.png`

---

## Deviations from M1 Plan

The HW/SW boundary has been expanded compared to the original M1 plan.
Originally only the QKᵀ dot product and AV weighted sum were targeted
for hardware acceleration. Based on profiling data (74.5% runtime in
attention, AI = 10.67 FLOP/byte) and professor feedback, the boundary
was expanded to include the full scaled dot-product attention block.
The interface remains AXI4-Stream as selected in M1. Precision remains
INT8 inputs with 32-bit accumulation as planned.

---

## File Structure

```
project/m2/
├── rtl/
│   ├── compute_core.sv    ← top-level attention pipeline
│   ├── mac_unit.sv        ← Stage 1: QKᵀ MAC
│   ├── scale_unit.sv      ← Stage 2: fixed-point scaling
│   ├── relu_approx.sv     ← Stage 3: softmax approximation
│   ├── av_unit.sv         ← Stage 4: AV weighted sum
│   └── interface.sv       ← AXI4-Stream interface
├── tb/
│   ├── tb_compute_core.sv ← compute core testbench
│   └── tb_interface.sv    ← interface testbench
├── sim/
│   ├── compute_core_run.log ← 3/3 PASS
│   ├── interface_run.log    ← 4/4 PASS
│   └── waveform.png         ← ModelSim wave screenshot
├── precision.md             ← INT8 precision + error analysis
└── README.md                ← this file
```