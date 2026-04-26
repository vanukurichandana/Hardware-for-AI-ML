# Hardware for AI/ML

**Name:** Sri Chandana Reddy Vanukuri
**Course:** ECE 410/510 Spring 2026
**Project:** Hardware Accelerator for Transformer Self-Attention Inference

---

## Project Overview

This project designs a hardware accelerator for transformer self-attention inference, targeting the scaled dot-product attention mechanism. The core operations — Q × Kᵀ and Attention × V — are the dominant computational bottleneck, accounting for 74.5% of total runtime in software profiling on an AMD Ryzen 7 8840HS CPU. The goal is to accelerate these operations using dedicated hardware MAC units, reducing latency and improving energy efficiency compared to general-purpose CPU execution.

---

## What the Module Does

The compute core (`attention_mac_core.sv`) implements a 2-stage pipelined MAC unit for the Q × Kᵀ dot product computation in transformer self-attention. It accepts one Q element and one K element per clock cycle, multiplies them as 8-bit signed integers, and accumulates the result into a 32-bit signed register. This produces one element of the attention score matrix per HEAD_DIM clock cycles. The module supports parameterized data width and accumulator width, uses synchronous active-high reset, and includes a valid handshake (`valid_in` / `valid_out`) for pipeline flow control.

---

## Interface

The module will expose an **AXI4-Stream** interface for data transfer between the host processor and the accelerator. AXI4-Stream is chosen because it is designed for high-throughput continuous data streaming, which matches the sequential access pattern of Q, K, and V matrix elements in self-attention. It has minimal protocol overhead per data beat compared to memory-mapped interfaces like AXI4-Lite, making it well suited for the pipelined dataflow of the MAC compute engine.

---

## Precision Plan

The chosen precision is **INT8 inputs with a 32-bit signed accumulator**. Q and K matrix elements are quantized to 8-bit signed integers before entering the compute core, while the accumulator is kept at 32 bits to prevent overflow during the dot product summation over HEAD_DIM elements. This precision choice is validated by the Codefest 4 INT8 symmetric quantization experiment, where the Mean Absolute Error was 0.004326 — well within acceptable bounds for attention score computation.

---

## Interface Bandwidth Justification

From the Milestone 1 roofline analysis, the dominant kernel (QKᵀ + AV) has an arithmetic intensity of **10.67 FLOP/byte** on the AMD Ryzen 7 8840HS CPU, placing it in the memory-bound region below the ridge point of 24.1 FLOP/byte. The hypothetical hardware accelerator targets a compute throughput of 64 GFLOP/s, which requires an interface bandwidth of 64 / 10.67 ≈ **6.0 GB/s** to avoid becoming interface-bound. An AXI4-Stream interface configured at 256-bit data width and 250 MHz clock provides approximately **8.0 GB/s** of sustained bandwidth, which exceeds the requirement by 1.33×. This confirms the accelerator will not be interface-bound at the target operating point, and AXI4-Stream has sufficient headroom to support higher throughput targets in future design iterations.
