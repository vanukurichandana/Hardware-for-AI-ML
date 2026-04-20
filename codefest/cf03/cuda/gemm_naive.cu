#include <cuda_runtime.h>
#include <iostream>

#define N 1024

__global__ void gemm_naive(const float* A, const float* B, float* C, int n) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    if (row < n && col < n) {
        float sum = 0.0f;
        for (int k = 0; k < n; k++) {
            sum += A[row * n + k] * B[k * n + col];
        }
        C[row * n + col] = sum;
    }
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

    dim3 block(16, 16);
    dim3 grid((N + block.x - 1) / block.x, (N + block.y - 1) / block.y);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    // Warm-up run (not timed)
    gemm_naive<<<grid, block>>>(d_A, d_B, d_C, N);
    cudaDeviceSynchronize();

    cudaEventRecord(start);
    gemm_naive<<<grid, block>>>(d_A, d_B, d_C, N);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms = 0.0f;
    cudaEventElapsedTime(&ms, start, stop);

    // FLOPs = 2 * N^3 (one multiply + one add per k iteration)
    // Time in seconds = ms / 1000.0
    // GFLOP/s = FLOPs / time_s / 1e9
    double flops  = 2.0 * N * N * N;
    double gflops = flops / (ms / 1000.0) / 1e9;

    // Estimated DRAM bytes: each of N^2 threads reads N floats from A + N from B, writes 1 to C
    double bytes_moved = (double)N * N * (2.0 * N + 1.0) * sizeof(float);
    double bw_gbs      = bytes_moved / (ms / 1000.0) / 1e9;

    std::cout << "=== Naive GEMM (N=" << N << ") ===" << std::endl;
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
