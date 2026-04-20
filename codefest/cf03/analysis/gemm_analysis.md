GEMM Analysis: Naive vs. Tiled CUDA Kernels

Hardware: NVIDIA T4 GPU (Google Colab) | Peak FP32: 8,141 GFLOP/s | DRAM BW: 300 GB/s | Ridge: 27.1 FLOP/byte

(a) Why the Naive Kernel is Memory-Bound
The naive GEMM kernel assigns one CUDA thread per output element C[i][j]. Each thread independently reads an entire row of A (1,024 floats) and column of B from memory for every output, with no data sharing between threads. The analytical arithmetic intensity under the no-reuse DRAM model is 0.25 FLOP/byte — far below the T4 DRAM ridge point of 27.1 FLOP/byte — placing it firmly in the memory-bound region. The measured 418.4 GFLOP/s exceeds the strict DRAM ceiling of 75 GFLOP/s because T4's L2 cache (≈1,500 GB/s bandwidth) absorbs repeated row-of-A accesses across column-wise output threads. The kernel is therefore L2-bandwidth-bound: at only 5.1% of the 8,141 GFLOP/s FP32 peak, the compute units sit nearly idle, starved for data.

(b) How Tiling Reduces DRAM Traffic
The tiled kernel partitions A and B into 8×8 sub-blocks loaded into __shared__ memory once per phase. All 8 threads sharing a tile row reuse the same A tile; all 8 sharing a tile column reuse the same B tile — eliminating redundant DRAM fetches within each block. This increases arithmetic intensity by a factor of TILE=8: from 0.25 to 2.0 FLOP/byte. Total DRAM traffic decreases from 2×N³×4 bytes (naive) to 2×N²×(N/TILE)×4 bytes (tiled), an 8× reduction.

(c) Whether the Tiled Kernel Achieved the Expected Improvement
The tiled kernel measured 407.5 GFLOP/s versus 418.4 GFLOP/s for naive — a 0.97× ratio, meaning no meaningful speedup was achieved despite an 8× analytical traffic reduction. The reason is that TILE=8 is too small to eliminate the effective bandwidth bottleneck: the naive kernel already benefits from L2 cache reuse, and tiling with only 64 threads per block provides insufficient occupancy to hide DRAM latency. Both kernels converge to the same L2/DRAM bandwidth wall. The remaining bottleneck is tile size and thread occupancy: a larger tile (TILE=32) with software pipelining and double-buffering would push arithmetic intensity above both ridge points, enabling compute-bound operation approaching the 8,141 GFLOP/s peak.

