# Project Scope Assessment
## Hardware Accelerator for Transformer Self-Attention Inference
## ECE 510 Spring 2026 | Sri Chandana Reddy Vanukuri

---

## Current Scope

The project implements the full scaled dot-product attention pipeline
in synthesizable SystemVerilog, consisting of four pipelined stages:

1. **mac_unit** — QKᵀ dot product (INT8 × INT8 → 32-bit accumulator)
2. **scale_unit** — Fixed-point scaling by 1/√d_k (arithmetic right shift)
3. **relu_approx** — Softmax approximation (ReLU clips negative scores)
4. **av_unit** — AV weighted sum (attention weight × V element)

The compute core is connected to the host via an AXI4-Stream interface
(interface_axi4s) with TVALID/TREADY handshaking.

---

## Synthesis Results (CF07)

OpenLane 1.1.1 synthesis on Sky130A PDK at 10.0 ns clock period:

| Metric | AREA_0 | DELAY_0 |
|--------|--------|---------|
| Total cells | 2,418 | 3,239 |
| Chip area | 23,189.74 µm² | 32,377.30 µm² |
| Critical path | 2,190 ps | 3,090 ps |
| Slack at 10ns | +7,810 ps | +6,910 ps |
| Flip-flops | 149 | 149 |
| Problems | 0 | 0 |

---

## Scope Confirmation

The synthesis results confirm the current scope is feasible and on track
for M3. The design synthesizes cleanly with 0 problems, meets timing at
100 MHz with large positive slack (+7810 ps), and produces a reasonable
chip area of 23,189.74 µm². The 149 flip-flops correctly correspond to
the four 32-bit pipeline registers in the attention pipeline.

For M3, the clock target will be tightened to 4.0 ns (250 MHz) to match
the AXI4-Stream interface frequency. The current critical path of 2190 ps
provides sufficient headroom for this target. The project scope remains
unchanged — full attention pipeline in hardware with INT8 precision and
AXI4-Stream interface. No scope reduction is needed based on the
synthesis results.

---

## M3 Readiness

- RTL: complete and verified (M2) ✅
- Synthesis: attempted and passing (CF07) ✅
- Interface: AXI4-Stream verified in testbench ✅
- Precision: INT8 with error analysis complete ✅
- Next step: tighten clock to 250 MHz for M3 synthesis