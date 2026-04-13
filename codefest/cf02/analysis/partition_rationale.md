# Hardware-Software Partition Rationale

The transformer self-attention algorithm consists of multiple stages, including linear projections (Q, K, V), matrix multiplications (Q × K^T and Attention × V), and softmax normalization.

From profiling results, the dominant computation is matrix multiplication, specifically Q × K^T and Attention × V. These operations involve a large number of multiply-and-accumulate (MAC) operations and exhibit high computational complexity.

## Hardware Partition

The matrix multiplication operations are assigned to hardware acceleration. These kernels are highly parallelizable and compute-intensive, making them well-suited for custom hardware design. Implementing them in hardware can significantly improve throughput and reduce execution latency.

The hardware accelerator will focus on:
- Q × K^T computation
- Attention × V computation

These operations can be optimized using parallel MAC units and efficient on-chip memory to reduce data movement.

## Software Partition

The remaining components of the algorithm are executed in software. These include:
- Input preprocessing
- Linear projections (Q, K, V generation)
- Softmax computation
- Control and sequencing logic

These operations involve conditional logic and are less compute-intensive compared to matrix multiplication, making them more suitable for execution on a general-purpose processor.

## Interface Considerations

The hardware accelerator will communicate with the host processor using an AXI4-Lite interface for control and configuration. Data transfer between memory and the accelerator must be efficiently managed to avoid bandwidth bottlenecks.

## Conclusion

By offloading the dominant matrix multiplication kernels to hardware and keeping control-oriented tasks in software, the design achieves an efficient hardware-software partition. This approach improves performance while maintaining flexibility and scalability for transformer-based workloads.