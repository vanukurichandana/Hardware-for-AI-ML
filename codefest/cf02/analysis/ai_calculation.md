# Arithmetic Intensity Calculation

Dominant Kernel: Matrix multiplication in transformer self-attention

From profiling, `run_attention` is the dominant application-level function, with a cumulative time of 0.539 s across 10 calls. Within this function, the dominant computations are the matrix multiplications used for:
- Q × K^T
- Attention × V

For the current software baseline:
- Batch size, B = 1
- Sequence length, T = 64
- Model dimension, d = 64
- Data type = FP32 = 4 bytes per element

## 1. FLOPs for one dominant matrix multiplication: Q × K^T

Q has shape (B, T, d) and K^T has shape (B, d, T).

For matrix multiplication, FLOPs = 2 × B × T × T × d

Substituting values:

FLOPs = 2 × 1 × 64 × 64 × 64  
FLOPs = 524,288

## 2. Bytes transferred for Q × K^T

Assuming all operands are loaded from DRAM with no reuse:

- Read Q: B × T × d × 4 bytes
- Read K: B × T × d × 4 bytes
- Write scores: B × T × T × 4 bytes

Substituting values:

- Q bytes = 1 × 64 × 64 × 4 = 16,384 bytes
- K bytes = 1 × 64 × 64 × 4 = 16,384 bytes
- Output bytes = 1 × 64 × 64 × 4 = 16,384 bytes

Total bytes = 16,384 + 16,384 + 16,384  
Total bytes = 49,152 bytes

## 3. Arithmetic Intensity

Arithmetic Intensity = FLOPs / Bytes

AI = 524,288 / 49,152  
AI = 10.67 FLOP/byte

## 4. Interpretation

The arithmetic intensity of the Q × K^T kernel is 10.67 FLOP/byte. This value will be used to place the software kernel on the roofline plot and to compare it against the hypothetical hardware accelerator design.

## 5. Note on the full attention function

The `run_attention` function also includes:
- three projection matrix multiplications for Q, K, and V
- softmax
- the Attention × V matrix multiplication

However, for roofline analysis, the dominant kernel is represented using one core matrix multiplication kernel, Q × K^T, since it captures the main compute pattern of scaled dot-product attention.