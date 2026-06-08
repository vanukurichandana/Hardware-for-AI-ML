# Benchmark Results — M4 Final
## Hardware Accelerator for Transformer Self-Attention Inference
## ECE 510 Spring 2026 | Sri Chandana Reddy Vanukuri

---

## Measurement Method

Two measurement methods are used and clearly distinguished:

1. **MEASURED** — cycle counts read directly from ModelSim waveform
   cursors on real signal transitions of the integrated top module
   driven via AXI4-Stream only.

2. **PROJECTED** — throughput extrapolated from measured cycle counts
   scaled to HEAD_DIM=64 operating point at 250 MHz clock.

---

## Software Baseline

**Platform:** AMD Ryzen 7 8840HS, Windows 11, Python 3.x, NumPy
**Workload:** Self-attention, N=512, HEAD_DIM=64, FP32, 100 runs
**Measurement:** Python time.perf_counter — no profiler overhead

| Metric | Value |
|--------|-------|
| Execution time per sample | 7.4947 ms |
| Throughput | 133.43 samples/sec |
| Peak memory usage | 6,470.90 KB (6.32 MB) |
| Precision | FP32 |
| Arithmetic intensity | 10.67 FLOP/byte (measured) |
| Bottleneck | Memory-bound |

---

## Hardware Accelerator — Measured (HEAD_DIM=4 test vector)

**Platform:** ModelSim Intel FPGA Edition 10.5b
**Method:** Waveform cursor measurements on real signal transitions
**Test vector:** q=[3,-2,5,1], k=[4,7,2,6], v=[2,3,1,-1] (HEAD_DIM=4)

### Measured Timing from Waveform Cursors

| Signal Event | Time (ns) |
|-------------|-----------|
| s_tvalid first HIGH | 25.761 ns |
| m_tvalid first rising edge (Test 2 result) | 115.000 ns |
| m_tvalid second rising edge (Test 4 result) | 304.750 ns |
| Total simulation time | 416.000 ns |

### Measured Results

```
First transaction latency = 115.000 - 25.761 = 89.239 ns
Cycles = 89.239 / 4.0 ns = 22.3 cycles (HEAD_DIM=4)

Total transactions in simulation = 2
Total time = 416 ns
Measured throughput = 2 / 416e-9 = 4,807,692 samples/sec (MEASURED)
```

| Metric | Value | Label |
|--------|-------|-------|
| First transaction latency | 89.239 ns | MEASURED |
| Cycles per sample (HEAD_DIM=4) | 22.3 cycles | MEASURED |
| Throughput (HEAD_DIM=4) | 4,807,692 samples/sec | MEASURED |
| Speedup vs SW baseline | 36,030× | MEASURED |

---

## Hardware Accelerator — Projected (HEAD_DIM=64 operating point)

**Method:** Cycle count extrapolated from pipeline stage analysis
**Note:** HEAD_DIM=4 testbench completes in 22.3 cycles. At HEAD_DIM=64
the pipeline accumulation stages each run 64 cycles instead of 4,
giving the full operating point projection below.

### Pipeline Cycle Count (HEAD_DIM=64)

| Stage | Cycles |
|-------|--------|
| AXI4-Stream input loading | 64 cycles |
| Stage 1: QKT MAC accumulation | 64 cycles |
| Stage 2: Scale | 1 cycle |
| Stage 3: ReLU softmax | 1 cycle |
| Stage 4A: AV multiply | 1 cycle |
| Stage 4B: AV accumulate | 64 cycles |
| **Total latency** | **195 cycles** |

```
Time per sample = 195 × 4.0 ns = 780 ns
Projected throughput = 1 / 780e-9 = 1,282,051 samples/sec (PROJECTED)
Projected speedup = 1,282,051 / 133.43 = 9,607× (PROJECTED)
```

| Metric | Value | Label |
|--------|-------|-------|
| Cycles per sample (HEAD_DIM=64) | 195 cycles | PROJECTED |
| Time per sample | 780 ns | PROJECTED |
| Throughput (HEAD_DIM=64) | 1,282,051 samples/sec | PROJECTED |
| Speedup vs SW baseline | 9,607× | PROJECTED |

---

## Combined Comparison Table

| Metric | SW Baseline | HW Measured (dk=4) | HW Projected (dk=64) |
|--------|-------------|-------------------|---------------------|
| Throughput | 133.43 samples/sec | 4,807,692 samples/sec | 1,282,051 samples/sec |
| Latency/sample | 7.4947 ms | 89.239 ns | 780 ns |
| Speedup | 1× | 36,030× (MEASURED) | 9,607× (PROJECTED) |
| Power | ~45 W (CPU) | 5.50 mW | 5.50 mW |
| Precision | FP32 | INT8 | INT8 |
| AI (FLOP/byte) | 10.67 | 42.7 | 42.7 |
| Label | Measured | MEASURED | PROJECTED |

---

## Energy Efficiency

```
SW energy/sample  = 45 W × 7.4947 ms        = 337.3 mJ
HW energy/sample  = 5.50 mW × 780 ns        = 4.29 nJ (PROJECTED)
Energy improvement = 337.3 mJ / 4.29 nJ     = ~78.6 million× (PROJECTED)
```

At conservative 5W active CPU power:
```
SW energy/sample  = 5 W × 7.4947 ms         = 37.5 mJ
Energy improvement = 37.5 mJ / 4.29 nJ      = ~8.7 million× (PROJECTED)
```

---

## Notes on Projection Uncertainties

1. AXI4-Stream handshake overhead — real TREADY/TVALID latency may
   reduce throughput by 10-20% at HEAD_DIM=64
2. Off-chip memory latency — if Q/K/V reload from DRAM each invocation,
   effective AI falls toward 10.67 FLOP/byte
3. Post-routing clock — design closes at 70.4 MHz post-routing vs
   250 MHz synthesis; at 70.4 MHz projected throughput = 360,513
   samples/sec, speedup = 2,701×