# Hardware Accelerator for Transformer Self-Attention Inference
## ECE 510 — Hardware for Artificial Intelligence and Machine Learning
## Spring 2026 | Sri Chandana Reddy Vanukuri | Portland State University

---

## M4 Final Submission

This repository contains the complete M4 final submission for a custom hardware accelerator targeting transformer self-attention inference.

**Design justification report (PDF):**
[project/m4/report/design_justification.pdf](project/m4/report/design_justification.pdf)

**M4 deliverables folder:**
[project/m4/](project/m4/)

**Submission tag:** `m4-submission`

---

## Project Summary

Transformer self-attention consumes 74.5% of CPU inference runtime, running at 133.43 samples/sec on an AMD Ryzen 7 8840HS. The accelerator uses INT8 precision to increase arithmetic intensity from 10.67 to 42.7 FLOP/byte, shifting the kernel from memory-bound to compute-bound.

The design implements a 4-stage pipeline — QKT MAC, scale, ReLU softmax, and AV weighted sum — connected via AXI4-Stream on the open-source Sky130A 130nm PDK.

---

## Key Results

| Metric | Value |
|--------|-------|
| Simulation | 5/5 PASS |
| Clock (synthesis) | 250 MHz — WNS = +961 ps ✅ |
| Clock (post-routing) | 70.4 MHz — WNS = -4.14 ns |
| Power | 5.50 mW (OpenSTA post-PnR) |
| DRC / LVS | 0 / 0 ✅ |
| GDSII | Generated ✅ |
| Measured speedup (dk=4) | 36,030× (MEASURED) |
| Projected speedup (dk=64) | 9,607× (PROJECTED) |

---

## Repository Structure

| Folder | Description |
|--------|-------------|
| `project/m1/` | SW profiling, roofline, interface selection |
| `project/m2/` | RTL design, module-level verification |
| `project/m3/` | Integration, full PnR, timing optimization |
| `project/m4/` | **M4 final submission** |
| `project/m4/rtl/` | SystemVerilog source files |
| `project/m4/tb/` | Testbench |
| `project/m4/sim/` | Simulation logs and waveforms |
| `project/m4/synth/` | OpenLane synthesis and PnR reports |
| `project/m4/bench/` | Benchmark results and roofline |
| `project/m4/report/` | Design justification PDF and figures |
| `codefest/` | Weekly codefest deliverables (CF01-CF09) |

---

## GitHub

**Repository:** https://github.com/vanukurichandana/Hardware-for-AI-ML

**Submission tag:** `m4-submission`