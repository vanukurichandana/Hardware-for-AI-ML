# Critical Path Analysis
## M3 Synthesis — top module (Sky130A, 4.0 ns clock)
## Tool: OpenLane 1.1.1 | Strategy: AREA_0

---

## Critical Path Identification

**Clock period:** 4.0 ns (250 MHz target)
**Best critical path delay (AREA_0):** 2295.0 ps
**Worst-case slack:** 4000 - 2295 = **+1705 ps (PASSING)**

---

## Critical Path Description

**Start point:** `u_interface.u_compute_core.u_mac.product_reg[15]`
The critical path originates from the output flip-flop of the MAC unit
Stage 1 (`mac_unit`), specifically the most-significant bit of the
16-bit signed product register `product_reg`. This register holds the
result of the INT8 × INT8 multiplication (q_in × k_in) latched on the
previous clock edge.

**End point:** `u_interface.u_compute_core.u_av.av_accum[31]`
The path terminates at the most-significant bit of the 32-bit
accumulator register `av_accum` in the AV unit (`av_unit`), Stage 4
of the pipeline. This register accumulates the weighted sum of V
elements multiplied by the attention weight from the ReLU stage.

**Logic stages along the path:**
1. `product_reg[15]` (mac_unit) → sign extension logic (XNOR/XOR chain)
2. Sign-extended product → adder carry chain in `qk_accum` (mac_unit)
3. `qk_accum` → arithmetic right shift by 3 (scale_unit, NAND/NOR tree)
4. Scaled value → ReLU comparison (relu_approx, sign bit check + MUX)
5. ReLU output → multiplier input (av_unit, 32-bit × 32-bit)
6. Multiplier output → right shift + accumulator adder → `av_accum[31]`

**Dominant cell types on path:**
- `xnor2_2` (251 instances) — sign extension and comparison logic
- `nand2_2` (239 instances) — carry-chain adder logic
- `or2_2` (156 instances) — accumulator logic
- `mux2_2` (60 instances) — ReLU select and pipeline registers

---

## Why This Is the Critical Path

The path from `product_reg` through all four pipeline stages to
`av_accum` is the longest because it traverses the full depth of the
attention pipeline combinationally within a single clock cycle at the
AV unit stage. The `av_unit` performs a 32-bit × 32-bit multiplication
(relu_out × v_extended) followed by an arithmetic right shift and
addition to the accumulator — all in one cycle. This multiplication is
the dominant delay contributor, generating a deep carry chain that the
synthesizer maps to a Wallace tree structure using XOR and NAND cells.

---

## What Would Shorten the Critical Path

Adding an intermediate pipeline register inside `av_unit` between the
multiplication and the accumulation would split this path into two
shorter paths, each fitting comfortably within 4.0 ns. Specifically,
registering the product `(relu_out * v_extended)` before the right
shift and accumulation would reduce the critical path to approximately
1500 ps, providing +2500 ps of slack at 250 MHz. This optimization is
planned for M4 if timing becomes critical at the final clock target.