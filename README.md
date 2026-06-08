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

```
Hardware-for-AI-ML/
├── README.md                        ← you are here
├── project/
│   ├── m1/                          ← SW profiling, roofline, interface selection
│   ├── m2/                          ← RTL design, module-level verification
│   ├── m3/                          ← Integration, full PnR, timing optimization
│   └── m4/                          ← M4 FINAL SUBMISSION
│       ├── README.md                ← M4 file catalog
│       ├── rtl/                     ← SystemVerilog source files
│       │   ├── top.sv
│       │   ├── compute_core.sv
│       │   ├── interface.sv
│       │   ├── mac_unit.sv
│       │   ├── scale_unit.sv
│       │   ├── relu_approx.sv
│       │   └── av_unit.sv
│       ├── tb/
│       │   └── tb_top.sv            ← End-to-end testbench
│       ├── sim/
│       │   ├── final_run.log        ← 5/5 PASS simulation log
│       │   └── final_waveform.png   ← Annotated waveform
│       ├── synth/
│       │   ├── config.json          ← OpenLane configuration
│       │   ├── timing_report.txt    ← WNS, critical path
│       │   ├── area_report.txt      ← Cell counts, area
│       │   └── power_report.txt     ← 5.50 mW OpenSTA
│       ├── bench/
│       │   ├── benchmark.md         ← SW vs HW comparison
│       │   ├── benchmark_data.csv   ← Raw measurement data
│       │   └── roofline_final.png   ← Final roofline plot
│       └── report/
│           ├── design_justification.pdf  ← 9-section report
│           └── figures/
│               ├── fig1_roofline_final.png
│               ├── fig2_dataflow_diagram.png
│               ├── fig3_block_diagram.png
│               └── fig4_final_waveform.png
└── codefest/                        ← Weekly deliverables CF01-CF09
```

---

## GitHub

**Repository:** https://github.com/vanukurichandana/Hardware-for-AI-ML

**Submission tag:** `m4-submission`