# HW/SW Partition Proposal
## Project: Hardware Accelerator for Transformer Self-Attention Inference

---

## (a) Which Kernel(s) to Accelerate in Hardware — Roofline Justification

The kernel selected for hardware acceleration is the **scaled dot-product attention core**: specifically the QKᵀ matrix multiplication and the AV attention-weighted sum. These two operations consume 74.5% of total runtime and scale quadratically with sequence length (O(T²·d)), making them the clear performance bottleneck.

On the target software platform (Apple M2 Pro, peak compute ≈ 3,600 GFLOP/s, peak memory bandwidth ≈ 200 GB/s, ridge point = 18.0 FLOP/byte), the dominant kernel sits at an arithmetic intensity of **42.67 FLOP/byte** — above the ridge point, placing it in the **compute-bound** region. The attainable performance is capped at 3,600 GFLOP/s, which is the full peak. However, this ceiling is a hardware peak, not what is actually achieved in NumPy: the measured throughput is far below peak due to Python overhead, lack of SIMD utilization in loop control paths, and poor memory locality across the multi-head loop structure.

The roofline analysis therefore supports acceleration on two grounds: (1) the kernel is already theoretically compute-bound, meaning a higher-throughput compute engine directly improves attainable performance, and (2) the NumPy baseline cannot approach the theoretical ceiling, so a custom datapath with fused multiply-accumulate units and tiled execution will unlock the headroom.

---

## (b) What Software Will Continue to Handle

The software baseline retains responsibility for: tokenization and embedding lookup, positional encoding, layer normalization, feed-forward sublayer (two dense projections with GeLU), output linear projection and vocabulary softmax for language model heads, and the overall inference orchestration (batching, KV-cache management, scheduling). These operations either have lower arithmetic intensity (e.g., layer norm is memory-bound and not on the critical path for long sequences), or their structure is irregular enough that hardware acceleration offers diminishing returns relative to implementation complexity.

---

## (c) Interface Bandwidth Requirement

At a target throughput of 100 inference sequences per second (T=512, d=512), the accelerator must move approximately **12.58 MB of data** (Q, K, V matrices and output) per sequence:

```
Required BW = 100 seq/s × 12,582,912 bytes/seq = 1,258,291,200 bytes/s ≈ 1.26 GB/s
```

**AXI4 Stream** (512-bit wide at 250 MHz) provides approximately **16 GB/s** of sustained throughput — more than 12× the required bandwidth. This ensures the accelerator will **not** be interface-bound at the target operating point. PCIe 4.0 x4 (8 GB/s rated) would also be sufficient. AXI4 Stream is preferred here because it is well-suited for streaming matrix data with minimal protocol overhead, integrates cleanly with FPGA SoC fabric, and matches the sequential, pipelined dataflow of the attention computation.

---

## (d) Bound Classification and Expected Change with HW Design

On the current CPU platform, the kernel is theoretically **compute-bound** (AI = 42.67 FLOP/byte > ridge point = 18.0 FLOP/byte). In practice, the software implementation underperforms the theoretical ceiling due to Python/NumPy overhead.

The hypothetical hardware accelerator is designed with a peak compute of **50 TFLOPS** and an on-chip SRAM bandwidth of **2 TB/s**, yielding a ridge point of **25.0 FLOP/byte**. Since the kernel's arithmetic intensity (42.67 FLOP/byte) exceeds this new ridge point, the kernel **remains compute-bound** on the accelerator as well. This is the desired outcome: it means the accelerator's compute throughput (50 TFLOPS) is the active ceiling, and the design achieves a theoretical speedup of approximately **50,000 / 3,600 ≈ 13.9×** over the CPU peak — and far greater over the measured NumPy baseline. On-chip SRAM with 2 TB/s bandwidth ensures data can be fed to the MAC array without starvation, keeping the systolic array fully utilized.

