# ECE 510 HW for AI and ML Codefest-4  
## CMAN: Manual INT8 Symmetric Quantization

---

## Given 4×4 FP32 Weight Matrix

W =

| 0.85 | -1.20 | 0.34 | 2.10 |
|------|-------|------|------|
| -0.07 | 0.91 | -1.88 | 0.12 |
| 1.55 | 0.03 | -0.44 | -2.31 |
| -0.18 | 1.03 | 0.77 | 0.55 |

---

## 1. Scale Factor

S = max(|W|) / 127

Absolute values:

| 0.85 | 1.20 | 0.34 | 2.10 |
|------|------|------|------|
| 0.07 | 0.91 | 1.88 | 0.12 |
| 1.55 | 0.03 | 0.44 | 2.31 |
| 0.18 | 1.03 | 0.77 | 0.55 |

Max(|W|) = 2.31  

S = 2.31 / 127  
S = 0.0181889763779  

---

## 2. Quantization

W_q = round(W / S)

Quantized INT8 matrix:

| 47 | -66 | 19 | 115 |
|----|-----|----|-----|
| -4 | 50 | -103 | 7 |
| 85 | 2 | -24 | -127 |
| -10 | 57 | 42 | 30 |

(All values are within [-128, 127], so no clamping needed)

---

## 3. Dequantization

W_deq = W_q × S

| 0.8549 | -1.2005 | 0.3456 | 2.0917 |
|--------|---------|--------|--------|
| -0.0728 | 0.9094 | -1.8735 | 0.1273 |
| 1.5461 | 0.0364 | -0.4365 | -2.3100 |
| -0.1819 | 1.0368 | 0.7639 | 0.5457 |

---

## 4. Error Analysis

|W - W_deq|:

| 0.0049 | 0.0005 | 0.0056 | 0.0083 |
|--------|--------|--------|--------|
| 0.0028 | 0.0006 | 0.0065 | 0.0073 |
| 0.0039 | 0.0064 | 0.0035 | 0.0000 |
| 0.0019 | 0.0068 | 0.0061 | 0.0043 |

Largest Error = **0.0083**

Mean Absolute Error (MAE):

MAE = (sum of all errors) / 16  
MAE = 0.06922 / 16  
MAE = **0.004326**

---

## 5. Bad Scale Experiment (S_bad = 0.01)

### Quantization

W_q_bad = round(W / S_bad)

Before clamping:

| 85 | -120 | 34 | 210 |
|----|------|----|-----|
| -7 | 91 | -188 | 12 |
| 155 | 3 | -44 | -231 |
| -18 | 103 | 77 | 55 |

After clamping to [-128, 127]:

| 85 | -120 | 34 | 127 |
|----|------|----|-----|
| -7 | 91 | -128 | 12 |
| 127 | 3 | -44 | -128 |
| -18 | 103 | 77 | 55 |

---

### Dequantization

W_deq_bad = W_q_bad × 0.01

| 0.85 | -1.20 | 0.34 | 1.27 |
|------|-------|------|------|
| -0.07 | 0.91 | -1.28 | 0.12 |
| 1.27 | 0.03 | -0.44 | -1.28 |
| -0.18 | 1.03 | 0.77 | 0.55 |

---

### Error

|W - W_deq_bad|:

| 0 | 0 | 0 | 0.83 |
|---|---|---|------|
| 0 | 0 | 0.60 | 0 |
| 0.28 | 0 | 0 | 1.03 |
| 0 | 0 | 0 | 0 |

Mean Absolute Error (MAE_bad):

MAE_bad = 2.74 / 16  
MAE_bad = **0.17125**

---

### Final Observation

When the scale S is too small, many values exceed the INT8 range and are clamped to -128 or 127.  
This causes saturation and leads to significantly larger quantization error.