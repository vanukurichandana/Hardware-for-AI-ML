# Interface Selection

Project: Hardware Accelerator for Transformer Self-Attention Inference

## Selected Interface

The selected interface for this project is **AXI4-Stream**.

AXI4-Stream is chosen because the dominant kernel in this project is matrix multiplication within transformer self-attention, specifically Q × K^T and Attention × V. These operations require continuous movement of input activations, intermediate data, and output tensors between the host memory system and the accelerator. Compared to control-oriented interfaces, AXI4-Stream is better suited for high-throughput data transfer.

## Host Platform Assumption

The assumed host platform is an **FPGA SoC-based system** in which a processor configures the accelerator and streams data to and from the compute engine.

## Target Operating Point

For the hypothetical hardware accelerator, assume a target compute throughput of:

- **64 GFLOP/s**

From the arithmetic intensity calculation:

- **Arithmetic intensity = 10.67 FLOP/byte**

The required memory/interface bandwidth to sustain this throughput is:

Required bandwidth = Throughput / Arithmetic Intensity

Required bandwidth = 64 GFLOP/s / 10.67 FLOP/byte  
Required bandwidth ≈ 6.0 GB/s

## Interface Bandwidth Assumption

Assume an AXI4-Stream implementation with:

- **256-bit data width**
- **250 MHz clock frequency**

Bandwidth = Data width × Frequency

Bandwidth = 256 bits × 250 MHz  
Bandwidth = 64 Gbit/s  
Bandwidth = 8 GB/s

## Bandwidth Comparison

- **Required bandwidth:** 6.0 GB/s
- **Available AXI4-Stream bandwidth:** 8.0 GB/s

Since the available interface bandwidth is greater than the required bandwidth, the design is **not interface-bound** at the chosen target operating point.

## Conclusion

AXI4-Stream is an appropriate interface for this design because it supports efficient high-throughput data transfer between the host and the self-attention accelerator. At the assumed 256-bit, 250 MHz configuration, the available 8 GB/s bandwidth is sufficient to support the target throughput of 64 GFLOP/s without making the interface the primary bottleneck.