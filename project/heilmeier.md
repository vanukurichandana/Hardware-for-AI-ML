**Project: Hardware Accelerator for Transformer Self-Attention Inference**



**Question 1: What are you trying to do?**



I am designing a hardware accelerator for transformer self-attention inference. The goal is to improve the performance of the most computationally intensive part of transformer models, specifically the scaled dot-product attention mechanism. This project focuses on accelerating matrix operations such as Q × Kᵀ and attention-weighted multiplication with V to enable faster and more efficient inference.



**Question 2: How is it done today, and what are the limits of current practice?**



Currently, transformer inference is executed on CPUs, GPUs, or cloud-based systems. While these platforms provide strong computational capability, they are not optimized for the dataflow and memory access patterns of self-attention.



From profiling results of the software baseline, the function `run\_attention` takes a cumulative time of approximately 0.539 seconds across 10 runs, with an average execution time of 0.0539 seconds per run. The dominant computations within this function are matrix multiplications, specifically Q × Kᵀ and Attention × V.



These operations involve high computational complexity and repeated data movement, especially as sequence length increases. This leads to increased latency, higher energy consumption, and inefficient utilization of compute resources on general-purpose processors. As a result, deploying transformer models efficiently in edge or resource-constrained environments remains challenging.



**Question 3: What is new in your approach and why do you think it will be successful?**



My approach is to design a specialized hardware accelerator focused on the dominant operations in transformer self-attention, particularly Q × Kᵀ and attention-weighted multiplication with V. By using parallel computation and optimizing data movement within the hardware, the design can reduce memory overhead and improve throughput. This approach is expected to achieve better performance and energy efficiency compared to software-based implementations on general-purpose platforms.

