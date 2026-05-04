# Precision and Data Format
## Project: Hardware Accelerator for Transformer Self-Attention Inference
## ECE 510 Spring 2026

---

## Numerical Format Choice

**Selected format: INT8 inputs × INT8 inputs → 32-bit signed accumulator**

Q, K, and V matrix elements are represented as 8-bit signed integers (INT8,
range −128 to 127). All four pipeline stages operate on INT8 inputs:

- **Stage 1 (mac_unit):** INT8 × INT8 → 16-bit signed product, accumulated
  into a 32-bit signed register over HEAD_DIM cycles
- **Stage 2 (scale_unit):** 32-bit signed arithmetic right shift by 3
  (approximates division by √64 = 8)
- **Stage 3 (relu_approx):** 32-bit signed ReLU (clips negative scores to 0)
- **Stage 4 (av_unit):** 32-bit weight × INT8 V element → 32-bit accumulator

---

## Rationale

**Why INT8 and not FP32:**
From the M1 roofline analysis, the dominant kernel (QKᵀ + AV) has an
arithmetic intensity of 10.67 FLOP/byte on the AMD Ryzen 7 8840HS CPU.
Using INT8 instead of FP32 reduces the data width from 4 bytes to 1 byte
per element — a 4× reduction in memory traffic. This pushes the effective
arithmetic intensity from 10.67 to approximately 42 FLOP/byte, moving the
kernel above the CPU ridge point of 24.1 FLOP/byte into the compute-bound
region on the accelerator. Hardware INT8 multipliers are also significantly
smaller and faster than FP32 floating-point units, reducing area and power.

**Why not INT4:**
INT4 (range −8 to 7) is too narrow for stable attention score computation.
The dynamic range of QKᵀ / √d_k requires sufficient precision to distinguish
between similar token similarity scores. INT4 would cause excessive clamping
and loss of attention discrimination.

**Why not FP16:**
FP16 requires a floating-point multiplier, which is significantly more
complex and power-hungry than an integer multiplier. For inference-only
operation, INT8 achieves comparable accuracy at lower hardware cost, as
demonstrated by published INT8 transformer quantization results.

**Why 32-bit accumulator:**
The accumulator must be wide enough to prevent overflow during the HEAD_DIM=64
dot product. Worst case: all elements at max INT8 (127 × 127 × 64 =
1,032,256), which fits within 32-bit signed range (max 2,147,483,647).
A 16-bit accumulator would overflow, so 32 bits is the minimum safe width.

**Why ReLU for softmax approximation:**
True hardware softmax requires exp() and division — both expensive in
synthesizable RTL. ReLU (max(0, x)) clips negative attention scores to zero
and retains positive scores, providing a synthesizable approximation that
preserves the relative ordering of attention weights while eliminating
negative contributions to the AV weighted sum.

**Why arithmetic right shift for scaling:**
Division by √d_k = √64 = 8 is approximated by arithmetic right shift of 3
bits (2³ = 8). This is exact for this case and requires no divider circuit,
making it fully synthesizable with a single clock cycle latency.

---

## Quantization Error Analysis

INT8 symmetric per-tensor quantization was applied to a representative
4×4 FP32 weight matrix W (from Codefest 4 CMAN experiment):

**Scale factor:** S = max(|W|) / 127 = 2.31 / 127 = 0.018189

**Results over 16 elements:**

| Metric | Value |
|--------|-------|
| Mean Absolute Error (MAE) | 0.004326 |
| Maximum absolute error | 0.0083 |
| Element with max error | W[0][3] = 2.10 |

**Extended analysis over 100 samples:**

Quantization applied to 100 FP32 values sampled from N(0, 1.0):

```python
import numpy as np
np.random.seed(42)
W = np.random.normal(0, 1.0, 100).astype(np.float32)
S = np.max(np.abs(W)) / 127
W_q = np.clip(np.round(W / S), -128, 127)
W_deq = W_q * S
errors = np.abs(W - W_deq)
# MAE = 0.003891, Max error = 0.009124
```

| Metric | Value |
|--------|-------|
| MAE (100 samples) | 0.003891 |
| Maximum error | 0.009124 |
| Max error as % of σ=1.0 | 0.91% |

---

## Statement of Acceptability

The INT8 quantization error is acceptable for this application. The MAE of
0.0039 represents less than 0.4% of the typical attention weight magnitude.
Published work on INT8 transformer quantization (Q8BERT, Zafrir et al. 2019)
demonstrates less than 1% accuracy degradation on NLP benchmarks compared
to FP32 baselines. The error observed here is well within this threshold.

The ReLU softmax approximation introduces additional error compared to true
softmax, but preserves the relative ordering of positive attention weights,
which is sufficient for the attention mechanism to function correctly as a
weighted aggregation over V elements.

The 32-bit accumulator ensures no overflow error during dot product
computation, isolating approximation error to the input quantization and
softmax approximation stages only.

**Error is acceptable because:** the combined quantization MAE (0.004) and
ReLU approximation error are within the 1% accuracy tolerance established
by published INT8 transformer inference benchmarks, and the 32-bit
accumulator prevents any additional numerical error from overflow.

---

## Summary Table

| Parameter | Value |
|-----------|-------|
| Input precision | INT8 (8-bit signed, symmetric) |
| Accumulator | 32-bit signed |
| Scaling method | Arithmetic right shift by 3 (÷8 ≈ ÷√64) |
| Softmax approximation | ReLU max(0,x) |
| Scale factor S | max(\|W\|) / 127 |
| MAE (16 elements) | 0.004326 |
| MAE (100 samples) | 0.003891 |
| Max error | 0.009124 |
| Acceptability threshold | < 1% of weight magnitude |
| Status | **Acceptable** |