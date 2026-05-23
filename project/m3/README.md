# Milestone 3 — Hardware Accelerator for Transformer Self-Attention Inference
## ECE 510 Spring 2026 | Sri Chandana Reddy Vanukuri

---

## File Catalog

| File | Description |
|------|-------------|
| `rtl/top.sv` | Integrated top module — instantiates interface_axi4s and compute_core |
| `rtl/compute_core.sv` | Top-level attention pipeline (copied from M2, unchanged) |
| `rtl/interface.sv` | AXI4-Stream interface module (copied from M2, unchanged) |
| `rtl/mac_unit.sv` | Stage 1: QKᵀ MAC unit (copied from M2, unchanged) |
| `rtl/scale_unit.sv` | Stage 2: fixed-point scaling unit (copied from M2, unchanged) |
| `rtl/relu_approx.sv` | Stage 3: ReLU softmax approximation (copied from M2, unchanged) |
| `rtl/av_unit.sv` | Stage 4: AV weighted sum unit (copied from M2, unchanged) |
| `tb/tb_top.sv` | End-to-end co-simulation testbench — AXI4-Stream only |
| `sim/cosim_run.log` | Co-simulation transcript — 5/5 PASS, OVERALL: PASS |
| `sim/cosim_waveform.png` | ModelSim waveform — HOST→DUT and DUT→HOST transactions |
| `synth/config.json` | OpenLane synthesis configuration — 4.0 ns clock, Sky130A |
| `synth/openlane_run.log` | Full OpenLane stdout/stderr from synthesis run |
| `synth/area_report.txt` | Area report — 2500 cells, 25097.82 µm² (AREA_0 strategy) |
| `synth/timing_report.txt` | Timing report — 3289 cells, DELAY_0 strategy cell breakdown |
| `synth/power_report.txt` | Power estimation — ~10.1 mW estimated, full PnR planned for M4 |
| `synth/critical_path.md` | Critical path identification — start/end/logic stages explained |
| `synth/0-exploration_analysis.html` | OpenLane synthesis exploration report |
| `synth/0-synthesis.AREA_0.chk.rpt` | Synthesis check report — 0 problems |
| `synth/0-synthesis_dff.stat` | Flip-flop statistics — 182 dfxtp_2 cells |
| `synthesis_notes.md` | Narrative — what worked, what did not, scope status (≥500 words) |

---

## How to Reproduce Co-Simulation

**Simulator:** ModelSim - Intel FPGA Edition 10.5b (Compiler 2016.10)

```
vlib work
cd "project/m3"
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

Expected output: `OVERALL: PASS` (5/5 tests)

---

## How to Reproduce Synthesis

**Tool:** OpenLane 1.1.1 (efabless/openlane Docker image)
**PDK:** Sky130A (bdc9412b3e468c102d01b7cf6337be06ec6e9c9a)
**Note:** OpenLane 2 pip install failed on Windows (klayout C++ dependency).
OpenLane 1 approved by professor as substitute. Same Yosys/OpenSTA backend.

```powershell
# Pull PDK (one time)
docker run --rm -v "openlane_pdk:/root/.volare" efabless/openlane:latest `
  sh -c "python3 -m volare fetch --pdk sky130 bdc9412b3e468c102d01b7cf6337be06ec6e9c9a"

# Run synthesis
docker run --rm -v "${PWD}/project/m3:/design" -v "openlane_pdk:/root/.volare" `
  efabless/openlane:latest `
  sh -c "cd /openlane1 && ./flow.tcl -design /design -tag synth_run -synth_explore"
```

Reports generated at: `project/m3/runs/synth_run/reports/synthesis/`

---

## Deviations from M2

All M2 RTL files are copied unchanged into `project/m3/rtl/`. No modifications
were made to any M2 module. The new file is `top.sv` which instantiates
`interface_axi4s` as the single top-level component. No glue logic was
required between the interface and compute core since `interface_axi4s`
already instantiates `compute_core` internally with direct port connections.

The clock target was tightened from 10.0 ns (CF07) to 4.0 ns (250 MHz) for
M3 as planned in the CF07 m3_plan.md. Both AREA_0 and DELAY_0 strategies
pass timing at 250 MHz with positive slack.