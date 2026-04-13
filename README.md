# Hardware for AI/ML

**Name:** SRI CHANDANA REDDY VANUKURI  
**Course:** ECE 410/510 Spring 2026  
**Project Topic:** Hardware Acceleration of Transformer Self-Attention Inference

---

This project focuses on designing a hardware accelerator for transformer self-attention inference. The design targets the most computationally intensive part of transformer models, specifically the scaled dot-product attention mechanism.

The core operations involve matrix multiplications such as Q × Kᵀ and attention-weighted multiplication with V, which are widely used in modern AI workloads. These operations are implemented using parallel multiply-and-accumulate (MAC) units to improve computational efficiency.

The goal is to achieve better performance compared to software implementations by leveraging a custom hardware architecture optimized for self-attention dataflow. This accelerator aims to reduce latency and improve energy efficiency, making transformer-based models more suitable for edge and resource-constrained environments.

The accelerator will interface with a host system using AXI4-Lite for control and configuration, while efficiently handling data movement between memory and compute units.