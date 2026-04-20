#include <cuda_runtime.h>
#include <iostream>

#define N    1024
#define TILE 8

__global__ void gemm_tiled(const float* A, const float* B, float* C, int n) {
    __shared__ float As[TILE][TILE];
    __shared__ float Bs[TILE][TILE];

    int row = blockIdx.y * TILE + threadIdx.y;
    int col = blockIdx.x * TILE + threadIdx.x;

    float sum = 0.0f;

    for (int t = 0; t < n / TILE; t++) {
        As[threadIdx.y][threadIdx.x] = A[row * n + (t * TILE + threadIdx.x)];
        Bs[threadIdx.y][threadIdx.x] = B[(t * TILE + threadIdx.y) * n + col];

        __syncthreads();

        for (int k = 0; k < TILE; k++) {
            sum += As[threadIdx.y][k] * Bs[k][threadIdx.x];
        }

        __syncthreads();
    }

    // Bounds check before writing output
    if (row < n && col < n)
        C[row * n + col] = sum;
}

int main() {
    size_t bytes = N * N * sizeof(float);

    float *h_A = new float[N * N];
    float *h_B = new float[N * N];
    float *h_C = new float[N * N];

    for (int i = 0; i < N * N; i++) {
        h_A[i] = 1.0f;
        h_B[i] = 1.0f;
    }

    float *d_A, *d_B, *d_C;
    cudaMalloc(&d_A, bytes);
    cudaMalloc(&d_B, bytes);
    cudaMalloc(&d_C, bytes);

    cudaMemcpy(d_A, h_A, bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, bytes, cudaMemcpyHostToDevice);

    dim3 block(TILE, TILE);
    dim3 grid(N / TILE, N / TILE);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    // Warm-up run (not timed)
    gemm_tiled<<<grid, block>>>(d_A, d_B, d_C, N);
    cudaDeviceSynchronize();

    cudaEventRecord(start);
    gemm_tiled<<<grid, block>>>(d_A, d_B, d_C, N);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms = 0.0f;
    cudaEventElapsedTime(&ms, start, stop);

    // FLOPs = 2 * N^3 (one multiply + one add per k iteration)
    // Time in seconds = ms / 1000.0
    // GFLOP/s = FLOPs / time_s / 1e9
    double flops  = 2.0 * N * N * N;
    double gflops = flops / (ms / 1000.0) / 1e9;

    // Tiled DRAM bytes: 2 * N^2 * (N/TILE) * sizeof(float)
    // Each tile loaded once per phase; TILE threads reuse it
    double bytes_moved = 2.0 * (double)N * N * ((double)N / TILE) * sizeof(float);
    double bw_gbs      = bytes_moved / (ms / 1000.0) / 1e9;

    std::cout << "=== Tiled GEMM (N=" << N << ", TILE=" << TILE << ") ===" << std::endl;
    std::cout << "Kernel time        : " << ms       << " ms"      << std::endl;
    std::cout << "Achieved GFLOP/s   : " << gflops   << " GFLOP/s" << std::endl;
    std::cout << "Est. DRAM bandwidth: " << bw_gbs   << " GB/s"    << std::endl;
    std::cout << "Arith. intensity   : "
              << flops / bytes_moved << " FLOP/byte" << std::endl;

    cudaMemcpy(h_C, d_C, bytes, cudaMemcpyDeviceToHost);

    cudaFree(d_A); cudaFree(d_B); cudaFree(d_C);
    delete[] h_A; delete[] h_B; delete[] h_C;

    return 0;
}
