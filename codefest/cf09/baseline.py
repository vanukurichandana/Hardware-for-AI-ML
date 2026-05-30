import numpy as np
import time
import tracemalloc

# Parameters from M1
N = 512
d_k = 64
runs = 100

Q = np.random.randn(N, d_k).astype(np.float32)
K = np.random.randn(N, d_k).astype(np.float32)
V = np.random.randn(N, d_k).astype(np.float32)

tracemalloc.start()

start = time.perf_counter()
for _ in range(runs):
    scores = Q @ K.T
    scores = scores / np.sqrt(d_k)
    scores = np.exp(scores) / np.sum(np.exp(scores), axis=1, keepdims=True)
    output = scores @ V
end = time.perf_counter()

current, peak = tracemalloc.get_traced_memory()
tracemalloc.stop()

total_time = end - start
per_sample = total_time / runs * 1000
throughput = runs / total_time

print(f"Total time     : {total_time:.4f} s")
print(f"Per sample     : {per_sample:.4f} ms")
print(f"Throughput     : {throughput:.2f} samples/sec")
print(f"Peak memory    : {peak/1024:.2f} KB")