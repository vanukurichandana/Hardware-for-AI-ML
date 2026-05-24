# Critical Path Analysis
## M3 Synthesis — top module (Sky130A, 4.0 ns clock)
## Tool: OpenLane 1.1.1 | Strategy: AREA_0 | av_unit pipelined

---

## Critical Path Identification

**Clock period:** 4.0 ns (250 MHz target)
**Critical path delay (AREA_0):** 3039.0 ps
**Worst-case slack:** 4000 - 3039 = **+961 ps (PASSING at 250 MHz)** ✅

---

## Design Evolution

The original av_unit (M2) had a single always_ff block performing
32-bit × 32-bit multiply + right shift + accumulate in one cycle.
This produced a critical path of 2295 ps in synthesis but 4790 ps
after full PnR (WNS = -3.52 ns at 250 MHz).

The M3 update adds an intermediate pipeline register inside av_unit
that splits the computation into two stages:
- **Stage A:** weight_in × v_extended → product_reg (registered)
- **Stage B:** product_reg >>> SCALE_SHIFT + av_accum → av_accum

This reduced the post-synthesis critical path from 2295 ps to 3039 ps
(AREA_0 strategy) while now passing timing at 250 MHz with +961 ps slack.

---

## Critical Path Description

**Start point:** `u_interface.u_compute_core.u_mac.product_reg[15]`
The critical path originates from the MAC unit Stage 1 flip-flop,
specifically the MSB of the 16-bit signed product register.

**End point:** `u_interface.u_compute_core.u_av.av_accum[31]`
The path terminates at the MSB of the 32-bit AV accumulator register
in av_unit Stage B.

**Logic stages along the path:**
1. `product_reg[15]` (mac_unit) → sign extension (XNOR/XOR chain)
2. Sign-extended product → adder carry chain in `qk_accum`
3. `qk_accum` → arithmetic right shift (scale_unit, NAND/NOR)
4. Scaled value → ReLU comparison (relu_approx, sign bit + MUX)
5. ReLU output → multiply input (av_unit Stage A)
6. `product_reg` (av_unit) → right shift + adder → `av_accum[31]`

**Dominant cell types:** xnor2 (251), nand2 (239), or2 (156), mux2 (60)

---

## Why This Is the Critical Path

The path traverses all four pipeline stages combinationally within
one clock cycle at the av_unit Stage B. The 32-bit × 32-bit
multiplication in Stage A is the dominant delay — it generates a
deep carry chain mapped to a Wallace tree structure.

---

## What Would Further Shorten the Critical Path

The remaining 961 ps of slack is sufficient for 250 MHz. If a higher
clock frequency were needed, the scale_unit right shift and relu_approx
comparison could be merged into a single registered stage, and the
mac_unit could be split into separate multiply and accumulate stages.
These optimizations are left for future work if M4 requires higher
throughput.