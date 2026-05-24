# Milestone 3 — Hardware Accelerator for Transformer Self-Attention Inference
## ECE 510 Spring 2026 | Sri Chandana Reddy Vanukuri

---

## File Catalog

| File | Description |
|------|-------------|
| `rtl/top.sv` | Integrated top module — instantiates interface_axi4s and compute_core |
| `rtl/compute_core.sv` | Top-level attention pipeline — instantiates 4 submodules (copied from M2) |
| `rtl/interface.sv` | AXI4-Stream interface module (copied from M2, unchanged) |
| `rtl/mac_unit.sv` | Stage 1: QKᵀ MAC unit (copied from M2, unchanged) |
| `rtl/scale_unit.sv` | Stage 2: fixed-point scaling unit (copied from M2, unchanged) |
| `rtl/relu_approx.sv` | Stage 3: ReLU softmax approximation (copied from M2, unchanged) |
| `rtl/av_unit.sv` | Stage 4: AV weighted sum — M3 update: pipelined for 250 MHz timing |
| `tb/tb_top.sv` | End-to-end co-simulation testbench — AXI4-Stream ports only, no direct core access |
| `sim/cosim_run.log` | Co-simulation transcript — 5/5 PASS, OVERALL: PASS |
| `sim/cosim_waveform.png` | ModelSim waveform — HOST→DUT write and DUT→HOST read transactions annotated |
| `synth/config.json` | OpenLane synthesis configuration — 4.0 ns clock (250 MHz), Sky130A PDK |
| `synth/openlane_run.log` | Full OpenLane stdout/stderr from synthesis exploration run |
| `synth/area_report.txt` | Area report — AREA_0 strategy: 2500+ cells, chip area from synthesis |
| `synth/timing_report.txt` | Timing report — DELAY_0 strategy cell breakdown |
| `synth/power_report.txt` | Power report — 5.18 mW typical from full PnR OpenSTA analysis |
| `synth/metrics.csv` | OpenLane full PnR metrics — real power, timing, area, wire length |
| `synth/critical_path.md` | Critical path — start/end registers, logic stages, fix applied in M3 |
| `synth/0-exploration_analysis.html` | OpenLane synthesis exploration HTML report |
| `synth/0-synthesis.AREA_0.chk.rpt` | Synthesis check — 0 problems |
| `synth/0-synthesis_dff.stat` | Flip-flop statistics |
| `synth/full_run.log` | Full OpenLane PnR run log — 44 steps, DRC clean, power analysis |
| `synth/timing_report_pnr.txt` | Post-PnR STA timing report from OpenSTA multi-corner analysis |
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
# Step 1 — Pull PDK (one time only)
docker run --rm -v "openlane_pdk:/root/.volare" efabless/openlane:latest `
  sh -c "python3 -m volare fetch --pdk sky130 bdc9412b3e468c102d01b7cf6337be06ec6e9c9a"

# Step 2 — Run synthesis exploration
docker run --rm -v "${PWD}/project/m3:/design" -v "openlane_pdk:/root/.volare" `
  efabless/openlane:latest `
  sh -c "cd /openlane1 && ./flow.tcl -design /design -tag synth_run -synth_explore"

# Step 3 — Run full PnR (for power report)
docker run --rm -v "${PWD}/project/m3:/design" -v "openlane_pdk:/root/.volare" `
  efabless/openlane:latest `
  sh -c "cd /openlane1 && ./flow.tcl -design /design -tag full_run"
```

---

## Key Results Summary

| Metric | Value |
|--------|-------|
| Co-simulation | 5/5 PASS |
| Synthesis strategy | AREA_0 (Sky130A) |
| Clock target | 4.0 ns (250 MHz) |
| Critical path | 3039 ps |
| Worst-case slack | +961 ps (PASSING) ✅ |
| Total cells | 2,500+ |
| Chip area | ~25,097 µm² |
| Total power (typical) | 5.18 mW |
| DRC violations | 0 |
| LVS errors | 0 |

---

## Deviations from M2

All M2 RTL files copied to `project/m3/rtl/`. One file was updated:

**`av_unit.sv` — pipelined for 250 MHz:**
The original M2 av_unit performed 32-bit × 32-bit multiply + right
shift + accumulate in one always_ff block. Full PnR showed this
created a 4.79 ns critical path (WNS = -3.52 ns at 250 MHz). An
intermediate pipeline register was added between the multiply and
accumulate stages, splitting the computation into two cycles. This
reduced the critical path to 3039 ps giving +961 ps slack at 250 MHz.
All other M2 modules are unchanged.