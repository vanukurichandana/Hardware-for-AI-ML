\# Heilmeier Draft



\## Q1. What are you trying to do?

I am designing a hardware accelerator for transformer self-attention inference. The goal is to speed up the most computationally expensive part of transformer inference, especially the matrix operations used in scaled dot-product attention. This project focuses on accelerating the self-attention stage so that transformer-based models can run more efficiently with lower latency and better energy efficiency.



\## Q2. How is it done today, and what are the limits of current practice?

Today, transformer inference is usually executed on CPUs, GPUs, or cloud-based hardware platforms. These systems provide high compute capability, but self-attention involves expensive matrix multiplications and memory movement, especially as sequence length increases. This leads to higher latency, larger power consumption, and reduced efficiency for resource-constrained or edge-oriented deployments. In practice, general-purpose processors are not optimized specifically for the dataflow and reuse patterns of self-attention, so performance is often limited by both compute cost and memory bandwidth.



\## Q3. What is new in your approach and why do you think it will be successful?

My approach is to design a specialized hardware accelerator for transformer self-attention inference, with emphasis on the dominant kernels in scaled dot-product attention such as Q × K^T and attention-weighted multiplication with V. By using a hardware architecture tailored for these operations, along with parallel computation and efficient on-chip data movement, the design can reduce unnecessary memory traffic and improve throughput. I believe this approach will be successful because self-attention has a structured computation pattern that is well suited to hardware acceleration, making it possible to achieve better performance and efficiency than a software-only baseline on general-purpose platforms.

