# M3 Synthesis Plan
## Codefest 7 — ECE 510 Spring 2026

**Synthesis Target: Option A — Project compute core (compute_core.sv)**

The CF07 synthesis of `synth_top` (compute_core) on Sky130A at 10.0 ns
clock period achieved a worst-case slack of +7810 ps (AREA_0 strategy),
confirming the design meets timing comfortably with significant margin.
Total cell area is 23,189.74 µm² with 2,418 cells and 149 flip-flops.

For M3, the clock period will be tightened to 4.0 ns (250 MHz) to match
the target AXI4-Stream interface frequency of 250 MHz stated in M1.
The current critical path delay of 2190 ps leaves headroom for this
target. If timing violations appear at 4.0 ns, the av_unit multiplication
will be pipelined by adding an intermediate register between the multiply
and accumulate operations, splitting the 32-bit × 32-bit multiply across
two cycles. The design will be kept at INT8 precision as the synthesis
shows no area or timing issues that would require precision reduction.
No unrolling changes are needed — the always_comb MAC loop synthesized
cleanly with 0 problems reported.