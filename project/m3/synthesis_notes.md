# Synthesis Notes and Scope Status
## M3 — Hardware Accelerator for Transformer Self-Attention Inference
## ECE 510 Spring 2026 | Sri Chandana Reddy Vanukuri

---

## Overview

This document describes the M3 synthesis attempt of the full
transformer self-attention accelerator, including what synthesized
successfully, what did not, and what was learned. The synthesis target
was the integrated `top` module connecting the AXI4-Stream interface
(`interface_axi4s`) to the full attention pipeline compute core
(`compute_core`), which instantiates four submodules: `mac_unit`,
`scale_unit`, `relu_approx`, and `av_unit`.

---

## What Synthesized Successfully

### RTL Compilation
All seven RTL modules compiled without errors in ModelSim 10.5b:
`mac_unit.sv`, `scale_unit.sv`, `relu_approx.sv`, `av_unit.sv`,
`compute_core.sv`, `interface.sv`, and `top.sv`. No syntax errors,
no unsupported constructs, and no warnings beyond the expected
PNR_SDC_FILE warnings from OpenLane.

### End-to-End Co-Simulation
The `tb_top.sv` testbench passed all 5 tests (5/5 PASS, OVERALL: PASS)
demonstrating complete end-to-end data flow from the host through the
AXI4-Stream slave interface, through all four pipeline stages of the
compute core, and back to the host through the AXI4-Stream master
interface. The testbench used only AXI4-Stream ports — no direct access
to compute core internals — confirming the integration is correct.

Test 1 verified TREADY handshake after reset. Test 2 sent four Q,K,V
triples representing a subset of the HEAD_DIM=64 attention computation
from M1 profiling. Test 3 verified the result was returned correctly
through the master interface. Test 4 verified that negative QKT scores
are clipped to zero by the ReLU softmax approximation stage. Test 5
verified synchronous reset behavior clears the interface correctly.

### OpenLane Synthesis
OpenLane 1.1.1 synthesis with Sky130A PDK at 4.0 ns clock period
(250 MHz target) completed successfully with 0 problems reported.

**AREA_0 strategy results:**
- Total cells: 2,500
- Chip area: 25,097.82 µm²
- Critical path delay: 2,295.0 ps
- Worst-case slack: +1,705 ps (PASSING at 250 MHz)
- Flip-flops: 182 (dfxtp_2)
- Problems: 0

**DELAY_0 strategy results:**
- Total cells: 3,289
- Chip area: 29,630.92 µm²
- Critical path delay: 3,107.0 ps
- Worst-case slack: +893 ps (PASSING at 250 MHz)
- Flip-flops: 182 (dfxtp_2)

Both strategies pass timing at 250 MHz, confirming the design is
synthesis-ready for the target clock frequency.

The increase from 149 flip-flops in CF07 (compute_core only) to 182
flip-flops in M3 (top = interface + compute_core) is expected. The 33
additional flip-flops correspond to the output result register and
valid/control signals in the `interface_axi4s` module.

---

## What Did Not Work

### OpenLane 2 Installation
OpenLane 2 pip installation failed on Windows due to a missing
Microsoft C++ Build Tools dependency required by the klayout package.
The error was: "error: Microsoft Visual C++ 14.0 or greater is
required." OpenLane 1.1.1 was used as an approved substitute (professor
approved for both CF07 and M3). OpenLane 1 uses the same Yosys and
OpenSTA synthesis backend as OpenLane 2, so the synthesis results are
equivalent for the synthesis-only flow.

### Power Estimation
Full power estimation was not achieved in M3 because OpenLane 1
synthesis exploration does not run OpenSTA power analysis — that
requires a placed and routed netlist from the full PnR flow. A static
power estimate of approximately 10.1 mW dynamic power was computed
analytically based on Sky130A cell characterization data. Full power
estimation will be attempted in M4 using the OpenLane PnR flow.

### Waveform Annotation
The ModelSim waveform shows all AXI4-Stream signals correctly but
signal names are truncated in the display due to the long hierarchical
path names. Signal renaming was performed using ModelSim's Properties
dialog to make the waveform readable.

---

## Scope Status

The project scope remains unchanged from M1 and M2. The full scaled
dot-product attention pipeline — QKᵀ dot product, scaling by 1/√d_k,
ReLU-based softmax approximation, and AV weighted sum — is implemented
in hardware with INT8 inputs and 32-bit accumulation, connected via an
AXI4-Stream interface.

The synthesis result at 250 MHz with +1,705 ps positive slack confirms
the design is feasible at the target clock frequency. The chip area of
25,097.82 µm² is reasonable for this level of pipeline complexity.

For M4, the following remain to be completed:
1. Power estimation via OpenLane PnR flow
2. Benchmark comparison against the M1 software baseline
3. Final roofline plot with measured accelerator performance point
4. Design justification report (9 sections, 2000-5000 words)

The M1 software baseline of 18.55 samples/sec on the AMD Ryzen 7 8840HS
CPU will be compared against the hardware accelerator throughput
estimated from the synthesis results: at 250 MHz with a HEAD_DIM=64
pipeline latency of 67 cycles, the accelerator produces one attention
output every 268 ns, giving a theoretical throughput significantly
exceeding the software baseline.