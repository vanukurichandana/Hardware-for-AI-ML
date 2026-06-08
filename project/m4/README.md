# Milestone 4 — Hardware Accelerator for Transformer Self-Attention Inference
## ECE 510 Spring 2026 | Sri Chandana Reddy Vanukuri
## Submission Tag: m4-submission

---

## Project Summary

A custom hardware accelerator for transformer scaled dot-product self-attention
inference, implemented in SystemVerilog and synthesized on the open-source
Sky130A 130nm PDK using OpenLane 1.1.1. The design implements a 4-stage INT8
pipeline connected via AXI4-Stream, achieving a measured speedup of 36,030×
over the CPU baseline at HEAD_DIM=4 and a projected speedup of 9,607× at
the full HEAD_DIM=64 operating point.

**Design justification report:**
[project/m4/report/design_justification.pdf](report/design_justification.pdf)

---

## Key Results

| Metric | Value |
|--------|-------|
| Simulation | 5/5 PASS |
| Clock target | 4.0 ns (250 MHz) |
| Critical path (synthesis) | 3,039 ps — WNS = +961 ps ✅ |
| Critical path (post-routing) | 4,510 ps — WNS = -4.14 ns |
| Achievable clock (post-routing) | 14.2 ns (70.4 MHz) |
| Die area | 0.0727 mm² |
| Wire length | 78,069 µm |
| Power (typical corner) | 5.50 mW |
| DRC violations | 0 ✅ |
| LVS errors | 0 ✅ |
| GDSII | Generated ✅ |
| SW baseline | 133.43 samples/sec |
| HW measured (dk=4) | 4,807,692 samples/sec — 36,030× (MEASURED) |
| HW projected (dk=64) | 1,282,051 samples/sec — 9,607× (PROJECTED) |

---

## File Catalog

### Source Code
| File | Description | Checklist |
|------|-------------|-----------|
| `rtl/top.sv` | Top module — instantiates interface_axi4s + compute_core | Section 2 |
| `rtl/compute_core.sv` | Full 4-stage attention pipeline | Section 2 |
| `rtl/interface.sv` | AXI4-Stream slave/master interface | Section 2 |
| `rtl/mac_unit.sv` | Stage 1: QKT MAC (INT8×INT8→32b) | Section 2 |
| `rtl/scale_unit.sv` | Stage 2: Scale by right shift >>>3 | Section 2 |
| `rtl/relu_approx.sv` | Stage 3: ReLU softmax approximation | Section 2 |
| `rtl/av_unit.sv` | Stage 4: AV sum — pipelined (M3 update) | Section 2 |
| `tb/tb_top.sv` | End-to-end testbench — AXI4-Stream only | Section 2 |

### Simulation
| File | Description | Checklist |
|------|-------------|-----------|
| `sim/final_run.log` | Final simulation log — 5/5 PASS | Section 2 |
| `sim/final_waveform.png` | ModelSim waveform — HOST→DUT and DUT→HOST | Section 2 |

### Synthesis
| File | Description | Checklist |
|------|-------------|-----------|
| `synth/config.json` | OpenLane config — 4.0 ns clock, Sky130A | Section 3 |
| `synth/openlane_run.log` | Full OpenLane synthesis log | Section 3 |
| `synth/timing_report.txt` | Timing — WNS, critical path, slack | Section 3 |
| `synth/area_report.txt` | Area — cell counts, total area | Section 3 |
| `synth/power_report.txt` | Power — 5.50 mW from OpenSTA post-PnR | Section 3 |
| `synth/metrics.csv` | Full PnR metrics — all numbers | Section 3 |
| `synth/full_run.log` | Full PnR 44-step OpenLane log | Section 3 |
| `synth/timing_report_pnr.txt` | Post-routing STA timing report | Section 3 |
| `synth/manufacturability.rpt` | DRC/LVS manufacturability report | Section 3 |

### Benchmark
| File | Description | Checklist |
|------|-------------|-----------|
| `bench/benchmark.md` | SW vs HW — measured dk=4 + projected dk=64 | Section 4 |
| `bench/benchmark_data.csv` | Raw measurements — all numbers traceable | Section 4 |
| `bench/roofline_final.png` | Final roofline — measured SW + projected HW | Section 4 |

### Report
| File | Description | Checklist |
|------|-------------|-----------|
| `report/design_justification.pdf` | 9-section design justification report | Section 5 |
| `report/figures/roofline_final.png` | Fig 1 — Roofline model | Section 5 |
| `report/figures/dataflow_diagram.png` | Fig 2 — Output-stationary dataflow | Section 5 |
| `report/figures/block_diagram.png` | Fig 3 — System block diagram | Section 5 |
| `report/figures/final_waveform.png` | Fig 4 — End-to-end waveform | Section 5 |

---

## Deviations from M3

`rtl/av_unit.sv` is the pipelined version from M3 with an intermediate
register between multiply and accumulate stages (Stage 4A and 4B). This
reduced synthesis critical path from 4.79 ns to 3039 ps, achieving
WNS = +961 ps at 250 MHz in synthesis. Post-routing critical path is
4.51 ns (WNS = -4.14 ns), closing at 70.4 MHz post-routing.

Power report updated: M4 reflects full PnR run on pipelined design —
5.50 mW typical corner (vs 5.18 mW in M3 which used pre-pipeline av_unit).

---

## How to Reproduce Simulation

**Simulator:** ModelSim Intel FPGA Edition 10.5b

```
cd project/m4
vlib work
vlog -sv rtl/mac_unit.sv
vlog -sv rtl/scale_unit.sv
vlog -sv rtl/relu_approx.sv
vlog -sv rtl/av_unit.sv
vlog -sv rtl/compute_core.sv
vlog -sv rtl/interface.sv
vlog -sv rtl/top.sv
vlog -sv tb/tb_top.sv
vsim tb_top
run -all
```

Expected: OVERALL: PASS (5/5 tests)

---

## How to Reproduce Synthesis

**Tool:** OpenLane 1.1.1 (efabless/openlane Docker)
**PDK:** Sky130A (bdc9412b3e468c102d01b7cf6337be06ec6e9c9a)
**Note:** OpenLane 2 unavailable on Windows — OpenLane 1 approved by instructor.

```powershell
copy synth\config.json config.json
docker run --rm -v "${PWD}/project/m4:/design" -v "openlane_pdk:/root/.volare" `
  efabless/openlane:latest `
  sh -c "cd /openlane1 && ./flow.tcl -design /design -tag full_run"
```