## Partition Rationale

## Project: Hardware Accelerator for Transformer Self-Attention Inference

---

## (a) Which Kernel(s) to Accelerate in Hardware — Roofline Justification

The kernel selected for hardware acceleration is the **scaled dot-product attention core**, specifically the Q × Kᵀ matrix multiplication and the Attention × V computation. From profiling results, the `run_attention` function takes a cumulative time of **0.539 seconds across 10 runs**, indicating that these matrix multiplication operations dominate execution time.

These kernels are computationally intensive and involve repeated multiply-and-accumulate (MAC) operations. For the given configuration (T = 64, d = 64), the arithmetic intensity is **10.67 FLOP/byte**.

Based on roofline analysis, this arithmetic intensity places the kernel in the **compute-bound region**, meaning performance is limited by available compute throughput rather than memory bandwidth. Therefore, accelerating these kernels using custom hardware can directly improve performance by increasing parallelism and compute efficiency.

---

## (b) What Software Will Continue to Handle

The software will handle the following components:
- Input generation and preprocessing
- Linear projections for Q, K, and V
- Softmax computation
- Control and sequencing of operations

These components involve less computational intensity or irregular operations, making them less suitable for hardware acceleration compared to matrix multiplication.

---

## (c) Interface Bandwidth Requirement

For the current configuration (B = 1, T = 64, d = 64), the data movement per attention computation includes Q, K, V matrices and output tensors.

Total data transferred per run:

- Q = 64 × 64 × 4 bytes = 16,384 bytes  
- K = 64 × 64 × 4 bytes = 16,384 bytes  
- V = 64 × 64 × 4 bytes = 16,384 bytes  
- Output = 64 × 64 × 4 bytes = 16,384 bytes  

Total ≈ **65,536 bytes per run**

Using the measured execution time (0.0539 seconds per run):

Required bandwidth:

Required BW = 65,536 / 0.0539 ≈ **1.21 MB/s**

The chosen interface is **AXI4-Stream** with:
- 256-bit data width
- 250 MHz clock frequency

Provided bandwidth:

Bandwidth = 256 bits × 250 MHz  
= 64 Gbit/s  
= **8 GB/s**

Since the available bandwidth (8 GB/s) is significantly higher than the required bandwidth (1.21 MB/s), the design is **not interface-bound**.

---

## (d) Bound Classification and Expected Change with HW Design

On the current CPU platform, the kernel is **compute-bound**, as indicated by its arithmetic intensity (10.67 FLOP/byte).

The proposed hardware accelerator increases parallelism using dedicated MAC units and optimized dataflow. With improved compute throughput, the performance ceiling shifts upward.

Since the arithmetic intensity remains unchanged and is above the ridge point of the system, the kernel will **remain compute-bound** even after acceleration. This is desirable because it ensures that performance improvements come directly from increased compute capability rather than being limited by memory bandwidth.

Overall, accelerating the dominant matrix multiplication kernels is expected to significantly improve throughput and reduce execution latency.