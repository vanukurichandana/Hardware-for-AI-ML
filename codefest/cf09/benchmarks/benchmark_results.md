# CF09 Benchmark Results
## Hardware Accelerator for Transformer Self-Attention
## ECE 510 Spring 2026 | Sri Chandana Reddy Vanukuri

---

## Software Baseline (Task 6)

**Platform:** AMD Ryzen 7 8840HS, Windows 11, Python 3.x, NumPy
**Workload:** Self-attention, N=512, HEAD_DIM=64, FP32, 100 runs
**Date:** May 30, 2026

| Metric | Value |
|--------|-------|
| Total time (100 runs) | 0.7495 s |
| Execution time per sample | 7.4947 ms |
| Throughput | 133.43 samples/sec |
| Peak memory usage | 6,470.90 KB (6.32 MB) |
| Precision | FP32 |
| Arithmetic intensity | 10.67 FLOP/byte |
| Bottleneck | Memory-bound |

---

## Hardware Accelerator (Task 7) — Projected

**Platform:** Sky130A PDK, OpenLane 1.1.1, 250 MHz clock
**Method:** Projected peak throughput from synthesis results
**Label:** PROJECTED (cycle-accurate simulation not yet available)

### Projection Method

Peak throughput is computed from synthesis cycle count:

```
Pipeline stages:
  Stage 1 — QKᵀ MAC:        64 cycles  (HEAD_DIM = 64 elements)
  Stage 2 — Scale:            1 cycle
  Stage 3 — ReLU softmax:     1 cycle
  Stage 4A — AV multiply:     1 cycle   (pipelined sub-stage)
  Stage 4B — AV accumulate:  64 cycles  (HEAD_DIM = 64 elements)
  AXI4-Stream input loading: 64 cycles  (64 Q/K/V triples)
  ──────────────────────────────────────
  Total latency:            195 cycles
```

```
Time per sample = 195 cycles × 4.0 ns = 780 ns = 0.000780 ms
Projected throughput = 1 / 0.000000780 = 1,282,051 samples/sec
```

### Projection Assumptions

1. Pipeline is fully utilized — back-to-back samples with no gaps
2. AXI4-Stream interface delivers one Q/K/V triple per clock cycle
3. No off-chip memory latency — data preloaded into interface buffer
4. No pipeline stalls from TREADY/TVALID handshake overhead
5. Clock frequency = 250 MHz (confirmed by synthesis, WNS = +961 ps)

| Metric | Value |
|--------|-------|
| Clock frequency | 250 MHz |
| Cycles per sample | 195 cycles |
| Execution time per sample | 0.780 µs (0.000780 ms) |
| **Projected throughput** | **1,282,051 samples/sec (PROJECTED)** |
| Peak memory bandwidth | 8 GB/s (AXI4-Stream 256-bit @ 250 MHz) |
| Power | 5.18 mW (from OpenSTA post-PnR) |
| Precision | INT8 inputs, 32-bit accumulator |
| Arithmetic intensity | 42.7 FLOP/byte (INT8) |
| Bottleneck | Compute-bound (projected) |

---

## Speedup and Efficiency (Task 8)

| Metric | SW Baseline | HW Accelerator | Ratio |
|--------|-------------|----------------|-------|
| Throughput | 133.43 samples/sec | 1,282,051 samples/sec (PROJECTED) | **9,607× (PROJECTED)** |
| Latency per sample | 7.4947 ms | 0.000780 ms (PROJECTED) | **9,607× (PROJECTED)** |
| Power | ~45 W (CPU TDP) | 5.18 mW | **~8,687× more efficient** |
| Precision | FP32 | INT8 | 4× less memory |
| Arithmetic intensity | 10.67 FLOP/byte | 42.7 FLOP/byte | 4× higher |
| Bottleneck | Memory-bound | Compute-bound (projected) | Shifted ✅ |

### Energy Efficiency

```
SW energy per sample = 45 W × 7.4947 ms = 337.3 mJ
HW energy per sample = 5.18 mW × 0.780 µs = 0.00404 µJ (PROJECTED)

Energy efficiency improvement = 337.3 mJ / 0.00000000404 J
                              = ~83 billion× (PROJECTED)
```

Note: CPU power is full TDP (45W). Actual CPU power for this workload
is lower — a conservative estimate of 5W gives ~10 billion× improvement.
Energy comparison is approximate and labeled PROJECTED.

---

## Notes on Projected Numbers

All HW accelerator numbers are labeled PROJECTED because:
- Cycle-accurate co-simulation (cocotb) not yet integrated
- Numbers derived from ModelSim simulation cycle counts + synthesis frequency
- Real measured numbers will be reported in M4 after full benchmark run
- The dominant uncertainty is AXI4-Stream interface overhead — real
  handshake latency may add 10-20% overhead reducing throughput