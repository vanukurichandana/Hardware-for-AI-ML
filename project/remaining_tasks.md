# Remaining Tasks Before M4
## ECE 510 Spring 2026 | Sri Chandana Reddy Vanukuri
## Last updated: May 30, 2026

---

The following three tasks are the highest-priority items remaining before
the M4 final submission. Each is stated specifically with the exact file,
metric, or module affected.

---

## Task 1 — Cycle-Accurate Benchmark via AXI4-Stream Simulation

**What:** Drive `tb_top.sv` with a full HEAD_DIM=64 sequence of Q/K/V
triples through the AXI4-Stream slave port and measure wall-clock cycles
from first TVALID assertion to last TVALID on the master port.

**Why:** The CF09 benchmark uses a projected throughput of 1,282,051
samples/sec based on pipeline stage counts. The dominant uncertainty is
AXI4-Stream handshake overhead — real TREADY/TVALID latency may reduce
throughput by 10-20%. A measured cycle count from ModelSim will replace
the projection with a verified number for the M4 report.

**File:** `project/m4/sim/final_run.log` — must show cycle count and
OVERALL: PASS from a HEAD_DIM=64 end-to-end simulation run.

---

## Task 2 — Run Full OpenLane PnR at 4.0 ns on Pipelined av_unit

**What:** Re-run the full OpenLane Place-and-Route flow (without
`-synth_explore`) on the M3 pipelined design (with the updated
`av_unit.sv`) at CLOCK_PERIOD=4.0 ns to confirm timing closure and
obtain updated post-PnR power, area, and wire length metrics.

**Why:** The M3 full PnR run used the pre-pipeline av_unit and showed
WNS = -3.52 ns. The synthesis exploration confirmed the pipelined design
closes at 250 MHz (WNS = +961 ps) but a full PnR with the updated design
is needed to verify routing does not reintroduce timing violations and to
get accurate post-routing power for the M4 power report.

**File:** `project/m4/synth/power_report.txt` — must show post-PnR
OpenSTA power at nominal corner with pipelined av_unit.

---

## Task 3 — Write 9-Section Design Justification Report PDF

**What:** Write the M4 design justification report covering all 9 required
sections: Problem and motivation, Roofline analysis, Precision and data
format, Dataflow and architecture, Hardware interface, Verification,
Synthesis results, Benchmark results, and What did not work. Report must
be 2,000-5,000 words and submitted as PDF.

**Why:** M4 is the final submission with no revision. The report is the
primary graded artifact and the basis for final exam questions. Each
section must reference specific numbers from the synthesis reports,
simulation logs, and benchmark results already committed to the repository.

**File:** `project/m4/report/design_justification.pdf` — 9 sections,
2,000-5,000 words, figures referenced by number from
`project/m4/report/figures/`.