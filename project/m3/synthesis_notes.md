# Synthesis Notes and Scope Status
## M3 — Hardware Accelerator for Transformer Self-Attention Inference
## ECE 510 Spring 2026 | Sri Chandana Reddy Vanukuri

---

## Overview

This document describes the M3 synthesis attempt of the full transformer
self-attention accelerator, including what synthesized successfully, what
did not, what was changed, and the final scope status. The synthesis target
is the integrated `top` module connecting the AXI4-Stream interface
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
PNR_SDC_FILE warnings from OpenLane. The Verilator linter found
10 warnings but 0 errors during the full PnR run.

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

### OpenLane Synthesis — First Run (before av_unit pipeline fix)
The first synthesis exploration at 4.0 ns clock showed AREA_0 critical
path of 2295 ps with +1705 ps slack. This looked promising, but the
full PnR run revealed setup timing violations — the post-routing
critical path was 4.79 ns (WNS = -3.52 ns at 250 MHz). OpenLane
suggested a clock period of 14.0 ns (71.4 MHz) for the unmodified design.

### av_unit Pipeline Fix
Based on the timing violation analysis, the critical path was identified
as running through the av_unit 32-bit × 32-bit multiply + accumulate
in a single clock cycle. To fix this, an intermediate pipeline register
was added inside `av_unit` between the multiply and accumulate stages:

- **Stage A:** weight_in × v_extended → product_reg (registered)
- **Stage B:** product_reg >>> SCALE_SHIFT + av_accum → av_accum

This splits the long multiply-accumulate path into two shorter stages.

### OpenLane Synthesis — Second Run (after av_unit pipeline fix)
After the pipeline fix, the synthesis exploration at 4.0 ns showed:

**AREA_0 strategy results:**
- Total cells: 2,500+
- Chip area: ~25,097 µm²
- Critical path delay: 3,039 ps
- Worst-case slack: **+961 ps (PASSING at 250 MHz)** ✅
- Flip-flops: 182+ (dfxtp_2)
- Problems: 0

The design now passes timing at 250 MHz with the pipelined av_unit.

### Full PnR Power Analysis
The full Place-and-Route flow was run to obtain a real power estimate.
The flow completed all 44 steps including synthesis, floorplanning,
placement, clock tree synthesis, routing, SPEF extraction, multi-corner
STA, DRC, LVS, and GDSII generation. Key results:

- **Total power (typical corner): 5.18 mW**
  - Internal: 3.40 mW
  - Switching: 1.78 mW
  - Leakage: 0.015 µW
- **DRC violations: 0** ✅
- **LVS errors: 0** ✅
- **Die area: 0.0578 mm²**
- **Wire length: 53,156 µm**

---

## What Did Not Work

### OpenLane 2 Installation
OpenLane 2 pip installation failed on Windows due to missing Microsoft
C++ Build Tools required by the klayout dependency. Error: "Microsoft
Visual C++ 14.0 or greater is required." OpenLane 1.1.1 was used as
an approved substitute (professor approved). OpenLane 1 uses the same
Yosys and OpenSTA backend as OpenLane 2.

### Initial Timing Violation at 250 MHz
The original M2 av_unit design failed timing at 250 MHz after full PnR.
The worst negative slack was -3.52 ns and OpenLane suggested 71.4 MHz
as the achievable clock frequency. The root cause was the 32-bit × 32-bit
multiply + right shift + accumulate all in one clock cycle inside av_unit,
creating a critical path of 4.79 ns post-routing.

### True Softmax
True hardware softmax was considered during M2 design but rejected because
it requires exp() and division circuits that are not efficiently
synthesizable in standard cell libraries. The ReLU approximation
(max(0,x)) was used instead — it clips negative attention scores to zero
and is synthesizable in a single clock cycle. This approximation
introduces some error compared to true softmax but the relative ordering
of positive attention weights is preserved.

---

## Scope Status

The project scope remains the full scaled dot-product attention pipeline
with INT8 inputs and 32-bit accumulation, connected via AXI4-Stream.
The one design change from M2 to M3 is the pipelining of av_unit to
meet 250 MHz timing — this does not change the functional scope, only
adds one extra pipeline stage to the AV computation.

The full PnR results confirm the design is physically realizable:
0 DRC violations, 0 LVS errors, and a real power estimate of 5.18 mW.
The timing now passes at 250 MHz with +961 ps slack.

For M4, the following remain:
1. Benchmark comparison against M1 software baseline (18.55 samples/sec)
2. Final roofline plot with measured accelerator performance point
3. Design justification report (9 sections, 2000-5000 words)

The M1 software baseline of 18.55 samples/sec on AMD Ryzen 7 8840HS
will be compared against the hardware accelerator throughput. At 250 MHz
with HEAD_DIM=64 pipeline latency of 68 cycles (one extra cycle from
av_unit pipeline), the accelerator produces one attention output every
272 ns, giving a theoretical throughput significantly exceeding the
software baseline.