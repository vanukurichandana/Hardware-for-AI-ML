# Software Baseline Benchmark

Project: Hardware Accelerator for Transformer Self-Attention Inference

## Platform and Configuration

- Hardware platform: AMD Ryzen 7 8840HS w/ Radeon 780M Graphics
- Operating system: Windows 11
- Python version: Python 3.14.3
- Execution device: CPU only
- Baseline algorithm: Transformer scaled dot-product self-attention
- Batch size: 1
- Sequence length: 64
- Model dimension: 64
- Data type: FP32

## Benchmark Setup

The software baseline is a NumPy-based implementation of transformer self-attention. The computation includes:
- linear projections for Q, K, and V
- Q × K^T matrix multiplication
- softmax normalization
- Attention × V matrix multiplication

The benchmark was executed for 10 runs on the CPU. Profiling results from Codefest 2 showed that the dominant runtime is associated with the self-attention computation, particularly the matrix multiplication operations inside `run_attention`.

## Execution Time

- Number of runs: 10
- Total cumulative time for `run_attention`: 0.539 s
- Average time per run: 0.0539 s

At this stage, the software baseline records the per-run execution time using the profiling output generated during Codefest 2.

## Throughput

Throughput is measured as the number of inference samples completed per second.

Throughput = 1 / execution time per run  
Throughput = 1 / 0.0539  
Throughput ≈ 18.55 samples/second

## Memory Usage

The software baseline uses FP32 tensors with the following main data structures:
- Input tensor X: 1 × 64 × 64
- Q, K, V tensors: each 1 × 64 × 64
- Attention score matrix: 1 × 64 × 64
- Output tensor: 1 × 64 × 64

This benchmark is a small functional baseline intended for algorithm profiling and roofline analysis. Peak system memory usage was not explicitly measured yet, but the tensor sizes are small and fit comfortably within CPU memory for this test configuration.

## Summary

This software baseline provides a reproducible reference point for later hardware comparison. It establishes the execution platform, timing behavior, and throughput of the transformer self-attention workload before hardware acceleration.